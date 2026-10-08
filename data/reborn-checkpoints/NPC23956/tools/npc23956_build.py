# coding: utf-8
from pathlib import Path
import struct,json,hashlib,datetime,zipfile
from wd9a_storm import Archive
import pympq
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');C=R/'beascendclient/newrebornWOWli20261008beAscend'
P=R/'000Ascendupdate/000Ascendupdate20261007'/('codexfix_'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S')+'_NPC23956_头盔方块资源修复')
P.mkdir(parents=True)
def put(rel,b):
 f=P/rel;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(b if isinstance(b,bytes) else b.encode('utf8'));return f
scan=json.loads(Path('npc23956_assets.json').read_text())
assert not any('_NiM' in x['key'] or '_HuM' in x['key'] for x in scan)
head='Item\\ObjectComponents\\Head\\Helm_Mail_Vrykul_01_'
a=Archive(C/'Data/patch-H.mpq');model=a.read(head+'VrM.m2');skin=a.read(head+'VrM00.skin');a.close()
assert model[:4]==b'MD20' and struct.unpack_from('<I',model,4)[0]==264 and skin[:4]==b'SKIN'
nv,ov,views=struct.unpack_from('<III',model,60);assert ov+nv*48<=len(model) and views==1
ni,oi,nt,ot=struct.unpack_from('<4I',skin,4)
assert oi+ni*2<=len(skin) and ot+nt*2<=len(skin)
assert max(struct.unpack_from('<'+'H'*ni,skin,oi))<nv
assert max(struct.unpack_from('<'+'H'*nt,skin,ot))<ni
# Enumerate exact dependencies instead of assuming listfile proves presence.
n,o=struct.unpack_from('<II',model,80);textures=[]
for i in range(n):
 typ,flags,length,offset=struct.unpack_from('<4I',model,o+i*16)
 if typ==0:
  assert offset+length<=len(model)
  textures.append(model[offset:offset+length].split(b'\0')[0].decode('utf8'))
textures.append('Item\\ObjectComponents\\Head\\Helm_Mail_Vrykul_01Blue.blp')
found={k:[] for k in textures}
for path in (C/'Data').rglob('*.mpq'):
 a=Archive(path)
 for k in textures:
  b=a.read(k)
  if b:found[k].append({'archive':str(path),'sha256':hashlib.sha256(b).hexdigest()})
 a.close()
assert all(found.values()),found
payload={}
for suffix in ['NiM','HuM']:
 payload[head+suffix+'.m2']=model;payload[head+suffix+'00.skin']=skin
for k,b in payload.items():put('client_mpq输入_导入Patch-XA/'+k.replace('\\','/'),b)
target=P/'02_覆盖到客户端根目录/Data/patch-ZB.mpq';target.parent.mkdir(parents=True)
assert not (C/'Data/patch-ZB.mpq').exists()
a=pympq.create_archive(str(target),[pympq.MPQ_CREATE_ARCHIVE_V1],16)
for k in payload:a.add_file(str(P/'client_mpq输入_导入Patch-XA'/k.replace('\\','/')),k,[pympq.MPQ_FILE_COMPRESS],[pympq.MPQ_COMPRESSION_ZLIB])
a.close();a=Archive(target)
for k,b in payload.items():assert a.read(k)==b
a.close()
readme='''# NPC23956 掠龙战略家：头顶方块修复候选

## 安装（无需编译、无需SQL）
1. 完全退出游戏。
2. 将“02_覆盖到客户端根目录”内Data文件夹复制到当前客户端根目录。新增Data/patch-ZB.mpq。
3. 原patch-ZA保留，这是翻译/火焰等其他修复。本包不含DBC、Lua、DLL或INI，不会回退WD135/WD136。
4. 重新启动游戏，查看23956。它有两个随机外观，需要找带头盔的那种：确认头顶不再出现方块，正常头盔位置、贴图正常，并检查目标头像。
5. 回滚只需退出游戏，将本包patch-ZB.mpq移到Data之外。若已有其他同名补丁，不能覆盖它，应采用下述导入方式。

也可把client_mpq输入_导入Patch-XA中的Item目录按原内部路径导入自己备份后的Patch-XA副本，再替换客户端Patch-XA；不需要同时安装本包ZB。导入前备份XA到Data之外，回滚恢复自己的备份。

## 原因和边界
本地数据库只读核实23956使用22293/22294，无模板附加Aura。模型2594仍指向VrykulMale。自定义CreatureDisplayInfoExtra把15246种族改成23、头盔改成99954190；ChrRaces23前缀Ni、客户端备用前缀Hu。对应NiM/HuM头盔和SKIN在枚举的当前全部MPQ中精确查询均缺失，而原VrM资源存在。
本包用当前patch-H的成对VrM头盔资源补两个缺失路径；不改变狼人/夜之子种族定义、不删除头盔、不换整个人物模型。还会覆盖同样引用这顶头盔和前缀的NPC，不是所有怪物的通用修复。
模型/SKIN结构、顶点索引、贴图依赖和MPQ逐文件读回已通过。没有抓取客户端实际文件请求，缺失路径是静态证据；头盔与高清主体的贴合度仍需游戏验证，不能把候选写成已实测成功。
'''
put('README_覆盖与测试说明.md',readme)
memo='使用repair-wotlk-item-texture-references和audit-wotlk-shadowing-mpq-backups。基线按新refResource为20261008。只读DB确认模型；首轮沙箱拒绝连接，经只读授权升级成功。未修改数据库、运行资源或旧包。当前Data/enUS存在多个备份MPQ，此次未擅自移动；对相关行和文件扫描记录来源，所有归档均缺NiM/HuM，补文件不依赖替换DBC胜出顺序。待用户验证，不登记成功或发布。'
put('memory.md',memo);put('phaseFixForNewChat.md',memo+'\n'+readme)
put('tutor.md','头盔模型像一件按体型命名的衣服。外观表告诉客户端按Ni或备用Hu找头盔，库里却只有Vr版本，就可能显示缺失模型方块。本次给原头盔模型与配套SKIN补上它要找的名字。M2管形状、材质和动画，SKIN管三角形如何引用顶点，两者必须成对。并未修改所有种族编号或怪物属性，也没有把头盔隐藏。新MPQ只放四个缺失文件，撤回容易，也不携带可能过时的整份DBC。实际头盔贴合仍由游戏确认。')
put('research/assets.json',json.dumps(scan,ensure_ascii=False,indent=2));put('research/dependencies.json',json.dumps(found,ensure_ascii=False,indent=2))
put('checks.json',json.dumps({'M2_SKIN_structure':True,'vertex_triangle_bounds':True,'textures_exist':True,'MPQ_readback':True,'runtime_verified':False,'vertices':nv,'skin_indices':ni,'triangles_indices':nt},indent=2))
for f in ['npc23956_build.py','npc23956_assets.py','npc23956_probe.py']:put('tools/'+f,Path(f).read_bytes())
put('SHA256.json',json.dumps({str(f.relative_to(P)):hashlib.sha256(f.read_bytes()).hexdigest() for f in P.rglob('*') if f.is_file()},ensure_ascii=False,indent=2))
with zipfile.ZipFile(str(P)+'.zip','w',zipfile.ZIP_DEFLATED) as z:
 for f in P.rglob('*'):
  if f.is_file():z.write(f,str(f.relative_to(P)))
for name in ['updateMemory.md','tutorMemory.md','refResourceAscend.md']:
 with (R/name).open('a',encoding='utf8') as f:f.write('\n\n## NPC23956 头盔缺失兼容资源（候选）\n'+memo+'\n包：'+str(P)+'.zip\n')
print(str(P)+'.zip',flush=True)
