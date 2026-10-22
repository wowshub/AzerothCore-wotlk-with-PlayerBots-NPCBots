-- TG4C: independent comparison windows. Only list/tree views of the guide replace each other.
-- Do not wrap WD Open/Toggle/Home, change native ToggleTalentFrame, or write talent data.
RebornTalentPanelWindows={frames={},order={}}
local W=RebornTalentPanelWindows
local function own(key)return key~='native'end
local function members(root)
 local result={};local base=root:GetFrameLevel()
 local function visit(f)
  result[#result+1]={f,math.max(0,f:GetFrameLevel()-base)}
  if f.GetChildren then for _,child in ipairs({f:GetChildren()})do visit(child)end end
 end
 visit(root);return result
end
function W.Focus(frame)
 if not frame or W.focusing then return end
 local key;for k,f in pairs(W.frames)do if f==frame then key=k;break end end
 if not key or not own(key)then return end
 W.focusing=true
 for i=#W.order,1,-1 do if W.order[i]==frame then table.remove(W.order,i)end end
 W.order[#W.order+1]=frame
 -- Keep each complete private window in its own band, below DIALOG confirmation popups.
 -- Rebase the whole family so a lower window's nodes cannot leak above the front background.
 local base=10
 for _,root in ipairs(W.order)do
  if root:IsShown()then
   local family=members(root);local span=0
   for _,row in ipairs(family)do span=math.max(span,row[2])end
   root:SetFrameStrata('HIGH')
   for _,row in ipairs(family)do row[1]:SetFrameLevel(base+row[2])end
   base=base+span+10
  end
 end
 W.focusing=false
end
function W.HideOthers(keep)
 -- These are alternate renderings of ONE recommendation, not separate comparison panels.
 local guide,tree=W.frames.guide,W.frames.recommendationTree
 if keep==guide and tree then tree:Hide()elseif keep==tree and guide then guide:Hide()end
end
function W.ReturnToRecommendation()
 local G=RebornTalentGuide
 if G.Navigation then return G.Navigation.Return('巫医')end
 G.Create();G.catalogClass='巫医';G.classPage=2;G.Refresh();G.frame:Show();W.Focus(G.frame)
end

function W.ReturnToCollection()
 if RebornTalentCollections then RebornTalentCollections.Open('WITCHDOCTOR')else W.ReturnToRecommendation()end
end
-- TG17A: enter recommendations from the viewed tree without touching its draft.
function W.RecommendFromDoctor(frame)
 local G,M=RebornTalentGuide,RebornWD8
 if not G or not G.WD or not G.Navigation or not M then return end
 local plans=RebornTalentGuideWDData.plans;local index=G.WD.selected
 if not index or not plans[index]or plans[index].spec~=M.draftSpec then
  index=nil;for i,plan in ipairs(plans)do if plan.spec==M.draftSpec then index=i;break end end
 end
 if not index then G.Message('当前浏览专精尚无推荐');return end
 G.fromBot=false;G.WD.previewCurrent=true;G.WD.previewLevel=UnitLevel('player')
 -- TG20A: the original tree remains open for comparison, including its draft.
 -- Navigation.Return already brings the recommendation window to the front.
 G.Navigation.Return('巫医',index)
end
function W.AddReturn(frame)
 if not frame or frame.rebornReturnCollection then return end
 local b=CreateFrame('Button',nil,frame,'UIPanelButtonTemplate');b:SetSize(190,20);b:SetPoint('TOPRIGHT',frame,'TOPRIGHT',-116,-3);b:SetFrameLevel(frame:GetFrameLevel()+4)
 b:SetText('返回天赋收藏面板');b:SetScript('OnClick',W.ReturnToCollection)
 b:SetScript('OnEnter',function(self)GameTooltip:SetOwner(self,'ANCHOR_BOTTOM');GameTooltip:SetText('返回天赋收藏面板');GameTooltip:AddLine('保留所选推荐与预览等级；两面板均可继续拖动缩放。',1,1,1,true);GameTooltip:Show()end)
 b:SetScript('OnLeave',function()GameTooltip:Hide()end)
 frame.rebornReturnCollection=b
 local recommend=CreateFrame('Button',nil,frame,'UIPanelButtonTemplate')
 recommend:SetSize(130,20);recommend:SetPoint('RIGHT',b,'LEFT',-8,0);recommend:SetFrameLevel(frame:GetFrameLevel()+4)
 recommend:SetText('天赋推荐');recommend:SetScript('OnClick',function()W.RecommendFromDoctor(frame)end)
 recommend:SetScript('OnEnter',function(self)GameTooltip:SetOwner(self,'ANCHOR_BOTTOM');GameTooltip:SetText('查看当前专精推荐');GameTooltip:AddLine('保留原天赋窗口和未保存草稿，按当前专精与等级打开推荐；不会自动保存、绑定或洗点。',1,1,1,true);GameTooltip:Show()end)
 recommend:SetScript('OnLeave',function()GameTooltip:Hide()end)
 frame.rebornRecommendation= recommend
end
function W.Register(key,frame)
 if not frame then return end
 W.frames[key]=frame
 if key=='witchDoctor'then W.AddReturn(frame)end
 if frame.rebornTG4CWindowHook then return end
 frame.rebornTG4CWindowHook=true
 if own(key)then
  frame:HookScript('OnShow',function(self)W.HideOthers(self);W.Focus(self)end)
  frame:HookScript('OnMouseDown',function(self)W.Focus(self)end)
  frame:HookScript('OnDragStart',function(self)W.Focus(self)end)
 end
 if key=='guide'or key=='recommendationTree'then
  frame:HookScript('OnHide',function()
   if StaticPopup_Hide then for _,name in ipairs({'REBORN_TG_WD_DRAFT','REBORN_TG_PALADIN','REBORN_TG_APPLY'})do StaticPopup_Hide(name)end end
  end)
 end
end
function W.Prepare(key)W.HideOthers(W.frames[key])end
function W.Install()
 W.Register('guide',RebornTalentGuide and RebornTalentGuide.frame)
 W.Register('witchDoctor',RebornWDTreePreview)
 W.Register('witchDoctorHome',RebornWDSpecHome)
 W.Register('native',PlayerTalentFrame)
end
function W.OpenDoctor()
 W.Install()
 if RebornWDTreePreview and RebornWDTreePreview:IsShown()then W.Focus(RebornWDTreePreview);return end
 if RebornWDTreePreviewAPI and RebornWDTreePreviewAPI.Open then RebornWDTreePreviewAPI.Open();W.Install();W.Focus(RebornWDTreePreview)end
end
local open=RebornTalentGuide.Open
function RebornTalentGuide.Open(...)
 W.Install()
 if InCombatLockdown()and PlayerTalentFrame and PlayerTalentFrame:IsShown()then RebornTalentGuide.Message('请脱战后打开天赋推荐');return end
 local result=open(...);W.Install();W.Focus(RebornTalentGuide.frame);return result
end
local event=CreateFrame('Frame');event:RegisterEvent('ADDON_LOADED');event:RegisterEvent('PLAYER_LOGIN');event:SetScript('OnEvent',W.Install)
local elapsed=0;event:SetScript('OnUpdate',function(_,dt)
 elapsed=elapsed+dt;if elapsed<.2 then return end;elapsed=0
 local created=RebornWDTreePreview and not RebornWDTreePreview.rebornTG4CWindowHook and RebornWDTreePreview:IsShown()
 W.Install();if created then W.Focus(RebornWDTreePreview)end
end)
W.Install()
