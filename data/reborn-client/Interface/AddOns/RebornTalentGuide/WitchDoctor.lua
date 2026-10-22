-- TG2A: use the installed Witch Doctor validator. Never sends a save/reset/bind command.
local G=RebornTalentGuide
local D=RebornTalentGuideWDData
local W={selected=1,version='TG4C'};G.WD=W
function W.IsDoctor()
 local _,token,id=UnitClass('player');return token=='WITCHDOCTOR'or id==13
end
function W.Ready()
 local M,L=RebornWD8,RebornWDNodeLayout
 if not M or not L or type(M.AEValid)~='function'or type(M.MaskSet)~='function'then return nil,'请启用配套巫医天赋插件，再重新登录'end
 if L.hash~=D.layoutHash or L.count~=164 then return nil,'巫医节点版本不匹配，请使用WD161累计或更新的配套推荐包'end
 return M,L
end
function W.Budget(level)
 level=math.max(1,math.min(255,math.floor(tonumber(level)or 80)))
 local M=RebornWD8
 if W.IsDoctor()and M and M.loaded and M.level==level and type(M.aeBudget)=='number'and type(M.teBudget)=='number'then return M.aeBudget,M.teBudget end
 -- Beyond 80 only authoritative snapshots may supply extra budget.
 level=math.min(level,80)
 return math.max(0,math.floor((level-8)/2)),math.max(0,math.floor((level-9)/2))
end
-- The production validator has no yielding calls. Restore every borrowed context field,
-- including after a thrown error; no draft, saved mask, revision or UI callback is touched.
function W.Validate(mask,spec,level,ae,te)
 local M=W.Ready();if not M then return false,'巫医校验器不可用'end
 local saved={level=M.level,aeBudget=M.aeBudget,teBudget=M.teBudget,specs=M.specs,slot=M.slot}
 M.level,M.aeBudget,M.teBudget,M.specs,M.slot=level,ae,te,{spec,spec,spec},0
 local ok,valid,why=pcall(M.AEValid,mask)
 M.level,M.aeBudget,M.teBudget,M.specs,M.slot=saved.level,saved.aeBudget,saved.teBudget,saved.specs,saved.slot
 if not ok then return false,'巫医校验器异常，已停止生成方案'end
 return valid,why
end
local function priorities(plan)
 local out={};for _,list in ipairs({plan.ae,plan.order})do for _,entry in ipairs(list)do
  out[#out+1]=type(entry)=='table'and{id=entry[1],rank=entry[2]}or{id=entry,rank=1}
 end end;return out
end
local function build(index,level,seed)
 local M,L=W.Ready();if not M then return nil,L end
 local p=D.plans[index];if not p then return nil,'推荐方案不存在'end
 level=math.max(1,math.min(255,math.floor(tonumber(level)or 80)))
 local ae,te=W.Budget(level);if seed then ae,te=M.aeBudget,M.teBudget end
 local mask=seed or M.MaskParse(0);local candidates=priorities(p);local order={}
 if seed then local valid,why=W.Validate(mask,p.spec,level,ae,te);if not valid then return nil,'当前已保存方案不符合规则：'..tostring(why)end end
 for pass=1,200 do
  local progressed=false
  for _,x in ipairs(candidates)do
   local n=D.nodes[x.id];local i=L.index[x.id]
   if not n or i==nil or x.rank>n.max then return nil,'推荐节点与本服版本不符：'..tostring(x.id)end
   local rank=M.AERank(x.id,mask)
   if rank<x.rank then
    local row=L.nodes[i];local nextMask=M.MaskSet(mask,row.offset,row.width,rank+1)
    if W.Validate(nextMask,p.spec,level,ae,te)then
     mask=nextMask;order[#order+1]={id=x.id,rank=rank+1};progressed=true;break
    end
   end
  end
  if not progressed then break end
  if pass==200 then return nil,'推荐生成超过安全步数'end
 end
 local valid,why=W.Validate(mask,p.spec,level,ae,te);if not valid then return nil,why end
 local blocked={};for _,x in ipairs(candidates)do
  if M.AERank(x.id,mask)<x.rank then
   local row=L.nodes[L.index[x.id]];local nextMask=M.MaskSet(mask,row.offset,row.width,M.AERank(x.id,mask)+1)
   local _,reason=W.Validate(nextMask,p.spec,level,ae,te)
   blocked[#blocked+1]={id=x.id,reason=reason or'当前优先级未纳入'}
  end
 end
 return {plan=p,index=index,level=level,mask=mask,order=order,blocked=blocked,ae=M.AESpent(mask),te=M.TESpent(mask),aeBudget=ae,teBudget=te}
end
-- TG6C: bounded cache of pure recommendation generation, never character eligibility.
local builds,keys={},{}
function W.ClearBuildCache() builds={};keys={} end
local function copyBuild(result)
 local out={};for k,v in pairs(result)do out[k]=v end
 -- Masks are immutable tagged hex strings. Lists must never escape by reference.
 for _,field in ipairs({'order','blocked'})do out[field]={};for i,row in ipairs(result[field])do local x={};for k,v in pairs(row)do x[k]=v end;out[field][i]=x end end
 return out
end
function W.Build(index,level,seed)
 local M,L=W.Ready();if not M then return nil,L end
 local plan=D.plans[index];if not plan then return nil,'推荐方案不存在'end
 level=math.max(1,math.min(255,math.floor(tonumber(level)or 80)))
 local ae,te=W.Budget(level);if seed then ae,te=M.aeBudget,M.teBudget end
 local key=table.concat({tostring(index),level,ae,te,tostring(seed or''),tostring(plan),tostring(D.nodes),tostring(L),L.hash,tostring(M.AEValid),tostring(W.Validate),tostring(M.MaskParse),tostring(M.MaskRank),tostring(M.MaskSet),tostring(M.AERank),tostring(M.LayoutValid),tostring(M.AESpent),tostring(M.TESpent)},':')
 if builds[key]then return copyBuild(builds[key])end
 local result,why=build(index,level,seed);if not result then return nil,why end
 if #keys>=24 then builds[table.remove(keys,1)]=nil end
 builds[key]=copyBuild(result);keys[#keys+1]=key;return result
end
function W.CheckDraft(index,previewLevel)
 local M,L=W.Ready();if not M then return nil,L end
 if not W.IsDoctor()or G.fromBot then return nil,'仅可载入自己巫医角色的草稿'end
 if InCombatLockdown()or UnitIsDeadOrGhost('player')then return nil,'脱战且存活时才可载入草稿'end
 if not M.loaded or not M.modern or not M.layoutReady or M.pending then return nil,'请先在巫医面板刷新完整方案，等待服务器同步'end
 if M.slot~=M.active or M.slot>=M.unlocked then return nil,'请先在巫医面板选择已解锁的当前激活方案'end
 if M.dirty or M.aeDirty then return nil,'当前有未保存加点，请先在巫医面板保存或撤回'end
 if UnitLevel('player')~=M.level then return nil,'角色等级与服务器快照不同，请等待同步或到原面板刷新；不会按旧点数载入'end
 if tonumber(previewLevel)~=M.level then return nil,'请切回当前等级推荐；预览等级方案不能直接载入'end
 local result,why=W.Build(index,M.level);if not result then return nil,why end
 local valid,reason=W.Validate(result.mask,result.plan.spec,M.level,M.aeBudget,M.teBudget);if not valid then return nil,reason end
 if M.specs[M.slot+1]~=result.plan.spec or M.draftSpec~=result.plan.spec then return nil,'请先在巫医面板绑定并查看本推荐专精；不会自动切换或付费重置'end
 local saved=M.aeMasks[M.slot+1];if not saved then return nil,'当前已保存方案尚未同步'end
 -- TG16A: a node outside the ideal recipe is not necessarily mutually exclusive.
 -- Seed from the authoritative saved mask, then add only validated affordable ranks.
 local ideal=result;local completed,why=W.Build(index,M.level,saved)
 if not completed then return nil,why end
 result=completed;result.retained={};result.deferred={};result.savedMask=saved
 for id,node in pairs(D.nodes)do
  local rank=M.AERank(id,saved)
  if rank>M.AERank(id,result.mask)then return nil,'补点结果试图移除已存节点，已停止'end
  if rank>M.AERank(id,ideal.mask)then result.retained[#result.retained+1]={id=id,name=node.name,rank=rank}end
  if M.AERank(id,result.mask)<M.AERank(id,ideal.mask)then
   local reason='当前点数或前置不足';for _,row in ipairs(result.blocked)do if row.id==id then reason=row.reason;break end end
   result.deferred[#result.deferred+1]={id=id,name=node.name,reason=reason}
  end
 end
 table.sort(result.retained,function(a,b)return a.id<b.id end);table.sort(result.deferred,function(a,b)return a.id<b.id end)
 result.addedAE=result.ae-M.AESpent(saved);result.addedTE=result.te-M.TESpent(saved)
 if M.MaskEqual(saved,result.mask)then
  if #result.deferred==0 then return nil,'当前方案已包含本级推荐，本次无需补点'end
  if result.ae>=result.aeBudget and result.te>=result.teBudget then return nil,'当前AE和TE额度已用完，没有可补点数；已存点数保留'end
  local first=result.deferred[1];return nil,'当前没有可补的推荐点数；'..first.name..'：'..first.reason..'。已存点数保留'
 end
 result.revision,result.slot,result.hash=M.revision,M.slot,L.hash;return result
end
function W.LoadDraft(index,level,expected)
 local result,why=W.CheckDraft(index,level);if not result then return false,why end
 local M,L=W.Ready()
 if expected and(expected.revision~=M.revision or expected.slot~=M.slot or expected.hash~=L.hash or (expected.savedMask and not M.MaskEqual(expected.savedMask,result.savedMask))or(expected.mask and not M.MaskEqual(expected.mask,result.mask))or(expected.aeBudget and expected.aeBudget~=result.aeBudget)or(expected.teBudget and expected.teBudget~=result.teBudget))then return false,'方案状态已改变，请重新确认'end
 M.draftAE=result.mask;M.aeDirty=not M.MaskEqual(M.draftAE,M.aeMasks[M.slot+1]);M.dirty=M.aeDirty
 M.message='推荐已载入本地草稿；请到原巫医面板核对后点击保存更改'
 if M.changed then M.changed()end;if M.homeChanged then M.homeChanged()end
 return true,M.message
end


function W.DraftText(result)
 local out={'保留当前方案全部已保存点数，按剩余额度补入可用推荐。',
  '新增 AE '..result.addedAE..'、TE '..result.addedTE..'；补入 '..#result.order..' 级节点。'}
 if #result.retained>0 then
  out[#out+1]='保留推荐清单外的已存内容：'
  for i=1,math.min(4,#result.retained)do local row=result.retained[i];out[#out+1]=row.name..' '..row.rank end
  if #result.retained>4 then out[#out+1]='等 '..#result.retained..' 项'end
 end
 if #result.deferred>0 then
  out[#out+1]='本级推荐有 '..#result.deferred..' 项未加入，不会自动删点：'
  for i=1,math.min(2,#result.deferred)do local row=result.deferred[i];out[#out+1]=row.name..'：'..row.reason end
 end
 out[#out+1]='只载入本地草稿，不保存、不收费。请到原巫医面板核对后保存。'
 return table.concat(out,'\n')
end
