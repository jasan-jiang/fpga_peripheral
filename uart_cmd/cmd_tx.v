`timescale 1ns/1ps

module cmd_tx(
    input clk_50m,
    input rst_n,
    input [119:0] cmd,
    input cmd_tx_start,

    output  data_out,
    output reg cmd_tx_done,
    output reg cmd_tx_busy
);
    reg [3:0]   cmd_byte_cnt;
    reg [7:0]   cmd_part;
    reg tx_start;
    wire tx_done;
    wire tx_busy;

    uarttx u_uarttx(
        .clk_50m(clk_50m),
        .rst_n(rst_n),
        .data_in(cmd_part),
        .tx_start(tx_start),
        .data_out(data_out),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );
    
    always @(posedge clk_50m or negedge rst_n) begin
        if(!rst_n)begin
            cmd_tx_done<=1'b0;
            cmd_tx_busy<=1'b0;
            cmd_byte_cnt<=4'b0;
            tx_start<=1'b0;
        end else if(!tx_busy)begin
            tx_start<=1'b0;
            if(cmd_tx_start&&!cmd_tx_busy)begin
                cmd_tx_busy<=1'b1;
                cmd_part <= cmd[7:0];
                tx_start <= 1'b1;
                cmd_byte_cnt<=4'b1;
            end else if(cmd_tx_busy&&tx_done)begin
                case(cmd_byte_cnt)
                    //4'd0 : cmd_part <= cmd[7:0];      // head
                    4'd1 : cmd_part <= cmd[15:8];     // addr
                    4'd2 : cmd_part <= cmd[23:16];    // func
                    4'd3 : cmd_part <= cmd[31:24];    // ID0
                    4'd4 : cmd_part <= cmd[39:32];    // ID1
                    4'd5 : cmd_part <= cmd[47:40];    // ID2
                    4'd6 : cmd_part <= cmd[55:48];    // ID3
                    4'd7 : cmd_part <= cmd[63:56];    // ID4
                    4'd8 : cmd_part <= cmd[71:64];    // ID5
                    4'd9 : cmd_part <= cmd[79:72];    // ID6
                    4'd10: cmd_part <= cmd[87:80];    // ID7
                    4'd11: cmd_part <= cmd[95:88];    // ID8
                    4'd12: cmd_part <= cmd[103:96];   // ID9
                    4'd13: cmd_part <= cmd[111:104];  // check
                    4'd14: cmd_part <= cmd[119:112];  // tail
                    default: cmd_part <= 8'd0;
                endcase
                tx_start <= 1'b1;
                if(cmd_byte_cnt==4'd14&&tx_done)begin
                    cmd_tx_done<=1'b1;
                    cmd_tx_busy<=1'b0;
                    cmd_byte_cnt<=4'b0;
                end else begin
                    cmd_byte_cnt<=cmd_byte_cnt+1'b1;
                    tx_start<=1'b1;
                end
            end
        end
    end

endmodule
