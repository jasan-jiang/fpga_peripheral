`timescale 1ns/1ps

module top_ds90lv_loopback_test #(parameter integer DEVICE_COUNT=4,parameter integer COUNTER_WIDTH=32)(
    input wire sys_clk,                 // test/reference clock
    input wire sys_rst_n,               // asynchronous active-low reset
    input wire run_enable,              // enable pattern and result counters
    input wire config_valid,            // one-cycle divider update
    input wire [7:0] config_device,      // 0..N-1; N means all devices
    input wire [15:0] config_divider,    // output half-period in sys_clk cycles
    output wire [DEVICE_COUNT-1:0] driver_din, // to DS90LV031A logic inputs
    input wire [DEVICE_COUNT-1:0] receiver_y1,receiver_y2,receiver_y3,receiver_y4,
    output wire [DEVICE_COUNT*COUNTER_WIDTH-1:0] y1_correct,y1_error,
    output wire [DEVICE_COUNT*COUNTER_WIDTH-1:0] y2_correct,y2_error,
    output wire [DEVICE_COUNT*COUNTER_WIDTH-1:0] y3_correct,y3_error,
    output wire [DEVICE_COUNT*COUNTER_WIDTH-1:0] y4_correct,y4_error
);
    wire [DEVICE_COUNT-1:0] active;
    ds90lv_pattern_gen #(.DEVICE_COUNT(DEVICE_COUNT)) u_gen(.clk(sys_clk),.rst_n(sys_rst_n),
        .run_enable(run_enable),.config_valid(config_valid),.config_device(config_device),
        .config_divider(config_divider),.pattern_out(driver_din),.configured_devices(active));
    ds90lv_result_counter #(.DEVICE_COUNT(DEVICE_COUNT),.COUNTER_WIDTH(COUNTER_WIDTH)) u_count(
        .clk(sys_clk),.rst_n(sys_rst_n),.run_enable(run_enable),.active_devices(active),
        .expected(driver_din),.y1(receiver_y1),.y2(receiver_y2),.y3(receiver_y3),.y4(receiver_y4),
        .y1_correct(y1_correct),.y1_error(y1_error),.y2_correct(y2_correct),.y2_error(y2_error),
        .y3_correct(y3_correct),.y3_error(y3_error),.y4_correct(y4_correct),.y4_error(y4_error));
endmodule
