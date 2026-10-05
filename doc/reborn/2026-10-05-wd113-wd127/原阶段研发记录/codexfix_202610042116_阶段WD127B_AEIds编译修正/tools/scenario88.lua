-- The harness first loads the actual WD87 regression scenario against WD88's Lua.
assert(loadfile(arg[3]))()
local M=RebornWD8
M.level=80;M.teBudget=35;M.aeBudget=36;M.specs[1]=0
local o,j,d=2^37,2^38,2^39
for a=0,1 do for b=0,1 do for c=0,1 do
 for _,low in ipairs({0,65024,2^32-1,2^36,2^37-1})do
  local m=low+a*o+b*j+c*d
  assert(M.AERank(4532,m)==a and M.AERank(29121,m)==b and M.AERank(31346,m)==c)
  assert(M.AERank(11532,m)==M.AERank(11532,low))
  assert(M.TESpent(m)==M.TESpent(low)+b+c)
 end
end end end
M.level=29;assert(not M.AEValid(o));M.level=30;assert(M.AEValid(o))
M.teBudget=0;assert(M.AEValid(o));M.teBudget=35
M.level=32;assert(not M.AEValid(65024+j));M.level=33;assert(M.AEValid(65024+j))
assert(not M.AEValid(65024-512+j))
M.level=80
local low23=65024+2*2^32+2^17
for i=17,27 do low23=low23+(i==21 and 2*2^23 or 2^(i>=22 and i+3 or i+2)) end
assert(M.TESpent(low23)==23 and M.AEValid(low23))
assert(M.AEValid(low23+d))
assert(not M.AEValid(low23-2^30+d)) -- Cannot use Other itself as the 23rd prerequisite point.
assert(not M.AEValid(low23-2^30+o+d)) -- Free node cannot count as TE.
assert(M.AEValid(low23-2^30+j+d))
M.teBudget=23;assert(not M.AEValid(low23+d));M.teBudget=35
M.specs[1]=1;assert(not M.AEValid(o));assert(not M.AEValid(low23+d));M.specs[1]=0
M.draftAE=low23+o+j+d;M.aeMasks[1]=low23;M.loaded=true;M.modern=true;M.pending=nil;M.slot=0;M.active=0;M.aeDirty=true
local request
M.Request=function(s)request=s end
M.Save();assert(request and request:match(' '..string.format('%.0f',M.draftAE)..'$'))
for _,id in ipairs({4532,29121,31346})do assert(M.AETooltip({ID=id,AECost=0,TECost=id==4532 and 0 or 1}))end
print('PASS WD88: 40 high-bit combinations, 30/33 levels, free node, 23 prior TE, budget/spec and exact save')
