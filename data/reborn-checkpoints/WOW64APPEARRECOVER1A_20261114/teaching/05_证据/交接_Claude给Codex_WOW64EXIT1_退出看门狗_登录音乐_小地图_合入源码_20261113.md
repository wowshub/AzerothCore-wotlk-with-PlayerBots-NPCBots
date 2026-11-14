# 交接：Claude → Codex　WOW64EXIT1 系列（退出看门狗 / 登录音乐修复 / 小地图队友圆点）合入你的 64 位客户端源码

日期：2026-11-13　写给：Codex（64 位客户端线路维护者）　来自：Claude（经用户转交）

## 1. 一句话
我在**自己的复制目录**里，基于你的 RACEPORT1C 累计源码（Client.cpp 等 25 文件与源码树逐个比对一致）改了 **3 个源码文件**，编译出 EXIT1B/1C/1D/1E 四版 `WowClient64.exe`。**用户已实测通过的是 EXIT1E：退出不卡死 + 登录界面有声音**。请你下次出新 EXE 时把这三处改动并进你的源码，否则声音和看门狗会丢。

## 2. 你需要知道的背景（为什么要改）
- 用户机器装了 **SoundWire 虚拟声卡**，64 位客户端点“退出”后一直“未响应”。我抓了卡死进程的转储：主线程在 `SE2::StopAllSounds` 之后卡在 Windows WinMM waveOut 的等待里；你的 `RebornExitTrace.log` 最后一行也是 `SI2 before SE2::StopAllSounds`。关游戏声音或停用 SoundWire 都能正常退出。
- 登录界面没有背景音乐，进世界用 `/run PlayMusic("...mp3")` 也没声音。日志证据：请求发出了、`enableAll=1 inMovie=0 enableMusic=1`、声道组音量 SCRIPTMUSIC/MUSIC=0.50、结果 `isPlaying=1`，但上一首被替换前 `pos=0`（放了 20 多秒位置不前进）。
- 小地图队友（巫医、武僧等无原版图标的职业）显示成黄色方块。

## 3. 改了什么（三个文件，均相对你的 BUILD1B/source 树）

### 3.1 `WoW/Source/Client.cpp`（约 54 行）　WOW64EXIT1A：退出看门狗
- `RebornExitStage` 里记录进度：`s_rebornExitStageName`、`s_rebornExitProgressTick`（`InterlockedExchange64(GetTickCount64())`）。
- 新增 `RebornExitWatchdogThread` + `RebornStartExitWatchdog`：每 0.25 s 检查；**退出流程 3 秒没有任何阶段推进就 `TerminateProcess(GetCurrentProcess(), 0)`**；当前阶段名含 `ShutdownAddOns` 时放宽到 15 秒（插件 SavedVariables 写盘）。触发前往 `RebornExitTrace.log` 写一行 `EXIT WATCHDOG: ... (no progress for N ms after stage '...')`。
- `WowClientDestroy()` 开头：先 `CVar::SaveAll()`（后面 `CVar::Destroy` 还会再存一次，不冲突），再 `RebornStartExitWatchdog()`。
- 注意：一个坑——我第一次把 `'\\'` 写进源码时被工具吃成 `'\'`，编译报 C2001；已改成 `static_cast<char>(92)`。你原有的 `strrchr(path,'\\')` 没动。
- 实机证据：用户日志里出现两次 `EXIT WATCHDOG ... after stage 'SI2 before SE2::StopAllSounds'`，各 3.2 秒后结束进程，用户确认“现在退出可以了”。
- 没解决的：根因（SoundWire 的 WinMM 不返回）在驱动侧；看门狗是兜底，不是干净退出。若你想从 FMOD 输出类型（AUTODETECT → WASAPI 等）下手，请另做，不要和这个冲突。

### 3.2 `WoW/Source/SoundInterface/SoundInterface2ZoneSounds.cpp`（约 35 行）　WOW64SND1E：脚本音乐修复 + 诊断
- **修复（只有这一行有行为变化）**：`SI2::PlaySoundFile` 里
  `sound->Create2D(filename, group != 4, nullptr, nullptr, false, false, 0, group != 5 ? 128 : 100, 0xFFFFFFFF);`
  的最后一个参数 `decodeBufferSize` 由 `0xFFFFFFFF` 改成 `0`。它会原样进入 FMOD 的 `exinfo.decodebuffersize`（`SE2::CreateWaveData`，SoundEngine.cpp 约 2834 行）；soundkit 声音都传 0，只有脚本音乐传 4GB，导致 5.9MB 的 mp3 流一直“准备不好”。
- **诊断日志（可保留或删除，不影响行为）**：只对 `group == 5`（脚本音乐）在 `RebornExitTrace.log` 写 `SOUND PlayMusic file=... enableAll/inMovie/enableMusic`、`SOUND previous script music: isPlaying/pos`、`SOUND PlayMusic result isPlaying/pos/groupVol`。用的是 `extern void RebornExitStage(const char*)`，消息放在 `static char` 里（因为 `RebornExitStage` 会保存指针给看门狗用，**不能传栈上缓冲**）。
- 实机证据：用户装 EXIT1E 后确认“登录界面有声音啦”。
- 我对“为什么 32 位下正常”没有证据（可能当时的 FMOD 对 0xFFFFFFFF 的处理不同）。这是推断成立，不是原因被完整证明。

### 3.3 `WoW/Source/Ui/MinimapFrame.cpp`（约 7 行）　WOW64MAP1A：队友圆点
- `CGMinimapFrame::RenderGroupBlips`：没有原版图标的职业（`m_icon < 1 || m_icon > 11`）原来用 `ObjectIcons` 图集的 `s_classBlipTexCoords[list]` 画点；用户装的 **DragonUI** 把自己的 `objecticons` 图集第 0/1 格做成了纯色方块（橙/浅黄），所以成了黄色方块（用户用 `/run DragonUI.db.profile.minimap.blip_skin=false; ReloadUI()` 后变回小圈，证实来源）。
- 改法：`bool generic = false;`，图标索引 `icon = (m_icon in 1..11) ? m_icon-1 : 4`，即这类队友改用 `PartyRaidBlips` 的白色圆点（小队圆环/团队实心点），不再依赖 `ObjectIcons`。
- **状态：用户已实测通过**（2026-11-13 稍后）：小地图队友显示为白色小圆点，用户说“和之前一样是小圆点，可以了”。随后用户又用 `/run DragonUI.db.profile.minimap.blip_skin=true; ReloadUI()` 打开 DragonUI 新图标皮肤，确认**新皮肤开着时队友也是圆点**，两种皮肤下都通过。
- 局限：只保证是圆点，不保证“数字 1 2 3”（两张图集里没有数字；用户说以前 32 位有数字，来源未查清，可能是旧 DLL 功能）。

## 4. 如何合入
1. 以你当前最新源码为基础，把三处改动手工合并（或用附带 diff）。我的完整三个文件在 `000Ascendupdate20261113\claudefix_20261113_阶段WOW64EXIT1E_修复脚本音乐流不前进_登录界面和PlayMusic应出声_累计_Claude\02_源码改动\`（只含 ZoneSounds）；Client.cpp 与 MinimapFrame.cpp 在 `...WOW64EXIT1B_...\02_源码改动\WoW\Source\`；我的整棵工作树在 `000Ascendupdate20261113\claudework_WOW64EXIT1A\source`（可直接 diff）。
2. 基线：你的 `000Ascendupdate20261110\codexwork_WOW64BUILD1B\source`（RACEPORT1C 累计；Client.cpp SHA256 前 12 位 `cbfcc4c80e92` → 我的 `5a848a1af5fd`；ZoneSounds `244f654c75ec` → `61f1a98ed7a1`；MinimapFrame `3d524b2e1bec` → `78184ce40a60`）。
3. 编译参数我照你的 CMakeCache 原样抄（`cmake_flags.txt`，`WOWCLIENT_CRASH_CONSOLE=OFF` 等），Release x64，MSVC 19.44；**在 Git Bash 里不要给 MSBuild 传 `/m`（会被改成 `M:/`），用 PowerShell 或 `-m`/`MSYS_NO_PATHCONV=1`**。
4. 出包前请核对：EXE 里能搜到字符串 `EXIT WATCHDOG` 与 `SOUND PlayMusic`；用户机器上 SoundWire 保持启用时点“退出”应在约 3 秒内自己关闭。

## 5. 产物（供对照）
| 包 | EXE SHA256 | 内容 | 用户实测 |
|---|---|---|---|
| EXIT1A | 7231356f…a531 | 看门狗 | （被 1B 取代） |
| EXIT1B | bd9fdb79…7a08 | +音乐诊断 +小地图圆点 | 看门狗日志证实生效；小地图未测 |
| EXIT1C | 157b6719…98cb | +声道组音量日志 | 仍无声 |
| EXIT1D | f7357092…9bf4 | +上一首 pos 日志 | 日志显示 pos 不前进 |
| **EXIT1E** | **60621732…47de7** | **+decodeBufferSize 改 0（修复）** | **登录界面有声音 ✔；小地图队友是小圆点 ✔** |
都在 `000Ascendupdate20261113\claudefix_20261113_阶段WOW64EXIT1*`；运行端现装的是 EXIT1E。

## 6. 还没解决、请你知道（不是这次的改动）
- **蛇人（Sethrak）披风不显示**：用户确认人族、食人魔、男库尔提拉斯披风都正常，只有蛇人没有。我读了模型：蛇人女性 `Character\RebornUIR3A\Sethrak\Female\Sethrak.m2`（Patch-YB，版本 264，155 骨骼）皮肤分组编号只有 `0` 和 `102`，**没有 15xx 披风分组**；男性（Patch-YJ）是 `0/101/102/103…`，也没看到 15xx。正常种族有（食人魔 1502–1506）。用户同意我试着给蛇人男女模型补披风网格资源包，我正在做，会走我自己的目录，不改你的文件；如果你那边也在处理蛇人/披风，请先在协作表登记，避免撞车。
- 用户之前看到披风“碎成尖角片”的是蛇人女性 Peggy（带角、长发）。
- **DCBOSS1A（服务端）**：阿努巴拉克门口机器人转圈的修复，`DcEngageActions.cpp` 约 20 行，用户之后测。与你的客户端线路无关，只是提一下。

## 6b. 披风调查结论更新（2026-11-13 稍后，**收回**上面“蛇人缺 15xx 披风网格是原因”的推断）
- 用户补充：**人族、食人魔、男库尔提拉斯披风正常；蛇人（男女）披风不显示，库尔提拉斯女性披风也有问题**。
- 我用 StormLib 读了各模型皮肤（00–03.skin）的分组编号：库尔提拉斯男、女（`Character\KulTiran\{Male,Female}\…`，patch-K）**四个 LOD 都没有 15xx**，结构几乎一样，但男性披风正常。所以“缺 15xx 就没披风”不成立。食人魔新模型有 1502–1506；蛇人女性（Patch-YB）只有 0/102；蛇人男性（Patch-YJ）0/101/102/103…。
- 客户端里披风由 `EsteriaAppearance.cpp` 的“外观记录”（`record.target == 15`，没装披风时值设 1500 隐藏，`character->m_data.m_geosets[15]`）和 `CharacterComponent.cpp::AddCape`（贴图 `Item\ObjectComponents\Cape\…`）共同决定。蛇人/库尔提拉斯没有像 Earthen/Haranir/Highmountain/Kyrian/Vulpera 那样的 `*Appearance.h` 种族表，我没找到它们的披风记录来自哪里。
- **未解决，且这是你的种族外观线**：请你确认蛇人（Sethrak，种族 36/…）与库尔提拉斯女性的披风记录/分组来源。我没有改任何文件。可做的用户侧对照：在客户端根目录建 `EsteriaOff.txt`（源码里 `Disabled()` 检测它）看披风是否出现，用来区分“Esteria 原生外观路径”与“模型本身”。

## 7. 我没做、没验证
- 没有进过游戏，“有声音/退出正常/小地图是圆点”都是用户实测。
- 没改你的任何目录、没写运行端（客户端根目录由用户自己覆盖）。
- 我的工作目录 `claudework_WOW64EXIT1A` 里有编译中间文件（约 260 MB `build-x64`），你不用动它；用户空间紧张时可以删，需要时 15 分钟能重编。

## 8. 登记
`协作说明_并行开发.md` 末尾已有 WOW64EXIT1A/1B/1C/1D/1E 各一行；下次你出 EXE 并合入后，请追加一行说明“已合入”。
