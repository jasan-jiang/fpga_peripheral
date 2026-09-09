# AD7984 高精度差分 ADC

本目录从 `0824/pro/AD7984BRMZ/code/src/spi.v` 提取转换和串行读取功能，去掉原工程的 96 MHz PLL、网络和 FIFO IP 依赖。

## 文件

- `ad7984_driver.v`：参数化 CNV 脉宽和 SCLK 的 18 位采样器。
- `top_ad7984.v`：板级顶层。
- PDF：AD7984 规格书。

## 顶层输入输出

`sys_clk`/`sys_rst_n` 为时钟和低有效复位。给 `sample_start` 单周期脉冲后，模块在 `adc_cnv` 上产生转换脉冲，然后通过 `adc_sclk` 从 `adc_sdo` 读取 18 位。`sample_valid` 拉高一周期时 `sample_data[17:0]` 有效，`busy` 表示当前转换未结束。

## 设置和修改

`CLK_FREQ_HZ` 必须等于实际系统时钟；`SCLK_FREQ_HZ` 设置串行读出速率；`CNV_HIGH_NS` 设置 CNV 高电平时间。更换时钟后必须重新检查 AD7984 数据手册的 CNV、数据访问和 SCLK 时序。模拟输入是差分信号，数字顶层只连接 ADC 的 CNV/SCK/SDO。
