# scoop-bucket

个人 Scoop bucket，在 `bucket/` 自维护应用 manifest。版本与 hash 由 GitHub Actions **Excavator** 每日自动 `checkver` 更新；本机用 `scoop update` 安装/升级即可。

## 快速开始

```powershell
scoop bucket add scoop-bucket https://github.com/835519608/scoop-bucket
scoop install scoop-bucket/pixpin
scoop update *
```

## 应用

| 应用 | 说明 | 版本检测 |
|------|------|----------|
| altrun | 轻量启动器 AltRun | GitHub Release |
| pixpin | 截图 / 贴图 / OCR | 官网稳定版文档 |
| uuyc | 网易 UU 远程（安装需管理员 PowerShell） | 网易发布 API |
| dbx | 开源数据库管理工具 | GitHub Release |
| moor | 本地 MCP 网关（Tauri） | GitHub Release |
| symm | 跨平台软链接管理（CLI + GUI） | GitHub Release |
| CLIProxyAPI | 多 CLI 代理为兼容 API 服务 | GitHub Release |
| hbuilderx | DCloud HTML5 / uni-app IDE | 官方 release.json |
| motty | 原生 SSH 工作台（终端 / SFTP / 转发 / VNC·RDP / AI） | GitHub Release |
| workbuddy-cn | 腾讯 WorkBuddy **国内版**（办公 Agent；微信/手机号，`workbuddy.cn`） | 官网 v2/update API |
| codebuddy-cn | 腾讯云 CodeBuddy IDE **国内版**（含 MCP；`codebuddy.cn`） | 官网 v2/update `ide-win32-x64-user` |
| cursor | Cursor AI 编辑器**最新版**（Scoop portable，数据在 persist） | cursor.com download API |
| cursor327 | Cursor **钉死 3.27.12**（与最新版可并存，shim=`cursor327`） | 无（不自动升） |
| dingtalk | 钉钉国内版（Scoop 便携；C 盘数据联接 persist） | dtapp-cast 签名 URL（同 sdoog） |

## 目录结构

```
bucket/*.json       # manifest
bin/hook.ps1        # hook 入口（加载 utils + 执行 hooks/）
bin/utils.ps1       # 公共函数
hooks/<app>/        # 各应用的 post_install / pre_uninstall 等脚本
.github/workflows/excavator.yml
```

### manifest hook 写法

Scoop 的 JSON 不能定义变量，每个 hook 用同一行模板，只改末尾路径：

```powershell
& ((Get-ChildItem (Join-Path $scoopdir 'buckets\*\bin\hook.ps1') -ErrorAction SilentlyContinue | Select-Object -First 1).FullName) 'hooks/<app>/post_install.ps1'
```

### 运行时数据（persist）

| 应用 | 持久化方式 |
|------|------------|
| altrun | Scoop `persist: Data`（配置与索引） |
| pixpin | Scoop `persist`：`Config`/`Data`/`History` + 联接 `LocalAppData/PixPin` |
| dbx | 目录联接：`AppData/com.dbx.app`、`LocalAppData/com.dbx.app`、`UserProfile/.dbx` |
| CLIProxyAPI | Scoop `persist` + 目录联接：`UserProfile/.cli-proxy-api` → `auth` |
| moor | 目录联接：`AppData/com.snowautumn.moor`、`LocalAppData/com.snowautumn.moor` |
| symm | Scoop `persist: data`（程序默认使用 `$dir/data`，含 `symm.db`、`settings.json`） |
| hbuilderx | 目录联接：`AppData/HBuilder X`、`LocalAppData/HBuilder X`；Scoop `persist: plugins` |
| uuyc | 目录联接：`LocalAppData/GameViewer`、`ProgramData/Netease/GameViewer` |
| motty | Scoop `persist: motty-data`（官方便携目录；≥0.3.2 已兼容 `current` 联接） |
| workbuddy-cn | 目录联接：`UserProfile/.workbuddy`、`AppData/WorkBuddy` → persist |
| codebuddy-cn | Scoop `persist: data` + 联接 `AppData/CodeBuddy CN`、`LocalAppData/CodeBuddy CN`、`UserProfile/.codebuddy` |
| cursor | Scoop `persist: data` + 联接 `AppData/Cursor`、`UserProfile/.cursor`（Crashpad / CLI） |
| cursor327 | 同 cursor；独立 `persist\\cursor327`（与最新版并存时后装者接管 C 盘联接） |
| dingtalk | 目录联接：`AppData/DingTalk`、`AppData/dinglive`、`LocalAppData/DingTalk_{91,108,133}` → persist |

`utils.ps1` 提供 `Install-PersistDataLinks`、`Clear-DesktopShortcuts`、`Assert-AdminElevation` 等。
