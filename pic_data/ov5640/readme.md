# OV5640 RGB565 经 UDP 传输

## 文件和顶层端口

- `ov5640_udp_pc.v`：顶层，连接 OV5640 SCCB、8-bit DVP 和 RGMII Ethernet PHY。
- `img_data_pkt.v`：将 DVP 字节流写入异步 FIFO，以每行一个 UDP 载荷的方式读出。
- `start_transfer_ctrl.v`：解析单字节 UDP 启停命令。

`sys_clk/sys_rst_n` 是板级时钟/低有效复位。`cam_pclk/cam_vsync/cam_href/cam_data[7:0]` 是 DVP 输入，`cam_scl/cam_sda` 是 SCCB，`cam_rst_n/cam_pwdn` 控制传感器。`eth_*` 为 RGMII PHY 端口。

## 操作流程

1. 在 Vivado 中加入父目录 README 列出的 Ethernet、SCCB、Clock Wizard 和 FIFO 依赖，将 `ov5640_udp_pc` 设为顶层。
2. 配置本机/电脑 MAC、IP，并将 FPGA 和电脑放在同一 IPv4 子网。
3. 上电后 SCCB 配置表初始化 OV5640。向 FPGA UDP 端口 1234 发送单字节 ASCII `1` (`8'h31`) 开始，发 ASCII `0` (`8'h30`) 停止。
4. PC 按 UDP 载荷拼图。第一行包为 `F0 5A A5 0F` + 宽度大端 2 字节 + 高度大端 2 字节 + `2*width` 个 RGB565 原始字节；后续行包为 `2*width` 字节。

## 改输入、分辨率或格式

| 需求 | 改哪里 |
|---|---|
| MAC/IP | `ov5640_udp_pc.v` 参数 `BOARD_MAC/BOARD_IP/DES_MAC/DES_IP` |
| 分辨率 | 改顶层 `H_CMOS_DISP/V_CMOS_DISP/TOTAL_H_PIXEL/TOTAL_V_PIXEL` 以及 OV5640 寄存器表；还必须把 H/V 传给 `img_data_pkt` 的 `CMOS_H_PIXEL/CMOS_V_PIXEL` |
| SCCB 地址/速率 | `SLAVE_ADDR/BIT_CTRL/CLK_FREQ/I2C_FREQ`，OV5640 通常使用 16-bit 寄存器地址 |
| RGB565 改 RAW/YUV/JPEG | 先改 `i2c_ov5640_rgb565_cfg` 寄存器表；再在 `img_data_pkt.v` 把每行长度从 `{CMOS_H_PIXEL,1'b0}` 改为实际 bytes-per-line。JPEG 是变长格式，不能继续按固定行长打包 |
| 改帧头 | `img_data_pkt.IMG_FRAME_HEAD`，对应 PC 解包器也要改 |
| 改启停命令 | `start_transfer_ctrl.START/STOP`；参数是 ASCII 字符而不是数值 1/0 |
| 改 UDP 端口 | `udp/udp_tx.v` 的 `ip_head[5]`，见 `udp/readme.md` |
| 数据输入改 10/12/16 bit | 建议在 `cam_pclk` 域先转成字节流，再送 `img_data_pkt`；同时重算行字节数和 FIFO 带宽 |

重要：当前 `ov5640_udp_pc.v` 声明的 `udp_tx_data/udp_rec_data` 为 32 位，但下层 `img_data_pkt` 和 `eth_top` 实际是 8 位，因此真正有效格式仍是逐字节。如需 32-bit 通路，必须连同 UDP/FIFO/keep/last 握手整体改造，不能只改这两根 wire。另外，顶层 H/V 参数当前没有在 `img_data_pkt` 实例上覆盖，更换分辨率时必须补上参数传递。
