//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           ip_fifo
// Last modified Date:  2019/05/10 11:31:26
// Last Version:        V1.0
// Descriptions:        FIFO实验顶层模块
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/05/10 11:31:51
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module ip_fifo(
    input    sys_clk ,  // 系统时钟信号
    input    sys_rst_n  // 系统复位信号
);

//wire define
wire         clk_50m       ;  // 50M时钟
wire         clk_100m      ;  // 100M时钟
wire         locked        ;  // 时钟锁定信号
wire         rst_n         ;  // 复位，低有效
wire         wr_rst_busy   ;  // 写复位忙信号
wire         rd_rst_busy   ;  // 读复位忙信号
wire         fifo_wr_en    ;  // FIFO写使能信号
wire         fifo_rd_en    ;  // FIFO读使能信号
wire  [7:0]  fifo_wr_data  ;  // 写入到FIFO的数据
wire  [7:0]  fifo_rd_data  ;  // 从FIFO读出的数据
wire         almost_full   ;  // FIFO将满信号
wire         almost_empty  ;  // FIFO将空信号
wire         full          ;  // FIFO满信号
wire         empty         ;  // FIFO空信号
wire  [7:0]  wr_data_count ;  // FIFO写时钟域的数据计数
wire  [7:0]  rd_data_count ;  // FIFO读时钟域的数据计数

//*****************************************************
//**                    main code
//*****************************************************

//通过系统复位信号和时钟锁定信号来产生一个新的复位信号
assign   rst_n = sys_rst_n & locked;

//例化PLL IP核
clk_wiz_0 clk_wiz_0 (
    // Clock out ports
    .clk_out1(clk_50m ),  // output clk_out1
    .clk_out2(clk_100m),  // output clk_out2
    // Status and control signals
    .locked  (locked  ),  // output locked
    // Clock in ports
    .clk_in1 (sys_clk )   // input clk_in1
);     
  
//例化FIFO IP核
fifo_generator_0  fifo_generator_0 (
    .rst           (~rst_n       ),  // input wire rst
    .wr_clk        (clk_50m      ),  // input wire wr_clk
    .rd_clk        (clk_100m     ),  // input wire rd_clk
    .wr_en         (fifo_wr_en   ),  // input wire wr_en
    .rd_en         (fifo_rd_en   ),  // input wire rd_en
    .din           (fifo_wr_data ),  // input wire [7 : 0] din
    .dout          (fifo_rd_data ),  // output wire [7 : 0] dout
    .almost_full   (almost_full  ),  // output wire almost_full
    .almost_empty  (almost_empty ),  // output wire almost_empty
    .full          (full         ),  // output wire full
    .empty         (empty        ),  // output wire empty
    .wr_data_count (wr_data_count),  // output wire [7 : 0] wr_data_count   
    .rd_data_count (rd_data_count),  // output wire [7 : 0] rd_data_count
    .wr_rst_busy   (wr_rst_busy  ),  // output wire wr_rst_busy
    .rd_rst_busy   (rd_rst_busy  )   // output wire rd_rst_busy
);

//例化写FIFO模块
fifo_wr  u_fifo_wr (
    .wr_clk        (clk_50m     ), // 写时钟
    .rst_n         (rst_n       ), // 复位信号
    .wr_rst_busy   (wr_rst_busy ), // 写复位忙信号
    .fifo_wr_en    (fifo_wr_en  ), // fifo写请求
    .fifo_wr_data  (fifo_wr_data), // 写入FIFO的数据
    .empty         (empty       ), // fifo空信号
    .almost_full   (almost_full )  // fifo将满信号
);

//例化读FIFO模块
fifo_rd  u_fifo_rd (
    .rd_clk       (clk_100m    ),  // 读时钟
    .rst_n        (rst_n       ),  // 复位信号
    .rd_rst_busy  (rd_rst_busy ),  // 读复位忙信号
    .fifo_rd_en   (fifo_rd_en  ),  // fifo读请求
    .fifo_rd_data (fifo_rd_data),  // 从FIFO输出的数据
    .almost_empty (almost_empty),  // fifo将空信号
    .full         (full        )   // fifo满信号
);

//写时钟域下ila
ila_0 u_ila_wr (
    .clk       (clk_50m      ), // input wire clk

    .probe0    (fifo_wr_en   ), // input wire [0:0]  probe0  
    .probe1    (fifo_wr_data ), // input wire [7:0]  probe1 
    .probe2    (almost_full  ), // input wire [0:0]  probe2 
    .probe3    (full         ), // input wire [0:0]  probe3 
    .probe4    (wr_data_count)  // input wire [7:0]  probe4
);

//读时钟域下ila
ila_1 u_ila_rd (
    .clk       (clk_100m     ), // input wire clk

    .probe0    (fifo_rd_en   ), // input wire [0:0]  probe0  
    .probe1    (fifo_rd_data ), // input wire [7:0]  probe1 
    .probe2    (almost_empty ), // input wire [0:0]  probe2 
    .probe3    (empty        ), // input wire [0:0]  probe3 
    .probe4    (rd_data_count)  // input wire [7:0]  probe4
);

endmodule 