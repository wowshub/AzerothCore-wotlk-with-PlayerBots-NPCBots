-- TG13A: refresh local projections from existing APIs/snapshots, never grant or save.
local G=RebornTalentGuide
local L={epoch=0,level=UnitLevel('player'),refreshes=0};G.Lifecycle=L
local frame=CreateFrame('Frame');L.frame=frame
local popups={'REBORN_TG_APPLY','REBORN_TG_PALADIN','REBORN_TG_WD_DRAFT','REBORN_COLLECTION_APPLY'}
local guideEvents={PLAYER_LEVEL_UP=true,UNIT_LEVEL=true,SPELLS_CHANGED=true,LEARNED_SPELL_IN_TAB=true,TRAINER_CLOSED=true,PLAYER_ENTERING_WORLD=true,PLAYER_ALIVE=true,CHARACTER_POINTS_CHANGED=true,PLAYER_REGEN_ENABLED=true,CHAT_MSG_SYSTEM=true}
local stopEvents={PLAYER_LEVEL_UP=true,PLAYER_LOGOUT=true,PLAYER_ENTERING_WORLD=true,ACTIVE_TALENT_GROUP_CHANGED=true,PLAYER_DEAD=true,PLAYER_REGEN_DISABLED=true}
local panelsAlreadyHandle={CHARACTER_POINTS_CHANGED=true,PLAYER_TALENT_UPDATE=true,ACTIVE_TALENT_GROUP_CHANGED=true,PLAYER_REGEN_DISABLED=true,PLAYER_REGEN_ENABLED=true}
function L.Current(epoch)return epoch==L.epoch end
local function shown(f)return f and f:IsShown()end
function L.Flush()
 local refreshGuide,refreshPanels=L.refreshGuide,L.refreshPanels;L.refreshGuide=nil;L.refreshPanels=nil;L.queued=nil;frame:SetScript('OnUpdate',nil)
 local W=G.WD
 if W and W.previewCurrent then W.previewLevel=UnitLevel('player')end
 local S=RebornTalentCollections
 -- The original WD watcher observes only its actual book. A guide-only level-up
 -- may otherwise retain the old server budget. One read-only query per level;
 -- never interrupt a save/bind/reset already in flight or replace local drafts.
 local M=RebornWD8;local level=UnitLevel('player')
 if L.needsSnapshot and type(level)=='number'and level>0 and W and W.IsDoctor()and M and type(M.Query)=='function'and
  (shown(G.frame)or(S and shown(S.frame))or(G.TreeViews and shown(G.TreeViews.frame))or(G.TalentCenter and shown(G.TalentCenter.frame)))and not M.pending and not M.dirty and not M.aeDirty and
  not(S and S.waiting)and M.level~=level then
  local key=tostring(UnitGUID('player'))..':'..tostring(level)
  if not L.queryAttempt or L.queryAttempt.key~=key then L.queryAttempt={key=key,count=0,next=0}end
  local attempt=L.queryAttempt
  if attempt.count<3 and GetTime()>=attempt.next then attempt.count=attempt.count+1;attempt.next=GetTime()+6;L.queryKey=key;M.Query()end
 end
 if M and M.loaded and M.level==level then L.needsSnapshot=nil end
 if refreshGuide and shown(G.frame)then G.Refresh()end
 if S and shown(S.frame)then S.Refresh()end
 local B=G.ClassHome
 if refreshPanels and B then if shown(B.home)then B.RefreshHome()end;if shown(B.tree)then B.RefreshTree()end end
 local A=RebornClassTalentPanels
 if refreshPanels and A and shown(A.frame)then A.Refresh()end
 local N=G.Navigation
 if refreshPanels and N and shown(N.large)then N.RefreshLarge()end
 local T=G.TreeViews
 if T and shown(T.frame)then T.RefreshWD()end
 if G.TalentCenter and shown(G.TalentCenter.frame)then G.TalentCenter.Refresh()end
 L.refreshes=L.refreshes+1
end
function L.Schedule(guide)
 L.refreshGuide=L.refreshGuide or guide
 if L.queued then return end
 L.queued=true;local elapsed=0
 frame:SetScript('OnUpdate',function(_,dt)elapsed=elapsed+dt;if elapsed>=.08 then L.Flush()end end)
end
function L.OnEvent(_,event,...)
 if event=='UNIT_LEVEL'and(...)~='player'then return end
 if event=='CHAT_MSG_SYSTEM'then
  local message=...;if type(message)~='string'or not message:match('^WD139[BE]|')then return end
 end
 local W=G.WD
 if event=='UNIT_LEVEL'and W and W.previewCurrent==nil then W.previewCurrent=W.previewLevel==nil or W.previewLevel==L.level end
 local levelChanged=event=='UNIT_LEVEL'and UnitLevel('player')~=L.level
 L.epoch=L.epoch+1
 for _,key in ipairs(popups)do if StaticPopup_Hide then StaticPopup_Hide(key)end end
 if event=='PLAYER_LEVEL_UP'then
  local value=tonumber((...));local W=G.WD
  if W and W.previewCurrent==nil then W.previewCurrent=W.previewLevel==nil or W.previewLevel==L.level end
  if W and W.previewCurrent then W.previewLevel=value or UnitLevel('player')end
  L.level=value or UnitLevel('player')
 end
 if event=='UNIT_LEVEL'then L.level=UnitLevel('player');L.observedLevel=L.level end
 if event=='PLAYER_LEVEL_UP'or event=='UNIT_LEVEL'or event=='PLAYER_ENTERING_WORLD'then L.needsSnapshot=true end
 if stopEvents[event]or levelChanged then
  for _,H in ipairs({RebornTalentGuideHunter,RebornTalentGuideRogue,RebornTalentGuidePriest,RebornTalentGuideDeathKnight,RebornTalentGuideShaman,RebornTalentGuideMage,RebornTalentGuideWarlock})do if H and H.job then H.Stop('角色状态改变，停止后续加点；已确认点数保留')end end
  if G.job then G.Stop('角色状态改变，停止后续加点；已确认点数保留')end
  local P=RebornTalentGuidePaladin;if P and P.job then P.Stop('角色状态改变，停止后续加点；已确认点数保留')end
  local R=RebornTalentGuideWarriorCollection;if R and R.job then R.Stop('角色状态改变，停止后续加点；已确认点数保留')end
 end
 if event=='PLAYER_LOGOUT'then L.watchFrame:SetScript('OnUpdate',nil);L.watching=false;L.queued=nil;L.refreshGuide=nil;L.refreshPanels=nil;frame:SetScript('OnUpdate',nil);return end
 L.refreshPanels=L.refreshPanels or not panelsAlreadyHandle[event]
 L.Schedule(guideEvents[event])
end
for _,event in ipairs({'PLAYER_LEVEL_UP','UNIT_LEVEL','SPELLS_CHANGED','LEARNED_SPELL_IN_TAB','TRAINER_CLOSED','CHARACTER_POINTS_CHANGED','PLAYER_TALENT_UPDATE','ACTIVE_TALENT_GROUP_CHANGED','PLAYER_ENTERING_WORLD','PLAYER_ALIVE','PLAYER_DEAD','PLAYER_REGEN_DISABLED','PLAYER_REGEN_ENABLED','PLAYER_LOGOUT','CHAT_MSG_SYSTEM'})do frame:RegisterEvent(event)end
frame:SetScript('OnEvent',L.OnEvent)

-- TG15A: commands may update UnitLevel without delivering the expected level events.
-- Sample only while our guide/collection/WD preview is visible; no scans or builds per tick.
L.watchFrame=CreateFrame('Frame');L.observedLevel=L.level
local watchElapsed=0
local function visible()
 local S=RebornTalentCollections;local T=G.TreeViews
 return shown(G.frame)or(S and shown(S.frame))or(T and shown(T.frame))or(G.TalentCenter and shown(G.TalentCenter.frame))
end
local function snapshotKey()
 local M=RebornWD8;if not M then return ''end
 return table.concat({tostring(M.level),tostring(M.revision),tostring(M.active),tostring(M.loaded),tostring(M.pending),tostring(M.dirty),tostring(M.aeDirty),tostring(M.aeBudget),tostring(M.teBudget)},':')
end
function L.WatchTick(_,dt)
 if not visible()then L.watchFrame:SetScript('OnUpdate',nil);L.watching=false;return end
 watchElapsed=watchElapsed+dt;if watchElapsed<.5 then return end;watchElapsed=0
 local level=UnitLevel('player');local key=snapshotKey()
 if type(level)=='number'and level>0 and level~=L.observedLevel then
  L.observedLevel=level;L.OnEvent(nil,'UNIT_LEVEL','player')
 elseif key~=L.watchSnapshot then L.Schedule(true)
 elseif L.needsSnapshot and L.queryAttempt and L.queryAttempt.count<3 and GetTime()>=L.queryAttempt.next then L.Schedule(true)end
 L.watchSnapshot=key
end
function L.UpdateWatch()
 if visible()then
  if not L.watching then
   L.watching=true;watchElapsed=0;L.watchSnapshot=snapshotKey();L.watchFrame:SetScript('OnUpdate',L.WatchTick)
   if RebornWD8 and RebornWD8.level~=UnitLevel('player')then L.needsSnapshot=true end
   L.Schedule(true)
  end
 else L.watching=false;L.watchFrame:SetScript('OnUpdate',nil)end
end
function L.Watch(f)
 if not f or f.tgLevelWatch then return end;f.tgLevelWatch=true
 f:HookScript('OnShow',L.UpdateWatch);f:HookScript('OnHide',L.UpdateWatch);L.UpdateWatch()
end
local createGuide=G.Create
function G.Create(...)local result=createGuide(...);L.Watch(G.frame);return result end
local C=RebornTalentTreeCanvas;local createWindow=C.Window
function C.Window(name,...)
 local f=createWindow(name,...)
 if name=='RebornTalentCollectionFrame'or name=='RebornTGWDRecommendationTree'or name=='RebornTalentCenterFrame'then L.Watch(f)end
 return f
end
L.Watch(G.frame)
