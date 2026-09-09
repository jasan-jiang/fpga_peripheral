`timescale 1ns/1ps

// Self-contained ADS1110 I2C controller. It writes CONFIG once, then reads
// conversion MSB, LSB and CONFIG periodically. SCL/SDA require pull-ups.
module ads1110_driver #(
    parameter integer CLK_FREQ_HZ      = 50_000_000,
    parameter integer I2C_FREQ_HZ      = 100_000,
    parameter integer SAMPLE_PERIOD_US = 10_000,
    parameter [6:0]   I2C_ADDR          = 7'h48,
    parameter [7:0]   CONFIG            = 8'h8C
)(
    input  wire        clk,
    input  wire        rst_n,
    output wire        i2c_scl,
    inout  wire        i2c_sda,
    output reg  [15:0] sample_data,
    output reg  [7:0]  status_config,
    output reg          sample_valid,
    output wire         busy,
    output reg          ack_error
);
    localparam integer QUARTER = CLK_FREQ_HZ / (I2C_FREQ_HZ*4);
    localparam integer QW = (QUARTER <= 1) ? 1 : $clog2(QUARTER);
    localparam integer PERIOD_CYCLES = (CLK_FREQ_HZ/1_000_000)*SAMPLE_PERIOD_US;
    localparam integer PERIOD_TICKS = (PERIOD_CYCLES/QUARTER < 1) ? 1 : PERIOD_CYCLES/QUARTER;
    localparam integer PW = (PERIOD_TICKS <= 1) ? 1 : $clog2(PERIOD_TICKS+1);
    localparam [3:0] IDLE=0, START0=1, START1=2, START2=3, SEND=4,
                     ACK=5, RECV=6, MASTER_ACK=7, STOP0=8, STOP1=9, STOP2=10;

    reg [3:0] state;
    reg [QW-1:0] tick_count;
    reg [PW-1:0] period_count;
    reg [1:0] phase;
    reg [2:0] bit_index;
    reg [1:0] byte_index;
    reg [7:0] tx_byte, rx_byte;
    reg transaction_read, configured;
    reg scl_low, sda_low;
    wire tick = (QUARTER <= 1) || (tick_count == QUARTER-1);

    assign i2c_scl = scl_low ? 1'b0 : 1'bz;
    assign i2c_sda = sda_low ? 1'b0 : 1'bz;
    assign busy = (state != IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE; tick_count <= 0; period_count <= 0; phase <= 0;
            bit_index <= 3'd7; byte_index <= 0; tx_byte <= 0; rx_byte <= 0;
            transaction_read <= 1'b0; configured <= 1'b0;
            scl_low <= 1'b0; sda_low <= 1'b0; sample_data <= 0;
            status_config <= 0; sample_valid <= 1'b0; ack_error <= 1'b0;
        end else begin
            sample_valid <= 1'b0;
            if (!tick) tick_count <= tick_count + 1'b1;
            else begin
                tick_count <= 0;
                case (state)
                    IDLE: begin
                        scl_low <= 1'b0; sda_low <= 1'b0; ack_error <= 1'b0;
                        if (!configured) begin
                            transaction_read <= 1'b0; byte_index <= 0;
                            state <= START0;
                        end else if ((PERIOD_TICKS <= 1) ||
                                     (period_count == PERIOD_TICKS-1)) begin
                            period_count <= 0; transaction_read <= 1'b1;
                            byte_index <= 0; state <= START0;
                        end else period_count <= period_count + 1'b1;
                    end
                    START0: begin scl_low <= 1'b0; sda_low <= 1'b0; state <= START1; end
                    START1: begin sda_low <= 1'b1; state <= START2; end
                    START2: begin
                        scl_low <= 1'b1; tx_byte <= {I2C_ADDR, transaction_read};
                        bit_index <= 3'd7; phase <= 0; state <= SEND;
                    end
                    SEND: begin
                        case (phase)
                            0: begin scl_low<=1'b1; sda_low<=~tx_byte[bit_index]; phase<=1; end
                            1: begin scl_low<=1'b0; phase<=2; end
                            2: phase<=3;
                            3: begin
                                scl_low<=1'b1; phase<=0;
                                if (bit_index==0) state<=ACK;
                                else bit_index<=bit_index-1'b1;
                            end
                        endcase
                    end
                    ACK: begin
                        case (phase)
                            0: begin sda_low<=1'b0; scl_low<=1'b1; phase<=1; end
                            1: begin scl_low<=1'b0; phase<=2; end
                            2: begin if (i2c_sda) ack_error<=1'b1; phase<=3; end
                            3: begin
                                scl_low<=1'b1; phase<=0;
                                if (ack_error || i2c_sda) state<=STOP0;
                                else if (!transaction_read && byte_index==0) begin
                                    byte_index<=1; tx_byte<=CONFIG; bit_index<=7; state<=SEND;
                                end else if (!transaction_read) begin
                                    configured<=1'b1; state<=STOP0;
                                end else begin
                                    byte_index<=0; bit_index<=7; rx_byte<=0; state<=RECV;
                                end
                            end
                        endcase
                    end
                    RECV: begin
                        case (phase)
                            0: begin sda_low<=1'b0; scl_low<=1'b1; phase<=1; end
                            1: begin scl_low<=1'b0; phase<=2; end
                            2: begin
                                rx_byte[bit_index] <= i2c_sda; phase<=3;
                                if (bit_index==0) begin
                                    if (byte_index==0) sample_data[15:8]<={rx_byte[7:1],i2c_sda};
                                    else if (byte_index==1) sample_data[7:0]<={rx_byte[7:1],i2c_sda};
                                    else status_config<={rx_byte[7:1],i2c_sda};
                                end
                            end
                            3: begin
                                scl_low<=1'b1; phase<=0;
                                if (bit_index==0) state<=MASTER_ACK;
                                else bit_index<=bit_index-1'b1;
                            end
                        endcase
                    end
                    MASTER_ACK: begin
                        case (phase)
                            0: begin sda_low<=(byte_index<2); scl_low<=1'b1; phase<=1; end
                            1: begin scl_low<=1'b0; phase<=2; end
                            2: phase<=3;
                            3: begin
                                scl_low<=1'b1; sda_low<=1'b0; phase<=0;
                                if (byte_index==2) state<=STOP0;
                                else begin byte_index<=byte_index+1'b1; bit_index<=7; rx_byte<=0; state<=RECV; end
                            end
                        endcase
                    end
                    STOP0: begin scl_low<=1'b1; sda_low<=1'b1; state<=STOP1; end
                    STOP1: begin scl_low<=1'b0; state<=STOP2; end
                    STOP2: begin
                        sda_low<=1'b0;
                        if (transaction_read && !ack_error) sample_valid<=1'b1;
                        state<=IDLE;
                    end
                    default: state<=IDLE;
                endcase
            end
        end
    end
endmodule
