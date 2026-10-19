-- TG9A: read-only recommendation provenance and glyph inspection. Never equip or cast.
local G=RebornTalentGuide;local S=RebornTalentCollections;local D=RebornTalentGuideEvidenceData
local A={cache={}};G.Evidence=A
local tokens={['战士']='WARRIOR',['圣骑士']='PALADIN',['巫医']='WITCHDOCTOR'}
local colors={good='|cff99e6b3',warn='|cffffd279',muted='|cffb8c7d9'}
local function color(kind,text)return(colors[kind]or colors.muted)..text..'|r'end
function A.Own(class)
 if G.fromBot then return false end
 if class=='WITCHDOCTOR'then return G.WD.IsDoctor()and true or false end
 local _,own=UnitClass('player');return own==class
end
function A.Sockets(class)
 local out={installed={},lines={},complete=false}
 if not A.Own(class)then out.reason=G.fromBot and'机器人雕文未查询；不使用本人雕文代替。'or'正在浏览其他职业；不读取本人的雕文作为对照。';return out end
 if type(GetGlyphSocketInfo)~='function'or type(GetActiveTalentGroup)~='function'then out.reason='雕文接口未就绪；装备状态未知。';return out end
 local ok,group=pcall(GetActiveTalentGroup,false,false)
 if not ok or type(group)~='number'or(group~=1 and group~=2)then out.reason='当前专精未就绪；装备状态未知。';return out end
 out.complete=true;out.group=group
 for i=1,6 do
  local read,enabled,kind,id=pcall(GetGlyphSocketInfo,i,group)
  if not read or(enabled~=true and enabled~=false and type(enabled)~='number')then
   out.complete=false;out.lines[#out.lines+1]='槽'..i..'：读取未就绪'
  elseif enabled==false or enabled==0 then out.lines[#out.lines+1]='槽'..i..'：未解锁'
  elseif id==nil or id==0 then out.lines[#out.lines+1]='槽'..i..'：空'
  elseif type(id)~='number'or id<1 or id%1~=0 then out.complete=false;out.lines[#out.lines+1]='槽'..i..'：状态未知'
  else
   out.installed[id]=true;local name=GetSpellInfo(id)
   out.lines[#out.lines+1]='槽'..i..'：'..(name or('技能 '..id))
  end
 end
 out.reason=out.complete and('本人当前专精 '..group..'；已装仅代表槽位读取，不代表效果验证。')or'部分槽位未就绪；不能把未知状态显示成未装备。'
 return out
end
function A.Targets(row,class)
 if not A.Own(class)then return nil,'受益技能：未读取该对象'end
 if type(IsSpellKnown)~='function'then return nil,'受益技能接口未就绪'end
 local found=0
 for _,group in ipairs(row.targets)do
  local known=false
  for _,id in ipairs(group.spells)do local ok,value=pcall(IsSpellKnown,id);if not ok then return nil,'受益技能读取失败'end;if value then known=true;break end end
  if known then found=found+1 end
 end
 return found>0,'受益技能已学 '..found..'/'..#row.targets..' 组'
end
function A.Rows(class)
 local rows={}
 if class=='WARRIOR'then
  local p=RebornTalentGuideData.plans[G.selected or 1]
  for _,x in ipairs(p and p.glyphList or{})do rows[#rows+1]={spell=x.spell,fact=D.glyphs[x.spell]}end
 elseif class=='PALADIN'then
  for _,id in ipairs(D.paladinPlans[RebornTalentGuidePaladin.selected or 1]or{})do rows[#rows+1]={spell=id,fact=D.glyphs[id]}end
 end
 return rows
end
function A.GlyphText(class)
 local sockets=A.Sockets(class)
 local plan=class=='PALADIN'and RebornTalentGuidePaladinData.plans[RebornTalentGuidePaladin.selected or 1]
 local lines={'雕文依据 · '..D.audit,'数据/源码核对与战斗实测分开；以下均未获得本服战斗验收。',''}
 if plan and plan.category=='PVP'then lines[#lines+1]='PVP仅列现有链路已核对的候选，不凑满三个大雕文；竞技场禁用的圣疗、PVE嘲讽用途不纳入。';lines[#lines+1]='专属PVP雕文与本服实际收益仍待逐项验证。'end
 if class=='WITCHDOCTOR'then
  lines[#lines+1]=color('warn','巫医：当前没有效果依据充分的专用雕文推荐。')
  lines[#lines+1]='其他职业雕文允许装备，不等于会增强巫医技能。外观雕文与旧RE触发不作为本方案收益。'
 else
  lines[#lines+1]='按当前方案列出候选；标“暂不推荐”的条目先不安装。'
  for _,entry in ipairs(A.Rows(class))do
   local row=entry.fact;lines[#lines+1]=''
   if not row then lines[#lines+1]=color('warn','技能 '..entry.spell..'：依据缺失，暂不推荐')
   else
    local name=GetSpellInfo(row.spell);local learned,learnText=A.Targets(row,class)
    local state=not row.chain and'数据链不完整，暂不推荐'or not row.routeKnown and'触发依据不足，暂不推荐'or not name and'客户端说明未就绪，暂不推荐'or learned==false and'受益技能未学习，暂缓安装'or'可供实测的候选'
    local equipped=sockets.installed[row.spell]and'已装'or sockets.complete and'未装备'or'装备未知'
    lines[#lines+1]=color(row.chain and row.routeKnown and name and learned~=false and'good'or'warn',row.kind..' · '..row.name)
    lines[#lines+1]=state..' · '..equipped
    lines[#lines+1]=learnText
    lines[#lines+1]='依据：'..row.basis
    lines[#lines+1]=row.note
    lines[#lines+1]=color('muted','物品 '..row.item..' → 属性 '..row.property..' → 效果 '..row.spell)
   end
  end
 end
 lines[#lines+1]='';lines[#lines+1]='当前已装对照';lines[#lines+1]=sockets.reason
 for _,line in ipairs(sockets.lines)do lines[#lines+1]=line end
 lines[#lines+1]='';lines[#lines+1]='本页只读，不购买、不消耗、不替换雕文。通过原雕文系统手动核对后安装；实测需比较开/关收益和切专精后的撤销。'
 return table.concat(lines,'\n')
end
function A.PlanText(class)
 local index=class=='WARRIOR'and G.selected or class=='PALADIN'and RebornTalentGuidePaladin.selected or G.WD.selected
 local level=class=='WITCHDOCTOR'and(G.WD.previewLevel or UnitLevel('player'))or 80
 local key=class..':'..tostring(index)..':'..tostring(level)
 if A.cache[key]then return A.cache[key]end
 local b,why=S.Recommendation(class);local ok,reason=false,why
 if b then ok,reason=S.Validate(b)end
 local lines={'依据核对 · TG9A','本服适配候选；玩法强度与完整技能联动未获实测认证。',ok and'节点、等级预算及前置/互斥：本地校验通过'or('规则未通过：'..tostring(reason or'数据未就绪'))}
 if class~='WITCHDOCTOR'then
  local changed={};local data=S.NativeData(class)
  if b and data then for _,tree in ipairs(data.trees)do for _,node in ipairs(tree)do if node.changed and(b.ranks[node.id]or 0)>0 then changed[#changed+1]=node.name end end end end
  if #changed>0 then lines[#lines+1]='已选本服替换节点 '..#changed..' 项：'..table.concat(changed,'、')end
  lines[#lines+1]='原生树163节点已对照本服Talent数据；客户端仍以实际说明为准。'
 else lines[#lines+1]='四类方案10—80级逐级校验；仅载入草稿，保存后才作用于当前方案。'end
 lines[#lines+1]='雕文依据和当前已装状态见“雕文建议”；数据匹配不等于战斗收益已验证。'
 local text=table.concat(lines,'\n')
 -- Missing/late data is not cached as a permanent failure.
 if b and ok then A.cache[key]=text end
 return text
end
function A.Render()
 if not G.frame or not G.frame:IsShown()or not G.Navigation then return end
 local state=G.Navigation.State();local class=tokens[G.catalogClass]
 if not class or state.source~='recommended'or not G.Navigation.visible or #G.Navigation.visible==0 then return end
 local text
 if G.showGlyphs then text=A.GlyphText(class)
 else
  text=(G.description:GetText()or''):gsub('\n\n依据核对 · TG9A.*$','')
  text=text:gsub('\n\n雕文参考\n.-\n\n加点清单','\n\n雕文依据见“雕文建议”。\n\n加点清单')
  text=text:gsub('\n\n雕文\n.-\n\n来源','\n\n雕文依据见“雕文建议”。\n\n来源')
  text=text..'\n\n'..A.PlanText(class)
 end
 G.glyphPanel:Hide();G.description:SetText(text);G.scroll:Show()
 G.content:SetHeight(math.max(394,G.description:GetStringHeight()+16));if G.scroll.UpdateScrollChildRect then G.scroll:UpdateScrollChildRect()end
 local view=G.catalogClass..':'..tostring(state.selected)..':'..tostring(G.showGlyphs)
 if A.view~=view then G.scroll:SetVerticalScroll(0);A.view=view end
end
local refresh=G.Refresh
function G.Refresh(...)local result=refresh(...);A.Render();return result end
for _,adapter in ipairs({RebornTalentGuidePaladin,G.WD})do
 local original=adapter.Refresh;adapter.Refresh=function(...)local result=original(...);A.Render();return result end
end
local events=CreateFrame('Frame')
for _,name in ipairs({'GLYPH_ADDED','GLYPH_REMOVED','GLYPH_UPDATED','ACTIVE_TALENT_GROUP_CHANGED','PLAYER_TALENT_UPDATE'})do events:RegisterEvent(name)end
events:SetScript('OnEvent',function()if G.showGlyphs then A.Render()end end);A.events=events
