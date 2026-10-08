unpack=unpack or table.unpack
RebornWD8={};function GetLocale() return 'zhCN' end
assert(loadfile(arg[1]))();local M=RebornWD8
M.level=80;M.teBudget=100;M.aeBudget=100;M.slot=0;M.active=0;M.specs={1,0,3};M.modern=true;M.revision=1;M.unlocked=3
local function set(m,i) return M.MaskSet(m,i,1,1) end
local f=set(0,84);f=M.MaskSet(f,55,2,2);f=M.MaskSet(f,57,2,2);f=M.MaskSet(f,59,2,2);f=set(set(f,62),64)
assert(M.BrewingFoundation(f)==8)
local parent=set(f,89)
for _,bit in ipairs({105,107}) do
 local m=set(parent,bit);assert(M.AEValid(m));assert(M.TESpent(m)==10)
 assert(not M.AEValid(set(f,bit)));assert(not M.AEValid(M.MaskSet(m,84,1,0)))
 M.specs[1]=0;assert(not M.AEValid(m));M.specs[1]=1
 M.teBudget=9;assert(not M.AEValid(m));M.teBudget=100
 assert(M.MaskEqual(M.MaskParse(M.MaskDecimal(m)),m))
end
M.level=28;assert(not M.AEValid(set(parent,105)));M.level=29;assert(M.AEValid(set(parent,105)));M.level=80
assert(not M.AEValid(set(set(parent,107),65)))
local splash=set(set(f,92),106);assert(M.AEValid(splash));assert(not M.AEValid(set(f,106)))
local full=set(set(set(set(parent,92),105),106),107);assert(M.AEValid(full));assert(M.TESpent(full)==13)
assert(not M.AEValid(set(full,108)))
for i=0,104 do local m=set(0,i);assert(M.MaskEqual(M.MaskSet(set(m,107),107,1,0),m)) end
print('PASS WD130 Lua 108-bit save, three nodes, prerequisites, choice, level, budget, old bits')
