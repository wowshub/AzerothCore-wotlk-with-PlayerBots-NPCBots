-- WOW64CREATOR1G. Esteria-style panels, Reborn identity/eligibility/quote contracts.

-- No Hero/Fate/Freeborn protocol, no new race IDs, no faction or spawn writes.

-- Append after current CharacterCreate.lua/RebornRacePreview.lua and XML-owned controls.

(function()

local C={active=false,step=1,page=1,group='Alliance',rows={},tiles={},mode='default',revision=0,elapsed=0}

RebornCreator=C

local ES=RebornCreatorStyle

local GOLD,TEXT,MUTED=ES.GOLD,ES.TEXT,ES.MUTED

local names={'种族','职业','外观','阵营与出生地'}

local tokens={WARRIOR=1,PALADIN=2,HUNTER=3,ROGUE=4,PRIEST=5,DEATHKNIGHT=6,SHAMAN=7,MAGE=8,WARLOCK=9,DRUID=11,WITCHDOCTOR=13,MONK=14,WITCHHUNTER=15}

local labels={WARRIOR='战士',PALADIN='圣骑士',HUNTER='猎人',ROGUE='潜行者',PRIEST='牧师',DEATHKNIGHT='死亡骑士',SHAMAN='萨满祭司',MAGE='法师',WARLOCK='术士',DRUID='德鲁伊',WITCHDOCTOR='巫医',MONK='武僧',WITCHHUNTER='猎巫者'}

local NativeRace,NativeClass,NativeSex=SetSelectedRace,SetSelectedClass,SetSelectedSex

local oldShow,oldHide,oldUpdate=CharacterCreate_OnShow,CharacterCreate_OnHide,CharacterCreateFrame_OnUpdate

local oldFinish,oldEnsure=CharacterCreate_Finish,CharacterCreate_EnsureCreateSelection

local oldBack=CharacterCreate_Back

local clean=function(s) return (tostring(s or ''):gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r','')) end

local truth=function(v) return v~=nil and v~=false and v~=0 end

local function setShown(f,on) if f then if on then f:Show() else f:Hide() end end end

local function text(parent,size,color)

 local f=parent:CreateFontString(nil,'OVERLAY');f:SetFont('Fonts\\ARKai_T.ttf',size,'');f:SetTextColor(unpack(color or TEXT));f:SetJustifyH('LEFT');return f

end

local function button(parent,label,width,height,fn)

 local b=CreateFrame('Button',nil,parent);b:SetSize(width,height);b:EnableMouse(true)

 b.bg=ES.Solid(b,'BACKGROUND',ES.INK,0);b.bg:SetAllPoints(b)

 b.edges=ES.Border(b,GOLD,0);b.label=text(b,15,GOLD);b.label:SetPoint('CENTER');b.label:SetSize(width-8,height-4);b.label:SetJustifyH('CENTER');b.label:SetText(label)

 b:SetScript('OnClick',fn);b:SetScript('OnEnter',function() b.label:SetTextColor(1,0.9,0.65) end)

 b:SetScript('OnLeave',function() b.label:SetTextColor(unpack(GOLD)) end);return b

end

-- NEUTRAL2D: disabled and selected are independent visual states.
local function sexButton(b,allowed,selected)
 if allowed then b:Enable() else b:Disable() end
 b:SetAlpha(allowed and 1 or 0.4)
 local color=not allowed and MUTED or selected and GOLD or TEXT
 b.label:SetTextColor(unpack(color));ES.Tint(b.edges,GOLD,allowed and selected and 1 or 0.12)
 b:SetScript('OnEnter',function() if allowed then b.label:SetTextColor(1,0.9,0.65) end end)
 b:SetScript('OnLeave',function() b.label:SetTextColor(unpack(color)) end)
end
local function settleLockedSex()
 local lock=C.race and C.race.only
 if lock~=nil then
  local sex=lock==1 and SEX_FEMALE or SEX_MALE
  if GetSelectedSex()~=sex then NativeSex(sex) end
 end
end

local function say(t) if C.status then C.status:SetText(t or '') end end

local function locked() return RebornCharacterSlotQuoteFrame and RebornCharacterSlotQuoteFrame:IsShown() end

local function state()

 if type(RebornCreationGetState)~='function' then return end

 return RebornCreationGetState()

end

local function metadata(file)

 return RebornCreatorData[string.upper(file or '')] or {}

end

-- WOW64SEVEN1A: actual new identities, not donor race IDs or list indices.
local seven={
 SEVENDARKFALLEN={id=43,name='暗落者',portrait='Darkfallen',faction='Alliance'},
 SEVENSKYBORNE={id=52,name='高阶天裔',portrait='Skyborne',faction='Alliance'},
 SEVENVRYKUL={id=57,name='维库人',portrait='VrykulHorde',faction='Horde'},
 SEVENOGRE={id=66,name='单头食人魔',portrait='OgreHorde',faction='Horde'},
 SEVENKYRIAN={id=108,name='格里恩',portrait='KyrianAlliance',faction='Alliance'},
 SEVENHARANIR={id=80,name='哈籁尼尔',portrait='Haranir',faction='Alliance'},
 ETHEREALALLIANCE={id=109,name='虚灵',faction='Horde'},
 MOGUALLIANCE={id=123,name='魔古族',faction='Alliance'},
 SUREKIALLIANCE={id=86,name='Sureki',faction='Alliance'},
 MURLOCHORDE={id=121,name='矮小鱼人',faction='Horde'},
}
local race12={
 STORMFORGEDALLIANCE={id=84,faction="Alliance"},
 ["ARAKKOA"]={id=79,faction="Alliance"},
 ["TUSKARR"]={id=28,faction="Alliance"},
 ["DRAKKARITROLL"]={id=41,faction="Horde"},
 ["REFORGEDFURBOLG"]={id=50,faction="Alliance"},
 ["GNOMEUNDEAD"]={id=51,faction="Horde"},
 ["MECHAGNOME"]={id=67,faction="Alliance"},
 ["EARTHEN"]={id=68,faction="Alliance"},
 ["JINYU"]={id=78,faction="Alliance"},
 ["DRAKKINALLIANCE"]={id=99,faction="Alliance"},
 ["VENTHYRHORDE"]={id=101,faction="Horde"},
 ["CENTAURHORDE"]={id=102,faction="Horde"},
 ["SYLVARIALLIANCE"]={id=110,faction="Horde"},
 ["HIGHMOUNTAINHD"]={id=125,faction="Horde"},
}
local neutralOriginIDs={["BANSHEEHORDE"]=90,["DRAKONIDHORDE"]=98,["DREADLORDHORDE"]=89,["FELORCNEUTRAL"]=116,["FUNGARIANALLIANCE"]=93,["GNOLLHORDE"]=83,["GRUMMLE"]=103,["HARPY"]=56,["HOZENALLIANCE"]=112,["LOSTONEALLIANCE"]=73,["MANTIDHORDE"]=106,["SABERONHORDE"]=97,["SKELETONNEUTRAL"]=114,["SPORELINGALLIANCE"]=76,["TAUNKANEUTRAL"]=115,["THINHUMAN"]=96}
local function readRaces()

 local v={GetAvailableRaces()};C.races={};C.byIndex={}

 local previews={}

 for _,f in pairs(_G) do

  if type(f)=='table' and type(f.e)=='table' and f.e.f and type(f.GetScript)=='function' then previews[f.e.f]=f end

 end

 for n=1,#v,3 do

  local i=(n+2)/3;local file=string.upper(v[n+1] or '');local m=metadata(file)

  local _,faction=GetFactionForRace(i);local p=previews[file]

  if RebornCreatorPreviewByFile and RebornCreatorPreviewByFile[file] then p={e=RebornCreatorPreviewByFile[file]} end

  local e={index=i,name=clean(p and p.e.n or v[n]),nativeName=clean(v[n]),file=file,id=nil,enabled=truth(v[n+2]),faction=faction,preview=p}

  local portrait=p

  if not portrait then for j=1,(MAX_RACES or 25) do local b=_G['CharCreateRaceButton'..j];if b and b:GetID()==i then portrait=b;break end end end

  local tex=portrait and portrait.GetNormalTexture and portrait:GetNormalTexture()

  if tex and tex.GetTexture then e.icon=tex:GetTexture();if tex.GetTexCoord then e.coords={tex:GetTexCoord()} end end

  e.neutral=p and p.e.neutral or false;e.only=p and p.e.only
  if neutralOriginIDs[file] then e.id=neutralOriginIDs[file];e.neutral=true;e.only=(e.id==56 or e.id==90) and 1 or 0 end

  local migrated=race12[file]
  if migrated then
   e.id=migrated.id;e.faction=migrated.faction;e.neutral=false
   if e.id==99 then e.only=nil end -- RACE12B2: preserve the authored female identity, do not infer a gender lock from its asset filename.
  end
  local added=seven[file]
  if added then
   e.id=added.id;e.name=added.name;e.nativeName=added.name;e.faction=added.faction
   e.neutral=false;e.only=nil;e.seven=added
   e.preview={e={n=added.name,horde=added.faction=='Horde',sc=added.faction=='Horde' and 12 or 5}}
  end
  -- Keep old Darkfallen38 hidden; the explicitly requested source has its own identity.

  if file~='TUSKARRNEUTRAL' and (added or (file~='DARKFALLEN' and file~='REBORN_DARKFALLEN' and e.name~='暗落者')) then

   table.insert(C.races,e);C.byIndex[i]=e

  end

 end

end

local function sync()

 local _,_,idx=GetSelectedClass();C.race=C.byIndex[GetSelectedRace()];C.classIndex=idx

 local actual,_,_,nativeIndex=state()

 if C.race and nativeIndex==GetSelectedRace() and actual then

  C.race.id=actual

  local m=RebornCreatorRaceByID and RebornCreatorRaceByID[actual]

  C.race.name=clean(C.race.preview and C.race.preview.e.n or m and m.name or C.race.nativeName)

 end

 CharacterCreate.selectedRace=GetSelectedRace();CharacterCreate.selectedClass=idx;CLASS_ALMACENADA=idx

 CharacterCreate.customSelectedRace=nil;CharacterCreate.extraRaceButtonSelection=nil

 if CharacterCreate_IsExtraRaceId and CharacterCreate_IsExtraRaceId(GetSelectedRace()) then

  CharacterCreate.customSelectedRace=GetSelectedRace();CharacterCreate.extraRaceButtonSelection=CharacterCreate_GetExtraRaceKeyForRaceId(GetSelectedRace())

 end

 if CharacterCreate_RegisterSafeRaceId then CharacterCreate_RegisterSafeRaceId(GetSelectedRace(),false) end

end

local function allow(index)

 local cl=C.classes and C.classes[index]

 if not cl or not cl.enabled or not tokens[cl.token] then return false end

 local ok=IsRaceClassValid(GetSelectedRace(),index)

 if not truth(ok) then return false end

 if CharacterCreate_IsRaceClassValidSafe then return truth(CharacterCreate_IsRaceClassValidSafe(GetSelectedRace(),index)) end

 return true

end

local function readClasses()

 local v={GetAvailableClasses()};C.classes={}

 for n=1,#v,3 do

  local i=(n+2)/3;local token=string.upper(v[n+1] or '')

  C.classes[i]={index=i,name=labels[token] or clean(v[n]),token=token,enabled=truth(v[n+2])}

 end

 -- Reuse the installed eligibility enumerator, including the three custom-class policies.

 CharacterCreateEnumerateClasses(unpack(v))

 sync()

end

local function preview()

 if not C.active then return false end

 local _,token=GetSelectedClass();token=string.upper(token or '')

 local cls=tokens[token];local costume=({WITCHDOCTOR=7,MONK=4,WITCHHUNTER=3})[token] or cls

 local command=({default='DEFAULT_EQUIPMENT_PREVIEW_TEST',none='NO_EQUIPMENT_PREVIEW_TEST'})[C.mode]

 if C.mode=='t14' and costume then command=string.format('T14_EQUIPMENT_PREVIEW_TEST_C%02d',costume) end

 if not command then say('未找到该职业的装备预览配置。');return false end

 local ok=R27_NoEquipmentCommand(command)

 if not ok then say('装备预览尚未就绪；请等待模型加载。');return false end

 return true

end

local function changed()

 C.revision=C.revision+1

 -- One settled redraw, not five undress/re-equip pulses. Readiness polling never changes selections.

 C.retry={revision=C.revision,at=0,total=0}

 sync()

end

local function hideLegacy()

 -- Keep the ModelFFX scene visible; hide its old controls container as a whole.

 -- Our root is a sibling, and the existing quote dialog is reparented when opened.

 CharacterCreateFrame:Hide()

 for _,name in ipairs({'CharCreateRaceFrame','CharCreateClassFrame','CharCreateCustomizationFrame','CharCreatePreviewFrame','CharCreateBackButton','CharCreateOkayButton','CharacterCreateRandomName','CharCreateRandomizeButton','CustomizationBG','CustomizationLogoAlliance','CustomizationTextAlliance','CustomizationLogoHorde','CustomizationTextHorde','NewHabilidadesText','NewHabilidadesText2','RebornPreviewNudge','CharacterCreateZoom1','CharacterCreateZoom2'}) do setShown(_G[name],false) end

 if CharacterCreateFrame.GetRegions then

  for _,region in ipairs({CharacterCreateFrame:GetRegions()}) do setShown(region,false) end

 end

 for _,f in pairs(_G) do

  if type(f)=='table' and type(f.GetName)=='function' then

   local n=f:GetName()

   if n and (n:match('^Reborn.*PreviewButton$') or n:match('^CharCreateRaceButton%d+$')) then setShown(f,false) end

  end

 end

 -- Legacy clothing controls are discovered by owner, rather than depending on historical button names.

 if CharacterCreate and type(CharacterCreate.dracthyrPreviewButtons)=='table' then for _,b in pairs(CharacterCreate.dracthyrPreviewButtons) do setShown(b,false) end end

end

local function detail(title,body)

 C.detailTitle:SetText(title or '');C.detailBody:SetText(clean(body or ''))

end

local function selectedLore(kind,token)

 if not GetFlavorText or not token then return '' end

 local ok,result=pcall(GetFlavorText,kind..token,GetSelectedSex());return ok and type(result)=='string' and result or ''

end

local function applyScene(e)

 local a=e and e.preview and e.preview.e

 if a then

  local female=GetSelectedSex()==SEX_FEMALE

  local scene=(female and a.scF) or a.sc or (a.horde and 12 or 5)

  CharacterCreate.backgroundRaceByListId=CharacterCreate.backgroundRaceByListId or {}

  CharacterCreate.backgroundRaceByListId[e.index]=scene

  local applied=false

  if a.zanda and CharacterCreate_SetStageIZandalariBackground then applied=CharacterCreate_SetStageIZandalariBackground() end

  if not applied and a.night and CharacterCreate_SetStageHNightborneBackground then applied=CharacterCreate_SetStageHNightborneBackground() end

  if not applied and a.drac and CharacterCreate_SetDracthyrBackground then applied=CharacterCreate_SetDracthyrBackground(1) end

  if not applied and SetBackgroundModel then SetBackgroundModel(CharacterCreate,scene>=12 and 'ORC' or 'HUMAN',scene,1) end

  local pos=(female and a.posF) or a.pos or {0,0,0}

  if CharacterCreate.SetPosition then CharacterCreate:SetPosition(unpack(pos)) end

 else

  if CharacterCreate.SetPosition then CharacterCreate:SetPosition(0,0,0) end

  if CharacterCreate_SetCurrentBackground then CharacterCreate_SetCurrentBackground(1) end

 end

 CharacterCreate.r27WheelZoomLevel=1

end

function C.SelectRace(index)

 if locked() then return false end

 local e=C.byIndex[index];if not e or not e.enabled then return false end

 if index==GetSelectedRace() then
  if e.only~=nil and GetSelectedSex()~=(e.only==1 and SEX_FEMALE or SEX_MALE) then
   NativeSex(e.only==1 and SEX_FEMALE or SEX_MALE)
   C.startZone=nil;pcall(SetCreateStartZone,0);C.origin=nil;pcall(CycleCharCustomization,"RB_ORIGIN_CLEAR");changed();applyScene(e)
  end
  C.Render();return true
 end

 local previousToken=select(2,GetSelectedClass())

 if CharacterCreate_RegisterSafeRaceId then CharacterCreate_RegisterSafeRaceId(index,false) end

 -- Do not invoke a hidden legacy button's OnClick: it also rewrites class, gender and screen state.

 -- NEUTRAL1C: settle a locked gender on the previous valid race before native race initialization.
 if e.only~=nil then local sex=e.only==1 and SEX_FEMALE or SEX_MALE;if GetSelectedSex()~=sex then NativeSex(sex) end end
 C.startZone=nil;pcall(SetCreateStartZone,0);C.origin=nil;pcall(CycleCharCustomization,"RB_ORIGIN_CLEAR")
 NativeRace(index)

 if GetSelectedRace()~=index then say('种族切换未被客户端接受。');return false end

 if e.only~=nil then local sex=e.only==1 and SEX_FEMALE or SEX_MALE;if GetSelectedSex()~=sex then NativeSex(sex) end end

 sync();readClasses()

 local chosen

 for i,cl in ipairs(C.classes) do if cl.token==previousToken and allow(i) then chosen=i end end

 if not chosen then for i in ipairs(C.classes) do if allow(i) then chosen=i;break end end end

 if chosen and chosen~=C.classIndex then NativeClass(chosen) end

 sync();CharacterCreateFrame.state='CUSTOMIZATION';applyScene(e)

 changed();C.Render();return true

end

function C.SelectClass(index)

 if locked() then return false end

 if not allow(index) then say('该种族尚未开放这个职业。');return false end

 local _,nativeClass,_,_,_,componentClass=state()

 local expected=tokens[C.classes[index].token]

 if C.classIndex~=index or nativeClass~=expected or componentClass~=expected then NativeClass(index) end

 sync()

 if C.classIndex~=index then say('职业切换未被客户端接受。');return false end

 changed();C.Render();return true

end

function C.SelectSex(sex)

 if locked() then return false end

 if not C.race then return false end

 if C.race.only~=nil and sex~=(C.race.only==1 and SEX_FEMALE or SEX_MALE) then return false end

 if GetSelectedSex()~=sex then NativeSex(sex);sync();applyScene(C.race);changed() end;C.Render();return GetSelectedSex()==sex

end

function C.RandomName()

 if locked() then return false end

 local before=CharacterCreateNameEdit:GetText();local value=GetRandomName()

 if type(value)~='string' or value=='' or value==before then

  local sex=GetSelectedSex()==SEX_FEMALE and 1 or 0

  local kind=RebornPreviewGetNamePoolKind and RebornPreviewGetNamePoolKind(GetSelectedRace())

  local pool=RebornCreatorNamePools[(kind or '')..sex] or RebornCreatorNamePools[(C.race and C.race.faction=='Horde' and 'OGRE' or 'SETHRAK')..sex]

  if pool and #pool>0 then

   local first=math.random(1,#pool)

   for j=0,#pool-1 do local candidate=pool[(first+j-1)%#pool+1];if candidate~=before then value=candidate;break end end

  end

 end

 if type(value)=='string' and value~='' then CharacterCreateNameEdit:SetText(value);return true end

 say('暂未取得随机名字，请直接输入名字。');return false

end

local function features()
 if C.race and C.race.file=='MURLOCHORDE' then return {{field=1,name='肤色'}} end

 local list={}

 local translated={['Arm Upgrade']='机械臂升级',['Leg Upgrade']='机械腿升级',['Modification']='眼镜与机械改装',['Eyesight']='视力装置',['Eye Style']='眼部样式',['Paint']='金属涂装',['Beard Style']='胡须样式',['Skin Color']='肤色',['Skin']='肤色',['Face']='脸型',['Hair Style']='发型',['Hair Color']='发色',['Facial Hair']='面部特征',['Features']='外观细节',['Cloth Color']='布料颜色',['Glow Color']='光效颜色',['Head']='头部',['Arms']='手臂',['Chest']='胸部',['Legs']='腿部',['Eye Color']='眼睛颜色',['Horns']='角饰',['Tail']='尾部',['Scales']='鳞片',['Tattoo']='纹饰'}

 -- Native adapter fields are available only for races owned by that adapter. Legacy identities fall back to five native rows.

 local ok,first,count,label=pcall(CycleCharCustomization,'EA_GET',1)

 if ok and type(count)=='number' and count>0 and type(first)=='number' then

  for i=1,64 do

   local yes,value,total,name=pcall(CycleCharCustomization,'EA_GET',i)

   if yes and type(total)=='number' and total>0 and type(value)=='number' and type(name)=='string' and name~='' then

    local label=clean(name or '');label=translated[label] or (label:find('[\128-\255]') and label) or ('外观选项 '..i)

    table.insert(list,{field=i,adapter=true,name=label,value=value,count=total})

   end

  end

 end

 if #list==0 then for i,n in ipairs({'肤色','脸型','发型','发色','外观细节'}) do table.insert(list,{field=i,name=n}) end end

 return list

end

-- WOW64TWOFORMS1I: randomize the same adapter that supplies the displayed options.

function C.RandomAppearance()

 if locked() then return end

 settleLockedSex()

 local ok,value,count,label=pcall(CycleCharCustomization,'EA_GET',1)

 local adapter=ok and type(value)=='number' and type(count)=='number' and count>0 and type(label)=='string' and label~=''

 local yes

 if adapter then yes=pcall(CycleCharCustomization,'EA_RANDOM',1)

 else yes=pcall(RandomizeCharCustomization) end

 settleLockedSex()
 if not yes then say('外观尚未就绪，请稍后重试。');return end

 changed();C.Render()

end



function C.Cycle(field,delta,adapter)

 if locked() then return end

 if adapter then CycleCharCustomization('EA_CYCLE',field,delta) else CycleCharCustomization(field,delta) end

 changed();C.Render()

end

local function row(i)

 if C.rows[i] then return C.rows[i] end

 local b=button(C.left,'',284,52,function(self) if self.action then self.action() end end)

 b:SetPoint('TOPLEFT',C.left,'TOPLEFT',22,-146-(i-1)*58)

 b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetPoint('LEFT',8,0);b.icon:SetSize(38,38)

 b.label:ClearAllPoints();b.label:SetPoint('LEFT',54,0);b.label:SetWidth(150);b.label:SetJustifyH('LEFT')

 C.rows[i]=b;return b

end

local function put(i,label,action,enabled,active,icon,coords)

 local b=row(i);b.label:SetText(label);b.action=action

 if enabled then b:Enable();b.label:SetTextColor(unpack(active and GOLD or TEXT)) else b:Disable();b.label:SetTextColor(unpack(MUTED)) end

 ES.Tint(b.edges,GOLD,active and 1 or 0.18)

 b.icon:SetTexture(icon or 'Interface\\Icons\\INV_Misc_QuestionMark');b.icon:SetTexCoord(unpack(coords or {0,1,0,1}));b:Show()

end

local raceGenderPortraits={
 STORMFORGEDALLIANCE={'STORMFORGEDALLIANCE-male.blp','STORMFORGEDALLIANCE-female.blp'},
 MOGUALLIANCE={'MOGUALLIANCE-male.blp','MOGUALLIANCE-female.blp'},
 SUREKIALLIANCE={'SUREKIALLIANCE-male.blp','SUREKIALLIANCE-female.blp'},
 ARAKKOA={'ARAKKOA-male.blp','ARAKKOA-female.blp'},
 BROKEN={'BROKEN-male.blp','BROKEN-female.blp'},
 CENTAURALLIANCE={'CENTAURALLIANCE-male.blp','CENTAURALLIANCE-female.blp'},
 CENTAURHORDE={'CENTAURHORDE-male.blp','CENTAURHORDE-female.blp'},
 COABROKEN={'COABROKEN-male.blp','COABROKEN-female.blp'},
 DRAKKARITROLL={'DRAKKARITROLL-male.blp','DRAKKARITROLL-female.blp'},
 DRAKKINALLIANCE={'DRAKKINALLIANCE-male.blp','DRAKKINALLIANCE-female.blp'},
 EARTHEN={'EARTHEN-male.blp','EARTHEN-female.blp'},
 ETHEREALALLIANCE={'ETHEREALALLIANCE-male.blp','ETHEREALALLIANCE-female.blp'},
 FELORC={'FELORC-male.blp','FELORC-female.blp'},
 FORESTTROLL={'FORESTTROLL-male.blp','FORESTTROLL-female.blp'},
 GNOMEUNDEAD={'GNOMEUNDEAD-male.blp','GNOMEUNDEAD-female.blp'},
 HIGHMOUNTAINHD={'HIGHMOUNTAINHD-male.blp','HIGHMOUNTAINHD-female.blp'},
 ICETROLL={'ICETROLL-male.blp','ICETROLL-female.blp'},
 JINYU={'JINYU-male.blp','JINYU-female.blp'},
 MAGHAR={'MAGHAR-male.blp','MAGHAR-female.blp'},
 MECHAGNOME={'MECHAGNOME-male.blp','MECHAGNOME-female.blp'},
 NAGA={'NAGA-male.blp','NAGA-female.blp'},
 NORTHRENDSKELETON={'NORTHRENDSKELETON-male.blp','NORTHRENDSKELETON-female.blp'},
 PANDAREN={'PANDAREN-male.blp','PANDAREN-female.blp'},
 PANDARENALLIANCE={'PANDARENALLIANCE-male.blp','PANDARENALLIANCE-female.blp'},
 REBORNDARKFALLEN={'REBORNDARKFALLEN-male.blp','REBORNDARKFALLEN-female.blp'},
 REBORNKULTIRAN={'REBORNKULTIRAN-male.blp','REBORNKULTIRAN-female.blp'},
 REBORNOGRE={'REBORNOGRE-male.blp','REBORNOGRE-female.blp'},
 REBORNSETHRAK={'REBORNSETHRAK-male.blp','REBORNSETHRAK-female.blp'},
 REFORGEDFURBOLG={'REFORGEDFURBOLG-male.blp','REFORGEDFURBOLG-female.blp'},
 SEVENDARKFALLEN={'SEVENDARKFALLEN-male.blp','SEVENDARKFALLEN-female.blp'},
 SEVENHARANIR={'SEVENHARANIR-male.blp','SEVENHARANIR-female.blp'},
 SEVENKYRIAN={'SEVENKYRIAN-male.blp','SEVENKYRIAN-female.blp'},
 SEVENOGRE={'SEVENOGRE-male.blp','SEVENOGRE-female.blp'},
 SEVENSKYBORNE={'SEVENSKYBORNE-male.blp','SEVENSKYBORNE-female.blp'},
 SEVENVRYKUL={'SEVENVRYKUL-male.blp','SEVENVRYKUL-female.blp'},
 SKELETON={'SKELETON-male.blp','SKELETON-female.blp'},
 SYLVARIALLIANCE={'SYLVARIALLIANCE-male.blp','SYLVARIALLIANCE-female.blp'},
 TAUNKA={'TAUNKA-male.blp','TAUNKA-female.blp'},
 MURLOCHORDE={'MURLOCHORDE-male.blp','MURLOCHORDE-female.blp'},
 TITANALLIANCE={'TITANALLIANCE-male.blp','TITANALLIANCE-female.blp'},
 TUSKARR={'TUSKARR-male.blp','TUSKARR-female.blp'},
 VENTHYRHORDE={'VENTHYRHORDE-male.blp','VENTHYRHORDE-female.blp'},
 VULPERA={'VULPERA-male.blp','VULPERA-female.blp'},
}
local function portrait(e)
 local file=e.file
 if file=='NAGA_' then
  if e.id==25 or (not e.id and e.nativeName=='娜迦') then
   file='NAGA'
  elseif e.id==13 or (not e.id and e.nativeName=='狐人') then
   file='VULPERA'
  end
 end
 local icons=raceGenderPortraits[file]
 if icons then
  local female=e.only==1 or (e.only==nil and GetSelectedSex()==SEX_FEMALE)
  local root=([[Reborn/Preview/RaceGender/]]):gsub('/',string.char(92))
  return root..icons[female and 2 or 1],{0,1,0,1}
 end
 if e.file=='MOGUALLIANCE' then return ([[Reborn/Preview/RACE14/Mogu/icon-round.blp]]):gsub('/',string.char(92)),{0,1,0,1} end
 if e.file=='TITANALLIANCE' then return ([[Reborn/Preview/RACE14/Titan/v199-round.blp]]):gsub('/',string.char(92)),{0,1,0,1} end
 if e.file=='TUSKARR' then return 'Reborn\\Preview\\NEUTRAL\\Tuskarr\\icon-round.blp',{0,1,0,1} end
 if e.seven and e.seven.portrait then
  return 'Reborn\\Seven1A\\Icons\\'..e.seven.portrait..(GetSelectedSex()==SEX_FEMALE and 'Female' or 'Male')..'.blp',{0,1,0,1}
 end
 if e.seven and e.seven.id==109 then return 'Reborn\\Preview\\NEUTRAL\\Ethereal\\icon-round.blp',{0,1,0,1} end

 local a=e.preview and e.preview.e

 if a and a.ic then

  local kind,name=a.ic:match('^(%a):(.+)$')

  local root=({R='UIR1B',S='RACE14',N='NEUTRAL'})[kind]

  if root then return 'Reborn\\Preview\\'..root..'\\'..name..'\\icon-round.blp',{0,1,0,1} end

 end

 local gender=GetSelectedSex()==SEX_FEMALE and 'FEMALE' or 'MALE'

 local dedicated={DARKIRONDWARF='DarkIronDwarf',PANDAREN='Pandaren',NIGHTBORNE='Nightborne',ZANDALARITROLL='Zandalari'}

 if dedicated[e.file] then return 'Interface\\Icons\\Reborn_'..dedicated[e.file]..(gender=='FEMALE' and 'Female' or 'Male')..'_Round',{0,1,0,1} end

 if e.file=='DRACTHYR' then return 'Interface\\Icons\\INV_DracthyrHead'..(gender=='FEMALE' and '01' or '02')..'_Round',{0,1,0,1} end

 -- WOW64CREATOR1G: our 13=Vulpera and 25=Naga share NAGA_.

 -- Non-selected rows have no native id yet; use their unmodified native name.

 -- Never use the native list index as a race id or rewrite either identity.

 if e.file=='NAGA_' and (e.id==25 or (not e.id and e.nativeName=='娜迦')) and CharacterCreate_GetNagaPortraitTexCoords then return 'Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races2',{CharacterCreate_GetNagaPortraitTexCoords()} end

 local uv=RACE_ICON_TCOORDS and RACE_ICON_TCOORDS[e.file..'_'..gender]

 if uv then return 'Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Races',{uv[1],uv[2],uv[3],uv[4]} end

 if e.coords and (#e.coords==4 or #e.coords==8) then return e.icon,e.coords end

 return 'Interface\\Icons\\INV_Misc_QuestionMark',{0,1,0,1}

end

local function featureIcon(e)

 local icons={['肤色']='INV_Misc_ArmorKit_17',['脸型']='Spell_Holy_MindVision',['发型']='INV_Misc_Comb_01',['发色']='Spell_Arcane_Arcane01',['外观细节']='INV_Misc_Gem_Pearl_04',['面部特征']='Spell_Holy_MindVision',['头部']='INV_Helmet_03',['手臂']='INV_Gauntlets_04',['胸部']='INV_Chest_Cloth_04',['腿部']='INV_Pants_02',['眼睛颜色']='Spell_Holy_MindVision',['角饰']='INV_Misc_Horn_01',['光效颜色']='Spell_Arcane_Arcane01'}

 return 'Interface\\Icons\\'..(icons[e.name] or 'INV_Misc_Gem_Pearl_04')

end

local function tile(i,label,action,enabled,active,icon,uv)

 local b=C.tiles[i]

 if not b then

  b=CreateFrame('Button',nil,C.left);b:SetSize(94,84);b:EnableMouse(true)

  b:SetPoint('TOPLEFT',C.left,'TOPLEFT',20+((i-1)%3)*96,-144-math.floor((i-1)/3)*86)

  b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetSize(60,60);b.icon:SetPoint('TOP',0,0)

  b.baseRing=b:CreateTexture(nil,'OVERLAY');b.baseRing:SetTexture('Interface\\Glues\\CharacterCreate\\UI-CharacterCreatePatchwerk_nuevo');b.baseRing:SetTexCoord(0.79296875,0.953125,0.00097656,0.08105469);b.baseRing:SetSize(74,74);b.baseRing:SetPoint('CENTER',b.icon,'CENTER',1,-1);b.baseRing:SetVertexColor(0.55,0.55,0.55,0.85)

  b.ring=b:CreateTexture(nil,'OVERLAY');b.ring:SetTexture('Interface\\Glues\\CharacterCreate\\UI-CharacterCreatePatchwerk_nuevo');b.ring:SetTexCoord(0.79296875,0.953125,0.00097656,0.08105469);b.ring:SetSize(74,74);b.ring:SetPoint('CENTER',b.icon,'CENTER',1,-1);b.ring:SetBlendMode('ADD')

  b.label=text(b,13,TEXT);b.label:SetSize(94,28);b.label:SetPoint('TOP',b.icon,'BOTTOM',0,-5);b.label:SetJustifyH('CENTER')

  b:SetScript('OnClick',function(self) if self.action then self.action() end end)

  b:SetScript('OnEnter',function(self) self.ring:SetAlpha(1) end)

  b:SetScript('OnLeave',function(self) self.ring:SetAlpha(self.active and 1 or 0) end)

  C.tiles[i]=b

 end

 b.action,b.active=action,active;b.label:SetText(label);b.icon:SetTexture(icon or 'Interface\\Icons\\INV_Misc_QuestionMark');b.icon:SetTexCoord(unpack(uv or {0,1,0,1}));b.ring:SetAlpha(active and 1 or 0)

 b.label:SetTextColor(unpack(active and GOLD or enabled and TEXT or MUTED));b.icon:SetAlpha(enabled and 1 or 0.35)

 if enabled then b:Enable() else b:Disable() end;b:Show()

end

local function resize()

 local root=C.root;if not root then return end

 local width=GlueParent:GetWidth();local height=GlueParent:GetHeight()

 if C.width==width and C.height==height then return end

 C.width,C.height=width,height

 local scale=math.min(1,width/1280,height/800);root:SetScale(scale)

 root:ClearAllPoints();root:SetPoint('CENTER',GlueParent,'CENTER');root:SetSize(width/scale,height/scale)

 C.left:SetWidth(330);C.right:SetWidth(330)

end

-- WOW64TWOFORMS1G: own controls belong to the live rewritten creator, not its hidden legacy sibling.

function C.UpdateForms()

 if not C.root then return end

 local ok,count=pcall(CycleCharCustomization,'EA_FORM_COUNT')

 local visible=C.active and ok and count==2

 if not visible then

  if C.formButtons then for _,b in ipairs(C.formButtons) do b:Hide() end end

  return

 end

 if not C.formButtons then

  C.formButtons={}

  for i=1,2 do

   local index=i-1

   local b=button(C.root,'',110,30,function()

    if locked() then return end

    local yes=pcall(CycleCharCustomization,'EA_FORM_SET',index)

    if yes then C.page=1;changed();C.Render() end

   end)

   b:SetPoint('BOTTOM',C.root,'BOTTOM',(i-2)*116,252)

   C.formButtons[i]=b

  end

  local b=button(C.root,'双预览',110,30,function()

   if locked() then return end

   local yes,value=pcall(CycleCharCustomization,'EA_FORM_DUAL',2)

   if yes then pcall(CycleCharCustomization,'EA_FORM_DUAL',value==1 and 0 or 1);C.UpdateForms() end

  end)

  b:SetPoint('BOTTOM',C.root,'BOTTOM',116,252);C.formButtons[3]=b

 end

 local labels={Wolf='狼人',Human='人类',Dragon='龙形态',Visage='人形态',Darkweaver='织暗者',Dreadnaught='巨像'}

 local _,current=pcall(CycleCharCustomization,'EA_FORM_GET')

 for i=1,2 do

  local _,name=pcall(CycleCharCustomization,'EA_FORM_NAME',i-1)

  C.formButtons[i].label:SetText((current==i-1 and '● ' or '')..(labels[name] or '形态'))

 end

 local _,dual=pcall(CycleCharCustomization,'EA_FORM_DUAL',2)

 C.formButtons[3].label:SetText(dual==1 and '双预览：开' or '双预览：关')

 for _,b in ipairs(C.formButtons) do

  b:SetFrameLevel((C.viewport and C.viewport:GetFrameLevel() or C.root:GetFrameLevel())+5)

  b:RegisterForClicks('LeftButtonUp');b:EnableMouse(true);b:Show()

 end

end



function C.Render()

 if not C.active or not C.root then return end

 sync();hideLegacy();C.UpdateForms()

 for _,b in ipairs(C.rows) do b:Hide();if b.minus then b.minus:Hide() end end

 for _,b in ipairs(C.tiles) do b:Hide() end

 for _,b in ipairs(C.tabs) do b:Hide() end

 C.title:SetText(({'选择你的种族','选择你的职业','定制角色外观','阵营与出生地'})[C.step])

 C.male.label:SetText('男性');C.female.label:SetText('女性')

 C.male.label:SetFont('Fonts\\ARKai_C.ttf',17,'');C.female.label:SetFont('Fonts\\ARKai_C.ttf',17,'')

 for i,b in ipairs(C.steps) do b.label:SetText(names[i]);b.number:SetTextColor(unpack(i==C.step and GOLD or MUTED));b.label:SetTextColor(unpack(i==C.step and GOLD or MUTED));setShown(b.line,i==C.step) end

 local r=C.race;local cl=C.classes and C.classes[C.classIndex]

 C.summary:SetText((r and r.name or '')..'  ·  '..(cl and cl.name or ''))

 local faction=r and r.faction or ''

 C.sub:SetText(C.step==1 and '选择你的种族，开启新的冒险。' or C.step==2 and '选择属于你的战斗方式。' or C.step==3 and '每一个细节，都由你决定。' or '你的旅程，从这里启程。')

 C.photo:Hide();C.pagePrev:Hide();C.pageNext:Hide();C.pageLabel:SetText('')

 C.detailTitle:ClearAllPoints();C.detailTitle:SetPoint('TOPLEFT',22,C.step==4 and -232 or -82)

 C.detailBody:ClearAllPoints();C.detailBody:SetPoint('TOPLEFT',22,C.step==4 and -274 or -126)

 setShown(C.randomAppearance,C.step==3)

 if C.step==1 then

  for _,b in ipairs(C.tabs) do b:Show();b.tint(b,false) end

  local filtered={}

  for _,e in ipairs(C.races) do

   if C.group=='NEUTRAL' and e.neutral or not e.neutral and e.faction==C.group then table.insert(filtered,e) end

  end


  local pages=math.max(1,math.ceil(#filtered/15));C.page=math.max(1,math.min(C.page,pages))

  for i=1,15 do

   local e=filtered[(C.page-1)*15+i]

   if e and not e.index then

    tile(i,e.name,nil,false,false,e.icon)

   elseif e then

    local idx=e.index

    local icon,uv=portrait(e)

    tile(i,e.name,function() C.SelectRace(idx) end,e.enabled,r and r.index==idx,icon,uv)

   end

  end

  C.pageLabel:SetText(C.page..' / '..pages..' 页');C.pagePrev:Show();C.pageNext:Show()

  detail(r and r.name or '选择一个种族',r and selectedLore('RACE_INFO_',r.file) or '')

  C.notes:SetText(r and r.neutral and '中立种族可在最后一步选择联盟或部落与出生地。' or ('当前阵营：'..(faction=='Horde' and '部落' or '联盟')))

 elseif C.step==2 then

  local all={};for i,e in ipairs(C.classes or {}) do if tokens[e.token] then table.insert(all,e) end end

  local pages=math.max(1,math.ceil(#all/15));C.page=math.max(1,math.min(C.page,pages))

  for i=1,15 do local e=all[(C.page-1)*15+i];if e then local idx=e.index

   local tc=CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[e.token]

   local icon=tc and 'Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes' or nil

   local legacy=({MONK=CharCreateMonkButton,WITCHDOCTOR=CharCreateWitchDoctorPreviewButton,WITCHHUNTER=CharCreateWitchHunterPreviewButton})[e.token] or _G['CharCreateClassButton'..idx]

   local tex=legacy and legacy.GetNormalTexture and legacy:GetNormalTexture()

   if tex and tex.GetTexture then icon=tex:GetTexture();if not tc and tex.GetTexCoord then local uv={tex:GetTexCoord()};if #uv==4 or #uv==8 then tc=uv end end end

   tile(i,e.name..(allow(idx) and '' or '\n未开放'),function() C.SelectClass(idx) end,allow(idx),C.classIndex==idx,icon,tc)

  end end

  C.pageLabel:SetText(C.page..' / '..pages..' 页');C.pagePrev:Show();C.pageNext:Show()

  detail(cl and cl.name or '选择职业',cl and selectedLore('CLASS_',cl.token) or '')

  C.notes:SetText('选择已开放的职业，踏上你的冒险之旅。')

 elseif C.step==3 then

  local f=features();local pages=math.max(1,math.ceil(#f/6));C.page=math.max(1,math.min(C.page,pages))

  for i=1,6 do local e=f[(C.page-1)*6+i];if e then

   local b=row(i);put(i,e.name..(e.count and ('  '..(e.value+1)..'/'..e.count) or ''),function() C.Cycle(e.field,1,e.adapter) end,true,false,featureIcon(e),{0.06,0.94,0.06,0.94})

   -- Separate left arrow, no perpetual re-selection of race/class.

   if not b.minus then b.minus=button(b,'‹',30,32,function() if b.feature then C.Cycle(b.feature.field,-1,b.feature.adapter) end end);b.minus:SetPoint('RIGHT',b,'RIGHT',-42,0) end

   b.feature=e;b.minus:Show()

  end end

  C.pageLabel:SetText(C.page..' / '..pages..' 页');C.pagePrev:Show();C.pageNext:Show()

  detail('你的外观','使用下方男女按钮与左侧外观选项调整角色。\n\n左右拖动旋转模型，滚轮调整镜头。名字只使用一个输入框，沿用本项目命名与角色槽报价流程。')

  C.notes:SetText('拖动角色旋转视角，滚轮拉近或远离。')

 else

  local selectedClass=C.classes[C.classIndex]
  if C.race and (C.race.id==121 or C.race.id==123) and selectedClass and selectedClass.token=='DEATHKNIGHT' then
   C.startZone=nil;pcall(SetCreateStartZone,0)
   C.pageLabel:SetText('死亡骑士出生地');C.pagePrev:Hide();C.pageNext:Hide()
   detail('黑锋要塞','死亡骑士从黑锋要塞开始，保留原有等级和英雄职业创建条件。')
  elseif C.race and C.race.neutral and neutralOriginIDs[C.race.file] then
   local id=neutralOriginIDs[C.race.file]
   if not C.origin or C.origin.race~=id then C.origin={race=id} end
   local origin=C.origin
   if origin.zone~=nil and (origin.zone<129 or origin.zone>140) then origin.zone=nil end
   for i,entry in ipairs({{0,'联盟','Interface\\Icons\\INV_BannerPVP_02'},{1,'部落','Interface\\Icons\\INV_BannerPVP_01'}}) do
    local team,label,image=entry[1],entry[2],entry[3]
    put(i,label,function() if origin.team~=team then origin.team=team;origin.zone=nil;C.page=1;pcall(CycleCharCustomization,'RB_ORIGIN_CLEAR') end;C.Render() end,true,origin.team==team,image)
   end
   local key=origin.team==1 and 'Horde' or 'Alliance'
   local zones=RebornCreatorZones[key] or {};local pages=math.max(1,math.ceil(#zones/6))
   C.page=math.max(1,math.min(C.page,pages))
   if origin.team~=nil then
    for i=1,6 do
     local slot=(C.page-1)*6+i;local z=zones[slot]
     if z then
      local choice=128+slot
      put(i+2,z.name,function() origin.zone=choice;C.Render() end,true,origin.zone==choice,z.image)
      if origin.zone==choice and z.image then C.photo:SetTexture(z.image);C.photo:Show() end
     end
    end
    C.pageLabel:SetText(C.page..' / '..pages..' 页');C.pagePrev:Show();C.pageNext:Show()
   else C.pageLabel:SetText('请选择阵营');C.pagePrev:Hide();C.pageNext:Hide() end
   local selected
   for i,z in ipairs(zones) do if 128+i==origin.zone then selected=z.name end end
   detail('选择你的阵营与出生地',origin.team==nil and '先选择联盟或部落，再从该阵营完整出生地列表中选择。' or ((origin.team==0 and '联盟' or '部落')..' · '..(selected or '请选择出生地')..'\n\n角色保持 '..C.race.name..' 身份，出生点与炉石同时保存。死亡骑士也可以选择这些出生地，等级与职业初始化沿用服务器规则。'))
   local ownBodyOnly=({[76]=true,[89]=true,[90]=true,[93]=true,[106]=true,[112]=true,[114]=true})[id]
   C.notes:SetText(ownBodyOnly and '此体型保留原生身体外观，普通胸甲、裤子与手套的外观适配尚未完成；装备属性按正常规则生效。' or '完成创建前请确认。角色创建后，重登仍保留本次阵营选择。')
  else
  local key=faction=='Horde' and 'Horde' or 'Alliance';local zones=RebornCreatorZones[key] or {}
  local identity=tostring(C.race.index)..':'..key
  if C.startIdentity~=identity then C.startIdentity=identity;C.startZone=nil;pcall(SetCreateStartZone,0) end
  local pages=math.max(1,math.ceil(#zones/8));C.page=math.max(1,math.min(C.page,pages))
  for i=1,8 do
   local slot=(C.page-1)*8+i;local z=zones[slot]
   if z then
    put(i,z.name,function() C.startZone=128+slot;C.Render() end,true,C.startZone==128+slot,z.image)
    if C.startZone==128+slot and z.image then C.photo:SetTexture(z.image);C.photo:Show() end
   end
  end
  C.pageLabel:SetText(C.page..' / '..pages..' 页');C.pagePrev:Show();C.pageNext:Show()
  local selected
  for i,z in ipairs(zones) do if C.startZone==128+i then selected=z.name end end
  detail('选择出生地',selected and ('已选择：'..selected..'。角色保留当前种族与阵营，出生点、炉石与开场镜头使用此地。') or '从列表选择出生地；未选择时使用本种族与职业的默认出生流程。')
  C.notes:SetText('创建后保留本次出生选择。已创建角色的位置不会改变。')

  end

 end

 for _,b in ipairs(C.rows) do if b.minus and C.step~=3 then b.minus:Hide() end end

 C.next.label:SetText(C.step==4 and '完成创建' or '下一步')

 C.modeLabel:SetText('当前：'..({default='T7装备',t14='T14装备',none='NO装备'})[C.mode]..' · 仅预览')

 local lock=r and r.only

 sexButton(C.male,lock==nil or lock==0,GetSelectedSex()==SEX_MALE)
 sexButton(C.female,lock==nil or lock==1,GetSelectedSex()==SEX_FEMALE)

end

local function create()


 if not C.active or not C.race or not allow(C.classIndex) then say('请先选择可创建的种族和职业。');return end

 if CharacterCreateNameEdit:GetText()=='' then say('请先输入名字，或点击骰子生成名字。');CharacterCreateNameEdit:SetFocus();return end

 if RebornCharacterSlotQuoteFrame and RebornCharacterSlotQuoteFrame:IsShown() then return end

 local raceID,classID,sexID,index,loaded,componentClass=state()

 local expected=C.classes[C.classIndex] and tokens[C.classes[C.classIndex].token]

 if index~=C.race.index or not truth(loaded) or classID~=expected or componentClass~=expected or C.race.id and raceID~=C.race.id then

  say('角色模型与当前选择尚未同步，请等待加载后重新选择职业。');return

 end

 if C.race.only~=nil and sexID~=C.race.only then say('该种族仅支持当前亮起的性别，请重新选择种族后再创建。');return end

 if C.race.neutral and neutralOriginIDs[C.race.file] then
  local v=C.origin
  if not v or v.race~=raceID or v.team==nil or v.zone==nil then say('请在最后一步选择阵营与出生地。');return end
  local ok,accepted=pcall(CycleCharCustomization,'RB_ORIGIN_SET',v.team,v.zone)
  if not ok then say('客户端创建指令执行失败，请使用本批配套客户端。');return end
  if accepted==-1 then say('服务器尚未确认完整出生地，请确认本批服务端及两库SQL已更新，再重新登录。');return end
  if accepted~=1 then say('角色模型与选择尚未同步，请重新选择种族或职业后重试。');return end
 else
  pcall(CycleCharCustomization,'RB_ORIGIN_CLEAR')
  local startZone=(raceID==121 and expected==6) and 0 or (C.startZone or 0)
  local ok,accepted=pcall(SetCreateStartZone,startZone)
  if not ok or not accepted then say('出生地保存尚未就绪，请更新配套服务端及数据后重新登录。');return end
 end
 if C.race.neutral then pcall(SetCreateStartZone,0) end
 sync();CharacterCreateFrame.state='CUSTOMIZATION';oldFinish()

 if RebornCharacterSlotQuoteFrame then RebornCharacterSlotQuoteFrame:SetParent(CharacterCreate);RebornCharacterSlotQuoteFrame:SetFrameStrata('DIALOG') end

end

function C.Build()

 C.namePlacement={parent=CharacterCreateNameEdit:GetParent(),width=CharacterCreateNameEdit:GetWidth(),height=CharacterCreateNameEdit:GetHeight(),font={CharacterCreateNameEdit:GetFont()},points={}}

 for i=1,CharacterCreateNameEdit:GetNumPoints() do table.insert(C.namePlacement.points,{CharacterCreateNameEdit:GetPoint(i)}) end

 local root=CreateFrame('Frame','RebornCreatorFrame',CharacterCreate);C.root=root

 root:SetFrameStrata('HIGH');root:SetFrameLevel(90);root:EnableMouse(false)

 local viewport=CreateFrame('Frame',nil,root);viewport:SetPoint('TOPLEFT',root,'TOPLEFT',330,-65);viewport:SetPoint('BOTTOMRIGHT',root,'BOTTOMRIGHT',-330,294);viewport:EnableMouse(true);viewport:EnableMouseWheel(true)

 viewport:SetScript('OnMouseDown',function(_,b) if b=='LeftButton' then CHARACTER_CREATE_ROTATION_START_X=GetCursorPosition() end end)

 viewport:SetScript('OnMouseUp',function() CHARACTER_CREATE_ROTATION_START_X=nil end)

 C.viewport=viewport

 viewport:SetScript('OnMouseWheel',function(_,delta)

  if locked() or type(delta)~='number' or delta~=delta then return end

  CycleCharCustomization('EA_ZOOM',math.max(-1,math.min(1,delta)))

 end)

 local left=CreateFrame('Frame',nil,root);C.left=left;left:SetPoint('TOPLEFT',root,'TOPLEFT',0,-65);left:SetPoint('BOTTOMLEFT',root,'BOTTOMLEFT',0,100);left:EnableMouse(true)

 local right=CreateFrame('Frame',nil,root);C.right=right;right:SetPoint('TOPRIGHT',root,'TOPRIGHT',0,-65);right:SetPoint('BOTTOMRIGHT',root,'BOTTOMRIGHT',0,100);right:EnableMouse(true)

 for _,p in ipairs({left,right}) do local bg=ES.Solid(p,'BACKGROUND',ES.INK,1);bg:SetAllPoints(p);if p==left then bg:SetGradientAlpha('HORIZONTAL',0.025,0.03,0.04,0.86,0.025,0.03,0.04,0.18) else bg:SetGradientAlpha('HORIZONTAL',0.025,0.03,0.04,0.18,0.025,0.03,0.04,0.86) end end

 local top=CreateFrame('Frame',nil,root);top:SetHeight(65);top:SetPoint('TOPLEFT');top:SetPoint('TOPRIGHT');local tbg=ES.Solid(top,'BACKGROUND',ES.INK,1);tbg:SetAllPoints(top)

 local emblem=top:CreateTexture(nil,'ARTWORK');emblem:SetTexture('Interface\\Glues\\Common\\realm_logo.tga');emblem:SetSize(104,52);emblem:SetPoint('LEFT',16,0)

 local logo=text(top,22,GOLD);logo:SetSize(220,38);logo:SetPoint('LEFT',134,0);logo:SetText('RebornWOW')

 local navigation=CreateFrame('Frame',nil,top);navigation:SetSize(720,65);navigation:SetPoint('CENTER',top,'CENTER',100,0);C.navigation=navigation

 C.steps={};for i,n in ipairs(names) do local j=i;local b=button(navigation,i..' '..n,176,35,function() C.step=j;C.page=1;say('');C.Render() end);b:SetPoint('CENTER',navigation,'CENTER',(i-2.5)*180,0);

 b.label:ClearAllPoints();b.label:SetPoint('CENTER',b,'CENTER',9,0);b.label:SetSize(154,31);b.label:SetText(n)

 b.number=b:CreateFontString(nil,'OVERLAY');b.number:SetFont('Fonts\\FRIZQT__.TTF',15,'');b.number:SetPoint('RIGHT',b.label,'LEFT',-3,0);b.number:SetSize(13,31);b.number:SetJustifyH('CENTER');b.number:SetText(tostring(i));b.number:SetTextColor(unpack(MUTED))

 b.line=ES.Solid(b,'ARTWORK',GOLD,0.9);b.line:SetSize(64,2);b.line:SetPoint('BOTTOM',0,-2);C.steps[i]=b end

 C.title=text(left,25,GOLD);C.title:SetPoint('TOPLEFT',22,-22)

 C.sub=text(left,12,MUTED);C.sub:SetPoint('TOPLEFT',22,-62);C.sub:SetWidth(286);C.sub:SetHeight(38)

 C.tabs={};for i,e in ipairs({{'Alliance','联盟'},{'Horde','部落'},{'NEUTRAL','中立'}}) do local v=e[1];local b=button(left,e[2],90,28,function() C.group=v;C.page=1;C.Render() end);b:SetPoint('TOPLEFT',22+(i-1)*98,-106);b.key=v

 b.label:ClearAllPoints();b.label:SetPoint('CENTER',8,0);b.label:SetSize(64,25)

 b.icon=b:CreateTexture(nil,'ARTWORK');b.icon:SetSize(22,22);b.icon:SetPoint('LEFT',1,0)

 b.icon:SetTexture((v=='NEUTRAL' and 'Reborn\\Preview\\NEUTRAL1\\emblem.blp') or ('Interface\\Glues\\CharacterCreate\\'..(v=='Alliance' and 'AllianceLogo' or 'HordeLogo')))

 b.line=ES.Solid(b,'ARTWORK',GOLD,1);b.line:SetHeight(2);b.line:SetPoint('BOTTOMLEFT',4,-1);b.line:SetPoint('BOTTOMRIGHT',-4,-1)

 local function tint(self,hover)

  local active=C.group==self.key

  self.label:SetTextColor(unpack(active and {1,0.85,0.4} or hover and TEXT or MUTED))

  self.icon:SetAlpha(active and 1 or hover and 0.9 or 0.55)

  setShown(self.line,active)

 end

 b.tint=tint;b:SetScript('OnEnter',function(self) tint(self,true) end);b:SetScript('OnLeave',function(self) tint(self,false) end)

 C.tabs[i]=b end

 C.pagePrev=button(left,'‹',38,28,function() C.page=C.page-1;C.Render() end);C.pagePrev:SetPoint('BOTTOMLEFT',22,12)

 C.pageNext=button(left,'›',38,28,function() C.page=C.page+1;C.Render() end);C.pageNext:SetPoint('BOTTOMRIGHT',-22,12)

 C.pageLabel=text(left,13,MUTED);C.pageLabel:SetPoint('BOTTOM',0,18)

 local rt=text(right,23,GOLD);rt:SetPoint('TOPLEFT',22,-22);rt:SetText('角色详情')

 C.photo=right:CreateTexture(nil,'ARTWORK');C.photo:SetPoint('TOPLEFT',22,-66);C.photo:SetSize(286,143)

 C.detailTitle=text(right,22,GOLD);C.detailTitle:SetPoint('TOPLEFT',22,-232);C.detailTitle:SetWidth(286)

 C.detailBody=text(right,15,TEXT);C.detailBody:SetPoint('TOPLEFT',22,-274);C.detailBody:SetWidth(286);C.detailBody:SetHeight(235);C.detailBody:SetJustifyV('TOP')

 C.notes=text(right,12,MUTED);C.notes:SetPoint('BOTTOMLEFT',22,20);C.notes:SetWidth(286);C.notes:SetHeight(105);C.notes:SetJustifyV('BOTTOM')

 C.summary=text(root,18,GOLD);C.summary:SetPoint('BOTTOM',root,'BOTTOM',0,218)

 C.male=button(root,'男性',94,30,function() C.SelectSex(SEX_MALE) end);C.male:SetPoint('BOTTOM',root,'BOTTOM',-52,178)

 C.female=button(root,'女性',94,30,function() C.SelectSex(SEX_FEMALE) end);C.female:SetPoint('BOTTOM',root,'BOTTOM',52,178)

 for i,e in ipairs({{'default','T7装备'},{'t14','T14装备'},{'none','NO装备'}}) do local mode=e[1];local b=button(root,e[2],88,29,function() C.mode=mode;changed();C.Render() end);b:SetPoint('BOTTOM',root,'BOTTOM',(i-2)*94,141) end

 C.modeLabel=text(root,12,MUTED);C.modeLabel:SetPoint('BOTTOM',root,'BOTTOM',0,121)

 C.randomAppearance=button(left,'随机外观',130,28,C.RandomAppearance);C.randomAppearance:SetPoint('BOTTOM',0,50)

 local bottom=CreateFrame('Frame',nil,root);bottom:SetHeight(100);bottom:SetPoint('BOTTOMLEFT');bottom:SetPoint('BOTTOMRIGHT');local bg=ES.Solid(bottom,'BACKGROUND',ES.INK,0.94);bg:SetAllPoints(bottom)

 C.bottom=bottom

 local back=button(bottom,'返回',130,34,function() if C.step>1 then C.step=C.step-1;C.page=1;C.Render() else CharacterCreateFrame.state='CLASSRACE';oldBack() end end);back:SetPoint('LEFT',22,0)

 C.next=button(bottom,'下一步',150,34,function() if C.step<4 then C.step=C.step+1;C.page=1;C.Render() else create() end end);C.next:SetPoint('RIGHT',-22,0)

 C.status=text(bottom,13,GOLD);C.status:SetPoint('TOP',bottom,'TOP',0,-10);C.status:SetSize(600,22);C.status:SetJustifyH('CENTER')

 CharacterCreateNameEdit:SetParent(bottom);CharacterCreateNameEdit:ClearAllPoints();CharacterCreateNameEdit:SetPoint('CENTER',bottom,'CENTER',0,-20);CharacterCreateNameEdit:SetSize(230,28);CharacterCreateNameEdit:SetFont('Fonts\\ARKai_T.ttf',17,'');CharacterCreateNameEdit:Show()

 C.nameLabel=text(bottom,14,GOLD);C.nameLabel:SetText('角色名字');C.nameLabel:SetSize(80,24);C.nameLabel:SetPoint('RIGHT',CharacterCreateNameEdit,'LEFT',-10,0)

 local dice=button(bottom,'骰子',62,28,C.RandomName);dice:SetPoint('LEFT',CharacterCreateNameEdit,'RIGHT',8,0)

 root:SetScript('OnSizeChanged',resize);resize()

 root:SetScript('OnUpdate',function(self,elapsed)

  if not C.active then return end

  CharacterCreateFrame_OnUpdate(CharacterCreateFrame,elapsed)

  local retry=C.retry

  if retry then

   retry.at=retry.at+elapsed;retry.total=retry.total+elapsed

   if retry.revision~=C.revision then C.retry=nil

   elseif retry.at>=0.15 then

     retry.at=0 -- WOW64TWOFORMS1J: poll at intervals, not every frame after the first interval.

    local _,cls,_,index,loaded,componentClass=state()

    if index==GetSelectedRace() and truth(loaded) and cls==componentClass then

     C.retry=nil;preview()

    elseif retry.total>=2 then C.retry=nil;say('模型尚在加载，可稍后点击装备预览。') end

   end

  end

  C.elapsed=C.elapsed+elapsed

  if C.elapsed>=0.25 then C.elapsed=0;hideLegacy();C.UpdateForms() end


  if locked() then C.next:Disable();CharacterCreateNameEdit:EnableKeyboard(false);CharacterCreateNameEdit:EnableMouse(false);CharacterCreateNameEdit:ClearFocus()

  else C.next:Enable();CharacterCreateNameEdit:EnableKeyboard(true);CharacterCreateNameEdit:EnableMouse(true) end

 end)

end

function CharacterCreate_EnsureCreateSelection(...)

 if not C.active then return oldEnsure(...) end

 -- The selected native component is authoritative; never replay stale legacy stored class/race indices.

 if C.race and GetSelectedRace()~=C.race.index then return end

 sync()

end

function CharacterCreate_Finish(...)


 if C.active then if C.step<4 then C.step=C.step+1;C.page=1;C.Render() else create() end;return end

 return oldFinish(...)

end

function CharacterCreate_OnShow(...)

 oldShow(...)

 if PAID_SERVICE_TYPE or type(RebornCreationGetState)~='function' then return end

 if not C.root then C.Build() end

 CharacterCreateNameEdit:SetParent(C.bottom);CharacterCreateNameEdit:ClearAllPoints();CharacterCreateNameEdit:SetPoint('CENTER',C.bottom,'CENTER',0,-20);CharacterCreateNameEdit:SetSize(230,28);CharacterCreateNameEdit:SetFont('Fonts\\ARKai_T.ttf',17,'')

 C.nameRegions={}

 for _,region in ipairs({CharacterCreateNameEdit:GetRegions()}) do

  local kind=region:GetObjectType()

  if kind=='Texture' or kind=='FontString' and (region:GetText()==NAME or region:GetText()=='名字' or region:GetText()=='Name') then

   table.insert(C.nameRegions,{region,region:IsShown()});region:Hide()

  end

 end

 C.active=true;C.step=1;C.page=1;C.group='Alliance';C.mode='default';C.elapsed=0

 C.startZone=nil;pcall(SetCreateStartZone,0);C.origin=nil;pcall(CycleCharCustomization,'RB_ORIGIN_CLEAR')
 CharacterCreateFrame.state='CUSTOMIZATION';readRaces();readClasses();sync()

 C.group=C.race and (C.race.neutral and 'NEUTRAL' or C.race.faction) or 'Alliance'

 local visible=0

 for _,entry in ipairs(C.races) do

  if C.group=='NEUTRAL' and entry.neutral or not entry.neutral and entry.faction==C.group then

   visible=visible+1;if entry==C.race then C.page=math.floor((visible-1)/15)+1;break end

  end

 end

 changed();C.root:Show();CharacterCreateNameEdit:Show();C.Render()

 say('')

end

function CharacterCreate_OnHide(...)

 C.active=false;C.retry=nil

 for _,entry in ipairs(C.nameRegions or {}) do setShown(entry[1],entry[2]) end;C.nameRegions=nil

 if RebornCharacterSlotQuoteFrame and RebornCharacterSlotQuoteFrame:IsShown() then

  local cancel=RebornCharacterSlotQuoteFrame.cancel

  local fn=cancel and cancel:GetScript('OnClick');if fn then fn(cancel) else RebornCharacterSlotQuoteFrame:Hide() end

 end

 if C.root then

  C.root:Hide();local p=C.namePlacement

  CharacterCreateNameEdit:SetParent(p.parent);CharacterCreateNameEdit:ClearAllPoints()

  for _,point in ipairs(p.points) do CharacterCreateNameEdit:SetPoint(unpack(point)) end

  CharacterCreateNameEdit:SetSize(p.width,p.height);CharacterCreateNameEdit:SetFont(unpack(p.font));CharacterCreateNameEdit:EnableKeyboard(true);CharacterCreateNameEdit:EnableMouse(true);CharacterCreateNameEdit:Hide()

 end

 CharacterCreateFrame.state='CLASSRACE';CharacterCreateFrame:Show();CHARACTER_CREATE_ROTATION_START_X=nil;return oldHide(...)

end

function CharacterCreate_Back(...)

 if not C.active then return oldBack(...) end

 if C.step>1 then C.step=C.step-1;C.page=1;C.Render();return end

 CharacterCreateFrame.state='CLASSRACE';return oldBack(...)

end

function CharacterCreateFrame_OnUpdate(self,elapsed)

 if not C.active then return oldUpdate(self,elapsed) end

 if CHARACTER_CREATE_ROTATION_START_X then

  local x=GetCursorPosition();local diff=(x-CHARACTER_CREATE_ROTATION_START_X)*CHARACTER_ROTATION_CONSTANT

  CHARACTER_CREATE_ROTATION_START_X=x;SetCharacterCreateFacing(GetCharacterCreateFacing()+diff)

 end

end

end)()


;
-- WOW64BODY1A: creator-only editor; saves through the authorized creation transaction.
(function()
local C=RebornCreator
if not C then return end
local B={group='body',page=1,rows={}}
local captions={BreastSize='胸部丰满度',ButtSize='臀部丰满度',Height='身高',HeadSize='头部大小',NeckLength='颈部长度',ShoulderWidth='肩宽',ArmLength='手臂长度',ArmGirth='手臂粗细',ChestSize='胸廓大小',WaistWidth='腰部宽度',TorsoLength='躯干长度',HipWidth='胯部宽度',LegLength='腿部长度',LegGirth='腿部粗细',JawSize='下颌大小',JawLength='下颌长度',FaceWidth='脸部宽度',FaceLength='脸部长度',BrowHeight='眉部高度',BrowDepth='眉部深度',EyeSize='眼睛大小',EyeSpacing='眼间距',EyeHeight='眼睛高度',NoseSize='鼻子大小',NoseWidth='鼻翼宽度',NoseLength='鼻子长度',NoseHeight='鼻子高度',MouthWidth='嘴部宽度',LipFullness='嘴唇厚度',MouthHeight='嘴部高度',ChinLength='下巴长度',ChinDepth='下巴深度',CheekWidth='面颊宽度',CheekHeight='面颊高度',JawWidth='下颌宽度',EarSize='耳朵大小',EarHeight='耳朵高度'}
local function label(parent,size)
 local f=parent:CreateFontString(nil,'OVERLAY');f:SetFont('Fonts\\ARKai_T.ttf',size,'');f:SetTextColor(1,.82,.3);return f
end
local function blocked()
 return RebornCharacterSlotQuoteFrame and RebornCharacterSlotQuoteFrame:IsShown()
end
local function ready()
 return not blocked() and type(RebornBodyReady)=='function' and RebornBodyReady()
end
local function button(parent,caption,w,fn)
 local b=CreateFrame('Button',nil,parent);b:SetSize(w,26)
 local bg=b:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints();bg:SetTexture(0,0,0,.25)
 b.caption=label(b,14);b.caption:SetPoint('CENTER');b.caption:SetText(caption)
 b:SetScript('OnClick',function() if not blocked() then fn() end end);return b
end
-- BODY1B: read-only diagnostics; never bypass server authorization.
local function status()
 local api=type(RebornBodyReady)=='function'
 local edit,server=false,false
 if api then edit,server=RebornBodyReady() end
 local names=type(GetBodyShapeNames)=='function' and {GetBodyShapeNames(B.group)} or {}
 local support,pending=0,0
 local bits={}
 for _,name in ipairs(names) do
  local v=GetBodyShapeSupport(name)
  bits[#bits+1]=name..':'..tostring(v)
  if v==true then support=support+1 elseif v==nil then pending=pending+1 end
 end
 local key=table.concat({tostring(api),tostring(edit),tostring(server),tostring(blocked()),tostring(GetSelectedRace()),tostring(GetSelectedSex()),B.group,table.concat(bits,',')},'|')
 local note
 if not api then note='客户端缺少体型接口'
 elseif blocked() then note='请先完成当前角色槽位确认'
 elseif not server then note='尚未收到服务端体型能力确认（BSE1）'
 elseif not edit then note='服务端已确认；模型绑定或种族检查未就绪'
 elseif pending>0 and support==0 then note='正在等待模型外观数据'
 elseif support==0 then note='当前模型没有支持的本页调整项'
 else note='随角色创建保存；右键滑条恢复默认' end
 if key~=B.lastStatus then
  B.lastStatus=key
  if type(BodyShapeLog)=='function' then BodyShapeLog('WOW64BODY1B '..key..' note='..note) end
 end
 return key,note
end
local function options()
 local list={}
 if not ready() then return list end
 for _,name in ipairs({GetBodyShapeNames(B.group)}) do
  if captions[name] and GetBodyShapeSupport(name)==true and (not RebornBodyRange or RebornBodyRange(name)~=nil) then list[#list+1]=name end
 end
 return list
end
local function refresh()
 if not B.panel or not B.panel:IsShown() then return end
 local list=options();local visible=math.max(1,math.min(6,math.floor((B.panel:GetHeight()-112)/48)))
 local pages=math.max(1,math.ceil(#list/visible));B.page=math.max(1,math.min(B.page,pages))
 B.pageText:SetText(B.page..' / '..pages..' 页')
 local key,note=status();B.renderedStatus=key;B.note:SetText(note)
 for i,row in ipairs(B.rows) do
  local name=i<=visible and list[(B.page-1)*visible+i] or nil;row.name=name
  if name then
   local low,high=(name=='BreastSize' or name=='ButtSize') and 0 or -.35,.35
   if RebornBodyRange then low,high=RebornBodyRange(name) end
   row.busy=true;row.slider:SetMinMaxValues(low or 0,high or 0)
   local value=GetBodyShape(name) or 0;row.slider:SetValue(value);row.busy=false
   row.title:SetText(captions[name]);row.value:SetText(string.format('%+.0f%%',value*100));row:Show()
  else row:Hide() end
 end
end
local function build()
 if B.panel or not C.left then return end
 B.toggle=button(C.left,'体型 / 捏脸',140,function() B.open=not B.open;C.Render() end)
 B.toggle:SetPoint('BOTTOM',0,87);B.toggle:SetFrameLevel(C.left:GetFrameLevel()+24)
 local p=CreateFrame('Frame',nil,C.left);B.panel=p;p:SetPoint('TOPLEFT',12,-132);p:SetPoint('BOTTOMRIGHT',-12,124);p:SetFrameLevel(C.left:GetFrameLevel()+22)
 local bg=p:CreateTexture(nil,'BACKGROUND');bg:SetAllPoints();bg:SetTexture(.025,.025,.035,.94)
 local body=button(p,'体型',90,function() B.group='body';B.page=1;refresh() end);body:SetPoint('TOPLEFT',8,-7)
 local face=button(p,'捏脸',90,function() B.group='face';B.page=1;refresh() end);face:SetPoint('TOPRIGHT',-8,-7)
 for i=1,6 do
  local row=CreateFrame('Frame',nil,p);row:SetPoint('TOPLEFT',10,-40-(i-1)*48);row:SetPoint('RIGHT',p,'RIGHT',-10,0);row:SetHeight(46)
  row.title=label(row,13);row.title:SetPoint('TOPLEFT');row.value=label(row,12);row.value:SetPoint('TOPRIGHT')
  local s=CreateFrame('Slider',nil,row);row.slider=s;s:SetPoint('TOPLEFT',0,-21);s:SetPoint('TOPRIGHT',0,-21);s:SetHeight(15);s:SetOrientation('HORIZONTAL');s:SetValueStep(.01)
  local track=s:CreateTexture(nil,'BACKGROUND');track:SetHeight(2);track:SetPoint('LEFT');track:SetPoint('RIGHT');track:SetTexture(.6,.5,.3,.6)
  s:SetThumbTexture('Interface\\Buttons\\UI-SliderBar-Button-Horizontal');s:GetThumbTexture():SetSize(16,18)
  s:SetScript('OnValueChanged',function(self,v)
   if row.busy or not row.name or not ready() then return end
   local ok=RebornBodySet(row.name,v)
   row.busy=true;local actual=GetBodyShape(row.name) or 0;self:SetValue(actual);row.busy=false
   row.value:SetText(string.format('%+.0f%%',actual*100))
  end)
  s:SetScript('OnMouseUp',function(self,key) if key=='RightButton' and row.name and ready() then RebornBodySet(row.name,0);refresh() end end)
  B.rows[i]=row
 end
 local random=button(p,'随机当前页签',126,function()
  for _,name in ipairs(options()) do
   local low,high=(name=='BreastSize' or name=='ButtSize') and 0 or -.25,.25
   if RebornBodyRange then low,high=RebornBodyRange(name) end
   if low and high then RebornBodySet(name,math.random(math.ceil(low*100),math.floor(high*100))/100) end
  end;refresh()
 end);random:SetPoint('BOTTOMLEFT',6,35)
 local reset=button(p,'恢复默认',110,function() if ready() then ResetBodyShape();refresh() end end);reset:SetPoint('BOTTOMRIGHT',-6,35)
 local prev=button(p,'‹',28,function() B.page=B.page-1;refresh() end);prev:SetPoint('BOTTOMLEFT',6,7)
 local next=button(p,'›',28,function() B.page=B.page+1;refresh() end);next:SetPoint('BOTTOMRIGHT',-6,7)
 B.pageText=label(p,13);B.pageText:SetPoint('BOTTOM',0,12)
 B.note=label(p,11);B.note:SetPoint('BOTTOM',p,'BOTTOM',0,65);B.note:SetWidth(280);B.note:SetHeight(28)
 p:SetScript('OnUpdate',function(self,elapsed)
  B.elapsed=(B.elapsed or 0)+elapsed
  if B.elapsed>.5 then B.elapsed=0;local key=status();if key~=B.renderedStatus then refresh() end end
 end)
 p:Hide()
end
local render=C.Render
function C.Render(...)
 render(...);build();if not B.panel then return end
 local shown=C.active and C.step==3
 if shown then B.toggle:Show() else B.toggle:Hide() end
 B.toggle.caption:SetText(B.open and '返回外观选项' or '体型 / 捏脸')
 if shown and B.open then
  for _,row in ipairs(C.rows or {}) do row:Hide() end
  C.randomAppearance:Hide();C.pagePrev:Hide();C.pageNext:Hide();C.pageLabel:Hide()
  B.panel:Show();refresh()
 else B.panel:Hide() end
end
local function resetIdentity()
 if type(ResetBodyShape)=='function' then ResetBodyShape() end
 B.page=1;B.open=false
end
for _,method in ipairs({'SelectRace','SelectSex'}) do
 local old=C[method]
 C[method]=function(...)
  local race,sex=GetSelectedRace(),GetSelectedSex();local result=old(...)
  if GetSelectedRace()~=race or GetSelectedSex()~=sex then resetIdentity();C.Render() end
  return result
 end
end
local show=CharacterCreate_OnShow
function CharacterCreate_OnShow(...)
 if not PAID_SERVICE_TYPE then resetIdentity() end
 return show(...)
end
end)()
