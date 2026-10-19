-- TG7A: warrior collection lifecycle. Scan and prerequisite queue remain canonical.
RebornTalentGuideWarriorCollection={}
local R=RebornTalentGuideWarriorCollection
local G=RebornTalentGuide
R.Scan=G.Scan;R.Queue=G.Queue
function R.Check(plan,owner)
 if RebornTalentGuide.fromBot or(not owner and RebornTalentGuide.catalogClass~='战士')then return nil,'当前查看对象不支持应用' end
 if InCombatLockdown()or UnitIsDeadOrGhost('player')then return nil,'战斗或死亡时不能应用'end
 if not owner and UnitLevel('player')<80 then return nil,'这三套是80级完整方案；低等级先作参考'end
 if type(LearnTalent)~='function'then return nil,'客户端未提供原生加点接口'end
 local ranks,why,map,group=R.Scan();if not ranks then return nil,why end
 if GetGroupPreviewTalentPointsSpent and GetGroupPreviewTalentPointsSpent(false,group)>0 then return nil,'原生面板有未确认预览点数，请先确认或取消'end
 local queue,err=R.Queue(plan,ranks);if not queue then return nil,err end
 local free=GetUnspentTalentPoints(false,false,group)
 if not free or free<#queue then return nil,'剩余点数不足，无法补齐整套方案'end
 return {rows=queue,map=map,group=group,ranks=ranks,pos=1,done=0}
end
function R.Message(s) RebornTalentGuide.Message(s) end
function R.Stop(s)local job=R.job;R.job=nil;R.Message(s or'已停止后续加点；已经学到的点数保留');if RebornTalentGuide.Refresh then RebornTalentGuide.Refresh()end;if job and job.onFinish then job.onFinish(false,s or'已停止；已投入点数保留')end end
function R.StartPlan(plan,owner,onFinish)
 if R.job or G.job or RebornTalentGuidePaladin.job then return false,'另一个战士应用任务正在进行'end
 local job,why=R.Check(plan,owner);if not job then return false,why end
 if #job.rows==0 then if onFinish then onFinish(true,'当前专精已符合收藏')end;return true end
 job.guid=UnitGUID('player');job.owner=owner;job.onFinish=onFinish;job.next=GetTime();R.job=job;R.Message('正在应用收藏，等待服务器逐点确认');return true
end
function R.Tick()
 local j=R.job;if not j then return end
 local owner=j.owner or RebornTalentGuide.frame
 if(not j.owner and RebornTalentGuide.catalogClass~='战士')or RebornTalentGuide.fromBot or UnitGUID('player')~=j.guid or not owner or not owner:IsShown()then R.Stop('查看对象改变，停止战士加点');return end
 if InCombatLockdown()or UnitIsDeadOrGhost('player')or GetActiveTalentGroup(false,false)~=j.group then R.Stop('状态或专精改变，已停止后续加点');return end
 local now=GetTime();if now<j.next then return end
 local current,why,currentMap=R.Scan();if not current then R.Stop(why);return end
 for t,row in ipairs(j.map)do
  if currentMap[t].tab~=row.tab then R.Stop('天赋页顺序改变，已停止后续加点');return end
  for i,native in ipairs(row)do if currentMap[t][i]~=native then R.Stop('天赋节点顺序改变，已停止后续加点');return end end
 end
 if j.waiting then
  local r=j.rows[j.pos];local n=current[r.tab][r.index]
  if n==r.rank then j.ranks[r.tab][r.index]=n;j.pos=j.pos+1;j.done=j.done+1;j.waiting=nil;j.next=now+.35
  elseif now-j.sent>5 then R.Stop('未收到加点确认，已停止；请检查点数/技能数据，未自动重发');return
  else return end
 end
 for t,row in ipairs(current)do for i,n in ipairs(row)do if n~=j.ranks[t][i]then R.Stop('检测到其他加点或重置，已停止');return end end end
 if not j.rows[j.pos]then local callback=j.onFinish;j.onFinish=nil;R.Stop('应用完成：服务器已确认 '..j.done..' 点；雕文仍需自行选择安装');if callback then callback(true,'服务器已逐点确认')end;return end
 if now<j.next then if RebornTalentGuide.Refresh then RebornTalentGuide.Refresh()end;return end
 local r=j.rows[j.pos];j.waiting=true;j.sent=now
 local ok=pcall(LearnTalent,j.map[r.tab].tab,j.map[r.tab][r.index],false,j.group)
 if not ok then R.Stop('原生加点接口拒绝，请打开天赋面板手动加点');return end
 RebornTalentGuide.message='已确认 '..j.done..' / '..#j.rows..' 点；正在等待下一点'
 if RebornTalentGuide.Refresh then RebornTalentGuide.Refresh()end
end


-- One native learning transaction at a time, including the old recommendation paths.
local start=G.Start
function G.Start(...)if R.job then G.Message('收藏正在逐点应用，请先停止或等待完成');return end;return start(...)end
local P=RebornTalentGuidePaladin
local pStart,pStartPlan=P.Start,P.StartPlan
function P.Start(...)if R.job then G.Message('收藏正在逐点应用，请先停止或等待完成');return end;return pStart(...)end
function P.StartPlan(...)if R.job or G.job then return false,'另一个原生加点任务正在进行'end;return pStartPlan(...)end
local timer=CreateFrame('Frame');local elapsed=0
timer:SetScript('OnUpdate',function(_,dt)elapsed=elapsed+dt;if elapsed<.1 then return end;elapsed=0;R.Tick()end)
