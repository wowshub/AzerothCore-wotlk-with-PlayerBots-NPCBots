-- TG15A: authoritative active-build totals and local plan totals are separate.
local G=RebornTalentGuide;local C=RebornTalentTreeCanvas;local S=RebornTalentCollections
local P={};G.PointSummary=P
local function number(n)return type(n)=='number'and n==n and n>=0 and n%1==0 end
function P.Current(bot)
 local level=UnitLevel('player');local M=G.WD.Ready()
 local result={level=level}
 if bot then result.reason='机器人浏览 · 本人点数不作机器人数据';return result end
 if not G.WD.IsDoctor()then result.reason='查看他职业 · 本人不是巫医';return result end
 if not M or not M.loaded or not M.modern or not M.layoutReady or not number(M.active)or M.active>2 or
  not M.aeMasks or not M.aeMasks[M.active+1]or not number(M.aeBudget)or not number(M.teBudget)then
  result.reason='角色'..level..'级 · 等待服务器方案';return result
 end
 if M.level~=level then result.reason='角色'..level..'级 · 等待同步（旧快照'..tostring(M.level)..'级）';return result end
 local ok,ae,te=pcall(function()return M.AESpent(M.aeMasks[M.active+1]),M.TESpent(M.aeMasks[M.active+1])end)
 if not ok or not number(ae)or not number(te)then result.reason='角色'..level..'级 · 点数暂不可读';return result end
 result.ae,result.te,result.aeBudget,result.teBudget=ae,te,M.aeBudget,M.teBudget
 result.aeLeft,result.teLeft=M.aeBudget-ae,M.teBudget-te
 result.reason='角色'..level..'级 · 已保存方案'..(M.active+1)
 return result
end
function P.CollectionPlan()
 local e=S.editor;if not e or e.build.class~='WITCHDOCTOR'then return nil end
 local ok,mask=pcall(S.Mask,e.build);if not ok or not mask then return nil end
 local counted,ae,te=pcall(function()return RebornWD8.AESpent(mask),RebornWD8.TESpent(mask)end)
 if not counted then return nil end
 return {level=e.build.level,ae=ae,te=te,label=e.dirty and'收藏编辑'or'收藏方案'}
end
local function text(parent,x,y,width,size)
 local t=C.Text(parent,x,y,width,'','GameFontHighlight')
 t:SetFont(STANDARD_TEXT_FONT or'Fonts\\FRIZQT__.TTF',size,'OUTLINE');t:SetHeight(size+4);return t
end
local function box(parent,x,y,width,height)
 local f=CreateFrame('Frame',nil,parent);f:SetPoint('TOPLEFT',x,y);f:SetSize(width,height);f:SetFrameLevel(parent:GetFrameLevel()+6)
 local bg=f:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints();bg:SetTexture(.018,.028,.04,.97)
 return f
end
local function val(n)return n==nil and'—'or tostring(n)end
local function left(current)
 if current.aeLeft==nil then return '|cffffbb66未同步前不显示旧额度|r'end
 local color=current.aeLeft<0 or current.teLeft<0
 return (color and'|cffff7777'or'|cff8fff92')..'剩余 AE '..current.aeLeft..' · TE '..current.teLeft..'|r'
end
local function planText(plan)
 if not plan then return '方案点数：暂不可读'end
 return plan.label..tostring(plan.level)..'级：AE '..val(plan.ae)..' · TE '..val(plan.te)
end
function P.UpdateGuide()
 if not G.frame then return end
 if not P.guide then
  local b=box(G.frame,428,-5,426,52);P.guide=b
  b.caption=text(b,6,-1,414,11);b.values=text(b,6,-15,414,18);b.plan=text(b,6,-37,414,11)
 end
 local b=P.guide
 if G.catalogClass~='巫医'then b:Hide();if G.titleText then G.titleText:SetWidth(700)end;G.context:SetWidth(900);return end
 b:Show();if G.titleText then G.titleText:SetWidth(390)end;G.context:SetWidth(390)
 local current=P.Current(G.fromBot);local result=G.WD.Build(G.WD.selected or 1,G.WD.previewLevel or UnitLevel('player'))
 local plan=result and{level=result.level,ae=result.ae,te=result.te,label='推荐'}or nil
 b.caption:SetText(current.reason..' · 已用 / 总额')
 b.values:SetText('|cff40dcffAE '..val(current.ae)..'/'..val(current.aeBudget)..(current.aeLeft~=nil and(' 余'..current.aeLeft)or'')..'|r    |cffffd15cTE '..val(current.te)..'/'..val(current.teBudget)..(current.teLeft~=nil and(' 余'..current.teLeft)or'')..'|r')
 b.plan:SetText(planText(plan)..'  |cffb7c3cf（大字＝角色已用/总额）|r')
 b.current=current;b.planData=plan
end
function P.UpdateCollection()
 if not S.frame then return end
 if not P.collection then
  local b=box(S.frame,1020,-133,245,112);P.collection=b
  b.caption=text(b,7,-4,231,11);b.values=text(b,7,-23,231,18)
  b.remaining=text(b,7,-47,231,13);b.plan=text(b,7,-68,231,11);b.planValues=text(b,7,-85,231,18)
 end
 local b=P.collection
 S.detailScroll:ClearAllPoints()
 if S.class~='WITCHDOCTOR'then b:Hide();S.detailScroll:SetPoint('TOPLEFT',1020,-133);S.detailScroll:SetSize(245,440);return end
 b:Show();S.detailScroll:SetPoint('TOPLEFT',1020,-249);S.detailScroll:SetSize(245,324)
 local current=P.Current();local plan=P.CollectionPlan()
 b.caption:SetText(current.reason)
 b.values:SetText('|cff40dcffAE '..val(current.ae)..'/'..val(current.aeBudget)..'|r   |cffffd15cTE '..val(current.te)..'/'..val(current.teBudget)..'|r')
 b.remaining:SetText(left(current));b.plan:SetText(plan and(plan.label..plan.level..'级（未应用）')or'尚未选择收藏')
 b.planValues:SetText(plan and('|cff40dcffAE '..val(plan.ae)..'|r   |cffffd15cTE '..val(plan.te)..'|r')or'—')
 b.current=current;b.planData=plan
end
local refresh=G.Refresh
function G.Refresh(...)local result=refresh(...);P.UpdateGuide();return result end
local refreshCollection=S.Refresh
function S.Refresh(...)local result=refreshCollection(...);P.UpdateCollection();return result end

-- The independent recommendation tree has a dedicated full-width summary row.
local T=G.TreeViews;local refreshTree=T.RefreshWD
function T.RefreshWD(...)
 local result=refreshTree(...)
 if T.frame then
  local current=P.Current(G.fromBot);local plan=G.WD.Build(G.WD.selected or 1,G.WD.previewLevel or UnitLevel('player'))
  T.frame.title:SetText('巫医推荐 · 天赋树预览 · TG16A')
  T.summary:SetFont(STANDARD_TEXT_FONT or'Fonts\\FRIZQT__.TTF',17,'OUTLINE');T.summary:SetHeight(24)
  T.summary:SetText(current.reason..'  |cff40dcffAE '..val(current.ae)..'/'..val(current.aeBudget)..'|r  |cffffd15cTE '..val(current.te)..'/'..val(current.teBudget)..'|r  '..left(current)..(plan and('  ｜推荐'..plan.level..'级：AE '..plan.ae..' · TE '..plan.te)or''))
 end
 return result
end
