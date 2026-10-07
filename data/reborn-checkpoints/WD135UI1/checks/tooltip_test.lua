local known = false
function IsSpellKnown(id) return known end
local lines, links = {}, {}
GameTooltip = {
 SetOwner=function() end,
 SetText=function(self,t) lines={t} end,
 AddLine=function(self,t) lines[#lines+1]=t end,
 SetHyperlink=function(self,t) links[#links+1]=t end,
 Show=function() end,
}
local function Tooltip(self)
    GameTooltip:SetOwner(self, 'ANCHOR_RIGHT')
    local id = self:GetAttribute('choiceID') or self:GetAttribute('selectedID')
    -- Empty slots describe their purpose, never preview an unlearned spell.
    if not id or not IsSpellKnown(id) then
        local labels = {
            [9003540] = '一键放置技能栏 / Ritual slot',
            [9003541] = '召唤物回收技能栏 / Recall slot',
            [9003673] = '独立守卫技能栏 / Independent Ward slot',
            [9003580] = '大巫毒技能栏 / Big Bad Voodoo slot',
            [9003800] = '魔像技能栏 / Golem slot',
        }
        local label = labels[self.utilityID] or self.category or '召唤技能栏 / Summon slot'
        GameTooltip:SetText(label, 1, .82, 0)
        GameTooltip:AddLine('此栏用于放置已学会的对应技能。', 1, 1, 1, true)
        GameTooltip:AddLine('This slot holds learned skills of this category.', .7, .75, .8, true)
        GameTooltip:Show()
        return
    end
    if id then GameTooltip:SetHyperlink('spell:' .. id)
    else GameTooltip:SetText(self.category or '巫医召唤栏', 1, .82, 0) end
    if self.dedicatedSummon then
        GameTooltip:AddLine(self.utilityID == 9003673 and '独立守卫 / Independent Ward' or (self.utilityID == 9003800 and '独立魔像 / Independent Golem' or '独立召唤 / Independent Summon'), .3, 1, .6)
        GameTooltip:AddLine('左键单独施放；不占守卫、神像或雕像槽，不包含在三类一键放置或回收中。', 1, 1, 1, true)
        GameTooltip:AddLine('Left-click to cast separately. Uses no Ward, Idol or Effigy slot; excluded from three-slot placement and recall.', .7, .75, .8, true)
        if not IsSpellKnown(self.utilityID) then
            GameTooltip:AddLine(self.utilityID == 9003673 and '尚未学习：在通用天赋中选择拟态守卫，保存并激活方案。' or (self.utilityID == 9003800 and '尚未学习战争魔像：在巫毒天赋中选择，保存并激活方案。' or '尚未学习大巫毒。学会后此槽自动显示技能。'), 1, .3, .3, true)
            GameTooltip:AddLine(self.utilityID == 9003673 and 'Not learned: select Mimic Ward in the Class tree, then save and activate the build.' or (self.utilityID == 9003800 and 'Not learned: select War Golem in the Voodoo tree, then save and activate the build.' or 'Big Bad Voodoo is not learned. This slot fills when learned.'), 1, .3, .3, true)
        end
    elseif self.utilityID then
        GameTooltip:AddLine(self.utilityID == 9003540 and '一次施放当前三个槽选中的召唤技能；仍需足够法力且技能冷却完毕。' or '回收自己的三类召唤物，返还成功召唤时实际法力费用的50%。', 1, 1, 1, true)
        if not IsSpellKnown(self.utilityID) then GameTooltip:AddLine('30级向巫医导师学习。', 1, .3, .3) end
    elseif self.isMain then
        GameTooltip:AddLine(self.category, .3, 1, .6)
        GameTooltip:AddLine('左键施放；右键或上方箭头展开选择。', 1, 1, 1, true)
        if not id then GameTooltip:AddLine('本类尚未学习召唤技能。', .7, .7, .7) end
    else
        GameTooltip:AddLine('点击选入主槽，再点击主槽施放。', 1, 1, 1, true)
    end
    GameTooltip:Show()
end

for _,id in ipairs({9003540,9003541,9003673,9003580,9003800}) do
 local b={utilityID=id,dedicatedSummon=id>=9003673 or id==9003580}
 function b:GetAttribute(k) if k=='choiceID' then return id end end
 known=false;links={};Tooltip(b)
 assert(#links==0 and #lines==3)
 known=true;links={};Tooltip(b);assert(links[1]=='spell:'..id)
end
for _,category in ipairs({'Ward','Idol','Effigy'}) do
 local b={category=category,isMain=true}
 function b:GetAttribute(k) return nil end
 known=false;links={};Tooltip(b);assert(#links==0 and lines[1]==category and #lines==3)
end
print('PASS: 8 empty slot tooltips; 5 learned utility hyperlinks')
