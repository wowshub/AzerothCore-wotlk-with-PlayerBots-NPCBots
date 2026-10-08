unpack=unpack or table.unpack
RebornWD8={};function GetLocale() return 'zhCN' end
assert(loadfile(arg[1]))();local M=RebornWD8
M.level=40;M.teBudget=0;M.aeBudget=0;M.slot=0;M.active=0;M.specs={1,0,3};M.modern=true;M.revision=1;M.unlocked=3
local m=M.MaskSet(M.MaskSet(0,63,1,1),110,1,1)
assert(M.AEValid(m));assert(M.TESpent(m)==0);assert(M.AERank(4733,m)==1)
assert(M.MaskEqual(M.MaskParse(M.MaskDecimal(m)),m))
M.level=39;assert(not M.AEValid(m));M.level=40
M.specs[1]=0;assert(not M.AEValid(m));M.specs[1]=1
assert(not M.AEValid(M.MaskSet(m,63,1,0)))
assert(not M.AEValid(M.MaskSet(m,116,1,1)))
print('PASS WD132 free level40 node; exact mask '..M.MaskDecimal(m))
