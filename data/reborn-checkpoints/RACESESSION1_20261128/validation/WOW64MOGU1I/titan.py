# -*- coding: utf-8 -*-
from probe import *
from struct import pack,pack_into
from zipfile import ZipFile,ZIP_DEFLATED

p=w.parent/'codexfix_20261126_TITANDK1A_联盟泰坦死亡骑士'
srv=next((r/'beascendserver').glob('*20261122Ascend'))
repo=r/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots'
def save(path,data):
 f=p/path;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(data)
def modify(path,original,result):
 save('backup_原文件/'+path,original);save(path,result)
def extend(b,name):
 _,rr,st=rows(b);sig,_,cols,width,_=u('<4s4I',b)
 if name=='CharBaseInfo':
  assert width==2 and bytes((91,6)) not in rr
  extra=[bytes((91,6))]
 else:
  assert width==296 and not any(q[4:6]==bytes((91,6)) for q in rr)
  extra=[];next_id=max(u('<I',q)[0] for q in rr)+1
  for sex in (0,1):
   matches=[q for q in rr if q[4:8]==bytes((1,6,sex,0))];assert len(matches)==1
   q=bytearray(matches[0]);q[4]=91;pack_into('<I',q,0,next_id+sex);extra.append(bytes(q))
 out=pack('<4s4I',sig,len(rr)+len(extra),cols,width,len(st))+b''.join(rr+extra)+st
 assert rows(out)[1][:len(rr)]==rr
 return out
for name,arc in [('CharBaseInfo','Patch-YB.mpq'),('CharStartOutfit','Patch-XA.mpq')]:
 key='DBFilesClient/'+name+'.dbc';old=read(c/'Data'/arc,key)
 modify('01_导入现有'+arc+'/'+key,old,extend(old,name))
 for locale in ('','zhCN/'):
  path='Data/dbc/'+locale+name+'.dbc';old=(srv/path).read_bytes()
  modify('02_覆盖服务端根目录/'+path,old,extend(old,name))
for filename in ('game/Handlers/CharacterHandler.cpp','game/Entities/Player/PlayerQuest.cpp'):
 path='src/server/'+filename;old=(repo/path).read_bytes();text=old.decode();nl='\r\n' if '\r\n' in text else '\n';text=text.replace('\r\n','\n')
 if filename.endswith('CharacterHandler.cpp'):
  needle='(createInfo->Race == 91 && (!IsClassicExpansionClass(createInfo->Class) || createInfo->Class == CLASS_DEATH_KNIGHT))'
  assert text.count(needle)==1;text=text.replace(needle,'(createInfo->Race == 91 && !IsClassicExpansionClass(createInfo->Class))')
 else:
  needle='(getRace() == RebornMurlocHordeRace || getRace() == RebornMoguAllianceRace)'
  assert text.count(needle)==1;text=text.replace(needle,'(getRace() == RebornMurlocHordeRace || getRace() == RebornMoguAllianceRace || getRace() == 91)')
  needle='getRace() == RebornMoguAllianceRace ? 12742u : 12748u'
  assert text.count(needle)==1;text=text.replace(needle,'getRace() == RebornMurlocHordeRace ? 12748u : 12742u')
 modify('03_服务端源码/'+path,old,text.replace('\n',nl).encode())
sql='''SET NAMES utf8mb4;
DROP PROCEDURE IF EXISTS codex_titandk1a_install;
DELIMITER $$
CREATE PROCEDURE codex_titandk1a_install()
BEGIN
 DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; RESIGNAL; END;
 START TRANSACTION;
 IF DATABASE()<>'acore_world' OR EXISTS(SELECT 1 FROM playercreateinfo WHERE race=91 AND class=6)
 OR NOT EXISTS(SELECT 1 FROM playercreateinfo WHERE race=91 AND class=1)
 OR NOT EXISTS(SELECT 1 FROM playercreateinfo WHERE race=1 AND class=6 AND map=609)
 THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT='TITANDK1A: wrong baseline or already installed'; END IF;
 INSERT INTO playercreateinfo(race,class,map,zone,position_x,position_y,position_z,orientation)
 SELECT 91,6,map,zone,position_x,position_y,position_z,orientation FROM playercreateinfo WHERE race=1 AND class=6;
 INSERT INTO playercreateinfo_action(race,class,button,action,type)
 SELECT 91,6,button,action,type FROM playercreateinfo_action WHERE race=1 AND class=6 AND NOT(type=0 AND action IN(20599,20600,59752));
 INSERT INTO playercreateinfo_item(race,class,itemid,amount,Note)
 SELECT 91,6,itemid,amount,Note FROM playercreateinfo_item WHERE race=1 AND class=6;
 COMMIT;
END$$
DELIMITER ;
CALL codex_titandk1a_install();
DROP PROCEDURE codex_titandk1a_install;
SELECT race,class,map,zone FROM playercreateinfo WHERE race=91 ORDER BY class;
'''
save('04_WORLD/01_TITANDK1A.sql',sql.encode())
save('README.md',('联盟泰坦死亡骑士\n\n以当前九职业泰坦91为基线，客户端/服务端分别追加DK资格和男女出生装备。服务端解除仅泰坦的DK限制，起始特例选联盟12742版本。\n\n退出客户端、停服备份。导入01、覆盖02，合并03源码后编译服务端，在acore_world执行04 SQL，再启动测试男女DK。首次55级在阿彻鲁斯，检查出生装备、符文熔铸与起始任务。\n\n如已装CLASSQUEST1A，把本包PlayerQuest的两个条件修改合并到当前源码，保留职业任务修复。如已装EXILEBIRTH1A，保留其CharacterHandler出生协议改动。避免用整个旧CPP覆盖后续修改。无新客户端程序。资格和出生装逐条验证，完整服务端编译、目标库和游戏待验。\n').encode())
files={f.relative_to(p).as_posix():f.read_bytes() for f in p.rglob('*') if f.is_file() and f.name!='SHA256SUMS.txt'}
manifest=''.join(f'{sha256(b).hexdigest()}  {n}\n' for n,b in sorted(files.items())).encode();save('SHA256SUMS.txt',manifest);files['SHA256SUMS.txt']=manifest
with ZipFile(p.with_suffix('.zip'),'w',ZIP_DEFLATED) as z:
 for name,b in files.items():z.writestr(name,b)
print('PASS Titan DK DBC rows',sha256(p.with_suffix('.zip').read_bytes()).hexdigest())
