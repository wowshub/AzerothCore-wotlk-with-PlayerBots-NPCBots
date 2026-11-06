-- WHTAL2A: scoped compatibility adapters; extracted CoA functions below are unchanged.
-- Original authors: Ascension Team. No global C_ClassInfo/C_CharacterAdvancement replacement.
RebornWHOriginalUI={}
local O=RebornWHOriginalUI
O.specs={{["id"]=10,["token"]="BOLTSLINGER",["name"]="Boltslinger",["description"]="Use crossbows to strike down enemies at a medium distance with unparalleled mobility.",["identity"]=4010,["Class"]="WITCHHUNTER",["Spec"]="BOLTSLINGER",["Name"]="Boltslinger",["tab"]=39,["zh"]="弩枪手",["descriptionZh"]="使用弩箭在中距离击倒敌人，并以卓越的机动性掌控战斗。",["Difficulty"]="Normal",["Role"]="ranged",["Primary"]={"Agility","Intellect"},["SampleSpells"]={705492,500085,800165},["samples"]={0,29150,31160}},{["id"]=11,["token"]="DARKNESS",["name"]="Houndmaster",["description"]="Use guns and a shadowhound companion to blast enemies into oblivion from across the battlefield.",["identity"]=4011,["Class"]="WITCHHUNTER",["Spec"]="DARKNESS",["Name"]="Houndmaster",["tab"]=40,["zh"]="猎犬大师",["descriptionZh"]="使用枪械和暗影猎犬伙伴，从战场各处向敌人倾泻火力。",["Difficulty"]="Normal",["Role"]="ranged",["Primary"]={"Agility","Intellect"},["SampleSpells"]={680234,680238,807918},["samples"]={0,30187,7414}},{["id"]=12,["token"]="INQUISITION",["name"]="Inquisition",["description"]="Use dual weapons to hunt the evil doers of Azeroth, burning them in searing flames of judgement.",["identity"]=4012,["Class"]="WITCHHUNTER",["Spec"]="INQUISITION",["Name"]="Inquisition",["tab"]=41,["zh"]="审判者",["descriptionZh"]="挥舞双武器追猎艾泽拉斯的邪恶，以炽烈的审判之火焚尽敌人。",["Difficulty"]="Normal",["Role"]="melee",["Primary"]={"Agility","Intellect"},["SampleSpells"]={503710,802269,802020},["samples"]={0,6622,7097}},{["id"]=97,["token"]="WITCHKNIGHT",["name"]="Black Knight",["description"]="Don your witchmail and wield a two-handed sword to deflect attacks and defend allies.",["identity"]=7553,["Class"]="WITCHHUNTER",["Spec"]="WITCHKNIGHT",["Name"]="Black Knight",["tab"]=94,["zh"]="黑骑士",["descriptionZh"]="身披猎巫锁甲，挥动双手剑格挡敌人的攻势，保护盟友。",["Difficulty"]="Medium",["Role"]="tank",["Primary"]={"Agility","Stamina"},["SampleSpells"]={680489,802269,802280},["samples"]={0,6622,7569}}}
local C_ClassInfo={}
function C_ClassInfo.GetAllSpecs()local v={};for _,s in ipairs(O.specs)do v[#v+1]=s.Spec end;return v end
function C_ClassInfo.GetSpecInfo(_,token)for _,s in ipairs(O.specs)do if s.Spec==token then return s end end end
function C_ClassInfo.GetSpecInfoByID(id)for _,s in ipairs(O.specs)do if s.id==id then return s end end end
local CharacterAdvancementUtil={GetClassDBCByFile=function()return "WITCHHUNTER"end,GetSpecDBCByFile=function(token)return C_ClassInfo.GetSpecInfo(nil,token).tab end,
 GetBackgroundAtlas=function(_,token)return "talents-background-witchhunter-"..token:lower()end}
local Const={TextureKit={IgnoreAtlasSize=false}}
local C_CharacterAdvancement={GetActiveChrSpec=function()return nil end} -- browsing never claims activation
local CreateFramePool
local CoASpecViewMixin={}
local CoATreeViewMixin={}
-- BEGIN unchanged original CoASpecViewMixin functions
function CoASpecViewMixin:OnLoad()
    self.class = select(2, UnitClass("player"))
    self.Background:SetAtlas("spec-background", Const.TextureKit.IgnoreAtlasSize)
    self.SpecChoicePool = CreateFramePool("Frame", self, "CoASpecChoiceTemplate")

    local specs = C_ClassInfo.GetAllSpecs(self.class)
    local numSpecs = #specs
    local choiceWidth = self:GetWidth() / math.max(numSpecs, 1)
    local choiceHeight = self:GetHeight()

    local specInfo, choiceFrame
    for i, spec in ipairs(specs) do
        specInfo = C_ClassInfo.GetSpecInfo(self.class, spec)
        choiceFrame = self.SpecChoicePool:Acquire()
        choiceFrame:SetSpecInfo(specInfo, choiceWidth, choiceHeight, i == 1, i == numSpecs)
        choiceFrame:SetPoint("LEFT", choiceWidth*(i-1), 0)
        choiceFrame:SetDividerShown(i ~= numSpecs)
        choiceFrame:Show()
    end

end
function CoASpecViewMixin:OnShow()
    local activeSpecID = C_CharacterAdvancement.GetActiveChrSpec()
    for choiceFrame in self.SpecChoicePool:EnumerateActive() do
        choiceFrame:UpdateVisualState(choiceFrame:GetSpecID() == activeSpecID)
    end
end
-- END unchanged original functions
-- BEGIN unchanged original CoATreeViewMixin:SetSpecID
function CoATreeViewMixin:SetSpecID(specID)
    if self.specID == specID then
        return
    end

    self.specID = specID
    local specInfo = C_ClassInfo.GetSpecInfoByID(specID)
    local specFile = specInfo.Spec
    local specDBC = CharacterAdvancementUtil.GetSpecDBCByFile(specFile)
    local classDBC = CharacterAdvancementUtil.GetClassDBCByFile(specInfo.Class)
    self.SpecTree.Label:SetText(specInfo.Name:upper())
    local specArt = CharacterAdvancementUtil.GetBackgroundAtlas(specInfo.Class, specInfo.Spec)
    self.Background1:SetAtlas(specArt)
    --self.Background2:SetAtlas(specArt)
    self.Background3:SetAtlas(specArt)
    self.SpecTree:SetClassTab(classDBC, specDBC)
end
-- END unchanged original function
function O.BuildHome(home,createCard,applyAtlas)
 home.Background.SetAtlas=function(texture,key)applyAtlas(texture,key)end
 CreateFramePool=function(_,parent,template)
  assert(template=="CoASpecChoiceTemplate")
  local pool={active={}}
  function pool:Acquire()local card=createCard(parent);self.active[#self.active+1]=card;return card end
  function pool:EnumerateActive()local i=0;return function()i=i+1;return self.active[i]end end
  return pool
 end
 CoASpecViewMixin.OnLoad(home);CoASpecViewMixin.OnShow(home)
end
function O.SelectSpec(view,id,applyAtlas)
 view.Background1.SetAtlas=function(texture,key)applyAtlas(texture,key)end
 view.Background3.SetAtlas=function(texture,key)applyAtlas(texture,key)end
 CoATreeViewMixin.SetSpecID(view,id)
end

-- Original sample spell icons: passive first, then example spells, as CoASpecChoiceMixin does.
local samples={["10"]={{["spell"]=705492,["node"]=0,["name"]="Boltslinger",["icon"]="Interface\\RebornWitchHunter\\TalentUI\\Samples\\705492"},{["spell"]=500085,["node"]=29150,["name"]="Vault",["icon"]="Interface\\RebornWitchHunter\\TalentUI\\Samples\\500085"},{["spell"]=800165,["node"]=31160,["name"]="Witchbane",["icon"]="Interface\\RebornWitchHunter\\TalentUI\\Samples\\800165"}},["11"]={{["spell"]=680234,["node"]=0,["name"]="Houndmaster",["icon"]="Interface\\RebornWitchHunter\\TalentUI\\Samples\\680234"},{["spell"]=680238,["node"]=30187,["name"]="Shadow Trap",["icon"]="Interface\\RebornWitchHunter\\TalentUI\\Samples\\680238"},{["spell"]=807918,["node"]=7414,["name"]="Unleash the Hounds",["icon"]="Interface\\RebornWitchHunter\\TalentUI\\Samples\\807918"}},["12"]={{["spell"]=503710,["node"]=0,["name"]="Flames of Sin",["icon"]="Interface\\RebornWitchHunter\\TalentUI\\Samples\\503710"},{["spell"]=802269,["node"]=6622,["name"]="Burrow Bolt",["icon"]="Interface\\RebornWitchHunter\\TalentUI\\Samples\\802269"},{["spell"]=802020,["node"]=7097,["name"]="Dusk Blade",["icon"]="Interface\\RebornWitchHunter\\TalentUI\\Samples\\802020"}},["97"]={{["spell"]=680489,["node"]=0,["name"]="Grasp of the Undying",["icon"]="Interface\\RebornWitchHunter\\TalentUI\\Samples\\680489"},{["spell"]=802269,["node"]=6622,["name"]="Burrow Bolt",["icon"]="Interface\\RebornWitchHunter\\TalentUI\\Samples\\802269"},{["spell"]=802280,["node"]=7569,["name"]="Noctis Blade",["icon"]="Interface\\RebornWitchHunter\\TalentUI\\Samples\\802280"}}}
for _,s in ipairs(RebornWHOriginalUI.specs)do s.sampleDetails=samples[tostring(s.id)]end
