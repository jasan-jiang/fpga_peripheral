# Verilog 通用模块库

仓库按功能分目录保存可复用 RTL。每个代码目录都有 `readme.md`，说明入口模块、操作时序、数据格式、工程依赖，以及更换时钟/位宽/地址/协议时应修改的代码。

| 目录 | 主要内容 |
|---|---|
| [`arp`](./arp/readme.md) | ARP 收发和 Ethernet CRC |
| [`udp`](./udp/readme.md) | GMII 上的 Ethernet/IPv4/UDP 字节流 |
| [`eth_ctrl`](./eth_ctrl/readme.md) | RGMII + ARP + UDP 整体顶层和 TX 仲裁 |
| [`gmii_to_rgmii`](./gmii_to_rgmii/readme.md) | Xilinx 7 系列 GMII/RGMII DDR 转换 |
| [`EEPROM`](./EEPROM/readme.md) | I²C EEPROM 读写测试和底层驱动 |
| [`fifo`](./fifo/readme.md) | 异步 FIFO 读写演示 |
| [`uart_cmd`](./uart_cmd/readme.md) | 500 kbaud UART 和 15 字节命令帧 |
| [`pic_data`](./pic_data/readme.md) | OV5640/OV7725 RGB565 经 UDP 传输 |
| [`外设`](./外设/readme.md) | ADC、电流/电压监测、比较器和 LVDS 外设 |

## 集成建议

1. 先阅读目标目录 README 的“依赖”部分，不要把所有 `.v` 一次性加入同一 fileset；部分摄像头模块同名，部分演示依赖未收录的 Vivado IP。
2. 先改时钟、复位、地址、位宽和数据格式，然后添加管脚/XDC 及时序约束。
3. 对每个时钟域单独做时序分析；跨域数据使用异步 FIFO，控制脉冲使用标准 CDC 握手。
