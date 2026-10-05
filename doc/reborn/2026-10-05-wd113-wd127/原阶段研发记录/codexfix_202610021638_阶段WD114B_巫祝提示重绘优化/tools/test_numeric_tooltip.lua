local file=arg[1]
local now=0;local locale='zhCN';local sent={};local frames={};local id=9003143
function GetLocale() return locale end
function GetTime() return now end
function UnitClass() return '巫医','WITCHDOCTOR',13 end
function SendChatMessage(s) sent[#sent+1]=s end
local setters={}
function hooksecurefunc(_,name,fn) setters[name]=fn end
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
function GameTooltip:Show() self.shows=(self.shows or 0)+1;self.hooks.OnTooltipSetSpell(self) end
function GameTooltip:SetSpell()end
function GetSpellLink()return "spell:"..id end
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
reset();M.refresh(GameTooltip)
assert(#sent==1 and sent[1]:match('9003143$'))
assert(GameTooltipTextLeft2.text=='330法力值（同步中）')
M.receive('WD114|'..seq()..'|9003143|ok|165|0|0|10|1')
assert(GameTooltipTextLeft2.text=='165法力值' and GameTooltipTextRight2.text=='30码射程')
for i=1,20 do M.refresh(GameTooltip)end
assert(#sent==1 and GameTooltipTextLeft2.text=='165法力值') -- no double half
-- Draft/view changes are irrelevant; only actual saved active/revision reply counts.
RebornWD8.slot=0;RebornWD8.draftAE=0;M.refresh(GameTooltip);assert(GameTooltipTextLeft2.text=='165法力值')
M.invalidate();now=1.1;M.refresh(GameTooltip);local old=seq()
M.invalidate();now=2.2;M.refresh(GameTooltip);local fresh=seq()
M.receive('WD114|'..old..'|9003143|ok|7|0|0|10|1')
assert(GameTooltipTextLeft2.text:match('同步中'))
M.receive('WD114|'..fresh..'|9003143|ok|164|0|0|10|1')
assert(GameTooltipTextLeft2.text=='164法力值') -- actual integer from server, never forced to half displayed330
M.invalidate();now=3.3;M.refresh(GameTooltip)
M.receive('WD114|'..seq()..'|9003143|ok|165|0|0|9|1')
assert(GameTooltipTextLeft2.text:match('同步中')) -- stale revision rejected
now=4.4;M.refresh(GameTooltip)
M.receive('WD114|'..seq()..'|9003143|ok|330|0|0|10|0')
assert(GameTooltipTextLeft2.text:match('同步中')) -- stale active slot rejected
-- Unit aura invalidates cached cost without touching player talents.
frames[1].OnEvent(nil,'UNIT_AURA','player');now=5.5;M.refresh(GameTooltip)
M.receive('WD114|'..seq()..'|9003143|ok|175|0|0|10|1')
assert(GameTooltipTextLeft2.text=='175法力值')
-- Unsupported offensive spell stays untouched and never requests.
id=9003112;reset('835法力值');now=6.6;local before=#sent;M.refresh(GameTooltip)
assert(#sent==before and GameTooltipTextLeft2.text=='835法力值')
-- Power Wuju effect and mana use returned effective numbers; no extra formula.
id=9003185;reset();M.invalidate();now=7.7;M.refresh(GameTooltip)
M.receive('WD114|'..seq()..'|9003185|ok|165|278|278|10|1')
assert(GameTooltipTextLeft2.text=='165法力值' and GameTooltipTextLeft5.text:match('278'))
M.refresh(GameTooltip);assert(GameTooltip:NumLines()==5)
-- Hexbreak: display two attempts; no generic damage field spoofing.
id=9003240;reset();M.invalidate();now=8.8;M.refresh(GameTooltip)
M.receive('WD114|'..seq()..'|9003240|ok|240|2|0|10|1')
assert(GameTooltipTextLeft5.text=='可尝试移除诅咒数量：2')
-- Save pending never displays draft numbers or sends a query.
RebornWD8.pending=true;now=10;before=#sent;M.refresh(GameTooltip)
assert(#sent==before and GameTooltipTextLeft2.text:match('同步中'))
RebornWD8.pending=false
assert(filter114(nil,nil,'WD114|3|4|ok'))
assert(not filter114(nil,nil,'其他聊天消息'))
assert(M.allowed[9003762] and not M.allowed[9003760])
-- Fresh load English, isolated globals; localized mana format.
locale='enUS';id=9003143;reset('351 Mana');frames={};sent={};now=0
M=assert(loadfile(file))();M.refresh(GameTooltip)
M.receive('WD114|'..seq()..'|9003143|ok|175|0|0|10|1')
assert(GameTooltipTextLeft2.text=='175 Mana')
-- Missing/old server: after three failed attempts, stop rapid retries for a minute.
M.invalidate();now=2;M.refresh(GameTooltip);M.receive('WD114|'..seq()..'|9003143|unavailable')
now=3.1;M.refresh(GameTooltip);M.receive('WD114|'..seq()..'|9003143|unavailable')
now=4.2;M.refresh(GameTooltip);M.receive('WD114|'..seq()..'|9003143|unavailable')
local count=#sent;now=10;M.refresh(GameTooltip);assert(#sent==count)
now=65;M.refresh(GameTooltip);assert(#sent==count+1)
print('PASS WD114 tooltip: authoritative integer cost, no repeated halving, drafts ignored, stale replies, aura invalidation, range preserved, Power Wuju/Hexbreak effects, supported spell whitelist, Chinese/English')

-- WD114B: native setters, native FontString rebuild and synchronous Show hooks.
locale='zhCN';id=9003143;reset();sent={};now=100
M=assert(loadfile(file))()
setters.SetSpell(GameTooltip,1,'spell')
local previousShows=GameTooltip.shows
M.receive('WD114|'..seq()..'|9003143|ok|165|0|0|10|1')
assert(GameTooltip.shows>previousShows and GameTooltipTextLeft2.text=='165法力值')
local stableShows=GameTooltip.shows
M.refresh(GameTooltip);assert(GameTooltip.shows==stableShows) -- no unnecessary relayout loop
-- Native UI overwrites fonts while retaining the tooltip object.
GameTooltipTextLeft2:SetText('440法力值')
setters.SetAction(GameTooltip,1)
assert(GameTooltipTextLeft2.text=='165法力值')
M.invalidate();now=101.1;setters.SetSpellBookItem(GameTooltip,1,'spell')
assert(GameTooltipTextLeft2.text=='440法力值（同步中）') -- use current base, not cached330
M.receive('WD114|'..seq()..'|9003143|ok|220|0|0|10|1')
assert(GameTooltipTextLeft2.text=='220法力值')
-- A reused cost FontString is now a range; it must no longer be overwritten.
GameTooltipTextLeft2:SetText('30码射程');M.refresh(GameTooltip)
assert(GameTooltipTextLeft2.text=='30码射程')
-- Reply arrives after native spell switched, before our normal update hook.
reset();M.invalidate();now=102.2;M.refresh(GameTooltip);local late=seq()
id=9003112;GameTooltipTextLeft2:SetText('835法力值')
M.receive('WD114|'..late..'|9003143|ok|165|0|0|10|1')
assert(GameTooltipTextLeft2.text=='835法力值')
-- Hyperlink entrance and colored comma-formatted cost; zero is a valid server result.
id=9003143;reset('|cffffffff1,100法力值|r');M.invalidate();now=103.3
setters.SetHyperlink(GameTooltip,'spell:9003143')
M.receive('WD114|'..seq()..'|9003143|ok|0|0|0|10|1')
assert(GameTooltipTextLeft2.text=='0法力值')
setters.SetSpellByID(GameTooltip,9003143)
assert(GameTooltipTextLeft2.text=='0法力值' and not GameTooltip.wd114Drawing)
print('PASS WD114B: native book/action/link hooks, reentrant layout, stable layout, refreshed base cost, reused range font, late reply isolation, colored comma cost and zero cost')
