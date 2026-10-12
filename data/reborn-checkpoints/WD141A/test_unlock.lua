FILE=[[D:/000rebornWOW/000RebornWOWHighForkPRO/000Ascendupdate/000Ascendupdate20261012/codexfix_20261012_054431_阶段WD141A_面板金币解锁第三方案/02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents/Unlock.lua]]

local tests=0;local function ok(v,m)assert(v,m);tests=tests+1 end
local now=100;local gold=10000000;local combat=false;local dead=false;local draft=false
GetTime=function()return now end;GetMoney=function()return gold end;InCombatLockdown=function()return combat end;UnitIsDeadOrGhost=function()return dead end
RebornWD8={loaded=true,layoutReady=true,revision=5,unlocked=2,level=80,HasDrafts=function()return draft end,Query=function()queried=true end,CanEdit=function()return true end}
RebornWDLanguage='zh';StaticPopupDialogs={};DEFAULT_CHAT_FRAME={AddMessage=function()end}
SendChatMessage=function(s)sent=s end;StaticPopup_Show=function(_,_,_,q)popup=q end
CreateFrame=function()return {RegisterEvent=function()end,SetScript=function(self,k,v)self[k]=v end}end
dofile(FILE);local U=RebornWDUnlock;local M=RebornWD8
ok(not U.Quote(3),'reserved fourth slot');ok(sent==nil,'reserved must not send')
draft=true;ok(not U.Quote(2),'draft gate');draft=false
combat=true;ok(not U.Quote(2),'combat gate');combat=false
ok(U.Quote(2),'request quote');ok(sent=='.wd141quote 1 5 2','quote arguments')
ok(not M.CanEdit(),'pending blocks editing');ok(not U.Quote(2),'duplicate request')
U.Receive('WD141|99|quote|5|2|11|40|1000');ok(popup==nil,'unrelated sequence ignored')
U.Receive('WD141|1|quote|5|2|11|40|1000');ok(popup and popup.gold==1000,'server price');ok(M.CanEdit(),'quote finished')
local q=popup;StaticPopupDialogs.REBORN_WD141_UNLOCK.OnCancel(nil,q);ok(not U.Confirm(q),'cancel cannot buy')
U.Quote(2);U.Receive('WD141|2|quote|5|2|12|40|1000');q=popup;now=160;ok(not U.Confirm(q),'expired quote')
U.Quote(2);U.Receive('WD141|3|quote|5|2|13|40|1000');q=popup;gold=0;ok(not U.Confirm(q),'money check');gold=10000000
U.Quote(2);U.Receive('WD141|4|quote|5|2|14|40|1000');q=popup;M.revision=6;ok(not U.Confirm(q),'revision change');M.revision=5
U.Quote(2);U.Receive('WD141|5|quote|5|2|15|40|1000');q=popup;ok(U.Confirm(q),'buy');ok(sent=='.wd141buy 6 15 5 2','buy args');ok(not U.Confirm(q),'double accept')
U.Receive('WD141|6|ok|1');ok(U.pending~=nil,'wrong slot ignored');U.Receive('WD141|6|ok|2');ok(queried and not U.pending,'success refresh')
U.Quote(2);U.Receive('WD141|7|error|disabled');ok(not U.pending and M.message:find('尚未开启'),'disabled message')
U.Quote(2);now=now+9;U.listener.OnUpdate();ok(not U.pending,'timeout clears request');U.Receive('WD141|8|quote|5|2|16|40|1000');ok(U.quote==nil,'late quote ignored')
U.Quote(2);U.Receive('WD141|9|quote|5|2|17|40|0');ok(U.quote.gold==0,'zero-price configured');ok(U.Confirm(U.quote),'zero-price buy');now=now+9;U.listener.OnUpdate();ok(M.message:find('勿直接重复购买'),'purchase timeout not failure claim')
print('PASS '..tests..' purchase UI tests')
