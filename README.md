# acky

下一代 ADE（agent 开发环境）的桌面客户端。

人不用再进一个个 agent 会话里推进任务。每个项目有一个常驻的 Acky：从 GitHub、定时任务进来的每一条 Trigger 都先到它那里，它只做分拣，接单、挂到已有的 Ticket、停止或忽略；真正干活的是派到你自己机器上的 Worker（Claude Code、Codex）。你只在要拍板和验收的时候出现。

这个仓库只放说明和安装包。

## 它做什么

- **一个项目一个 Acky**：按你写下的原话和 Policy 决定接不接，Router 分拣时只分拣，不读代码、不定方案。
- **Worker 在你的机器上跑**：每张 Ticket 一个独立的工作目录；Worker 自己确认需求、写验收标准、交证据，交付后由另一个 Worker 复核；Claude 只跑自己发起的 Ticket。
- **人只看要拍板的事**：首页和项目页集中显示等你回答、等你验收的事，可以直接在卡片上回答；需要时才进会话插话或接管。
- **多台机器**：笔记本、办公室的机器都能接活，离线时排队，连上再派。
- **自我迭代（RSI）**：每晚复盘，把教训起草成配置修改，用历史 Trigger 回放验证，人验收后才生效；授权只归人。

## 系统要求

- macOS 12 或更高，Apple Silicon 或 Intel。
- 干活的机器上装好并登录 Claude Code（`claude`）或 Codex（`codex`）。
- 用 Google 账号登录云端；Acky 自己的模型服务由部署统一提供。

## 安装

### 一行命令（推荐）

退出已打开的 acky，在「终端」粘贴：

```sh
curl -fsSL https://github.com/myaier/acky/releases/latest/download/install.sh | bash
```

脚本会按芯片下载最新的完整 ZIP，核对 SHA-256 后安装到 `/Applications/acky.app`，替换旧副本、清除该应用的 quarantine 标记并打开。应用程序目录需要管理员权限时会提示输入密码。校验失败不会替换旧应用，安装失败会恢复旧副本。发布的脚本锁定同一个版本的 ZIP 与校验文件。

每个 release 都提供固定名称的 [Apple Silicon ZIP](https://github.com/myaier/acky/releases/latest/download/acky-mac-arm64.zip) 和 [通用 ZIP](https://github.com/myaier/acky/releases/latest/download/acky-mac-universal.zip)，供首次安装使用。

### DMG 安装

在 [Releases](https://github.com/myaier/acky/releases) 找到提供 DMG 的版本：Apple Silicon 用 `acky-<版本>-arm64.dmg`，Intel 用 `acky-<版本>-universal.dmg`。打开后把 acky 拖进「应用程序」，再打开 acky。

目前尚未取得 Apple Developer ID 签名与公证。若 macOS 显示「Apple 无法验证」，关闭提示，前往「系统设置 → 隐私与安全性」，找到 acky，点「仍要打开」并确认。参见 [Apple 官方说明](https://support.apple.com/zh-cn/102445)。不依赖右键「打开」绕过。

也可以在确认下载来自本仓库后，在终端执行：

```sh
xattr -dr com.apple.quarantine /Applications/acky.app
open /Applications/acky.app
```

## 更新

应用自动检查新版本，下载好后点「重启更新」。日常更新只下载应用代码和界面；Electron 等基础内容没变就不会重复下载。新版本启动失败时会恢复上一版。

已使用旧整包更新机制的 0.4 版本会先进行一次完整下载，之后转为小包更新。DMG 和完整 ZIP 只需首次安装或这次过渡时使用，不必每版重新安装。

## 数据在哪

- 项目和会话记录保存在云端，桌面端通过本机代理访问。
- 设备和节点凭据暂用应用数据目录中的本地随机密钥加密保存；同一系统用户下的其他程序也能读取密钥。旧钥匙串凭据只做一次迁移，在个人设置中可吊销设备。
- Worker 工作目录在运行它的节点上；第三轮不迁移前两轮的本机数据。
- 日志在 `~/Library/Logs/acky`。

## 卸载

退出 acky，删掉「应用程序」里的 acky.app。要连数据一起删，再删 `~/Library/Application Support/acky`；这不会删除云端数据，也不会替你吊销其他设备。
