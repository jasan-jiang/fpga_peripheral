`timescale 1ns/1ps

module max9601_pattern_gen #(
    parameter integer DEVICE_COUNT=4,
    parameter integer DIVIDER_WIDTH=16
)(
    input wire clk,input wire rst_n,input wire run_enable,
    input wire config_valid,input wire [7:0] config_device,
    input wire [DIVIDER_WIDTH-1:0] config_divider,
    output reg [DEVICE_COUNT-1:0] pattern_out,
    output reg [DEVICE_COUNT-1:0] configured_devices
);
    reg [DIVIDER_WIDTH-1:0] divider[0:DEVICE_COUNT-1];
    reg [DIVIDER_WIDTH-1:0] count[0:DEVICE_COUNT-1]; integer i;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin pattern_out<=0;configured_devices<=0;
            for(i=0;i<DEVICE_COUNT;i=i+1)begin divider[i]<=0;count[i]<=0;end end
        else for(i=0;i<DEVICE_COUNT;i=i+1)begin
            if(config_valid&&((config_device==i)||(config_device==DEVICE_COUNT)))begin
                divider[i]<=config_divider;count[i]<=0;pattern_out[i]<=0;configured_devices[i]<=1;end
            else if(!run_enable||!configured_devices[i]||divider[i]<2)begin count[i]<=0;pattern_out[i]<=0;end
            else if(count[i]>=divider[i]-1)begin count[i]<=0;pattern_out[i]<=~pattern_out[i];end
            else count[i]<=count[i]+1'b1;
        end
    end
endmodule
