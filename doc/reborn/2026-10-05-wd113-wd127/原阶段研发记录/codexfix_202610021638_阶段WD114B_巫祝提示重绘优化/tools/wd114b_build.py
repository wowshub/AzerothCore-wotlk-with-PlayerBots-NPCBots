from pathlib import Path
from datetime import datetime
import shutil

root=Path(r'D:/000rebornWOW/000RebornWOWHighForkPRO')
base=Path(Path(r'D:/000rebornWOW/wd114_path.txt').read_text(encoding='utf-8-sig').strip())
stamp=datetime.now().strftime('%Y%m%d%H%M')
out=root/'000Ascendupdate'/'000Ascendupdate20261002'/f'codexfix_{stamp}_阶段WD114B_巫祝提示重绘优化'
out.mkdir(exist_ok=False)
Path(r'D:/000rebornWOW/wd114b_path.txt').write_text(str(out),encoding='utf-8')
rel=Path('02_覆盖到客户端根目录/Interface/AddOns/RebornWitchDoctorTalents/NumericTooltip.lua')
src=base/rel
dst=out/rel;dst.parent.mkdir(parents=True)
backup=out/'rollback_WD114A'/rel;backup.parent.mkdir(parents=True);shutil.copy2(src,backup)
s=src.read_text(encoding='utf-8-sig')
s=s.replace('-- WD114:','-- WD114B:')
s=s.replace('local function refresh(self,forced)','local function draw(self,forced)')
s=s.replace(' self.wd114Spell=id',' if self.wd114Spell~=id then self.wd114Lines=nil;self.wd114EffectLine=nil end\n self.wd114Spell=id\n local changed=false',1)
a=s.index('    local original=self.wd114Lines[key] or text')
b=s.index('\n   end',a)
s=s[:a]+'''    -- Native tooltip setters can rebuild the same FontString without clearing it.
    local record=self.wd114Lines[key]
    local original=(record and text==record.rendered) and record.original or text
    local clean=plain(original)
    if clean:match("^%s*%d[%d,%. ]*%s*法力值%s*$") or clean:match("^%s*%d[%d,%. ]*%s*[Mm]ana%s*$") then
     local rendered=value and (tostring(value.cost)..(en and " Mana" or "法力值")) or (original..(en and " (syncing)" or "（同步中）"))
     self.wd114Lines[key]={original=original,rendered=rendered}
     if text~=rendered then font:SetText(rendered);changed=true end
    else
     self.wd114Lines[key]=nil
    end'''+s[b:]
s=s.replace('self.wd114EffectLine=self:NumLines();if self.Show then self:Show() end','self.wd114EffectLine=self:NumLines();changed=true')
s=s.replace('if font then font:SetText(text) end','if font and font:GetText()~=text then font:SetText(text);changed=true end')
needle='\nend\nlocal function receive(message)'
s=s.replace(needle,'''\n if changed and self.Show and self:IsShown() then self:Show() end
end
local function refresh(self,forced)
 -- Show() and other tooltip hooks may synchronously request another refresh.
 if self.wd114Drawing then return end
 self.wd114Drawing=true
 draw(self,forced)
 self.wd114Drawing=nil
end
local function receive(message)''',1)
s=s.replace('then refresh(tip,id) end','then refresh(tip) end')
dst.write_text(s,encoding='utf-8')
tools=out/'tools';tools.mkdir();shutil.copy2(Path(r'D:/000rebornWOW/wd114b_build.py'),tools/'wd114b_build.py')
print(out)
