`timescale 1ns/1ps

// Parameterized AD7984 conversion controller and 18-bit serial reader.
module ad7984_driver #(
    parameter integer CLK_FREQ_HZ = 50_000_000,
    parameter integer SCLK_FREQ_HZ = 10_000_000,
    parameter integer CNV_HIGH_NS  = 600
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire        adc_sdo,
    output reg         adc_cnv,
    output reg         adc_sclk,
    output reg  [17:0] sample_data,
    output reg         sample_valid,
    output reg         busy
);
    localparam integer HALF_PERIOD = CLK_FREQ_HZ / (2*SCLK_FREQ_HZ);
    localparam integer CNV_CYCLES = ((CLK_FREQ_HZ/1_000_000)*CNV_HIGH_NS + 999) / 1000;
    localparam integer DIV_WIDTH = (HALF_PERIOD <= 1) ? 1 : $clog2(HALF_PERIOD);
    localparam integer CNV_WIDTH = (CNV_CYCLES <= 1) ? 1 : $clog2(CNV_CYCLES+1);

    localparam ST_IDLE = 2'd0, ST_CONVERT = 2'd1, ST_SHIFT = 2'd2;
    reg [1:0] state;
    reg [DIV_WIDTH-1:0] div_count;
    reg [CNV_WIDTH-1:0] cnv_count;
    reg [4:0] bit_count;
    reg [17:0] shift_data;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_IDLE; div_count <= 0; cnv_count <= 0; bit_count <= 0;
            adc_cnv <= 1'b0; adc_sclk <= 1'b0; shift_data <= 0;
            sample_data <= 0; sample_valid <= 1'b0; busy <= 1'b0;
        end else begin
            sample_valid <= 1'b0;
            case (state)
                ST_IDLE: begin
                    adc_cnv <= 1'b0; adc_sclk <= 1'b0; busy <= 1'b0;
                    if (start) begin
                        adc_cnv <= 1'b1; busy <= 1'b1; cnv_count <= 0;
                        state <= ST_CONVERT;
                    end
                end
                ST_CONVERT: begin
                    if ((CNV_CYCLES <= 1) || (cnv_count == CNV_CYCLES-1)) begin
                        adc_cnv <= 1'b0; div_count <= 0; bit_count <= 0;
                        shift_data <= 0; state <= ST_SHIFT;
                    end else cnv_count <= cnv_count + 1'b1;
                end
                ST_SHIFT: begin
                    if ((HALF_PERIOD <= 1) || (div_count == HALF_PERIOD-1)) begin
                        div_count <= 0;
                        if (!adc_sclk) begin
                            adc_sclk <= 1'b1;
                            shift_data <= {shift_data[16:0], adc_sdo};
                        end else begin
                            adc_sclk <= 1'b0;
                            if (bit_count == 5'd17) begin
                                sample_data <= {shift_data[16:0], adc_sdo}; sample_valid <= 1'b1;
                                busy <= 1'b0; state <= ST_IDLE;
                            end else bit_count <= bit_count + 1'b1;
                        end
                    end else div_count <= div_count + 1'b1;
                end
                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
