`timescale 1ns/1ps

// Collect 32-bit words in a fifo_generator_0 IP. Whenever at least
// BATCH_WORDS are available, transmit one UDP payload containing those words.
module fifo_udp_tx #(
    parameter integer BATCH_WORDS = 50,
    parameter         MSB_FIRST   = 1'b1,
    parameter [47:0]  BOARD_MAC   = 48'h00_11_22_33_44_55,
    parameter [31:0]  BOARD_IP    = {8'd192, 8'd168, 8'd1, 8'd10},
    parameter [47:0]  DES_MAC     = 48'hff_ff_ff_ff_ff_ff,
    parameter [31:0]  DES_IP      = {8'd192, 8'd168, 8'd1, 8'd102}
)(
    // FIFO write interface and common clock/reset.
    input  wire        clk,
    input  wire        srst,
    input  wire [31:0] din,
    input  wire        wr_en,
    output wire        full,
    output wire        empty,
    output wire [31:0] dout,
    output reg         rd_en,
    output wire [9:0]  data_count,

    // Destination. Drive zero to use DES_MAC/DES_IP parameters.
    input  wire [47:0] des_mac,
    input  wire [31:0] des_ip,

    // GMII transmit interface from the existing udp module.
    output wire        gmii_tx_en,
    output wire [7:0]  gmii_txd,
    output wire        udp_tx_done,
    output wire        udp_tx_req,
    output reg         batch_busy
);
    localparam integer UDP_PAYLOAD_BYTES = BATCH_WORDS * 4;

    localparam [3:0] ST_IDLE          = 4'd0,
                     ST_WORD0_WAIT    = 4'd1,
                     ST_WORD0_CAPTURE = 4'd2,
                     ST_WORD1_WAIT    = 4'd3,
                     ST_WORD1_CAPTURE = 4'd4,
                     ST_STREAM        = 4'd5;

    reg [3:0]  state;
    reg [31:0] current_word;
    reg [31:0] next_word;
    reg [7:0]  udp_tx_data;
    reg        udp_tx_start_en;
    reg        request_seen;
    reg [1:0]  byte_index;
    reg [7:0]  word_index;
    reg [1:0]  prefetch_delay;

    wire fifo_wr_en = wr_en && !full;
    wire rst_n = !srst;

    function [7:0] select_byte;
        input [31:0] word_value;
        input [1:0]  index;
        begin
            if (MSB_FIRST) begin
                case (index)
                    2'd0: select_byte = word_value[31:24];
                    2'd1: select_byte = word_value[23:16];
                    2'd2: select_byte = word_value[15:8];
                    default: select_byte = word_value[7:0];
                endcase
            end else begin
                case (index)
                    2'd0: select_byte = word_value[7:0];
                    2'd1: select_byte = word_value[15:8];
                    2'd2: select_byte = word_value[23:16];
                    default: select_byte = word_value[31:24];
                endcase
            end
        end
    endfunction

    // Vivado FIFO Generator IP configuration required by this instance:
    // common clock, standard read mode, width 32, depth 1024, synchronous
    // active-high reset, and a 10-bit data_count output.
    fifo_generator_0 u_fifo_generator_0 (
        .full       (full),
        .din        (din),
        .wr_en      (fifo_wr_en),
        .empty      (empty),
        .dout       (dout),
        .rd_en      (rd_en),
        .data_count (data_count),
        .clk        (clk),
        .srst       (srst)
    );

    // Receive is unused in this transmit-only wrapper. Keeping the receive
    // clock running prevents an undriven clock input in the udp instance.
    udp #(
        .BOARD_MAC (BOARD_MAC),
        .BOARD_IP  (BOARD_IP),
        .DES_MAC   (DES_MAC),
        .DES_IP    (DES_IP)
    ) u_udp (
        .rst_n        (rst_n),
        .gmii_rx_clk  (clk),
        .gmii_rx_dv   (1'b0),
        .gmii_rxd     (8'd0),
        .gmii_tx_clk  (clk),
        .gmii_tx_en   (gmii_tx_en),
        .gmii_txd     (gmii_txd),
        .rec_pkt_done (),
        .rec_en       (),
        .rec_data     (),
        .rec_byte_num (),
        .tx_start_en  (udp_tx_start_en),
        .tx_data      (udp_tx_data),
        .tx_byte_num  (UDP_PAYLOAD_BYTES[15:0]),
        .des_mac      (des_mac),
        .des_ip       (des_ip),
        .tx_done      (udp_tx_done),
        .tx_req       (udp_tx_req)
    );

    // The FIFO has standard (registered) read behavior. Two words are loaded
    // before UDP starts; later reads overlap serialization using next_word.
    always @(posedge clk) begin
        if (srst) begin
            state             <= ST_IDLE;
            current_word      <= 32'd0;
            next_word         <= 32'd0;
            udp_tx_data       <= 8'd0;
            udp_tx_start_en   <= 1'b0;
            request_seen      <= 1'b0;
            byte_index        <= 2'd0;
            word_index        <= 8'd0;
            prefetch_delay    <= 2'd0;
            rd_en             <= 1'b0;
            batch_busy        <= 1'b0;
        end else begin
            udp_tx_start_en <= 1'b0;
            rd_en <= 1'b0;

            // Capture a background FIFO read two cycles after rd_en is issued.
            if (prefetch_delay == 2) begin
                prefetch_delay <= 1;
            end else if (prefetch_delay == 1) begin
                next_word <= dout;
                prefetch_delay <= 0;
            end

            case (state)
                ST_IDLE: begin
                    batch_busy <= 1'b0;
                    request_seen <= 1'b0;
                    if ((data_count >= BATCH_WORDS) && !empty) begin
                        rd_en <= 1'b1;
                        batch_busy <= 1'b1;
                        state <= ST_WORD0_WAIT;
                    end
                end

                ST_WORD0_WAIT: begin
                    state <= ST_WORD0_CAPTURE;
                end

                ST_WORD0_CAPTURE: begin
                    current_word <= dout;
                    rd_en <= 1'b1;
                    state <= ST_WORD1_WAIT;
                end

                ST_WORD1_WAIT: begin
                    state <= ST_WORD1_CAPTURE;
                end

                ST_WORD1_CAPTURE: begin
                    next_word <= dout;
                    udp_tx_data <= select_byte(current_word, 2'd0);
                    udp_tx_start_en <= 1'b1;
                    byte_index <= 2'd0;
                    word_index <= 8'd0;
                    request_seen <= 1'b0;
                    state <= ST_STREAM;
                end

                ST_STREAM: begin
                    if (udp_tx_done) begin
                        batch_busy <= 1'b0;
                        request_seen <= 1'b0;
                        prefetch_delay <= 2'd0;
                        state <= ST_IDLE;
                    end else if (udp_tx_req) begin
                        // udp_tx raises tx_req one cycle before consuming the
                        // first payload byte. Ignore that leading request only.
                        if (!request_seen) begin
                            request_seen <= 1'b1;
                        end else if (byte_index == 2'd3) begin
                            // The current low byte is consumed on this edge.
                            // Move the already-prefetched word into service.
                            if (word_index < BATCH_WORDS-1) begin
                                current_word <= next_word;
                                udp_tx_data <= select_byte(next_word, 2'd0);
                                byte_index <= 2'd0;
                                word_index <= word_index + 1'b1;

                                // After switching to word 49 (index 48), word
                                // 50 is already in next_word; no further read.
                                if (word_index < BATCH_WORDS-2) begin
                                    rd_en <= 1'b1;
                                    prefetch_delay <= 2'd2;
                                end
                            end
                        end else begin
                            byte_index <= byte_index + 1'b1;
                            udp_tx_data <= select_byte(current_word,
                                                       byte_index + 1'b1);
                        end
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

    initial begin
        if (BATCH_WORDS < 2)
            $error("fifo_udp_tx requires BATCH_WORDS >= 2");
        if (UDP_PAYLOAD_BYTES > 65535)
            $error("UDP payload exceeds 16-bit length field");
    end
endmodule
