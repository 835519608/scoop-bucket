# scoop-bucket

个人 Scoop bucket，manifest 在 `bucket/` 自维护。版本更新以 **Excavator 自动 + 标准 `checkver`** 为主，尽量少手改。

## 快速开始

```powershell
scoop bucket add scoop-bucket https://github.com/835519608/scoop-bucket
scoop install scoop-bucket/pixpin
scoop install scoop-bucket/dbx
# …见下方应用列表
```

## 维护方式（推荐，最省心）

| 你要做的 | 频率 |
|----------|------|
| **什么都不做** | 每天 Excavator 05:00（北京时间）自动 `checkver` 并提交 manifest |
| `scoop bucket update scoop-bucket` + `scoop update <app>` | 本机升级软件时 |
| 看 GitHub Actions → Excavator 是否成功 | 偶尔 |
| 手改 `bucket/*.json` | **几乎不需要**（见下方例外） |

本地试跑更新（WSL）：

```bash
./scripts/checkver-update.sh
```

或在 Windows：

```powershell
cd <scoop-bucket 路径>
scoop checkver * -u
```

### 各应用自动更新能力

| 应用 | 检测方式 | 维护难度 |
|------|----------|----------|
| dbx | GitHub Release | ⭐ 低 |
| CLIProxyAPI | GitHub Release | ⭐ 低 |
| mcp-router | GitHub Release | ⭐ 低 |
| pixpin | 官网文档 + CDN | ⭐⭐ 中 |
| uuyc | 网易发布 API | ⭐⭐⭐ 较高（API/安装脚本变更时要改） |
| symm | GitHub 正式 Release | ⭐ 低（**需先有正式 tag**；无正式版时勿安装） |

**已从本 bucket 移除 `xshellplus`**：原 manifest 无自动更新且下载链不稳定。若仍需使用：

```powershell
scoop bucket add echoiron_echo-scoop https://github.com/echoiron/echo-scoop
scoop install echoiron_echo-scoop/xshellplus
```

### 设计原则

1. **优先 GitHub Release**：`"checkver": "github"` + `autoupdate.hash.mode: download`（Excavator 自动算 hash）。
2. **不收录无法 `checkver` 的包**（如旧 xshellplus）。
3. **仅正式版**：symm 不跟 `-test` Pre-release；PixPin 跟官网稳定版。

## 安装应用

```powershell
scoop install scoop-bucket/pixpin
scoop install scoop-bucket/symm      # 需 GitHub 已有正式 Release
scoop install scoop-bucket/uuyc
scoop install scoop-bucket/dbx
scoop install scoop-bucket/mcp-router
scoop install scoop-bucket/CLIProxyAPI
```

## 从旧社区 bucket 迁移

```powershell
scoop uninstall <app>
scoop bucket rm <旧bucket名>    # 可选
scoop bucket update scoop-bucket
scoop install scoop-bucket/<app>
```

`persist` 数据在 `scoop\persist\<app>\`，重装前可备份。

## 目录结构

```
bucket/*.json           # 应用 manifest
bin/utils.ps1           # uuyc 安装依赖
catalog/apps.json
.github/workflows/excavator.yml
scripts/checkver-update.sh
```

应用清单：[`catalog/apps.json`](catalog/apps.json)
