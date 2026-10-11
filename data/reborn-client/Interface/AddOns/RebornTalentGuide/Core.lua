-- TG1A: native warrior only. Recommendations are candidates, never confirmed ranks.
RebornTalentGuide={selected=1,tree=3}
local G=RebornTalentGuide
local D=RebornTalentGuideData
function G.Queue(plan,current)
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
function G.Scan()
 local _,class=UnitClass('player')
 if class~='WARRIOR'then return nil,'当前角色不是战士：可查看推荐，不可应用'end
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
function G.Check(plan)
 if InCombatLockdown()or UnitIsDeadOrGhost('player')then return nil,'战斗或死亡时不能应用'end
 if UnitLevel('player')<80 then return nil,'这三套是80级完整方案；低等级先作参考'end
 if type(LearnTalent)~='function'then return nil,'客户端未提供原生加点接口'end
 local ranks,why,map,group=G.Scan();if not ranks then return nil,why end
 if GetGroupPreviewTalentPointsSpent and GetGroupPreviewTalentPointsSpent(false,group)>0 then return nil,'原生面板有未确认预览点数，请先确认或取消'end
 local queue,err=G.Queue(plan,ranks);if not queue then return nil,err end
 local free=GetUnspentTalentPoints(false,false,group)
 if not free or free<#queue then return nil,'剩余点数不足，无法补齐整套方案'end
 return {rows=queue,map=map,group=group,ranks=ranks,pos=1,done=0}
end
function G.Message(s)
 G.message=s;if G.status then G.status:SetText(s)end
 if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage('|cffffcc66[天赋参考]|r '..s)end
end
function G.Stop(s)G.job=nil;G.Message(s or'已停止后续加点；已经学到的点数保留');if G.Refresh then G.Refresh()end end
function G.Start(index)
 if G.job then return end
 local job,why=G.Check(D.plans[index]);if not job then G.Message(why);return end
 if #job.rows==0 then G.Message('当前专精已经与推荐一致');return end
 job.plan=index;job.next=GetTime();G.job=job;G.Message('开始补齐自己的当前专精，等待服务器逐点确认')
end
function G.Tick()
 local j=G.job;if not j then return end
 if InCombatLockdown()or UnitIsDeadOrGhost('player')or GetActiveTalentGroup(false,false)~=j.group then G.Stop('状态或专精改变，已停止后续加点');return end
 local now=GetTime();if now<j.next then return end
 local current,why,currentMap=G.Scan();if not current then G.Stop(why);return end
 for t,row in ipairs(j.map)do
  if currentMap[t].tab~=row.tab then G.Stop('天赋页顺序改变，已停止后续加点');return end
  for i,native in ipairs(row)do if currentMap[t][i]~=native then G.Stop('天赋节点顺序改变，已停止后续加点');return end end
 end
 if j.waiting then
  local r=j.rows[j.pos];local n=current[r.tab][r.index]
  if n==r.rank then j.ranks[r.tab][r.index]=n;j.pos=j.pos+1;j.done=j.done+1;j.waiting=nil;j.next=now+.35
  elseif now-j.sent>5 then G.Stop('未收到加点确认，已停止；请检查点数/技能数据，未自动重发');return
  else return end
 end
 for t,row in ipairs(current)do for i,n in ipairs(row)do if n~=j.ranks[t][i]then G.Stop('检测到其他加点或重置，已停止');return end end end
 if not j.rows[j.pos]then G.Stop('应用完成：服务器已确认 '..j.done..' 点；雕文仍需自行选择安装');return end
 if now<j.next then if G.Refresh then G.Refresh()end;return end
 local r=j.rows[j.pos];j.waiting=true;j.sent=now
 local ok=pcall(LearnTalent,j.map[r.tab].tab,j.map[r.tab][r.index],false,j.group)
 if not ok then G.Stop('原生加点接口拒绝，请打开天赋面板手动加点');return end
 G.message='已确认 '..j.done..' / '..#j.rows..' 点；正在等待下一点'
 if G.Refresh then G.Refresh()end
end
