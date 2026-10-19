-- TG7B: one scaling owner for the guide; migrate the old size preference once.
local G=RebornTalentGuide
function G.DecorateWindow()
 local f=G.frame;local C=RebornTalentTreeCanvas;if not f or not C then return end
 if f.rebornScaleGrips then return end
 RebornTGScaleDB=RebornTGScaleDB or{};local db=RebornTGScaleDB;db.windows=db.windows or{}
 if db.windows.RebornTalentGuideFrame==nil and tonumber(db.scale)then db.windows.RebornTalentGuideFrame=tonumber(db.scale)end
 C.AttachScale(f,'RebornTalentGuideFrame');f.rebornScaleGrip=f.rebornScaleGrips[1]
 f:HookScript('OnShow',function()C.Fit(f)end);C.Fit(f)
end
local waiter=CreateFrame('Frame');waiter:SetScript('OnUpdate',function(self)if G.frame and RebornTalentTreeCanvas then G.DecorateWindow();self:SetScript('OnUpdate',nil)end end)
