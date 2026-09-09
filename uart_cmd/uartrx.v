`timescale 1ns/1ps

module uart_rx(     
//500kbps 2us/bit       50mhz T=20ns N=100,100T/bit
//8n1
    input   clk_50m,
    input   data_in,
    input   rst_n,
    output  reg [7:0]    data_out,
    output  reg rx_done,
    output  reg rx_busy
);
    reg data1;
    reg data2;
    wire data_falling;

    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n)begin
            data1<=1'b1;
            data2<=1'b1;
        end
        else begin
            data1<=data_in;
            data2<=data1;
        end
    end

    assign data_falling=data2&~data1;

    reg [6:0]   cnt_clk;    //100clk/1bit
    reg [3:0]   cnt_bit;    //8n1 10bits
    reg         stop_right;

    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n)begin
            cnt_bit<=4'b0;
            cnt_clk<=7'b0;
            rx_done<=1'b0;
            rx_busy<=1'b0;
            data_out<=8'b0;
            stop_right<=1'b0;
        end
        else if(!rx_busy && data_falling)begin
            rx_busy<=1;
            cnt_bit<=4'b0;
            cnt_clk<=7'b0;
            stop_right<=1'b0;
        end
        else if(rx_busy)begin
            rx_done<=1'b0;
            if(cnt_bit==4'd9&&cnt_clk==7'd99)begin
                cnt_clk<=7'd0;
                cnt_bit<=4'b0;
                rx_busy<=1'b0;
                if(stop_right)  rx_done<=1'b1;
                else begin
                    rx_done<=1'b0;
                    data_out<=8'b0;
                end            
            end
            else if(cnt_clk==7'd99)begin
                cnt_clk<=7'd0;
                cnt_bit<=cnt_bit+1'b1;
            end
            else begin
                cnt_clk<=cnt_clk+1'b1;
            end
        end
         //低位先发 pl:0xa3:10100011 发送顺序11000101
        if(cnt_clk==7'd49)begin
            case(cnt_bit)
                1:data_out[0]<=data2;
                2:data_out[1]<=data2;
                3:data_out[2]<=data2;
                4:data_out[3]<=data2;
                5:data_out[4]<=data2;
                6:data_out[5]<=data2;
                7:data_out[6]<=data2;
                8:data_out[7]<=data2;
                9:stop_right<=data2;
                default:;
            endcase
        end
    end



endmodule
