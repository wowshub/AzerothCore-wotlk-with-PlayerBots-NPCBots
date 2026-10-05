# coding: utf-8
from pathlib import Path
import json,hashlib,struct,difflib,zipfile,datetime
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO')
P=Path(Path('wd121b_path.txt').read_text());B=Path(Path('wd121_path.txt').read_text())
def put(rel,s):
 p=P/rel;p.parent.mkdir(parents=True,exist_ok=True);p.write_text(s,encoding='utf8')
checks=[]
def ck(n,b):
 assert b,n
 checks.append(n)
spellrel='src/server/game/Spells/Spell.cpp';playerrel='src/server/game/Entities/Player/Player.cpp'
s=(P/'01_覆盖到源代码根目录'/spellrel).read_text(encoding='utf-8-sig')
old=(P/'rollback'/spellrel).read_text(encoding='utf-8-sig')
player=(P/'01_覆盖到源代码根目录'/playerrel).read_text(encoding='utf-8-sig')
a=s.index('    // WD63E: correct');b=s.index('    bool resetAttackTimers',a);block=s[a:b]
ck('cooldown first, SPELL_GO second, correction last',s.index('    SendSpellCooldown();')<s.index('    SendSpellGo();')<a)
ck('unchanged surrounding Spell.cpp',old[:old.index('    // WD63E: correct')]==s[:a] and old[old.index('    bool resetAttackTimers',old.index('    // WD63E: correct')):]==s[b:])
ck('Player.cpp identical to WD121A', (P/'01_覆盖到源代码根目录'/playerrel).read_bytes()==(B/'01_覆盖到源代码根目录'/playerrel).read_bytes())
for guard in ['player->getClass() == 13','!m_CastItem','!m_spellInfo->IsPassive()','!m_spellInfo->IsCooldownStartedOnEvent()','TRIGGERED_IGNORE_SPELL_AND_CATEGORY_CD','TRIGGERED_IGNORE_EFFECTS','modifier->op == SPELLMOD_COOLDOWN','player->IsAffectedBySpellmod(m_spellInfo, modifier, this)','if (remaining)']:
 ck('guard '+guard,guard in block)
ck('exact Gonk frog pair','source == 9003862 && m_spellInfo->Id != 9003861' in block)
ck('Hastened retained','{9003653u, 9003862u}' in block)
ck('read stored remaining before clear and packet',block.index('GetSpellCooldownDelay')<block.index('SendClearCooldown')<block.index('BuildCooldownPacket')<block.index('SendDirectMessage'))
ck('no cooldown recalculation or server removal',all(x not in block for x in ['ApplySpellMod(', 'RemoveSpellCooldown(', '_AddSpellCooldown(', '60000', '60 *']))
clear=player.split('void Player::SendClearCooldown(')[1].split('\nvoid Player::')[0]
ck('clear is network only', 'SMSG_CLEAR_COOLDOWN' in clear and 'm_spellCooldowns' not in clear and 'RemoveSpellCooldown' not in clear)
ck('native calculation retained','ApplySpellMod(spellInfo->Id, SPELLMOD_COOLDOWN, rec, spell)' in player)
up=(P/'research/upstream_Spell.cpp').read_text(encoding='utf8')
ck('fresh upstream retains same message ordering',up.index('    SendSpellCooldown();')<up.index('    SendSpellGo();'))
for prefix in ['03_覆盖到服务端根目录/Data/dbc','client_mpq输入_导入现有Patch-XA/DBFilesClient']:
 data=(B/prefix/'Spell.dbc').read_bytes();magic,n,fields,size,strings=struct.unpack_from('<4s4I',data)
 ck(prefix+' DBC shape',magic==b'WDBC' and size==fields*4 and len(data)==20+n*size+strings)
 rows={}
 for i in range(n):
  offset=20+i*size;ident=struct.unpack_from('<I',data,offset)[0]
  if ident in (9003861,9003862):rows[ident]=struct.unpack_from('<'+str(fields)+'I',data,offset)
 ck(prefix+' frog base120s and movement interrupt',rows[9003861][29]==120000 and rows[9003861][31]&1==1)
 ck(prefix+' Gonk native minus60000ms',rows[9003862][95]==107 and rows[9003862][110]==11 and struct.unpack('<i',struct.pack('<I',rows[9003862][80]))[0]+1==-60000)

# Packet-order model: demonstrates the overwrite and correction, not a live client test.
def playback(events):
 timer=0
 for event,value in events:
  if event in ('GO','COOLDOWN'):timer=value
  elif event=='CLEAR':timer=0
 return timer
ck('model old early60 then GO120 reproduces 120',playback([('COOLDOWN',60000),('GO',120000)])==120000)
for remain in [60000,59995,59400,30000,1]:
 ck('model post GO remaining '+str(remain),playback([('COOLDOWN',60000),('GO',120000),('CLEAR',0),('COOLDOWN',remain)])==remain)
ck('model base and Krag remain120',playback([('GO',120000)])==120000)

print('PASS',len(checks))
