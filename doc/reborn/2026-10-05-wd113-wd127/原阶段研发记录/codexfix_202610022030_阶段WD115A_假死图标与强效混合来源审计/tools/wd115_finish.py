from pathlib import Path
import json,hashlib,zipfile,shutil,datetime
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd115_path.txt').read_text(encoding='utf8'))
def put(name,s):(P/name).write_text(s,encoding='utf8')
# Simulate the grant/remove sequence for all old/new ownership combinations and stale duplicate aura.
def reconcile(c,b,known,auras):
 known.discard(9003854);auras.discard(9003854);rank=max(c,b)
 for tier in [2,1]:
  spell=9003620+tier-1
  if rank!=tier:known.discard(spell);auras.discard(spell)
 if rank:known.add(9003620+rank-1);auras.add(9003620+rank-1)
 return known,auras
count=0
for oldc in [0,1]:
 for oldb in [0,1,2]:
  for c in [0,1]:
   for b in [0,1,2]:
    for stale in [False,True]:
     k,a=reconcile(oldc,oldb,set(),set())
     if stale:k.add(9003854);a.add(9003854)
     k,a=reconcile(c,b,k,a);expected={9003620+max(c,b)-1} if max(c,b) else set()
     assert k==a==expected
     assert reconcile(c,b,k.copy(),set())==(expected,expected)
     count+=1
put('checks/ownership-model.txt',f'{count} transition/stale-state cases passed, including passive restoration. This is a behavior model, not a compiled C++ runtime test.\n')
sha=json.loads((P/'research/head.json').read_text())['sha']
readme=f'''# WD115A 假死图标与强效混合整合（候选）

假死药剂用户基本实测通过。本包修正其图标，并纠正强效混合同源法术重复发放。未代编译、未部署、未修改角色数据库。

## 安装

这是基于已覆盖 WD114A 源码及当前已安装 Lua 的增量包；保留 WD114B 数值提示和 WD114D 定位工具。
1. 退出游戏、停服并备份当前文件。覆盖 `01_覆盖到源代码根目录`，重新编译服务端。
2. 覆盖 `02_覆盖到客户端根目录`；包含 Allocation.lua 和两个现有官方图标资源。
3. 将 `client_mpq输入_导入现有Patch-XA/DBFilesClient` 的 Spell.dbc、SpellIcon.dbc 导入现有 Patch-XA 的同名内部路径。不要把这个目录直接丢到客户端根目录；MPQ备份放Data外。
4. 覆盖 `03_覆盖到服务端根目录` 中独立服务端 Spell.dbc，再启动。双端 Spell.dbc 不能互换。
5. 本包不需要 SQL。不要重复执行历史 WD113A schema。

## 实际行为

- 假死药剂9003853：技能书与节点31118使用同一份官方 `nhi_arcanepotion_Border` 图标；未改动已通过的假死机制。
- 通用节点12264和酿造节点7131保留。通用给1级；酿造给1或2级。正式激活时合并为最高等级：仅通用/酿造1级=4%治疗、15%法术减仇恨；酿造2级=8%/30%。不额外叠加通用的一份。
- 技能书只留9003620或9003621中的最高级，统一名称“强效混合”与同一节点图标。旧独立9003854自动撤销，保留数据记录用于兼容。
- 已保存节点、方案编号、购买资格、AE/TE账本不改。重复投入不额外生效，也不会自动返还点数；两个入口提示已经说明。现有加点不需要为安装本包重置，后续规划可避免重复投资。保留双入口是本项目兼容方案，不宣称已证明飞升当前服务器的加点规则。
- 图标缺失排查已收敛：用户截图中假死和显性诅咒都已显示；不再把这个问题归因于C++未授予。

## 来源与边界

在线核对 CoAwow 上游提交 `{sha}`，相关 Issue #1290、#2190及当前 percent-effectiveness/death-draught 场景文件保存在research。
本项目树数据：12264引用503748；7131引用503748/504888；两个入口确实指向同一技能等级家族。这支持收益合并，不支持原来复制出9003854后额外叠加。
20260925客户端 Data/Content/CharacterAdvancementData.json 不含这三个法术，节点ID还存在跨版本复用，所以没有用其同号节点推断当前服务器开放规则。没有获得飞升线上服务器配置，不能宣称复刻其现行加点方案。
上游场景按DBC测试固定减仇恨量，与文字百分比不同；本项目继续保留按说明实现的15%/30%法术威胁减少，未复制该差异。

## 测试

双端DBC全记录字符串偏移、长度及限定记录差异校验通过。客户端只新增两条SpellIcon，图标文件与节点原文件逐字节相同。所有非目标Spell记录保持原值。72组拥有状态/切换/旧重复被动/被动丢失恢复行为模型通过；模型不等同C++运行测试。Lua语法检查另见checks。未编译和实机验收。

请测：假死节点与技能书图标一致；仅通用显示1级；酿造2级显示2级；两边同时点不会出现第二项；切换不含此技能的方案后移除，切回与重登恢复。测试治疗/仇恨时保持装备、其他增益相同。

## 回滚

rollback按原路径保存本批覆盖文件。停服退出后恢复源码并重编译、恢复Lua及各自双端DBC；重登按原方案恢复旧技能。新增的两份图标是现有同名同内容资源，可保留。不要回滚角色表或删除已购方案。
'''
put('README_覆盖与测试说明.md',readme)
put('tutor.md','''# 同源天赋整合教程

1. 从节点Spells数组追到原始法术编号，不能按中文译名判断是否同一技能。12264的503748正好是7131的第一级。
2. 先清除以前人为复制的9003854，再根据两个来源的最大等级授予9003620/21。逐级从高到低移除时使用已有removeSpell参数，避免移除高等级又自动学回低等级。
3. 两个来源都没有才撤销整组。已学但永久被动丢失时重新触发，覆盖方案切换与重登恢复。
4. 保留节点存档位和账本，避免借一次技能修复改坏方案购买和保存。没有证据证明官方双入口可同时投资，因此本包明确采用兼容的最高等级规则，而非声称官方双加点行为。
5. 图标沿节点Icon追到现有BLP，SpellIcon新增独立路径记录，Spell.IconID只改目标法术。不能把旧公共图标记录换图，否则所有使用它的技能都会变。
6. 本次读取trace-and-port-coa-spell-resources与build-wotlk-three-build-projection永久Skill。技能书分类不变；DBC行与方案位不变；未新增职业或扩大UI资格。
''')
put('memory.md',readme)
for name in ['wd115_build.py','wd115_audit.py','wd115_finish.py']:
 dest=P/'tools'/name;dest.parent.mkdir(exist_ok=True);shutil.copy2(Path('D:/000rebornWOW')/name,dest)
print('Docs and',count,'model cases complete.')
