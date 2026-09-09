`timescale 1ns/1ps

module max9601_result_counter #(
    parameter integer DEVICE_COUNT=4, parameter integer COUNTER_WIDTH=32
)(
    input wire clk,input wire rst_n,input wire run_enable,
    input wire [DEVICE_COUNT-1:0] active_devices,input wire [DEVICE_COUNT-1:0] expected,
    input wire [DEVICE_COUNT-1:0] qa_p,input wire [DEVICE_COUNT-1:0] qa_n,
    input wire [DEVICE_COUNT-1:0] qb_p,input wire [DEVICE_COUNT-1:0] qb_n,
    output reg [DEVICE_COUNT*COUNTER_WIDTH-1:0] a_correct_count,
    output reg [DEVICE_COUNT*COUNTER_WIDTH-1:0] a_error_count,
    output reg [DEVICE_COUNT*COUNTER_WIDTH-1:0] b_correct_count,
    output reg [DEVICE_COUNT*COUNTER_WIDTH-1:0] b_error_count
);
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin a_correct_count<=0;a_error_count<=0;b_correct_count<=0;b_error_count<=0;end
        else if(run_enable)for(i=0;i<DEVICE_COUNT;i=i+1)if(active_devices[i])begin
            if((qa_p[i]==expected[i])&&(qa_n[i]!=expected[i]))
                a_correct_count[i*COUNTER_WIDTH+:COUNTER_WIDTH]<=a_correct_count[i*COUNTER_WIDTH+:COUNTER_WIDTH]+1'b1;
            else a_error_count[i*COUNTER_WIDTH+:COUNTER_WIDTH]<=a_error_count[i*COUNTER_WIDTH+:COUNTER_WIDTH]+1'b1;
            if((qb_p[i]==expected[i])&&(qb_n[i]!=expected[i]))
                b_correct_count[i*COUNTER_WIDTH+:COUNTER_WIDTH]<=b_correct_count[i*COUNTER_WIDTH+:COUNTER_WIDTH]+1'b1;
            else b_error_count[i*COUNTER_WIDTH+:COUNTER_WIDTH]<=b_error_count[i*COUNTER_WIDTH+:COUNTER_WIDTH]+1'b1;
        end
    end
endmodule
