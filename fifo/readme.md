# 异步 FIFO 演示

## 内容和运行方式

- `ip_fifo.v`：演示顶层，使用 Clock Wizard 产生 50/100 MHz，对异步 FIFO 写入递增字节并读出。
- `fifo_wr.v`：当 FIFO 空时开始写，到 `almost_full` 停止，数据每次加 1。
- `fifo_rd.v`：当 FIFO 满时开始读，到 `almost_empty` 停止。

`ip_fifo.v` 依赖本目录中没有提供的 Vivado IP：`clk_wiz_0`、`fifo_generator_0`、`ila_0`、`ila_1`。在 Vivado 中必须创建同名 IP，或删除 ILA 实例并用项目现有时钟/FIFO 替换。

## IP 建议配置

- FIFO 选 Independent Clocks，写时钟 50 MHz、读时钟 100 MHz。
- 当前 `din/dout` 是 8 位，`wr_data_count/rd_data_count` 是 8 位，需开启 `full/empty/almost_full/almost_empty/wr_rst_busy/rd_rst_busy`。
- FIFO 深度、almost 阈值和 FWFT/standard read 模式必须与 `fifo_rd` 的读时序配合。

## 修改指南

| 变化 | 修改位置 |
|---|---|
| 系统时钟或读写频率 | 重新配置 `clk_wiz_0`，不能只改注释 |
| FIFO 位宽 | 重新生成 `fifo_generator_0`，并同步改 `fifo_wr_data/fifo_rd_data`、`fifo_wr.v` 输出和 ILA probe 宽度 |
| FIFO 深度 | 改 IP 参数，同步改 data-count 总线宽度和 almost 阈值 |
| 写入其他格式 | 将 `fifo_wr.v` 中递增 `fifo_wr_data` 替换为上层 `valid/data/ready` 接口，`almost_full` 用作反压 |
| 读出交给其他模块 | 用消费者 ready 与 `empty/almost_empty` 共同生成 `rd_en`，按 IP 的 FWFT/标准模式对齐 data-valid |

两个时钟域之间不要直接传递多位计数或控制脉冲；跨域信息应经 FIFO 或专用 CDC 逻辑。
