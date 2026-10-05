unpack=table.unpack or unpack
local commands={}
function CreateFrame() return {RegisterEvent=function()end,SetScript=function(self,k,v)self[k]=v end} end
function GetTime()return 100 end
function SendChatMessage(s)commands[#commands+1]=s end
function RebornWDRegisterTranslation()end
function ChatFrame_AddMessageEventFilter()end
function InCombatLockdown()return false end
function GetRealmName()return 'test' end
function UnitGUID()return 'player' end
StaticPopupDialogs={};YES='yes';NO='no'
function StaticPopup_Show()end
assert(loadfile(arg[1]))();assert(loadfile(arg[2]))()
local M=RebornWD8
local function reply(rev,mask,level)
 M.listener.OnEvent(nil,'CHAT_MSG_SYSTEM','WD16|ok|'..rev..'|0|0|0|1|2|'..(level or 80)..'|1|71|3|1|'..string.format('%.0f',mask)..'|0|0|36|35')
end
local base=15872+49152
reply(1,base)
assert(M.loaded and M.modern and M.AEValid(base))
local combos=0
for a=0,3 do for b=0,3 do for c=0,1 do
 for _,low in ipairs({0,1,3,64,127,128,base,1073741823,2147483648,4294967295})do
  local m=low+a*4294967296+b*17179869184+c*68719476736
  assert(M.AERank(31345,m)==a and M.AERank(6007,m)==b and M.AERank(11532,m)==c)
  assert(M.AERank(6059,m)==math.floor(low/1073741824)%2 and M.AERank(5332,m)==math.floor(low/2147483648)%2)
  assert(M.TESpent(m)==M.TESpent(low)+a+b)
  assert(M.TEFoundation(m)==M.TEFoundation(low)+a)
  combos=combos+1
 end
end end end
M.SetNode(31345,1);M.SetNode(31345,2);M.SetNode(6007,1);M.SetNode(6007,2);M.SetNode(11532,1)
local full=base+2*4294967296+2*17179869184+68719476736
assert(M.draftAE==full and M.AEValid(full))
M.Save();assert(commands[#commands]=='.wd67save 1 0 '..string.format('%.0f',full))
reply(2,full);assert(M.aeMasks[1]==full and M.AERank(11532)==1 and not M.dirty)
for _,node in ipairs({31345,6007,11532})do M.SetNode(node,0);assert(M.draftAE==full)end
reply(3,base);M.SetNode(31345,1);M.SetNode(31345,0);assert(M.draftAE==base)
assert(not M.AEValid(base+3*4294967296));assert(not M.AEValid(base+3*17179869184))
-- Loa ranks genuinely count toward foundation; Beware cannot count toward its own gate.
assert(M.AEValid(base-49152+16384+2*4294967296+17179869184))
assert(not M.AEValid(base-49152+16384+2*17179869184))
M.level=39;assert(not M.AEValid(68719476736));M.level=40;assert(M.AEValid(68719476736))
M.teBudget=0;assert(M.AEValid(68719476736));assert(not M.AEValid(4294967296));M.teBudget=35
M.specs[1]=1;assert(not M.AEValid(68719476736));assert(not M.AEValid(4294967296));M.specs[1]=0
local old=M.revision;reply(999,154742504910672534362390528);assert(M.revision==old)
reply(4,1099511627775);assert(M.aeMasks[1]==1099511627775)
reply(5,base)
GameTooltip={SetText=function()end,AddLine=function(self,s)assert(type(s)=='string')end}
for _,node in ipairs({31345,6007,11532})do assert(M.AETooltip({ID=node,AECost=0,TECost=node==11532 and 0 or 1}))end
print('PASS '..combos..' decode combinations; 40-bit protocol with WD87 regression, exact decimal save, rank/gates/free-level40/rollback UI guards')

