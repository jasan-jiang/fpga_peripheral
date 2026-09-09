`timescale 1ns/1ps

module cmd_rx( 
    input   clk_50m,
    input   rst_n,
    input   data_in,
    output  reg     [119:0]  cmd_cout,
    output  reg     cmd_rx_done,
    output  reg     cmd_rx_busy
);

//head	    addr    func    ID0	ID1	ID2	ID3	ID4	ID5	ID6	ID7	ID8	ID9     check   tail
//8*15=120bit
    reg     [3:0]   cmd_cnt;            //0-15 1111 
    reg     [15:0]  cmd_timeout_cnt;   
    wire     [7:0]   data_out;
    wire         rx_done;
    wire         rx_busy;

    uart_rx u_uart_rx(
        .clk_50m(clk_50m),
        .data_in(data_in),
        .rst_n(rst_n),
        .data_out(data_out),
        .rx_done(rx_done),
        .rx_busy(rx_busy)
    );
    reg rx_done1;
    wire rx_rise;
    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n)  rx_done1<=1'b0;
        else        rx_done1<=rx_done;
    end
    assign rx_rise=rx_done&~rx_done1;
    
    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n)begin
            cmd_cout<=120'b0;
            cmd_rx_done<=1'b0;
            cmd_cnt<=4'b0;
            cmd_rx_busy<=1'b0;
            cmd_timeout_cnt<=14'b0;
        end else if(rx_rise)begin
            cmd_rx_done<=1'b0;
            case(cmd_cnt)
                4'd0 : begin    cmd_cout[7:0]   <= data_out;     // head
                                cmd_rx_busy     <= 1'b1;
                end
                4'd1 : cmd_cout[15:8]  <= data_out;    // add
                4'd2 : cmd_cout[23:16] <= data_out;    // fun
                4'd3 : cmd_cout[31:24] <= data_out;    // ID0
                4'd4 : cmd_cout[39:32] <= data_out;    // ID1
                4'd5 : cmd_cout[47:40] <= data_out;    // ID2
                4'd6 : cmd_cout[55:48] <= data_out;    // ID3
                4'd7 : cmd_cout[63:56] <= data_out;    // ID4
                4'd8 : cmd_cout[71:64] <= data_out;    // ID5
                4'd9 : cmd_cout[79:72] <= data_out;    // ID6
                4'd10: cmd_cout[87:80] <= data_out;    // ID7
                4'd11: cmd_cout[95:88] <= data_out;    // ID8
                4'd12: cmd_cout[103:96] <= data_out;   // ID9
                4'd13: cmd_cout[111:104] <= data_out;  // check
                4'd14: begin    cmd_cout[119:112] <= data_out;   // tail
                                cmd_rx_done<=1'b1;
                                cmd_rx_busy<=1'b0;
                end 
                default: ;
            endcase
            if(cmd_cnt<4'd14)begin
                cmd_cnt<=cmd_cnt+1'b1;
            end else cmd_cnt<=4'b0;
        end
        if(cmd_timeout_cnt>=16'd45300)begin
            cmd_cout<=120'b0;
            cmd_rx_done<=1'b0;
            cmd_cnt<=4'b0;
            cmd_rx_busy<=1'b0;
            cmd_timeout_cnt<=16'b0;
        end else if(!cmd_rx_busy)begin
            cmd_timeout_cnt<=16'b0;
        end else if(cmd_rx_busy)begin
            cmd_timeout_cnt<=cmd_timeout_cnt+1'b1;
        end 
    end
    

endmodule
