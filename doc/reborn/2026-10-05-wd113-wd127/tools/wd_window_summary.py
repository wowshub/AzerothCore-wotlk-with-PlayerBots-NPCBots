# -*- coding: utf-8 -*-
from pathlib import Path
import re,json,hashlib,shutil,datetime,struct
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO')
C=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots'
A=R/'000Ascendupdate'
F=A/'000Ascendupdate20261005/codexfix_202610050306_阶段WD127F_投掷泼洒冷却完整同步'
P=A/('000Ascendupdate20261005/codexsummary_20261005'+datetime.datetime.now().strftime('%H%M')+'_阶段WD113至WD127_成功失败教学与交接')
P.mkdir(exist_ok=True)
Path('D:/000rebornWOW/wd_summary_path.txt').write_text(str(P),encoding='utf-8')
def write(rel,text):
 p=P/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(text,encoding='utf-8')
def append(path,text):
 path.parent.mkdir(parents=True,exist_ok=True)
 with path.open('a',encoding='utf-8') as f:f.write(text)
stages=[]
for day in ['20261002','20261003','20261004','20261005']:
 for d in sorted((A/('000Ascendupdate'+day)).iterdir()):
  if d.is_dir() and re.search(r'阶段WD\d+[A-Z]',d.name):
   code=re.search(r'阶段(WD\d+[A-Z])',d.name)[1]
   z=d.with_suffix('.zip')
   stages.append(dict(stage=code,name=d.name,path=str(d),zip=str(z) if z.exists() else None,sha256=hashlib.sha256(z.read_bytes()).hexdigest() if z.exists() else None,has_docs=any(d.glob('*.md'))))
write('阶段包清单.json',json.dumps(stages,ensure_ascii=False,indent=2))
scope='''# 本窗口结论：WD113—WD127

用户在2026-10-05明确反馈：“现在这次的技能测试都通过了”。据此将最终WD127F两种药水的基本使用与显示同步登记实测成功；前面已明确确认的技能保持原通过状态。该总反馈不等同每一级、每种装备、PvP递减、机器人、多人组合和数据库故障恢复都已经逐项测试。

本窗口从用户对WD113／WD114的洛阿强化、耗蓝显示、假死及强效混合反馈起，推进到WD127F。WD109—112是开窗前依赖，承接但不计入本窗口新增。源码Git上次检查点停在WD85，因此本次提交也带入WD86—112尚未提交的必要累计依赖；这些不伪称本窗口新开发。

## 实际修复清单与验收证据

| 阶段 | 开发或修正 | 用户确认／保留边界 |
|---|---|---|
| WD113 | 洛阿强化：指定巫祝减耗50%、力量效果+20%；希里克祝福：破咒多一次尝试；显性诅咒：五类诅咒减耗25% | 洛阿明确通过；显性书页已显示，后续“前面测试都通过”为整体基本反馈，未单独记录每类每等级耗蓝 |
| WD114A/B | 服务端权威耗蓝与效果查询；重绘防重复、快切技能不串值；假死5分钟／30秒；通用强效混合4%／15% | 耗蓝提示、洛阿、假死明确通过；B只修显示，不能说截图证明原服务器扣蓝错误 |
| WD114C/D→WD119B | 诊断已学技能、分类与分页；移除写原生书页和按钮的补漏／定位路径，解决面板污染 | C的“缺项”假设被诊断证据否定；D是定位工具不是最终修复；用户明确覆盖119B恢复正常 |
| WD115 | 假死节点／书页同图标；强效混合同一法术家族只授予最高等级，撤销重复9003854 | 4%/15%与8%/30%最高级方案整合；保留两个兼容入口，未证明官方现服也保留双入口 |
| WD118B | 把五个已引用BLP补进MPQ，使原生鼠标拖影可加载 | 用户明确假死拖动图标可见；不是重写PickupSpell |
| WD116/117 | 沃金守望25%减伤、每秒基础2%恢复、10秒／120秒CD；灵魂行者两级把持续和效果提高10%/20% | 沃金明确通过；二级12秒／30%／2.4%与迅捷神像联动随前批整体通过，概率与取整边界未全测 |
| WD118 | 化蛇：5秒、速度+80%、清旧定身减速、不能攻击施法、配套效果随父Aura清理 | 技能面板异常经119B解决；不能称全伤害免疫或完整PvP验收 |
| WD119A/C＋WD121B | 蛙变术、贡克与克拉格瓦祝福；贡克120→60秒；普通／贡克读条移动中断、克拉格瓦瞬发 | 用户六项逐条确认通过；C施放前同步不够，121B后置发送才闭环 |
| WD120 | 免费大锅入口、丛林蘑菇每6秒范围治疗、药水投掷7级／15秒、蘑菇18秒HoT | 用户明确三项通过；HoT为隐藏附效，不是第二个可加点技能 |
| WD121 | 新鲜配料两级15%/30%；药水增效投掷直接和蘑菇HoT +20% | 用户明确两项通过 |
| WD122A/B | 丛林绽放：每跳+100%、8→5人；丛林医师：6→4秒、仍8人；二者互斥 | 用户明确该批通过；先修不存在的TARGET_UNIT_SRC_AREA_RAID枚举 |
| WD123A/B | 泼洒药水7级／40码选点／10码8友方／15秒；12秒每3秒蘑菇HoT；实时治疗 | 用户明确泼洒与附加治疗通过；修正上游子法术误走鱼油 |
| WD124A/B | 药水投手两种药水减5秒；药师两级；再生者；wanted重名修正 | 投手在127F才实机闭环；药师／再生者数值编码另有复核项，不能以总反馈抹去已见数据矛盾 |
| WD125 | 鱼油与蛙骨准备；不同投掷／泼洒子效果；发射时配料快照；目前单配料 | 已合入最终累计，总体基本测试反馈；没有逐项鱼油自动学习／护盾量／弹道换料的明确记录 |
| WD126 | 缩小盟友：8秒、闪避+50%、外观缩小约25%、120秒 | 已合入累计；未收到独立逐项数值／目标拒绝反馈 |
| WD127A/B/C | 蛇神门徒：额外治疗系数+15%、破咒附近第二目标、GCD最低1秒；AEIds统一88；6缺失节点补Data.lua | 面板可见由用户截图确认；蛇神门徒各项参数没有独立逐条战斗日志 |
| WD127D/E/F | 投手图标与书页统一；完整冷却协议；施放后动作条同步；右侧标题；投掷回包；毫秒偏差 | F最后明确通过；D/E只是中间失败／局部修正版，不能推广它们 |

## 仍需进一步复核或完善

1. **药师／再生者DBC已见数值矛盾**：最终服务端数据9003898是die0/base49；9003899是die0/base9及die0/base49；9003900是die0/base9。核心CalcValue的die0分支不加1。当前分别对应49%、9%／49%、9%的原生量，而说明为50%、10%、10%。本次仅归档，不修改用户已测试包；新窗口应优先核对实际Aura Amount／原生消费函数，确认后定向双端修正并检查其他WD124记录。相关JSON见checks。不能简单把所有旧BasePoints都加1，很多别的记录真实die1。
2. 酿造树布局仍为旧项目树加临时空位置，并非完整20260925官方树。官方同号节点有跨版本复用，7131不能按新版ID直接覆盖成另一技能；整树升级需迁移台账，保护原方案和账本。
3. 双配料Mixologist未移植：现有快照、配料互斥先保持。不要为了继续开发提前把容量改2。
4. 鱼油自动学习的升级／重登、蛙骨护盾具体量、缩小盟友目标边界、蛇神门徒附近第二驱散与GCD、PvP／机器人／大量友方组合列为细项续测，不能重复要求用户已经通过的基本流程。
5. DRBOT1A不属本窗口巫医修复的成功结论；无明确反馈。未知旧GM测试夹具失败也没有定位为生产BUG。

## 归档边界

有效累计母版是 **202610050306 WD127F**，不是0305构建中断目录。WD118“森金之临”草稿、022207图标草稿等无完整文档／ZIP的目录不是额外发布阶段，已在包清单标出。不覆盖、不删除历史包。成功方法进入Skill，失败只做反例／备份。此阶段只提交、推送、归档，没有新编译EXE、生产SQL或客户端部署。
'''
write('memory.md',scope)
write('成功与待测清单.md',scope)
failures=[
 ('WD114A','只改费用显示初稿未覆盖原生重建与快切','WD114B','查询权威值＋保留原文＋重入与序号/epoch/revision/active核对'),
 ('WD114C','认为已学技能缺列表，但日志证实槽和列表均存在','WD119B','先用只读ID/槽/页证据区分授予、列表、渲染；不要继续补不存在的缺项'),
 ('WD114D','定位工具写原生渲染表/按钮与页状态，跨安全边界','WD119B','删除写入/更新受保护按钮；不能因弹窗提DBM就断言DBM为源头'),
 ('WD115A','插件书页可见而原生鼠标图标透明，BLP只在loose插件目录','WD118B','保持PickupSpell，按SpellIcon引用把资源补入MPQ并完全重启'),
 ('WD118A','安装累计包后技能面板出现专业/宠物UI污染','WD119B','旧C/D路径仍累计存在，清理污染插件而非改化蛇C++'),
 ('WD119C','贡克真实60而动作条120，施放前冷却包可被GO覆盖','WD121B','必须核对最终网络发送顺序，GO之后清客户端预测再发真实剩余'),
 ('WD122A','TARGET_UNIT_SRC_AREA_RAID目标枚举本核心不存在','WD122B','改为本核心TARGET_UNIT_CASTER_AREA_RAID；modules.lib是连带失败'),
 ('WD124A','同AEApply作用域两个wanted数组不同长度','WD124B','新四项改supportWanted，仅改相应引用；原八项不变'),
 ('WD127A','AEIds定义88、声明/遍历86','WD127B','统一AEIdCount=88用于定义、extern和查询/读取遍历'),
 ('WD127B','逻辑和保存已加节点，Data.lua绘图源没加六项','WD127C','检查Panel读取真实数据源，补六节点；不要靠截图猜灰图标身份'),
 ('WD127D','std::min/max有符号与无符号模板推导失败','WD127E','显式int32模板并先转型再做减法，独立MSVC复现失败和修正'),
 ('WD127E','仅施放前发包、只改Left说明、Toss漏占位、-5001/die0','WD127F','两个技能全等级、后置包、左右文本、协议实参、实际字段语义同时检查'),
]
rows=['# 失败归档：禁止作为安装基线\n','| 中间包 | 实际失败 | 最终替代 | 教训 |','|---|---|---|---|']
for code,reason,replaced,lesson in failures:rows.append(f'| {code} | {reason} | {replaced} | {lesson} |')
rows.append('\n源ZIP原样复制到本目录backup_zips，SHA256与原文件比较；旧版本不可直接覆盖当前环境。已保存新节点后旧SQL拒绝unknown node是版本保护，不应删除守卫或清空角色记录。\n')
backups=[]
codes={x[0] for x in failures}
for st in stages:
 if st['stage'] in codes and st['zip']:
  z=Path(st['zip']);dest=P/'失败修复备份/backup_zips'/z.name;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(z,dest)
  assert hashlib.sha256(dest.read_bytes()).hexdigest()==st['sha256'];backups.append(st)
write('失败修复备份/README.md','\n'.join(rows))
write('失败修复备份/备份哈希清单.json',json.dumps(backups,ensure_ascii=False,indent=2))
write('失败修复备份/开发工具失败补记.md','''# 未进入生产的工具／测试失败

构建锚点不匹配被assert阻断；双语Lua嵌套错误先测出后修；SpellDuration实际位于patch-S；MySQL8 rank保留字需反引号；临时SQL夹具缺schema；新增节点使旧越界向量失效；一次GM夹具失败复测通过但未定位。它们见各原memory，不算新技能成功，也不能称修复了生产故障。

本窗口F归档脚本曾在Python3.9使用Path.write_text(newline=...)报错，后改write_bytes；0305为中断目录，0306才是最终包。归档教学生成器须显式UTF-8。当前Git通用文本属性使ZIP被CRLF转换；8100818d2增加归档目录*.zip binary并重录，git show读取blob与原ZIP比较通过，CRC完整。远端最终版本正确；初始559fe78fd里的归档ZIP不可单独取用，至少包含8100818d2。
''')
# Preserve every stage's original lesson and checks without pretending old claims are current.
lesson_index=['# 原阶段教学索引\n\n先读本窗口总教学。这里保留原文，其中“候选”和旧数值判断仅代表当时；当前结论以成功与待测清单为准，特别是WD124的die/base编码误判。\n']
for st in stages:
 d=Path(st['path']);t=d/'tutor.md'
 if not st['has_docs']:continue
 dest=f'逐阶段教学/{d.name}.md'
 original=t.read_text(encoding='utf-8-sig',errors='replace') if t.exists() else '该阶段没有独立tutor；详见原说明与本窗口总教学。'
 write(dest,f'# {d.name}\n\n原阶段：[{d.name}]({d.as_posix()})\n\n当前验收见[总清单](../成功与待测清单.md)，不要把历史候选状态或错误假设当成当前结论。\n\n'+original)
 lesson_index.append(f'- [{d.name}]({dest})')
 evidence=P/'原阶段研发记录'/d.name;evidence.mkdir(parents=True,exist_ok=True)
 for name in ['memory.md','README_覆盖与测试说明.md','来源与适配说明.md']:
  if (d/name).exists():shutil.copy2(d/name,evidence/name)
 for parent in ['checks','tools']:
  if (d/parent).exists():
   for f in (d/parent).iterdir():
    if f.is_file() and f.suffix in ['.py','.lua','.json','.txt','.md','.cpp','.log']:
     out=evidence/parent/f.name;out.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(f,out)
write('逐阶段教学索引.md','\n'.join(lesson_index))
write('git记录.md','''# 已提交并推送

远端： https://github.com/wowshub/AzerothCore-wotlk-with-PlayerBots-NPCBots.git
分支： threemodelcardpro

- 559fe78fdbeefba87d88c0d29bcbc4be5d6bd693：28项文件，累计巫医模块、核心依赖、最终测试资源归档。
- 8100818d20b1a7d1262627daeb3333ec65cef8c8：归档ZIP强制binary，恢复原字节。最终ZIP SHA256 e68282509364048d9b32009ac07b7c7f14dfa5fb46ae918560856201e4e90417。
- 首轮push实际输出f758d118b..8100818d2，随后独立ls-remote确认同一完整SHA。此前未推送的32095f2e5同时进入该分支历史。

排除并原样保留：ACSoap独立故障修改、shell执行位、PSD、子模块指针、种族Lua备份等非巫医改动。源码工作树因此不宣称完全干净。14份WD127F交付源码与提交前实际工程逐字节一致。只有已有Allocation.inc末尾额外空行的空白提示被单独记录；检查不忽略实质缩进／合并标记。

总结／Skills／Tutor随后作为第二轮文档提交推送；其最终SHA由Git日志和本窗口最终回复给出，避免提交文件自引用自身SHA。
''')
data=[]
b=(F/'03_覆盖到服务端根目录/Data/dbc/Spell.dbc').read_bytes();_,n,cols,size,_=struct.unpack_from('<4s4I',b)
for i in range(n):
 row=struct.unpack_from('<'+'I'*cols,b,20+i*size)
 if row[0] in [9003897,9003898,9003899,9003900]:
  data.append({'spell':row[0],'effects':[{'effect':row[71+j],'die_sides_field74':row[74+j],'base_points_field80':struct.unpack('<i',struct.pack('<I',row[80+j]))[0],'aura_field95':row[95+j]} for j in range(3) if row[71+j]]})
write('checks/药师再生者编码复核.json',json.dumps(data,indent=2))
print(P)
