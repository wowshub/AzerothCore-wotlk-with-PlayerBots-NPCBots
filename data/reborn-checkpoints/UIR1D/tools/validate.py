from pathlib import Path
import struct,json,hashlib,xml.etree.ElementTree as ET
from lupa.lua51 import LuaRuntime
P=Path(__file__).resolve().parents[1];ui=P/'02_MPQ导入目录/导入PATCH-YB/Interface/GlueXML';lua=LuaRuntime(unpack_returned_tuples=True)
s=(ui/'RebornRacePreview.lua').read_text(encoding='utf8');assert lua.eval('function(s) return loadstring(s)~=nil end')(s)
lua.execute('''
frames={};creates=0
local methods={}
function methods:SetScript(k,v) self.scripts[k]=v end
function methods:SetPoint(...) self.point={...} end
function methods:SetSize(w,h) self.w=w;self.h=h end
function methods:SetScale(v) self.scale=v end
function methods:GetScale() return self.scale or 1 end
function methods:GetFrameLevel() return 1 end
function methods:SetChecked(v) self.checked=v end
function methods:SetTexture(v) self.texture=v end
function methods:SetNormalTexture(v) self.normal=v end
function methods:SetPushedTexture(v) self.pushed=v end
function methods:SetText(v) self.text=v end
function methods:Show() self.visible=true end
function methods:Hide() self.visible=false;if self.scripts.OnHide then self.scripts.OnHide(self) end end
function methods:CreateFontString() return CreateFrame('Font') end
function CreateFrame(kind,name,parent,template)
 local f={scripts={},kind=kind,parent=parent};setmetatable(f,{__index=function(_,k) return methods[k] or (k:match('^[A-Z]') and function() end or nil) end});table.insert(frames,f);if name then _G[name]=f end;return f
end
CharacterCreate=CreateFrame('Frame')
CharCreateRaceButtonsFrame=CreateFrame('Frame')
CharCreateRaceButton23=CreateFrame('CheckButton')
CharCreateRaceButton25=CreateFrame('CheckButton')
for _,n in ipairs({'RebornSethrakPreviewButton','RebornOgrePreviewButton'}) do
 local b=CreateFrame('CheckButton',n,CharacterCreate);b.borderfaction=CreateFrame('Texture');b.nameFrame={text=CreateFrame('Font')}
end
function CharacterCreate_OnShow() end
function CharacterCreate_OnHide() end
function CreateCharacter() creates=creates+1 end
function GetCursorPosition() return 0,0 end
''')
lua.execute(s)
lua.execute('''
CharacterCreate_OnShow()
local a,b=RebornSethrakPreviewButton,RebornOgrePreviewButton
assert(a.point[2]==CharCreateRaceButton23 and a.point[4]==-70)
assert(b.point[2]==CharCreateRaceButton25 and b.point[4]==70)
assert(a.point[5]==0 and b.point[5]==0)
assert(a.w==62 and b.w==62 and a.scale==0.78 and b.scale==0.78)
assert(a.borderfaction.texture:find('AlliRoundRaceOk') and b.borderfaction.texture:find('HordeRoundRaceOk'))
assert(a.visible and b.visible)
a.scripts.OnClick();CreateCharacter();assert(creates==0 and a.checked and not b.checked)
b.scripts.OnClick();assert(b.checked and not a.checked)
CharacterCreate_OnHide();CreateCharacter();assert(creates==1 and not a.checked and not b.checked)
PAID_SERVICE_TYPE=1;CharacterCreate_OnShow();assert(not a.visible and not b.visible)
PAID_SERVICE_TYPE=nil;CharacterCreate_OnShow();assert(a.visible and b.visible)
''')

lua.execute("CharacterCreate_OnShow()")
for name, expected in {'RebornSethrakPreviewButton': ['静电盘绕：对8码内的敌人造成自然伤害，并使其移动速度降低40%，持续6秒。冷却：2分钟。', '鳞甲：装备提供的护甲提高2%。', '蛇形反射：躲闪几率提高1%。', '风暴之血：自然伤害和治疗效果提高1%。', '抗毒体质：中毒效果持续时间缩短15%。'], 'RebornOgrePreviewButton': ['头槌：使附近一名敌人昏迷2秒。冷却：2分钟。', '蛮力：力量提高2%。', '厚皮：装备提供的护甲提高2%。', '重手：使用锤类和拳套武器时，精准提高3点。', '食人魔烹饪：烹饪技能提高5点。']}.items():
 tooltip=lua.globals()[name].tooltip
 assert all(line in tooltip for line in expected)
 assert '来源参考' not in tooltip and '尚未实装' not in tooltip and '开发中' not in tooltip
 assert tooltip.count('\n\n')==6
 assert tooltip.startswith('|cffffffff') and tooltip.count('|cffffd200')==1 and tooltip.count('|cffffffff')==2
 assert tooltip.count('|r')==3 and tooltip.count('- ')==5
ET.fromstring(Path('D:\\000rebornWOW\\000RebornWOWHighForkPRO\\000Ascendupdate\\000Ascendupdate20261029\\codexfix_20261029_阶段UIR1B_圆环图标与对称布局\\02_MPQ导入目录\\导入PATCH-YB\\Interface\\GlueXML\\CharacterCreate.xml').read_bytes())
checks=['white heading yellow introduction white traits; balanced color codes','both tooltips include all five exact translated traits','tooltips omit status disclaimers as requested','Lua5.1 parse','same-row opposite relative anchors +/-70','same size62 scale0.78','native Alliance/Horde rings','selection highlight','create blocked and restored','paid service hides previews','XML parsed']
for p in (P/'02_MPQ导入目录').rglob('*.blp'):
 b=p.read_bytes();w,h=struct.unpack_from('<II',b,12);o=struct.unpack_from('<I',b,20)[0];assert all(b[o+4*(y*w+x)+3]==0 for x,y in [(0,0),(w-1,0),(0,h-1),(w-1,h-1)]);assert b[o+4*((h//2)*w+w//2)+3]>0
 checks.append(p.parent.name+' corners transparent and center retained')
(P/'checks/validation.json').write_text(json.dumps({'checks':checks,'game':'not run','model_black_silhouette':'reported by user, not fixed in UIR1B'},ensure_ascii=False,indent=2),encoding='utf8')
print('PASS',len(checks),'checks')
