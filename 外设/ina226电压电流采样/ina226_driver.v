`timescale 1ns/1ps

module ina226_driver #(
    parameter integer CLK_FREQ_HZ=50_000_000,
    parameter integer I2C_FREQ_HZ=100_000,
    parameter integer SAMPLE_PERIOD_US=10_000,
    parameter [6:0] I2C_ADDR=7'h40,
    parameter [15:0] CONFIG=16'h4127,
    parameter [15:0] CALIBRATION=16'h0800
)(
    input wire clk,input wire rst_n,output wire i2c_scl,inout wire i2c_sda,
    output reg [15:0] bus_voltage_raw,output reg [15:0] current_raw,
    output reg sample_valid,output wire busy,output wire ack_error
);
    localparam integer PERIOD_CYCLES=(CLK_FREQ_HZ/1_000_000)*SAMPLE_PERIOD_US;
    localparam integer PW=(PERIOD_CYCLES<=1)?1:$clog2(PERIOD_CYCLES+1);
    localparam [3:0] CFG_REQ=0,CFG_WAIT=1,CAL_REQ=2,CAL_WAIT=3,WAIT=4,
        VOLT_REQ=5,VOLT_GET=6,CURR_REQ=7,CURR_GET=8;
    reg [3:0] state; reg [PW-1:0] period_count; reg start,write_enable;
    reg [7:0] reg_addr; reg [15:0] write_data; wire [15:0] read_data; wire done;
    wire master_busy;
    assign busy=master_busy||(state!=WAIT);
    i2c_reg16_master #(.CLK_FREQ_HZ(CLK_FREQ_HZ),.I2C_FREQ_HZ(I2C_FREQ_HZ),.I2C_ADDR(I2C_ADDR)) u_i2c(
        .clk(clk),.rst_n(rst_n),.start(start),.write_enable(write_enable),
        .reg_addr(reg_addr),.write_data(write_data),.read_data(read_data),
        .done(done),.busy(master_busy),.ack_error(ack_error),.i2c_scl(i2c_scl),.i2c_sda(i2c_sda));
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin state<=CFG_REQ;period_count<=0;start<=0;write_enable<=0;
            reg_addr<=0;write_data<=0;bus_voltage_raw<=0;current_raw<=0;sample_valid<=0;end
        else begin
            start<=0;sample_valid<=0;
            case(state)
                CFG_REQ:if(!master_busy)begin start<=1;write_enable<=1;reg_addr<=8'h00;write_data<=CONFIG;state<=CFG_WAIT;end
                CFG_WAIT:if(done)state<=CAL_REQ;
                CAL_REQ:if(!master_busy)begin start<=1;write_enable<=1;reg_addr<=8'h05;write_data<=CALIBRATION;state<=CAL_WAIT;end
                CAL_WAIT:if(done)state<=WAIT;
                WAIT:if((PERIOD_CYCLES<=1)||(period_count==PERIOD_CYCLES-1))begin period_count<=0;state<=VOLT_REQ;end
                    else period_count<=period_count+1'b1;
                VOLT_REQ:if(!master_busy)begin start<=1;write_enable<=0;reg_addr<=8'h02;state<=VOLT_GET;end
                VOLT_GET:if(done)begin bus_voltage_raw<=read_data;state<=CURR_REQ;end
                CURR_REQ:if(!master_busy)begin start<=1;write_enable<=0;reg_addr<=8'h04;state<=CURR_GET;end
                CURR_GET:if(done)begin current_raw<=read_data;sample_valid<=~ack_error;state<=WAIT;end
                default:state<=CFG_REQ;
            endcase
        end
    end
endmodule
