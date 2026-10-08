# coding: utf-8
from pathlib import Path
import struct,datetime,json,hashlib,zipfile,subprocess
from wd9a_storm import Archive
import pympq
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO')
C=R/'beascendclient/newrebornWOWli20261007beAscend'
B=Path(Path('D:/000rebornWOW/wd136_path.txt').read_text(encoding='utf8').strip())
P=R/'000Ascendupdate/000Ascendupdate20261007'/('codexfix_'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S')+'_WD135UI2_灵魂链接神像译名')
P.mkdir(parents=True)
def put(p,b):
 p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(b if isinstance(b,bytes) else b.encode('utf8'))
reports=[]
def spell(raw):
 magic,n,f,size,ss=struct.unpack_from('<4s4I',raw);assert magic==b'WDBC' and f==234 and size==936
 end=20+n*size;assert end+ss==len(raw)
 out=bytearray(raw);pool=bytearray(raw[end:]);changed=[]
 row=next(20+i*size for i in range(n) if struct.unpack_from('<I',raw,20+i*size)[0]==9003953)
 for field in list(range(136,152))+list(range(170,186))+list(range(187,203)):
  off=struct.unpack_from('<I',raw,row+field*4)[0];assert off<ss
  old=bytes(pool[off:]).split(b'\0')[0].decode('utf8');new=old.replace('雕像','神像')
  if new!=old:
   struct.pack_into('<I',out,row+field*4,len(pool));pool+=new.encode('utf8')+b'\0';changed.append(field)
 assert changed
 out=out[:end]+pool;struct.pack_into('<I',out,16,len(pool))
 # Only localized text offsets of this spell may change; all mechanics/other rows preserved.
 check=bytearray(out[:end]);struct.pack_into('<I',check,16,ss)
 for field in changed:check[row+field*4:row+field*4+4]=raw[row+field*4:row+field*4+4]
 assert bytes(check)==raw[:end] and out[end:end+ss]==raw[end:]
 reports.append({'changed_spell':9003953,'fields':changed,'all_other_records_and_mechanics_unchanged':True})
 return bytes(out)
for label,client,server,mpq in [
 ('A_已安装WD135使用',C,R/'beascendserver/wowshub_playerbot_npcbot_newrace20261007Ascend/Data/dbc/Spell.dbc',C/'Data/patch-ZA.mpq'),
 ('B_已安装WD136A使用',B/'02_覆盖到客户端根目录',B/'03_覆盖到服务端根目录/Data/dbc/Spell.dbc',B/'02_覆盖到客户端根目录/Data/patch-ZA.mpq')]:
 root=P/label
 a=Archive(mpq);names=a.read('(listfile)').decode('utf8').splitlines();content={k:a.read(k) for k in names if not k.startswith('(')};a.close()
 key=next(k for k in content if k.lower()=='dbfilesclient\\spell.dbc')
 put(root/'rollback/Data/patch-ZA.mpq',mpq.read_bytes());content[key]=spell(content[key])
 for k,v in content.items():put(root/'client_mpq输入'/k.replace('\\','/'),v)
 target=root/'02_覆盖到客户端根目录/Data/patch-ZA.mpq';target.parent.mkdir(parents=True)
 a=pympq.create_archive(str(target),[pympq.MPQ_CREATE_ARCHIVE_V1],64)
 for k in content:a.add_file(str(root/'client_mpq输入'/k.replace('\\','/')),k,[pympq.MPQ_FILE_COMPRESS],[pympq.MPQ_COMPRESSION_ZLIB])
 a.close();a=Archive(target)
 for k,v in content.items():assert a.read(k)==v
 a.close()
 for filename in ['Allocation.lua','Progress.lua']:
  rel=Path('Interface/AddOns/RebornWitchDoctorTalents')/filename;raw=(client/rel).read_bytes();s=raw.decode('utf8')
  lines=s.splitlines(keepends=True);count=0
  for i,line in enumerate(lines):
   if '灵魂链接雕像' in line:
    lines[i]=line.replace('雕像','神像');count+=1
  assert count==1
  put(root/'rollback'/rel,raw);dest=root/'02_覆盖到客户端根目录'/rel;put(dest,''.join(lines))
  compiler=R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_compiler.exe'
  subprocess.run([str(compiler),'-p',str(dest)],check=True)
 raw=server.read_bytes();put(root/'rollback/服务端/Data/dbc/Spell.dbc',raw);put(root/'03_覆盖到服务端根目录/Data/dbc/Spell.dbc',spell(raw))
readme='''# 灵魂链接神像：中文译名修正

9003953 / Spirit Link Idol 改为“灵魂链接神像”。技能书、动作条、神像栏提示和天赋说明统一用“神像”。Idol=神像；Effigy=雕像。分类与效果不变。

## 选择一个版本
- 还在WD135：使用 A_已安装WD135使用。
- 已安装调制大师WD136A：使用 B_已安装WD136A使用。不要再覆盖A，以免回退WD136新增记录与天赋保存结构。
两个版本不能混用。以后重装旧WD135/WD136包后，需要最后再覆盖对应本包。

## 安装
1. 完全退出游戏，先备份当前Data/patch-ZA.mpq和两个同名Lua到客户端Data以外。
2. 选定版本内的“02_覆盖到客户端根目录”内容复制到游戏根目录，覆盖Data和Interface。
3. 服务端文字同步：停服，备份Data/dbc/Spell.dbc，覆盖“03_覆盖到服务端根目录”内文件，再启动。无需编译、无需SQL。
4. 若自己合并Patch-XA，用所选版本client_mpq输入全部内容按原路径导入副本；旧patch-ZA/ZZ移出Data避免盖回。与第2步的MPQ方案二选一，两个Lua仍须覆盖。
5. 重新启动游戏，检查技能书、神像栏、天赋标题均显示“灵魂链接神像”，说明写“同一神像槽”。仅/reload不足以重载DBC。

保留原LIGHT8B火焰视觉与回收图标；B另保留WD136A新增资源。DLL、INI、技能效果不变。本包未直接部署，已通过双端DBC无关行/数值不变检查、MPQ读回、四份Lua语法检查，实机中文显示待确认。
回滚：使用自己安装前备份；附带rollback仅适用于本包记录的基线。
'''
put(P/'README_覆盖与测试说明.md',readme)
memo='本批仅本地中文用语统一，无技能移植或机制变更。依据用户确认Idol及现场9003953分类。采用trace-and-port-coa-spell-resources的双端独立DBC、追加字符串与无关行保护方法；不改旧交付包或运行文件。两个独立版本避免WD136候选倒灌WD135。未实机验收、未提交发布。'
put(P/'memory.md',memo);put(P/'phaseFixForNewChat.md',memo+'\n'+readme)
put(P/'tutor.md','名称在两处：Spell.dbc负责游戏原生技能提示，天赋插件Lua负责自定义天赋文字。只改Lua会造成技能书仍显示旧名。脚本只修改9003953的中文字符串引用，并追加新字符串，不移动旧字符串或修改技能数值；天赋两文件只替换该技能所在行。MPQ是覆盖容器，旧高优先级整表会盖回新名称，所以退出游戏并避免新旧补丁混用。')
put(P/'checks.json',json.dumps(reports,ensure_ascii=False,indent=2));put(P/'tools/rename_idol.py',Path(__file__).read_bytes())
put(P/'SHA256.json',json.dumps({str(f.relative_to(P)):hashlib.sha256(f.read_bytes()).hexdigest() for f in P.rglob('*') if f.is_file()},ensure_ascii=False,indent=2))
with zipfile.ZipFile(str(P)+'.zip','w',zipfile.ZIP_DEFLATED) as z:
 for f in P.rglob('*'):
  if f.is_file():z.write(f,str(f.relative_to(P)))
for name in ['updateMemory.md','tutorMemory.md','refResourceAscend.md']:
 with (R/name).open('a',encoding='utf8') as f:f.write('\n\n## WD135UI2 灵魂链接神像中文统一（待实测）\n'+memo+'\n包：'+str(P)+'.zip\n')
print(str(P)+'.zip')
