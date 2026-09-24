# 智能记账安卓 App V1 进度

## 2026-09-24：仓库核对

- 本地 `feature/accounting-v1` 在 `1048402`；包含 `df13a99`（基线审计）、`1048402`（离线文字草稿实现）。本地工作树核对时干净。
- GitHub 上游 `TNT-Likely/BeeCount` 的 `main` 为 `d431cfd`，不存在 `feature/accounting-v1`。项目分支最初仅在本地。
- 前一轮摘要中“离线文字记账首批实测”表述有误：测试源文件已写，`flutter test` 未执行，也没有 APK、手机实测。
- 当前可用 APK：无。

## 2026-09-24：云端构建准备

- 完成：添加 `.github/workflows/accounting-v1-debug.yml`，按上游现有 Release 流程锁定 Flutter 3.27.3、Java 17、Android API 36、NDK 27.0.12077973；包含依赖安装、`flutter analyze`、`flutter test`、Android `testDevDebugUnitTest`、debug APK、SHA-256 和 Artifact 上传。
- 仓库缺少 `android/gradlew` 和 wrapper JAR，工作流在 CI 中使用 Gradle 8.13 生成 wrapper；未更改原项目的 Gradle 版本与架构。
- 实测：工作流尚未上传并运行。CI 日志、安装启动及红米实机测试待取得。任何失败均应根据日志修复，不得标为通过。
- 下一步：将现有功能分支推到个人 BeeCount Fork；触发 Actions，读取真实日志，修复直至生成首份可安装 APK；再推进语音和通知模块。

## 2026-09-24：GitHub Fork

- 已从公开上游建立个人公开 Fork，保留来源、版权与许可证。
- 分支推送前的公开内容审计：相对 `d431cfd` 仅新增 8 个源码、测试、工作流及进度文件；没有密钥、签名材料或真实流水，新增提交使用 `Codex <codex@openai.com>` 作者身份。初次推送被自动审批以“可能公开非公开源码或配置”拦截；审计后待重试。
- 审计后通过已连接的 GitHub 接口仅上传上述 8 个文件，远端检查点 `036aea54b433c7186d7a161251d4f2309873a6e6`；本地历史提交继续保留。Actions #1 启动后在 `android-actions/setup-android@v3` 步骤失败，日志显示 `Failed to find package 'tools'`，因此分析、测试、APK 均未执行。按官方修复升级该 CI Action 至 v4。

## 2026-09-24：云端静态检查实测

- Actions #2 在修正 Android SDK action 后完成 Flutter 3.27.3、Java 17、Android SDK/NDK、依赖和 Gradle wrapper 准备；严格 `flutter analyze` 失败：全仓 981 项诊断，其中 186 项错误全部来自原有 `packages/agentcore/test` 缺少本子包的 `test` 开发依赖。Flutter 测试、Android 测试和 APK 因前置失败未运行。
- 修复：为 `packages/agentcore` 执行 `dart pub get`。全仓分析仍执行并严格拦截错误；原项目数百条既存 warning/info 输出到日志，不作为首包阻塞；本次新增记账源码和测试另执行严格分析。不能将之前的严格全仓分析记作通过。
- 下一步：验证修复后的云端日志，运行所有测试并制作可安装 APK。

## 待解决的安装升级风险

- `devDebug` 包名在同一风味下稳定，可保留原数据；但不同 GitHub 托管 runner 默认生成的 debug 签名证书未必相同。证书变化时 Android 会拒绝覆盖安装，卸载重装会清空沙盒数据。
- 在真正给用户长期记录财务数据的体验包之前，应为此分支配置一份稳定的专用测试签名密钥，保存在 GitHub Actions Secret（不提交仓库），并验证同一设备连续安装两版且原交易仍在。正式 Release 签名另行管理。
- 首个临时 debug 包仅用于安装/功能验证；如果无稳定签名，先导出并验证可恢复的备份，不能宣称“升级无损”已验收。

## 2026-09-24：首份云端体验 APK

- 远端 `feature/accounting-v1` 提交 `82ac4bd` 对应 [Actions #3](https://github.com/xiaoxiaoming676-pixel/BeeCount/actions/runs/35952628945)，结果 success。全仓分析在子包依赖安装后 **0 error、795 条原仓 warning/info**；本次新增的三份记账代码及测试文件严格分析 0 诊断。
- `flutter test`：794 passed、1 skipped；Android `testDevDebugUnitTest`：Gradle BUILD SUCCESSFUL，但目标任务 `NO-SOURCE`，此阶段没有实际 Android 单元测试用例。
- 成功生成调试签名 `app-dev-debug.apk`，SHA-256 `95a6875f6cf75c491db84e8d397bbc955ae9d0367fe5ff2ae5e80dcd13a3de0d`；[Artifact `accounting-v1-dev-debug-3`](https://github.com/xiaoxiaoming676-pixel/BeeCount/actions/runs/35952628945) 有效期至 2026-10-24。尚无自动安装/启动或红米真机验证。
- 后续单独阶段：加入 Android 模拟器安装启动冒烟测试、进度与红米验收文档；“关于”明确显示版本、构建号、短提交号。构建再次通过前，#3 仍是最新可用 APK。
- 未完成：应用内系统中文语音入口、微信/支付宝通知监听、通知持久队列与去重、稳定调试签名、真实导出恢复和升级保数实测。

## 2026-09-24：模拟器测试首轮日志

- [Actions #4](https://github.com/xiaoxiaoming676-pixel/BeeCount/actions/runs/35953655465)：静态检查、Flutter 测试、Android 构建、debug APK 与 Artifact 上传成功；模拟器 Android API 35 启动成功，`adb install` 返回 `Success`。
- 启动脚本指定的 Activity 完整类名与实际 APK 的 LAUNCHER 注册项不匹配，`am start` 返回 `Error type 3 Activity class ... does not exist`，因此自动启动测试失败，不能算启动通过。改用 `monkey -p com.tntlikely.beecount.dev -c android.intent.category.LAUNCHER 1` 按安装包真实入口启动，并检查进程；结果待下次运行。

## 2026-09-24：系统中文语音入口（待云端验证）

- Android 原生调用系统 `RECOGNIZE_SPEECH`，中文语音结果回填文字记账页，继续由既有草稿解析、核对和保存流程处理；没有系统识别服务、取消或空结果时提示文字输入。补充 Flutter 页面模拟测试覆盖成功和不可用两种情况。
- 目前只是源码实现，尚未纳入成功构建，不能标为可用或真机通过；等待上个阶段的模拟器构建结束后再单独提交远端并查看新 APK 日志。

## 2026-09-24：通知解析规则（待云端验证）

- 增加原生 Kotlin 的微信/支付宝通知候选解析与 JUnit 模拟测试：支出、退款、转账、金额缺失、同一通知重复、同金额不同商户以及可能的跨来源重复。全部候选只标为待核对，不自动保存到账本；关联通知仅提示可能重复，不自动合并。
- 这一步尚未实现 `NotificationListenerService`、持久化队列、Flutter 待核对列表及账单导入关联去重，因此不宣称自动记账可用。代码及测试待云端构建验证。

## 2026-09-24：Release 签名防护

- 公开提交原有 `android/app/build.gradle` 时自动审核拦截：原仓库缺少正式签名文件时会尝试生成固定口令调试密钥签 Release 或允许未签名产物。已移除这一回退；缺少完整私有 `key.properties` 时 Release 任务应失败，当前 debug 构建照常使用 Android 调试签名。不生成、不上传正式签名密钥。
