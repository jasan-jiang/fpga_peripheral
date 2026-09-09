`timescale 1ns/1ps

module uarttx(
//500kbps 2us/bit       50mhz T=20ns N=100,100T/bit
//8n1
    input   clk_50m,
    input   rst_n,
    input   [7:0]  data_in,
    input   tx_start,

    output  reg data_out,
    output  reg tx_busy,
    output  reg tx_done
);
    reg [6:0]   cnt_clk;    //100clk/1bit
    reg [3:0]   cnt_bit;    //8n1 10bits
    reg [7:0]   data_reg;

    reg [1:0]   gap_cnt;    //

    reg start1;
    reg start2;
    wire start_rising;
    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n)begin
            start1<=1'b0;
            start2<=1'b0;
        end
        else begin
            start1<=tx_start;
            start2<=start1;
        end
    end
    assign start_rising=start1&~start2;

    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n)begin
            data_out<=1'b1;
            tx_busy<=1'b0;
            tx_done<=1'b0;
            cnt_clk<=7'b0;
            cnt_bit<=4'b0;
            gap_cnt<=2'b0;
        end
        else begin
            if(!tx_busy)begin
                data_out<=1'b1;
                tx_done <= 1'b0;
            end

            if(start_rising&&!tx_busy)begin
                data_reg<=data_in;
                cnt_clk<=7'b0;
                cnt_bit<=4'b0;
                tx_busy<=1'b1;
                data_out<=1'b0;
            end 
            else if(!tx_busy)begin
                data_out<=1'b1;
            end
            else if(tx_busy)begin
                if(cnt_clk==7'd99)begin
                    cnt_clk<=7'b0;
                    if(cnt_bit==4'd9)begin
                        cnt_bit<=4'b0;
                        gap_cnt<=2'b1;                  //
    //                   tx_busy<=1'b0;                 //
    //                   tx_done<=1'b1;                 //
                    end                
                    else                cnt_bit<=cnt_bit+1'b1;
                end
                else cnt_clk<=cnt_clk+1'b1;
            end
            
            if(gap_cnt) gap_cnt<=gap_cnt+1'b1; //
            if(gap_cnt==2'b11) begin                    //
                tx_busy<=1'b0;                          //
                tx_done<=1'b1;                          //
                gap_cnt<=2'b00;                         //
            end

            if(cnt_clk==7'd0&&tx_busy)begin
                case(cnt_bit)
                    1:  data_out<=data_reg[0];
                    2:  data_out<=data_reg[1];
                    3:  data_out<=data_reg[2];
                    4:  data_out<=data_reg[3];
                    5:  data_out<=data_reg[4];
                    6:  data_out<=data_reg[5];
                    7:  data_out<=data_reg[6];
                    8:  data_out<=data_reg[7];
                    9:  data_out<=1'b1;
                    default:;
                endcase
            end 
        end
        

    end



endmodule
