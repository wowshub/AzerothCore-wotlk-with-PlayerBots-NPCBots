from pathlib import Path
import re
P=Path(Path('wd125_path.txt').read_text().strip())
S='01_覆盖到源代码根目录/'
src=S+'modules/mod-reborn-witchdoctor/src/'
def write(rel,data):
 p=P/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(data,encoding='utf8')
def rep(s,a,b):
 assert s.count(a)==1,(a,s.count(a));return s.replace(a,b)
q=P/(src+'RebornWitchDoctorTalents.cpp')
s=q.read_text(encoding='utf8').replace('AEIds[85]','AEIds[86]').replace('i<85','i<86')
q.write_text(s,encoding='utf8')

old=P/'server_SQL/01_CHARACTERS_WD124A_必须执行.sql'
s=old.read_text(encoding='utf8')
s=s.replace('reborn_wd124_schema','reborn_wd125_schema').replace('WD124A','WD125A')
s=s.replace('35065,35064,35068)','35065,35064,35068,29738)')
s=rep(s,' DECLARE r84 INT DEFAULT 0;',' DECLARE r85 INT DEFAULT 0;\n DECLARE r84 INT DEFAULT 0;')
s=rep(s,' SET r84=MOD(FLOOR(p_mask/',f' SET r85=MOD(FLOOR(p_mask/{2**97}),2);\n SET r84=MOD(FLOOR(p_mask/')
s=rep(s,str(2**97-1),str(2**98-1))
s=rep(s,'r84<>0) AND r49+r50+r51+r53+r55+r81<8','r84<>0 OR r85<>0) AND r49+r50+r51+r53+r55+r81<8')
s=rep(s,'r80+r81+r82+r83+r84>v_te','r80+r81+r82+r83+r84+r85>v_te')
s=rep(s,'r80+r81+r82+r83+r84>0','r80+r81+r82+r83+r84+r85>0')
s=rep(s,'WHEN 35068 THEN node_rank*',f'WHEN 29738 THEN node_rank*{2**97} WHEN 35068 THEN node_rank*')
s=rep(s,' IF r82<MOD(FLOOR(v_saved/',f' IF r85<MOD(FLOOR(v_saved/{2**97}),2) OR r82<MOD(FLOOR(v_saved/')
s=rep(s,' IF r84>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,35068,r84);END IF;',
''' IF r84>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,35068,r84);END IF;
 IF r85>0 THEN INSERT INTO reborn_wd67_nodes VALUES(p_guid,p_slot,29738,r85);END IF;''')
# The official Frog Bones talent requires a prepared cauldron path.
s=rep(s,' IF r81<>0 AND p_level<17',
''' IF r85<>0 AND r74=0 AND r0=0 THEN ROLLBACK;SELECT 0 AS result;LEAVE proc;END IF;
 IF r81<>0 AND p_level<17''')
write('server_SQL/01_CHARACTERS_WD125A_必须执行.sql',s)
old.unlink()
print('finalized',P)
