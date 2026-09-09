# MAX960x 高速比较器测试

从 `0824/pro/MAX9601/code` 提取了激励生成和结果统计逻辑，并将器件数、分频宽度和计数器宽度参数化。

## 文件

- `max9601_pattern_gen.v`：为每片器件生成可独立设置的方波激励。
- `max9601_result_counter.v`：检查 A/B 两组差分输出的极性和期望电平，分别累计正确/错误数。
- `top_max9601_test.v`：测试顶层。

## 顶层使用

`config_valid` 拉高一周期时，`config_device=0..DEVICE_COUNT-1` 设置单个器件，等于 `DEVICE_COUNT` 时设置全部；`config_divider` 是方波半周期的 `sys_clk` 计数。`run_enable` 开始激励和统计，`test_pattern` 需经板级激励电路加到比较器输入。`qa_p/qa_n/qb_p/qb_n` 是回读差分输出。计数总线按器件索引切片，第 `i` 个结果为 `[i*COUNTER_WIDTH +: COUNTER_WIDTH]`。

`DEVICE_COUNT` 和 `COUNTER_WIDTH` 可修改。高于 `sys_clk/2` 的激励或双边沿采样应在顶层外加厂商 ODDR/IDDR 原语，并重新做时序约束。
