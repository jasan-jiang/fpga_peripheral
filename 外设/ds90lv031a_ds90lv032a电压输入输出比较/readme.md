# DS90LV031A / DS90LV032A 环回测试

从 `0827/DS90LV031ATMTC/code` 提取 pattern/result 逻辑，去掉 UART、INA226 和时钟 IP 等项目级依赖。

- `ds90lv_pattern_gen.v`：参数化多器件方波生成器。
- `ds90lv_result_counter.v`：对四路接收器输出 Y1～Y4 累计正确/错误数。
- `top_ds90lv_loopback_test.v`：完整环回测试顶层。

`driver_din` 连 DS90LV031A 单端输入，驱动器 LVDS 输出经终端匹配后连 DS90LV032A，接收器的 Y1～Y4 分别连 `receiver_y1..receiver_y4`。`config_valid/config_device/config_divider` 的设置方式与 MAX9601 目录相同；`run_enable` 启动测试。计数总线第 `i` 个切片为 `[i*COUNTER_WIDTH +: COUNTER_WIDTH]`。

修改 `DEVICE_COUNT`、`COUNTER_WIDTH` 或时钟后需同步更新管脚和时序约束。当数据速率接近 FPGA I/O 极限时，应使用 IOB 寄存器/ODDR/IDDR，当前文件保持为可移植的纯 RTL 单边沿版本。
