from pathlib import Path
import shutil,datetime,json,hashlib
R=Path(r'D:\000rebornWOW\000RebornWOWHighForkPRO')
C=R/'beascendclient/newrebornWOWli20260929beAscend'
A=Path('wd119_path.txt').read_text().strip()
A=Path(A)
P=R/'000Ascendupdate/000Ascendupdate20261003'/('codexfix_'+datetime.datetime.now().strftime('%Y%m%d%H%M')+'_阶段WD119B_持续时间显示与技能书污染清理')
P.mkdir(parents=True,exist_ok=False)
Path('wd119b_path.txt').write_text(str(P))
def put(rel,s):
 f=P/rel;f.parent.mkdir(parents=True,exist_ok=True);f.write_text(s,encoding='utf8')
def capture(src,rel):
 f=P/rel;f.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,f)
base='02_覆盖到客户端根目录/Interface/AddOns/'
book='RebornWitchDoctorSkillBook/RebornWitchDoctorSkillBook.lua'
numeric='RebornWitchDoctorTalents/NumericTooltip.lua'
cool='RebornWDCooldownTooltip/Cooldown.lua'
for rel in [book,numeric,cool]:capture(C/'Interface/AddOns'/rel,'rollback_安装前客户端/Interface/AddOns/'+rel)
capture(A/base/numeric,'research/WD119A_NumericTooltip.lua')
old=(C/'Interface/AddOns'/book).read_text(encoding='utf-8-sig')
prefix=old.split('-- WD114C:')[0]
scan=old[old.index('local function isDoctor()'):old.index('local busy=false')]
locate=old[old.index('local function locate(id)'):old.index('SlashCmdList.REBORNWDBOOK=function(arg)')]
put(base+book,prefix+'''-- WD119B: read-only diagnostics. Never refresh, navigate or mutate native spellbook state.
local ids={9003850,9003851,9003852,9003853,9003854,9003855,9003432,9003857,9003858}
'''+scan+locate+'''
local names={['假死']=9003853,['假死药剂']=9003853,['显性诅咒']=9003852,['強效混合']=9003854,['强效混合']=9003854,['沃金守望']=9003855,['迅捷神像']=9003432}
local previous=SlashCmdList.REBORNWDBOOK
local lastBlocked
local monitor=CreateFrame('Frame')
monitor:RegisterEvent('ADDON_ACTION_BLOCKED')
monitor:RegisterEvent('ADDON_ACTION_FORBIDDEN')
monitor:SetScript('OnEvent',function(_,event,addon,operation)
 if isDoctor() then lastBlocked={event,tostring(addon),tostring(operation)} end
end)
SlashCmdList.REBORNWDBOOK=function(arg)
 if not isDoctor() then return end
 local text=(arg or ''):match('^%s*(.-)%s*$')
 local id=tonumber(text) or names[text]
 if not id then previous() end
 local native=scan()
 for _,sid in ipairs(id and {id} or ids) do
  local tab,page,slot=locate(sid)
  print(string.format('[WD119B] %d %s 已学=%s 原生槽=%s 分类=%s 页=%s 格=%s',sid,GetSpellInfo(sid) or '?',tostring(IsSpellKnown(sid)),tostring(native[sid] and native[sid].slot),tostring(tab),tostring(page),tostring(slot)))
 end
 print('[WD119B] 只读定位：请手动点击对应分类和页码；左右列交替计格。')
 if lastBlocked then print('[WD119B] 最近受保护操作：'..table.concat(lastBlocked,' / ')) end
end
return {locate=locate,scan=scan}
''')
s=(A/base/numeric).read_text(encoding='utf-8-sig')
# Retain the complete latest protocol, including WD119 frog and WD118 Slither.
anchor='local function draw(self,forced)'
helper='''-- WD119B: replace only this pair's base-value description, using server values.
local function walkerDescription(id,value)
 local lead=value and '当前效果 / Current effect: ' or '当前效果同步中 / Syncing current effect. '
 if id==9003855 then
  if not value then return lead..'持续时间、减伤与每秒治疗等待服务器确认。' end
  return string.format('持续%.1f秒，受到伤害降低%d%%，基础每秒恢复最大生命的%.2f%%。 / Lasts %.1f sec; damage taken -%d%%; base healing %.2f%% max health/sec.',value.a/1000,value.b,(value.c or 200)/100,value.a/1000,value.b,(value.c or 200)/100)
 end
 local limits='30码内视线可达的自己与队伍成员；与其他神像共用一个名额，守卫、神像和雕像名额彼此独立。 / Affects self and party in line of sight within 30 yd; shares the idol limit, separate from wards and effigies.'
 if not value then return lead..limits end
 return string.format('放置神像，持续%.1f秒，移动速度与抵抗定身/减速的几率提高%d%%。 / Summon an idol for %.1f sec; movement speed and root/snare resistance +%d%%. ',value.a/1000,value.b,value.a/1000,value.b)..limits
end
'''
assert s.count(anchor)==1;s=s.replace(anchor,helper+anchor)
needle='    if clean:match("^%s*%d[%d,%. ]*%s*法力值%s*$")'
new='''    if (id==9003855 or id==9003432) and side=="Left" and (clean:find("基础（未计灵魂行者）",1,true) or clean:find("基础 (未计灵魂行者)",1,true) or clean:find("Base values; current values shown below.",1,true) or clean:find("Base values: current values shown below.",1,true)) then
     local rendered=walkerDescription(id,value)
     self.wd114Lines[key]={original=original,rendered=rendered}
     if text~=rendered then font:SetText(rendered);changed=true end
    elseif clean:match("^%s*%d[%d,%. ]*%s*法力值%s*$")'''
assert needle in s;s=s.replace(needle,new)
s=s.replace('Current: %.1f sec;','Current duration: %.1f sec;').replace('当前：%.1f秒；','当前持续时间：%.1f秒；')
put(base+numeric,s)
s=(C/'Interface/AddOns'/cool).read_text(encoding='utf-8-sig')
s=s.replace("(english and 'Hastened: ' or '迅捷召唤：')","(english and 'Cooldown (Hastened): ' or '冷却时间（迅捷召唤）：')")
put(base+cool,s)
capture(A/'tools/wd119_numeric_test.lua','tools/wd119_numeric_test.lua')
capture(Path(__file__),'tools/wd119b_build.py')
print(P)
