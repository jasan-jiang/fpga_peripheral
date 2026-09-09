`timescale 1ns/1ps

module top_ads1110 #(
    parameter integer CLK_FREQ_HZ      = 50_000_000,
    parameter integer I2C_FREQ_HZ      = 100_000,
    parameter integer SAMPLE_PERIOD_US = 10_000,
    parameter [6:0]   I2C_ADDR          = 7'h48,
    parameter [7:0]   CONFIG            = 8'h8C
)(
    input  wire        sys_clk,        // FPGA system clock
    input  wire        sys_rst_n,      // asynchronous active-low reset
    output wire        i2c_scl,        // open-drain I2C clock; external pull-up required
    inout  wire        i2c_sda,        // open-drain I2C data; external pull-up required
    output wire [15:0] sample_data,    // latest signed two's-complement ADC code
    output wire [7:0]  status_config,  // CONFIG byte returned by ADS1110
    output wire        sample_valid,   // one-cycle data-valid pulse
    output wire        busy,           // I2C transaction in progress
    output wire        ack_error       // no ACK in the latest transaction
);
    ads1110_driver #(
        .CLK_FREQ_HZ(CLK_FREQ_HZ), .I2C_FREQ_HZ(I2C_FREQ_HZ),
        .SAMPLE_PERIOD_US(SAMPLE_PERIOD_US), .I2C_ADDR(I2C_ADDR), .CONFIG(CONFIG)
    ) u_ads1110_driver (
        .clk(sys_clk), .rst_n(sys_rst_n), .i2c_scl(i2c_scl), .i2c_sda(i2c_sda),
        .sample_data(sample_data), .status_config(status_config),
        .sample_valid(sample_valid), .busy(busy), .ack_error(ack_error)
    );
endmodule
