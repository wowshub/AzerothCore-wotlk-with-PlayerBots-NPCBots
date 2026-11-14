from pathlib import Path
import struct
p=Path(__file__).resolve().parents[1]/'05_证据/E输出'
for sex in ('male','female'):
 b=(p/(sex+'-after.skin')).read_bytes()
 assert b[:4]==b'SKIN'
 n,o=struct.unpack_from('<II',b,28)
 assert o+n*48<=len(b)
 for group in (3001,3002,3101,3102):
  rows=[struct.unpack_from('<10H',b,o+i*48) for i in range(n) if struct.unpack_from('<H',b,o+i*48)[0]==group]
  assert len(rows)==1 and rows[0][5]>0 and rows[0][5]%3==0,(sex,group)
 b=(p/'selection-after.bin').read_bytes();n=struct.unpack_from('<I',b,8)[0]
 for group in (30,31):
  rows=[struct.unpack_from('<7I',b,12+i*156) for i in range(n) if struct.unpack_from('<I',b,12+i*156+8)[0]==group]
  assert rows and all(row[3]//100==group for row in rows)
print('PASS: E archived geometry and independent groups; NOT an in-game render test')
