# ARP 收发模块

## 入口和文件

- `arp.v`：建议实例化的顶层，组合接收、发送和 CRC。
- `arp_rx.v`：从 8 位 GMII 字节流解析 ARP 请求/应答。
- `arp_tx.v`：生成前导码、以太网头、ARP 载荷、填充和 FCS。
- `crc32_d8.v`：每时钟处理 1 字节的 Ethernet CRC-32。UDP 目录也依赖该文件。

## 怎么操作

GMII 接收侧在 `gmii_rx_clk` 下输入 `gmii_rx_dv` 和 `gmii_rxd[7:0]`。当收到发往本机的 ARP 包时，`arp_rx_done` 脉冲一周期，`arp_rx_type=0` 为请求、`1` 为应答，`src_mac/src_ip` 给出对端地址。

发送时先稳定 `arp_tx_type`、`des_mac`、`des_ip`，再给 `arp_tx_en` 一个 `gmii_tx_clk` 周期的高脉冲。`arp_tx_type=0` 发请求，`1` 发应答；保持参数稳定直到 `tx_done`。输出为 `gmii_tx_en + gmii_txd[7:0]`。

## 不同地址或格式怎么改

| 需求 | 修改位置 |
|---|---|
| 修改本机 MAC/IP | 实例化 `arp` 时覆盖 `BOARD_MAC`、`BOARD_IP`；不要只改子模块默认值 |
| 默认目标 MAC/IP | 覆盖 `DES_MAC`、`DES_IP`，或在运行时使用 `des_mac/des_ip` 端口 |
| 改非 Ethernet/IPv4 ARP 格式 | 在 `arp_tx.v` 修改 `ETH_TYPE`、`HD_TYPE`、`PROTOCOL_TYPE` 和 `arp_data[]`；在 `arp_rx.v` 同步修改类型检查和字节计数 |
| 改总线位宽 | 当前状态机固定为 8-bit GMII；需同时重写 `arp_rx.v`/`arp_tx.v` 的字节索引和 CRC 并行宽度 |

所有多字节网络字段均按高字节先发。`crc32_d8.v` 针对 Ethernet FCS，不能直接当作普通文件 CRC 使用。
