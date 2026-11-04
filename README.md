# acky

下一代 ADE（agent 开发环境）的桌面客户端。

人不用再进一个个 agent 会话里推进任务。每个项目有一个常驻的 Acky：从 GitHub、定时任务进来的每一条 Trigger 都先到它那里，它只做分拣，接单、挂到已有的 Ticket、停止或忽略；真正干活的是派到你自己机器上的 Worker（Claude Code、Codex）。你只在要拍板和验收的时候出现。

这个仓库只放说明和安装包。

## 它做什么

- **一个项目一个 Acky**：按你写下的原话和 Policy 决定接不接，研判时只分拣，不读代码、不定方案。
- **Worker 在你的机器上跑**：每张 Ticket 一个独立的工作目录；Worker 自己确认需求、写验收标准、交证据，交付后由另一个 Worker 复核；Claude 只跑自己发起的 Ticket。
- **人只看要拍板的事**：首页和项目页集中显示等你回答、等你验收的事，可以直接在卡片上回答；需要时才进会话插话或接管。
- **多台机器**：笔记本、办公室的机器都能接活，离线时排队，连上再派。
- **自我迭代（RSI）**：每晚复盘，把教训起草成配置修改，用历史 Trigger 回放验证，人验收后才生效；授权只归人。

## 系统要求

- macOS 12 或更高，Apple Silicon 或 Intel。
- 干活的机器上装好并登录 Claude Code（`claude`）或 Codex（`codex`）。
- 用 Google 账号登录云端；Acky 自己的模型服务由部署统一提供。

## 安装

1. 在 [Releases](https://github.com/myaier/acky/releases/latest) 下载对应芯片的安装包：Apple Silicon 用 `acky-<版本>-arm64.dmg`，Intel 用 `acky-<版本>-x64.dmg`。如果提供 `universal` 通用包，两种芯片都能使用。打开后把 acky 拖进「应用程序」。
2. 这个版本还没有经过 Apple 公证，第一次打开时 macOS 会拦下：先在 Finder 中右键 acky →「打开」；若仍被拦下，到「系统设置 → 隐私与安全性」点「仍要打开」，或者在终端运行 `xattr -dr com.apple.quarantine /Applications/acky.app`。

## 更新

acky 启动后和之后每 4 小时检查一次这里的最新版本，有新版本就在后台下载并校验；左下角出现「新版本已就绪」，点一下 acky 就重启成新版本。也可以在「设置」里手动检查。

## 数据在哪

- 项目和会话记录保存在云端，桌面端通过本机代理访问。
- 设备令牌由系统钥匙串保护的加密密钥加密保存；在个人设置中可吊销。
- Worker 工作目录在运行它的节点上；第三轮不迁移前两轮的本机数据。
- 日志在 `~/Library/Logs/acky`。

## 卸载

退出 acky，删掉「应用程序」里的 acky.app。要连数据一起删，再删 `~/Library/Application Support/acky`；这不会删除云端数据，也不会替你吊销其他设备。
