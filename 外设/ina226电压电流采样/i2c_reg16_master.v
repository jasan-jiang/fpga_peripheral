`timescale 1ns/1ps

// Small open-drain I2C master for 8-bit register / 16-bit data devices.
// Clock stretching and multi-master arbitration are intentionally unsupported.
module i2c_reg16_master #(
    parameter integer CLK_FREQ_HZ = 50_000_000,
    parameter integer I2C_FREQ_HZ = 100_000,
    parameter [6:0] I2C_ADDR = 7'h40
)(
    input  wire        clk, input wire rst_n, input wire start,
    input  wire        write_enable, input wire [7:0] reg_addr,
    input  wire [15:0] write_data, output reg [15:0] read_data,
    output reg done, output wire busy, output reg ack_error,
    output wire i2c_scl, inout wire i2c_sda
);
    localparam integer QUARTER=CLK_FREQ_HZ/(I2C_FREQ_HZ*4);
    localparam integer QW=(QUARTER<=1)?1:$clog2(QUARTER);
    localparam [4:0] IDLE=0,START0=1,START1=2,START2=3,SEND=4,ACK=5,
        RSTART0=6,RSTART1=7,RSTART2=8,RECV=9,MASTER_ACK=10,
        STOP0=11,STOP1=12,STOP2=13;
    reg [4:0] state;
    reg [QW-1:0] tick_count;
    reg [1:0] phase;
    reg [2:0] bit_index, token;
    reg [7:0] tx_byte, rx_byte, reg_latched;
    reg [15:0] data_latched;
    reg op_write, scl_low, sda_low;
    wire tick=(QUARTER<=1)||(tick_count==QUARTER-1);
    assign i2c_scl=scl_low?1'b0:1'bz;
    assign i2c_sda=sda_low?1'b0:1'bz;
    assign busy=(state!=IDLE);

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state<=IDLE; tick_count<=0; phase<=0; bit_index<=7; token<=0;
            tx_byte<=0; rx_byte<=0; reg_latched<=0; data_latched<=0;
            op_write<=0; scl_low<=0; sda_low<=0; read_data<=0;
            done<=0; ack_error<=0;
        end else begin
            done<=0;
            if(state==IDLE) begin
                scl_low<=0; sda_low<=0;
                if(start) begin
                    op_write<=write_enable; reg_latched<=reg_addr;
                    data_latched<=write_data; token<=0; ack_error<=0; state<=START0;
                end
            end
            if(!tick) tick_count<=tick_count+1'b1;
            else begin
                tick_count<=0;
                case(state)
                    IDLE: ;
                    START0: begin scl_low<=0;sda_low<=0;state<=START1;end
                    START1: begin sda_low<=1;state<=START2;end
                    START2: begin scl_low<=1;tx_byte<={I2C_ADDR,1'b0};bit_index<=7;phase<=0;state<=SEND;end
                    SEND: case(phase)
                        0:begin scl_low<=1;sda_low<=~tx_byte[bit_index];phase<=1;end
                        1:begin scl_low<=0;phase<=2;end
                        2:phase<=3;
                        3:begin scl_low<=1;phase<=0;if(bit_index==0)state<=ACK;else bit_index<=bit_index-1'b1;end
                    endcase
                    ACK: case(phase)
                        0:begin sda_low<=0;scl_low<=1;phase<=1;end
                        1:begin scl_low<=0;phase<=2;end
                        2:begin if(i2c_sda)ack_error<=1;phase<=3;end
                        3:begin
                            scl_low<=1;phase<=0;
                            if(ack_error||i2c_sda)state<=STOP0;
                            else if(token==0)begin token<=1;tx_byte<=reg_latched;bit_index<=7;state<=SEND;end
                            else if(op_write&&token==1)begin token<=2;tx_byte<=data_latched[15:8];bit_index<=7;state<=SEND;end
                            else if(op_write&&token==2)begin token<=3;tx_byte<=data_latched[7:0];bit_index<=7;state<=SEND;end
                            else if(op_write)state<=STOP0;
                            else if(token==1)state<=RSTART0;
                            else begin token<=0;bit_index<=7;rx_byte<=0;state<=RECV;end
                        end
                    endcase
                    RSTART0:begin sda_low<=0;scl_low<=1;state<=RSTART1;end
                    RSTART1:begin scl_low<=0;state<=RSTART2;end
                    RSTART2:begin sda_low<=1;scl_low<=1;token<=2;tx_byte<={I2C_ADDR,1'b1};bit_index<=7;state<=SEND;end
                    RECV:case(phase)
                        0:begin sda_low<=0;scl_low<=1;phase<=1;end
                        1:begin scl_low<=0;phase<=2;end
                        2:begin rx_byte[bit_index]<=i2c_sda;phase<=3;
                            if(bit_index==0)begin
                                if(token==0)read_data[15:8]<={rx_byte[7:1],i2c_sda};
                                else read_data[7:0]<={rx_byte[7:1],i2c_sda};
                            end
                        end
                        3:begin scl_low<=1;phase<=0;if(bit_index==0)state<=MASTER_ACK;else bit_index<=bit_index-1'b1;end
                    endcase
                    MASTER_ACK:case(phase)
                        0:begin sda_low<=(token==0);scl_low<=1;phase<=1;end
                        1:begin scl_low<=0;phase<=2;end
                        2:phase<=3;
                        3:begin scl_low<=1;sda_low<=0;phase<=0;
                            if(token==0)begin token<=1;bit_index<=7;rx_byte<=0;state<=RECV;end
                            else state<=STOP0;
                        end
                    endcase
                    STOP0:begin scl_low<=1;sda_low<=1;state<=STOP1;end
                    STOP1:begin scl_low<=0;state<=STOP2;end
                    STOP2:begin sda_low<=0;done<=1;state<=IDLE;end
                    default:state<=IDLE;
                endcase
            end
        end
    end
endmodule
