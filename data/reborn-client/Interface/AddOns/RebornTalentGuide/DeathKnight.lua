-- TG26A: death knight adapter reuses native stable-ID scan and acknowledged point queue.
RebornTalentGuideDeathKnight={selected=1}
local P=RebornTalentGuideDeathKnight
local D=RebornTalentGuideDeathKnightData
function P.Queue(plan,current)
 local work,queue={},{}
 for t,tree in ipairs(D.trees)do
  work[t]={}
  for i,x in ipairs(tree)do
   local n=current[t]and current[t][i]
   local target=plan.ranks[t][i]
   if type(n)~='number'or n<0 or n%1~=0 then return nil,'当前点数尚未读取完整'end
   if n>target then return nil,'已有加点冲突：'..x.name..'。请自行重置当前专精后再应用'end
   if target>x.max then return nil,'方案等级超出本服上限'end
   work[t][i]=n
  end
 end
 for t,tree in ipairs(D.trees)do
  local byid={};for i,x in ipairs(tree)do byid[x.id]=i end
  local progress=true
  while progress do
   progress=false;local spent=0;for _,n in ipairs(work[t])do spent=spent+n end
   for i,x in ipairs(tree)do
    if work[t][i]<plan.ranks[t][i]and spent>=(x.row-1)*5 and(x.dep==0 or(work[t][byid[x.dep]]or 0)>=x.depRank)then
     work[t][i]=work[t][i]+1;spent=spent+1;queue[#queue+1]={tab=t,index=i,rank=work[t][i]};progress=true
    end
   end
  end
  for i,n in ipairs(work[t])do if n~=plan.ranks[t][i]then return nil,'方案前置条件不足'end end
 end
 return queue
end
function P.Scan()
 local _,class=UnitClass('player')
 if class~='DEATHKNIGHT'then return nil,'当前角色不是死亡骑士：可查看推荐，不可应用'end
 local group=GetActiveTalentGroup(false,false);if not group then return nil,'尚未读取当前专精'end
 -- TG1H: recommendation tree order is independent of the client's tab order.
 local tabs={};local count=GetNumTalentTabs(false,false)
 if not count or count<3 then return nil,'客户端天赋页尚未读取完整'end
 for tab=1,count do
  local actual={};local n=GetNumTalents(tab,false,false)
  if not n then return nil,'客户端天赋页尚未读取完整'end
  for i=1,n do
   local link=GetTalentLink(tab,i,false,false,group)
   local id=link and tonumber(link:match('talent:(%d+):'))
   if not id or actual[id]then return nil,'客户端天赋编号尚未就绪'end
   actual[id]=i
  end
  tabs[tab]={ids=actual,count=n}
 end
 local ranks,map,used={},{},{}
 for t,tree in ipairs(D.trees)do
  local tab
  for candidate,data in ipairs(tabs)do
   local matches=data.count==#tree
   if matches then for _,x in ipairs(tree)do if not data.ids[x.id]then matches=false;break end end end
   if matches then
    if tab then return nil,'客户端天赋树编号重复，无法安全应用'end
    tab=candidate
   end
  end
  if not tab or used[tab]then return nil,'客户端天赋树与推荐基线不符，无法匹配第 '..t..' 系'end
  used[tab]=true;ranks[t]={};map[t]={tab=tab}
  for i,x in ipairs(tree)do
   local native=tabs[tab].ids[x.id]
   local name,icon,row,col,rank,maxRank=GetTalentInfo(tab,native,false,false,group)
   if not name or row~=x.row or col~=x.col or maxRank~=x.max then return nil,'客户端天赋布局/等级不符：'..x.name end
   for _,id in ipairs(x.spells)do if not GetSpellInfo(id)then return nil,'客户端缺少技能数据：'..id..'（'..x.name..'）'end end
   ranks[t][i]=rank;map[t][i]=native
  end
 end
 return ranks,nil,map,group
end
function P.Check(plan,owner)
 if P.job or (RebornTalentGuideHunter and RebornTalentGuideHunter.job)or (RebornTalentCollections and RebornTalentCollections.ActiveNativeJob())or RebornTalentGuide.job then return nil,"已有应用任务，等待结束或先停止"end
 if RebornTalentGuide.fromBot or(not owner and RebornTalentGuide.catalogClass~='死亡骑士')then return nil,'当前查看对象不支持应用' end
 if InCombatLockdown()or UnitIsDeadOrGhost('player')then return nil,'战斗或死亡时不能应用'end
 if not owner and UnitLevel('player')<80 then return nil,'这些是80级完整方案；低等级先作参考'end
 if type(LearnTalent)~='function'then return nil,'客户端未提供原生加点接口'end
 local ranks,why,map,group=P.Scan();if not ranks then return nil,why end
 if GetGroupPreviewTalentPointsSpent and GetGroupPreviewTalentPointsSpent(false,group)>0 then return nil,'原生面板有未确认预览点数，请先确认或取消'end
 local queue,err=P.Queue(plan,ranks);if not queue then return nil,err end
 local free=GetUnspentTalentPoints(false,false,group)
 if not free or free<#queue then return nil,'剩余点数不足，无法补齐整套方案'end
 return {rows=queue,map=map,group=group,ranks=ranks,pos=1,done=0}
end
function P.Message(s) local T=RebornTalentGuide.TalentCenter;if T and T.frame and T.frame:IsShown()then T.Message(s)else RebornTalentGuide.Message(s)end end
function P.Stop(s)local job=P.job;P.job=nil;P.Message(s or'已停止后续加点；已经学到的点数保留');if RebornTalentGuide.Refresh then RebornTalentGuide.Refresh()end;if job and job.onFinish then job.onFinish(false,s or'已停止；已投入点数保留')end end
function P.StartPlan(plan,owner,onFinish)
 if P.job then return false,'另一个死亡骑士应用任务正在进行'end
 local job,why=P.Check(plan,owner);if not job then return false,why end
 if #job.rows==0 then if onFinish then onFinish(true,'当前专精已符合收藏')end;return true end
 job.guid=UnitGUID('player');job.owner=owner;job.onFinish=onFinish;job.next=GetTime();P.job=job;P.Message('正在应用收藏，等待服务器逐点确认');return true
end
function P.Start(index)
 if P.job then return end
 local job,why=P.Check(D.plans[index]);if not job then P.Message(why);return end
 if #job.rows==0 then P.Message('当前专精已经与推荐一致');return end
 job.guid=UnitGUID('player');job.plan=index;job.next=GetTime();P.job=job;P.Message('开始补齐自己的当前专精，等待服务器逐点确认')
end
function P.Tick()
 local j=P.job;if not j then return end
 local owner=j.owner or RebornTalentGuide.frame
 if(not j.owner and RebornTalentGuide.catalogClass~='死亡骑士')or RebornTalentGuide.fromBot or UnitGUID('player')~=j.guid or not owner or not owner:IsShown()then P.Stop('查看对象改变，停止死亡骑士加点');return end
 if InCombatLockdown()or UnitIsDeadOrGhost('player')or GetActiveTalentGroup(false,false)~=j.group then P.Stop('状态或专精改变，已停止后续加点');return end
 local now=GetTime();if now<j.next then return end
 local current,why,currentMap=P.Scan();if not current then P.Stop(why);return end
 for t,row in ipairs(j.map)do
  if currentMap[t].tab~=row.tab then P.Stop('天赋页顺序改变，已停止后续加点');return end
  for i,native in ipairs(row)do if currentMap[t][i]~=native then P.Stop('天赋节点顺序改变，已停止后续加点');return end end
 end
 if j.waiting then
  local r=j.rows[j.pos];local n=current[r.tab][r.index]
  if n==r.rank then j.ranks[r.tab][r.index]=n;j.pos=j.pos+1;j.done=j.done+1;j.waiting=nil;j.next=now+.35
  elseif now-j.sent>5 then P.Stop('未收到加点确认，已停止；请检查点数/技能数据，未自动重发');return
  else return end
 end
 for t,row in ipairs(current)do for i,n in ipairs(row)do if n~=j.ranks[t][i]then P.Stop('检测到其他加点或重置，已停止');return end end end
 if not j.rows[j.pos]then local callback=j.onFinish;j.onFinish=nil;P.Stop('应用完成：服务器已确认 '..j.done..' 点；雕文仍需自行选择安装');if callback then callback(true,'服务器已逐点确认')end;return end
 if now<j.next then if RebornTalentGuide.Refresh then RebornTalentGuide.Refresh()end;return end
 local r=j.rows[j.pos];j.waiting=true;j.sent=now
 local ok=pcall(LearnTalent,j.map[r.tab].tab,j.map[r.tab][r.index],false,j.group)
 if not ok then P.Stop('原生加点接口拒绝，请打开天赋面板手动加点');return end
 RebornTalentGuide.message='已确认 '..j.done..' / '..#j.rows..' 点；正在等待下一点'
 if RebornTalentGuide.Refresh then RebornTalentGuide.Refresh()end
end


-- One scheduler for this adapter. Tick validates owner, GUID, spec and authoritative ranks.
local events=CreateFrame('Frame');P.events=events
local elapsed=0
events:SetScript('OnUpdate',function(_,dt)if not P.job then return end;elapsed=elapsed+dt;if elapsed>=.1 then elapsed=0;P.Tick()end end)
for _,name in ipairs({'PLAYER_LOGOUT','PLAYER_ENTERING_WORLD','PLAYER_DEAD','PLAYER_REGEN_DISABLED','ACTIVE_TALENT_GROUP_CHANGED'})do events:RegisterEvent(name)end
events:SetScript('OnEvent',function()if P.job then P.Stop('角色状态改变，停止后续加点；已确认点数保留')end end)
-- Existing warrior/paladin entry points must not overlap an active death knight transaction.
for _,engine in ipairs({RebornTalentGuide,RebornTalentGuidePaladin,RebornTalentGuideWarriorCollection,RebornTalentGuideHunter,RebornTalentGuideRogue,RebornTalentGuidePriest})do
 for _,key in ipairs({'Start','StartPlan'})do
  local old=engine[key]
  if old then engine[key]=function(...)if P.job then return false,'已有死亡骑士加点任务，请先停止'end;return old(...)end end
 end
end
function P.Build(index,level)
 local full=D.plans[index];if not full then return nil,'死亡骑士方案不存在'end
 level=math.max(55,math.min(80,math.floor(tonumber(level)or UnitLevel('player'))))
 local empty={{},{},{}};for t,tree in ipairs(D.trees)do for i in ipairs(tree)do empty[t][i]=0 end end
 local queue,why=P.Queue(full,empty);if not queue then return nil,why end
 local ordered={};for _,step in ipairs(queue)do if step.tab==full.spec then ordered[#ordered+1]=step end end
 for _,step in ipairs(queue)do if step.tab~=full.spec then ordered[#ordered+1]=step end end
 local result={title=full.title,ranks=empty,split={0,0,0},level=level}
 local budget=level-9
 local _,class=UnitClass('player')
 if class=='DEATHKNIGHT'and P.previewCurrent~=false and level==UnitLevel('player')then
  local actual,err,_,group=P.Scan();if not actual then return nil,err end
  local free=GetUnspentTalentPoints(false,false,group);if type(free)~='number'or free<0 then return nil,'尚未读取实际可用天赋点'end
  budget=free;for _,row in ipairs(actual)do for _,v in ipairs(row)do budget=budget+v end end
  budget=math.min(budget,level-9)
 end
 result.budget=budget
 for i=1,math.min(budget,#ordered)do local step=ordered[i];empty[step.tab][step.index]=step.rank;result.split[step.tab]=result.split[step.tab]+1 end
 return result
end
