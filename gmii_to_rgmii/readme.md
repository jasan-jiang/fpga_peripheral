# GMII 与 RGMII 转换

## 结构与操作

`gmii_to_rgmii.v` 是顶层，`rgmii_rx.v` 用 IDDR 将 RGMII 上下沿 4-bit 数据拼成 8-bit GMII，`rgmii_tx.v` 用 ODDR 将 8-bit GMII 拆成 RGMII。

- `idelay_clk`：严格的 200 MHz IDELAYCTRL 参考时钟。
- RX：PHY 输入 `rgmii_rxc/rgmii_rx_ctl/rgmii_rxd[3:0]`，输出 `gmii_rx_clk/gmii_rx_dv/gmii_rxd[7:0]`。
- TX：在 `gmii_tx_clk` 下输入 `gmii_tx_en/gmii_txd[7:0]`，生成 `rgmii_txc/rgmii_tx_ctl/rgmii_txd[3:0]`。

本实现包含 Xilinx 7 系列 `BUFG`、`BUFIO`、`IDELAYCTRL`、`IDELAYE2`、`IDDR`、`ODDR` 原语，仿真时需加入 UNISIM 库。

## 输入、时序或器件变化

| 变化 | 修改位置 |
|---|---|
| RX 相位/板级延迟 | 覆盖 `gmii_to_rgmii.IDELAY_VALUE`，它传入 `rgmii_rx.v` 的时钟和 4 根数据 IDELAYE2 |
| 参考时钟不是 200 MHz | 不只改端口；同时改 `IDELAYE2.REFCLK_FREQUENCY`，并确认该 FPGA 支持的范围 |
| 改成 RGMII-ID/TXID/RXID PHY | 根据 PHY 内部延迟模式决定 FPGA 是否还需 IDELAY/时钟相移，避免重复延迟 |
| 更换 UltraScale/Intel/Gowin 等 | 用目标平台的 DDR I/O、时钟缓冲和 delay-control 原语重写 `rgmii_rx.v/rgmii_tx.v` |
| 需要 RX_ER/TX_ER | RGMII control 的上下沿还包含错误编码；当前只输出 `gmii_rx_dv`/输入 `gmii_tx_en`，需扩展 IDDR/ODDR control 逻辑 |

最终 `IDELAY_VALUE`、时钟相位和 I/O 标准必须以原理图、PHY strap 配置和 STA/板级测试为准。
