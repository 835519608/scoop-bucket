# scoopBucket

个人 Scoop bucket，用于通过 [Scoop](https://scoop.sh/) 安装常用软件。

## 添加 bucket

```powershell
scoop bucket add scoop-bucket "$(Resolve-Path .)"
```

若仓库已推送到 GitHub，也可使用远程地址：

```powershell
scoop bucket add scoop-bucket https://github.com/835519608/scoop-bucket
```

## 安装应用

```powershell
scoop install scoop-bucket/pixpin   # 截图 / 贴图 / OCR
scoop install scoop-bucket/symm     # 软链接管理 CLI + GUI
```

### PixPin

[PixPin](https://pixpin.cn/) 是一款免费的截图、贴图、长截图与 OCR 工具（Windows）。安装后可通过 `pixpin` 命令或开始菜单快捷方式启动。

### 配置与数据持久化（Scoop）

官方 zip 版把运行时数据放在 **与 `PixPin.exe` 同目录** 的 `Config`、`Data`、`History` 下。manifest 里已配置 `persist`，升级 `scoop update pixpin` 时这些目录会保留。

| 程序目录下的文件夹 | Scoop 实际存放位置（示例） |
| ------------------ | -------------------------- |
| `Config` | `%USERPROFILE%\scoop\persist\pixpin\Config` |
| `Data` | `%USERPROFILE%\scoop\persist\pixpin\Data` |
| `History` | `%USERPROFILE%\scoop\persist\pixpin\History` |

安装后，版本目录里上述三项是 **目录联接（junction）** 指向 `persist`，不是复制一份。

查看路径：

```powershell
scoop prefix pixpin          # 当前版本程序目录（…\apps\pixpin\current）
scoop prefix -p pixpin       # persist 根目录
```

若你以前用安装包装过、数据在 `%AppData%\PixPin`，需要**手动复制**到 `scoop\persist\pixpin\` 对应子目录（结构不一致时以 zip 版首次运行后生成的目录为准），再 `scoop reset pixpin` 重建联接。

### symm

[symm](https://github.com/835519608/symm) 是跨平台软链接管理工具（本 bucket 仅提供 Windows 便携 zip）。

| 命令 / 文件 | 说明 |
| ----------- | ---- |
| `symm` | GUI（`symm.exe`） |
| `symm-cli` | CLI（`cli/symm-cli.exe`） |
| `persist/data` | SQLite 库 `symm.db`，环境变量 `SYMM_HOME` 已指向此处 |

若曾用 `scoop bucket add symm https://github.com/835519608/symm` 安装，可改为本 bucket 后重装：

```powershell
scoop uninstall symm
scoop bucket rm symm
scoop bucket add scoop-bucket https://github.com/835519608/scoop-bucket
scoop install scoop-bucket/symm
```

数据在 `scoop\persist\symm\data`，重装前可先备份该目录。

## 版本与自动更新

Scoop **安装时**必须知道确切的 `version`、`url`、`hash`（保证可复现、可校验），manifest 里写的版本是「当前已验证的快照」，不是让你每次手改。

真正跟官网走版本的是每个 app 里的 **`checkver` + `autoupdate`**（PixPin 已配置）。你平时不用手改版本号，只需：

```powershell
# 本地一次更新 bucket 里所有 app
scoop checkver * -u
```

仓库已配置 [Excavator](https://github.com/ScoopInstaller/GithubActions) 工作流（`.github/workflows/excavator.yml`），**每天北京时间 05:00**（UTC 21:00）在 GitHub 的 Windows  runner 上自动跑一遍；也可在 Actions 页手动点 **Run workflow**。

### Excavator 怎么更新 manifest

1. **检出**当前仓库（你的 `bucket/*.json`）。
2. 在 runner 上装好 Scoop，对 bucket 里**每个**带 `checkver` 的 app 执行 `checkver`：
   - 按 manifest 里的规则访问官网 / GitHub 等，解析**最新版本号**；
   - 若比 manifest 里新，用 `autoupdate` 规则生成新 `url`，下载安装包并算 **SHA256**，写入 `version`、`url`、`hash`。
3. 若有变更，用 `GITHUB_TOKEN` **直接 commit 到默认分支**（一般是 `main`），commit 信息类似 `chore: automatic update via Excavator`。
4. 若没有新版本，则不改文件、不提交（`SKIP_UPDATED: '1'` 只减少日志噪音）。

你在 Windows 上升级已装软件时，先拉 bucket 再更新 app：

```powershell
scoop bucket update scoop-bucket
scoop update pixpin symm
```

**注意**：Excavator 只维护 **GitHub 仓库里的 manifest**；本机已安装版本不会自动变，需要你自己 `scoop update`。

### 以后加新软件怎么省事

| 软件发布方式 | manifest 里 checkver 怎么写 |
| ------------ | --------------------------- |
| GitHub Releases | `"checkver": "github"` + `homepage` 指向仓库即可 |
| 官网固定规则（如 PixPin 带版本号的 zip） | 为该 app 写一段 `checkver` / `autoupdate`（无法省略，但只写一次） |
| 有 `latest` 直链 | 仍建议用 checkver 解析版本并更新 hash |

**每个 app 都要有自己的版本发现规则**（这是 Scoop 的设计），麻烦的是「维护」，用 `checkver * -u` 或 Excavator **批量**处理即可，不必逐个手改。

## 软件列表

| 应用   | 说明                         |
| ------ | ---------------------------- |
| pixpin | 截图 / 贴图 / 长截图 / OCR   |
| symm   | 软链接管理（CLI + GUI）      |
