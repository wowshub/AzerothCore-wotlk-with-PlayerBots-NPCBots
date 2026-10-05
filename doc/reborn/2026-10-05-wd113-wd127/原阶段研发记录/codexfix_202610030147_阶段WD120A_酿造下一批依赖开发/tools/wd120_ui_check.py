from pathlib import Path
import subprocess
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd120_path.txt').read_text());B=Path(Path('wd119c_path.txt').read_text());T=P/'tools';A=P/'02_覆盖到客户端根目录/Interface/AddOns';lua=R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe'
s=(B/'tools/wd119c_numeric_test.lua').read_text(encoding='utf8')+'''
locale='zhCN';now=100;frames={};sent={};M=assert(loadfile(file))()
for _,spell in ipairs({9003865,9003870,9003876}) do
 id=spell;now=now+3;reset();M.invalidate();M.refresh(GameTooltip)
 M.receive('WD114|'..seq()..'|'..spell..'|ok|0|200|240|10|1')
 local line=_G['GameTooltipTextLeft'..GameTooltip.n].text
 assert(line:find('200',1,true) and line:find('240',1,true))
 for i=1,5 do M.refresh(GameTooltip) end
 assert(GameTooltip.n==5)
 M.invalidate();now=now+3;M.refresh(GameTooltip)
 assert(not _G['GameTooltipTextLeft'..GameTooltip.n].text:find('200',1,true))
end
print('PASS WD120 query values / min-max / no stale heal number after invalidation')
'''
(T/'wd120_numeric_test.lua').write_text(s,encoding='utf8')
for name,script,addon in [('numeric','wd120_numeric_test.lua','RebornWitchDoctorTalents/NumericTooltip.lua'),('book','wd119b_book_test.lua','RebornWitchDoctorSkillBook/RebornWitchDoctorSkillBook.lua'),('cooldown','wd119b_cooldown_test.lua','RebornWDCooldownTooltip/Cooldown.lua')]:
 if name!='numeric':(T/script).write_bytes((B/'tools'/script).read_bytes())
 r=subprocess.run([str(lua),str(T/script),str(A/addon)],capture_output=True,encoding='utf8',errors='replace');(P/'checks'/('ui_'+name+'.txt')).write_text(r.stdout+r.stderr,encoding='utf8');print(r.stdout,r.stderr);assert r.returncode==0
