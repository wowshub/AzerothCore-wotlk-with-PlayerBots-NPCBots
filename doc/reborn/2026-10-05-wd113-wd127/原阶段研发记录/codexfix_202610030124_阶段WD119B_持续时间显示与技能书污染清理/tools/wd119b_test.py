from pathlib import Path
import subprocess,json
P=Path(Path('wd119b_path.txt').read_text().strip())
R=Path(r'D:\000rebornWOW\000RebornWOWHighForkPRO')
lua=R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe'
base=P/'02_覆盖到客户端根目录/Interface/AddOns'
test=(P/'tools/wd119_numeric_test.lua').read_text(encoding='utf8')
test+='''
-- Real DBC description, both client locales; the cast/CD heading stays independent.
for _,language in ipairs({'zhCN','enUS'}) do
 locale=language;now=0;frames={};sent={};M=assert(loadfile(file))()
 for rank=0,2 do
  for _,sid in ipairs({9003855,9003432}) do
   M.invalidate();now=now+3;id=sid;reset('')
   GameTooltipTextLeft4=font('基础（未计灵魂行者）：持续10秒，效果25%。 / Base values; current values shown below.')
   GameTooltipTextRight3=font(sid==9003855 and '2分钟冷却时间' or '45秒冷却时间')
   local header=GameTooltipTextRight3.text
   M.refresh(GameTooltip)
   assert(not GameTooltipTextLeft4.text:find('10秒',1,true))
   assert(GameTooltipTextLeft4.text:find('同步中',1,true))
   local duration=10000+1000*rank;local amount=({25,27,30})[rank+1]
   M.receive('WD114|'..seq()..'|'..sid..'|ok|0|'..duration..'|'..amount..'|10|1|'..(200+20*rank))
   local desc=GameTooltipTextLeft4.text
   assert(desc:find(string.format('%.1f秒',duration/1000),1,true))
   assert(desc:find(amount..'%',1,true))
   assert(not desc:find('未计',1,true))
   assert(GameTooltipTextRight3.text==header)
   for tick=1,10 do M.refresh(GameTooltip) end
   assert(GameTooltipTextLeft4.text==desc and GameTooltip.n==5)
   -- Cache invalidation removes both current prose and the summary immediately.
   M.invalidate();now=now+3;M.refresh(GameTooltip)
   assert(GameTooltipTextLeft4.text:find('同步中',1,true))
   assert(not GameTooltipTextLeft4.text:find(string.format('%.1f秒',duration/1000),1,true))
  end
 end
end
print('PASS WD119B real description: ranks 0/1/2, two skills, two languages, repeat paint, invalidate, independent cooldown')
'''
(P/'tools/wd119b_numeric_test.lua').write_text(test,encoding='utf8')
booktest='''
local function forbidden() error('Native mutation or render invocation from addon') end
local function frozen(t) return setmetatable({}, {__index=t,__newindex=forbidden,__pairs=function() return pairs(t) end,__ipairs=function() return ipairs(t) end}) end
BOOKTYPE_SPELL='spell'
SlashCmdList={}
function UnitClass() return '巫医','WITCHDOCTOR',13 end
function GetNumSpellTabs()return 2 end
function GetSpellTabInfo(i)if i==1 then return '综合',nil,0,1 else return '巫毒 / Voodoo',nil,1,1 end end
function GetSpellLink(i)return i==2 and 'spell:9003853' or 'spell:6603' end
function GetSpellInfo(id)return 'Test'..id end
function IsSpellKnown()return true end
local log={}
function print(s)log[#log+1]=s end
local events
function CreateFrame()events={RegisterEvent=function()end,SetScript=function(self,k,v)self[k]=v end};return events end
spellbookCustomRender=frozen({[2]=frozen({{spellID=9003853}})})
SpellBookFrame=frozen({bookType='spell'})
SPELLBOOK_PAGENUMBERS=frozen({[2]=1})
SpellBookFrame_UpdateSpellRender=forbidden
SpellButton_UpdateButton=forbidden
SpellBookSkillLineTab_OnClick=forbidden
hooksecurefunc=forbidden
CastSpellByID=forbidden
local before=SpellBookFrame_UpdateSpellRender
local M=assert(loadfile(arg[1]))()
SlashCmdList.REBORNWDBOOK('')
SlashCmdList.REBORNWDBOOK('假死')
SlashCmdList.REBORNWDBOOK('9003853')
assert(M.locate(9003853)==2)
assert(SpellBookFrame_UpdateSpellRender==before)
events.OnEvent(nil,'ADDON_ACTION_FORBIDDEN','DBM-Core','CastSpellByID()')
SlashCmdList.REBORNWDBOOK('假死')
assert(log[#log]:find('DBM-Core',1,true) and log[#log]:find('CastSpellByID',1,true))
io.write('PASS WD119B read-only book: native globals/tables/handlers untouched, diagnostics and blocked event preserved\\n')
'''
(P/'tools/wd119b_book_test.lua').write_text(booktest,encoding='utf8')
outputs=[]
for script,target in [('wd119b_numeric_test.lua','RebornWitchDoctorTalents/NumericTooltip.lua'),('wd119b_book_test.lua','RebornWitchDoctorSkillBook/RebornWitchDoctorSkillBook.lua')]:
 r=subprocess.run([str(lua),str(P/'tools'/script),str(base/target)],capture_output=True)
 out=(r.stdout+r.stderr).decode('utf8',errors='replace');print(out);outputs.append(out);assert r.returncode==0
syntax="for i=1,#arg do assert(loadfile(arg[i])) end; print('PASS delivered Lua syntax')"
(P/'tools/syntax.lua').write_text(syntax)
r=subprocess.run([str(lua),str(P/'tools/syntax.lua')]+[str(x) for x in base.rglob('*.lua')],capture_output=True)
assert r.returncode==0;outputs.append(r.stdout.decode())
(P/'checks').mkdir(exist_ok=True)
(P/'checks/lua.txt').write_text('\n'.join(outputs),encoding='utf8')
