from pathlib import Path
import datetime,shutil,struct,json,hashlib,subprocess,zipfile
from wd19_common import dbc
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');A=Path(Path('wd119_path.txt').read_text());B=Path(Path('wd119b_path.txt').read_text());CODE=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots'
t=datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=-7))).strftime('%Y%m%d%H%M')
P=R/f'000Ascendupdate/000Ascendupdate{t[:8]}/codexfix_{t}_阶段WD119C_蛙变冷却同步与移动打断'
P.mkdir(parents=True,exist_ok=False);Path('wd119c_path.txt').write_text(str(P))
def put(n,s):
 f=P/n;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(s if isinstance(s,bytes) else s.encode('utf8'))
def copy(src,rel):put(rel,src.read_bytes())
rel='src/server/game/Entities/Player/Player.cpp'
raw=(CODE/rel).read_bytes();s=raw.decode('utf-8-sig')
old='mod && mod->spellId == 9003653 && IsAffectedBySpellmod(spellInfo, mod, spell)'
new='mod && (mod->spellId == 9003653 || (mod->spellId == 9003862 && spellInfo->Id == 9003861)) && IsAffectedBySpellmod(spellInfo, mod, spell)'
assert s.count(old)==1
s=s.replace(old,new)
s=s.replace('// WD63B: the exact server-only Hastened modifier has a zero client mask.','// WD119C: Hastened and Gonk use exact server-only modifiers with zero client masks.')
put('rollback/01_覆盖到源代码根目录/'+rel,raw)
put('01_覆盖到源代码根目录/'+rel,s)
# Retain all three accepted WD119B client corrections.
shutil.copytree(B/'02_覆盖到客户端根目录',P/'02_覆盖到客户端根目录')
num='02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents/NumericTooltip.lua'
s=(P/num).read_text(encoding='utf8');put('rollback/'+num,s)
needle='clean:match("秒施法$") or clean:match("秒施放$")'
assert s.count(needle)==1
s=s.replace(needle,'clean:match("秒施法时间$") or clean:match("秒施放时间$") or '+needle)
put(num,s)
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 raw=(A/prefix/'Spell.dbc').read_bytes();rows,pool=dbc(raw)
 assert rows[9003861][31]==14
 rows[9003861][31]|=1
 n=len(next(iter(rows.values())))
 out=struct.pack('<4s4I',b'WDBC',len(rows),n,n*4,len(pool))+b''.join(struct.pack('<'+'I'*n,*r) for r in rows.values())+pool
 put(prefix+'/Spell.dbc',out);put('rollback/'+prefix+'/Spell.dbc',raw)
 before,oldpool=dbc(raw);after,newpool=dbc(out)
 assert pool==newpool==oldpool
 assert [(k,i) for k in before for i in range(n) if before[k][i]!=after[k][i]]==[(9003861,31)]
put('checks/dbc.json',json.dumps({'base':'WD119A, explicitly under user test','delta_each_side':{'spell':9003861,'field':31,'before':14,'after':15},'all_other_rows_fields_strings':'unchanged'},indent=2))
for name in ['wd119b_numeric_test.lua','wd119b_book_test.lua','wd119b_cooldown_test.lua','syntax.lua']:copy(B/'tools'/name,'tools/'+name)
test=(P/'tools/wd119b_numeric_test.lua').read_text(encoding='utf8')+'''
locale='zhCN';now=0;frames={};sent={};M=assert(loadfile(file))()
for i,v in ipairs({{1000,120000},{1500,60000},{0,120000}}) do
 id=9003861;now=i*3;reset();M.invalidate()
 GameTooltipTextLeft3=font('0.943秒施法时间');GameTooltipTextRight3=font('2分钟冷却时间')
 GameTooltipTextLeft4=font('冷却时间剩余：2分钟')
 M.refresh(GameTooltip);M.receive('WD114|'..seq()..'|9003861|ok|743|'..v[1]..'|'..v[2]..'|10|1')
 assert(GameTooltipTextLeft3.text==(v[1]==0 and '瞬发法术' or string.format('%.2f秒施法',v[1]/1000)))
 assert(GameTooltipTextRight3.text==string.format('%g秒冷却时间',v[2]/1000))
 assert(GameTooltipTextLeft4.text=='冷却时间剩余：2分钟') -- never fake the real cooldown timer
end
print('PASS WD119C Chinese cast-time header, three blessing states; remaining cooldown untouched')
'''
put('tools/wd119c_numeric_test.lua',test)
lua=R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe'
base=P/'02_覆盖到客户端根目录/Interface/AddOns'
outputs=[]
for sc,target in [('wd119c_numeric_test.lua','RebornWitchDoctorTalents/NumericTooltip.lua'),('wd119b_book_test.lua','RebornWitchDoctorSkillBook/RebornWitchDoctorSkillBook.lua'),('wd119b_cooldown_test.lua','RebornWDCooldownTooltip/Cooldown.lua')]:
 r=subprocess.run([str(lua),str(P/'tools'/sc),str(base/target)],capture_output=True);out=(r.stdout+r.stderr).decode('utf8',errors='replace');assert r.returncode==0,out;outputs.append(out)
put('checks/lua.txt','\n'.join(outputs))
# Check the packet change is limited to existing native control flow and exact spell pair.
delivered=(P/'01_覆盖到源代码根目录'/rel).read_text(encoding='utf8')
original=raw # DBC variable is deliberately unrelated to source verification below
source=(P/'rollback/01_覆盖到源代码根目录'/rel).read_text(encoding='utf-8-sig')
assert delivered==source.replace(old,new).replace('// WD63B: the exact server-only Hastened modifier has a zero client mask.','// WD119C: Hastened and Gonk use exact server-only modifiers with zero client masks.')
checks=[]
for modifier,spell,affected,want in [(9003862,9003861,True,True),(9003862,9003432,True,False),(9003862,9003861,False,False),(9003863,9003861,True,False),(9003653,9003432,True,True),(9003653,9003861,False,False)]:
 assert ((modifier==9003653 or (modifier==9003862 and spell==9003861)) and affected)==want
 checks.append([modifier,spell,affected,want])
put('checks/source_scope.json',json.dumps(checks))
put('README_覆盖与测试说明.md','''# WD119C 蛙变术冷却同步与移动打断

前置：已安装WD119A源码、SQL及双端数据。此包是WD119A的增量修复，并含WD119B三个客户端文件，避免面板回退。没有新技能或SQL。

## 安装
1. 备份当前Player.cpp与双端Spell.dbc、三个客户端Lua。
2. 将01_覆盖到源代码根目录覆盖到源码根目录，重新编译并替换服务端程序。
3. 覆盖03_覆盖到服务端根目录的Data/dbc/Spell.dbc。
4. 将client_mpq输入_导入现有Patch-XA/DBFilesClient/Spell.dbc按路径导入客户端现有Patch-XA，保存并关闭MPQEditor；备份MPQ放Data目录外。
5. 覆盖02_覆盖到客户端根目录，重启服务端，完全退出客户端后重新进入。

## 修正
- 贡克祝福是服务端按精确ID匹配的法术修正，客户端没有匹配掩码。原服务端实际计算60秒，但未强制下发最终冷却包；现沿用迅捷召唤既有路径，对9003862影响9003861时发送最终原生冷却。不重复减60秒，不在Lua里伪造剩余倒计时。
- 蛙变术的双端InterruptFlags原值14缺少MOVEMENT位1。现在只把9003861这一字段改为15，其他所有行、字段和字符串保持不变。普通版/贡克版有读条时移动中断；克拉格瓦版瞬发仍允许移动施放。
- 提示匹配新增“秒施法时间/秒施放时间”，修复原生标题0.943秒而服务端当前行1.42秒的矛盾。真实读条仍受急速影响，1/1.5秒是未计急速的基础值。

## 测试
先让旧冷却自然结束，再重新施放，不能用安装前已启动的120秒冷却判断新包。
1. 普通版：基础1秒读条、120秒冷却；读条中走动应取消，不进入完整技能冷却。
2. 贡克：基础1.5秒读条、60秒冷却；确认动作条与技能提示的实际剩余倒计时从约1分钟开始。读条中移动同样应取消。
3. 克拉格瓦：瞬发、120秒冷却；移动时施放仍正常。
4. 成功释放后切方案不能清掉已有冷却；重登后检查剩余时间。复测迅捷召唤45秒冷却和WD119B面板。

## 验证边界
通过累计Lua数值/技能书只读/冷却提示回归、截图中文标题三种状态测试、双端DBC逐字段差异校验、源码增量与6组精确ID条件检查。没有替用户编译或实机测试；实际施法、网络包及移动中断需要游戏验收。
回退文件在rollback，对应本包变更前的源文件及WD119A/WD119B数据；回退需双端一致并重新编译。WD120目录仍只是下一批研发证据，未混入本包。
''')
put('memory.md','''# 故障与来源
用户图：贡克已保存，数值查询60秒，客户端剩余2分钟；后续报告读条中移动不取消。两项有独立原因。
源码Player::AddSpellAndCategoryCooldowns先ApplySpellMod再保存冷却，但needsCooldownPacket的精确ID只有WD63B迅捷9003653，漏9003862；_AddSpellCooldown仅保存冷却及needSend标志，本函数不会立即发送最终SMSG_SPELL_COOLDOWN。沿既有路径补精确对，拒绝二次应用修正。
Spell::prepare及update均按InterruptFlags&MOVEMENT检查，瞬发不走读条移动中断；WD119A记录14而原生Hex15，MOVEMENT=1。只补位，不改全局施法/移动逻辑。
技能来源沿用本会话新鲜核对HEAD d7620151fa4267ab90c7e0554b32628017df241a及官方20260925和PR4753。本批适配本地客户端协议/原生InterruptFlags，不改官方贡克数值。使用trace-and-port-coa-spell-resources与既有UI稳定规范，未将用户报告升级为通过。
Player.cpp来自当前项目源码（WD119A包无该文件），包内保留完整输入和精确差异证据。双端DBC分别取用户明确测试的WD119A对应侧，不拿锁定MPQ的旧解包替代当前数据。
''')
put('tutor.md','''# 数值、冷却与移动是三条链
提示查询调用ApplySpellMod可以得到60秒，不能证明客户端也已收到60秒。服务端保存CD后，应发送明确的最终冷却包，使客户端不再用基础DBC120秒推算；发送时复用已经计算的rec，不能再减一次。
移动能否打断由InterruptFlags控制，不由CastTime非零自动推导。14二进制1110，15为1111，最低位是移动中断。保留其余位，按具体技能修复双端；瞬发没有等待中的读条，因此不应因移动而被拦。
Lua只修标题格式，不改GetSpellCooldown或动作条剩余值。这样真实冷却若仍异常，不会被假显示掩盖。逐项验证普通/贡克/克拉格瓦，冷却开始前、过程中、切方案、重登分别观察。
''')
put('phaseFixForNewChat.md','WD119C候选修复WD119A贡克60秒冷却包缺失与蛙变InterruptFlags缺MOVE。需覆盖Player.cpp重编译+双端Spell.dbc+三个Lua，含WD119B；不执行SQL。未编译未实机。等待普通/贡克读条移动取消、瞬发正常和实际CD60/120实测。酿造WD120仅审计未交付。\n')
copy(Path(__file__),'tools/wd119c_build.py')
manifest={f.relative_to(P).as_posix():hashlib.sha256(f.read_bytes()).hexdigest() for f in P.rglob('*') if f.is_file()}
put('SHA256.json',json.dumps(manifest,ensure_ascii=False,indent=2))
z=P.with_suffix('.zip')
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED) as a:
 for f in P.rglob('*'):
  if f.is_file():a.write(f,f.relative_to(P).as_posix())
with zipfile.ZipFile(z) as a:
 assert a.testzip() is None
 for n,h in manifest.items():assert hashlib.sha256(a.read(n)).hexdigest()==h
note=f'\n\n## 2026-10-03 WD119C 蛙变冷却与移动回归（候选待测）\nWD119A用户发现贡克查询60秒但客户端实际倒计时120秒，以及移动不中断读条。Player.cpp精确补9003862→9003861的最终冷却包；双端9003861 InterruptFlags14→15补MOVEMENT位；提示识别秒施法时间。保留WD119B。累计Lua、逐字段数据差异与源码范围检查通过，未编译未实机；不宣称WD119A整体通过。需源码重编译+双端DBC+Lua，不需SQL。\n[覆盖说明]({P.as_posix()}/README_覆盖与测试说明.md)；ZIP SHA256 {hashlib.sha256(z.read_bytes()).hexdigest()}。\n'
for rel in ['updateMemory.md','updateListAscend.md','refResourceAscend.md','tutorMemory.md','beascendskills/skillsAscend.md','beascendtutor/tutorsAscend.md','beascendskills/trace-and-port-coa-spell-resources/SKILL.md','beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md']:
 with (R/rel).open('a',encoding='utf8') as out:out.write(note)
print(z)
