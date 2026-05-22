# scoop-bucket

个人 Scoop bucket：manifest 均在 `bucket/` **自维护**，不再依赖社区 bucket 源。

## 添加 bucket

```powershell
scoop bucket add scoop-bucket https://github.com/835519608/scoop-bucket
# 或本地
scoop bucket add scoop-bucket "$(Resolve-Path .)"
```

## 安装应用

```powershell
scoop install scoop-bucket/pixpin
scoop install scoop-bucket/symm
scoop install scoop-bucket/uuyc
scoop install scoop-bucket/dbx
scoop install scoop-bucket/xshellplus
scoop install scoop-bucket/mcp-router
scoop install scoop-bucket/CLIProxyAPI
```

## 从旧社区 bucket 迁移

若曾用 `cmontage_scoopbucket-soup`、`echoiron_echo-scoop` 等安装，可改为本 bucket：

```powershell
# 示例：uuyc
scoop uninstall uuyc
scoop bucket rm cmontage_scoopbucket-soup   # 可选，不再使用
scoop bucket update scoop-bucket
scoop install scoop-bucket/uuyc
```

`symm` 同理：`scoop uninstall symm` → `scoop bucket rm symm` → `scoop install scoop-bucket/symm`。

数据一般在 `scoop\persist\<app>\`，重装前备份对应目录。

## 应用说明

| 应用 | 说明 | 原社区源 |
|------|------|----------|
| pixpin | 截图 / 贴图 / OCR | 官网 |
| symm | 软链接管理（仅正式 Release） | 835519608/symm |
| uuyc | 网易 UU 远程 | cmontage/scoopbucket-soup |
| dbx | 数据库管理 | t8y2/scoop-bucket |
| xshellplus | Xshell Plus | echoiron/echo-scoop |
| mcp-router | MCP 路由桌面端 | LaelLuo/scoop |
| CLIProxyAPI | CLI 代理 API | YewFence/YewNursery |

`uuyc` 依赖本仓库 [`bin/utils.ps1`](bin/utils.ps1)（`New-PersistDirectory`）。

## 版本与自动更新

- 各 app 的 `checkver` / `autoupdate` 写在对应 `bucket/*.json` 中。
- 本地更新：`scoop checkver * -u`（在 bucket 目录或已 add 的 repo 上）。
- CI：[Excavator](https://github.com/ScoopInstaller/GithubActions) 每天北京时间 05:00 自动检查并提交 manifest 更新。

```powershell
scoop bucket update scoop-bucket
scoop update pixpin symm uuyc dbx xshellplus mcp-router CLIProxyAPI
```

**策略**：仅跟踪正式/stable 版本（PixPin 官网稳定版、GitHub 非 Pre-release）。

## 目录结构

```
bucket/          # 应用 manifest（自维护）
bin/utils.ps1    # uuyc 安装脚本依赖
catalog/apps.json
.github/workflows/excavator.yml
```

应用清单见 [`catalog/apps.json`](catalog/apps.json)。
