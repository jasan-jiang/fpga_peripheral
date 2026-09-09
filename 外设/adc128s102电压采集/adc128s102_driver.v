`timescale 1ns/1ps

// Parameterized SPI-mode-3 reader for one of several ADC128S102 devices.
module adc128s102_driver #(
    parameter integer CLK_FREQ_HZ = 50_000_000,
    parameter integer SCLK_FREQ_HZ = 8_000_000,
    parameter integer DEVICE_COUNT = 1
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         start,
    input  wire [2:0]                   channel,
    input  wire [1:0]                   device_select,
    input  wire [DEVICE_COUNT-1:0]      adc_dout,
    output wire [DEVICE_COUNT-1:0]      adc_sclk,
    output reg  [DEVICE_COUNT-1:0]      adc_cs_n,
    output reg  [DEVICE_COUNT-1:0]      adc_din,
    output reg  [11:0]                  sample_data,
    output reg                          sample_valid,
    output reg                          busy
);
    localparam integer HALF_PERIOD = CLK_FREQ_HZ / (2*SCLK_FREQ_HZ);
    localparam integer DIV_WIDTH = (HALF_PERIOD <= 1) ? 1 : $clog2(HALF_PERIOD);

    reg [DIV_WIDTH-1:0] div_count;
    reg [4:0] bit_count;
    reg [2:0] channel_latched;
    reg [1:0] device_latched;
    reg sclk_int;
    reg [11:0] shift_data;
    assign adc_sclk = busy ? {DEVICE_COUNT{sclk_int}} : {DEVICE_COUNT{1'b1}};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            div_count       <= {DIV_WIDTH{1'b0}};
            bit_count       <= 5'd0;
            channel_latched <= 3'd0;
            device_latched  <= 2'd0;
            sclk_int        <= 1'b1;
            adc_cs_n        <= {DEVICE_COUNT{1'b1}};
            adc_din         <= {DEVICE_COUNT{1'b0}};
            shift_data      <= 12'd0;
            sample_data     <= 12'd0;
            sample_valid    <= 1'b0;
            busy            <= 1'b0;
        end else begin
            sample_valid <= 1'b0;
            if (!busy) begin
                sclk_int <= 1'b1;
                adc_cs_n <= {DEVICE_COUNT{1'b1}};
                adc_din  <= {DEVICE_COUNT{1'b0}};
                div_count <= {DIV_WIDTH{1'b0}};
                if (start && (device_select < DEVICE_COUNT)) begin
                    busy            <= 1'b1;
                    bit_count       <= 5'd0;
                    channel_latched <= channel;
                    device_latched  <= device_select;
                    shift_data      <= 12'd0;
                    adc_cs_n[device_select] <= 1'b0;
                end
            end else if ((HALF_PERIOD <= 1) || (div_count == HALF_PERIOD-1)) begin
                div_count <= {DIV_WIDTH{1'b0}};
                if (sclk_int) begin
                    // Falling edge: ADC samples DIN. Address occupies clocks 3..5.
                    sclk_int <= 1'b0;
                    adc_din <= {DEVICE_COUNT{1'b0}};
                    if ((bit_count >= 5'd2) && (bit_count <= 5'd4))
                        adc_din[device_latched] <= channel_latched[4-bit_count];
                end else begin
                    // Rising edge: FPGA samples DOUT; result is on clocks 5..16.
                    sclk_int <= 1'b1;
                    if (bit_count >= 5'd4)
                        shift_data <= {shift_data[10:0], adc_dout[device_latched]};
                    if (bit_count == 5'd15) begin
                        sample_data <= {shift_data[10:0], adc_dout[device_latched]};
                        sample_valid <= 1'b1;
                        busy <= 1'b0;
                        adc_cs_n <= {DEVICE_COUNT{1'b1}};
                    end else begin
                        bit_count <= bit_count + 1'b1;
                    end
                end
            end else begin
                div_count <= div_count + 1'b1;
            end
        end
    end
endmodule
