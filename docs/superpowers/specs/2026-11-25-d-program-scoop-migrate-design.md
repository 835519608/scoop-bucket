# D:\Program 迁入 scoop-bucket 设计

日期：2026-11-25  
状态：已定案（用户确认按推荐方案）

## 背景

`D:\Program` 下仍有若干未进 Scoop 的软件。本仓库已用统一模式管理应用：

- `bucket/<app>.json` + `hooks/<app>/{post_install,pre_uninstall,persist.ps1}`
- C 盘用户数据经 `Install-PersistDataLinks` 联到 `persist\<app>\...`
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
| todesk | [soup/todesk](https://github.com/cmontage/scoopbucket-soup)（及 scoopcn） | 7z 解包 + `config.ini` persist + `LocalAppData/ToDesk` 联接；驱动/服务脚本改为本仓 hook + `Assert-AdminElevation`；不依赖 soup 的 `utils.ps1` API |
| metatrader4/5 | 无成熟 Scoop 包；按官方 portable 文档自写 | 安装到 Scoop apps 目录；快捷方式强制 `/portable`；多账号用模板克隆（见下） |

## 各包设计

### 1. g-helper

- **分发**：GitHub Release `GHelper.zip`（同 extras）。
- **persist**：Scoop `persist: data`；映射 `AppData/GHelper` → `$persist_dir/data`（`EnsureTarget`）。
- **hooks**：`persist.ps1` + `post_install` / `pre_uninstall` 装/卸联接。
- **迁移**：安装前若存在 `%APPDATA%\GHelper` 实目录，由 `Install-PersistDataLinks` 迁入 persist；装好后卸掉 `D:\Program\GHelper`（用户确认后）。
- **依赖**：notes + suggest `.NET Desktop Runtime`（同 extras）。
- **不需要管理员**。

### 2. todesk

- **分发**：官网 exe `#/setup.7z` 再解内层 `app64.7z`（同 soup）；checkver 跟官网 download 页。
- **persist**：
  - 目录内：`config.ini`、`Logs`（Scoop `persist` 数组）
  - C 盘：`LocalAppData/ToDesk` → `$persist_dir/LocalAppData`
- **hooks**：`persist.ps1`；install/uninstall 处理解包与（如需要）驱动/服务；`Assert-AdminElevation`。
- **迁移**：合并现有 `D:\Program\ToDesk\config.ini` 与 `%LOCALAPPDATA%\ToDesk` 进 persist。
- **风险**：远程桌面含驱动；卸载须停进程并尽量清服务。实现时以 soup 卸载脚本为蓝本，改写成自包含 hook。

### 3. metatrader4 / metatrader5

#### 单实例（Scoop 管理）

- 各一个 manifest：`metatrader4`、`metatrader5`。
- 安装位置在 Scoop apps（非 Program Files）→ 可写。
- **shortcuts / bin 启动参数必须带 `/portable`**，数据留在安装树（或 persist 子目录），避免 `%APPDATA%\MetaQuotes\Terminal\<hash>`。
- **persist**：把 portable 下可变数据目录纳入 Scoop persist（具体子目录在实现时对照现网 `D:\Program\MetaTrader\MetaTrader {4,5}`：至少 `config` / `profiles` / `MQL4|MQL5` / `bases` 或等价；以「升级不丢账号与图表」为准）。
- checkver：跟 MetaQuotes 官网或现有安装包版本源（实现阶段锁定稳定 URL）。

#### 多账号（方案 A：模板 + 克隆）— 已定案

官方约束：**同一安装目录不能同时跑两份**；多开 = 多目录。

Scoop 同名只能装一份，故：

1. Scoop 只维护 **模板包** `metatrader4` / `metatrader5`（可 `scoop update`）。
2. 提供脚本（建议 `bin/mt-clone.ps1`，经 notes 说明用法），例如：

   ```powershell
   # 从当前 Scoop 模板复制出独立实例
   mt-clone -App metatrader5 -Name acc2
   # → D:\Program\Scoop\persist\metatrader5-instances\acc2\
   # → 开始菜单 / 桌面快捷方式：terminal64.exe /portable，WorkingDirectory=该实例目录
   ```

3. 实例目录 **不** 注册为独立 Scoop app；升级流程：
   - `scoop update metatrader5` 更新模板程序文件；
   - 脚本可选 `-SyncBinaries`：把模板里的 exe/dll 同步到各实例，保留实例自己的 config/MQL/图表。
4. 不采用「metatrader5-2、metatrader5-3… 多份 manifest」（难维护）。

现有 `D:\Program\MetaTrader\MetaTrader 4|5`：首次迁入时作为默认模板数据导入 persist；若用户已有多份拷贝，用 `mt-clone` 再迁或手工拷进 `metatrader*-instances`。

## 明确不做

- WeGame、DHF-VPN 进本 bucket。
- 用多个 Scoop manifest 名堆账号。
- 把 WSL 仓库与 `D:\...\buckets\scoop-bucket` 硬联成同一目录（UNC junction 不可用）；继续 push → `scoop update`。

## 本机切换顺序（实现后执行）

1. 推送 bucket → Windows `scoop update`。
2. 退出 GHelper / ToDesk / MT4 / MT5。
3. `scoop install scoop-bucket/g-helper`（数据从 AppData 迁入）。
4. `scoop install scoop-bucket/todesk`（管理员 PowerShell）。
5. `scoop install scoop-bucket/metatrader4`、`metatrader5`；按需 `mt-clone`。
6. 验证启动与数据后，再删 `D:\Program\GHelper`、`ToDesk`、旧 MetaTrader 目录（及无用的 AppData 残留）。

## 验收

- `scoop install` / `scoop uninstall` 各包不报错；卸载后 C 盘联接拆除，persist 数据保留。
- G-Helper：托盘/设置仍在；`%APPDATA%\GHelper` 为 Junction → persist。
- ToDesk：能连；`%LOCALAPPDATA%\ToDesk` 为 Junction；config 升级保留。
- MT：从 Scoop 快捷方式启动带 `/portable`；数据不在新的 MetaQuotes hash 目录（或仅历史残留）。
- `mt-clone` 可再开第二实例，两账号同时在线互不影响。
- Excavator / checkver 至少 g-helper、todesk 可自动升；MT 若官网难刮，允许半手动并在 notes 标明。

## 文档

- 更新根 `README.md` 应用表与 persist 表。
- 各 manifest `notes` 写清管理员、`/portable`、克隆用法。
