unpack=unpack or table.unpack
RebornWD8={};function GetLocale() return 'zhCN' end
assert(loadfile(arg[1]))();local M=RebornWD8
M.level=80;M.teBudget=100;M.aeBudget=100;M.slot=0;M.active=0;M.specs={1,0,3};M.modern=true;M.revision=1;M.unlocked=3
local function set(m,i) return M.MaskSet(m,i,1,1) end
local f=set(set(0,84),85);f=M.MaskSet(f,55,2,2);f=M.MaskSet(f,57,2,2);f=M.MaskSet(f,59,2,2);f=set(set(f,62),64)
for _,pair in ipairs({{108,97,6016},{109,103,6009}}) do
 local m=set(set(f,pair[2]),pair[1]);assert(M.AEValid(m));assert(M.TESpent(m)==10)
 assert(not M.AEValid(set(f,pair[1])));assert(not M.AEValid(M.MaskSet(m,85,1,0)));assert(not M.AEValid(M.MaskSet(m,84,1,0)))
 M.specs[1]=0;assert(not M.AEValid(m));M.specs[1]=1
 M.teBudget=9;assert(not M.AEValid(m));M.teBudget=100
 M.level=9;assert(not M.AEValid(m));M.level=80
 assert(M.MaskEqual(M.MaskParse(M.MaskDecimal(m)),m));assert(M.AERank(pair[3],m)==1)
 print('Exact saved mask',pair[3],M.MaskDecimal(m))
end
local full=set(set(set(set(f,97),103),108),109);assert(M.AEValid(full));assert(M.TESpent(full)==12);assert(not M.AEValid(set(full,110)))
for i=0,107 do local m=set(0,i);assert(M.MaskEqual(M.MaskSet(set(m,109),109,1,0),m)) end
print('PASS WD131 two new nodes; decimal/old bits/budget/spec/ingredient gates')
