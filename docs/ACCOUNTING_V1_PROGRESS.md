# 智能记账 V1 开发进度

## 阶段 0：基线审计

- 完成：克隆官方仓库，锁定 `d431cfd`，创建 `feature/accounting-v1`；核查许可证、数据模型、服务、导入解析器、Android 权限与构建版本。
- 缺口：离线多笔文字解析、第三方通知捕获、持久事件队列、跨源去重与 ACK、待核对界面、完整恢复验证及红米实测。
- 基线构建：未运行；当前工作环境缺少 Flutter/Android SDK 和设备。命令检查：`command -v flutter` 与 `command -v adb` 无结果；`java` 存在。
- 下一步：阶段 1 实现规则解析与可编辑草稿，配置 Flutter/Android 环境后运行 `flutter pub get && flutter analyze && flutter test && flutter build apk --debug`。
- 当前提交：见本文件最近一次 Git 提交历史（后续阶段更新）。

## 阶段 1：离线文字输入（首批）

- 完成：首页新增文字入口；按中文分隔的一句话多笔解析、CNY 整数分校验、逐笔可编辑草稿和显式保存反馈；转账与模糊时间/金额不自动保存；复用 `BillCreationService`；增加 T01/T20 及不确定输入的测试代码。
- 尚未完成：设备端语音识别抽象、AI 可选回退接线、传统表单与导入的统一草稿/去重、跨来源融合、通知服务。
- 测试：`git diff --check` 通过；Flutter SDK 缺失，`flutter test`、`flutter analyze` 与 APK 构建未运行，代码尚未经编译验证。
- 关键变更：`local_bill_draft_parser.dart`、`local_quick_entry_page.dart`、`home_page.dart`、解析测试。
- 下一步：在具备 Flutter 3.27.3 与 Android SDK 的环境跑门禁，修复实际失败项；再推进阶段 2 的持久通知 inbox。
