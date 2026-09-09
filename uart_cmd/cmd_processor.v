`timescale 1ns/1ps

module cmd_processor(
    input clk_50m,
    input rst_n,
    input rx,
    output tx
);

    // Received frame layout:
    // byte 0: head; bytes 1..12: address/function/ID0..ID9;
    // byte 13: checksum; byte 14: tail.
    wire [119:0] cmd_rx;
    reg [119:0] cmd_tx;
    // This is the only accept/execute pulse in this loopback example. It is
    // asserted only for a frame whose byte-13 checksum is valid.
    reg cmd_valid;

    wire cmd_rx_done;
    wire cmd_tx_done;


    cmd_rx u_cmd_rx( 
        .clk_50m(clk_50m),
        .rst_n(rst_n),
        .data_in(rx),
        .cmd_cout(cmd_rx),
        .cmd_rx_done(cmd_rx_done),
        .cmd_rx_busy()
    );

    cmd_tx u_cmd_tx(
        .clk_50m(clk_50m),
        .rst_n(rst_n),
        .cmd(cmd_tx),
        .cmd_tx_start(cmd_valid),
        .data_out(tx),
        .cmd_tx_done(cmd_tx_done),
        .cmd_tx_busy()
    );

    reg cmd_rx_done1;
    wire cmd_rx_done_rise;
    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n)begin
            cmd_rx_done1<=1'b0;
        end else
            cmd_rx_done1<=cmd_rx_done;
    end
    assign cmd_rx_done_rise=cmd_rx_done&~cmd_rx_done1;

    // The protocol checksum is the modulo-256 sum of bytes 1 through 12.
    // The head (byte 0), checksum (byte 13), and tail (byte 14) are excluded.
    function [7:0] calc_checksum;
        input [119:0] frame;
        integer byte_index;
        reg [7:0] sum;
        begin
            sum = 8'd0;
            for(byte_index = 1; byte_index <= 12;
                byte_index = byte_index + 1)
                sum = sum + frame[byte_index*8 +: 8];
            calc_checksum = sum;
        end
    endfunction

    wire checksum_ok = (cmd_rx[111:104] == calc_checksum(cmd_rx));

    // A bad checksum produces no cmd_valid pulse, so no command is accepted
    // and cmd_tx is not started. It is deliberately discarded without reply.
    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n)begin
            cmd_valid<=1'b0;
            cmd_tx<=120'b0;
        end else if(cmd_rx_done_rise && checksum_ok)begin
            cmd_tx<=cmd_rx;
            cmd_valid<=1'b1;
        end else if(cmd_rx_done_rise)begin
            cmd_tx<=120'b0;
            cmd_valid<=1'b0;
        end else begin
            cmd_valid<=1'b0;
        end
    end

endmodule
