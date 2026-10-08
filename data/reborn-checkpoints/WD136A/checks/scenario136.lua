unpack=unpack or table.unpack
RebornWD8={};function GetLocale() return 'zhCN' end
assert(loadfile(arg[1]))();local M=RebornWD8
M.level=80;M.teBudget=100;M.aeBudget=100;M.slot=0;M.active=0;M.specs={1,0,3};M.modern=true;M.revision=1;M.unlocked=3
local index={[29744]=0,[6054]=1,[6047]=2,[7092]=3,[29309]=4,[29301]=5,[4004]=6,[31154]=7,[31344]=8,[31340]=9,[7157]=10,[6058]=11,[29928]=12,[30973]=13,[4533]=14,[31341]=15,[6045]=16,[31347]=17,[31348]=18,[6644]=19,[6046]=20,[6062]=21,[30889]=22,[31343]=23,[6053]=24,[31350]=25,[5333]=26,[6059]=27,[5332]=28,[31345]=29,[6007]=30,[11532]=31,[4532]=32,[29121]=33,[31346]=34,[7100]=35,[29768]=36,[6057]=37,[30596]=38,[7088]=39,[30147]=40,[4132]=41,[31349]=42,[29929]=43,[6055]=44,[11133]=45,[7033]=46,[6051]=47,[6048]=48,[7131]=49,[30884]=50,[29736]=51,[9311]=52,[5055]=53,[4715]=54,[7129]=55,[7948]=56,[31137]=57,[30891]=59,[6030]=60,[7132]=61,[29753]=62,[6381]=63,[12048]=64,[11323]=65,[31118]=66,[12264]=67,[6042]=68,[9347]=69,[29306]=70,[6031]=71,[6525]=72,[12525]=73,[4005]=74,[12645]=75,[12646]=76,[6498]=77,[29303]=78,[6020]=79,[29737]=80,[7128]=81,[35065]=82,[35064]=83,[35068]=84,[29738]=85,[30888]=86,[35051]=87,[6645]=88,[4112]=89,[7130]=90,[6021]=91,[6014]=92,[30823]=93,[6022]=94,[6013]=95,[6016]=96,[6009]=97,[4733]=98,[6015]=99,[29310]=100,[29754]=101,[30333]=102,[6027]=103,[13133]=104,[6026]=105}
local function Shift(i) return i==83 and 94 or i>=84 and (i+12) or i==77 and 87 or i>=78 and (i+11) or i>=70 and (i+10) or i>=52 and (i+9) or i>=49 and (55+2*(i-49)) or i==39 and 44 or i>=40 and (i+6) or i>=32 and (i+5) or i>=29 and (32+2*(i-29)) or i<3 and i or (i>=22 and i+3 or (i>=14 and i+2 or i+1)) end
local function add(m,id,r) return M.MaskSet(m,Shift(index[id]),1,r or 1) end

local base="20604371637084532008189945406554112"
base=add(add(base,6014),12645)
for _,id in ipairs({30333,6027,29754,6026}) do base=add(base,id,0) end
assert(M.AEValid(base))
for pass=1,6 do for i=100,49,-1 do for id,k in pairs(index) do
 if k==i and id~=6014 and id~=12645 and M.BrewingSpent(base)>23 and M.AERank(id,base)>0 then
  local width=(id==6498 or id==35064 or id==7131 or id==30884 or id==29736) and 2 or 1
  local next=M.MaskSet(base,Shift(i),width,M.AERank(id,base)-1)
  if M.AEValid(next) then base=next end
 end
end end end
assert(M.BrewingSpent(base)==23)
local good=add(base,6026)
assert(M.AEValid(good));assert(M.TESpent(good)==M.TESpent(base)+1)
M.level=56;assert(not M.AEValid(good));M.level=57;assert(M.AEValid(good));M.level=80
assert(not M.AEValid(add(good,12645,0)));assert(not M.AEValid(add(good,6014,0)));assert(not M.AEValid(add(good,4005,0)))
M.specs[1]=0;assert(not M.AEValid(good));M.specs[1]=1
M.teBudget=M.TESpent(good)-1;assert(not M.AEValid(good));M.teBudget=100
assert(not M.AEValid(M.MaskSet(good,118,1,1)))
local less=base
for id,k in pairs(index) do if id~=6014 and id~=12645 and M.AERank(id,base)>0 then
 local width=(id==6498 or id==35064 or id==7131 or id==30884 or id==29736) and 2 or 1
 local m=M.MaskSet(base,Shift(k),width,M.AERank(id,base)-1)
 if M.AEValid(m) and M.BrewingSpent(m)==22 then less=m;break end
end end
assert(M.BrewingSpent(less)==22);assert(not M.AEValid(add(less,6026)))
M.CanEdit=function() return true end;M.aeDirty=true;M.draftAE=good;local got
M.Request=function(cmd,kind) got=cmd;assert(kind=='save') end;M.Save();assert(got=='.wd67save 1 0 '..M.MaskDecimal(good))
print('CONCOCTIONS '..M.MaskDecimal(good));print('LESS '..M.MaskDecimal(add(less,6026)));print('CONCOCTIONS_TE '..M.TESpent(good));print('PASS WD136 exact 118-bit save and prerequisite boundaries')
