from wd120_audit import *
a=Archive(Path('D:/game/ascend/coaWOW/coawowClinet20260925OFFICIAL/Data/patch-T.MPQ'))
rows,pool=dbc(a.read('DBFilesClient\\Spell.dbc'))
out={}
for sid,r in rows.items():
 name=pool[r[136]:pool.find(b'\0',r[136])].decode()
 if name not in ['Potion Toss','Jungle Shrooms','Ingredient: Jungle Shrooms','Cauldron Brewer']:continue
 out[str(sid)]={'row':r,'name':name,'rank':pool[r[153]:].split(b'\0')[0].decode(),'desc':pool[r[170]:].split(b'\0')[0].decode()}
 print(sid,name,out[str(sid)]['rank'],'level',r[37:40],'base',r[80:83])
(P/'research/rank_donor.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf8')
raw=a.read('DBFilesClient\\SpellDescriptionVariables.dbc')
if raw:
 r,p=dbc(raw);print('DESCRIPTION VAR182',r.get(182));print(p[r[182][1]:].split(b'\0')[0].decode());(P/'research/description182.txt').write_text(p[r[182][1]:].split(b'\0')[0].decode(),encoding='utf8')
a.close()
