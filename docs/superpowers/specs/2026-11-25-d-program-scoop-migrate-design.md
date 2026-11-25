# D:\Program 迁入 scoop-bucket 设计

日期：2026-11-25  
状态：已定案（用户确认按推荐方案；spec 审查修订）

## 背景

`D:\Program` 下仍有若干未进 Scoop 的软件。本仓库已用统一模式管理应用：

- `bucket/<app>.json` + `hooks/<app>/{post_install,pre_uninstall,persist.ps1}`
- C 盘用户数据经 `Install-PersistDataLinks` / `Uninstall-PersistDataLinks` 联到 `persist\<app>\...`
- WSL 仓库推送后，Windows 侧 `D:\Program\Scoop\buckets\scoop-bucket` 独立 clone 拉更新（勿在该 clone 直接改文件）

目标：能迁的迁入本 bucket；优先复用成熟第三方 manifest，再改造成仓库现有 persist 风格。

## 范围

| 源目录 | 决策 | 包名 |
|--------|------|------|
| `D:\Program\GHelper` | **迁入** | `g-helper` |
| `D:\Program\ToDesk` | **迁入** | `todesk` |
| `D:\Program\MetaTrader\MetaTrader 4` | **迁入** | `metatrader4` |
| `D:\Program\MetaTrader\MetaTrader 5` | **迁入** | `metatrader5` |
| `D:\Program\WeGame` | **不迁** | —（自更新平台，Scoop 难管） |
| `D:\Program\DHF-VPN` | **不迁** | —（iNode + 内核驱动） |

已在其它 Scoop bucket 的软件（Chrome、Telegram 等）不在本次范围。

## 成熟清单来源

| 包 | 参考 | 本仓改造要点 |
|----|------|--------------|
| g-helper | [extras/g-helper](https://github.com/ScoopInstaller/Extras/blob/master/bucket/g-helper.json) | 已有 AppData junction；改为 `persist.ps1` + `Install-PersistDataLinks`；保留 checkver/autoupdate、.NET suggest |
| todesk | [soup/todesk](https://github.com/cmontage/scoopbucket-soup)（及 scoopcn） | 7z 解包 + `config.ini` persist + `LocalAppData/ToDesk` 联接；不依赖 soup 的 `utils.ps1` API；本机实测服务/驱动见下 |
| metatrader4/5 | 无成熟 Scoop 包；官方 `/auto /path` + `/portable` | 模板包 + `mt-clone` 多开；persist 目录表已冻结 |

## 各包设计

### 1. g-helper

- **分发**：GitHub Release `GHelper.zip`（同 extras）。
- **persist**：Scoop `persist: ["data"]`。
- **映射**（`hooks/g-helper/persist.ps1`）：

  ```powershell
  @{ Label = 'roaming'; Source = 'AppData/GHelper'; Target = '$persist_dir/data'; EnsureTarget = $true }
  ```

- **hooks**：`post_install` → `Install-PersistDataLinks`；`pre_uninstall` → `Uninstall-PersistDataLinks`（不要像 extras 那样对 junction `Remove-Item -Recurse`）。
- **迁移**：现有 `%APPDATA%\GHelper`（本机有 `config.json`）由联接逻辑迁入 persist；确认后删 `D:\Program\GHelper`。
- **依赖**：notes + suggest `.NET Desktop Runtime`（同 extras）。
- **不需要管理员**。

### 2. todesk

#### 本机实测（2026-11-25）

- 服务：`ToDesk_Service`（Manual，当前 Stopped）
- 驱动：`ToDeskAudio` → `C:\WINDOWS\system32\drivers\ToDeskAudio.sys`（Running）
- 配置：`D:\Program\ToDesk\config.ini`（含账号相关字段）；`%LOCALAPPDATA%\ToDesk` ≈ 16.6 MB

#### 分发与 persist

- **分发**：官网 exe `#/setup.7z` 再解内层 `app64.7z`（同 soup）；checkver 跟官网 download 页。
- **Scoop persist**：`config.ini`、`Logs`
- **C 盘映射**：`LocalAppData/ToDesk` → `$persist_dir/LocalAppData`

#### 安装 / 卸载策略（相对 soup 写清）

Soup 现网清单**不**主动安装/卸载内核驱动，只做解包 + LocalAppData persist；卸载要求管理员、停进程、清注册表/LocalAppData。本仓对齐该边界：

| 阶段 | 权限 | 行为 |
|------|------|------|
| install | **需要管理员**（`Assert-AdminElevation`） | 解包；若 persist 无 `config.ini` 则从旧 `D:\Program\ToDesk\config.ini` **复制**（`Install-PersistDataLinks` 不管文件）；再联接 LocalAppData；**不**强制重装 `ToDeskAudio.sys`（沿用系统已有驱动；首次干净机由 ToDesk 自身拉起） |
| uninstall | **需要管理员** | 停 `ToDesk.exe` / 相关进程；停并尝试删除服务 `ToDesk_Service`（若存在）；`Uninstall-PersistDataLinks`；**不保证**删除 `ToDeskAudio.sys`（与排除 DHF-VPN「内核驱动难回滚」同一理由——notes 写明可能残留音频驱动） |

#### 迁移注意

1. 先退出 ToDesk，停 `ToDesk_Service`。
2. `scoop install` 前不要删旧目录，以便拷 `config.ini`。
3. 验证后删 `D:\Program\ToDesk`。

### 3. metatrader4 / metatrader5

#### 本机实测（2026-11-25）

| | MT4 | MT5 |
|--|-----|-----|
| 版本 | 4.0.0.1492 | 5.0.0.6274 |
| 路径 | `D:\Program\MetaTrader\MetaTrader 4` | `D:\Program\MetaTrader\MetaTrader 5` |
| 顶层数据目录 | `config`, `history`, `logs`, `MQL4`, `profiles`, `Sounds`, `templates`, `tester` | `Bases`, `Config`, `logs`, `MQL5`, `Profiles`, `Sounds`, `Tester`, `llm-agent` |
| portable.ini | 无 | 无 |
| AppData | （未观察到独立 hash） | `%APPDATA%\MetaQuotes\Terminal\F991361C...` → origin=`D:\Program\MetaTrader\MetaTrader 5`（**非 portable**） |

迁入后必须改用 `/portable`，并把 AppData 里该 hash 的数据合并进模板 persist，避免双数据源。

#### 安装方式（已定）

- URL：官方 `mt4setup.exe` / `mt5setup.exe`（web installer）。
- 安装命令：`mtXsetup.exe /auto /path:"$dir"`（官方支持；装到 Scoop `$dir`，非 Program Files）。
- 装完后 hook：写入/确保 Scoop 快捷方式与 shim **始终带** `/portable`；可选 touch `portable` 标记文件（若有助于客户端识别，以实现时实测为准）。
- **checkver / autoupdate**：官网版本难稳刮 → **首版允许半手动**（notes 标明）；能找到稳定 API 再补 Excavator。
- 备选种子：若 silent 安装在本机失败，允许 `pre_install` 从现有 `D:\Program\MetaTrader\...` 复制程序树到 `$dir`（一次性迁移路径），仍走同一 persist/`/portable` 约定。

#### Scoop persist（模板包，已冻结）

**metatrader4** `persist`：

```text
config, history, logs, MQL4, profiles, templates, tester
```

（`Sounds` 随程序更新，不 persist。）

**metatrader5** `persist`：

```text
Bases, Config, logs, MQL5, Profiles, Tester
```

（`Sounds` 不 persist；`llm-agent` 若存在则一并 persist。）

大小写以安装后 `$dir` 实名为准；manifest 与磁盘不一致时在 post_install 纠名或按实名写 persist。

**无** C 盘 `AppData/MetaQuotes` 联接：强制 `/portable` 后数据应在 `$dir`/persist；旧 hash 目录仅作迁移源，迁完可删。

#### shortcuts / bin 形态

```json
"bin": [ ["terminal64.exe", "metatrader5", "/portable"] ],
"shortcuts": [ ["terminal64.exe", "MetaTrader 5", "/portable"] ]
```

MT4 用 `terminal.exe` / shim `metatrader4`。

#### 多账号：模板 + `bin/mt-clone.ps1`（已定案）

官方：**同目录不能同时跑两份**。Scoop 同名只能装一份。

| 概念 | 路径 | Scoop 管理 |
|------|------|------------|
| 模板 | `apps/metatrader5/current` + `persist/metatrader5/...` | 是；`scoop update` |
| 实例 | `persist/metatrader5-instances/<Name>/`（完整私有树） | **否**；仅脚本管理 |

**克隆规则（防 junction 污染）：**

1. 源二进制：从模板 **versioned `$dir`** 复制 `*.exe`、`*.dll`、`Sounds` 等不可变资源；**排除** Scoop persist 联接名（上表目录）——用 robocopy `/XJ` 或不拷 junction。
2. 源数据：从 `persist/metatrader5/`（实目录）复制到 `persist/metatrader5-instances/<Name>/` 对应子目录；或 `-EmptyData` 只要空壳。
3. 结果：实例是**自包含目录**，内部 **没有** 指向模板 persist 的 junction。
4. 快捷方式：`...\instances\<Name>\terminal64.exe /portable`，WorkingDirectory=实例根。
5. 调用（notes 写绝对路径，因 `bin/mt-clone.ps1` 默认不在 PATH）：

   ```powershell
   & "$env:SCOOP\buckets\scoop-bucket\bin\mt-clone.ps1" -App metatrader5 -Name acc2
   & "$env:SCOOP\buckets\scoop-bucket\bin\mt-clone.ps1" -App metatrader5 -SyncBinaries
   ```

**`-SyncBinaries`：**

- 先停该 app 所有实例进程。
- 仅同步 exe/dll/Sounds 等；**永不**覆盖 instances 下的 Config/MQL/Bases/profiles/history 等数据目录。
- 不刷新则快捷方式仍指向原路径（实例根不变）。

**卸载模板：** `scoop uninstall metatrader5` **不删除** `persist/metatrader5-instances\`（notes + uninstall 脚本显式跳过）。

## 明确不做

- WeGame、DHF-VPN 进本 bucket。
- 多份 `metatrader5-N` Scoop manifest。
- Scoop 路径强装/强删 ToDesk 内核音频驱动。
- WSL 仓库与 Windows scoop-bucket clone 硬联成同一目录。

## 本机切换顺序（实现后执行）

1. 推送 bucket → Windows `scoop update`。
2. 退出 GHelper / ToDesk / MT4 / MT5；停 `ToDesk_Service`。
3. `scoop install scoop-bucket/g-helper`。
4. 管理员 PowerShell：`scoop install scoop-bucket/todesk`。
5. `scoop install scoop-bucket/metatrader4`、`metatrader5`（合并 AppData hash / 旧目录数据进 persist）；按需 `mt-clone`。
6. 验证后删 `D:\Program\GHelper`、`ToDesk`、旧 MetaTrader；可删已迁移的 `%APPDATA%\MetaQuotes\Terminal\<hash>`。

## 验收

- 各包 install/uninstall 成功；卸载后 C 盘联接拆除，**模板** persist 保留；MT instances 目录在卸模板后仍在。
- G-Helper：`%APPDATA%\GHelper` → Junction → `persist\g-helper\data`；设置保留。
- ToDesk：能连；LocalAppData 为 Junction；`config.ini` 升级保留；卸后无 `ToDesk_Service`（或 notes 已说明残留）；`ToDeskAudio` 驱动允许残留并在 notes 写明。
- MT：Scoop 快捷方式含 `/portable`；File → Open Data Folder 落在 `$dir`/persist，**不**新建 `%APPDATA%\MetaQuotes\Terminal\<hash>`（非 `/portable` 误开造成的垃圾除外）。
- `mt-clone` 第二实例可与模板同时在线；`-SyncBinaries` 后实例账号/图表仍在。
- g-helper、todesk 有可用 checkver；MT 半手动可接受。

## 文档

- 更新根 `README.md` 应用表与 persist 表。
- 各 manifest `notes`：管理员、驱动残留、`/portable`、`mt-clone` 调用路径。
