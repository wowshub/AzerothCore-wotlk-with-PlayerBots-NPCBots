from pathlib import Path
import subprocess as sp,socket,time,json
w=Path(__file__).resolve().parent;r=w.parents[2];bin=Path('D:/soft/MYSQL8.0.42/bin');data=w/'mysql-test/data';data.parent.mkdir(exist_ok=True);port=13427;flags=sp.CREATE_NO_WINDOW;checks=[]
with socket.socket() as s:s.bind(('127.0.0.1',port))
if not data.exists():
 z=sp.run([str(bin/'mysqld.exe'),'--no-defaults','--initialize-insecure',f'--datadir={data}'],capture_output=True,creationflags=flags);assert z.returncode==0,z.stderr
server=sp.Popen([str(bin/'mysqld.exe'),'--no-defaults',f'--datadir={data}',f'--port={port}','--bind-address=127.0.0.1','--mysqlx=OFF','--skip-log-bin',f'--log-error={data.parent}/mysql.log'],creationflags=flags,stdout=sp.DEVNULL,stderr=sp.DEVNULL)
def sql(s,ok=True):
 z=sp.run([str(bin/'mysql.exe'),'--no-defaults','--protocol=TCP','--host=127.0.0.1',f'--port={port}','--user=root','--password=','--ssl-mode=DISABLED','--connect-timeout=2','--batch','--raw','--skip-column-names'],input=s,text=True,encoding='utf8',capture_output=True,creationflags=flags,timeout=60)
 if ok:assert not z.returncode,z.stderr
 return z
try:
 for _ in range(100):
  z=sql('SELECT @@datadir;',False)
  if not z.returncode:break
  assert server.poll() is None,'test server exited';time.sleep(.2)
 assert not z.returncode,(z.returncode,z.stderr)
 assert Path(z.stdout.strip()).resolve()==data.resolve(),(repr(z.stdout),str(data.resolve()))
 print('isolated datadir verified',flush=True)
 sql('DROP DATABASE IF EXISTS startfix1c;DROP DATABASE IF EXISTS wrong_database;CREATE DATABASE startfix1c;');prefix='USE startfix1c;';base=r/'000Ascendupdate/000Ascendupdate20261117'
 sql(prefix+(r/'000Ascendupdate/000Ascendupdate20261119/codexwork_WOW64NEUTRAL3F/sql/characters_WOW64NEUTRAL3F.sql').read_text('utf8'))
 sql(prefix+(base/'codexwork_WOW64NEUTRAL2A/payload/06_SQL_characters/01_NEUTRAL2A_origin.sql').read_text('utf8'))
 sql(prefix+(base/'codexwork_WOW64NEUTRAL2E/payload/06_SQL_characters/01_NEUTRAL2E_origin_routes.sql').read_text('utf8'))
 for table,vals in [('character_reborn_birth_route','1,123,5,0,0,141'),('character_reborn_neutral_origin','1,83,1,0,0,141')]:
  z=sql(prefix+f'INSERT INTO {table}(guid,race,class,sex,team,zone) VALUES({vals});',False);assert z.returncode and '3819' in z.stderr;checks.append('reproduced old 3819 '+table)
 sql(prefix+'INSERT INTO character_reborn_birth_route VALUES(1,123,5,0,0,129);INSERT INTO character_reborn_neutral_origin(guid,race,class,sex,team,zone) VALUES(1,83,6,0,0,0);')
 before=sql(prefix+'SELECT * FROM character_reborn_birth_route;SELECT * FROM character_reborn_neutral_origin;').stdout
 migration=(w/'install.sql').read_text('utf8');sql(prefix+migration);sql(prefix+migration);assert sql(prefix+'SELECT * FROM character_reborn_birth_route;SELECT * FROM character_reborn_neutral_origin;').stdout==before;checks.append('repeat install preserves all legacy columns/rows and original DK0')
 rollback=(w/'rollback.sql').read_text('utf8');sql(prefix+rollback);sql(prefix+migration);checks.append('guarded rollback with only legacy rows and reinstall')
 for table in ['character_reborn_birth_route','character_reborn_neutral_origin']:
  vals=','.join(f'({1000+race*2+team},{race},{15 if race>123 else 5},1,{team},141)' for race in range(1,256) for team in range(2));sql(prefix+f'INSERT INTO {table}(guid,race,class,sex,team,zone) VALUES'+vals+';');checks.append('510 current/future race/faction routes accepted '+table)
 for table in ['character_reborn_birth_route','character_reborn_neutral_origin']:
  for team,zone in [(0,128),(0,142),(2,141)]:
   z=sql(prefix+f'INSERT INTO {table}(guid,race,class,sex,team,zone) VALUES(99999,83,1,0,{team},{zone});',False);assert z.returncode and '3819' in z.stderr;checks.append(f'kept invalid boundary {table} {team}/{zone}')
 for race,cl,sex in [(0,1,0),(1,0,0),(1,1,2)]:
  z=sql(prefix+f'INSERT INTO character_reborn_neutral_origin(guid,race,class,sex,team,zone) VALUES(99999,{race},{cl},{sex},0,141);',False);assert z.returncode;checks.append(f'kept neutral scalar invalid {race}/{cl}/{sex}')
 z=sql(prefix+rollback,False);assert z.returncode and 'rollback blocked' in z.stderr;checks.append('rollback refuses saved 141/future records')
 sql('CREATE DATABASE wrong_database;');z=sql('USE wrong_database;'+migration,False);assert z.returncode and 'select the CHARACTERS' in z.stderr;checks.append('wrong database rejected before schema changes')
 (w/'sql-test-results.json').write_text(json.dumps(checks,indent=2),'utf8');print('PASS',len(checks),'checks',flush=True)
finally:
 sql('SHUTDOWN;',False)
 try:server.wait(timeout=20)
 except sp.TimeoutExpired:server.terminate();server.wait(timeout=10)
 print('isolated mysql stopped',flush=True)
