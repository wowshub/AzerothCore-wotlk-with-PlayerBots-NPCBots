assert(loadfile(arg[4]))()
local M=RebornWD8
local low23=65024+2*2^32+2^17
for i=17,27 do low23=low23+(i==21 and 2*2^23 or 2^(i>=22 and i+3 or i+2)) end
M.level=80;M.teBudget=35;M.specs[1]=0
local d,o=2^40,2^39
assert(M.AERank(7100,d)==1 and M.TESpent(low23+d)==24)
assert(M.AEValid(low23+d));assert(not M.AEValid(low23-2^30+d))
assert(not M.AEValid(low23-2^30+d+o));assert(M.AEValid(low23+d+o))
M.teBudget=24;assert(not M.AEValid(low23+d+o));M.teBudget=25;assert(M.AEValid(low23+d+o))
M.specs[1]=1;assert(not M.AEValid(low23+d));M.specs[1]=0
assert(not M.AEValid(2^41));assert(M.AERank(31346,low23+d+o)==1)
M.draftAE=low23+d;M.aeMasks[1]=low23;M.aeDirty=true;M.dirty=true;M.pending=nil
local request;M.Request=function(s)request=s end;M.Save()
assert(request and request:match(' '..string.format('%.0f',low23+d)..'$'))
assert(M.AETooltip({ID=7100,AECost=0,TECost=1}))
print('PASS WD91: 41-bit decode/save, lower-tier gate, no circular bootstrap, budget/spec and tooltip')
