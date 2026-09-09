`timescale 1ns/1ps

module top_max9601_test #(parameter integer DEVICE_COUNT=4,parameter integer COUNTER_WIDTH=32)(
    input wire sys_clk,                 // test/reference clock
    input wire sys_rst_n,               // asynchronous active-low reset
    input wire run_enable,              // enables generation and counting
    input wire config_valid,            // one-cycle divider update
    input wire [7:0] config_device,      // 0..N-1; N updates every device
    input wire [15:0] config_divider,    // output half-period in sys_clk cycles
    output wire [DEVICE_COUNT-1:0] test_pattern, // drive comparator inputs via board circuitry
    input wire [DEVICE_COUNT-1:0] qa_p,qa_n,qb_p,qb_n, // differential comparator outputs
    output wire [DEVICE_COUNT*COUNTER_WIDTH-1:0] a_correct_count,a_error_count,
    output wire [DEVICE_COUNT*COUNTER_WIDTH-1:0] b_correct_count,b_error_count
);
    wire [DEVICE_COUNT-1:0] active;
    max9601_pattern_gen #(.DEVICE_COUNT(DEVICE_COUNT)) u_gen(.clk(sys_clk),.rst_n(sys_rst_n),
        .run_enable(run_enable),.config_valid(config_valid),.config_device(config_device),
        .config_divider(config_divider),.pattern_out(test_pattern),.configured_devices(active));
    max9601_result_counter #(.DEVICE_COUNT(DEVICE_COUNT),.COUNTER_WIDTH(COUNTER_WIDTH)) u_count(
        .clk(sys_clk),.rst_n(sys_rst_n),.run_enable(run_enable),.active_devices(active),
        .expected(test_pattern),.qa_p(qa_p),.qa_n(qa_n),.qb_p(qb_p),.qb_n(qb_n),
        .a_correct_count(a_correct_count),.a_error_count(a_error_count),
        .b_correct_count(b_correct_count),.b_error_count(b_error_count));
endmodule
