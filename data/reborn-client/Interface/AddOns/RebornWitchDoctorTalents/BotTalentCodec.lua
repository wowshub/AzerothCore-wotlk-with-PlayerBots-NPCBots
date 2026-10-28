-- WD139A: exact nibble arithmetic. Decimal is only a legacy input boundary.
local M,L=RebornWDBotTalents,RebornWDNodeLayout
local alphabet="0123456789abcdef"
local function Nibble(c) return tonumber(c,16) end
function M.MaskParse(value)
 if type(value)=="number" then
  if value<0 or value>=9007199254740992 or value~=math.floor(value) then return nil end
  value=string.format("%.0f",value)
 end
 if type(value)~="string" then return nil end
 if value:sub(1,2)=="h:" then
  local hex=value:sub(3)
  if #hex~=L.hexSize or not hex:match("^[0-9a-f]+$") then return nil end
  if L.bits%4~=0 and Nibble(hex:sub(1,1))>=2^(L.bits%4) then return nil end
  return value
 end
 if #value==0 or #value>39 or not value:match("^%d+$") then return nil end
 local digits={};for i=1,L.hexSize do digits[i]=0 end
 for i=1,#value do
  local carry=tonumber(value:sub(i,i))
  for j=1,L.hexSize do local n=digits[j]*10+carry;digits[j]=n%16;carry=math.floor(n/16) end
  if carry~=0 then return nil end
 end
 local out="";for i=L.hexSize,1,-1 do out=out..alphabet:sub(digits[i]+1,digits[i]+1) end
 local result="h:"..out
 if not M.MaskFits(result,L.legacyBits) then return nil end
 return result
end
function M.MaskHex(value) local x=M.MaskParse(value);return x and x:sub(3) end
function M.MaskEqual(a,b) local x=M.MaskParse(a);return x~=nil and x==M.MaskParse(b) end
function M.MaskFits(value,bits)
 if bits<0 or bits>L.bits then return false end
 -- Do not call MaskParse for an already tagged value: decimal parsing calls us.
 local hex
 if type(value)=="string" and value:sub(1,2)=="h:" then hex=value:sub(3)
 else local v=M.MaskParse(value);if not v then return false end;hex=v:sub(3) end
 if #hex~=L.hexSize or not hex:match("^[0-9a-f]+$") then return false end
 for i=1,#hex do local allowed=math.max(0,math.min(4,bits-4*(#hex-i)));if Nibble(hex:sub(i,i))>=2^allowed then return false end end
 return true
end
function M.MaskRank(value,offset,width)
 local hex=M.MaskHex(value)
 if not hex or offset<0 or width<1 or offset+width>L.bits then return 0 end
 local rank=0
 for b=0,width-1 do local pos=offset+b;local j=#hex-math.floor(pos/4);rank=rank+(math.floor(Nibble(hex:sub(j,j))/2^(pos%4))%2)*2^b end
 return rank
end
function M.MaskSet(value,offset,width,rank)
 local hex=M.MaskHex(value)
 if not hex or offset<0 or width<1 or offset+width>L.bits or rank<0 or rank>=2^width or rank~=math.floor(rank) then return nil end
 for b=0,width-1 do
  local pos=offset+b;local j=#hex-math.floor(pos/4);local n=Nibble(hex:sub(j,j));local power=2^(pos%4)
  n=n+(math.floor(rank/2^b)%2-math.floor(n/power)%2)*power
  hex=hex:sub(1,j-1)..alphabet:sub(n+1,n+1)..hex:sub(j+1)
 end
 return "h:"..hex
end
function M.LayoutValid(value)
 if not M.MaskFits(value,L.bits) then return false end
 for i=0,L.count-1 do local n=L.nodes[i];if M.MaskRank(value,n.offset,n.width)>n.maximum then return false end end
 return true
end

-- A snapshot becomes visible atomically only after header, all pieces and end.
local snapshot,lastSequence=nil,0
function M.Receive139(msg)
 if not msg:match("^WD139") then return msg,false end
 if msg:match("^WD139X|") then
  snapshot=nil;M.layoutReady=false;M.loaded=false;M.pending=false;M.operation=nil
  M.message="天赋布局版本不匹配，请更新服务端和插件后刷新；草稿保留"
  if M.changed then M.changed() end
  return nil,true
 end
 if msg:match("^WD139B|") then
  local f={};for x in msg:gmatch("[^|]+") do f[#f+1]=x end
  if #f~=19 or f[3]~=tostring(L.version) or f[4]~=L.hash or tonumber(f[19])~=L.hexSize then return M.Receive139("WD139X|layout") end
  local seq=tonumber(f[2]);if not seq or seq<=lastSequence or seq>4294967295 then return nil,true end
  snapshot={seq=seq,fields=f,pieces={{},{},{}},time=GetTime()}
  return nil,true
 end
 if not snapshot or GetTime()-snapshot.time>5 then snapshot=nil;return nil,true end
 local seq,slot,part,total,hex=msg:match("^WD139M|(%d+)|(%d+)|(%d+)|(%d+)|([0-9a-f]+)$")
 if seq then
  seq,slot,part,total=tonumber(seq),tonumber(slot),tonumber(part),tonumber(total)
  if seq~=snapshot.seq then return nil,true end
  if slot>2 or total~=math.ceil(L.hexSize/80) or part>=total or #hex~=math.min(80,L.hexSize-part*80) then snapshot=nil;return nil,true end
  local pieces=snapshot.pieces[slot+1]
  if pieces[part+1] and pieces[part+1]~=hex then snapshot=nil;return nil,true end
  pieces[part+1]=hex;return nil,true
 end
 seq=tonumber(msg:match("^WD139E|(%d+)$"))
 if not seq or seq~=snapshot.seq then return nil,true end
 local masks={}
 for slot=1,3 do
  local pieces=snapshot.pieces[slot]
  for part=1,math.ceil(L.hexSize/80) do if not pieces[part] then snapshot=nil;return nil,true end end
  masks[slot]="h:"..table.concat(pieces)
  if not M.LayoutValid(masks[slot]) then snapshot=nil;return nil,true end
 end
 local f=snapshot.fields
 local base="WD16";for i=5,16 do base=base.."|"..f[i] end
 base=base.."|"..table.concat(masks,"|").."|"..f[17].."|"..f[18]
 lastSequence=seq;snapshot=nil;M.layoutReady=true
 return base,true
end

function M.ResetBotCodec() snapshot=nil;lastSequence=0 end
