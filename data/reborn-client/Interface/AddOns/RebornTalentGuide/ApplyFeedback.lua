-- TG16A: explain the exact live eligibility result; never bypass its guards.
local G=RebornTalentGuide;local W=G.WD;local F={};G.ApplyFeedback=F
local function update()
 if not G.frame or not G.apply then return end
 if not F.blocker then
  local b=CreateFrame('Frame',nil,G.frame);b:SetAllPoints(G.apply);b:SetFrameLevel(G.apply:GetFrameLevel()+4);b:EnableMouse(true);F.blocker=b
  b:SetScript('OnEnter',function(self)
   if not F.reason then return end
   GameTooltip:SetOwner(self,'ANCHOR_RIGHT');GameTooltip:SetText('暂不能载入推荐',1,.45,.25)
   GameTooltip:AddLine(F.reason,1,.85,.65,true);GameTooltip:AddLine('不会自动删点、洗点或收费。',.8,.85,.9,true);GameTooltip:Show()
  end)
  b:SetScript('OnLeave',function()GameTooltip:Hide()end)
  b:SetScript('OnMouseUp',function()if F.reason then G.Message(F.reason);G.Refresh()end end)
 end
 if G.catalogClass~='巫医'or not G.Navigation or G.Navigation.State().source~='recommended'then
  F.blocker:Hide();F.reason=nil;G.status:SetHeight(48);G.status:SetTextColor(.85,.85,.85);return
 end
 local result,why=W.CheckDraft(W.selected,W.previewLevel or UnitLevel('player'))
 G.status:SetHeight(80);G.status:SetFont(STANDARD_TEXT_FONT or'Fonts\\FRIZQT__.TTF',14,'OUTLINE')
 if result then
  F.reason=nil;F.blocker:Hide();G.apply:Enable()
  G.apply:SetText('保留已学，补 AE '..result.addedAE..' / TE '..result.addedTE)
  G.status:SetTextColor(.5,1,.6)
  G.status:SetText('可保留已存点数，补入 '..#result.order..' 级推荐节点。\n树图是标准推荐；实际补点请看确认及草稿，核对后保存。')
 else
  F.reason=why or'当前状态暂不可用';F.blocker:Show();G.apply:Disable()
  G.status:SetTextColor(1,.65,.35);G.status:SetText('暂不能载入：\n'..F.reason)
 end
end
local refresh=G.Refresh
function G.Refresh(...)local result=refresh(...);update();return result end
