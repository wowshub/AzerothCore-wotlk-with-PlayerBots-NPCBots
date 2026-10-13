
unpack=table.unpack or unpack
local now=100;GetTime=function()return now end
local hooks={};hooksecurefunc=function(obj,key,fn)hooks[key]=fn end
ITEM_COOLDOWN_TIME="冷却时间剩余：%s";ITEM_COOLDOWN_TIME_MIN="冷却时间剩余：%d 分钟";ITEM_COOLDOWN_TIME_SEC="冷却时间剩余：%d秒";ITEM_COOLDOWN_TIME_HOURS="剩余冷却时间：%d小时"
local start,duration,enabled=100,90,1
GetActionCooldown=function(slot)assert(slot==7);return start,duration,enabled end
GetSpellCooldown=function(id,book)assert(id=="Veil" or (id==4 and book=="spell"));return start,duration,enabled end
GetSpellInfo=function(id)if id==9003962 then return "Veil"end end
local function line(t)return {text=t,GetText=function(self)return self.text end,SetText=function(self,s)self.text=s end}end
GameTooltipTextLeft1=line('黑暗帷幕');GameTooltipTextLeft2=line('1.5分钟冷却时间');GameTooltipTextLeft3=line('冷却时间剩余：2 分钟')
local scripts={};local owner={action=7};GameTooltip={shown=true,GetOwner=function()return owner end,IsShown=function(self)return self.shown end,GetName=function()return 'GameTooltip'end,NumLines=function()return 3 end,GetSpell=function()return 'Veil',9003962 end,HookScript=function(self,k,f)scripts[k]=f end,SetAction=function()end,SetSpell=function()end,SetHyperlink=function()end}

local locale="zhCN";GetLocale=function()return locale end
SlashCmdList={}
local frames={};CreateFrame=function()local f={SetScript=function(self,k,fn)self[k]=fn end};frames[#frames+1]=f;return f end
local root=arg[1]..'/02_覆盖到客户端根目录/Interface/AddOns/'
dofile(root..'DragonUI/modules/precisecooldowns.lua')
local function tick()frames[1]:OnUpdate(.11)end
local function native()GameTooltipTextLeft3.text='冷却时间剩余：2 分钟'end
local function expected(s)assert(GameTooltipTextLeft3.text=='冷却时间剩余：'..s,GameTooltipTextLeft3.text)end
hooks.SetAction(GameTooltip,7);expected('90秒');assert(GameTooltipTextLeft2.text=='1.5分钟冷却时间')
for _,case in ipairs({{101,'89秒'},{130,'60秒'},{131,'59秒'},{189.5,'1秒'}})do now=case[1];tick();expected(case[2])end
now=190;tick();assert(GameTooltipTextLeft3.text=='')
now=100
for _,text in ipairs({'冷却时间剩余: 2 分钟','|cffffffff冷却时间剩余： 2 分钟|r','剩余冷却时间：2分钟'})do GameTooltipTextLeft3.text=text;tick();expected('90秒')end
scripts.OnTooltipCleared();native();tick();expected('90秒') -- owner fallback
owner=nil;scripts.OnTooltipCleared();native();tick();expected('90秒') -- spell fallback
scripts.OnTooltipSetItem();native();tick();assert(GameTooltipTextLeft3.text=='冷却时间剩余：2 分钟')
hooks.SetSpell(GameTooltip,4,'spell');expected('90秒')
scripts.OnTooltipCleared();hooks.SetHyperlink(GameTooltip,'spell:9003962');expected('90秒')
GameTooltipTextRight3=line('冷却时间剩余：2 分钟');tick();assert(GameTooltipTextRight3.text=='冷却时间剩余：90秒')
enabled=0;native();tick();assert(GameTooltipTextLeft3.text=='冷却时间剩余：2 分钟');enabled=1
GameTooltip.shown=false;scripts.OnHide();native();tick();assert(GameTooltipTextLeft3.text=='冷却时间剩余：2 分钟');GameTooltip.shown=true;tick();expected('90秒')
start=0;tick();assert(GameTooltipTextLeft3.text=='');start=100
locale='enUS';ITEM_COOLDOWN_TIME='Cooldown remaining: %s';GameTooltipTextLeft3.text='Cooldown remaining: 2 min';tick();assert(GameTooltipTextLeft3.text=='Cooldown remaining: 90s')
dofile(root..'RebornCooldownDisplay/RebornCooldownDisplay.lua');assert(#frames==1);assert(SlashCmdList.REBORNCOOLDOWNDISPLAY)
local addon={L={},db={profile={buttons={cooldown={color={1,1,0}}}}}}
assert(loadfile(root..'DragonUI/modules/cooldowns.lua'))('DragonUI',addon)
local out={SetText=function(self,t)self.text=t end,SetTextColor=function()end,SetFormattedText=function(self,fmt,n)self.text=string.format(fmt,n)end,Hide=function(self)self.hidden=true end}
local cd={text=out,GetParent=function()return {action=7}end}
for _,case in ipairs({{90,90},{61,61},{60,60},{59,59},{5,'5.0'},{3600,3600},{3661,3661}})do cd.remain=now+case[1];cd.duiNextTick=0;addon.cooldownMixin.update_cooldown(cd,.3);assert(out.text==case[2],tostring(out.text))end
cd.remain=now;cd.duiNextTick=0;addon.cooldownMixin.update_cooldown(cd,.3);assert(cd.remain==nil and out.hidden)
dofile(root..'Cooldowns/Cooldowns.lua')
for _,threshold in ipairs({0,10,60,120})do
 YarkoCooldowns_SavedVars={Seconds=threshold,Tenths='Y',BelowTwo='N'}
 for _,case in ipairs({{90,90},{61,61},{60,'60'},{59,'59'},{3600,3600},{1,'1'}})do assert(YarkoCooldowns.GetTimeFormat(case[1])==tostring(case[2]))end
end
YarkoCooldowns_SavedVars.BelowTwo='Y';assert(YarkoCooldowns.GetTimeFormat(1.4)=='1.4')
print('PASS UI9C base: both real overlay formatters, tooltip action/book/link/fallbacks, locale/colon/color/right-line, expiry/disabled/item isolation, independent timer, duplicate-load guard, threshold settings')

format=string.format
UIParent={GetScale=function()return 1 end}
ActionButton1Cooldown=setmetatable({},{__index={SetCooldown=function()end}})
local stub={Hide=function()end};LibStub=function()return {New=function()return stub end}end
local priorCreateFrame=CreateFrame
CreateFrame=function()return {Hide=function()end,SetScript=function()end,RegisterEvent=function()end}end
OmniCC={GetTenthsDuration=function()return 5 end,GetFontInfo=function()return 'font',18,'OUTLINE'end,ScalingText=function()return true end,GetMMSSDuration=function()return 0 end}
dofile(root..'OmniCC/cc.lua')
local timer=setmetatable({cooldown={GetParent=function()return {action=7}end}},{__index=OmniCC.Timer})
for _,c in ipairs({{90,90},{81,81},{60,60},{59.1,60},{5,5},{4.9,'4.9'},{0,''}})do local text,delay=timer:GetTimeText(c[1]);assert(text==c[2],tostring(text));assert(delay>0 and delay<=.1)end
local size;timer.text={SetFont=function(self,f,s,o)size=s;return true end};timer.GetWidth=function()return 36 end;timer.UpdateShown=function()end;timer:UpdateFont();assert(size==13.5)
local other=setmetatable({cooldown={GetParent=function()return {}end}},{__index=OmniCC.Timer});assert(other:GetTimeText(81)=='1m')
print('PASS UI9C OmniCC actual file: 90/81/60/59.1/5/4.9/expiry, tick interval, 18->13.5 font, non-action unchanged')
