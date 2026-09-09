`timescale 1ns/1ps

// Board-level wrapper. Map these ports directly in the constraints file.
module top_adc128s102 #(
    parameter integer CLK_FREQ_HZ = 50_000_000,
    parameter integer SCLK_FREQ_HZ = 8_000_000,
    parameter integer DEVICE_COUNT = 1
)(
    input  wire                    sys_clk,       // FPGA system clock
    input  wire                    sys_rst_n,     // asynchronous active-low reset
    input  wire                    sample_start,  // one-cycle request; ignored while busy
    input  wire [2:0]              adc_channel,   // channel 0..7
    input  wire [1:0]              adc_device,    // device 0..DEVICE_COUNT-1
    input  wire [DEVICE_COUNT-1:0] adc_dout,      // ADC serial data outputs
    output wire [DEVICE_COUNT-1:0] adc_sclk,      // ADC serial clocks, idle high
    output wire [DEVICE_COUNT-1:0] adc_cs_n,      // active-low chip selects
    output wire [DEVICE_COUNT-1:0] adc_din,       // ADC channel command inputs
    output wire [11:0]             sample_data,   // latest unsigned conversion code
    output wire                    sample_valid,  // one-cycle data-valid pulse
    output wire                    busy           // transaction in progress
);
    adc128s102_driver #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ), .SCLK_FREQ_HZ(SCLK_FREQ_HZ),
        .DEVICE_COUNT(DEVICE_COUNT)
    ) u_adc128s102_driver (
        .clk(sys_clk), .rst_n(sys_rst_n), .start(sample_start),
        .channel(adc_channel), .device_select(adc_device), .adc_dout(adc_dout),
        .adc_sclk(adc_sclk), .adc_cs_n(adc_cs_n), .adc_din(adc_din),
        .sample_data(sample_data), .sample_valid(sample_valid), .busy(busy)
    );
endmodule
