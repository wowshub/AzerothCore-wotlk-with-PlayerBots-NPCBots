from pathlib import Path
import sys,struct,json,hashlib,zipfile,shutil
R=Path(r'D:\000rebornWOW\000RebornWOWHighForkPRO');D=R/'000Ascendupdate/000Ascendupdate20261029'
P=D/'codexfix_20261029_阶段WDWP1B_巫医近战武器累计学习';A=D/'codexfix_20261029_阶段WDWP1A_巫医拳套与武器大师'
sys.path.insert(0,str(D/'codexfix_20261029_阶段UIR1A_蛇人与双头食人魔预览/tools'));from storm_read import Archive
def put(rel,data):
 p=P/rel;p.parent.mkdir(parents=True,exist_ok=True)
 if isinstance(data,str):p.write_text(data,encoding='utf8')
 else:p.write_bytes(data)
def js(rel,data):put(rel,json.dumps(data,ensure_ascii=False,indent=2))
sha=lambda b:hashlib.sha256(b).hexdigest()
event='|2026-10-29|Codex|WDWP1B|占用独立副本|开发中|XA/服务端双表武器资格；职业资格Skill/reference/Tutor/索引|本轮现场表与NPC只读核对；A拳套累计|用户授权剑斧锤长柄，保留拳套；不改生产/SQL/双持|'
with (R/'协作说明_并行开发.md').open('a',encoding='utf8') as f:f.write('\n'+event+'\n')
assert event in (R/'协作说明_并行开发.md').read_text(encoding='utf8')
targets={196:('单手斧',44,248),197:('双手斧',172,3213),198:('单手锤',54,254),199:('双手锤',160,3214),200:('长柄武器',229,2928),201:('单手剑',43,252),202:('双手剑',55,256),15590:('拳套',473,8438)}
def parse(b):
 magic,n,f,z,ss=struct.unpack_from('<4s4I',b);assert magic==b'WDBC' and z==4*f and len(b)==20+n*z+ss
 return n,f,z,[struct.unpack_from('<'+'I'*f,b,20+i*z) for i in range(n)]
live=R/'beascendclient/newrebornWOWli20261029beAscend/Data';arc=Archive(live/'Patch-XA.mpq')
client={t:arc.read('DBFilesClient\\'+t+'.dbc') for t in ['SkillLineAbility','SkillRaceClassInfo']};arc.close()
scans=[]
for p in sorted(live.glob('*'),key=lambda p:p.name.lower()):
 if p.suffix.lower()!='.mpq' or not p.name.lower().startswith('patch-') or p.name.lower()<='patch-xa.mpq':continue
 arc=Archive(p)
 for t,b in client.items():
  other=arc.read('DBFilesClient\\'+t+'.dbc')
  if other:scans.append({'mpq':p.name,'table':t,'hash':sha(other)});assert other==b,(p,t)
 arc.close()
js('research/later_root_patch_scan.json',scans)
manifest=[];outputs={};report=[]
for side in ['client','server']:
 outputs[side]={}
 for t in ['SkillLineAbility','SkillRaceClassInfo']:
  b=client[t] if side=='client' else (R/'beascendserver/wowshub_playerbot_npcbot_newrace20261029Ascend/Data/dbc'/(t+'.dbc')).read_bytes()
  n,f,z,rows=parse(b);new=bytearray(b);changes=[]
  selected=[(v[2],4,v[1],spell) for spell,v in targets.items()] if t=='SkillLineAbility' else [(330,3,473,None)]
  for id,col,skill,spell in selected:
   indexes=[i for i,r in enumerate(rows) if r[0]==id];assert len(indexes)==1
   i=indexes[0];r=rows[i];assert r[1]==skill and (spell is None or r[2]==spell)
   # ClassMask 0 means unrestricted; never turn it into class13-only.
   mask=r[col];nextmask=mask|4096 if mask else 0
   if nextmask!=mask:
    struct.pack_into('<I',new,20+i*z+col*4,nextmask);changes.append({'row':id,'field':col,'old':mask,'new':nextmask})
  actual=[]
  for before,after in zip(rows,parse(new)[3]):
   for col,(x,y) in enumerate(zip(before,after)):
    if x!=y:actual.append({'row':before[0],'field':col,'old':x,'new':y});assert y==x|4096
  assert sorted(actual,key=lambda x:x['row'])==sorted(changes,key=lambda x:x['row'])
  assert b[:20]==new[:20] and b[20+n*z:]==new[20+n*z:]
  rel=('02_MPQ导入目录/导入PATCH-XA/DBFilesClient/' if side=='client' else '03_覆盖到服务端根目录/Data/dbc/')+t+'.dbc'
  put(rel,bytes(new));put('backup_原文件/'+side+'/'+t+'.dbc',b);outputs[side][t]=parse(new)[3]
  manifest.append({'side':side,'table':t,'input_sha256':sha(b),'output_sha256':sha(new),'output':rel,'changes':actual,'other_fields_and_strings_preserved':True})
 for spell,(name,skill,id) in targets.items():
  a=next(r for r in outputs[side]['SkillLineAbility'] if r[0]==id)
  normal=[r for r in outputs[side]['SkillRaceClassInfo'] if r[1]==skill and r[4]!=1040 and (r[3]==0 or r[3]&4096)]
  assert (a[4]==0 or a[4]&4096) and normal,(side,name)
  for race in range(1,33):assert any(r[2]==0 or r[2]&(1<<(race-1)) for r in normal)
  report.append({'side':side,'weapon':name,'spell':spell,'skill':skill,'class13_ability_allowed':True,'normal_skill_rows':[r[0] for r in normal],'race_bits_1_through_32_covered':True})
js('checks/manifest.json',manifest);js('checks/eligibility_validation.json',report)
put('research/upstream_audit.md',(A/'research/upstream_audit.md').read_text(encoding='utf8')+'\nWDWP1B沿用本会话已读取的固定上游Trainer.cpp及本地过滤链；本批扩展明确武器白名单，不改Trainer源码。\n')
readme='''# WDWP1B 巫医近战武器累计学习包

本包含：单手剑、双手剑、单手斧、双手斧、单手锤、双手锤、长柄武器，并累计保留WDWP1A拳套资格。未装A可直接装B；已装A也使用B，之后不要再用旧A覆盖B。

## 安装

1. 退出游戏并停止worldserver，分别备份客户端和服务端对应两表。
2. `02_MPQ导入目录/导入PATCH-XA/DBFilesClient` 中的 SkillLineAbility.dbc、SkillRaceClassInfo.dbc 导入**现有PATCH-XA**的同路径，勿替换整份XA。
3. `03_覆盖到服务端根目录/Data/dbc` 中两张表覆盖服务端对应Data/dbc文件。双端文件不能混用。
4. 保存关闭MPQ编辑器，重启服务端与客户端，去武器大师付费学习。

无需SQL、无需重新编译；不自动赠送熟练度、不刷满技能、不放宽物品专属职业/等级、不新增双持或双手武器双持。种族介绍YB/UIR1D不受影响。

## 学什么、找谁、多少钱

|学习项目|法术ID|基础收费/等级|已核对的NPC示例|
|---|---:|---|---|
|单手斧/双手斧|196/197|各10银|布里维夫·石拳11865、塞尤克11868、哈纳什2704|
|单手锤/双手锤|198/199|各10银|布里维夫·石拳11865、安塞瓦11869、韩迪尔16773|
|单手剑/双手剑|201/202|各10银|吴平11867、阿基巴德11870、伊蕾达16621、韩迪尔16773|
|长柄武器|200|1金币，20级|吴平11867、阿基巴德11870、伊蕾达16621|
|拳套|15590|10银|布里维夫·石拳11865、塞尤克11868、伊琳尼雅·月火11866|

NPC默认Trainer映射及训练项目已从本地世界库只读核查，未逐个在游戏找到其实际出生点；选正常可交互、己方可访问的NPC。基础价格仍受原生声望折扣影响。每个武器大师教的项目不同，不保证一个NPC提供全部武器。长柄必须满足20级，其他上述项目数据库ReqLevel=0，实际仍受正常交互条件约束。

原已允许的法杖、匕首、弓、枪、弩、魔杖、投掷保持原样；职业允许不等于每个NPC出售，尤其当前普通武器大师表没有魔杖5009项目。本包不擅自新增该训练项。

## 技术范围与验证

巫医class13职业位4096。SkillLineAbility仅对8项熟练法术的职业位做OR追加；SkillRaceClassInfo保留A拳套330行追加。剑斧锤长柄已有正常、覆盖巫医的技能行，原样保留，不修改多余行或全部职业掩码。保留0=不限语义、已有其他职业位、行数和全部字符串块。

从本轮实际XA和服务端Data独立构建，不用旧整表覆盖新功能。完整差异见checks/manifest.json，双端8种武器学习资格、32个种族位覆盖及非目标字段/字符串保留已离线验证；不把种族位覆盖等同32个种族实际可创建。运行客户端根目录XA之后同路径表扫描无冲突。CoA源码依据见research，上游与本地职业编号不混用。

游戏测试未运行。请逐项验证：未学习角色看到可学项；资金不足拒绝；学习只扣一次钱；长柄19级不可学/20级可学；等级适合的武器能装备并攻击；小退重登保留；其他原可学/不可学职业不回归。双持、副手规则仍走原有资格。

## 回滚

比较当前文件与本包输出SHA256，一致时停服/退出游戏再分别恢复backup_原文件/client和server。若有后续更新必须按白名单反向合并，不能整表回退。备份是本次实际输入，可能早于A；想保留A拳套应使用对应A输出或合并。已付费学会的技能不会因回滚DBC自动遗忘或退费；不批量改玩家数据。

本包不commit/Release、不部署生产，仅供用户导入验证。永久Skill新增的是强制审计规则和已核对的数据依据，不把未实机候选写成已验收功能。
'''
put('README_安装与NPC学习清单.md',readme)
put('tools/build_WDWP1B.py',Path(__file__).read_bytes())
print('Built cumulative package, input/output fields verified; '+str(len(report))+' side/weapon cases')
