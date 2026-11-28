from pathlib import Path
import shutil,sys
w=Path.cwd()/'000Ascendupdate/000Ascendupdate20261127/codexwork_STARTFIX1C';sys.argv=['',str(w),'x'];ns={};src=(Path.cwd()/'000Ascendupdate/000Ascendupdate20261121/codexwork_WOW64NEUTRAL3P/verify_mpq.py').read_text('utf8');exec(src[:src.index('baseline=digest(original)')],ns)
original=Path('C:/000ref/WarcraftXL试装_client/Data/Patch-YI.mpq');target=w/'verify-Patch-YI.mpq';shutil.copyfile(original,target);key='Character/Furbolg/FurbolgRace.m2';h=ns['open_mpq'](target,0)
try:
 assert ns['read'](h,key)==(w/'bear.m2').read_bytes();control=ns['read'](h,key[:-3]+'00.skin');ns['require'](ns['d'].SFileAddFileEx(h,str(w/'bear-fixed.m2'),key.replace('/','\\').encode(),0x80000200,2,2))
finally:ns['require'](ns['d'].SFileCloseArchive(h))
h=ns['open_mpq'](target,0x100)
try:
 assert ns['read'](h,key)==(w/'bear-fixed.m2').read_bytes();assert ns['read'](h,key[:-3]+'00.skin')==control
finally:ns['require'](ns['d'].SFileCloseArchive(h))
print('PASS isolated existing Patch-YI import and readback, original skin retained')
