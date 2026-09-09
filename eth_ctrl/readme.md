# Ethernet 顶层与 ARP/UDP 仲裁

## 文件

- `eth_top.v`：整体入口，连接 RGMII PHY、ARP、UDP 和发送仲裁。
- `eth_ctrl.v`：当 ARP 应答和 UDP 同时需要 GMII TX 时选择通道，UDP 发送期间不插入 ARP。

`eth_top.v` 不是单文件可编译顶层，还必须加入 `gmii_to_rgmii/*.v`、`arp/*.v`、`udp/*.v`。其中 RGMII 模块使用 Xilinx 7 系列原语。

## 操作方式

- `clk_200m` 必须是 IDELAYCTRL 参考时钟，`sys_rst_n` 为低有效复位。
- PHY 连到 `eth_rxc/eth_rx_ctl/eth_rxd` 和 `eth_txc/eth_tx_ctl/eth_txd`；`eth_rst_n` 目前直接跟随 `sys_rst_n`。
- 发 UDP 时在 `gmii_tx_clk` 域提交 `udp_tx_start_en/tx_byte_num`，响应 `tx_req` 给出 `tx_data`，等待 `udp_tx_done`。
- 收 UDP 时在 `gmii_rx_clk` 域使用 `rec_en/rec_data/rec_byte_num/rec_pkt_done`。
- 当收到对本机的 ARP 请求，`eth_ctrl` 会自动安排应答；UDP 动态目标 MAC/IP 取最近解析到的 ARP 源地址。

## 修改指南

| 需求 | 改哪里 |
|---|---|
| 网卡地址 | 实例化 `eth_top` 时设 `BOARD_MAC/BOARD_IP/DES_MAC/DES_IP` |
| PHY RX 采样相位 | 调整 `eth_top.IDELAY_VALUE`（0～31），配合时序报告和板级走线，不要盲目设置 |
| 更换 PHY/FPGA 家族 | 替换 `gmii_to_rgmii` 中 BUFG/BUFIO/IDELAYE2/IDDR/ODDR 及约束；其他厂商不能直接综合 |
| 改 UDP 数据格式 | 字节流接口不变时只改上层打包/解包；改网络头则参考 `udp/readme.md` |
| 增加 ICMP/TCP/多发送源 | 在 `eth_ctrl.v` 增加仲裁状态和完整的 busy/done 握手，不能只用组合 mux |

当前 `eth_ctrl` 的控制时钟接 `gmii_rx_clk`，而 UDP TX 状态来自 TX 域。若 RX/TX 时钟并非同源，应在 `udp_tx_start_en/udp_tx_done` 等控制线上增加脉冲同步或异步握手。
