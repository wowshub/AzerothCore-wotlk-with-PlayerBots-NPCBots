assert(loadfile(arg[5]))()
local M=RebornWD8
local low23=65024+2*2^32+2^17
for i=17,27 do low23=low23+(i==21 and 2*2^23 or 2^(i>=22 and i+3 or i+2)) end
local v,p,d,o=2^41,2^42,2^40,2^39
M.level=80;M.teBudget=35;M.aeBudget=36;M.specs[1]=0
assert(M.AERank(29768,v)==1 and M.AERank(6057,p)==1)
assert(M.AEValid(low23+v));assert(M.AEValid(low23+v+p));assert(not M.AEValid(low23+p))
assert(not M.AEValid(low23-2^30+v+p+d+o));assert(M.AEValid(low23+v+p+d+o))
M.level=56;assert(not M.AEValid(low23+v));M.level=57;assert(M.AEValid(low23+v))
M.teBudget=24;assert(not M.AEValid(low23+v+p));M.teBudget=25;assert(M.AEValid(low23+v+p))
M.specs[1]=1;assert(not M.AEValid(low23+v));M.specs[1]=0
assert(not M.AEValid(2^52));assert(M.TESpent(low23+v+p)==25)
M.level=80;M.draftAE=low23+v+p;M.aeMasks[1]=low23;M.aeDirty=true;M.dirty=true;M.pending=nil
local request;M.Request=function(s)request=s end;M.Save()
assert(request and request:match(' '..string.format('%.0f',low23+v+p)..'$'))
for _,id in ipairs({29768,6057})do assert(M.AETooltip({ID=id,AECost=0,TECost=1}))end
print('PASS WD93 43-bit save/decode, Voice/Price dependency, four-node tier boundary, budget/spec/level and tooltip')

local g=2^43;local low8=65024
M.level=27;M.teBudget=9;M.aeBudget=9;M.specs[1]=0
assert(M.AERank(30596,g)==1 and M.TESpent(low8+g)==9)
assert(M.AEValid(low8+g));M.level=26;assert(not M.AEValid(low8+g));M.level=27
M.teBudget=8;assert(not M.AEValid(low8+g));M.teBudget=109;assert(M.AEValid(low8+g))
assert(not M.AEValid(low8-512+g));assert(not M.AEValid(low8-512+2^19+g))
M.level=57;assert(M.AEValid(low23-2^30+g+v+p))
M.specs[1]=1;assert(not M.AEValid(low8+g));M.specs[1]=0
M.level=85;M.aeBudget=56;M.teBudget=55;M.draftAE=low23+v+p+g;M.aeMasks[1]=low23+v+p;M.aeDirty=true;M.dirty=true;M.pending=nil
M.Save();assert(request and request:match(' '..string.format('%.0f',low23+v+p+g)..'$'))
assert(M.AETooltip({ID=30596,AECost=0,TECost=1}));assert(not M.AEValid(2^52))
print('PASS WD96 44-bit Grasp, level27/foundation8/TE9, saved-decimal payload, next-tier contribution and GM budgets')

local j,a,h=2^44,2^46,2^47
local class9=123+2*j -- 1+1+2+1+1+1 legacy AE =7, Juju rank2 =2
M.level=80;M.aeBudget=36;M.teBudget=35;M.specs[1]=0;M.pending=nil
assert(M.AERank(7088,2*j)==2 and M.AERank(30147,a)==1 and M.AERank(4132,h)==1)
assert(M.AESpent(class9)==9 and M.AESpent(class9+a+h)==11 and M.TESpent(class9+a+h)==0)
assert(M.AEValid(j));assert(M.AEValid(2*j));assert(not M.AEValid(3*j))
assert(M.AEValid(class9+a+h));assert(not M.AEValid(class9-j+a+h))
M.aeBudget=10;assert(not M.AEValid(class9+a+h));M.aeBudget=11
M.level=27;assert(not M.AEValid(class9+a));assert(M.AEValid(class9+h));M.level=28;assert(M.AEValid(class9+a))
M.level=80;M.specs[1]=1;assert(M.AEValid(class9+a+h));assert(not M.AEValid(low8+g));M.specs[1]=0
M.aeMasks[1]=class9;M.draftAE=class9+a+h;M.aeDirty=true;M.dirty=true;M.pending=nil
local request97;M.Request=function(s) request97=s end;M.Save()
assert(request97 and request97:match(' '..string.format('%.0f',class9+a+h)..'$'))
for _,id in ipairs({7088,30147,4132})do assert(M.AETooltip({ID=id,AECost=1,TECost=0}))end
assert(not M.AEValid(2^52))
print('PASS WD97B 48-bit Class rank/budget/foundation/level/spec/protocol/tooltip scenarios')

local war,mal,soul=2^48,2^49,2^50
M.level=80;M.teBudget=35;M.aeBudget=36;M.specs[1]=0
assert(M.AERank(31349,war)==1 and M.AERank(29929,mal)==1 and M.AERank(6055,soul)==1)
assert(M.TESpent(low23+war+mal+soul)==26 and M.AESpent(low23+war+mal+soul)==0)
assert(M.AEValid(low23+war+mal+soul))
M.level=58;assert(not M.AEValid(low8+war));assert(not M.AEValid(low23+soul));M.level=59
assert(M.AEValid(low8+war));assert(not M.AEValid(low8-512+war))
assert(not M.AEValid(low23-2^30+mal+soul))
assert(M.AEValid(low23-2^30+war+mal+soul))
M.teBudget=25;assert(not M.AEValid(low23+war+mal+soul));M.teBudget=26
M.specs[1]=1;assert(not M.AEValid(low23+war+mal+soul));assert(M.AEValid(class9+a+h));M.specs[1]=0
M.level=80;M.aeBudget=36;M.teBudget=35;M.draftAE=low23+war+mal+soul;M.aeMasks[1]=low23;M.aeDirty=true;M.dirty=true;M.pending=nil
local req98;M.Request=function(s)req98=s end;M.Save()
assert(req98 and req98:match(' '..string.format('%.0f',low23+war+mal+soul)..'$'))
for _,id in ipairs({31349,29929,6055})do assert(M.AETooltip({ID=id,AECost=0,TECost=1}))end
print('PASS WD98 51-bit, three Voodoo nodes, TE budgets, level59, tier anti-bootstrap, spec, save and tooltip')

local adept=2^51
M.level=50;M.aeBudget=0;M.teBudget=0;M.specs[1]=0
assert(M.AERank(11133,adept)==1)
assert(M.AEValid(adept) and M.AESpent(adept)==0 and M.TESpent(adept)==0)
M.level=49;assert(not M.AEValid(adept));M.level=50
M.specs[1]=1;assert(not M.AEValid(adept));M.specs[1]=0
M.level=80;M.aeBudget=36;M.teBudget=35
assert(M.AEValid(low23+war+mal+soul+adept))
assert(M.TESpent(low23+war+mal+soul+adept)==26)
M.draftAE=low23+war+mal+soul+adept;M.aeMasks[1]=low23;M.aeDirty=true;M.dirty=true;M.pending=nil
local sent;M.Request=function(s)sent=s end;M.Save()
assert(sent and sent:match(' '..string.format('%.0f',M.draftAE)..'$'))
assert(M.AETooltip({ID=11133,AECost=0,TECost=0}))
print('PASS WD99 52-bit: free node, level50, spec ownership, cumulative TE, exact decimal save, tooltip')

local function eq(a,b) assert(M.MaskEqual(a,b),tostring(a).." != "..tostring(b)) end
for _,v in ipairs({"0","1","4294967295","4294967296","9007199254740991","9007199254740992","9007199254740993","18014398509481985","36028797018963967","18446744073709551615"}) do
 assert(M.MaskDecimal(M.MaskParse(v))==v)
end
for _,v in ipairs({"","-1","1.0","1e4","340282366920938463463374607431768211456","123456789012345678901234567890123456789012",-1,0.5,9007199254740992})do assert(M.MaskParse(v)==nil) end
assert(M.MaskFits("36028797018963967",55) and not M.MaskFits("36028797018963968",55))
local class9=35184372088955
M.level=85;M.aeBudget=36;M.teBudget=35;M.specs={0,1,2};M.slot=0;M.modern=true;M.loaded=true;M.pending=nil
M.CanEdit=function()return true end
local count=0
for bits=0,7 do
 for _,low in ipairs({"0","1","35184372088955","2251799813685249","4503599627370495"})do
  local mask=M.MaskParse(low)
  for i=0,2 do mask=M.MaskSet(mask,52+i,1,math.floor(bits/2^i)%2) end
  local copy=M.MaskParse(M.MaskDecimal(mask));eq(mask,copy)
  for i,id in ipairs({7033,6051,6048})do assert(M.AERank(id,copy)==math.floor(bits/2^(i-1))%2)end
  assert(M.AERank(29744,copy)==M.AERank(29744,M.MaskParse(low)))
  for i=0,2 do copy=M.MaskSet(copy,52+i,1,0) end
  eq(copy,M.MaskParse(low));count=count+1
 end
end
local full=class9
for i=52,54 do full=M.MaskSet(full,i,1,1)end
assert(M.AESpent(full)==12 and M.TESpent(full)==0 and M.AEValid(full))
M.level=31;assert(not M.AEValid(full));M.level=32;assert(M.AEValid(full))
local swift=M.MaskSet(class9,53,1,1);M.level=27;assert(not M.AEValid(swift));M.level=28;assert(M.AEValid(swift))
M.level=85;assert(not M.AEValid(M.MaskSet(full,44,2,1))) -- eight foundation, cannot bootstrap
M.aeBudget=11;assert(not M.AEValid(full));M.aeBudget=12;assert(M.AEValid(full))
for slot=0,2 do
 M.slot=slot;M.aeMasks={class9,class9,class9};M.draftAE=class9;M.pending=nil
 for _,id in ipairs({7033,6051,6048})do M.SetNode(id,1) end
 eq(M.draftAE,full);assert(M.aeDirty)
 local payload;M.Request=function(v)payload=v end;M.Save()
 assert(payload==".wd67save "..M.revision.." "..slot.." "..M.MaskDecimal(full))
 M.aeMasks[slot+1]=full;M.AEOnReply('save',true);assert(not M.aeDirty)
 M.SetNode(6048,0);eq(M.draftAE,full) -- cannot refund saved rank
end
M.slot=0;M.aeDirty=false;M.pending=nil
local dec=M.MaskDecimal(full)
M.listener.OnEvent(nil,'CHAT_MSG_SYSTEM','WD16|ok|99|0|0|0|1|2|85|1|71|3|1|'..dec..'|'..dec..'|'..dec..'|36|35')
assert(M.revision==99)
for i=1,3 do eq(M.aeMasks[i],full)end
eq(M.draftAE,full)
M.aeDirty=true;M.draftAE=M.MaskSet(full,54,1,0);M.AEOnReply('refresh',false);assert(M.aeDirty)
M.draftAE=full;M.AEOnReply('refresh',false);assert(not M.aeDirty)
local revision=M.revision
M.listener.OnEvent(nil,'CHAT_MSG_SYSTEM','WD16|ok|100|0|0|0|1|2|85|1|71|3|1|1237940039285380274899124224|0|0|36|35');assert(M.revision==revision)
for _,id in ipairs({7033,6051,6048})do assert(M.AETooltip({ID=id,AECost=1,TECost=0}))end
print('PASS WD100 '..count..' exact mask combinations; >2^53 odd values, three slots, events, dirty state, decimal save, foundation, levels, budgets, tooltips')

M.level=80;M.slot=1;M.specs={0,1,2};M.aeBudget=36;M.teBudget=35;M.pending=nil;M.aeMasks={0,0,0};M.draftAE=0
local ids={7131,30884,29736}
local count104=0
for a=0,2 do for b=0,2 do for c=0,2 do
 local mask=1
 for j,r in ipairs({a,b,c})do mask=M.MaskSet(mask,55+2*(j-1),2,r)end
 local dec=M.MaskDecimal(mask);assert(M.MaskDecimal(M.MaskParse(dec))==dec)
 for j,r in ipairs({a,b,c})do assert(M.AERank(ids[j],mask)==r)end
 assert(M.AESpent(mask)==1 and M.TESpent(mask)==a+b+c and M.AEValid(mask))
 for j=1,3 do mask=M.MaskSet(mask,55+2*(j-1),2,0)end
 assert(M.MaskEqual(mask,1));count104=count104+1
end end end
local rank1=0
for j=1,3 do rank1=M.MaskSet(rank1,55+2*(j-1),2,1)end
local rank2=0
for j=1,3 do rank2=M.MaskSet(rank2,55+2*(j-1),2,2)end
assert(M.MaskDecimal(rank2)=='1513209474796486656')
M.teBudget=5;assert(not M.AEValid(rank2));M.teBudget=6;assert(M.AEValid(rank2))
M.aeBudget=0;assert(M.AEValid(rank2)) -- TE never charges AE
M.level=9;assert(not M.AEValid(rank1));M.level=80
for _,spec in ipairs({0,2,3})do M.specs[2]=spec;assert(not M.AEValid(rank1))end
M.specs[2]=1
assert(not M.AEValid(M.MaskSet(rank1,51,1,1))) -- free Voodoo identity cannot mix
assert(not M.AEValid(M.MaskSet(rank1,55,2,3)))
assert(not M.AEValid('1237940039285380274899124224'))
M.draftAE=0;M.aeMasks[2]=0
for _,id in ipairs(ids)do M.SetNode(id,1);assert(M.AERank(id)==1);M.SetNode(id,0);assert(M.AERank(id)==0);M.SetNode(id,2)end
assert(M.MaskEqual(M.draftAE,rank2))
local payload104;M.Request=function(v)payload104=v end
M.Save();assert(payload104=='.wd67save '..M.revision..' 1 1513209474796486656')
M.aeMasks[2]=rank2;M.AEOnReply('save',true);assert(not M.aeDirty)
for _,id in ipairs(ids)do M.SetNode(id,0);assert(M.AERank(id)==2);assert(M.AETooltip({ID=id,AECost=0,TECost=1}))end
M.aeDirty=false;M.dirty=false;M.pending=nil
M.listener.OnEvent(nil,'CHAT_MSG_SYSTEM','WD16|ok|105|1|1|0|1|2|80|1|71|3|1|0|1513209474796486656|0|36|35')
assert(M.revision==105 and M.MaskEqual(M.aeMasks[2],rank2))
assert(M.IsAENode(7131) and not M.IsAENode(6044))
print('PASS WD104A '..count104..' Brewing rank combinations; 61bit exact decimal, 3 nodes, budgets, spec, rank3, draft undo, saved no-refund, reply and tooltips')
