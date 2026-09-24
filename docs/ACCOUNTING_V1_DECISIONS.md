# 智能记账 V1 决策记录

## 2026-09-24：基线与边界

- 采用 BeeCount 的个人非商业修改路线；基线 `d431cfd403b8c2b5f42fe143e3cbe4b1d741df4c`，分支 `feature/accounting-v1`。
- 保留仓库的 `LICENSE`、版权信息和现有 Android/Flutter 架构。源代码修改版本依其许可证公开；商业用途需另行取得授权。
- 现有 `BillCreationService` 接收 `BillInfo`，AI 文本、语音、图像和自动截图复用它；手动编辑页直接使用 repository，当前 `AutoBillingService.processText` 依赖已配置的 AI。
- 微信、支付宝 CSV 解析器已存在；通知广播接收器负责本应用提醒，不具备第三方支付通知捕获能力。
- 原库 `Transactions.amount` 为 REAL、`schemaVersion` 为 33，含 `excludeFromStats`、`excludeFromBudget` 和多币种字段。新增规则解析将以整数分作为输入边界；数据库迁移须单独审查和测试。
- 依赖和权限：Flutter/Dart SDK ^3.6、Gradle 8.13、Android Gradle Plugin 8.12.1、Kotlin 2.2.0、Java 17、compileSdk 36、NDK 27.0.12077973。现有应用声明互联网、录音、图片读取、安装 APK、通知显示等权限；尚无通知监听服务声明。
- 此工作区无 Flutter SDK、Android SDK 和连接的手机；此处不能宣称通过 `flutter analyze`、`flutter test` 或构建 APK。先实现并保存源代码，待环境具备后执行这些门禁。
