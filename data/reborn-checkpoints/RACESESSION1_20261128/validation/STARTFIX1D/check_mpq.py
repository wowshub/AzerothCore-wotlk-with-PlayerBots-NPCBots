from pathlib import Path
import sys,shutil
r=Path.cwd();w=Path(__file__).parent.resolve();sys.argv=['',str(w),'x'];ns={};src=(r/'000Ascendupdate/000Ascendupdate20261121/codexwork_WOW64NEUTRAL3P/verify_mpq.py').read_text('utf8');exec(src[:src.index('baseline=digest(original)')],ns)
original=Path('C:/000ref/WarcraftXL试装_client/Data/Patch-YI.mpq');copy=w/'verify-Patch-YI.mpq';shutil.copyfile(original,copy);h=ns['open_mpq'](copy,0);stem='Character/Furbolg/FurbolgRace';changes=[(stem+'.m2','bear.m2','bear-cape.m2'),(stem+'00.skin','bear00.skin','bear-cape00.skin')]
try:
 for key,old,new in changes:
  assert ns['read'](h,key)==(w/old).read_bytes();ns['require'](ns['d'].SFileAddFileEx(h,str(w/new),key.replace('/','\\').encode(),0x80000200,2,2))
finally:ns['require'](ns['d'].SFileCloseArchive(h))
h=ns['open_mpq'](copy,0x100)
try:
 for key,old,new in changes:assert ns['read'](h,key)==(w/new).read_bytes()
finally:ns['require'](ns['d'].SFileCloseArchive(h))
print('PASS isolated current Patch-YI: both exact cape files imported and read back; live archive untouched')
