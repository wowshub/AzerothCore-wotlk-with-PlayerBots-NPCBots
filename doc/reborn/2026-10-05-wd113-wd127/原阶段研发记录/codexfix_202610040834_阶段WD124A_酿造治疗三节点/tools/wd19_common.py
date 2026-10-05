"""WD19 build helpers: read-only input access; candidate writers live in the stage tools."""
from pathlib import Path
import re, os, subprocess, struct
from wd9a_storm import Archive
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO')
C=R/'beascendclient/newrebornWOWli20260915beAscend'
S=R/'beascendserver/wowshub_playerbot_npcbot_newrace20260915Ascend'
CODE=R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots'
D=Path('D:/game/ascend/coaWOW/coawowClinet20260915')
def package():
 nearby=Path(__file__).resolve().parent.parent
 if (nearby/'manifest.json').is_file():return nearby
 return Path(Path('wd19_path.txt').read_text(encoding='utf8'))
def dbc(b):
 magic,n,f,size,ss=struct.unpack_from('<4s4I',b)
 assert magic==b'WDBC' and size==f*4 and len(b)==20+n*size+ss
 return {struct.unpack_from('<I',b,20+i*size)[0]:list(struct.unpack_from('<'+'I'*f,b,20+i*size)) for i in range(n)},b[20+n*size:]
def query(key,sql):
 # These tools use this connection only to inspect the installed schema/data.
 assert all(s.strip().upper().startswith(('SELECT ','SHOW ')) for s in sql.split(';') if s.strip())
 cfg=(S/'configs/worldserver.conf').read_text(encoding='utf-8-sig')
 fields=re.search(r'^'+re.escape(key)+r'\s*=\s*(.+)',cfg,re.M)[1].strip().strip('"').split(';')
 env=os.environ.copy();env['MYSQL_PWD']=fields[3]
 res=subprocess.run([str(S/'mysql-8.0.31-winx64/bin/mysql.exe'),'-h',fields[0],'-P',fields[1],'-u',fields[2],fields[4],'-B'],input=sql.encode(),env=env,capture_output=True)
 if res.returncode:raise RuntimeError(res.stderr.decode('utf8','replace'))
 return res.stdout
