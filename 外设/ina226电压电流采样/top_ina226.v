`timescale 1ns/1ps

module top_ina226 #(
    parameter integer CLK_FREQ_HZ=50_000_000,
    parameter integer I2C_FREQ_HZ=100_000,
    parameter integer SAMPLE_PERIOD_US=10_000,
    parameter [6:0] I2C_ADDR=7'h40,
    parameter [15:0] CONFIG=16'h4127,
    parameter [15:0] CALIBRATION=16'h0800
)(
    input wire sys_clk,                 // FPGA system clock
    input wire sys_rst_n,               // asynchronous active-low reset
    output wire i2c_scl,                // open-drain SCL; pull-up required
    inout wire i2c_sda,                 // open-drain SDA; pull-up required
    output wire [15:0] bus_voltage_raw, // INA226 register 02h, unsigned
    output wire [15:0] current_raw,     // INA226 register 04h, signed
    output wire sample_valid,           // one-cycle pulse after both reads
    output wire busy,                   // initialization/read active
    output wire ack_error               // latest I2C transaction was not ACKed
);
    ina226_driver #(.CLK_FREQ_HZ(CLK_FREQ_HZ),.I2C_FREQ_HZ(I2C_FREQ_HZ),
        .SAMPLE_PERIOD_US(SAMPLE_PERIOD_US),.I2C_ADDR(I2C_ADDR),
        .CONFIG(CONFIG),.CALIBRATION(CALIBRATION)) u_ina226(
        .clk(sys_clk),.rst_n(sys_rst_n),.i2c_scl(i2c_scl),.i2c_sda(i2c_sda),
        .bus_voltage_raw(bus_voltage_raw),.current_raw(current_raw),
        .sample_valid(sample_valid),.busy(busy),.ack_error(ack_error));
endmodule
