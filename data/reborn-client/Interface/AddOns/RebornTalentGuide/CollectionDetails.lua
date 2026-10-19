-- TG8A: optional revision annotations; never part of character talent authority.
local S=RebornTalentCollections
S.scenes={'未分类','练级','PVE','PVP','其他'};S.roles={'未分类','输出','坦克','治疗','支援'}
local fields={'scene','role','skills','rotation','notes'}
local labels={scene='用途',role='职责',skills='关键技能',rotation='联动顺序',notes='备注'}
local limits={skills=512,rotation=1024,notes=2048}
local function contains(list,value)for _,x in ipairs(list)do if value==x then return true end end end
function S.Profile(value)
 if value==nil then value={}end
 if type(value)~='table'then return nil,'方案资料格式无效'end
 for k in pairs(value)do if not labels[k]then return nil,'未知方案资料字段'end end
 local out={scene=value.scene==nil and'未分类'or value.scene,role=value.role==nil and'未分类'or value.role}
 if not contains(S.scenes,out.scene)or not contains(S.roles,out.role)then return nil,'用途或职责分类无效'end
 for key,limit in pairs(limits)do
  local text=value[key];if text==nil then text=''end
  if type(text)~='string'then return nil,labels[key]..'必须是文字'end
  text=text:gsub('\r\n','\n'):gsub('\r','\n')
  if #text>limit then return nil,labels[key]..'过长（上限'..limit..'字节）'end
  if text:find('|',1,true)then return nil,labels[key]..'只允许纯文字，不接受链接或颜色标记'end
  for i=1,#text do local b=text:byte(i);if(b<32 and b~=9 and b~=10)or b==127 then return nil,labels[key]..'含控制字符'end end
  out[key]=text
 end
 return out
end
function S.ProfileKey(value)
 local meta=S.Profile(value);if not meta then return nil end
 local out={};for _,field in ipairs(fields)do out[#out+1]=#meta[field]..':'..meta[field]end;return table.concat(out,';')
end
function S.FilterState()
 S.filters=S.filters or{};S.filters[S.class]=S.filters[S.class]or{query='',scene='全部',role='全部'};return S.filters[S.class]
end
function S.Find(class,query,scene,role)
 local list=S.List(class);local out={};query=type(query)=='string'and query:sub(1,128):lower():gsub('^%s+',''):gsub('%s+$','')or''
 for _,item in ipairs(list)do
  local latest=type(item.versions[#item.versions])=='table'and item.versions[#item.versions]or{};local meta=S.Profile(latest.profile)or S.Profile()
  if(not scene or scene=='全部'or meta.scene==scene)and(not role or role=='全部'or meta.role==role)then
   local text=table.concat({item.name,type(latest.name)=='string'and latest.name or'',meta.skills,meta.rotation,meta.notes},'\n'):lower()
   if query==''or text:find(query,1,true)then out[#out+1]=item end
  end
 end
 return out,#list
end
function S.CycleFilter(field)
 local state=S.FilterState();local values={'全部'};for _,v in ipairs(field=='scene'and S.scenes or S.roles)do values[#values+1]=v end
 local index=1;for i,v in ipairs(values)do if v==state[field]then index=i end end;state[field]=values[index%#values+1];S.RefreshList()
end
function S.SetProfile(field,value)
 local e=S.editor;if not e or e.readOnlyReason or not labels[field]then return end
 e.profile=e.profile or S.Profile();if e.profile[field]==value then return end
 S.Dirty();e.profile[field]=value
end
function S.CycleProfile(field)
 local e=S.editor;if not e or e.readOnlyReason then return end
 local values=field=='scene'and S.scenes or S.roles;local index=1
 for i,v in ipairs(values)do if(e.profile or{})[field]==v then index=i end end
 S.SetProfile(field,values[index%#values+1]);S.Refresh()
end
function S.RecommendationProfile(class)
 local meta=S.Profile();local G=RebornTalentGuide
 if class=='WARRIOR'then local p=RebornTalentGuideData.plans[G.selected];meta.scene=p.category;meta.role=p.title:find('防护')and'坦克'or'输出'
 elseif class=='PALADIN'then local p=RebornTalentGuidePaladinData.plans[RebornTalentGuidePaladin.selected or 1];meta.scene=p.category or'PVE';meta.role=p.role or({'治疗','坦克','输出'})[p.spec or 1]
 elseif class=='WITCHDOCTOR'then local i=G.WD.selected or 1;meta.scene=i==1 and'练级'or'PVE';meta.role=i==4 and'支援'or'输出'end
 return meta
end
function S.VersionSummary(id,version)
 local db=S.DB();local item=db and db.builds[id];local now=item and item.versions[version]
 if type(now)~='table'then return {'新收藏：保存后记录版本变化'}end
 local base=type(now.basedOn)=='number'and now.basedOn>=1 and now.basedOn<version and now.basedOn or version-1
 local before=item.versions[base];if not before then return {'初始版本'}end
 if type(before)~='table'or type(before.build)~='table'or type(now.build)~='table'then return {'历史结构损坏，原记录保留'}end
 local out={'基于版本 '..base..' → '..version};local count=0;local changes={}
 if S.Shape(before.build)and S.Shape(now.build)then
  for node,n in pairs(S.Nodes(now.build.class))do local a,z=before.build.ranks[node]or 0,now.build.ranks[node]or 0;if a~=z then count=count+1;changes[#changes+1]={id=node,text=n.name..'：'..a..' → '..z}end end
  table.sort(changes,function(a,b)return a.id<b.id end);out[#out+1]='配点变化：'..count..'项'
  for i=1,math.min(5,#changes)do out[#out+1]=changes[i].text end;if #changes>5 then out[#out+1]='另有 '..(#changes-5)..' 项配点变化'end
 else out[#out+1]='节点版本不兼容，仅比较资料'end
 if now.name~=before.name then out[#out+1]='名称已修改'end
 if now.build.level~=before.build.level then out[#out+1]='等级：'..tostring(before.build.level)..' → '..tostring(now.build.level) end
 if now.build.spec~=before.build.spec then out[#out+1]='专精选择已修改'end
 local a,b=S.Profile(before.profile),S.Profile(now.profile)
 if a and b then for _,key in ipairs(fields)do if a[key]~=b[key]then out[#out+1]=(key=='scene'or key=='role')and(labels[key]..'：'..a[key]..' → '..b[key])or(labels[key]..'已修改')end end end
 return out
end

function S.ShortName(text)
 local out={};local at,units=1,0
 while at<=#text do local b=text:byte(at);local size=b<128 and 1 or b<224 and 2 or b<240 and 3 or 4;local cost=size==1 and 1 or 2
  if units+cost>26 then return table.concat(out)..'…'end
  out[#out+1]=text:sub(at,at+size-1);at=at+size;units=units+cost
 end;return table.concat(out)
end
