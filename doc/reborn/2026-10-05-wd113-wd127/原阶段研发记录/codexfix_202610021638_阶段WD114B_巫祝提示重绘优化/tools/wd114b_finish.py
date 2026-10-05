from pathlib import Path
import shutil,json,hashlib,subprocess,zipfile,difflib
root=Path('D:/000rebornWOW/000RebornWOWHighForkPRO')
p=Path(Path('D:/000rebornWOW/wd114b_path.txt').read_text(encoding='utf-8'))
base=Path(Path('D:/000rebornWOW/wd114_path.txt').read_text(encoding='utf-8-sig').strip())
rel=Path('02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents/NumericTooltip.lua')
lua=root/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe'
def sha(f):return hashlib.sha256(f.read_bytes()).hexdigest()
checks=p/'checks';checks.mkdir(exist_ok=True)
result=subprocess.run([str(lua),str(p/'tools/test_numeric_tooltip.lua'),str(p/rel)],capture_output=True)
assert result.returncode==0,(result.stdout,result.stderr)
(checks/'lua_results.txt').write_bytes(result.stdout+result.stderr)
old=subprocess.run([str(lua),str(p/'tools/test_numeric_tooltip.lua'),str(base/rel)],capture_output=True)
assert old.returncode!=0
(checks/'old_version_expected_failure.txt').write_bytes(old.stdout+old.stderr)
(checks/'source_changes.txt').write_text(''.join(difflib.unified_diff((base/rel).read_text(encoding='utf-8-sig').splitlines(True),(p/rel).read_text(encoding='utf-8').splitlines(True),fromfile='WD114A/NumericTooltip.lua',tofile='WD114B/NumericTooltip.lua')),encoding='utf-8')
original_zip=base.with_suffix('.zip')
assert sha(original_zip)=='3ce59a96fcec5ac90b1097b17454d85b822701f8a1428bed475acce6351ada40'
readme=f'''# WD114B：巫祝耗蓝提示重绘优化（待实机测试）

本包是 WD114A 的客户端提示增量包，不是新一轮技能累计包。

## 安装顺序

1. 先按 [WD114A 说明]({base.as_posix()}/README_覆盖与测试说明.md) 完成累计源码、Characters SQL、双端数据和客户端文件安装，并使用对应编译后的服务端。
2. 把本包 `02_覆盖到客户端根目录` 内的 `Interface` 文件夹覆盖到你的实际游戏客户端根目录。实际只更换 `Interface/AddOns/RebornWitchDoctorTalents/NumericTooltip.lua`。
3. 进入游戏执行 `/reload`。若之前没有完整安装 WD114A 客户端文件，先完整安装；本补丁依赖 WD114A 的 TOC 加载项及 `.wd114numbers` 服务端接口。

本补丁无需重新编译，不执行任何 SQL，不导入 DBC。保留 WD114A 的源码和全部其他内容；原 WD114A ZIP 未改动。不要把 `rollback_WD114A` 一起覆盖。

## 这次修改

技能费用始终采用服务端 CalcPowerCost 返回的整数；Lua 不按天赋草稿自行除以二，也不改变实际扣蓝。
费用文字变更后重新布局提示，并防止 Show 回调递归；客户端重建同一行文字时重新识别原始费用，避免旧文字覆盖射程或其他内容；异步回复按当前实际悬停技能刷新，不把旧技能费用写进另一个技能。覆盖中文、英文、带颜色和千位分隔符费用，以及零费用。

## 请测试

1. 激活并保存含洛阿强化的方案，鼠标停在灵魂巫祝技能书和动作条图标上约 1—2 秒。提示可短暂显示“同步中”，随后应显示服务端费用。
2. 若相同状态下未强化费用确实为 330，单独减耗50%通常应为165；以服务端最终整数为准，其他费用修正及取整可能影响结果。不要用不同装备、等级或增益下的351与330直接比较。
3. 切换到不含该天赋的方案，确认数值恢复；再切回来，随后 `/reload` 和重登各测一次。
4. 快速在灵魂巫祝与恶意妖术之间移动鼠标，确认费用不串技能，射程/施法时间不被覆盖。
5. 可额外施放一次核对实际扣蓝，尽量排除回蓝跳数干扰。用户目前仅反馈“很可能已减半”，实际扣蓝尚未确认；若实际仍错，需要另查机制。

若一直显示“同步中”，优先核对是否运行 WD114A 编译产物、对应插件是否完整及服务器回复是否正常；不能仅凭旧330数字判定实际扣蓝失败。

## 验证与回滚

实际 Lua 解释器运行旧 WD114 提示回归及新增重绘/回调用例通过；旧 WD114A 在新增布局回归断言处如预期失败。离线检查不等于客户端实机通过。未替用户编译、部署或修改生产数据库。
回滚时仅把 `rollback_WD114A/02_覆盖到客户端根目录` 中文件覆盖客户端并 `/reload`，恢复 WD114A 提示。不要回滚角色存档。
'''
(p/'README_覆盖与测试说明.md').write_text(readme,encoding='utf-8')
tutor='''# WD114B 提示同步教学

问题要分两条链：服务端 CalcPowerCost 算实际消耗，客户端提示负责显示。WD114A 已接入只读查询；私有法术 modifier 的空 family mask 不会给原生客户端提供通用费用更新，因此用服务端查询结果补显示，而不是在 Lua 再减一次。

本次只改 NumericTooltip.lua。draw 取得当前法术ID和已有服务器缓存；缓存仍校验激活方案与revision。每条费用行记录 original 与 rendered：当前文字仍是我们上次输出时，才能复用 original；如果原生UI已经写入新文本，就重新识别，不能盲目复用旧330。

只有文字发生变化才设置 changed，末尾调用 Show 让提示重新排版。refresh 的 wd114Drawing 标记阻止同步回调重入；正常返回时释放标记。没有变化就不重复布局。服务器回包只提供缓存，不强迫当前tooltip使用回复中的旧ID；refresh重新查看当前悬停法术，防止快速移动鼠标后费用串行。

费用识别仅接受整条“数字+法力值/Mana”，剥离颜色后匹配，避免描述段落或射程中的数字误匹配。零费用也直接显示服务器返回值。力量巫祝的当前效果附加行继续沿用WD114A，原始说明不做盲目文本替换。

tools/test_numeric_tooltip.lua 使用实际Lua解释器，模拟游戏API、原生文字重建与Show同步回调。覆盖入口SetSpell、SetSpellBookItem、SetAction、SetHyperlink、SetSpellByID，保留旧回包/草稿/方案/限流测试，并验证反复刷新不会再次减半。checks保存输出与可读差异。实际游戏仍需用户验收。

只读参考的永久方法：beascendskills/trace-and-port-coa-spell-resources/SKILL.md 和 beascendskills/build-wotlk-three-build-projection/SKILL.md。沿用本对话WD114A已完成的上游核对（commit 8be305f008a3b74f39344156291e479262242e5c）；本增量未新增技能机制、未重新声称该commit为当前最新。详细来源保留在WD114A/SOURCE_来源与适配.md。
'''
(p/'tutor.md').write_text(tutor,encoding='utf-8')
note=f'''## 2026-10-02 WD114B 巫祝提示重绘优化（候选待测试）

用户澄清实际耗蓝很可能已减半，要求基于WD114A优化显示。保留WD114A原ZIP，仅交付NumericTooltip.lua增量：费用重绘、原生行重建识别、Show重入保护、异步回包当前技能核对；不修改实际费用或角色存档。旧提示回归与新增Lua回调测试通过，旧A触发新增布局断言预期失败。未编译未部署未实机；实际扣蓝仍未确认。下一批机制开发仍以WD114A累计源码与本B客户端为候选基线，不能登记WD114已验收。

[覆盖说明]({p.as_posix()}/README_覆盖与测试说明.md) · [教学]({p.as_posix()}/tutor.md)
'''
(p/'memory.md').write_text(note,encoding='utf-8')
(p/'phaseFixForNewChat.md').write_text(note+'\n恢复工作时读取项目AGENTS、ruleAscend、refResourceAscend与永久技能目录。WD109—112已基本通过；WD113/114与DRBOT1A不能推定验收。\n',encoding='utf-8')
for target in ['updateMemory.md','refResourceAscend.md','beascendskills/skillsAscend.md','beascendtutor/tutorsAscend.md']:
 with (root/target).open('a',encoding='utf-8') as f:f.write('\n\n'+note)
for f in ['wd114b_build.py','wd114b_test_extend.py','wd114b_finish.py']:
 shutil.copy2(Path('D:/000rebornWOW')/f,p/'tools'/f)
(checks/'manifest.json').write_text(json.dumps({'baseline':str(base),'baseline_zip_sha256':sha(original_zip),'original_lua_sha256':sha(base/rel),'new_lua_sha256':sha(p/rel),'changed_runtime_files':[rel.as_posix()],'cpp_sql_dbc_changes':False,'lua_pass':True,'old_version_expected_failure':True,'in_game_tested':False},ensure_ascii=False,indent=2),encoding='utf-8')
files={str(f.relative_to(p)).replace('\\','/'):sha(f) for f in p.rglob('*') if f.is_file()}
(p/'SHA256SUMS.json').write_text(json.dumps(files,ensure_ascii=False,indent=2),encoding='utf-8')
z=p.with_suffix('.zip')
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED) as archive:
 for f in p.rglob('*'):
  if f.is_file():archive.write(f,str(f.relative_to(p)))
with zipfile.ZipFile(z) as archive:assert archive.testzip() is None
print(json.dumps({'zip':str(z),'sha256':sha(z),'files':len(files)+1},ensure_ascii=False))
