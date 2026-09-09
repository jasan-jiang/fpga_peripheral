//****************************************Copyright (c)***********************************//
//原子哥在线教学平台：www.yuanzige.com
//技术支持：www.openedv.com
//淘宝店铺：http://openedv.taobao.com
//关注微信公众平台微信号："正点原子"，免费获取ZYNQ & FPGA & STM32 & LINUX资料。
//版权所有，盗版必究。
//Copyright(C) 正点原子 2018-2028
//All rights reserved
//----------------------------------------------------------------------------------------
// File name:           fifo_rd
// Last modified Date:  2019/05/10 13:38:04
// Last Version:        V1.0
// Descriptions:        读FIFO模块
//----------------------------------------------------------------------------------------
// Created by:          正点原子
// Created date:        2019/05/10 13:38:14
// Version:             V1.0
// Descriptions:        The original version
//
//----------------------------------------------------------------------------------------
//****************************************************************************************//

module fifo_rd(
    //system clock
    input               rd_clk      , //时钟信号
    input               rst_n       , //复位信号
    //FIFO interface
    input               rd_rst_busy , //读复位忙信号
    input        [7:0]  fifo_rd_data, //从FIFO读出的数据
    input               full        , //FIFO满信号
    input               almost_empty, //FIFO将空信号
    output  reg         fifo_rd_en    //FIFO读使能
);

//reg define
reg       full_d0;
reg       full_d1;

//*****************************************************
//**                    main code
//*****************************************************

//因为full信号是属于FIFO写时钟域的
//所以对full打两拍同步到读时钟域下
always @(posedge rd_clk or negedge rst_n) begin
    if(!rst_n) begin
        full_d0 <= 1'b0;
        full_d1 <= 1'b0;
    end
    else begin
        full_d0 <= full;
        full_d1 <= full_d0;
    end
end    
    
//对fifo_rd_en进行赋值,FIFO写满之后开始读，读空之后停止读
always @(posedge rd_clk or negedge rst_n) begin
    if(!rst_n) 
        fifo_rd_en <= 1'b0;
    else if(!rd_rst_busy) begin
        if(full_d1)
           fifo_rd_en <= 1'b1;
        else if(almost_empty)
           fifo_rd_en <= 1'b0; 
    end
    else
        fifo_rd_en <= 1'b0;
end

endmodule