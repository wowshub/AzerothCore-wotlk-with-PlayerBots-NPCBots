unpack=unpack or table.unpack
function GetLocale() return 'zhCN' end
function InCombatLockdown() return false end
function CreateFrame() return {RegisterEvent=function() end,SetScript=function() end} end
function ChatFrame_AddMessageEventFilter() end
RebornWD8={}
assert(loadfile(arg[1]..'/WD8.lua'))();assert(loadfile(arg[1]..'/Allocation.lua'))()
local M=RebornWD8
M.level=50;M.teBudget=0;M.aeBudget=0;M.loaded=true;M.slot=0;M.active=0;M.specs={1,0,3};M.draftSpec=1;M.modern=true;M.revision=17;M.unlocked=3;M.aeDirty=true
M.draftAE=M.MaskSet(M.MaskSet(M.MaskSet(0,63,1,1),110,1,1),116,1,1)
assert(M.AEValid(M.draftAE));assert(M.AESpent(M.draftAE)==0)
local got;M.Request=function(cmd,kind) got=cmd;assert(kind=='save') end
M.Save();assert(got=='.wd67save 17 0 84374823951190958186992602204602368')
print('PASS actual M.Save '..got)
M.pending=true;got=nil;M.Save();assert(got==nil)
print('PASS pending save suppressed')

M.pending=false;M.level=49;assert(not M.AEValid(M.draftAE))
M.level=50;local good=M.draftAE;M.draftAE=M.MaskSet(good,110,1,0);assert(not M.AEValid(M.draftAE))
M.draftAE=good;M.specs[1]=0;assert(not M.AEValid(good));M.specs[1]=1
assert(M.TESpent(good)==0 and M.AESpent(good)==0)
assert(not M.AEValid(M.MaskSet(good,118,1,1)))
print('PASS WD135 free save, boundaries, parent, spec and unknown bits')
