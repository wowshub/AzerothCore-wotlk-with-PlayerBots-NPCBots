from pathlib import Path
import subprocess
P=Path(Path('wd117_path.txt').read_text(encoding='utf8'));T=P/'tools'
s=(T/'wd114_numeric_test.lua').read_text(encoding='utf8')+'''
M.invalidate();id=9003855;reset('');now=70;M.refresh(GameTooltip)
M.receive('WD114|'..seq()..'|9003855|ok|0|11000|27|10|1|220')
assert(GameTooltipTextLeft5.text:find('11.0',1,true) and GameTooltipTextLeft5.text:find('27%',1,true) and GameTooltipTextLeft5.text:find('2.20%',1,true))
M.invalidate();id=9003432;reset('');now=72;M.refresh(GameTooltip)
M.receive('WD114|'..seq()..'|9003432|ok|0|12000|30|10|1|0')
assert(GameTooltipTextLeft5.text:find('12.0',1,true) and GameTooltipTextLeft5.text:find('30%',1,true))
locale='zhCN';M.invalidate();id=9003855;reset('');now=74;M.refresh(GameTooltip)
M.receive('WD114|'..seq()..'|9003855|ok|0|12000|30|10|1|240')
assert(GameTooltipTextLeft5.text:find('12.0',1,true) and GameTooltipTextLeft5.text:find('2.40%',1,true))
print('PASS WD117 server duration, integer effect and fractional healing; Chinese/English')
'''
(T/'wd117_numeric_test.lua').write_text(s,encoding='utf8')
lua=Path('D:/000rebornWOW/000RebornWOWHighForkPRO/beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe')
r=subprocess.run([str(lua),str(T/'wd117_numeric_test.lua'),str(P/'02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents/NumericTooltip.lua')],capture_output=True,encoding='utf8',errors='replace')
(P/'checks/numeric_tooltip.txt').write_text(r.stdout+r.stderr,encoding='utf8');print(r.stdout,r.stderr);assert r.returncode==0
