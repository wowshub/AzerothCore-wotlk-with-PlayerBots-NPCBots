unpack=unpack or table.unpack
function GetLocale() return 'zhCN' end
function InCombatLockdown() return false end
function CreateFrame() return {RegisterEvent=function() end,SetScript=function() end} end
function ChatFrame_AddMessageEventFilter() end
RebornWD8={}
assert(loadfile(arg[1]..'/WD8.lua'))();assert(loadfile(arg[1]..'/Allocation.lua'))()
local M=RebornWD8
M.level=40;M.teBudget=0;M.aeBudget=0;M.loaded=true;M.slot=0;M.active=0;M.specs={1,0,3};M.draftSpec=1;M.modern=true;M.revision=17;M.unlocked=3;M.aeDirty=true
M.draftAE=M.MaskSet(M.MaskSet(0,63,1,1),110,1,1)
assert(M.AEValid(M.draftAE));assert(M.AESpent(M.draftAE)==0)
local got;M.Request=function(cmd,kind) got=cmd;assert(kind=='save') end
M.Save();assert(got=='.wd67save 17 0 1298074214633716130504660937080832')
print('PASS actual M.Save '..got)
M.pending=true;got=nil;M.Save();assert(got==nil)
print('PASS pending save suppressed')
