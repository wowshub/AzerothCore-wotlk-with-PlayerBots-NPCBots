local file=arg[1]
local now=0;local locale='zhCN';local sent={};local frames={};local id=9003143
function GetLocale() return locale end
function GetTime() return now end
function UnitClass() return '巫医','WITCHDOCTOR',13 end
function SendChatMessage(s) sent[#sent+1]=s end
function hooksecurefunc() end
function ChatFrame_AddMessageEventFilter(_,fn) _G.filter114=fn end
function CreateFrame()
 local f={};function f:RegisterEvent()end;function f:SetScript(k,v)self[k]=v end;frames[#frames+1]=f;return f
end
local function font(s) return {text=s,GetText=function(self)return self.text end,SetText=function(self,s)self.text=s end} end
GameTooltip={hooks={},n=4}
function GameTooltip:HookScript(k,v) self.hooks[k]=v end
function GameTooltip:GetSpell()return 'Skill','Rank 4',id end
function GameTooltip:GetName()return 'GameTooltip'end
function GameTooltip:NumLines()return self.n end
function GameTooltip:IsShown()return true end
function GameTooltip:AddLine(s)self.n=self.n+1;_G['GameTooltipTextLeft'..self.n]=font(s)end
function GameTooltip:SetHyperlink()end
function GameTooltip:SetSpellByID()end
function GameTooltip:SetSpellBookItem()end
function GameTooltip:SetAction()end
function GetSpellBookItemInfo()return 'SPELL',id end
function GetActionInfo()return 'spell',id end
RebornWD8={loaded=true,pending=false,revision=10,active=1,draftAE='99999999999999999999'}
local M=assert(loadfile(file))()
local function reset(s)
 GameTooltip.hooks.OnTooltipCleared(GameTooltip);GameTooltip.n=4
 GameTooltipTextLeft2=font(s or '330法力值');GameTooltipTextRight2=font('30码射程');GameTooltipTextLeft3=font('瞬发法术');GameTooltipTextLeft4=font('说明')
end
local function seq()return tonumber(sent[#sent]:match('numbers (%d+)'))end

local cases=0
for _,lang in ipairs({'zhCN','enUS'}) do
 locale=lang;now=0;frames={};sent={};M=assert(loadfile(file))()
 for _,first in ipairs({9003870,9003890}) do
  for rank=0,6 do
   id=first+rank
   for _,cooldown in ipairs({10000,15000,10000}) do
    M.invalidate();now=now+3;reset('826 Mana')
    GameTooltipTextRight3=font(lang=='zhCN' and '15秒冷却时间' or '15 sec Cooldown')
    GameTooltipTextLeft4=font(lang=='zhCN' and '蘑菇持续12秒，每3秒；15秒冷却。' or 'Shrooms 12 sec every 3 sec. 15 sec cooldown.')
    M.refresh(GameTooltip)
    assert(GameTooltipTextRight3.text:find('syncing',1,true) or GameTooltipTextRight3.text:find('同步中',1,true))
    M.receive('WD114|'..seq()..'|'..id..'|ok|826|293|319|10|1|160|12000|'..cooldown)
    local sec=tostring(cooldown/1000):gsub('%.0$','')
    assert(GameTooltipTextRight3.text==(lang=='zhCN' and sec..'秒冷却时间' or sec..' sec Cooldown'),GameTooltipTextRight3.text)
    assert(GameTooltipTextLeft4.text:find(lang=='zhCN' and sec..'秒冷却' or sec..' sec cooldown',1,true))
    assert(GameTooltipTextLeft4.text:find(lang=='zhCN' and '持续12秒' or '12 sec',1,true))
    assert(GameTooltipTextLeft5.text:find('cooldown '..sec..' sec',1,true))
    for rep=1,5 do M.refresh(GameTooltip) end
    assert(GameTooltip:NumLines()==5)
    -- Native action/book setter can rebuild the original Right heading in place.
    GameTooltipTextRight3:SetText(lang=='zhCN' and '15秒冷却时间' or '15 sec Cooldown')
    M.refresh(GameTooltip)
    assert(GameTooltipTextRight3.text==(lang=='zhCN' and sec..'秒冷却时间' or sec..' sec Cooldown'))
    cases=cases+1
   end
  end
 end
 -- No authoritative cooldown field: never invent a green 15-second result.
 id=9003876;M.invalidate();now=now+3;reset()
 GameTooltipTextRight3=font('15 sec Cooldown');M.refresh(GameTooltip)
 M.receive('WD114|'..seq()..'|'..id..'|ok|0|100|200|10|1|0|0')
 assert(GameTooltipTextLeft5.text:find('cooldown syncing',1,true))
 -- Late response for Toss must not repaint Splash.
 M.invalidate();now=now+3;id=9003876;reset();M.refresh(GameTooltip);local late=seq()
 id=9003896;reset();GameTooltipTextRight3=font('15 sec Cooldown');M.refresh(GameTooltip)
 M.receive('WD114|'..late..'|9003876|ok|0|100|200|10|1|0|0|10000')
 assert(GameTooltipTextRight3.text~='10 sec Cooldown')
end
print('PASS WD127F: '..cases..' potion rank/locale/build cases, Right header, Left description, green values, rebuild, stale replies, missing field and independent HoT duration')
