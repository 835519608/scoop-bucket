# D:\Program 迁入 scoop-bucket Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 GHelper、ToDesk、MetaTrader 4/5 迁入本 bucket（persist + C 盘联接；MT 多开用 `mt-clone`），并更新 README。

**Architecture:** 每个应用：`bucket/<app>.json` + `hooks/<app>/{persist,post_install|install,pre_uninstall|uninstall}.ps1`，经 `bin/hook.ps1` 加载 `utils.ps1`。G-Helper/ToDesk 用 `Install-PersistDataLinks`；MT 用官方 `/auto /path` 装到 `$dir`、快捷方式强制 `/portable`、Scoop persist 冻结目录；多账号由 `bin/mt-clone.ps1` 复制自包含实例到 `persist/<app>-instances/<Name>`。

**Tech Stack:** Scoop manifests (JSON)、PowerShell 5.1 hooks、UTF-8 BOM `.ps1`、现有 `bin/utils.ps1` API。

**Spec:** `docs/superpowers/specs/2026-11-25-d-program-scoop-migrate-design.md`

---

## File map

| Path | Responsibility |
|------|----------------|
| `bucket/g-helper.json` | extras 风格 zip + checkver；hook 入口 |
| `hooks/g-helper/persist.ps1` | `AppData/GHelper` → `persist/data` |
| `hooks/g-helper/post_install.ps1` / `pre_uninstall.ps1` | 装/卸联接 |
| `bucket/todesk.json` | soup 风格 7z 解包 + persist + checkver |
| `hooks/todesk/persist.ps1` | LocalAppData 联接 |
| `hooks/todesk/install.ps1` | 管理员、解包、拷 config.ini、联接 |
| `hooks/todesk/uninstall.ps1` | 停进程/服务、拆联接 |
| `bucket/metatrader4.json` / `metatrader5.json` | `/auto /path` 安装 + `/portable` shortcuts |
| `hooks/metatrader4/*` / `hooks/metatrader5/*` | 安装后迁移 AppData/旧目录；卸模板不删 instances |
| `bin/mt-clone.ps1` | 克隆实例 / SyncBinaries |
| `README.md` | 应用表 + persist 表 |

**不做：** WeGame、DHF-VPN；多份 `metatrader5-N` manifest。

---

### Task 1: g-helper manifest + hooks

**Files:**
- Create: `bucket/g-helper.json`
- Create: `hooks/g-helper/persist.ps1`
- Create: `hooks/g-helper/post_install.ps1`
- Create: `hooks/g-helper/pre_uninstall.ps1`
- Reference: extras `g-helper.json`（url/hash/checkver/suggest）；`hooks/pixpin/*`（hook 风格）

- [ ] **Step 1: 拉取最新 extras 清单字段**

在 Windows PowerShell 或 curl：

```powershell
Invoke-RestMethod https://raw.githubusercontent.com/ScoopInstaller/Extras/master/bucket/g-helper.json |
  ConvertTo-Json -Depth 10
```

记下 `version`、`url`、`hash`、`suggest`、`checkver`、`autoupdate`。

- [ ] **Step 2: 写 `hooks/g-helper/persist.ps1`（UTF-8 BOM）**

```powershell
$persistMappings = @(
    @{ Label = 'roaming'; Source = 'AppData/GHelper'; Target = '$persist_dir/data'; EnsureTarget = $true }
)
```

- [ ] **Step 3: 写 post/pre uninstall hooks**

`post_install.ps1`:

```powershell
. (Join-Path $PSScriptRoot 'persist.ps1')
Install-PersistDataLinks -Mappings $persistMappings -Log:$true
```

`pre_uninstall.ps1`:

```powershell
. (Join-Path $PSScriptRoot 'persist.ps1')
Uninstall-PersistDataLinks -Mappings $persistMappings -Log:$true
```

- [ ] **Step 4: 写 `bucket/g-helper.json`**

要点：
- 字段同 extras（description/homepage/license/url/hash/bin/shortcuts/persist/checkver/autoupdate/suggest/notes）
- `persist`: `["data"]`
- `post_install` / `pre_uninstall` 用本仓 hook 一行：

```json
"post_install": "& ((Get-ChildItem (Join-Path $scoopdir 'buckets\\\\*\\\\bin\\\\hook.ps1') -ErrorAction SilentlyContinue | Select-Object -First 1).FullName) 'hooks/g-helper/post_install.ps1'",
"pre_uninstall": "& ((Get-ChildItem (Join-Path $scoopdir 'buckets\\\\*\\\\bin\\\\hook.ps1') -ErrorAction SilentlyContinue | Select-Object -First 1).FullName) 'hooks/g-helper/pre_uninstall.ps1'"
```

- notes：便携；`%APPDATA%\\GHelper` → persist；需 .NET Desktop Runtime。

- [ ] **Step 5: 校验**

```bash
python3 -c 'import json; json.load(open("bucket/g-helper.json")); print("ok")'
# Windows: Parser::ParseFile 三个 ps1；确认 BOM
```

Expected: JSON ok；Parse 无错；`read_bytes()[:3]==BOM`。

- [ ] **Step 6: Commit**

```bash
git add bucket/g-helper.json hooks/g-helper/
git commit -m "$(cat <<'EOF'
feat(g-helper): 迁入 extras 便携包并联接 AppData 到 persist

EOF
)"
```

---

### Task 2: todesk manifest + hooks

**Files:**
- Create: `bucket/todesk.json`
- Create: `hooks/todesk/persist.ps1`
- Create: `hooks/todesk/install.ps1`
- Create: `hooks/todesk/uninstall.ps1`
- Reference: soup `todesk.json`；本仓 `hooks/uu/install.ps1`（管理员模式）

- [ ] **Step 1: 确认官网当前版本与 hash**

从 soup checkver 或 download 页得到 `version`、`url`（`.../ToDesk_x.y.z.exe#/setup.7z`），下载算 sha256（或先装 soup 字段再 excavator）。

本机旧版可能是 `5.2.1.0`（`D:\Program\ToDesk`）；manifest 用官网当前可下载版本，迁移时只拷 `config.ini` 内容。

- [ ] **Step 2: `hooks/todesk/persist.ps1`**

```powershell
$persistMappings = @(
    @{ Label = 'local'; Source = 'LocalAppData/ToDesk'; Target = '$persist_dir/LocalAppData'; EnsureTarget = $true }
)
```

- [ ] **Step 3: `hooks/todesk/install.ps1`**

逻辑顺序：
1. `Assert-AdminElevation -Reason 'ToDesk 安装/服务需要管理员' -InstallHint 'scoop install scoop-bucket/todesk'`
2. 若 `$dir\app64.7z` 存在：`Expand-7zipArchive` 到 `$dir`，删 `app64.7z` 与安装器残片
3. 若 `$persist_dir\config.ini` 不存在或空：优先从 `D:\Program\ToDesk\config.ini` 复制；否则写入最小默认（可参考 soup 模板，`autoupdate=0`）
4. `. persist.ps1`；`Install-PersistDataLinks`
5. **不**安装/覆盖 `ToDeskAudio.sys`

- [ ] **Step 4: `hooks/todesk/uninstall.ps1`**

1. `Assert-AdminElevation`
2. 停进程：`ToDesk`, `todesk-mcp`, `zagent`, `updater` 等（`-ErrorAction SilentlyContinue`）
3. 若存在服务 `ToDesk_Service`：`Stop-Service`；`sc.exe delete ToDesk_Service`（失败只 warn）
4. `. persist.ps1`；`Uninstall-PersistDataLinks`
5. notes 已说明驱动可残留——脚本不删 `ToDeskAudio.sys`

- [ ] **Step 5: `bucket/todesk.json`**

- `url`/`hash`/`checkver`/`autoupdate` 同 soup 模式（`$matchPath`）
- `persist`: `["Logs", "config.ini"]`
- 用 `installer.script` **或** 自定义 `pre_install`+`post_install` 调用 `hooks/todesk/install.ps1`（优先单一 `install.ps1` 经 hook，与 uu 一致：若 manifest 用 `installer`/`uninstaller` script 内嵌 hook 调用亦可）
- 推荐与 uu 类似：

```json
"pre_install": "... hook ... 'hooks/todesk/install.ps1'"
```

注意：Scoop 先解压 `#/setup.7z` 再跑 pre/post；确认 `app64.7z` 在 `$dir` 时再 Expand。若必须在 persist 链接之后，把联接放 install 末尾。

- shortcuts: `ToDesk.exe` / `ToDesk`
- notes：管理员；LocalAppData 联接；`ToDeskAudio` 可能残留；迁移后删 `D:\Program\ToDesk`

- [ ] **Step 6: 校验 BOM + JSON + Parse**

- [ ] **Step 7: Commit**

```bash
git add bucket/todesk.json hooks/todesk/
git commit -m "$(cat <<'EOF'
feat(todesk): Scoop 解包安装并联接 LocalAppData 到 persist

EOF
)"
```

---

### Task 3: metatrader5 模板包

**Files:**
- Create: `bucket/metatrader5.json`
- Create: `hooks/metatrader5/persist.ps1`（仅文档化 persist 名；若无 C 盘联接可省略 mappings，或留空数组不用）
- Create: `hooks/metatrader5/post_install.ps1`
- Create: `hooks/metatrader5/pre_uninstall.ps1`

- [ ] **Step 1: 锁定安装 URL**

```text
https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe
```

hash：实现时下载算 sha256；`version` 暂用本机探测 `5.0.0.6274` 或安装后读 `terminal64.exe`（半手动 notes）。

- [ ] **Step 2: manifest 骨架**

- `url`: 上述 exe（可 `#/mt5setup.exe` 保留文件名）
- **不要**把 setup 当最终程序：用 `installer.script` / `post_install`：

```powershell
$setup = Get-ChildItem $dir -Filter 'mt5setup.exe' | Select-Object -First 1
if (-not $setup) { $setup = Get-ChildItem $dir -Filter '*.exe' | Select-Object -First 1 }
Start-Process -FilePath $setup.FullName -ArgumentList @('/auto', "/path:`"$dir`"") -Wait
# 清理 setup；确认 $dir\terminal64.exe 存在
# 若失败：从 D:\Program\MetaTrader\MetaTrader 5 复制程序树（规格备选种子）
```

- `persist`（冻结）：

```json
["Bases", "Config", "logs", "MQL5", "Profiles", "Tester"]
```

若安装后有 `llm-agent`，post_install 将其纳入 persist（`persist_file` 或手动 junction——优先：发现则追加拷到 persist 并 junction）。

- `bin` / `shortcuts`：

```json
"bin": [["terminal64.exe", "metatrader5", "/portable"]],
"shortcuts": [["terminal64.exe", "MetaTrader 5", "/portable"]]
```

- checkver：首版可省略或固定 version；notes 写「半手动升」。

- [ ] **Step 3: `post_install.ps1` 数据迁移**

1. 若 `%APPDATA%\MetaQuotes\Terminal\*\origin.txt` 指向旧 `D:\Program\MetaTrader\MetaTrader 5`：把该 hash 目录内容合并进 `$persist_dir` 对应子目录（Bases/Config/MQL5/Profiles 等）。
2. 若旧安装目录仍在且 persist 为空：从 `D:\Program\MetaTrader\MetaTrader 5` 拷冻结目录进 persist。
3. 确认快捷方式参数含 `/portable`（Scoop 已生成则复查；必要时重写 lnk）。
4. **不要**联接整个 `AppData\MetaQuotes`。

- [ ] **Step 4: `pre_uninstall.ps1`**

- 停 `terminal64` / `metaeditor64` / `metatester64`
- **禁止**删除 `$scoopdir\persist\metatrader5-instances`

- [ ] **Step 5: 校验 + Commit**

```bash
git add bucket/metatrader5.json hooks/metatrader5/
git commit -m "$(cat <<'EOF'
feat(metatrader5): Scoop 模板包，/portable 与冻结 persist

EOF
)"
```

---

### Task 4: metatrader4 模板包

**Files:**
- Create: `bucket/metatrader4.json`
- Create: `hooks/metatrader4/post_install.ps1`
- Create: `hooks/metatrader4/pre_uninstall.ps1`

- [ ] **Step 1: 镜像 Task 3，替换为 MT4**

- URL：`https://download.mql5.com/cdn/web/metaquotes.software.corp/mt4/mt4setup.exe`（若 404，用 broker 包或种子复制 `D:\Program\MetaTrader\MetaTrader 4`）
- exe：`terminal.exe`；shim：`metatrader4`；shortcut 名 `MetaTrader 4`；参数 `/portable`
- `persist`：

```json
["config", "history", "logs", "MQL4", "profiles", "templates", "tester"]
```

- 迁移源：旧目录（本机 AppData 无独立 MT4 hash 时可只拷目录）

- [ ] **Step 2: 校验 + Commit**

```bash
git add bucket/metatrader4.json hooks/metatrader4/
git commit -m "$(cat <<'EOF'
feat(metatrader4): Scoop 模板包，/portable 与冻结 persist

EOF
)"
```

---

### Task 5: `bin/mt-clone.ps1`

**Files:**
- Create: `bin/mt-clone.ps1`
- Modify: `bucket/metatrader4.json` notes、`bucket/metatrader5.json` notes（调用示例）

- [ ] **Step 1: 实现脚本（UTF-8 BOM）**

参数：
- `-App`：`metatrader4` | `metatrader5`（Mandatory）
- `-Name`：实例名（与 `-SyncBinaries` 二选一主模式）
- `-SyncBinaries`：同步所有 `persist\<app>-instances\*`
- `-EmptyData`：克隆时不拷模板 persist 数据

行为：
1. `$scoop = $env:SCOOP`；`$appDir = Join-Path $scoop "apps\$App\current"`；`$persist = Join-Path $scoop "persist\$App"`；`$instRoot = Join-Path $scoop "persist\$App-instances"`
2. **Clone**：`robocopy $appDir $dest /E /XJ /XF uninstall.exe` 后，删除 dest 下与 persist 同名的空/坏 junction；再从 `$persist` 实目录拷数据（或 `-EmptyData`）
3. 写开始菜单快捷方式：`...Terminal ... ($Name)` → `$dest\terminal64.exe`（或 MT4 `terminal.exe`）` /portable`
4. **SyncBinaries**：对每个实例停进程；只同步 `*.exe` `*.dll` `Sounds`；永不覆盖 Config/MQL/Bases/profiles/history/logs/Tester/templates 等

- [ ] **Step 2: notes 写入调用路径**

```powershell
& "$env:SCOOP\buckets\scoop-bucket\bin\mt-clone.ps1" -App metatrader5 -Name acc2
& "$env:SCOOP\buckets\scoop-bucket\bin\mt-clone.ps1" -App metatrader5 -SyncBinaries
```

- [ ] **Step 3: 干跑语法 Parse + Commit**

```bash
git add bin/mt-clone.ps1 bucket/metatrader4.json bucket/metatrader5.json
git commit -m "$(cat <<'EOF'
feat(mt-clone): MetaTrader 多账号实例克隆与二进制同步

EOF
)"
```

---

### Task 6: README + 本机安装验证

**Files:**
- Modify: `README.md`

- [ ] **Step 1: 更新应用表与 persist 表**

加入 g-helper、todesk、metatrader4、metatrader5 行；persist 说明含 MT instances 与 ToDesk 驱动残留。

- [ ] **Step 2: Commit README**

```bash
git add README.md
git commit -m "$(cat <<'EOF'
docs: README 登记 g-helper / todesk / MetaTrader

EOF
)"
```

- [ ] **Step 3: 推送并 Windows 验证（需用户环境）**

```powershell
# 在 WSL 仓库
git push

# Windows
cd D:\Program\Scoop\buckets\scoop-bucket
git pull --ff-only
# 退出 GHelper/ToDesk/MT；停 ToDesk_Service
scoop install scoop-bucket/g-helper
# 管理员:
scoop install scoop-bucket/todesk
scoop install scoop-bucket/metatrader5
scoop install scoop-bucket/metatrader4
```

验收对照 spec「验收」节：Junction、`/portable` Data Folder、ToDesk 服务、可选 `mt-clone`。

- [ ] **Step 4: 验证通过后（用户确认）再删旧 `D:\Program\...` 目录**

---

## Execution notes

- 所有新建 `.ps1` 必须 UTF-8 BOM + CRLF（与现有 hooks 一致）。
- 改的是 WSL 仓库；勿在 `D:\Program\Scoop\buckets\scoop-bucket` 直接改文件。
- ToDesk hash/版本以实现当日官网为准；MT setup hash 实现日下载计算。
