# UDP/IPv4 over GMII

## 文件和接口

- `udp.v`：顶层，组合 `udp_rx`、`udp_tx` 和 `crc32_d8`。
- `udp_rx.v`：解析 Ethernet II + IPv4 + UDP，输出载荷字节流。
- `udp_tx.v`：生成 Ethernet/IPv4/UDP 帧。
- `fifo_udp_tx.v`：FIFO + UDP 批量发送顶层；实例化工程中的 `fifo_generator_0` IP，FIFO 中至少有 50 个 32-bit 字时自动发送 200 字节。

编译时还需加入 `arp/crc32_d8.v`。本模块接受 8-bit GMII，它不包含 PHY 的 RGMII 转换或 ARP 调度。

## 发送操作

1. 在 `gmii_tx_clk` 域设置 `tx_byte_num`、`des_mac`、`des_ip`，给 `tx_start_en` 一周期脉冲。地址端口为 0 时使用参数默认值。
2. 模块用 `tx_req` 逐字节请求载荷；上层应在每个有效请求上提供下一个 `tx_data[7:0]`。最好用 FWFT FIFO 或先将第一字节放到输出。
3. `tx_done` 表示包括 FCS 在内的帧已发完。载荷小于 18 字节时会自动填充，UDP 长度仍使用真实 `tx_byte_num`。

## 接收操作

`rec_en=1` 的每个 `gmii_rx_clk` 周期，`rec_data[7:0]` 是一个 UDP 载荷字节。`rec_byte_num` 给出载荷长度，`rec_pkt_done` 在包结束时脉冲。上层应在 `rec_en` 下自行计数和缓存。

## 修改点

| 输入/格式变化 | 修改位置 |
|---|---|
| 本机 MAC/IP | `udp` 顶层参数 `BOARD_MAC`、`BOARD_IP` |
| 默认目标 | `DES_MAC`、`DES_IP`；动态目标优先用端口 |
| UDP 源/目的端口 | `udp_tx.v` 中 `ip_head[5] <= {16'd1234,16'd1234}`；当前 RX 不输出也不过滤端口，需在 `udp_rx.v` 的 UDP 头状态增加保存/比较 |
| 带 VLAN、IPv4 options 或非 UDP | `udp_rx.v` 使用固定 14+20+8 字节头，需改 `st_eth_head/st_ip_head/st_udp_head` 计数；TX 同步改 `ip_head[]` 和长度/校验和 |
| 启用 UDP checksum | 当前写 `16'h0000`；需在 `udp_tx.v` 为伪首部+载荷计算校验和，RX 也需增加验证 |
| 16/32/64 位载荷 | 建议在模块外做宽度转换；直改本模块需重算字节有效、尾字节和 CRC |

当前接收检查主要协议字段和本机地址，不等同于完整网络栈；用于复杂网络前应增加长度、checksum 和异常帧验证。

## 32-bit FIFO 每 50 条自动发送

先在 Vivado 中创建名为 `fifo_generator_0` 的 FIFO Generator IP，配置为 Common Clock / Native Interface、32-bit 输入输出、深度 1024、Standard Read Mode、同步高有效 `srst`，并开启 `full`、`empty` 和 10-bit `data_count`。IP 端口名必须为 `full/din/wr_en/empty/dout/rd_en/data_count/clk/srst`。

将 `fifo_udp_tx` 设为应用顶层或实例化到 Ethernet 工程中。`clk` 同时是 FIFO 和 UDP GMII TX 时钟，`srst` 为高有效同步复位。写入时，在 `full=0` 时将 `din[31:0]` 与 `wr_en=1` 保持一个时钟周期；顶层也会内部屏蔽满时写入。

当 `data_count>=50` 时，模块自动读出恰好 50 个字，转成 200 字节 UDP 载荷并发送。`batch_busy=1` 表示正在预取或发送，`udp_tx_done` 是帧完成脉冲。若 FIFO 在上一包期间又累积至 50 条，返回空闲后会继续发下一包。

默认 `MSB_FIRST=1`，一个 `32'h11223344` 在 UDP 载荷中为 `11 22 33 44`；设 `MSB_FIRST=0` 则为 `44 33 22 11`。`des_mac/des_ip` 为 0 时使用 `DES_MAC/DES_IP` 参数。

FIFO 深度为 1024，但指定的 `data_count[9:0]` 无法同时表示 0～1024。满状态的具体 `data_count` 值取决于 FIFO Generator IP 配置，判断全满必须使用 `full`。如改 `BATCH_WORDS`，该值必须至少为 2，且 `BATCH_WORDS*4` 不能超过 UDP 16-bit 长度上限。

编译 `fifo_udp_tx` 时需加入 `fifo_udp_tx.v`、`udp.v`、`udp_tx.v`、`udp_rx.v`、`arp/crc32_d8.v` 以及 Vivado 生成的 `fifo_generator_0` IP。
