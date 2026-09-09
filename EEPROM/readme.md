# I²C EEPROM 读写测试

## 文件与顶层

- `top_e2prom.v`：测试顶层，上电后先写入递增数据，再逐字节读回比较。
- `e2prom_rw.v`：测试流程控制。
- `i2c_dri.v`：可单独复用的 I²C 字节读写引擎。
- `rw_result_led.v`：将 `rw_done/rw_result` 转为 LED 显示。

`sys_clk/sys_rst_n` 为时钟和低有效复位，`iic_scl/iic_sda` 连 EEPROM，SDA 必须有上拉。释放复位后测试自动运行；`led` 显示最终比较结果。测试会覆盖从地址 0 开始的内容，不要直接用于已有重要数据的 EEPROM。

## 不同 EEPROM 或数据怎么改

| 需求 | 修改位置 |
|---|---|
| 7-bit 器件地址 | `top_e2prom.SLAVE_ADDR` |
| 8/16-bit 字地址 | `top_e2prom.BIT_CTRL`：0 为 8 位，1 为 16 位 |
| 系统/I²C 时钟 | `CLK_FREQ`、`I2C_FREQ`，必须符合器件最大 SCL |
| 测试容量 | `MAX_BYTE`；不能超出实际容量，也要考虑块选地址位 |
| EEPROM 写周期 | `e2prom_rw.WR_WAIT_TIME`，单位是 `dri_clk` 周期；更换 `CLK_FREQ/I2C_FREQ` 后需重新换算 |
| 写入非递增数据 | 改 `e2prom_rw.v` 中 `i2c_addr/i2c_data_w` 的生成逻辑，比较条件也要同步改 |
| 做通用寄存器接口 | 不实例化 `e2prom_rw`，直接驱动 `i2c_dri` 的 `i2c_exec/i2c_rh_wl/i2c_addr/i2c_data_w`，等待 `i2c_done` 并检查 `i2c_ack` |

当前每次写 1 字节，没有页写、ACK polling 或 write-protect 管脚控制。改为页写时必须根据页边界拆分传输。
