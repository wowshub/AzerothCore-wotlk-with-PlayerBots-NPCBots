-- TG8B: fixed, bounded data format. Never evaluate imported Lua, macros or commands.
local S=RebornTalentCollections
S.Share={header='RTCB1',rules='REBORN-TALENTS-1',limit=32768}
local X=S.Share
local keys={'rules','name','class','mode','level','spec','source_version','layout','ranks','scene','role','skills','rotation','notes'}
local hexLimits={name=96,layout=8192,scene=32,role=32,skills=512,rotation=1024,notes=2048}
local allowed={};for _,key in ipairs(keys)do allowed[key]=true end
local function integer(text,lo,hi)
 if type(text)~='string'or not text:match('^%d+$')or #text>10 or(#text>1 and text:sub(1,1)=='0')then return nil end
 local n=tonumber(text);if not n or n<lo or n>hi then return nil end;return n
end
local function utf8(text)
 local i=1
 while i<=#text do
  local a=text:byte(i);local count,lo,hi=0,128,191
  if a<128 then count=0
  elseif a>=194 and a<=223 then count=1
  elseif a>=224 and a<=239 then count=2;if a==224 then lo=160 elseif a==237 then hi=159 end
  elseif a>=240 and a<=244 then count=3;if a==240 then lo=144 elseif a==244 then hi=143 end
  else return false end
  if i+count>#text then return false end
  for j=1,count do local b=text:byte(i+j);if b<(j==1 and lo or 128)or b>(j==1 and hi or 191)then return false end end
  i=i+count+1
 end;return true
end
local function hex(text)return(text:gsub('.',function(c)return string.format('%02x',c:byte())end))end
local function unhex(text,limit)
 if #text>limit*2 or #text%2~=0 or not text:match('^[0-9a-f]*$')then return nil end
 return(text:gsub('%x%x',function(c)return string.char(tonumber(c,16))end))
end
function X.Checksum(text)
 local a,b=1,0;for i=1,#text do a=(a+text:byte(i))%65521;b=(b+a)%65521 end
 return string.format('%08x',b*65536+a)
end
local function fieldsValid(name,build,profile,version)
 if type(name)~='string'or #name==0 or #name>96 or #name:gsub('%s','')==0 or name:find('[%c|]')or not utf8(name)then return nil,'方案名称格式无效'end
 local nodes,why=S.Shape(build);if not nodes then return nil,why end
 local meta,err=S.Profile(profile);if not meta then return nil,err end
 for _,key in ipairs({'scene','role','skills','rotation','notes'})do if not utf8(meta[key])then return nil,'方案资料不是有效的UTF-8文字'end end
 if not integer(tostring(version),1,S.historyLimit)then return nil,'来源版本无效'end
 if build.spec~=nil and not integer(tostring(build.spec),0,2)then return nil,'专精标记无效'end
 if #build.layout>hexLimits.layout then return nil,'节点布局过长，不能分享'end
 return meta
end
function X.ContentKey(name,build,profile)
 local fingerprint=S.Fingerprint(build);local meta=S.ProfileKey(profile);if not meta then return nil end
 return #name..':'..name..#fingerprint..':'..fingerprint..#meta..':'..meta
end
function X.Encode(name,build,profile,version)
 version=version or 1
 local meta,why=fieldsValid(name,build,profile,version);if not meta then return nil,why end
 local ids={};for id,rank in pairs(build.ranks)do if rank>0 then ids[#ids+1]=id end end;table.sort(ids)
 local ranks={};for _,id in ipairs(ids)do ranks[#ranks+1]=id..':'..build.ranks[id]end
 local data={rules=X.rules,name=hex(name),class=build.class,mode=build.mode,level=tostring(build.level),spec=build.spec==nil and'-'or tostring(build.spec),source_version=tostring(version),layout=hex(build.layout),ranks=table.concat(ranks,',')}
 for _,key in ipairs({'scene','role','skills','rotation','notes'})do data[key]=hex(meta[key])end
 local lines={X.header};for _,key in ipairs(keys)do lines[#lines+1]=key..'='..data[key]end
 local body=table.concat(lines,'\n');local text=body..'\ncheck='..X.Checksum(body)
 if #text>X.limit then return nil,'分享内容过长，请精简方案资料'end
 return text
end
function X.Decode(text)
 if type(text)~='string'or #text>X.limit then return nil,'分享文本为空或超过长度限制'end
 text=text:gsub('\r\n','\n'):gsub('^%s+',''):gsub('%s+$','')
 local body,checksum=text:match('^(.*)\ncheck=([0-9a-f]+)$')
 if not body or #checksum~=8 or X.Checksum(body)~=checksum then return nil,'分享文本不完整或校验不符，请重新复制全部内容'end
 local lines={};for line in(body..'\n'):gmatch('(.-)\n')do lines[#lines+1]=line;if #lines>#keys+1 then return nil,'分享字段过多'end end
 if lines[1]~=X.header then return nil,'不支持的分享格式版本'end
 if #lines~=#keys+1 then return nil,'分享字段数量不完整'end
 local data={}
 for i=2,#lines do
  local key,value=lines[i]:match('^([a-z_]+)=(.*)$')
  if not key or not allowed[key]or data[key]~=nil then return nil,'分享中含未知或重复字段'end
  data[key]=value
 end
 for _,key in ipairs(keys)do if data[key]==nil then return nil,'分享缺少必要字段'end end
 if data.rules~=X.rules then return nil,'分享规则版本不兼容'end
 if data.class~='WARRIOR'and data.class~='PALADIN'and data.class~='WITCHDOCTOR'and data.class~='HUNTER'and data.class~='ROGUE'and data.class~='PRIEST'and data.class~='DEATHKNIGHT'and data.class~='SHAMAN'and data.class~='MAGE'and data.class~='WARLOCK'and data.class~='DRUID'then return nil,'该职业尚未接入收藏分享'end
 local level=integer(data.level,10,80);local version=integer(data.source_version,1,S.historyLimit)
 local spec=data.spec~='-'and integer(data.spec,0,2)or nil
 if not level or not version or(data.spec~='-'and spec==nil)then return nil,'等级、专精或来源版本无效'end
 local decoded={}
 for key,limit in pairs(hexLimits)do decoded[key]=unhex(data[key],limit);if decoded[key]==nil then return nil,'分享文字或布局编码无效'end end
 local ranks={};local previous,count=0,0
 if data.ranks~=''then
  for token in(data.ranks..','):gmatch('(.-),')do
   count=count+1;if count>200 then return nil,'节点数量超过限制'end
   local id,rank=token:match('^(%d+):(%d+)$');id=integer(id,1,2147483647);rank=integer(rank,1,20)
   if not id or not rank or id<=previous then return nil,'节点点数格式、顺序或重复记录无效'end
   ranks[id]=rank;previous=id
  end
 end
 local build={schema=1,class=data.class,mode=data.mode,level=level,spec=spec,layout=decoded.layout,ranks=ranks}
 local profile={scene=decoded.scene,role=decoded.role,skills=decoded.skills,rotation=decoded.rotation,notes=decoded.notes}
 local meta,why=fieldsValid(decoded.name,build,profile,version);if not meta then return nil,why end
 return {name=decoded.name,build=build,profile=meta,sourceVersion=version,raw=text,key=X.ContentKey(decoded.name,build,meta)}
end
function X.Duplicate(parsed)
 local fingerprint=S.Fingerprint(parsed.build);local profile=S.ProfileKey(parsed.profile)
 for _,item in ipairs(S.List(parsed.build.class))do for i=#item.versions,1,-1 do
  local rev=item.versions[i]
  if type(rev)=='table'and rev.name==parsed.name and type(rev.build)=='table'and rev.build.layout==parsed.build.layout then
   local ok,key=pcall(S.Fingerprint,rev.build)
   if ok and key==fingerprint and S.ProfileKey(rev.profile)==profile then return item.id,i end
  end
 end end
end
function X.Preview(text)
 local parsed,why=X.Decode(text);if not parsed then return nil,why end
 parsed.valid,parsed.validation=S.Validate(parsed.build)
 parsed.duplicateId,parsed.duplicateVersion=X.Duplicate(parsed)
 return parsed
end
function X.Import(preview)
 if type(preview)~='table'or type(preview.raw)~='string'then return nil,'请先检查导入文本'end
 local parsed,why=X.Decode(preview.raw);if not parsed then return nil,why end
 if parsed.key~=preview.key then return nil,'预览内容已改变，请重新检查'end
 local id,version=X.Duplicate(parsed);if id then return id,version,true end
 local newId,newVersion=S.Commit(parsed.name,parsed.build,nil,nil,nil,parsed.profile)
 if not newId then return nil,newVersion end
 -- Provenance is attached once, as part of creating this new local revision.
 -- Duplicate imports never amend the existing version or its provenance.
 S.DB().builds[newId].versions[newVersion].origin={kind='share',format=X.header,sourceVersion=parsed.sourceVersion}
 return newId,newVersion,false
end
