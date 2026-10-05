local active=true
local locale='zhCN'
function UnitClass()return '巫医','WITCHDOCTOR',13 end
function GetLocale()return locale end
function IsSpellKnown(id)return id==9003653 and active end
function GetActionInfo(slot)return slot==1 and 'spell' or 'item',9003370 end
function GetSpellBookItemInfo()return 'SPELL',9003370 end
local hooks={}
function hooksecurefunc(t,n,f)hooks[n]=f end
local function font(text)return {text=text,GetText=function(self)return self.text end,SetText=function(self,x)self.text=x end}end
GameTooltip={n=5,hooks={}}
function GameTooltip:GetName()return 'GameTooltip'end
function GameTooltip:NumLines()return self.n end
function GameTooltip:AddLine(text)self.n=self.n+1;_G['GameTooltipTextLeft'..self.n]=font(text)end
function GameTooltip:Show()end
function GameTooltip:GetSpell()return 'Spirit Idol',9003370 end
function GameTooltip:HookScript(n,f)self.hooks[n]=f end
function GameTooltip:SetSpellByID()end
function GameTooltip:SetSpellBookItem()end
local function reset()
 if GameTooltip.hooks.OnTooltipCleared then GameTooltip.hooks.OnTooltipCleared(GameTooltip)end
 GameTooltip.n=5
 for i=1,12 do _G['GameTooltipTextLeft'..i]=nil;_G['GameTooltipTextRight'..i]=nil end
 GameTooltipTextRight2=font('3分钟冷却时间')
 GameTooltipTextLeft3=font('持续15秒，每3秒恢复法力。')
 GameTooltipTextLeft4=font('冷却时间剩余：1分20秒')
end
local T=assert(loadfile(arg[1]))()
assert(T.Duration(135)=='2分15秒' and T.Duration(33.75)=='33.75秒')
local count=0
for _,route in ipairs({'event','SetHyperlink','SetSpellByID','SetSpellBookItem','SetAction'})do
 reset()
 if route=='event'then GameTooltip.hooks.OnTooltipSetSpell(GameTooltip)
 elseif route=='SetHyperlink'then hooks[route](GameTooltip,'spell:9003370')
 elseif route=='SetSpellByID'then hooks[route](GameTooltip,9003370)
 elseif route=='SetSpellBookItem'then hooks[route](GameTooltip,1,'spell')
 else hooks[route](GameTooltip,1)end
 assert(GameTooltipTextRight2.text=='2分15秒冷却时间',route)
 assert(GameTooltipTextLeft6.text=='迅捷召唤：3分 × 75% = 2分15秒')
 assert(GameTooltipTextLeft3.text=='持续15秒，每3秒恢复法力。')
 assert(GameTooltipTextLeft4.text=='冷却时间剩余：1分20秒')
 T.Describe(GameTooltip,9003370);assert(GameTooltip.n==6)
 active=false;GameTooltip.hooks.OnUpdate(GameTooltip,.25);assert(GameTooltipTextRight2.text=='3分冷却时间')
 active=true;GameTooltip.hooks.OnUpdate(GameTooltip,.25);assert(GameTooltipTextRight2.text=='2分15秒冷却时间')
 count=count+1
end
reset();T.Describe(GameTooltip,9003800);assert(GameTooltip.n==5 and not GameTooltip.wd100Cooldown) -- War Golem not scoped by Hastened
reset();hooks.SetAction(GameTooltip,2);assert(GameTooltip.n==5) -- item tooltips untouched
reset();T.Describe(GameTooltip,9003420);assert(GameTooltipTextRight2.text=='33.75秒冷却时间')
reset();T.Describe(GameTooltip,9003432);assert(GameTooltipTextRight2.text=='45秒冷却时间')
reset();T.Describe(GameTooltip,9003673);assert(GameTooltipTextRight2.text=='45秒冷却时间')
locale='enUS';local E=assert(loadfile(arg[1]))();reset();GameTooltipTextRight2.text='3 min cooldown';E.Describe(GameTooltip,9003370)
assert(GameTooltipTextRight2.text=='2 min 15 sec cooldown')
assert(GameTooltipTextLeft6.text=='Hastened: 3 min × 75% = 2 min 15 sec')
print('PASS WD100 cooldown tooltip: '..count..' routes; 180->135, 60->45, 45->33.75; repeat/switch/no-draft/no-duration/no-remaining/no-unrelated; zhCN/enUS')
