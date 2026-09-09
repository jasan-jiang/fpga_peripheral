`timescale 1ns/1ps

module top_ad7984 #(
    parameter integer CLK_FREQ_HZ = 50_000_000,
    parameter integer SCLK_FREQ_HZ = 10_000_000,
    parameter integer CNV_HIGH_NS  = 600
)(
    input  wire        sys_clk,       // FPGA system clock
    input  wire        sys_rst_n,     // asynchronous active-low reset
    input  wire        sample_start,  // one-cycle conversion request
    input  wire        adc_sdo,       // AD7984 serial data output
    output wire        adc_cnv,       // conversion-start output
    output wire        adc_sclk,      // serial read clock
    output wire [17:0] sample_data,   // latest 18-bit conversion code
    output wire        sample_valid,  // one-cycle data-valid pulse
    output wire        busy           // conversion/read in progress
);
    ad7984_driver #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ), .SCLK_FREQ_HZ(SCLK_FREQ_HZ),
        .CNV_HIGH_NS(CNV_HIGH_NS)
    ) u_ad7984_driver (
        .clk(sys_clk), .rst_n(sys_rst_n), .start(sample_start),
        .adc_sdo(adc_sdo), .adc_cnv(adc_cnv), .adc_sclk(adc_sclk),
        .sample_data(sample_data), .sample_valid(sample_valid), .busy(busy)
    );
endmodule
