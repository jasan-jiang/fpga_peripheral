`timescale 1ns/1ps

module ds90lv_result_counter #(parameter integer DEVICE_COUNT=4,parameter integer COUNTER_WIDTH=32)(
    input wire clk,input wire rst_n,input wire run_enable,
    input wire [DEVICE_COUNT-1:0] active_devices,input wire [DEVICE_COUNT-1:0] expected,
    input wire [DEVICE_COUNT-1:0] y1,y2,y3,y4,
    output reg [DEVICE_COUNT*COUNTER_WIDTH-1:0] y1_correct,y1_error,y2_correct,y2_error,
    output reg [DEVICE_COUNT*COUNTER_WIDTH-1:0] y3_correct,y3_error,y4_correct,y4_error
);
    integer i;
    always @(posedge clk or negedge rst_n)begin
        if(!rst_n)begin y1_correct<=0;y1_error<=0;y2_correct<=0;y2_error<=0;y3_correct<=0;y3_error<=0;y4_correct<=0;y4_error<=0;end
        else if(run_enable)for(i=0;i<DEVICE_COUNT;i=i+1)if(active_devices[i])begin
            if(y1[i]==expected[i])y1_correct[i*COUNTER_WIDTH+:COUNTER_WIDTH]<=y1_correct[i*COUNTER_WIDTH+:COUNTER_WIDTH]+1'b1;else y1_error[i*COUNTER_WIDTH+:COUNTER_WIDTH]<=y1_error[i*COUNTER_WIDTH+:COUNTER_WIDTH]+1'b1;
            if(y2[i]==expected[i])y2_correct[i*COUNTER_WIDTH+:COUNTER_WIDTH]<=y2_correct[i*COUNTER_WIDTH+:COUNTER_WIDTH]+1'b1;else y2_error[i*COUNTER_WIDTH+:COUNTER_WIDTH]<=y2_error[i*COUNTER_WIDTH+:COUNTER_WIDTH]+1'b1;
            if(y3[i]==expected[i])y3_correct[i*COUNTER_WIDTH+:COUNTER_WIDTH]<=y3_correct[i*COUNTER_WIDTH+:COUNTER_WIDTH]+1'b1;else y3_error[i*COUNTER_WIDTH+:COUNTER_WIDTH]<=y3_error[i*COUNTER_WIDTH+:COUNTER_WIDTH]+1'b1;
            if(y4[i]==expected[i])y4_correct[i*COUNTER_WIDTH+:COUNTER_WIDTH]<=y4_correct[i*COUNTER_WIDTH+:COUNTER_WIDTH]+1'b1;else y4_error[i*COUNTER_WIDTH+:COUNTER_WIDTH]<=y4_error[i*COUNTER_WIDTH+:COUNTER_WIDTH]+1'b1;
        end
    end
endmodule
