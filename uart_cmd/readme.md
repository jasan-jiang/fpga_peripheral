# UART 15 字节命令帧

## 文件与默认格式

- `uartrx.v` / `uarttx.v`：固定 50 MHz、500 kbaud、8N1、LSB first 的字节收发器。
- `cmd_rx.v`：连续收 15 字节并拼成 `cmd_cout[119:0]`。
- `cmd_tx.v`：将 120 位命令按低字节到高字节发送。
- `cmd_processor.v`：顶层校验与回环示例，仅在完整帧校验通过后原样发回。

默认 15 字节映射为：字节 0=`[7:0]` head，1=`[15:8]` address，2=`[23:16]` function，3～12=`[103:24]` ID0～ID9，13=`[111:104]` check，14=`[119:112]` tail。按从 1 开始的通信文档编号，check 是第 14 字节。

`cmd_processor` 对第 14 字节执行校验：`check = (address + function + ID0 + ... + ID9) mod 256`，即对字节 1～12 做 8-bit 累加，不包含 head、check 和 tail。校验不符时 `cmd_valid` 不会产生，命令被丢弃，也不启动 UART 回传。`cmd_rx` 仍只负责收齐 15 字节；head/tail 值尚未限定。

## 操作

`cmd_processor` 只需连 `clk_50m/rst_n/rx/tx`。单独使用 `cmd_rx` 时，`cmd_rx_done` 是一帧完成脉冲，此时读取 `cmd_cout`；`cmd_rx_busy` 表示帧正在接收。单独使用 `cmd_tx` 时，稳定 `cmd`后给 `cmd_tx_start` 一周期脉冲，等待 `cmd_tx_done`。

## 改时钟、波特率或帧格式

| 需求 | 修改位置 |
|---|---|
| 改系统时钟/波特率 | `uartrx.v` 和 `uarttx.v` 中每 bit 的 `cnt_clk==99`，新终值=`CLK_HZ/BAUD-1`；RX 中点 `49` 改为约半个 bit |
| 计数值超过 127 | 同步扩展两个 UART 文件的 `cnt_clk[6:0]` |
| 7/9 data bits、奇偶校验、2 stop bits | 修改 `uartrx.v/uarttx.v` 的 `cnt_bit` 结束值、采样 case 和发送 case；两端必须一致 |
| 帧长不是 15 字节 | 同时改 `cmd_rx.v`/`cmd_tx.v` 的 120 位总线、`cmd_cnt/cmd_byte_cnt` 宽度、case 映射和结束值 14 |
| 改字段顺序/大小端 | 在 `cmd_rx.v` 修改每个字节写入的 bit slice，`cmd_tx.v` 做完全对应的反向映射 |
| 修改校验算法 | 修改 `cmd_processor.v` 中 `calc_checksum`；当前为字节 1～12 的模 256 累加 |
| 增加帧头/帧尾验证 | 在 `cmd_processor.v` 的接受条件中继续检查 `cmd_rx[7:0]` 和 `cmd_rx[119:112]`；失败时与 checksum 失败一样丢弃 |
| 改帧超时 | `cmd_rx.v` 中 `cmd_timeout_cnt>=45300`，按 `CLK_HZ × timeout_seconds` 重算并扩展计数器 |

对噪声较大或时钟误差较大的链路，建议将 UART RX 改为 8x/16x 过采样并加入起始位确认。
