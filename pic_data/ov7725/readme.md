# OV7725 RGB565 经 UDP 传输

## 文件和顶层

- `ov7725_udp_pc.v`：整机顶层，连接 OV7725 DVP/SCCB 和 RGMII PHY。
- `img_data_pkt.v`：跨 `cam_pclk` 与 Ethernet TX 时钟域缓存图像，按行发 UDP。
- `start_transfer_ctrl.v`：通过 UDP 单字节命令启停。

`cam_pclk/cam_vsync/cam_href/cam_data[7:0]` 是摄像头输入，`cam_scl/cam_sda` 连 SCCB，`cam_rst_n` 保持摄像头退出复位，`cam_sgm_ctrl=1` 选摄像头自带晶振。`eth_*` 是 RGMII PHY。

## 操作和 PC 数据格式

1. 加入 `pic_data/readme.md` 中列出的 IP 和共公 RTL，将 `ov7725_udp_pc` 设为顶层。
2. 设置 MAC/IP 和管脚约束。上电后 `i2c_ov7725_rgb565_cfg` 初始化摄像头。
3. 向 UDP 端口 1234 发 1 字节 ASCII `1` (`0x31`) 开始传图，发 ASCII `0` (`0x30`) 停止。
4. 默认 640×480 RGB565。每帧第一个行包前加 8 字节：`F0 5A A5 0F 02 80 01 E0`（帧头、大端宽高），随后是 1280 字节像素；后续行包为 1280 字节。

## 怎么改

| 输入/格式 | 修改位置 |
|---|---|
| MAC/IP | `ov7725_udp_pc.v` 的 `BOARD_MAC/BOARD_IP/DES_MAC/DES_IP` |
| SCCB | `SLAVE_ADDR=7'h21`、`BIT_CTRL=0`、`CLK_FREQ/I2C_FREQ`；更换摄像头时地址和寄存器地址宽度都要核对 |
| 分辨率 | 改 `img_data_pkt.CMOS_H_PIXEL/CMOS_V_PIXEL`，并在 `i2c_ov7725_rgb565_cfg` 的寄存器表中配置同样的输出尺寸 |
| 像素不是 RGB565 | 修改摄像头寄存器表，并把 `img_data_pkt.v` 中的 `{CMOS_H_PIXEL,1'b0}` 替换为每行实际字节数 |
| 帧头/宽高字节序 | 修改 `IMG_FRAME_HEAD` 和 `head_cnt` 对应的 `wr_fifo_data`，PC 同步改解包 |
| 启停命令 | `start_transfer_ctrl.START/STOP`，当前只接受长度为 1 的 UDP 载荷 |
| 增加包序号/行号 | 在 `img_data_pkt.v` 的帧头/行头写 FIFO 逻辑中增加字段，同时增加 `udp_tx_byte_num` 并调整 FIFO 阈值 |

`img_data_pkt` 假设 2 bytes/pixel 且每行能装入一个 UDP 包。增大水平分辨率时要确保载荷不超过 UDP/IP/Ethernet 及接收端的 MTU；超过时应一行拆多包并加帧/行/分包序号。

注意：OV5640 和 OV7725 目录都定义了同名 `img_data_pkt` 和 `start_transfer_ctrl`，一个 Vivado fileset 中只加入当前使用的一组，或先重命名模块。
