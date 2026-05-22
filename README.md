# scoop-bucket

个人 Scoop bucket，在 `bucket/` 自维护应用 manifest。版本与 hash 由 GitHub Actions **Excavator** 每日自动 `checkver` 更新；本机用 `scoop update` 安装/升级即可。

## 快速开始

```powershell
scoop bucket add scoop-bucket https://github.com/835519608/scoop-bucket
scoop install scoop-bucket/pixpin
scoop update *    # 升级已安装应用（会拉取 bucket 最新 manifest）
```

## 应用

| 应用 | 说明 | 版本检测 |
|------|------|----------|
| pixpin | 截图 / 贴图 / OCR | 官网稳定版文档 |
| uuyc | 网易 UU 远程 | 网易发布 API（安装需管理员 PowerShell） |
| dbx | 开源数据库管理工具 | GitHub Release |
| mcp-router | MCP 服务器桌面管理 | GitHub Release |
| CLIProxyAPI | 多 CLI 代理为兼容 API 服务 | GitHub Release |

```powershell
scoop install scoop-bucket/pixpin
scoop install scoop-bucket/uuyc
scoop install scoop-bucket/dbx
scoop install scoop-bucket/mcp-router
scoop install scoop-bucket/CLIProxyAPI
```

## 自动更新

| 环节 | 说明 |
|------|------|
| GitHub | 每天北京时间约 05:00，Excavator 对全部 manifest 跑 `checkver` 并提交 |
| 本机 | `scoop update <app>` 或 `scoop update *`，无需本地跑 checkver |
| 监控 | 偶尔查看仓库 Actions → Excavator 是否成功 |

### 设计约定

- **仅正式版**：例如 PixPin 跟官网 `official-log` 稳定版，不跟 beta 频道。
- **GitHub hash**：Release 有 `checksums.txt` / `SHA256SUMS` 则从文件读取；否则 `autoupdate.hash.mode: download`。
- **不可自动检测的包不收录**，避免 manifest 长期失效。

| 应用 | Release 校验文件 | autoupdate |
|------|------------------|------------|
| CLIProxyAPI | `checksums.txt` | 读文件 |
| dbx | 无 | download |
| mcp-router | 无 | download |
| pixpin / uuyc | — | 各自 checkver 配置 |

## 目录结构

```
bucket/*.json              # manifest
bin/load-utils.ps1         # manifest 入口：$bucket → install.json → 搜索（兼容 Scoop v0.5.3）
bin/utils.ps1              # 公共 PowerShell 函数（由 load-utils.ps1 加载）
scripts/mcp-router-launch.ps1  # mcp-router 启动器模板（打开应用后延迟禁用开机启动）
.github/workflows/excavator.yml
```

### 运行时数据（persist）

manifest 通过 `Install-PersistDataLinks` / `Uninstall-PersistDataLinks`（目录联接，与 Scoop persist 一致）或 Scoop 自带 `persist` 保留数据；API 见 `bin/utils.ps1` 文件头。

| 应用 | 持久化方式 |
|------|------------|
| pixpin | Scoop `persist`：`Config`、`Data`、`History` |
| dbx | 自动链接：`AppData/com.dbx.app`、`LocalAppData/com.dbx.app`、`UserProfile/.dbx` |
| CLIProxyAPI | Scoop `persist` + 自动链接：`UserProfile/.cli-proxy-api` → `auth` |
| mcp-router | 自动链接：`AppData/MCP Router` → `roaming`；请用 `mcp-router` 或开始菜单启动（约 12s 后禁用开机启动） |
| uuyc | 自动链接：`LocalAppData/GameViewer`、`ProgramData/Netease/GameViewer` |

数据在 `scoop\persist\<app>\`，`pre_uninstall` 会拆除联接、保留 persist 目录；升级前可自行备份。
