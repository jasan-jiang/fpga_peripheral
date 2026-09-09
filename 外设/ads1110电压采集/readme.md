# ADS1110 I²C 电压采集

功能源自 `0824/pro/MAX9601/code/iic_for_ads1110`，已将固定 50 MHz、100 kHz、0x48 地址和等待计数改为参数，并合并成自包含驱动。

## 文件与顶层

- `ads1110_driver.v`：上电写 CONFIG，之后定期读取转换值和状态。
- `top_ads1110.v`：顶层。`i2c_scl` 和 `i2c_sda` 是开漏网络，板上必须有上拉电阻。

`sys_clk`/`sys_rst_n` 为时钟和低有效复位。`sample_valid` 拉高时，`sample_data[15:0]` 是有符号二进制补码，`status_config` 是器件返回的配置字节。`busy` 表示 I²C 活动，`ack_error` 表示地址或数据未应答。

## 设置

- `CLK_FREQ_HZ`/`I2C_FREQ_HZ`：实际系统时钟和 I²C 速率。
- `SAMPLE_PERIOD_US`：两次读数之间的微秒数，应不小于所选转换速率的周期。
- `I2C_ADDR`：按器件型号/地址版本修改，默认 `7'h48`。
- `CONFIG`：默认 `8'h8C`（连续转换、15 SPS、PGA=1）；改变数据率或 PGA 后同步调整采样周期和电压换算。
