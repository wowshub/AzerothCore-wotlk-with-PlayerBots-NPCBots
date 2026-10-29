from pathlib import Path
import sys,struct,json,hashlib
ROOT=Path(r'D:\000rebornWOW\000RebornWOWHighForkPRO');A=ROOT/'000Ascendupdate/000Ascendupdate20261029/codexfix_20261029_阶段UIR1A_蛇人与双头食人魔预览';B=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(A/'tools'));from storm_read import Archive
live=ROOT/'beascendclient/newrebornWOWli20261029beAscend/Data';rows=[]
for mpq,names in [('Patch-YB.mpq',['Interface/GlueXML/RebornRacePreview.lua','Interface/GlueXML/CharacterCreate.xml','Reborn/Preview/UIR1A/Sethrak/icon.blp']),('Patch-YC.mpq',['Reborn/Preview/UIR1A/Ogre/icon.blp'])]:
 arc=Archive(live/mpq)
 for name in names:
  data=arc.read(name.replace('/','\\'));assert data is not None,name
  old=A/'02_MPQ导入目录'/('导入PATCH-YB' if 'YB' in mpq else '导入PATCH-YC')/name
  assert data==old.read_bytes(), 'live baseline differs '+name
  dest=B/'backup_原文件'/mpq/name;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(data)
  rows.append({'mpq':mpq,'path':name,'sha256':hashlib.sha256(data).hexdigest()})
 arc.close()
(B/'checks/input_hashes.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2),encoding='utf8')
# Keep the CoA pixels; apply circular alpha coverage directly to every raw BGRA mip.
for race,mpq in [('Sethrak','Patch-YB.mpq'),('Ogre','Patch-YC.mpq')]:
 data=bytearray((B/'backup_原文件'/mpq/f'Reborn/Preview/UIR1A/{race}/icon.blp').read_bytes());assert data[:4]==b'BLP2' and data[8]==3
 w,h=struct.unpack_from('<II',data,12)
 for level in range(16):
  off=struct.unpack_from('<I',data,20+4*level)[0];size=struct.unpack_from('<I',data,84+4*level)[0]
  if not off or not size:continue
  mw,mh=max(1,w>>level),max(1,h>>level);assert size>=mw*mh*4
  for y in range(mh):
   for x in range(mw):
    dist=((x+.5-mw/2)**2+(y+.5-mh/2)**2)**.5;coverage=max(0,min(1,min(mw,mh)*.455-dist+.5));at=off+4*(y*mw+x)+3;data[at]=round(data[at]*coverage)
 out=B/'02_MPQ导入目录'/('导入PATCH-YB' if race=='Sethrak' else '导入PATCH-YC')/f'Reborn/Preview/UIR1B/{race}/icon-round.blp';out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(data)
ui=B/'02_MPQ导入目录/导入PATCH-YB/Interface/GlueXML';ui.mkdir(parents=True,exist_ok=True)
s=(B/'backup_原文件/Patch-YB.mpq/Interface/GlueXML/RebornRacePreview.lua').read_text(encoding='utf8');s=s.replace('新种族预览 · UIR1A','新种族预览 · UIR1B')
start=s.index('    if not launcher then',s.index('local originalOnShow'))
end=s.index('\nend\nlocal originalOnHide',start)
s=s[:start]+'''    -- UIR1B: XML-owned buttons reuse the exact native circular race template.
    local buttons = { RebornSethrakPreviewButton, RebornOgrePreviewButton }
    local neighbours = { CharCreateRaceButton23, CharCreateRaceButton25 }
    for i,b in ipairs(buttons) do
        local e=entries[i]
        local anchor=neighbours[i]
        local index=i
        b:ClearAllPoints()
        b:SetSize(62,62)
        b:SetScale(0.78)
        -- Existing top-row centers are +/-185, separated by 70 units.
        -- A relative center step follows the current anchor even after resizing.
        b:SetPoint("CENTER", anchor, "CENTER", i==1 and -70 or 70, 0)
        b:SetFrameStrata("HIGH")
        if CharCreateRaceButtonsFrame then b:SetFrameLevel(CharCreateRaceButtonsFrame:GetFrameLevel()+20) end
        b:SetNormalTexture("Reborn\\\\Preview\\\\UIR1B\\\\"..e.key.."\\\\icon-round.blp")
        b:SetPushedTexture("Reborn\\\\Preview\\\\UIR1B\\\\"..e.key.."\\\\icon-round.blp")
        b.borderfaction:SetTexture("Interface\\\\Glues\\\\CharacterCreate\\\\"..(i==1 and "AlliRoundRaceOk" or "HordeRoundRaceOk"))
        b.borderfaction:SetAlpha(1)
        b.borderfaction:Show()
        b.nameFrame.text:SetText(i==1 and "蛇人" or "双头食人魔")
        b.tooltip=e.title.." · 预览 / 开发中"
        b:SetScript("OnClick", function()
            Open(index)
            for j,other in ipairs(buttons) do other:SetChecked(j==index) end
        end)
        if PAID_SERVICE_TYPE then b:Hide() else b:Show() end
    end''' + s[end:]
# Preview panel's icon tabs use the same round portraits (keep existing tab layout).
s=s.replace('b:SetNormalTexture(prefix..e.key.."\\\\icon.blp")','b:SetNormalTexture("Reborn\\\\Preview\\\\UIR1B\\\\"..e.key.."\\\\icon-round.blp")')
s=s.replace('    active = false\n    if preview then preview:Hide() end','    active = false\n    if RebornSethrakPreviewButton then RebornSethrakPreviewButton:SetChecked(false) end\n    if RebornOgrePreviewButton then RebornOgrePreviewButton:SetChecked(false) end\n    if preview then preview:Hide() end')
(ui/'RebornRacePreview.lua').write_text(s,encoding='utf8')
xml=(B/'backup_原文件/Patch-YB.mpq/Interface/GlueXML/CharacterCreate.xml').read_bytes();assert xml.count(b'</Ui>')==1
extra=b'\r\n\t<CheckButton name="RebornSethrakPreviewButton" inherits="CharCreateRaceButtonTemplate" parent="CharacterCreate" hidden="true"/>\r\n\t<CheckButton name="RebornOgrePreviewButton" inherits="CharCreateRaceButtonTemplate" parent="CharacterCreate" hidden="true"/>\r\n'
(ui/'CharacterCreate.xml').write_bytes(xml.replace(b'</Ui>',extra+b'</Ui>'))
print('built UIR1B; 4 live inputs match UIR1A')
