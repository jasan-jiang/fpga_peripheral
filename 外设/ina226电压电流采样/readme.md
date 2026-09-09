# INA226 电压/电流监测

功能源自两个原工程共用的 `ina226_moudle.v`、`iic_ctrl_vol.v` 和 `iic_com.v`。新版修正了固定时钟、地址和配置值，并提供 ACK 错误输出。

## 文件与顶层

- `i2c_reg16_master.v`：通用 8 位寄存器地址/16 位数据 I²C 主机。
- `ina226_driver.v`：写配置和校准寄存器，周期读取总线电压和电流。
- `top_ina226.v`：板级顶层。`i2c_scl/i2c_sda` 需外部上拉。

`sample_valid` 为高时，`bus_voltage_raw` 和 `current_raw` 同时有效。总线电压通常按 1.25 mV/LSB 换算；电流寄存器是有符号值，每 LSB 的实际电流由分流电阻和 `CALIBRATION` 决定。

## 设置

`CLK_FREQ_HZ`、`I2C_FREQ_HZ`、`SAMPLE_PERIOD_US`和 `I2C_ADDR` 按板级设计修改。`CONFIG` 控制平均、转换时间和模式。`CALIBRATION = 0.00512/(Current_LSB × Rshunt)`；修改分流电阻或量程时必须重算该值，并在上层按相同 `Current_LSB` 换算 `current_raw`。
