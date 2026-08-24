# Order Report Test Fixture

这是 Allred 异机实验使用的隔离夹具。请先复制整个目录，再让 Codex 修改副本。

- `orders.csv`：功能和调试样例输入，原文件不应被修改。
- `report.ps1`：包含一个有意保留的状态匹配错误。
- `history-2026-07.csv`、`history-2026-08.csv`：长期任务只读分析样例。

初始运行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\report.ps1
Get-Content .\summary.csv
```

正确业务事实：

- `orders.csv` 有 2 个“已完成”、1 个“处理中”、1 个“已取消”订单。
- 未取消订单金额合计为 3500。
- 7 月取消订单为 1/5（20%），8 月为 2/5（40%）。
