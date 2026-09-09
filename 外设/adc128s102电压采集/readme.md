# ADC128S102 电压采集

本目录从 `0824/pro/adc128s102_vivado_pro` 的 `spi_adc_if.v` 和 `spiclkdiv.v` 提取功能，合并为不依赖 PLL/IP 的参数化 RTL。

## 文件

- `adc128s102_driver.v`：SPI mode 3 采样驱动，支持 1～4 片器件和 8 通道选择。
- `top_adc128s102.v`：可直接加入工程的顶层。
- `adc128s102.pdf`：器件数据手册。

## 顶层输入输出

`sys_clk`/`sys_rst_n` 是系统时钟和低有效复位；`sample_start` 给一个时钟周期高脉冲启动采样；`adc_device` 选择芯片，`adc_channel` 选择 0～7 通道。`adc_dout/adc_sclk/adc_cs_n/adc_din` 连接 ADC 管脚。`sample_valid` 为高时 `sample_data[11:0]` 有效；`busy=1` 时不要再发起请求。

## 设置和修改

- `CLK_FREQ_HZ`：填写实际 FPGA 时钟。
- `SCLK_FREQ_HZ`：SPI 时钟，必须满足数据手册和 `CLK_FREQ_HZ/(2*SCLK_FREQ_HZ)>=1`。
- `DEVICE_COUNT`：并联器件数，当为 1 时 `adc_device` 固定为 0。增加器件时同步扩展约束中的 DOUT/SCLK/CS/DIN 管脚。

原工程的时钟 IP、以太网、UART 和 FIFO 未复制，因为它们不是 ADC128S102 驱动所必需的外设逻辑。
