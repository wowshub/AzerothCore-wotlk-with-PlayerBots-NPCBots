-- TG5A. Account-local library of intentions, never a character's confirmed talent state.
RebornTalentCollections={schema=1,limit=1,historyLimit=40}
local S=RebornTalentCollections
local G=RebornTalentGuide;local PD=RebornTalentGuidePaladinData;local WD=RebornTalentGuideWDData
function S.Copy(t)if type(t)~='table'then return t end;local n={};for k,v in pairs(t)do n[k]=S.Copy(v)end;return n end
function S.Now()return time and time()or 0 end
function S.DB()
 if RebornTalentCollectionsDB==nil then RebornTalentCollectionsDB={schema=1,nextId=1,builds={},receipts={}}end
 local d=RebornTalentCollectionsDB
 if type(d)~='table'or d.schema~=1 or type(d.builds)~='table'or type(d.receipts)~='table'or type(d.nextId)~='number'or d.nextId<1 or d.nextId>1000000000 or d.nextId%1~=0 then return nil,'收藏库格式不受支持；原数据未覆盖'end
 return d
end
-- Native class adapters share storage, never character-authoritative ranks.
function S.NativeData(class)
 if class=='WARRIOR'then return RebornTalentGuideData elseif class=='PALADIN'then return PD elseif class=='HUNTER'then return RebornTalentGuideHunterData elseif class=='ROGUE'then return RebornTalentGuideRogueData elseif class=='PRIEST'then return RebornTalentGuidePriestData elseif class=='DEATHKNIGHT'then return RebornTalentGuideDeathKnightData elseif class=='SHAMAN'then return RebornTalentGuideShamanData end
end
function S.NativeEngine(class)
 if class=='WARRIOR'then return RebornTalentGuideWarriorCollection elseif class=='PALADIN'then return RebornTalentGuidePaladin elseif class=='HUNTER'then return RebornTalentGuideHunter elseif class=='ROGUE'then return RebornTalentGuideRogue elseif class=='PRIEST'then return RebornTalentGuidePriest elseif class=='DEATHKNIGHT'then return RebornTalentGuideDeathKnight elseif class=='SHAMAN'then return RebornTalentGuideShaman end
end
function S.ActiveNativeJob()
 local R=RebornTalentGuideWarriorCollection;local P=RebornTalentGuidePaladin
 if R.job then return R.job,R elseif P.job then return P.job,P elseif RebornTalentGuideHunter and RebornTalentGuideHunter.job then return RebornTalentGuideHunter.job,RebornTalentGuideHunter elseif RebornTalentGuideRogue and RebornTalentGuideRogue.job then return RebornTalentGuideRogue.job,RebornTalentGuideRogue elseif RebornTalentGuidePriest and RebornTalentGuidePriest.job then return RebornTalentGuidePriest.job,RebornTalentGuidePriest elseif RebornTalentGuideDeathKnight and RebornTalentGuideDeathKnight.job then return RebornTalentGuideDeathKnight.job,RebornTalentGuideDeathKnight elseif RebornTalentGuideShaman and RebornTalentGuideShaman.job then return RebornTalentGuideShaman.job,RebornTalentGuideShaman end
end
function S.StopOwned(reason)
 local job,engine=S.ActiveNativeJob();local T=G.TalentCenter
 if job and(job.owner==S.frame or(T and job.owner==T.frame))then engine.Stop(reason)end
end
function S.Class()local _,c,id=UnitClass('player');return id==13 and'WITCHDOCTOR'or c end
function S.Nodes(class)
 local out={}
 local data=S.NativeData(class)
 if data then for t,tree in ipairs(data.trees)do for i,n in ipairs(tree)do out[n.id]={max=n.max,name=n.name,tree=t,index=i,raw=n}end end
 elseif class=='WITCHDOCTOR'then for id,n in pairs(WD.nodes)do out[id]={max=n.max,name=n.name,raw=n}end end
 return out
end
function S.Layout(class)
 if class=='WITCHDOCTOR'then return WD.layoutHash end
 local data=S.NativeData(class);if not data then return nil end
 local rows={};for _,tree in ipairs(data.trees)do for _,n in ipairs(tree)do rows[#rows+1]=table.concat({n.id,n.max,n.row,n.col,n.dep,n.depRank,table.concat(n.spells,',')},':')end end
 return table.concat(rows,',')
end
function S.Shape(b)
 if type(b)~='table'or b.schema~=1 or(not S.NativeData(b.class)and b.class~='WITCHDOCTOR')or type(b.level)~='number'or b.level<10 or b.level>(b.class=='WITCHDOCTOR'and 255 or 80)or b.level%1~=0 or type(b.ranks)~='table'then return nil,'方案职业、等级或结构无效'end
 if b.layout~=S.Layout(b.class)then return nil,'节点版本已改变：请重新核对后另存，不能直接应用'end
 if b.mode~=(b.class~='WITCHDOCTOR'and'NATIVE'or'WD_AETE')then return nil,'职业配点模式不匹配'end
 if b.class=='WITCHDOCTOR'and(b.spec~=0 and b.spec~=1 and b.spec~=2)then return nil,'巫医专精无效'end
 local nodes=S.Nodes(b.class);local count=0
 for id,rank in pairs(b.ranks)do count=count+1;if count>200 or type(id)~='number'or not nodes[id]or type(rank)~='number'or rank%1~=0 or rank<0 or rank>nodes[id].max then return nil,'含未知节点、非整数或超上限点数：'..tostring(id)end end
 return nodes
end
function S.NativePlan(b)
 local plan={title='收藏方案',ranks={{},{},{}},split={0,0,0}}
 local data=S.NativeData(b.class);if not data then return nil end
 for t,tree in ipairs(data.trees)do for i,n in ipairs(tree)do local rank=b.ranks[n.id]or 0;plan.ranks[t][i]=rank;plan.split[t]=plan.split[t]+rank end end
 return plan
end
function S.Mask(b)
 local M,L=G.WD.Ready();if not M then return nil,L end
 local mask=M.MaskParse(0)
 for id,rank in pairs(b.ranks)do local row=L.nodes[L.index[id]];if not row then return nil,'巫医布局缺少节点'end;mask=M.MaskSet(mask,row.offset,row.width,rank)end
 return mask
end
function S.Validate(b)
 local nodes,why=S.Shape(b);if not nodes then return false,why end
 local data=S.NativeData(b.class)
 if data then
  local plan=S.NativePlan(b);local total=plan.split[1]+plan.split[2]+plan.split[3]
  if total>b.level-9 then return false,'超出等级点数预算：'..total..'/'..(b.level-9)end
  local empty={{},{},{}};for t,tree in ipairs(data.trees)do for i in ipairs(tree)do empty[t][i]=0 end end
  local queue,err=S.NativeEngine(b.class).Queue(plan,empty);if not queue then return false,err end
  return true,'前置和预算有效；'..table.concat(plan.split,'/')..'，总计 '..total..'/'..(b.level-9)
 end
 local mask,err=S.Mask(b);if not mask then return false,err end
 local ae,te=G.WD.Budget(b.level);local ok,msg=G.WD.Validate(mask,b.spec,b.level,ae,te)
 return ok,msg or('前置/互斥有效；AE '..RebornWD8.AESpent(mask)..'/'..ae..'，TE '..RebornWD8.TESpent(mask)..'/'..te)
end
function S.Blank(class,level,spec)return{schema=1,class=class,mode=class~='WITCHDOCTOR'and'NATIVE'or'WD_AETE',layout=S.Layout(class),level=level or UnitLevel('player'),spec=spec or 0,ranks={}}end
function S.Capture(class)
 if S.Class()~=class then return nil,'只能捕获自己的当前职业'end
 if not S.NativeData(class)and class~='WITCHDOCTOR'then return nil,'该职业收藏尚未接入'end
 local b=S.Blank(class,UnitLevel('player'))
 local data=S.NativeData(class)
 if data then
  local ranks,why=S.NativeEngine(class).Scan();if not ranks then return nil,why end
  for t,tree in ipairs(data.trees)do for i,n in ipairs(tree)do if ranks[t][i]>0 then b.ranks[n.id]=ranks[t][i]end end end
 else
  local M,why=G.WD.Ready();if not M then return nil,why end
  if not M.loaded or not M.layoutReady or M.pending or not M.modern or not M.aeMasks[M.active+1]or M.specs[M.active+1]==3 then return nil,'请先在巫医面板同步已激活、已绑定方案'end
  b.spec=M.specs[M.active+1]
  for id in pairs(WD.nodes)do local rank=M.AERank(id,M.aeMasks[M.active+1]);if rank>0 then b.ranks[id]=rank end end
 end
 return b
end
function S.Recommendation(class)
 if class=='HUNTER'or class=='ROGUE'or class=='PRIEST'or class=='DEATHKNIGHT'or class=='SHAMAN'then
  local H=S.NativeEngine(class);local p,why=H.Build(H.selected or 1,H.previewCurrent~=false and UnitLevel('player')or H.previewLevel)
  if not p then return nil,why end
  local b=S.Blank(class,p.level);for t,tree in ipairs(S.NativeData(class).trees)do for i,n in ipairs(tree)do if p.ranks[t][i]>0 then b.ranks[n.id]=p.ranks[t][i]end end end
  return b,p.title
 end
 local data=S.NativeData(class)
 if data then
  local p=data.plans[class=='WARRIOR'and G.selected or(RebornTalentGuidePaladin.selected or 1)];local b=S.Blank(class,80)
  for t,tree in ipairs(data.trees)do for i,n in ipairs(tree)do if p.ranks[t][i]>0 then b.ranks[n.id]=p.ranks[t][i]end end end
  return b,p.title
 end
 if class~='WITCHDOCTOR'then return nil,'该职业收藏尚未接入'end
 local r,why=G.WD.Build(G.WD.selected or 1,G.WD.previewLevel or UnitLevel('player'));if not r then return nil,why end
 local b=S.Blank(class,r.level,r.plan.spec)
 for id in pairs(WD.nodes)do local rank=RebornWD8.AERank(id,r.mask);if rank>0 then b.ranks[id]=rank end end
 return b,r.plan.title
end
function S.Fingerprint(b)
 local ids={};for id in pairs(b.ranks)do ids[#ids+1]=id end;table.sort(ids)
 local out={b.class,b.mode,b.layout,tostring(b.level),tostring(b.spec or'-')}
 for _,id in ipairs(ids)do if b.ranks[id]>0 then out[#out+1]=id..':'..b.ranks[id]end end
 return table.concat(out,'|')
end
function S.Commit(name,b,id,expectedHead,basedOn,profile)
 local d,why=S.DB();if not d then return nil,why end
 if type(name)~='string'or #name>96 or #name:gsub('%s','')==0 or name:find('[%c|]')then return nil,'请输入1至96字节的名称，不含控制符或竖线'end
 local nodes,err=S.Shape(b);if not nodes then return nil,err end
 local item=id and d.builds[id]
 if id and(type(item)~='table'or type(item.versions)~='table'or #item.versions~=expectedHead)then return nil,'收藏头版本已改变，请重新选择再保存'end
 if item and item.class~=b.class then return nil,'不能改变已收藏方案的职业'end
 if item and #item.versions>=S.historyLimit then return nil,'已达40个历史版本，请复制为新收藏'end
 local inputProfile=profile;if inputProfile==nil and item then inputProfile=item.versions[#item.versions].profile end
 local meta,metaError=S.Profile(inputProfile);if not meta then return nil,metaError end
 if not item then
  local n=0;for _,v in pairs(d.builds)do if type(v)=='table'and v.class==b.class then n=n+1 end end
  if n>=S.limit then return nil,'本职业免费收藏位已用完（1个）；已有收藏保留，可重命名或删除，扩展入口尚未开放'end
  repeat id='local-'..d.nextId;d.nextId=d.nextId+1 until d.builds[id]==nil
  item={id=id,class=b.class,versions={}};d.builds[id]=item
 end
 local last=item.versions[#item.versions]
 if last and last.name==name and S.Fingerprint(last.build)==S.Fingerprint(b)and S.ProfileKey(last.profile)==S.ProfileKey(meta)then return nil,'内容和名称未改变'end
 local valid,reason=S.Validate(b);local rev={name=name,build=S.Copy(b),version=#item.versions+1,basedOn=basedOn,created=S.Now(),validAtSave=valid and true or false,validation=reason,profile=S.Copy(meta)}
 item.versions[#item.versions+1]=rev;item.name=name
 return id,rev.version
end
function S.List(class)
 local d=S.DB();local list={};if not d then return list end
 for _,item in pairs(d.builds)do if type(item)=='table'and item.class==class and type(item.id)=='string'and type(item.name)=='string'and type(item.versions)=='table'and #item.versions>0 then list[#list+1]=item end end
 table.sort(list,function(a,b)return a.name==b.name and a.id<b.id or a.name<b.name end);return list
end
function S.Delete(id,head)
 local d,why=S.DB();if not d then return false,why end;local item=d.builds[id]
 if type(item)~='table'or type(item.versions)~='table'or #item.versions~=head then return false,'收藏已改变，请重新确认'end
 d.builds[id]=nil;return true
end
