-- WD68A: six Class nodes, Voodoo identity and the first TE node.
local M=RebornWD8
-- WD109: four exact 32-bit limbs; numbers only below 2^53.
local MASK_BASE=4294967296
function M.MaskParts(value)
 if type(value)=="number" then
  if value<0 or value>=9007199254740992 or value~=math.floor(value) then return nil end
  return value%MASK_BASE,math.floor(value/MASK_BASE),0,0
 end
 if type(value)~="string" or #value==0 or #value>39 or not value:match("^%d+$") then return nil end
 local words={0,0,0,0}
 for i=1,#value do
  local carry=tonumber(value:sub(i,i))
  for j=1,4 do local n=words[j]*10+carry;words[j]=n%MASK_BASE;carry=math.floor(n/MASK_BASE) end
  if carry~=0 then return nil end
 end
 return unpack(words)
end
local function MaskFromParts(lo,hi,w2,w3)
 if w2==0 and w3==0 and hi<2097152 then return hi*MASK_BASE+lo end
 local words={lo,hi,w2,w3};local out=""
 repeat
  local carry=0
  for j=4,1,-1 do local n=carry*MASK_BASE+words[j];words[j]=math.floor(n/10);carry=n%10 end
  out=tostring(carry)..out
 until words[1]==0 and words[2]==0 and words[3]==0 and words[4]==0
 return out
end
function M.MaskParse(value)
 local a,b,c,d=M.MaskParts(value);if a==nil then return nil end
 return MaskFromParts(a,b,c,d)
end
function M.MaskDecimal(value)
 local parsed=M.MaskParse(value);if parsed==nil then return nil end
 return type(parsed)=="number" and string.format("%.0f",parsed) or parsed
end
function M.MaskEqual(a,b) local left=M.MaskDecimal(a);return left~=nil and left==M.MaskDecimal(b) end
function M.MaskFits(value,bits)
 local words={M.MaskParts(value)};if not words[1] or bits<0 or bits>128 then return false end
 for j=1,4 do local allowed=math.max(0,math.min(32,bits-(j-1)*32));if words[j]>=2^allowed then return false end end
 return true
end
function M.MaskRank(value,shift,width)
 local words={M.MaskParts(value)};if not words[1] or shift<0 or width<1 or shift+width>128 then return 0 end
 local result=0
 for bit=0,width-1 do local pos=shift+bit;result=result+(math.floor(words[math.floor(pos/32)+1]/2^(pos%32))%2)*2^bit end
 return result
end
function M.MaskSet(value,shift,width,rank)
 local words={M.MaskParts(value)}
 if not words[1] or shift<0 or width<1 or shift+width>128 or rank<0 or rank>=2^width or rank~=math.floor(rank) then return nil end
 for bit=0,width-1 do
  local pos=shift+bit;local j=math.floor(pos/32)+1;local power=2^(pos%32)
  words[j]=words[j]+(math.floor(rank/2^bit)%2-math.floor(words[j]/power)%2)*power
 end
 return MaskFromParts(unpack(words))
end

local index={[29744]=0,[6054]=1,[6047]=2,[7092]=3,[29309]=4,[29301]=5,[4004]=6,[31154]=7,[31344]=8,[31340]=9,[7157]=10,[6058]=11,[29928]=12,[30973]=13,[4533]=14,[31341]=15,[6045]=16,[31347]=17,[31348]=18,[6644]=19,[6046]=20,[6062]=21,[30889]=22,[31343]=23,[6053]=24,[31350]=25,[5333]=26,[6059]=27,[5332]=28,[31345]=29,[6007]=30,[11532]=31,[4532]=32,[29121]=33,[31346]=34,[7100]=35,[29768]=36,[6057]=37,[30596]=38,[7088]=39,[30147]=40,[4132]=41,[31349]=42,[29929]=43,[6055]=44,[11133]=45,[7033]=46,[6051]=47,[6048]=48,[7131]=49,[30884]=50,[29736]=51,[9311]=52,[5055]=53,[4715]=54,[7129]=55,[7948]=56,[31137]=57,[30891]=59,[6030]=60,[7132]=61,[29753]=62,[6381]=63,[12048]=64,[11323]=65,[31118]=66,[12264]=67,[6042]=68,[9347]=69,[29306]=70,[6031]=71,[6525]=72,[12525]=73,[4005]=74,[12645]=75,[12646]=76,[6498]=77,[29303]=78,[6020]=79,[29737]=80,[7128]=81,[35065]=82,[35064]=83,[35068]=84,[29738]=85,[30888]=86,[35051]=87,[6645]=88,[4112]=89,[7130]=90,[6021]=91,[6014]=92,[30823]=93,[6022]=94,[6013]=95,[6016]=96,[6009]=97,[4733]=98,[6015]=99,[29310]=100,[29754]=101,[30333]=102,[6027]=103,[13133]=104,[6026]=105,[29740]=106}
local maximum={[29744]=1,[6054]=1,[6047]=2,[7092]=1,[29309]=1,[29301]=1,[4004]=1,[31154]=1,[31344]=1,[31340]=1,[7157]=1,[6058]=1,[29928]=1,[30973]=3,[4533]=1,[31341]=1,[6045]=1,[31347]=1,[31348]=1,[6644]=1,[6046]=1,[6062]=2,[30889]=1,[31343]=1,[6053]=1,[31350]=1,[5333]=1,[6059]=1,[5332]=1,[31345]=2,[6007]=2,[11532]=1,[4532]=1,[29121]=1,[31346]=1,[7100]=1,[29768]=1,[6057]=1,[30596]=1,[7088]=2,[30147]=1,[4132]=1,[31349]=1,[29929]=1,[6055]=1,[11133]=1,[7033]=1,[6051]=1,[6048]=1,[7131]=2,[30884]=2,[29736]=2,[9311]=1,[5055]=1,[4715]=1,[7129]=1,[7948]=1,[31137]=1,[30891]=1,[6030]=1,[7132]=1,[29753]=1,[6381]=1,[12048]=1,[11323]=1,[31118]=1,[12264]=1,[6042]=1,[9347]=2,[29306]=1,[6031]=1,[6525]=1,[12525]=1,[4005]=1,[12645]=1,[12646]=1,[6498]=2,[29303]=1,[6020]=1,[29737]=1,[7128]=1,[35065]=1,[35064]=2,[35068]=1,[29738]=1,[30888]=1,[35051]=1,[6645]=1,[4112]=1,[7130]=1,[6021]=1,[6014]=1,[30823]=1,[6022]=1,[6013]=1,[6016]=1,[6009]=1,[4733]=1,[6015]=1,[29310]=1,[29754]=1,[30333]=1,[6027]=1,[13133]=1,[6026]=1,[29740]=1}
M.aeMasks={0,0,0};M.draftAE=0
local function Changed() if M.changed then M.changed() end;if M.homeChanged then M.homeChanged() end end
local function Message(s) M.message=s;Changed() end
function M.IsAENode(id) return M.modern and index[id]~=nil end
local function Shift(i) return i==83 and 94 or i>=84 and (i+12) or i==77 and 87 or i>=78 and (i+11) or i>=70 and (i+10) or i>=52 and (i+9) or i>=49 and (55+2*(i-49)) or i==39 and 44 or i>=40 and (i+6) or i>=32 and (i+5) or i>=29 and (32+2*(i-29)) or i<3 and i or (i>=22 and i+3 or (i>=14 and i+2 or i+1)) end
function M.AERank(id,mask)
 local i=index[id];if not i then return 0 end
 mask=mask or M.draftAE or 0
 return M.MaskRank(mask,Shift(i),(i==83 or i==77 or i==69 or i==2 or i==13 or i==21 or i==29 or i==30 or i==39 or (i>=49 and i<=51)) and 2 or 1)
end
function M.AESpent(mask)
 local total=0;for id,i in pairs(index) do if i<6 or (i>=39 and i<=41) or (i>=46 and i<=48) or (i>=58 and i<=60) or (i>=63 and i<=73) then total=total+M.AERank(id,mask) end end;return total
end
function M.TEFoundation(mask) return M.AERank(31154,mask)+M.AERank(31344,mask)+M.AERank(31340,mask)+M.AERank(7157,mask)+M.AERank(6058,mask)+M.AERank(29928,mask)+M.AERank(30973,mask)+M.AERank(31345,mask) end
function M.BrewingFoundation(mask) return M.AERank(7128,mask)+ M.AERank(7131,mask)+M.AERank(30884,mask)+M.AERank(29736,mask)+M.AERank(5055,mask)+M.AERank(7129,mask) end
function M.BrewingSpent(mask) return M.AERank(29740,mask)+M.AERank(6026,mask)+M.AERank(30333,mask)+M.AERank(6027,mask)+M.AERank(6015,mask)+M.AERank(29310,mask)+M.AERank(29754,mask)+M.AERank(6016,mask)+M.AERank(6009,mask)+ M.AERank(30823,mask)+M.AERank(6022,mask)+M.AERank(6013,mask)+ M.AERank(6021,mask)+M.AERank(6014,mask)+ M.AERank(6645,mask)+M.AERank(4112,mask)+M.AERank(7130,mask)+ M.AERank(35051,mask)+M.AERank(30888,mask)+M.AERank(29738,mask)+ M.AERank(35065,mask)+M.AERank(35064,mask)+M.AERank(35068,mask)+ M.AERank(7128,mask)+ M.AERank(6020,mask)+M.AERank(29737,mask)+ M.AERank(6498,mask)+M.AERank(29303,mask)+ M.AERank(7131,mask)+M.AERank(30884,mask)+M.AERank(29736,mask)+M.AERank(5055,mask)+M.AERank(7129,mask)+M.AERank(7948,mask)+M.AERank(31137,mask)+M.AERank(7132,mask)+M.AERank(29753,mask) end
function M.TESpent(mask) return M.BrewingSpent(mask)+ M.AERank(31154,mask)+M.AERank(31344,mask)+M.AERank(31340,mask)+M.AERank(7157,mask)+M.AERank(6058,mask)+M.AERank(29928,mask)+M.AERank(30973,mask)+M.AERank(31341,mask)+M.AERank(6045,mask)+M.AERank(31347,mask)+M.AERank(31348,mask)+M.AERank(6644,mask)+M.AERank(6046,mask)+M.AERank(6062,mask)+M.AERank(30889,mask)+M.AERank(31343,mask)+M.AERank(6053,mask)+M.AERank(31350,mask)+M.AERank(5333,mask)+M.AERank(6059,mask)+M.AERank(5332,mask)+M.AERank(31345,mask)+M.AERank(6007,mask)+M.AERank(29121,mask)+M.AERank(31346,mask)+M.AERank(7100,mask)+M.AERank(29768,mask)+M.AERank(6057,mask)+M.AERank(30596,mask)+M.AERank(31349,mask)+M.AERank(29929,mask)+M.AERank(6055,mask) end
function M.AEValid(mask)
 if M.MaskRank(mask,67,1)>0 or not M.MaskFits(mask,119) or (M.AERank(35064,mask)>2 or M.AERank(6498,mask)>2 or M.AERank(9347,mask)>2 or M.AERank(6047,mask)>2 or M.AERank(6062,mask)>2 or M.AERank(31345,mask)>2 or M.AERank(6007,mask)>2 or M.AERank(7088,mask)>2 or M.AERank(7131,mask)>2 or M.AERank(30884,mask)>2 or M.AERank(29736,mask)>2) then return false,"加点数据无效，请刷新方案" end
 if M.TESpent(mask)>(M.teBudget or 0) then return false,"专精点数TE不足；AE不能代替TE" end
 local function rank(id) return M.AERank(id,mask) end
 if (rank(30333)>0 or rank(6027)>0) and (M.level<57 or M.specs[M.slot+1]~=1 or rank(4005)==0 or M.BrewingSpent(mask)-rank(29740)-rank(30333)-rank(6027)<23) then return false,"需要57级、大锅及23点既有酿造TE" end
 if rank(30333)>0 and rank(6014)==0 and rank(6020)==0 and rank(29737)==0 then return false,"需要相连酿造前置" end
 if rank(6027)>0 and rank(30333)==0 then return false,"需要巫毒大锅" end
 if (rank(6015)>0 or rank(29310)>0 or rank(29754)>0) and (M.level<10 or M.specs[M.slot+1]~=1 or rank(4005)==0 or M.BrewingFoundation(mask)<8) then return false,"需要酿造方案、大锅和8基础TE" end
 if rank(6015)>0 and (M.level<16 or rank(7948)==0 or rank(29738)==0) then return false,"需要16级、鱼油和蛙骨" end
 if rank(29310)>0 and rank(6009)==0 and rank(7132)==0 and rank(29753)==0 then return false,"需要相连酿造前置" end
 if rank(29754)>0 and (rank(29310)==0 or M.BrewingSpent(mask)-rank(29740)-rank(29754)<23) then return false,"需要野兽之血及23点既有酿造TE" end
 if rank(29740)>0 and (M.level<59 or M.specs[M.slot+1]~=1 or rank(6026)==0) then return false,"需要59级、酿造方案和调制大师" end
 if rank(6026)>0 and (M.level<57 or M.specs[M.slot+1]~=1 or rank(4005)==0 or rank(12645)==0 or rank(6014)==0 or M.BrewingSpent(mask)-rank(29740)-rank(6026)-rank(30333)-rank(6027)-rank(29754)<23) then return false,"需要57级、大锅、丛林蘑菇、森金之仪和23点前层酿造TE" end
 if rank(13133)>0 and (M.level<50 or rank(4733)==0 or M.specs[M.slot+1]~=1) then return false,"需要50级、魔精波动及酿造方案" end
 if rank(4733)>0 and (M.level<40 or rank(4715)==0 or M.specs[M.slot+1]~=1) then return false,"需要40级、洛阿祝福及酿造方案" end
 if (rank(6016)>0 or rank(6009)>0) and (M.level<10 or rank(4005)==0 or rank(12645)==0 or M.BrewingFoundation(mask)<8) then return false,"需要大锅、蘑菇和8基础酿造TE" end
 if rank(6016)>0 and rank(29738)==0 then return false,"需要蛙骨配料" end
 if rank(6009)>0 and rank(6021)==0 then return false,"需要血蓟配料" end
 if (rank(30823)>0 or rank(6022)>0 or rank(6013)>0) and (M.level<10 or rank(4005)==0 or M.BrewingFoundation(mask)<8) then return false,"需要大锅和8点基础酿造TE" end
 if rank(30823)>0 and (M.level<29 or (rank(7128)==0 and rank(29303)==0)) then return false,"魔精光束需要29级及泼洒或药水增效" end
 if rank(6022)>0 and rank(7128)==0 then return false,"需要泼洒药水" end
 if rank(6013)>0 and ((rank(29303)==0 and rank(29738)==0) or rank(7948)>0) then return false,"需要药水增效或蛙骨，并与灵魂之触互斥" end
 if (rank(6021)>0 or rank(6014)>0) and (M.level<10 or rank(4005)==0 or M.BrewingFoundation(mask)<8) then return false,"需要大锅酿造及8点基础酿造TE" end
 if rank(4112)>0 and rank(7130)>0 then return false,"两种香料互斥" end
 if (rank(6645)>0 or rank(4112)>0 or rank(7130)>0) and rank(4005)==0 then return false,"需要大锅酿造" end
 if (rank(4112)>0 or rank(7130)>0) and M.BrewingFoundation(mask)<8 then return false,"需先投入8点基础酿造TE" end
 if M.AESpent(mask)>(M.aeBudget or 0) then return false,"通用点数AE不足；TE不能代替AE" end
 if rank(6054)>0 and rank(29744)==0 and rank(29301)==0 then return false,"灵性传统需要治疗守卫或拟态守卫" end
 if (rank(6047)>0 or rank(7092)>0) and rank(6054)==0 then return false,"睿智／寻觅者需要灵性传统" end
 if rank(29309)>0 and M.level<16 then return false,"净化神像需要角色等级16" end
 if rank(29309)>0 and rank(6047)==0 and rank(7092)==0 then return false,"净化神像需要睿智或寻觅者" end
 if (rank(4004)>0 or rank(4533)>0 or rank(11532)>0 or rank(4532)>0 or rank(11133)>0 or M.TESpent(mask)-M.BrewingSpent(mask)>0) and M.specs[M.slot+1]~=0 then return false,"本方案需要绑定巫毒专精" end
 if (M.BrewingSpent(mask)>0 or rank(9311)>0 or rank(4715)>0) and M.specs[M.slot+1]~=1 then return false,"本方案需要绑定酿造专精" end
 if (rank(4005)>0 or rank(12645)>0 or rank(12646)>0) and M.specs[M.slot+1]~=1 then return false,"本方案需要绑定酿造专精" end
 if (rank(12645)>0 or rank(12646)>0) and rank(4005)==0 and rank(29744)==0 then return false,"需要大锅酿造或治疗守卫" end
 if (rank(6498)>0 or rank(29303)>0 or rank(6020)>0 or rank(29737)>0) and M.BrewingFoundation(mask)<8 then return false,"需要先投入8点基础酿造TE；同层不计前置" end
 if rank(6020)>0 and rank(29737)>0 then return false,"丛林绽放与丛林医师二选一" end
 if rank(7128)>0 and M.level<17 then return false,"泼洒药水需要17级" end
 if (rank(35065)>0 or rank(35064)>0 or rank(35068)>0 or rank(29738)>0 or rank(30888)>0 or rank(35051)>0) and M.BrewingFoundation(mask)<8 then return false,"需先投入8点基础酿造TE" end
 if rank(12646)>0 and M.level<14 then return false,"药水投掷需要14级" end
 if rank(9311)>0 and M.level<20 then return false,"灵魂医者需要等级20" end
 if rank(4715)>0 and M.level<30 then return false,"洛阿祝福需要等级30" end
 if (rank(7948)>0 or rank(31137)>0) and M.BrewingFoundation(mask)<8 then return false,"需要先投入8点基础酿造TE；这两个节点不能互相凑前置" end
 if rank(7948)>0 and M.level<16 then return false,"灵魂之触需要16级" end
 if rank(31137)>0 and M.level<30 then return false,"丛林秘法需要30级" end
 if (rank(5113)>0 or rank(30891)>0) and M.AESpent(mask)-rank(30147)-rank(4132)-rank(7033)-rank(6051)-rank(6048)-rank(5113)-rank(30891)-rank(6381)-rank(12048)-rank(11323)-rank(12264)-rank(6042)-rank(9347)-rank(29306)-rank(6031)-rank(6525)-rank(12525)<9 then return false,"先投入9点基础AE；同层不能互相凑点" end
 if rank(5113)>0 and M.level<58 then return false,"诅咒雕像需要58级" end
 if rank(30891)>0 and M.level<30 then return false,"穆厄扎拉之触需要30级" end
 if (rank(7132)>0 or rank(29753)>0) and M.level<31 then return false,"佳酿需要31级" end
 if rank(7132)>0 and rank(29753)>0 then return false,"怒气佳酿与奥术佳酿二选一" end
 if (rank(7132)>0 or rank(29753)>0) and M.BrewingFoundation(mask)<8 then return false,"先投入8点基础酿造TE" end
 if (rank(6031)>0 or rank(6525)>0 or rank(12525)>0) and M.level<26 then return false,"蛙变术及祝福需要26级" end
 if (rank(6525)>0 or rank(12525)>0) and rank(6031)==0 then return false,"需先学习蛙变术" end
 if rank(6525)>0 and rank(12525)>0 then return false,"贡克与克拉格瓦祝福二选一" end
 if rank(29306)>0 and M.level<30 then return false,"化蛇需要角色等级30" end
 if (rank(6381)>0 or rank(12048)>0 or rank(11323)>0 or rank(12264)>0 or rank(6042)>0 or rank(9347)>0 or rank(29306)>0 or rank(6031)>0 or rank(6525)>0 or rank(12525)>0) and rank(29744)+rank(6054)+rank(6047)+rank(7092)+rank(29309)+rank(29301)+rank(7088)+rank(6030)+rank(31118)<9 then return false,"先投入9点基础AE；同层不能互相凑点" end
 if rank(12048)>0 and rank(6048)>0 then return false,"希里克的祝福与黑暗魔精二选一" end
 if rank(31154)>0 then
  if M.level<11 then return false,"暗影傀儡需要角色等级11" end
  if rank(29301)==0 and rank(4004)==0 then return false,"暗影傀儡缺少前置：拟态守卫和傀儡师之线" end
  if rank(29301)==0 then return false,"暗影傀儡缺少前置：拟态守卫（左侧通用树最上排中间）" end
  if rank(4004)==0 then return false,"暗影傀儡缺少前置：傀儡师之线（巫毒最右竖列顶部，免费）" end
  if (M.teBudget or 0)<1 then return false,"暗影傀儡需要1点TE" end
 end
 if (rank(30147)>0 or rank(4132)>0 or rank(7033)>0 or rank(6051)>0 or rank(6048)>0) and M.AESpent(mask)-rank(30147)-rank(4132)-rank(7033)-rank(6051)-rank(6048)-rank(5113)-rank(30891)-rank(6381)-rank(12048)-rank(11323)-rank(12264)-rank(6042)-rank(9347)-rank(29306)-rank(6031)-rank(6525)-rank(12525)<9 then return false,"需要先投入9 AE；同层节点不能互相凑前置" end
 if rank(6051)>0 and M.level<28 then return false,"迅捷神像需要等级28" end
 if rank(6048)>0 and M.level<32 then return false,"黑暗魔精需要等级32" end
 if rank(30147)>0 and M.level<28 then return false,"炼金强化需要等级28" end
 if rank(11133)>0 and M.level<50 then return false,"妖火进阶需要等级50" end
 if rank(31349)>0 and (M.level<59 or M.TEFoundation(mask)<8) then return false,"战争魔像需要59级与8点基础TE" end
 if rank(6055)>0 and M.level<59 then return false,"灵魂提线需要59级" end
 if (rank(29929)>0 or rank(6055)>0) and (M.level<57 or M.TESpent(mask)-rank(31346)-rank(7100)-rank(29768)-rank(6057)-rank(29929)-rank(6055)<23) then return false,"需要23点前层TE，高阶节点不能互相凑点" end
 if rank(30596)>0 and (M.level<27 or M.TEFoundation(mask)<8) then return false,"傀儡师之握需要27级及8点基础巫毒TE" end
 if rank(4532)>0 and M.level<30 then return false,"涌动巫毒需要等级30" end
 if rank(29121)>0 and M.level<33 then return false,"恶毒诅咒需要等级33" end
 if rank(6057)>0 and rank(29768)==0 then return false,"力量的代价需要邦桑迪之声" end
 if (rank(29768)>0 or rank(6057)>0) and (M.level<57 or M.TESpent(mask)-rank(31346)-rank(7100)-rank(29768)-rank(6057)-rank(29929)-rank(6055)<23) then return false,"需要57级及23点前层巫毒TE" end
 if rank(7100)>0 and M.TESpent(mask)-rank(31346)-rank(7100)-rank(29768)-rank(6057)-rank(29929)-rank(6055)<23 then return false,"黑暗雕像需要先投入23 TE，不能用自身凑前置" end
 if rank(31346)>0 and M.TESpent(mask)-rank(31346)-rank(7100)-rank(29768)-rank(6057)-rank(29929)-rank(6055)<23 then return false,"彼界需要先投入23 TE，不能用自身凑前置" end
 if rank(11532)>0 and M.level<40 then return false,"巫毒灵魂需要角色等级40" end
 if rank(4533)>0 and M.level<20 then return false,"巫毒之力需要角色等级20" end
 if rank(31341)>0 and rank(6045)>0 then return false,"空灵之魂与这就是巫毒只能选择一个" end
 if (rank(31341)>0 or rank(6045)>0 or rank(31347)>0 or rank(31348)>0 or rank(6644)>0 or rank(6046)>0 or rank(6062)>0 or rank(30889)>0 or rank(31343)>0 or rank(6053)>0 or rank(31350)>0 or rank(5333)>0 or rank(6059)>0 or rank(5332)>0 or rank(6007)>0 or rank(29121)>0) and M.TEFoundation(mask)<8 then return false,"需要先在已开放的基础巫毒节点投入8 TE；高阶节点不能互相凑前置" end
 if rank(29928)>0 and M.level<15 then return false,"邪恶巫毒需要角色等级15" end
 if rank(7157)>0 and M.level<15 then return false,"妖火需要角色等级15" end
 if M.level<10 and not M.MaskEqual(mask,0) then return false,"天赋加点需要角色等级10" end
 return true
end
function M.AEOnReply(operation,confirmed)
 if not M.modern then return end
 if confirmed or not M.aeDirty then M.draftAE=M.aeMasks[M.slot+1] or 0 end
 M.aeDirty=not M.MaskEqual(M.draftAE,M.aeMasks[M.slot+1] or 0);M.dirty=M.aeDirty
end
local oldReset=M.ResetDraft
function M.ResetDraft(slot,view)
 oldReset(slot,view)
 if M.modern then M.draftAE=M.aeMasks[slot+1] or 0;M.aeDirty=false;M.dirty=false;Changed() end
end
local oldSpec=M.SetSpec
function M.SetSpec(key)
 local result=oldSpec(key)
 if M.modern then M.dirty=M.aeDirty;Changed() end
 return result
end
local oldDrafts=M.HasDrafts
function M.HasDrafts() if M.modern then return M.aeDirty or false end;return oldDrafts() end
-- WD69A: one informational popup; never allocates, resets or submits points.
local function AllocationError(id,mask,reason)
 Message(reason or "加点条件不满足")
 local text=reason or "加点条件不满足"
 if id==31154 and M.AERank(31154,mask)>0 then
  local missing={}
  if M.AERank(29301,mask)==0 then missing[#missing+1]="拟态守卫：左侧通用树最上排中间，1 AE。\nMimic Ward: top-middle of Class tree, 1 AE." end
  if M.AERank(4004,mask)==0 then missing[#missing+1]="傀儡师之线：巫毒最右竖列顶部，免费。\nPuppeteer's Threads: top of far-right Voodoo column, free." end
  if #missing>0 then text=text.."\n\n"..table.concat(missing,"\n\n").."\n\n不需要点满通用树；选好前置后再点暗影傀儡，一起保存。\nThe full Class tree is NOT required. Select prerequisites, then Shadow Puppets, and save together." end
 end
 if StaticPopupDialogs and StaticPopup_Show then
  StaticPopupDialogs.REBORN_WD69_REQUIREMENTS={text="|cffff5555无法加点 / Cannot allocate|r\n\n%s",button1="知道了 / OK",timeout=0,whileDead=true,hideOnEscape=true,preferredIndex=3}
  StaticPopup_Show("REBORN_WD69_REQUIREMENTS",text)
 end
end
local oldSet=M.SetNode
function M.SetNode(id,rank)
 if not M.modern then return oldSet(id,rank) end
 local i=index[id]
 if not i or not M.CanEdit() or M.pending then return end
 if type(rank)~="number" or rank~=math.floor(rank) or rank<0 or rank>maximum[id] then return end
 if rank<M.AERank(id,M.aeMasks[M.slot+1]) then Message("已保存点数需要付费重置整个方案");return end
 local mask=M.MaskSet(M.draftAE,Shift(i),(i==83 or i==77 or i==69 or i==2 or i==13 or i==21 or i==29 or i==30 or i==39 or (i>=49 and i<=51)) and 2 or 1,rank)
 local valid,reason=M.AEValid(mask)
 if not valid then AllocationError(id,mask,reason);return end
 M.draftAE=mask;M.aeDirty=not M.MaskEqual(mask,M.aeMasks[M.slot+1]);M.dirty=M.aeDirty
 Message("草稿已更改，请点击保存更改")
end
local oldSave=M.Save
function M.Save()
 if not M.modern then return oldSave() end
 if not M.CanEdit() or not M.aeDirty or M.pending then return end
 M.Request(".wd67save "..M.revision.." "..M.slot.." "..M.MaskDecimal(M.draftAE),"save")
end
function M.JoinAE()
 if not M.loaded or M.pending or M.modern or InCombatLockdown() then return end
 M.Request(".wd67join "..M.revision,"join")
end
-- WD67B: benefits first; bilingual names, current/next rank, limits and prerequisites.
local details={
 [29744]={zh="治疗守卫",en="Healing Ward",level=10,early="10",kind="主动召唤 / Active summon",
  effects={{"学会治疗守卫：每2.5秒治疗30码内最多8名自己或队伍/团队友方，优先受伤目标。治疗量随等级成长，获得18.5%治疗加成和8%远程攻击强度加成。","Learn Healing Ward: every 2.5 seconds, heals up to 8 friendly party/raid members (including you) within 30 yards, prioritizing injured targets. Healing scales with level, 18.5% bonus healing and 8% ranged attack power."}},
  limit={"与其他基础守卫共用一个名额；召唤物到期或被替换后停止治疗。","Shares one basic Ward slot. Healing ends when the summon expires or is replaced."},
  path={"起始节点，无技能前置。","Starting node; no ability prerequisite."}},
 [6054]={zh="灵性传统",en="Spiritual Traditions",level=12,early="12",kind="被动 / Passive",
  effects={{"受到伤害时的施法打退幅度降低70%；施法耗蓝后仍保留40%的自然精神回蓝。","Reduces casting pushback from damage by 70%. Allows 40% of your normal Spirit-based mana regeneration to continue after spending mana on spells."}},
  limit={"不免疫打断或沉默；不是每次施法返还40%法力。固定每5秒回蓝仍按原规则处理。","Does not grant interrupt or silence immunity, and does not refund 40% of spell costs. Flat mana per 5 seconds follows its normal rules."},
  path={"治疗守卫，或拟态守卫。","Healing Ward OR Mimic Ward."}},
 [6047]={zh="睿智",en="Wizened",level=10,early="14 / 16",kind="被动 / Passive",
  effects={
   {"最大法力提高5%，标准法术与技能消耗降低3%。","Increases maximum mana by 5% and reduces standard spell and ability costs by 3%."},
   {"最大法力提高10%，标准法术与技能消耗降低6%。这是总收益，不与1级再次叠加。","Increases maximum mana by 10% and reduces standard spell and ability costs by 6%. These are total bonuses, not added to rank 1."}},
  limit={"提高法力上限不会立即回满法力；自定义扣费或清空资源的技能沿用其自身规则。","Increasing maximum mana does not refill it. Custom costs and resource-draining abilities retain their own rules."},
  path={"灵性传统；原图另一条连接为天选者，本批尚未开放。","Spiritual Traditions. The authored alternative, Chosen One, is not open in this batch."}},
 [7092]={zh="寻觅者",en="Seeker",level=10,early="14",kind="被动 / Passive",
  effects={{"本人的守卫、神像及雕像召唤法术，标准法力消耗降低20%。","Reduces the standard mana cost of your Ward, Idol and Effigy summoning spells by 20%."}},
  limit={"一键放置分别计算每个召唤法术；回收按实际支付的法力返还，不额外返还节省的部分。","One-key placement calculates each summon separately. Recall refunds mana actually paid, not mana saved by this passive."},
  path={"灵性传统。","Spiritual Traditions."}},
 [29309]={zh="净化神像",en="Cleansing Idol",level=16,early="16",kind="主动召唤 / Active summon",
  effects={{"学会净化神像，持续60秒。放置3秒后首次净化，此后每3秒为30码内视线可达的自己和队伍成员，各驱散1个疾病和1个中毒效果。","Learn Cleansing Idol, lasting 60 seconds. First cleanses after 3 seconds, then every 3 seconds removes 1 disease and 1 poison from you and party members within 30 yards and line of sight."}},
  limit={"与其他神像共用一个名额；不驱散诅咒或魔法效果。","Shares one Idol slot; does not dispel curses or magic effects."},
  path={"睿智至少1级，或寻觅者至少1级。","At least rank 1 of Wizened OR Seeker."}}
}
details[29301]={zh="拟态守卫",en="Mimic Ward",level=10,early="10",kind="主动召唤 / Active summon",
 effects={{"学会拟态守卫：持续12秒，复制你的恶意之怒和洛阿佳酿，60秒冷却。","Learn Mimic Ward: repeats your Malefic Wrath and Loa's Brew for 12 seconds; 60-second cooldown."}},
 limit={"独立于普通守卫；未点天选之人时保留一个拟态守卫，复制目标需在守卫40码内且视线可达。","Independent of the basic Ward slot; one Mimic, two with Chosen One. Mirror targets must be within 40 yards of the Ward and in line of sight."},path={"通用树起始节点。","Class starting node."}}
details[4004]={zh="傀儡师之线",en="Puppeteer's Threads",level=10,early="10",kind="巫毒被动 / Voodoo passive",
 effects={{"直接伤害技能留下10秒丝线，储存你造成伤害的15%，结束时一次结算。","Direct damaging abilities apply 10-second Threads, storing 15% of your damage and releasing it at the end."}},
 limit={"周期伤害不能独自建立丝线，已有丝线时可储存；爆发不再次储存。","Periodic damage requires existing Threads; released damage cannot store itself."},path={"本方案绑定巫毒；0 AE / 0 TE。","This build must be bound to Voodoo; 0 AE / 0 TE."}}
details[31154]={zh="暗影傀儡",en="Shadow Puppets",level=11,early="11",kind="主动伤害 / Active damage",
 effects={{"解锁暗影傀儡：每0.75秒造成一次暗影伤害，持续3秒；每跳额外获得22%暗影法强加成并收集灵魂。18秒冷却，技能等级随角色升级。","Unlock Shadow Puppets: Shadow damage every 0.75 seconds for 3 seconds, adding 22% Shadow spell power per tick and collecting Spirits. 18-second cooldown; spell ranks grow with character level."}},
 limit={"1点TE解锁整条技能等级链；不是每个技能等级重复消耗TE。","One TE unlocks the spell rank chain; later spell ranks do not cost additional TE."},path={"同时需要傀儡师之线和拟态守卫。","Requires BOTH Puppeteer's Threads and Mimic Ward."}}
for _,id in ipairs({31344,31340,7157}) do
 local spell=id==31344 and 9003610 or (id==31340 and 9003611 or 9003500)
 local zh=id==31344 and "暴击几率提高4个百分点；巫毒攻击法术威胁降低20%。" or (id==31340 and "恶意妖术周期伤害提高15%；诅咒持续时间增加2秒，仍遵守PVP上限和递减。" or "造成火焰伤害；火焰法强高于自然法强时加55%火焰法强，否则加55%自然法强及50%精神。")
 local en=id==31344 and "Adds 4 percentage points of critical strike chance; reduces Voodoo attack spell threat by 20%." or (id==31340 and "Hex of Malice periodic damage +15%; Jinx duration +2 sec, retaining PvP caps and diminishing returns." or "Deals Fire damage; adds 55% Fire spell power if higher than Nature, otherwise 55% Nature spell power and 50% Spirit.")
 details[id]={zh=id==31344 and "荆棘谷风格" or (id==31340 and "扎拉赞恩的恶意" or "妖火"),
  en=id==31344 and "Stranglethorn Style" or (id==31340 and "Zalazane's Malice" or "Hexfire"),
  level=id==7157 and 15 or 10,early=id==7157 and "15" or "11",kind=id==7157 and "主动伤害 / Active damage" or "被动 / Passive",
  effects={{zh,en}},limit={"仅当前激活且已保存的方案生效；1 TE解锁，后续技能等级免费。","Only applies in the saved active build. One TE unlocks the talent; later spell ranks are free."},
  path={"本方案绑定巫毒，无其他技能前置。","Build bound to Voodoo; no other ability prerequisites."}}
end
details[6058]={zh="黑暗魔法",en="Dark Magic",level=10,early="11",kind="被动 / Passive",
 effects={{"恶意之怒和邪恶巫毒的施法时间减少0.5秒。","Reduces the cast time of Malefic Wrath and Bad Juju by 0.5 sec."}},
 limit={"只匹配这两类技能；不影响其他施法，也不直接提高伤害。","Only affects these two spell families; no other casts or direct damage bonus."},
 path={"巫毒方案，无额外技能前置；1 TE。","Voodoo build, no additional ability prerequisite; 1 TE."}}
details[29928]={zh="邪恶巫毒",en="Bad Juju",level=15,early="15",kind="主动伤害 / Active damage",
 effects={{"向目标施放暗影伤害；对已被恶意妖术影响的目标命中后，附加治疗效果降低。","Deals Shadow damage; a hit on a target affected by Hex of Malice also reduces healing received."}},
 limit={"1 TE解锁；22/28/34/40/46/52/58/60级自动补技能等级，不额外收费。沿用已有伤害和减疗实现。","One TE unlocks all spell ranks at 15/22/28/34/40/46/52/58/60, with no additional point cost. Retains existing damage and healing-reduction mechanics."},
 path={"巫毒方案，无额外技能前置。图中的连接线不等于强制前置。","Voodoo build, no additional ability prerequisite. Graph connections are not mandatory prerequisites."}}
details[7088]={zh="巫毒注射",en="Juju Injection",level=10,early="10 / 12",kind="通用被动 / Class passive",
 effects={{"敏捷和智力提高5%。","Agility and Intellect +5%."},{"敏捷和智力提高10%。","Agility and Intellect +10%."}},
 limit={"每级1 AE，只保留最高级；保存当前方案后生效。","One AE per rank; highest rank only; active saved build."},path={"通用树，无额外前置。","Class tree, no additional prerequisite."}}
details[30147]={zh="炼金强化",en="Alchemical Enhancement",level=28,early="28",kind="通用被动 / Class passive",
 effects={{"施法及近战/远程攻击急速提高5%。","Spell and melee/ranged haste +5%."}},limit={"花费1 AE；28级，先投入9点基础通用AE。","One AE; level28, nine prior Class AE."},path={"本节点与迅捷召唤不能互相凑9 AE。","This and Hastened cannot bootstrap each other's nine AE."}}
details[4132]={zh="迅捷召唤",en="Hastened",level=10,early="9 AE后",kind="通用被动 / Class passive",
 effects={{"现有已适配守卫、神像、雕像的冷却缩短25%。","Cooldown of supported Wards, Idols and Effigies -25%."}},limit={"花费1 AE；沿用精确法术族冷却修饰，不影响其他法术。","One AE; existing exact-family modifier, unrelated spells unchanged."},path={"先投入9点基础通用AE；不能用自身或炼金强化凑前置。","Nine prior Class AE, excluding this and Alchemical Enhancement."}}
details[30973]={zh="女巫会之杖",en="Staff of the Coven",level=10,early="11（第一级）",kind="被动 / Passive",
 effects={{"精神提高8%，近战、远程与法术命中率提高2%。","Spirit +8%; melee, ranged and spell hit chance +2%."},{"精神提高16%，近战、远程与法术命中率提高4%。","Spirit +16%; melee, ranged and spell hit chance +4%."},{"精神提高25%，近战、远程与法术命中率提高6%。","Spirit +25%; melee, ranged and spell hit chance +6%."}},
 limit={"每级1 TE，共3级；只保留最高级，不叠加三个等级。","One TE per rank, three ranks; only the highest rank applies."},
 path={"巫毒方案，无额外前置。","Voodoo build, no additional prerequisite."}}
details[4533]={zh="巫毒之力",en="Voodoo Power",level=20,early="20",kind="免费被动 / Free passive",
 effects={{"获得相当于精神50%的法术伤害，以及精神5%的法术命中等级。","Gain spell damage equal to 50% of Spirit and spell hit rating equal to 5% of Spirit."}},
 limit={"20级，0 AE／0 TE；随当前已保存方案生效。命中等级不是命中率。","Level 20, zero AE/TE; active committed build only. Hit rating is not hit chance."},
 path={"巫毒方案，无额外前置。","Voodoo build, no additional prerequisite."}}
details[31341]={zh="这就是巫毒",en="It's Da Voodoo",level=10,early="27",kind="被动 / Passive",
 effects={{"暗影烈焰伤害提高25%。","Increases Shadowflare damage by 25%."}},
 limit={"沿用已移植的精确技能族增伤，不叠加第二份修饰器。","Uses the existing exact-family modifier, without duplicating it."},
 path={"先在巫毒投入8 TE，再花1 TE学习；AE不能代替。","Invest eight Voodoo TE first, then spend one TE; AE cannot substitute."}}
details[6045]={zh="空灵之魂",en="Hollow Spirit",level=10,early="27",kind="被动 / Passive",
 effects={{"暗影烈焰或妖火造成有效伤害后，使存活敌人被法术和武器攻击暴击的几率提高3个百分点，持续12秒。","After Shadowflare or Hexfire deals damage, increases the surviving target's chance to be critically hit by spells and weapons by 3 percentage points for 12 sec."}},
 limit={"与这就是巫毒二选一；刷新持续时间，不叠层。触发它的本次伤害不追溯提高暴击率。","Choose this OR It's Da Voodoo. Refreshes duration without stacking; does not retroactively change the triggering hit."},
 path={"先投入8点巫毒TE，再花1 TE；不能同时选择这就是巫毒。","Invest eight Voodoo TE first, then spend one TE; cannot coexist with It's Da Voodoo."}}
details[31341].limit={"与空灵之魂二选一；只提高暗影烈焰伤害，不影响妖火。","Choose this OR Hollow Spirit; increases Shadowflare damage only, not Hexfire."}
details[31347]={zh="妖术迸发",en="Hexplosion",level=10,early="27",kind="被动 / Passive",
 effects={{"本人攻击造成有效伤害并暴击时，获得20%施法急速，持续6秒；再次触发刷新，不叠层。","Your damaging attack critical strikes grant 20% casting haste for 6 sec; subsequent triggers refresh without stacking."}},
 limit={"只增加施法急速，不增加近战或远程攻击速度；不由治疗、召唤物或完全吸收触发。","Casting haste only, not melee or ranged attack speed; healing, summon damage and fully absorbed hits do not trigger it."},
 path={"先投入8点基础巫毒TE，再花1 TE。","Invest eight TE in the available foundation Voodoo nodes, then spend one TE."}}
details[31348]={zh="恶意滋长",en="Growing Malice",level=10,early="27",kind="被动 / Passive",
 effects={{"自己的恶意妖术造成有效周期伤害后叠1层；下一跳每层伤害提高3%，最多10层即30%。","Your Hex of Malice damaging ticks add a stack; subsequent ticks gain 3% damage per stack, up to ten stacks (30%)."}},
 limit={"不同目标和施法者独立计层；原妖术移除或此被动取消时清理本人层数，不改动原始周期快照。","Stacks are separate per target and caster. Removing your Hex or this passive clears your stacks without changing the original DoT snapshot."},
 path={"先投入8点基础巫毒TE，再花1 TE；战斗中需要自己的恶意妖术。","Invest eight foundation Voodoo TE, then spend one TE; requires your Hex of Malice in combat."}}
details[6644]={zh="恶性蔓延",en="Malignant",level=10,early="27",kind="被动 / Passive",
 effects={{"邪恶巫毒或妖火造成有效伤害后，将受击者身上属于你的恶意妖术蔓延到8码内另一个合法敌人，最多1个。","After Bad Juju or Hexfire deals damage, spreads your Hex of Malice from that target to one eligible enemy within eight yards."}},
 limit={"继承剩余时间、下一跳时间、伤害和暴击快照；不复制他人妖术，不重复初始伤害，不覆盖目标已有的自身妖术。","Preserves remaining duration, tick timing, damage and critical snapshot. Does not copy another caster's Hex, repeat initial damage or overwrite an existing Hex of yours."},
 path={"先投入8点基础巫毒TE，再花1 TE；需要受击者身上有自己的恶意妖术。","Invest eight foundation Voodoo TE, then spend one TE; the struck target must have your Hex of Malice."}}
details[6046]={zh="金度之怒",en="Jin'do's Wrath",level=10,early="27",kind="被动 / Passive",
 effects={{"妖火暴击率提高25个百分点；暴击额外伤害提高25%。","Hexfire critical chance +25 percentage points; its critical bonus damage +25%."}},
 limit={"只影响妖火各技能等级；沿用原生暴击差额倍率，不把150%直接变成187.5%。","Hexfire ranks only; modifies the critical damage bonus, not the whole critical hit."},
 path={"先投入8点基础巫毒TE，再花1 TE。","Invest eight foundation Voodoo TE, then spend one TE."}}
details[6062]={zh="仪式妖术",en="Ritual Hexing",level=10,early="27 / 29",kind="被动 / Passive",
 effects={{"对带有你自己的恶意妖术的敌人，恶意之怒、邪恶巫毒和妖火伤害提高10%。","Malefic Wrath, Bad Juju and Hexfire deal 10% more damage to enemies affected by your Hex of Malice."},{"上述三类技能伤害提高20%；这是总收益，不与1级叠加。","The same three spell families deal 20% more damage; total bonus, not added to rank one."}},
 limit={"不由别人施加的妖术启用；不增加妖术周期伤害、暗影烈焰或召唤物伤害。","Another caster's Hex does not enable it; does not increase Hex ticks, Shadowflare or summon damage."},
 path={"先投入8点基础巫毒TE，每级另花1 TE，共2级。","Invest eight foundation Voodoo TE, then one TE per rank; two ranks."}}
details[30889]={zh="延续恶意",en="Prolonged Malice",level=10,early="27",kind="被动 / Passive",
 effects={{"新施放的恶意妖术基础持续时间增加6秒；已适配的攻击巫毒技能射程增加6码。","New Hex of Malice casts last six seconds longer; supported offensive Voodoo spells gain six yards of range."}},
 limit={"只延长恶意妖术；射程匹配恶意之怒、恶意妖术、邪恶巫毒、妖火、暗影傀儡及四种已移植诅咒。不扩大AOE、蔓延、雕像或守卫半径。","Duration applies only to Hex. Range applies to Wrath, Hex, Bad Juju, Hexfire, Shadow Puppets and the four ported Jinx families; no larger AoE, spread or summon radius."},
 path={"先投入8点基础巫毒TE，再花1 TE；旧妖术和洗点后的剩余时间不倒算。","Invest eight foundation Voodoo TE, then one TE; existing aura time is not retroactively recalculated."}}
details[31343]={zh="充盈巫毒",en="Overflowing Juju",level=10,early="27",kind="被动 / Passive",
 effects={{"恶意之怒、暗影烈焰、邪恶巫毒的法术强度加成提高20%。","Malefic Wrath, Shadowflare and Bad Juju gain 20% increased spell power scaling."}},
 limit={"只提高法强部分，不增加基础伤害、精神或远程攻击强度加成；不是总伤害提高20%。","Spell power contribution only; no increase to base damage, Spirit or ranged attack power."},
 path={"先投入8点基础巫毒TE，再花1 TE。","Invest eight foundation Voodoo TE, then spend one TE."}}
details[6053]={zh="巫毒释放",en="Voodoo Unleashed",level=10,early="27",kind="被动 / Passive",
 effects={{"拟态守卫可以复制邪恶巫毒；本人每次成功施放邪恶巫毒，使暗影傀儡剩余冷却减少3秒。","Mimic Ward can mirror Bad Juju; each successful personal cast reduces Shadow Puppets' remaining cooldown by three seconds."}},
 limit={"采用当前CoA客户端504607的3秒；上游社区代码写5秒，版本差异已记录。复制与触发施法不再次减冷却，读条取消不触发。","Uses the current donor's three seconds; community code uses five. Triggered and mirrored casts do not reduce cooldown again; cancelled casts grant nothing."},
 path={"先投入8点基础巫毒TE，再花1 TE；复制需要自己的拟态守卫存在。","Invest eight foundation Voodoo TE, then spend one TE; mirroring requires your active Mimic Ward."}}
details[31350]={zh="巫毒丝线",en="Voodoo Strings",level=10,early="27",kind="被动 / Passive",
 effects={{"邪恶巫毒命中带有你自己的傀儡师之线的目标后，附加自然周期伤害：每秒造成这次实际伤害的30%。","Bad Juju on a target with your Puppeteer's Threads adds a Nature damage tick each second equal to 30% of its actual hit."}},
 limit={"未命中、全吸收、没有自己的丝线时不触发；单次伤害按整数取整。","Requires a real damaging hit and your own Threads; integer damage rounds down."},
 path={"先投入8点基础巫毒TE，再花1 TE。","Invest eight foundation Voodoo TE, then spend one TE."}}
details[5333]={zh="巫毒之魂",en="Voodoo Spirits",level=10,early="27",kind="被动 / Passive",
 effects={{"妖火命中带有你自己的傀儡师之线的目标时，立即释放已储存伤害并获得1层灵魂。","A damaging Hexfire hit snaps your own Puppeteer's Threads, releases stored damage immediately and grants one Spirit."}},
 limit={"只结算一次；不消费其他巫医的丝线。灵魂沿用现有最多5层、12秒持续时间。","Releases once; never consumes another Witch Doctor's Threads. Spirit uses the existing five-stack, 12-second aura."},
 path={"先投入8点基础巫毒TE，再花1 TE。","Invest eight foundation Voodoo TE, then spend one TE."}}
details[6059]={zh="巫毒心智",en="Voodoo Mind",level=10,early="27",kind="被动 / Passive",
 effects={{"按施放时自身灵魂层数，每层使暗影傀儡跳速提高10%，持续时间延长10%；最多计算5层。","Each Spirit at application gives Shadow Puppets 10% increased tick rate and 10% increased duration, up to five Spirits."}},
 limit={"施放时快照；本次傀儡随后获得的灵魂不再改变本次节奏。","Snapshots at application; Spirits gained by this cast do not change its timings."},
 path={"先投入8点基础巫毒TE，再花1 TE。","Invest eight foundation Voodoo TE, then spend one TE."}}
details[5332]={zh="黑暗洛阿祝福",en="Dark Loa's Blessing",level=10,early="27",kind="被动 / Passive",
 effects={{"100码内自身、小队和团队成员伤害提高3%，与同类团队增伤取强；自身暗影傀儡跳跃间隔与持续时间缩短20%。","Increases damage of self, party and raid members within 100 yards by 3%, using the strongest similar damage buff. Your Shadow Puppets interval and duration are reduced by 20%."}},
 limit={"队友只获得增伤，不获得你的傀儡加速。按照官方DBC的20%时间缩短实现，单独使用时不额外增加跳数。","Recipients gain damage only. Uses the donor's 20% shorter timings; alone it does not add ticks."},
 path={"先投入8点基础巫毒TE，再花1 TE。","Invest eight foundation Voodoo TE, then spend one TE."}}
details[31345]={zh="洛阿之灵",en="Loa Spirits",level=10,early="11",kind="被动 / Passive",
 effects={{"自身有效伤害或治疗有8%概率获得1层灵魂；每层灵魂提高2%精神。","Your effective damage or healing has an 8% chance to grant a Spirit; each Spirit increases Spirit by 2%."},{"自身有效伤害或治疗有15%概率获得1层灵魂；每层灵魂提高4%精神。","Your effective damage or healing has a 15% chance to grant a Spirit; each Spirit increases Spirit by 4%."}},
 limit={"最高5层；纯过量治疗、全吸收伤害、灵魂自身恢复及衍生复制不触发；召唤物不代主人触发。","Up to five Spirits. No procs from pure overheal, fully absorbed damage, Spirit restoration, derived copies or summon-owned events."},
 path={"巫毒基础节点，每级1 TE，无其他技能前置。","Voodoo foundation node; one TE per rank, no other prerequisite."}}
details[6007]={zh="当心巫毒",en="Beware Da Voodoo",level=10,early="27",kind="被动 / Passive",
 effects={{"拟态守卫和灵魂持续时间延长4秒。","Increases Mimic Ward and Spirit duration by 4 seconds."},{"拟态守卫和灵魂持续时间延长8秒。","Increases Mimic Ward and Spirit duration by 8 seconds."}},
 limit={"只影响之后召唤的拟态守卫和之后新施加/刷新的灵魂，不延长其他召唤。","Affects subsequent Mimic summons and newly applied/refreshed Spirits; other summons are unchanged."},
 path={"先投入8点基础巫毒TE，再按等级花1/2 TE。","Invest eight foundation Voodoo TE, then spend one/two TE for the ranks."}}
details[11532]={zh="巫毒灵魂",en="Juju Spirits",level=40,early="40",kind="40级免费被动 / Free level-40 passive",
 effects={{"法术暴击伤害提高100%；每层自身灵魂使邪恶巫毒暴击率提高5个百分点，最高25个百分点。","Increases spell critical damage by 100%; each Spirit adds 5 percentage points to Bad Juju critical chance, up to 25 points."}},
 limit={"不提高近战白字暴击伤害，不增加其他技能暴击率；按当前核心原生效果，常规法术暴击从150%提高至300%。","Does not boost melee critical damage or other spells' critical chance; the native core effect increases a normal 150% spell critical hit to 300%."},
 path={"本方案绑定巫毒且达到40级，免费点选并保存。","Bind this build to Voodoo, reach level 40, then select and save the free node."}}

details[4532]={zh="涌动巫毒（30级）",en="Overflowing Juju",level=30,early="30",kind="免费被动 / Free passive",
 effects={{"暗影傀儡或傀儡师之线造成有效伤害时有15%概率重置邪恶巫毒冷却，并使下一次邪恶巫毒冷却缩短10秒。","Effective Shadow Puppets or Puppeteer's Threads damage has a 15% chance to reset Bad Juju and reduce its next cooldown by 10 seconds."}},
 limit={"减冷却准备持续10秒，下一次完成的邪恶巫毒消耗；取消施法不消耗。不是同名的20%傀儡伤害天赋。","The readiness lasts 10 seconds and is consumed by the next completed Bad Juju cast, not cancellation. Separate from the similarly named 20% Puppet damage talent."},
 path={"30级，巫毒方案，免费点选保存。","Level 30 Voodoo build; select and save for free."}}
details[29121]={zh="恶毒诅咒",en="Malignant Jinx",level=33,early="33",kind="主动诅咒 / Active curse",
 effects={{"诅咒敌人8秒，其下一次正常法术成功施放时沉默5秒；30码，60秒冷却。","Curse an enemy for 8 seconds; its next non-triggered spell cast causes a 5-second silence. 30 yards, 60-second cooldown."}},
 limit={"同一目标只能有一种巫医Jinx；施加成功才替换。可以驱散，沉默受原生免疫/递减规则约束。","Only one Witch Doctor Jinx per target; replaces on successful application. Dispellable; silence follows native immunity and diminishing rules."},
 path={"先投入8点基础巫毒TE，再花1 TE；法术要求33级。","Eight foundation Voodoo TE, then one TE; spell requires level 33."}}
details[31346]={zh="彼界",en="De Other Side",level=10,early="57",kind="被动 / Passive",
 effects={{"暗影傀儡有效伤害增加1层彼界；每层魔法伤害和暴击率提高1%，最多10层。首层开始20秒倒计时，继续叠层不续时。","Effective Shadow Puppets damage adds one stack: +1% magical damage and critical chance, up to 10. The 20-second timer starts at the first stack and never refreshes."}},
 limit={"只响应本人傀儡，不响应他人、复制或全吸收伤害；移除天赋时清除增益。","Only your Puppet damage qualifies, excluding others and fully absorbed hits. Removing the talent removes its buff."},
 path={"先投入23点巫毒TE，再花1 TE；不能用本节点自己凑23点。","Invest 23 Voodoo TE before spending one TE here; this node cannot satisfy its own prerequisite."}}

details[7100]={zh="黑暗雕像",en="Dark Effigy",level=10,early="57",kind="被动 / Passive",
 effects={{"邪恶巫毒和妖火额外打击主目标10码内最多2名敌人。暗影耀斑对带有本人傀儡师之线的目标伤害提高50%。","Bad Juju and Hexfire strike up to 2 additional enemies within 10 yards of the primary target. Shadowflare deals 50% more damage to targets affected by your Puppeteer's Threads."}},
 limit={"仅本人已保存激活天赋生效；额外施法不再次扩散，不额外扣法力或冷却。","Requires your saved active talent. Extra triggered casts cannot spread again and cost no additional mana or cooldown."},
 path={"先投入23点前层巫毒TE，再花1 TE；不能用本节点自身凑门槛。","Invest 23 lower-tier Voodoo TE first, then spend one TE; this node cannot count toward its own prerequisite."}}
details[29768]={zh="邦桑迪之声",en="Voice of Bwonsamdi",level=57,early="57",kind="主动 / Active",
 effects={{"持续20秒，冷却90秒，消耗12%基础法力。本人造成有效周期伤害时，向该敌人释放困缚之魂，造成162点基础暗影伤害加25%暗影法强。","For 20 sec, your damaging periodic hits release Trapped Spirits at that enemy for 162 base Shadow damage plus 25% Shadow spell power. 90 sec cooldown; 12% base mana."}},
 limit={"单次周期伤害触发一次；额外伤害不递归。力量的代价另行提供精神加成。","One proc per damaging periodic event; no recursion. The Price of Power separately adds Spirit."},path={"57级，先投入23点前层巫毒TE，再花1 TE。","Level 57, 23 lower-tier Voodoo TE, then one TE."}}
details[6057]={zh="力量的代价",en="The Price of Power",level=57,early="59",kind="被动 / Passive",
 effects={{"邦桑迪之声生效期间提高100%精神，结束后恢复。","Voice of Bwonsamdi increases Spirit by 100% while active."}},
 limit={"仅已保存激活的天赋生效；不提供暗影伤害百分比加成。","Requires the saved active talent; no Shadow damage percentage bonus."},path={"需要邦桑迪之声、23点前层巫毒TE，再花1 TE。","Requires Voice of Bwonsamdi and 23 lower-tier Voodoo TE; costs one TE."}}
details[30596]={zh="傀儡师之握",en="Puppeteer's Grasp",level=27,early="27",kind="主动 / Active",
 effects={{"持续30秒，冷却3分钟，消耗34%基础法力。期间可移动施放恶意之怒与邪恶巫毒，获得1层灵魂，此后每2秒再获得1层（沿用5层上限）。","Lasts 30 sec, with a 3-minute cooldown and 34% base mana cost. Cast Malefic Wrath and Bad Juju while moving; gain one Spirit immediately and every 2 sec, up to the existing 5-stack cap."}},
 limit={"仅这两类技能；光环结束后恢复移动打断。原变身模型引用缺失，沿用上游修正保留人物外观。","Only these two spell families. Movement interrupts resume when the aura ends. The missing donor transform is disabled, following the upstream fix."},path={"27级，已投入8点基础巫毒TE，再花1 TE。","Level 27, eight foundational Voodoo TE, then one TE."}}
details[31349]={zh="战争魔像",en="War Golem",level=59,early="59",kind="主动 / Active",effects={{"召唤10秒；吸收自身伤害，护盾为施放时智力的8倍；将15码友方受到的可重定向法术引向魔像。3分钟冷却，35%基础法力。","10-sec golem; shield for 8x snapshotted Intellect; redirect eligible spells targeting nearby allies. 3-min cooldown; 35% base mana."}},limit={"魔像死亡/消失即失去保护；不重定向带禁止标记的法术。","Protection ends with golem; native no-redirection flags remain."},path={"59级，8点基础TE，费用1 TE。","Level59, eight foundational TE; costs one TE."}}
details[29929]={zh="恶意魔像",en="Malicious Golems",level=57,early="23 TE后",kind="被动 / Passive",effects={{"召唤战争魔像获得20秒30%施法急速；恶意妖术周期伤害或暗影傀儡伤害每次减少魔像冷却0.5秒。","Summoning War Golem grants 30% spell haste for 20 sec; own Hex of Malice periodic damage or Shadow Puppets damage reduces its cooldown by 0.5 sec."}},limit={"只认本人有效伤害；不计其他周期伤害。","Only own qualifying damage."},path={"23点前层TE，费用1 TE。","23 prior TE; costs one TE."}}
details[6055]={zh="灵魂提线",en="Soul Marionette",level=59,early="59",kind="主动 / Active",effects={{"定身8秒召唤5分身，每2秒各叠1层，每层1%施法急速。20层后强化15秒，恶意之怒/邪恶巫毒伤害+30%并必暴击；分身各自爆炸并昏迷附近敌人。90秒冷却，22%基础法力。","Root for 8 sec; five clones each grant a stack every 2 sec, 1% spell haste per stack. At20, empower Wrath/Juju for 15 sec with +30% damage and guaranteed crit; clones explode and stun. 90-sec cooldown; 22% base mana."}},limit={"分身被杀或提前取消可能无法满20层；仅本人分身。","Killed clones or early cancellation can prevent reaching20; own clones only."},path={"59级，23点前层TE，费用1 TE。","Level59,23 prior TE; costs one TE."}}
details[11133]={zh="妖火进阶",en="Hexfire Adept",level=50,early="50",kind="免费被动 / Free passive",effects={{"施放妖火后，下一次恶意之怒变为妖火之怒：最多3目标火焰直伤和可暴击诅咒，并在主目标位置召唤短时蛇守卫。","Casting Hexfire empowers the next Malefic Wrath: fire damage and a critical-capable curse on up to three targets, plus a short-lived Serpent Ward."}},limit={"正式保存后生效；强化被消耗或到期后按钮还原。","Save the build first; the button restores on consumption or expiration."},path={"50级，绑定巫毒；免费，不花AE/TE。","Level50, Voodoo specialization; no AE/TE cost."}}
details[7033]={zh="灵魂守卫",en="Spirit Warden",level=10,early="先投入9 AE",kind="通用被动 / Class passive",effects={{"成功召唤神像后，自身精神提高10%，持续60秒。","Successfully summoning an Idol increases your Spirit by 10% for 60 sec."}},limit={"守卫和雕像不触发；重复召唤刷新时间，不叠加。取消本天赋会移除本人增益。","Wards and Effigies do not trigger it; repeated summons refresh rather than stack. Removing this talent clears your buff."},path={"先投入9点前层AE，再花1 AE；无强制连线技能前置。","Invest nine foundation AE, then one AE; no required connected ability."}}
details[6051]={zh="迅捷神像",en="Swift Idol",level=28,early="28",kind="主动神像 / Active Idol",effects={{"召唤持续10秒的神像，使30码内自己和队伍/团队成员移动速度提高25%，抵抗定身和减速的几率提高25%。","Summons a 10-second Idol: nearby party/raid members within 30 yards gain 25% movement speed and 25% resistance to roots and snares."}},limit={"共用神像栏位；离开范围或神像消失后结束，不解除已有定身或减速，也不是免疫。","Shares the Idol slot; ends out of range or when the Idol disappears. Does not cleanse existing roots/snares or grant immunity."},path={"28级，先投入9点前层AE，再花1 AE。","Level 28, nine foundation AE, then one AE."}}
details[6048]={zh="黑暗魔精",en="Dark Mojo",level=32,early="32",kind="通用被动 / Class passive",effects={{"抵抗魔法类和诅咒类负面效果的几率提高20%。","Increases your chance to resist Magic and Curse debuffs by 20%."}},limit={"不是魔法伤害减免，也不直接驱散已有负面效果；原图同组选项尚未开放。","Not magic damage reduction or a cleanse; the alternate authored choice is not open yet."},path={"32级，先投入9点前层AE，再花1 AE。","Level 32, nine foundation AE, then one AE."}}
-- WD104A: native effects; talent ownership is independent of spellbook category.
details[7131]={zh="强效混合",en="Potent Mixes",level=10,early="11 / 13",kind="酿造被动 / Brewing passive",effects={{"治疗效果提高4%，法术威胁降低15%。","Healing done +4%; spell threat -15%."},{"治疗效果提高8%，法术威胁降低30%。","Healing done +8%; spell threat -30%."}},limit={"最高级总收益，不叠加1级；普通近战白字不受法术威胁降低影响。与通用强效混合共用技能，只取较高等级；重复投入不增加收益。","Highest rank only, not added to rank 1; spell-threat reduction does not affect white melee swings. Shared with Class Potent Mixes; highest rank only. Duplicate investment adds no benefit."},path={"绑定酿造；每级1 TE，无额外技能前置。","Brewing build; one TE per rank; no ability prerequisite."}}
details[30884]={zh="魔精依赖",en="Mojo Addiction",level=10,early="11 / 13",kind="酿造被动 / Brewing passive",effects={{"精神和最大法力提高5%。","Spirit and maximum mana +5%."},{"精神和最大法力提高10%。","Spirit and maximum mana +10%."}},limit={"提高法力上限不等于瞬间回满；切换或重置方案移除本天赋加成。","Maximum mana increase is not a refill; switching or resetting removes this talent's bonus."},path={"绑定酿造；每级1 TE，无额外技能前置。","Brewing build; one TE per rank; no ability prerequisite."}}
details[29736]={zh="酿造大师",en="Brewmaster",level=10,early="11 / 13",kind="酿造被动 / Brewing passive",effects={{"洛阿佳酿基础施法时间缩短0.25秒。","Loa's Brew base cast time reduced by 0.25 sec."},{"洛阿佳酿基础施法时间缩短0.5秒。","Loa's Brew base cast time reduced by 0.5 sec."}},limit={"仅洛阿佳酿各等级；不缩短恶意之怒、邪恶巫毒、公共冷却或召唤时长。","Only Loa's Brew ranks; no effect on Malefic Wrath, Bad Juju, global cooldown or summon duration."},path={"绑定酿造；每级1 TE，无额外技能前置。","Brewing build; one TE per rank; no ability prerequisite."}}
details[9311]={zh="灵魂医者",en="Spirit Healer",level=20,early="20",kind="免费被动 / Free passive",effects={{"治疗强度增加当前精神的40%；每5秒额外回蓝等于当前精神的100%。","Healing power increased by 40% of current Spirit; additional mana per 5 seconds equals 100% of current Spirit."}},limit={"动态随精神变化；不是所有治疗直接提高40%，满蓝不额外储存回复。","Scales with current Spirit, not a flat 40% healing multiplier; mana is capped normally."},path={"20级，绑定酿造；0 AE / 0 TE，选中并保存生效。","Level 20, Brewing build; zero AE/TE, select and save."}}
details[5055]={zh="洛阿之临",en="Presence of the Loa",level=10,early="11",kind="酿造被动 / Brewing passive",effects={{"法术、近战和远程暴击几率提高4个百分点。","Spell, melee and ranged critical chance increased by 4 percentage points."}},limit={"不是暴击伤害提高4%；仅激活并保存的方案持有。","Not a 4% critical-damage bonus; requires an active saved build."},path={"绑定酿造，1 TE，无额外技能前置。","Brewing build, one TE, no ability prerequisite."}}
details[4715]={zh="洛阿祝福",en="Loa's Blessing",level=30,early="30",kind="免费被动 / Free passive",effects={{"洛阿佳酿直接治疗后，为目标随机赋予20秒增益：急速+3%、受治疗+3%、暴击+3个百分点或物理承伤-3%。","Direct Loa's Brew healing grants one random 20-second buff: haste +3%, healing received +3%, critical chance +3 points or physical damage taken -3%."}},limit={"同种刷新、异种可共存；复制治疗不重复触发。切方案停止新触发，已赋予的20秒增益自然到期。","Same buff refreshes; different buffs may coexist. Copied heals do not retrigger. Switching stops new procs; existing 20-second buffs expire normally."},path={"30级，绑定酿造；0 AE / 0 TE，选中并保存。","Level 30, Brewing build; zero AE/TE, select and save."}}
details[7129]={zh="充足药剂",en="Plentiful Potions",level=10,early="11",kind="酿造被动 / Brewing passive",effects={{"洛阿佳酿及破咒术的法力消耗降低10%。","Loa's Brew and Hexbreak mana cost reduced by 10%."}},limit={"仅这两个技能；不降低酒瓶、巫毒伤害技能或召唤技能消耗。","Only these two families; no cost reduction to Bottle, Voodoo damage or summons."},path={"绑定酿造；1 TE，无额外技能前置。","Brewing build; one TE; no ability prerequisite."}}
details[7948]={zh="灵魂之触",en="Touch of the Spirits",level=16,early="27",kind="酿造被动 / Brewing passive",effects={{"酒瓶溅射造成有效伤害时，使敌人受到伤害提高3%、造成伤害降低3%，持续15秒。","Effective Bottle splash damage increases enemy damage taken by 3% and reduces damage done by 3% for 15 seconds."}},limit={"满吸收、免疫、零伤害不触发；互斥选项暂未开放。切出方案停止新触发，已有短减益自然到期。","No proc on full absorb, immunity or zero damage. Alternate choice is not open. Existing short debuffs expire naturally on switching."},path={"绑定酿造，先投入8点基础酿造TE，再花1 TE；酒瓶需已学会。","Brewing; eight foundation TE then one TE; learn Bottle to use the effect."}}
details[31137]={zh="丛林秘法",en="Jungle Secrets",level=30,early="30",kind="酿造被动 / Brewing passive",effects={{"洛阿佳酿有效直接治疗后，己方雕像为20码内另一名受伤队伍/团队友方复制35%治疗，优先血量百分比最低者。","After effective direct Loa's Brew healing, your Effigy copies 35% healing to another injured party/raid ally within 20 yards, preferring lowest health percentage."}},limit={"需要自己的有效雕像；守卫、神像、魔像不替代雕像。排除本次主目标，满血和复制治疗不递归触发。","Requires your living Effigy, not a Ward, Idol or Golem. Excludes the primary target; no overheal or recursive echo proc."},path={"30级，绑定酿造；先投入8点基础酿造TE，再花1 TE。","Level 30, Brewing; eight foundation TE then one TE."}}

details[30891]={zh="穆厄扎拉之触",en="Touch of Muehzala",level=30,early="30",kind="通用天赋 / Class talent",effects={{"静滞守卫的昏迷基础时间延长1秒；仍受玩家控制上限与递减规则约束。","Stasis Ward stun base duration +1 second; native PvP caps and diminishing returns apply."}},limit={"仅已保存且激活的方案生效；本批待实机验收。","Active saved build only; awaiting gameplay verification."},path={"9点基础AE后花1 AE。","See prerequisites above."}}
details[6030]={zh="天选之人",en="Chosen One",level=10,early="10",kind="通用天赋 / Class talent",effects={{"拟态守卫额外召唤一个；两个各自检查目标距离及视线。","Mimic Ward summons one additional ward; each checks range and line of sight."}},limit={"仅已保存且激活的方案生效；本批待实机验收。","Active saved build only; awaiting gameplay verification."},path={"1 AE；需学会拟态守卫才能产生效果。","See prerequisites above."}}
details[7132]={zh="怒气佳酿",en="Rage Brew",level=31,early="31",kind="酿造主动 / Brewing active",effects={{"恢复友方50%最大怒气、能量或集中值；提高15%近战及远程攻击强度。","Restores 50% maximum Rage, Energy or Focus; increases melee/ranged attack power by 15%."}},limit={"仅已保存且激活的方案生效；本批待实机验收。","Active saved build only; awaiting gameplay verification."},path={"8点基础酿造TE后花1 TE；与奥术佳酿二选一。","See prerequisites above."}}
details[29753]={zh="奥术佳酿",en="Arcane Brew",level=31,early="31",kind="酿造主动 / Brewing active",effects={{"提高友方法术强度及精神，持续时间与数值详见技能；数值随施法者等级成长。","Increases friendly spell power and Spirit, scaling with caster level."}},limit={"仅已保存且激活的方案生效；本批待实机验收。","Active saved build only; awaiting gameplay verification."},path={"8点基础酿造TE后花1 TE；与怒气佳酿二选一。","See prerequisites above."}}

details[6381]={zh="洛阿强化",en="Loa Empowerment",level=10,early="先投9 AE",kind="通用被动 / Class passive",effects={{"巫祝技能耗蓝降低50%；力量巫祝效果提高20%。包括已移植的强效巫祝。","Wuju mana cost -50%; Power Wuju effectiveness +20%, including supported Greater Wujus."}},limit={"保存并激活后生效；既有增益需重新施放。","Active saved build only; recast existing buffs."},path={"9点基础AE后花1 AE；同层不计前置。","Nine foundation AE, then one AE."}}
details[12048]={zh="希里克的祝福",en="Blessing of Hir’eek",level=10,early="先投9 AE",kind="通用被动 / Class passive",effects={{"破咒术额外尝试移除一个诅咒，与黑暗魔精互斥。","Hexbreak attempts to remove one additional curse; exclusive with Dark Mojo."}},limit={"保存并激活后生效；既有增益需重新施放。","Active saved build only; recast existing buffs."},path={"9点基础AE后花1 AE；同层不计前置。","Nine foundation AE, then one AE."}}
details[11323]={zh="显性诅咒",en="Blatant Curse",level=10,early="先投9 AE",kind="通用被动 / Class passive",effects={{"倦怠、希里克、法力、缩小及恶毒诅咒耗蓝降低25%；不影响其他巫毒伤害或治疗技能。","Supported Jinx mana cost -25%; does not affect other damage/healing spells."}},limit={"保存并激活后生效；既有增益需重新施放。","Active saved build only; recast existing buffs."},path={"9点基础AE后花1 AE；同层不计前置。","Nine foundation AE, then one AE."}}
details[31118]={zh="假死药剂",en="Death Draught",level=10,early="10",kind="通用主动 / Class active",effects={{"进入假死，最多持续5分钟，30秒冷却。","Feign death for up to 5 minutes; 30 sec cooldown."}},limit={"沿用原生假死；不是无敌，副本中不保证脱战。移动/主动取消后恢复。","Native feign death, not immunity; dungeon combat may persist. Move or cancel to stand."},path={"10级花1 AE；本批不强制图中连线为技能前置。","Level 10 and one AE; graph connections are not extra prerequisites."}}
details[12264]={zh="强效混合",en="Potent Mixes",level=10,early="先投9 AE",kind="通用被动 / Class passive",effects={{"治疗量提高4%；法术产生的威胁降低15%。","Healing done +4%; threat generated by spells -15%."}},limit={"与酿造强效混合共用技能，只取较高等级；重复投入不增加收益。保存激活后生效。","Shared with Brewing Potent Mixes; highest rank only, no duplicate benefit; active saved build only."},path={"9点基础AE后花1 AE；同层不能凑前置。","Nine foundation AE, then one AE; same-tier nodes do not count."}}
details[6042]={zh="沃金守望",en="Vol'jin's Vigil",level=10,early="先投9 AE",kind="通用主动 / Class active",effects={{"受到的伤害降低25%；每秒恢复最大生命值的2%，持续10秒。冷却2分钟。","Damage taken -25%; restore 2% of maximum health each second for 10 sec. 2 min cooldown."}},limit={"仅自身；恢复量受实际治疗修正影响；不是免疫。可受灵魂行者增强，当前数值查看技能书。","Self only; actual healing follows healing modifiers, not immunity. Spirit Walker applies; see spellbook for current values."},path={"9点基础AE后花1 AE；保存并激活生效。","Nine foundation AE, then one AE; save and activate."}}
details[9347]={zh="灵魂行者",en="Spirit Walker",level=10,early="先投9 AE",kind="通用被动 / Class passive",effects={{"沃金守望和迅捷神像的持续时间与效果提高10%。","Vigil and Swift Idol duration/effectiveness +10%."},{"沃金守望和迅捷神像的持续时间与效果提高20%。","Vigil and Swift Idol duration/effectiveness +20%."}},limit={"不缩短冷却、不增加范围；百分比光环数值按核心整数截断。变更等级会结束旧沃金守望/迅捷神像，需要重新施放。","No cooldown/range change. Percentage aura amounts truncate to integers. Rank changes end existing Vigil/Swift Idol; recast."},path={"9点基础AE后，每级1 AE；同层不能凑前置。","Nine foundation AE; one AE per rank; no same-tier bootstrap."}}
details[29306]={zh="化蛇",en="Slither",level=30,early="等级30；先投9 AE",kind="通用主动 / Class active",effects={{"化为蛇，解除已有定身/减速；移动速度提高80%，持续5秒。远程攻击与法术命中率降低100个百分点，游泳速度提高80%。冷却60秒。","Transform into a serpent, remove existing roots/snares, +80% movement for 5 sec; ranged/spell hit chance -100 percentage points, +80% swim speed. 60 sec cooldown."}},limit={"期间不能攻击或施法；可右键取消。不免疫近战、已有持续伤害或后续控制。","Cannot attack/cast; right-click to cancel. Not immune to melee, existing periodic damage or subsequent control."},path={"等级30，9点基础AE后花1 AE；保存并激活。","Level 30, nine foundation AE then one AE; save and activate."}}
details[6031]={zh="蛙变术",en="Amphibimorph",level=26,early="26；先投9 AE",kind="通用技能 / Class ability",effects={{"30码内选定区域的敌人变蛙，不能攻击施法，移速降低25%，视为野兽；持续40秒，对玩家最多8秒，受伤解除。基础施法1秒，冷却120秒。","Frog enemies in the target area; pacify/silence, -25% speed, Beast type. 40 sec, up to 8 sec on players; damage breaks. Base cast 1 sec, cooldown 120 sec."}},limit={"仅激活且已保存方案生效；两种祝福互斥，玩家控制受递减规则约束。","Active saved build; blessings exclusive; native PvP diminishing applies."},path={"9点基础AE后每节点1 AE；祝福需先学习蛙变术。","Nine foundation AE, one AE per node; blessings require Amphibimorph."}}
details[6525]={zh="贡克祝福",en="Gonk's Blessing",level=26,early="26；先投9 AE",kind="通用技能 / Class ability",effects={{"蛙变术冷却缩短60秒，基础施法时间增加0.5秒。","Amphibimorph cooldown -60 sec; base cast time +0.5 sec."}},limit={"仅激活且已保存方案生效；两种祝福互斥，玩家控制受递减规则约束。","Active saved build; blessings exclusive; native PvP diminishing applies."},path={"9点基础AE后每节点1 AE；祝福需先学习蛙变术。","Nine foundation AE, one AE per node; blessings require Amphibimorph."}}
details[12525]={zh="克拉格瓦祝福",en="Krag'wa's Blessing",level=26,early="26；先投9 AE",kind="通用技能 / Class ability",effects={{"蛙变术变为瞬发；冷却仍为120秒。","Amphibimorph becomes instant; cooldown remains 120 sec."}},limit={"仅激活且已保存方案生效；两种祝福互斥，玩家控制受递减规则约束。","Active saved build; blessings exclusive; native PvP diminishing applies."},path={"9点基础AE后每节点1 AE；祝福需先学习蛙变术。","Nine foundation AE, one AE per node; blessings require Amphibimorph."}}
details[4005]={zh="大锅酿造",en="Cauldron Brewer",level=10,early="10",kind="酿造技能 / Brewing ability",effects={{"解锁酿造配料体系。本批支持丛林蘑菇；配料需主动准备，基础同时保留一种。","Unlocks ingredient brewing. This batch supports Jungle Shrooms; prepare it actively, one ingredient at a time."}},limit={"仅已保存的激活酿造方案生效；配料不是可消耗物品。","Active saved Brewing build only; ingredients are not consumable items."},path={"免费节点；配料及投掷需要大锅酿造或治疗守卫。","Free nodes; ingredient and toss require Cauldron Brewer or Healing Ward."}}
details[12645]={zh="配料：丛林蘑菇",en="Ingredient: Jungle Shrooms",level=10,early="10",kind="酿造技能 / Brewing ability",effects={{"准备后每6秒治疗周围30码最多8名队友；基础治疗随角色等级缩放，另加20%治疗加成。药水投掷附加每3秒一次、持续18秒的治疗。","Prepare to heal up to 8 raid allies within 30 yd every 6 sec; level-scaled base plus 20% bonus healing. Potion Toss adds a heal every 3 sec for 18 sec."}},limit={"仅已保存的激活酿造方案生效；配料不是可消耗物品。","Active saved Brewing build only; ingredients are not consumable items."},path={"免费节点；配料及投掷需要大锅酿造或治疗守卫。","Free nodes; ingredient and toss require Cauldron Brewer or Healing Ward."}}
details[12646]={zh="药水投掷",en="Potion Toss",level=14,early="14",kind="酿造技能 / Brewing ability",effects={{"需先准备配料。瞬发治疗友方，冷却15秒；随等级学习对应技能等级，直接治疗增加28%治疗加成及10%精神。","Requires a prepared ingredient. Instant friendly heal, 15 sec cooldown; ranks follow level. Direct heal gains 28% bonus healing and 10% Spirit."}},limit={"仅已保存的激活酿造方案生效；配料不是可消耗物品。","Active saved Brewing build only; ingredients are not consumable items."},path={"免费节点；配料及投掷需要大锅酿造或治疗守卫。","Free nodes; ingredient and toss require Cauldron Brewer or Healing Ward."}}
details[6498]={zh="新鲜配料",en="Fresh Ingredients",level=10,early="先投8 TE",kind="酿造被动 / Brewing passive",effects={{"治疗量提高15%。只提高大锅丛林蘑菇的周期范围治疗；不提高投掷附带治疗。", "Healing +15%. Cauldron Shrooms pulse only; excludes tossed heal over time."}, {"治疗量提高30%。只提高大锅丛林蘑菇的周期范围治疗；不提高投掷附带治疗。", "Healing +30%. Cauldron Shrooms pulse only; excludes tossed heal over time."}},limit={"仅保存并激活后生效；持续治疗增益在重新投掷时生效。","Active saved build only; recast Potion Toss to update its existing heal over time."},path={"先投入8点基础酿造TE，每级1 TE；同层不能互相凑前置。","Eight foundation Brewing TE, then one TE per rank; same-tier points do not qualify."}}
details[29303]={zh="药水增效",en="Potion Boss",level=10,early="先投8 TE",kind="酿造被动 / Brewing passive",effects={{"治疗量提高20%。提高药水投掷直接治疗及投掷／泼洒附带的蘑菇持续治疗；不提高泼洒直接或大锅治疗。", "Healing +20%. Potion Toss direct and tossed/splashed Shrooms HoT; excludes direct Splash and Cauldron pulses."}},limit={"仅保存并激活后生效；持续治疗增益在重新投掷时生效。","Active saved build only; recast Potion Toss to update its existing heal over time."},path={"先投入8点基础酿造TE，每级1 TE；同层不能互相凑前置。","Eight foundation Brewing TE, then one TE per rank; same-tier points do not qualify."}}
details[6020]={zh="丛林绽放",en="Jungle Booms",level=10,early="先投8 TE",kind="酿造被动 / Brewing passive",effects={{"大锅丛林蘑菇单次治疗提高100%，每跳目标由8人降至5人；间隔仍为6秒。","Cauldron Shrooms healing +100%, target cap reduced from 8 to 5; interval remains 6 sec."}},limit={"两者互斥；不影响投掷及其持续治疗；仅保存并激活后生效。","Mutually exclusive; excludes Potion Toss and its HoT; active saved build only."},path={"先投入8点基础酿造TE，再花1 TE；同层不计前置。","Eight foundation Brewing TE, then one TE; same-tier points excluded."}}
details[29737]={zh="丛林医师",en="Doctor of the Jungle",level=10,early="先投8 TE",kind="酿造被动 / Brewing passive",effects={{"大锅丛林蘑菇治疗间隔缩短2秒，由6秒变为4秒；目标上限仍为8人。","Cauldron Shrooms interval -2 sec, from 6 to 4 sec; target cap remains 8."}},limit={"两者互斥；不影响投掷及其持续治疗；仅保存并激活后生效。","Mutually exclusive; excludes Potion Toss and its HoT; active saved build only."},path={"先投入8点基础酿造TE，再花1 TE；同层不计前置。","Eight foundation Brewing TE, then one TE; same-tier points excluded."}}
details[7128]={zh="泼洒药水",en="Splash Potion",level=17,early="17",kind="酿造技能 / Brewing ability",effects={{"向40码内地点泼洒，治疗10码内最多8名友方；7个技能等级，冷却15秒。蘑菇附加每3秒一次、持续12秒的治疗。","Splash at a location within 40 yd, healing up to 8 allies within 10 yd. Seven ranks, 15 sec cooldown. Shrooms adds healing every 3 sec for 12 sec."}},limit={"需准备丛林蘑菇。药水增效只增强附加持续治疗，不增强泼洒直接治疗。","Requires prepared Shrooms. Potion Boss boosts the added HoT only, not direct Splash healing."},path={"酿造专精，17级，1 TE；按等级自动学习最高技能等级。","Brewing, level 17, one TE; highest rank learned by level."}}
details[35065]={zh="药水投手",en="Potion Slinger",level=10,early="先投8 TE",kind="酿造被动 / Brewing passive",effects={{"药水投掷与泼洒药水的冷却各缩短5秒。","Potion Toss and Splash Potion cooldowns are each reduced by 5 sec."}},limit={"仅本方案激活后生效；不影响其他技能。","Active saved build only; excludes other spells."},path={"8点基础酿造TE后花1 TE。","Eight foundation Brewing TE, then one TE."}}
details[35064]={zh="药师",en="Medicine Man",level=10,early="先投8 TE",kind="酿造被动 / Brewing passive",effects={{"施法中保留50%法力回复。","50% mana regeneration while casting."},{"施法中保留50%法力回复，并提高10%治疗量。","50% mana regeneration while casting and +10% healing done."}},limit={"二级取代一级；不叠加两份法力回复。","Rank 2 replaces rank 1; regeneration does not stack twice."},path={"8点基础酿造TE后，每级花1 TE。","Eight foundation Brewing TE, then one TE per rank."}}
details[35068]={zh="再生者",en="Regenerator",level=10,early="先投8 TE",kind="酿造被动 / Brewing passive",effects={{"精神的10%转换为法术暴击等级；实际暴击几率随角色等级换算。","Adds 10% of Spirit as spell critical rating; the final crit chance depends on character level."}},limit={"只增加法术暴击等级；不改近战或远程暴击。","Spell critical rating only; not melee or ranged crit."},path={"8点基础酿造TE后花1 TE。","Eight foundation Brewing TE, then one TE."}}
details[29738]={zh="配料：蛙骨",en="Ingredient: Frog Bones",level=10,early="先投8 TE",kind="酿造主动 / Brewing active",effects={{"酿入大锅后，40码内团队成员受到的伤害降低3%；药水投掷附加护盾：100＋35%精神＋80%自然治疗加成。泼洒药水附加护盾基础值25，采用相同加成。","Prepare in the Cauldron: raid members within 40 yd take 3% less damage. Toss adds a shield of 100 + 35% Spirit + 80% Nature healing bonus; Splash uses base 25 with the same scaling."}},limit={"默认仅一种配料；调酒师允许两种，第三种替换最早准备的配料。","One ingredient normally; Mixologist allows two, replacing the oldest on a third preparation."},path={"先投入8点基础酿造TE，再花1 TE。","Eight foundation Brewing TE, then one TE."}}
details[30888]={zh="缩小盟友",en="Shrink Ally",level=10,early="先投8 TE",kind="酿造主动 / Brewing active",effects={{"使一名友方缩小8秒，闪避几率提高50%；冷却2分钟。缩小外观约25%。","Shrink an ally for 8 sec, increasing dodge chance by 50%; 2 min cooldown. Appearance shrinks by about 25%."}},limit={"仅已保存并激活的酿造方案可施放。","Active saved Brewing build only."},path={"先投入8点基础酿造TE，再花1 TE。","Eight foundation Brewing TE, then one TE."}}
details[35051]={zh="蛇神门徒",en="Disciple of Sseratus",level=10,early="先投8 TE",kind="酿造被动 / Brewing passive",effects={{"洛阿佳酿、瓶中之灵的额外治疗加成提高15%；破咒术额外解除附近一名友方的诅咒，公共冷却缩短0.5秒。","Bonus-healing scaling of Loa's Brew and Spirit in a Bottle +15%; Hexbreak affects one additional nearby ally and has 0.5 sec less global cooldown."}},limit={"仅已保存并激活的酿造方案生效。","Active saved Brewing build only."},path={"先投入8点基础酿造TE，再花1 TE。","Eight foundation Brewing TE, then one TE."}}
details[6645]={zh="调酒师",en="Mixologist",level=10,early="1 TE",kind="酿造被动 / Brewing passive",effects={{"同时准备两种配料；第三种替换最早准备的一种。提前授予鱼油；16级独立学习仍保留。","Prepare two ingredients; a third replaces the oldest. Grants Fish Oil early; independent level-16 ownership is preserved."}},limit={"只读取已保存激活方案；换料不会改变已发射药水的配料。","Active saved build only; in-flight potions keep their ingredient snapshot."},path={"大锅酿造后花1 TE；此点不计入旧8点基础门槛。","Cauldron Brewer, then 1 TE; excluded from the existing eight-point foundation."}}
details[4112]={zh="香料：宁神花",en="Spice: Peacebloom",level=10,early="先投8 TE",kind="酿造被动 / Brewing passive",effects={{"40码内自身及团队成员受到的定身、昏迷、减速持续时间缩短25%。","Reduces root, stun and snare duration on yourself and raid members within 40 yd by 25%."}},limit={"与地根草互斥；遵循原生控制递减和同类效果规则。","Exclusive with Earthroot; native diminishing returns and stacking rules apply."},path={"大锅酿造和8点基础酿造TE，再花1 TE。","Cauldron Brewer and eight foundation Brewing TE, then 1 TE."}}
details[7130]={zh="香料：地根草",en="Spice: Earthroot",level=10,early="先投8 TE",kind="酿造被动 / Brewing passive",effects={{"大锅蘑菇治疗、蘑菇附加治疗、鱼油及蛙骨附效提高30%；整数光环按核心截断。","Increases cauldron mushroom healing and mushroom, fish-oil and frog-bone ingredient effects by 30%; integer aura amounts truncate."}},limit={"与宁神花互斥；不增加药水直接治疗、冷却、持续时间或无关技能。","Exclusive with Peacebloom; does not increase direct potion healing, cooldowns, durations or unrelated spells."},path={"大锅酿造和8点基础酿造TE，再花1 TE。","Cauldron Brewer and eight foundation Brewing TE, then 1 TE."}}
details[6021]={zh="配料：血蓟",en="Ingredient: Bloodthistle",level=10,early="先投8 TE",kind="酿造配料 / Ingredient",effects={{"准备后40码团队获得8%治疗承受加成。投掷附加15秒、泼洒附加20秒吸血：自身造成伤害的5%转为治疗，每0.5秒最多一次。","Cauldron grants 8% healing received in 40 yd. Toss/Splash grant 15/20 sec of 5% damage leech, at most once per 0.5 sec."}},limit={"不消耗背包草药；服从调酒师容量及顺序替换。地根草增强其效果；不同来源共用受益者0.5秒冷却，不重复吸血。","No bag reagent; follows ingredient capacity/FIFO. Earthroot applies; recipient-wide 0.5 sec cooldown prevents duplicate leech."},path={"大锅酿造与8点基础酿造TE，再花1 TE。","Cauldron Brewer and eight foundation Brewing TE, then 1 TE."}}
details[6014]={zh="森金之仪",en="Sen'jin's Presence",level=10,early="先投8 TE",kind="酿造被动 / Brewing passive",effects={{"成功施放药水投掷或瓶中之灵后，接下来两次洛阿佳酿施法时间缩短20%，持续10秒。","Successful Potion Toss or Spirit in a Bottle grants 20% reduced cast time for the next two Loa's Brews within 10 sec."}},limit={"泼洒、隐藏治疗和触发法术不刷新。只对佳酿生效；中断不消耗，重复触发重置为两次而非叠加。","Splash, hidden heals and triggered spells do not refresh. Brew only; interrupted casts preserve charges; refresh resets to two."},path={"大锅酿造与8点基础酿造TE，再花1 TE。","Cauldron Brewer and eight foundation Brewing TE, then 1 TE."}}
details[30823]={zh="魔精光束",en="Mojo Beam",level=29,early="8基础TE",kind="酿造 / Brewing",effects={{"引导8秒，每0.5秒治疗，逐渐长出分支，最多8个目标，分支增多时耗蓝增加。引导中投掷、泼洒及瓶中之灵瞬发，费用提高20%。","Channels for 8 sec at 0.5 sec intervals; grows up to 8 branches with increasing mana upkeep. Toss, Splash and Bottle are instant and cost 20% more during the channel."}},limit={"移动中断光束，其他技能不享受引导特例。","Moving interrupts Beam; unrelated spells receive no channel exception."},path={"大锅、8点基础酿造TE及连接前置，再花1 TE。","Cauldron, eight foundation Brewing TE and connected prerequisite, then 1 TE."}}
details[6022]={zh="泼洒他们",en="Splash On Em",level=10,early="8基础TE",kind="酿造 / Brewing",effects={{"光束每次有效治疗使投掷与泼洒冷却各缩短1秒；成功施放洛阿药剂使光束冷却缩短2秒。","Each effective Beam heal reduces Toss and Splash cooldowns by 1 sec. A successful Loa Brew reduces Beam cooldown by 2 sec."}},limit={"移动中断光束，其他技能不享受引导特例。","Moving interrupts Beam; unrelated spells receive no channel exception."},path={"大锅、8点基础酿造TE及连接前置，再花1 TE。","Cauldron, eight foundation Brewing TE and connected prerequisite, then 1 TE."}}
details[6013]={zh="瓶外之灵",en="Spirit Out Of The Bottle",level=10,early="8基础TE",kind="酿造 / Brewing",effects={{"成功施放瓶中之灵获得1层灵魂；引导光束期间瓶中之灵额外治疗主要目标附近15码内最多2名团队友方。与灵魂之触互斥。","Bottle grants one Spirit; during Beam it heals up to 2 additional raid allies within 15 yd of its primary target. Exclusive with Touch of the Spirits."}},limit={"移动中断光束，其他技能不享受引导特例。","Moving interrupts Beam; unrelated spells receive no channel exception."},path={"大锅、8点基础酿造TE及连接前置，再花1 TE。","Cauldron, eight foundation Brewing TE and connected prerequisite, then 1 TE."}}
details[6016]={zh="魔精：蛙骨蘑菇",en="Mojo: Frog Shrooms",level=10,early="8基础TE",kind="酿造主动 / Brewing active",effects={{"立即准备蘑菇与蛙骨，重置投掷和泼洒冷却；5秒内下一次投掷或泼洒使目标最大生命提高10%、体型增大15%，持续10秒。45秒冷却。","Instant ingredient pair; reset Toss/Splash cooldowns. Next Toss/Splash within 5 sec grants the Mojo effect. 45 sec cooldown."}},limit={"手动换料取消待用魔精；双魔精互相替换。","Manual preparation cancels pending Mojo; the two Mojos replace each other."},path={"大锅、蘑菇、对应配料、8基础酿造TE，再花1 TE。","Cauldron, Shrooms, matching ingredient, 8 foundation TE, then 1 TE."}}
details[6009]={zh="魔精：丛林血蓟",en="Mojo: Jungle Thistle",level=10,early="8基础TE",kind="酿造主动 / Brewing active",effects={{"立即准备蘑菇与血蓟，重置投掷和泼洒冷却；5秒内下一次投掷或泼洒使目标受到的范围伤害降低30%，持续10秒。45秒冷却。","Instant ingredient pair; reset Toss/Splash cooldowns. Next Toss/Splash within 5 sec grants the Mojo effect. 45 sec cooldown."}},limit={"手动换料取消待用魔精；双魔精互相替换。","Manual preparation cancels pending Mojo; the two Mojos replace each other."},path={"大锅、蘑菇、对应配料、8基础酿造TE，再花1 TE。","Cauldron, Shrooms, matching ingredient, 8 foundation TE, then 1 TE."}}
details[4733]={zh="魔精波动",en="Mojo Wave",level=40,early="40",kind="酿造免费被动 / Free Brewing passive",effects={ {"光束有效治疗的50%扩散给受治疗者20码内最多2名低血量团队友方；施放光束给予40码内最多10名法力友方恢复，每5秒回复5%最大法力，持续15秒。","50% of effective Beam healing echoes to up to 2 lowest-health raid allies within 20 yd. Casting Beam grants up to 10 mana allies within 40 yd Replenishment: 5% maximum mana per 5 sec for 15 sec."} },limit={"扩散不长分支、不再减药水冷却；恢复与原生57669互斥。","Echo does not grow branches or reduce potion cooldowns; Replenishment is exclusive with native 57669."},path={"40级、已保存洛阿祝福；免费选择并保存。","Level 40 and saved Loa Blessing; select and save for free."}}
details[6015]={zh="魔精：鱼骨",en="Mojo: Fish Bones",level=16,early="16",kind="酿造主动 / Brewing active",effects={{"准备鱼油与蛙骨，重置投掷/泼洒冷却；5秒内下一次药水命中目标时回复10%最大生命并驱散1个有害魔法。45秒冷却。","Prepares Fish Oil + Frog Bones; resets Toss/Splash. Next potion within 5 sec heals 10% max health and dispels 1 harmful magic effect. 45 sec cooldown."}},limit={"正式方案生效；两种基底同一施法者互斥。","Active saved build only; one Base per caster."},path={"16级、鱼油、蛙骨、大锅和8基础酿造TE；再花1 TE。","Requires saved prerequisites, then 1 TE."}}
details[29310]={zh="基底：野兽之血",en="Base: Beast Blood",level=10,early="10",kind="酿造主动 / Brewing active",effects={{"10秒内，40码团队友方受到直接物理伤害的15%转为随后5秒逐秒结算；基底或范围效果结束会结清余款。90秒冷却，30%基础法力。","For 10 sec, 15% direct physical damage to raid allies within 40 yd is paid over 5 sec. Leaving/ending settles remaining debt. 90 sec cooldown; 30% base mana."}},limit={"正式方案生效；两种基底同一施法者互斥。","Active saved build only; one Base per caster."},path={"大锅、8基础酿造TE；丛林血蓟或怒气/奥术佳酿前置；再花1 TE。","Requires saved prerequisites, then 1 TE."}}
details[29754]={zh="基底：水晶之水",en="Base: Crystal Water",level=10,early="10",kind="酿造主动 / Brewing active",effects={{"10秒内，40码团队友方实际受到治疗的20%累积为持续5秒的吸收盾，上限为目标最大生命。90秒冷却，30%基础法力。","For 10 sec, 20% effective healing received by raid allies within 40 yd builds a 5 sec shield, capped at max health. 90 sec cooldown; 30% base mana."}},limit={"正式方案生效；两种基底同一施法者互斥。","Active saved build only; one Base per caster."},path={"野兽之血，先投入23点酿造TE，不计本节点；再花1 TE。","Requires saved prerequisites, then 1 TE."}}
details[30333]={zh="巫毒大锅",en="Voodoo Cauldron",level=57,early="57",kind="酿造主动 / Brewing active",effects={{"放置巫毒大锅15秒，15码内团队友方受到治疗提高20%，每1.5秒恢复300+60%治疗强度；3分钟冷却，11%基础法力。","Places a cauldron for 15 sec. Raid allies within 15 yd receive 20% more healing and are healed for 300 + 60% bonus healing every 1.5 sec. 3 min cooldown; 11% base mana."}},limit={"每位施法者仅一个巫毒大锅，与守卫/雕像独立。","One Voodoo Cauldron per caster; independent of wards/idols."},path={"57级，大锅，23点既有酿造TE及相连前置；再花1 TE。","Level 57, Cauldron, 23 prior Brewing TE and a connected prerequisite; then 1 TE."}}
details[6027]={zh="动荡混合物",en="Unstable Concoction",level=57,early="59",kind="酿造被动 / Brewing passive",effects={{"药水投掷给目标留下20秒标记；你对其施放洛阿药剂或瓶中之灵时消耗标记，治疗目标20码内最多5名团队友方。基础值5+4×(等级−17)+40%治疗强度。","Potion Toss marks its target for 20 sec. Your Loa's Brew or Spirit in a Bottle consumes the mark and heals up to 5 raid allies within 20 yd for 5 + 4*(level-17) + 40% bonus healing."}},limit={"仅消耗自己的标记；泼洒和周期治疗不挂标记、不触发爆发。","Only your own mark; Splash and periodic heals do not mark or detonate."},path={"巫毒大锅与23点既有酿造TE；再花1 TE。","Voodoo Cauldron and 23 prior Brewing TE; then 1 TE."}}
details[13133]={zh="灵魂链接神像",en="Spirit Link Idol",level=50,early="50",kind="酿造免费主动 / Free Brewing active",effects={{"放置神像14秒，每2秒将10码内存活团队玩家的当前生命重新分配为近似相同百分比，保持总生命不变；3分钟冷却，3%基础法力。","Places an idol for 14 sec. Every 2 sec, living raid players within 10 yd share the same health percentage while total health is conserved. 3 min cooldown; 3% base mana."}},limit={"占用同一神像槽；不复活、不产生额外治疗，NPC机器人不参与。","Shares the Idol slot. No resurrection or extra healing; NPC bots are excluded."},path={"50级，魔精波动；免费选择并保存。","Level 50, Mojo Wave; select and save for free."}}
details[6026]={zh="调制大师",en="Master of Concoctions",level=57,early="57",kind="酿造被动 / Brewing passive",effects={{"药水投掷与泼洒附带的配料效果持续时间延长20%。丛林蘑菇使受益者在15秒内接下来3次进攻技能按实际伤害的5%恢复自身生命。","Delivered ingredient effects last 20% longer. Jungle Shrooms grants 15 sec to heal for 5% of resolved damage from the next 3 offensive casts."}},limit={"每次成功施法扣一次，群攻不按目标扣，周期伤害沿用该次施法；普攻、自动射击及无关触发不消耗。回收治疗不重复吃法强或暴击。","One charge per successful cast, not per target/tick. Autoattacks and unrelated procs are excluded; leech does not double-scale or crit."},path={"大锅、丛林蘑菇、森金之仪，先投入23点前层酿造TE，再花1 TE。","Cauldron Brewer, Jungle Shrooms and Senjin Presence; 23 prior Brewing TE, then 1 TE."}}
details[29740]={zh="调酒大师",en="Master Mixologist",level=59,early="59",kind="酿造主动 / Brewing active",effects={{"持续10秒，大锅中四种配料及投掷/泼洒附带的配料效果提高100%，期间可以移动施放瓶中之灵。2分钟冷却。","For 10 sec, Cauldron ingredient effects and delivered Ingredients gain 100% effectiveness; Spirit in a Bottle can be cast while moving. 2 min cooldown."}},limit={"按官方配料掩码限定蘑菇、鱼油、蛙骨与血蓟；不增加范围、持续时间、层数或药水直接治疗，不增强独立的大锅基底与调制大师吸血。","Ingredient whitelist only; no radius/duration/charge increase, direct potion healing, independent bases or Concoctions leech."},path={"59级、调制大师；再花1 TE。","Level 59 and Master of Concoctions; one additional TE."}}
local function Pair(zh,en,r,g,b,sameColor)
 -- Both languages remain visible; the language switch chooses which comes first.
 if RebornWDLanguage=="en" then zh,en=en,zh end
 GameTooltip:AddLine(zh,r or 1,g or .82,b or 0,true)
 GameTooltip:AddLine(en,sameColor and (r or 1) or .7,sameColor and (g or .82) or .75,sameColor and (b or 0) or .8,true)
end
local function PathReady(id)
 if id==6031 or id==6525 or id==12525 then
  local foundation=M.AERank(29744)+M.AERank(6054)+M.AERank(6047)+M.AERank(7092)+M.AERank(29309)+M.AERank(29301)+M.AERank(7088)+M.AERank(6030)+M.AERank(31118)
  return M.level>=26 and foundation>=9 and (id==6031 or M.AERank(6031)>0) and (id~=6525 or M.AERank(12525)==0) and (id~=12525 or M.AERank(6525)==0)
 end
 if id==29306 then return M.level>=30 and M.AERank(29744)+M.AERank(6054)+M.AERank(6047)+M.AERank(7092)+M.AERank(29309)+M.AERank(29301)+M.AERank(7088)+M.AERank(6030)+M.AERank(31118)>=9 end
 if id==6381 or id==12048 or id==11323 or id==12264 or id==6042 or id==9347 then return M.AERank(29744)+M.AERank(6054)+M.AERank(6047)+M.AERank(7092)+M.AERank(29309)+M.AERank(29301)+M.AERank(7088)+M.AERank(6030)+M.AERank(31118)>=9 end
 if id==6030 then return true end
 if id==30891 then return M.AESpent(M.draftAE)-M.AERank(30147)-M.AERank(4132)-M.AERank(7033)-M.AERank(6051)-M.AERank(6048)-M.AERank(5113)-M.AERank(30891)-M.AERank(6381)-M.AERank(12048)-M.AERank(11323)-M.AERank(12264)-M.AERank(6042)-M.AERank(9347)-M.AERank(29306)-M.AERank(6031)-M.AERank(6525)-M.AERank(12525)>=9 end
 if id==7132 or id==29753 then return M.specs[M.slot+1]==1 and M.BrewingFoundation(M.draftAE)>=8 end
 if id==7948 or id==31137 then return (id~=7948 or M.AERank(6013)==0) and M.specs[M.slot+1]==1 and M.BrewingFoundation(M.draftAE)>=8 end
 if id==29740 or id==6026 or id==30333 or id==6027 or id==6015 or id==29310 or id==29754 then local m=M.MaskSet(M.draftAE,Shift(index[id]),1,1);return M.AEValid(m) end
 if id==13133 then return M.level>=50 and M.specs[M.slot+1]==1 and M.AERank(4733)>0 end
 if id==4733 then return M.level>=40 and M.specs[M.slot+1]==1 and M.AERank(4715)>0 end
 if id==6016 or id==6009 then return M.level>=10 and M.specs[M.slot+1]==1 and M.AERank(4005)>0 and M.AERank(12645)>0 and M.BrewingFoundation(M.draftAE)>=8 and M.AERank(id==6016 and 29738 or 6021)>0 end
 if id==30823 or id==6022 or id==6013 then
  local parent=id==30823 and (M.AERank(7128)>0 or M.AERank(29303)>0) or id==6022 and M.AERank(7128)>0 or id==6013 and (M.AERank(29303)>0 or M.AERank(29738)>0) and M.AERank(7948)==0
  return parent and M.level>=(id==30823 and 29 or 10) and M.specs[M.slot+1]==1 and M.AERank(4005)>0 and M.BrewingFoundation(M.draftAE)>=8
 end
 if id==7948 and M.AERank(6013)>0 then return false end
 if id==6021 or id==6014 then return M.level>=10 and M.specs[M.slot+1]==1 and M.AERank(4005)>0 and M.BrewingFoundation(M.draftAE)>=8 end
 if id==6645 then return M.level>=10 and M.specs[M.slot+1]==1 and M.AERank(4005)>0 end
 if id==4112 or id==7130 then return M.level>=10 and M.specs[M.slot+1]==1 and M.AERank(4005)>0 and M.BrewingFoundation(M.draftAE)>=8 and M.AERank(id==4112 and 7130 or 4112)==0 end
 if id==7128 then return M.level>=17 and M.specs[M.slot+1]==1 end
 if id==35051 or id==30888 or id==29738 or id==6498 or id==29303 or id==6020 or id==29737 or id==35065 or id==35064 or id==35068 then return M.level>=10 and M.specs[M.slot+1]==1 and M.BrewingFoundation(M.draftAE)>=8 end
 if id==4005 then return M.level>=10 and M.specs[M.slot+1]==1 end
 if id==12645 or id==12646 then return M.level>=(id==12646 and 14 or 10) and M.specs[M.slot+1]==1 and (M.AERank(4005)>0 or M.AERank(29744)>0) end
 if id==7131 or id==30884 or id==29736 or id==9311 or id==5055 or id==4715 or id==7129 then return M.specs[M.slot+1]==1 end
 if id==11133 then return M.specs[M.slot+1]==0 and M.level>=50 end
 if id==31349 then return M.specs[M.slot+1]==0 and M.level>=59 and M.TEFoundation(M.draftAE)>=8 end
 if id==29929 or id==6055 then return M.specs[M.slot+1]==0 and M.level>=(id==6055 and 59 or 57) and M.TESpent(M.draftAE)-M.AERank(31346)-M.AERank(7100)-M.AERank(29768)-M.AERank(6057)-M.AERank(29929)-M.AERank(6055)>=23 end
 if id==30147 or id==4132 or id==7033 or id==6051 or id==6048 then return M.AESpent(M.draftAE)-M.AERank(30147)-M.AERank(4132)-M.AERank(7033)-M.AERank(6051)-M.AERank(6048)-M.AERank(5113)-M.AERank(30891)-M.AERank(6381)-M.AERank(12048)-M.AERank(11323)-M.AERank(12264)-M.AERank(6042)-M.AERank(9347)-M.AERank(29306)-M.AERank(6031)-M.AERank(6525)-M.AERank(12525)>=9 and ((id~=30147 and id~=6051) or M.level>=28) and (id~=6048 or M.level>=32) end
 if id==30596 then return M.specs[M.slot+1]==0 and M.level>=27 and M.TEFoundation(M.draftAE)>=8 end
 if id==29768 or id==6057 then return M.specs[M.slot+1]==0 and M.level>=57 and M.TESpent(M.draftAE)-M.AERank(31346)-M.AERank(7100)-M.AERank(29768)-M.AERank(6057)-M.AERank(29929)-M.AERank(6055)>=23 and (id==29768 or M.AERank(29768)>0) end
 if id==7100 then return M.specs[M.slot+1]==0 and M.TESpent(M.draftAE)-M.AERank(31346)-M.AERank(7100)-M.AERank(29768)-M.AERank(6057)-M.AERank(29929)-M.AERank(6055)>=23 end
 if id==31346 then return M.specs[M.slot+1]==0 and M.TESpent(M.draftAE)-M.AERank(31346)-M.AERank(7100)-M.AERank(29768)-M.AERank(6057)-M.AERank(29929)-M.AERank(6055)>=23 end
 if id==31347 or id==31348 or id==6644 or id==6046 or id==6062 or id==30889 or id==31343 or id==6053 or id==31350 or id==5333 or id==6059 or id==5332 or id==6007 or id==29121 then return M.specs[M.slot+1]==0 and M.TEFoundation(M.draftAE)>=8 end
 if id==31341 or id==6045 then
  local other=id==31341 and 6045 or 31341
  return M.specs[M.slot+1]==0 and M.AERank(other)==0 and M.TEFoundation(M.draftAE)>=8
 end
 local function has(node) return M.AERank(node)>0 end
 if id==6054 then return has(29744) or has(29301) end
 if id==6047 or id==7092 then return has(6054) end
 if id==29309 then return has(6047) or has(7092) end
 if id==31344 or id==31340 or id==7157 or id==6058 or id==29928 or id==30973 or id==4533 or id==31341 then return M.specs[M.slot+1]==0 end
 if id==4532 or id==31345 or id==11532 or id==4004 then return M.specs[M.slot+1]==0 end
 if id==31154 then return has(29301) and has(4004) and M.specs[M.slot+1]==0 end
 return true
end
local function Requirement(zh,en,ready)
 Pair((ready and "已满足：" or "未满足：")..zh,(ready and "Met: " or "Missing: ")..en,ready and .3 or 1,ready and 1 or .3,.3,true)
end
local function NodeNames(ids)
 local names={}
 for _,id in ipairs(ids or {}) do
  local label=tostring(id)
  for _,node in ipairs(RebornWDTreeData or {}) do if node.ID==id then label=node.Name;break end end
  local p=RebornWDProgress and RebornWDProgress.nodes[id]
  names[#names+1]=p and (p.name.." / "..label) or label
 end
 return table.concat(names,", ")
end
function M.AETooltip(n)
 if not M.modern then return false end
 local d=details[n.ID]
 if not d then
  local entry=RebornWDProgress and RebornWDProgress.nodes[n.ID]
  -- Existing mapped spells provide actual client descriptions; no invented preview effects.
  if entry and entry.spells[1] and GetSpellInfo(entry.spells[1]) then
   GameTooltip:SetHyperlink("spell:"..entry.spells[1])
  else
   GameTooltip:SetText(n.Name,1,.82,0)
   Pair("效果说明尚待核实，当前不能加点。","Effect details await verification; this node cannot be allocated.",.8,.8,.8)
  end
  Pair("未开放加点：下列条件仅供预览。","Allocation unavailable: the following requirements are a preview.",1,.5,.2)
  if (n.RequiredLevel or 0)>0 then Pair("等级要求："..n.RequiredLevel,"Required level: "..n.RequiredLevel) end
  if #(n.RequiredIDs or {})>0 then Pair("必需前置："..NodeNames(n.RequiredIDs),"Required nodes: "..NodeNames(n.RequiredIDs)) end
  Pair("每级费用："..(n.AECost or 0).." AE / "..(n.TECost or 0).." TE；最高"..n.MaxPoints.."级。",
   "Cost per rank: "..(n.AECost or 0).." AE / "..(n.TECost or 0).." TE; maximum rank "..n.MaxPoints..".")
  if (n.RequiredTabAEInvestment or 0)>0 or (n.RequiredTabTEInvestment or 0)>0 then
   Pair("本树前置投入："..(n.RequiredTabAEInvestment or 0).." AE / "..(n.RequiredTabTEInvestment or 0).." TE。",
    "Required tree investment: "..(n.RequiredTabAEInvestment or 0).." AE / "..(n.RequiredTabTEInvestment or 0).." TE.")
  end
  return true
 end
 GameTooltip:SetText(d.zh.." / "..d.en,1,.82,0)
 GameTooltip:AddLine(d.kind,.8,.8,.8)
 local saved=M.AERank(n.ID,M.aeMasks[M.slot+1] or 0)
 local draft=M.AERank(n.ID)
 local dirty=draft~=saved
 Pair("当前选择："..draft.." / "..#d.effects..(dirty and "（未保存）" or "（已保存）"),
  "Selected: "..draft.." / "..#d.effects..(dirty and " (unsaved)" or " (saved)"),dirty and .3 or 1,dirty and .8 or 1,1)
 Pair("服务器已保存："..saved.." / "..#d.effects,"Server-saved: "..saved.." / "..#d.effects,.7,.7,.7)
 if dirty then
  local zh,en
  if n.ID==7131 or n.ID==30884 or n.ID==29736 then
   zh="本天赋等级："..saved.." → "..draft.."；各级总收益见下方。"
   en="Talent rank: "..saved.." -> "..draft.."; total bonuses for each rank are listed below."
  elseif n.ID==6062 then
   zh="本天赋变化：条件增伤 "..(saved*10).."% → "..(draft*10).."%。"
   en="Change: conditional damage "..(saved*10).."% -> "..(draft*10).."%."
  elseif n.ID==6047 then
   zh="本天赋变化：最大法力加成 +"..(saved*5).."% → +"..(draft*5).."%；消耗降低 "..(saved*3).."% → "..(draft*3).."%。"
   en="Change: maximum mana bonus +"..(saved*5).."% -> +"..(draft*5).."%; cost reduction "..(saved*3).."% -> "..(draft*3).."%."
  elseif n.ID==6054 then
   zh="本天赋变化：施法打退降低0% → 70%；施法耗蓝后精神回蓝保留0% → 40%。"
   en="Change: pushback reduction 0% -> 70%; Spirit mana regeneration while casting 0% -> 40%."
  elseif n.ID==7092 then
   zh="本天赋变化：召唤法术减耗0% → 20%。"
   en="Change: summoning spell cost reduction 0% -> 20%."
  else
   zh="本天赋变化：未获得 → 学会"..d.zh.."。"
   en="Change: not granted -> learn "..d.en.."."
  end
  Pair(zh,en,.3,1,.4)
  Pair("以上为本次加点预览；保存成功并激活本方案后生效。",
   "Allocation preview only; applies after a successful save with this build active.",.3,.8,1)
 end
 if M.pending and M.operation=="save" then
  Pair("正在保存，等待服务器确认…","Saving; awaiting server confirmation...",1,.82,0)
 end
 if saved>0 then
  Pair("当前"..saved.."级收益："..d.effects[saved][1],"Current rank "..saved..": "..d.effects[saved][2],.3,1,.4)
 end
 if draft~=saved and draft>0 then
  Pair("待保存"..draft.."级收益："..d.effects[draft][1],"Draft rank "..draft.." (not saved): "..d.effects[draft][2],.3,.8,1)
 elseif saved<#d.effects then
  local nextRank=saved+1
  Pair("加至"..nextRank.."级后："..d.effects[nextRank][1],"At rank "..nextRank..": "..d.effects[nextRank][2],.3,1,.4)
 end
 Pair("限制："..d.limit[1],"Limits: "..d.limit[2],1,.3,.3,true)
 if n.ID==31154 then
  Requirement("前置：拟态守卫 "..M.AERank(29301).."/1（左侧通用树顶部中间）",
   "Mimic Ward "..M.AERank(29301).."/1 (Class tree, top-middle)",M.AERank(29301)>0)
  Requirement("前置：傀儡师之线 "..M.AERank(4004).."/1（最右竖列顶部，免费）",
   "Puppeteer's Threads "..M.AERank(4004).."/1 (far-right column, top; free)",M.AERank(4004)>0)
  Requirement("本方案绑定巫毒","Build bound to Voodoo",M.specs[M.slot+1]==0)
 else Requirement("前置："..d.path[1],"Prerequisite: "..d.path[2],PathReady(n.ID)) end
 if n.ID==6047 or n.ID==7092 then
  Pair("无额外技能等级门槛；通用树10级开放。","No additional spell-level requirement; the Class tree opens at level 10.")
 else Requirement("角色等级要求："..d.level,"Required character level: "..d.level,M.level>=d.level) end
 Pair("本批路径最早可达等级："..d.early.."（点数全部用于这条路径）。",
  "Earliest level on the available path: "..d.early.." (all needed points spent along this path).")
 Pair("每级费用："..(n.AECost or 0).." AE / "..(n.TECost or 0).." TE。","Cost per rank: "..(n.AECost or 0).." AE / "..(n.TECost or 0).." TE.",.8,.8,.8)
 if M.slot~=M.active then Pair("正在查看未激活方案，收益尚未作用于角色。","Viewing an inactive build; these bonuses are not currently applied.",1,.5,.2) end
 if not M.loaded then Pair("等待服务器同步，当前显示仅供核对。","Awaiting server synchronization; displayed allocation is not confirmed.",1,.5,.2) end
 Pair("左键加点；右键撤回未保存点数；保存后生效。","Left-click to add; right-click to undo unsaved points; save to apply.",.6,.6,.6)
 return true
end
