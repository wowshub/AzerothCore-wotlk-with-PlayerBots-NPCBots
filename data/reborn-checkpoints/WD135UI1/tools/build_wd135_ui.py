from pathlib import Path
import datetime,struct,json,hashlib,zipfile,shutil,subprocess
from wd9a_storm import Archive
import pympq
R=Path(r'D:\000rebornWOW\000RebornWOWHighForkPRO')
C=R/'beascendclient/newrebornWOWli20261007beAscend - blacknight'
P=R/'000Ascendupdate/000Ascendupdate20261007'/('codexfix_'+datetime.datetime.now().strftime('%Y%m%d_%H%M%S')+'_WD135UI1_召唤栏空槽与回收图标')
P.mkdir(parents=True);Path('wd135ui_path.txt').write_text(str(P),encoding='utf8')
def save(name,b):
 f=P/name;f.parent.mkdir(parents=True,exist_ok=True);f.write_bytes(b if isinstance(b,bytes) else b.encode('utf8'));return f
rel='Interface/AddOns/DragonUI/modules/actionbars/witchdoctorbar.lua'
old=(C/rel).read_bytes();s=old.decode('utf-8-sig')
before='9003432, 9003382, 9003380, 9003390}}'
assert s.count(before)==1;s=s.replace(before,'9003432, 9003382, 9003380, 9003390, 9003953}}')
marker="    if id then GameTooltip:SetHyperlink('spell:' .. id)"
assert s.count(marker)==1
early='''    -- Empty slots describe their purpose, never preview an unlearned spell.
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
'''
s=s.replace(marker,early+marker)
# Utilities also remain visually empty when unlearned, including recall/ritual.
s=s.replace('if button.dedicatedSummon and not IsSpellKnown(id) then id = nil end','if id and not IsSpellKnown(id) then id = nil end')
save('rollback/'+rel,old);candidate=save('02_覆盖到客户端根目录/'+rel,s)

# Preserve installed LIGHT8B archive contents; replace only Recall icon reference.
a=Archive(C/'Data/patch-ZA.mpq');listing=a.read('(listfile)').decode('utf8').splitlines()
content={name:a.read(name) for name in listing if not name.startswith('(')};a.close()
assert len(content)==10 and all(v is not None for v in content.values())
save('rollback/Data/patch-ZA.mpq',(C/'Data/patch-ZA.mpq').read_bytes())
spellkey=next(k for k in content if k.lower()=='dbfilesclient\\spell.dbc')
raw=content[spellkey];b=bytearray(raw);_,n,f,size,ss=struct.unpack_from('<4s4I',b)
assert f==234 and size==936
rows={struct.unpack_from('<I',b,20+i*size)[0]:20+i*size for i in range(n)}
assert 9003953 in rows
assert struct.unpack_from('<I',b,rows[9003541]+133*4)[0]==3062
struct.pack_into('<I',b,rows[9003541]+133*4,3994)
assert b[:rows[9003541]+133*4]==raw[:rows[9003541]+133*4]
assert b[rows[9003541]+134*4:]==raw[rows[9003541]+134*4:]
content[spellkey]=bytes(b)
for name,body in content.items():save('client_mpq输入/'+name.replace('\\','/'),body)
# No new icon row: reuse the existing standard Totemic Recall graphic.
a=Archive(C/'Data/Patch-XA.mpq');icons=a.read('DBFilesClient\\SpellIcon.dbc');a.close()
_,nn,ff,sz,sss=struct.unpack_from('<4s4I',icons);st=icons[20+nn*sz:]
ir={struct.unpack_from('<I',icons,20+i*sz)[0]:struct.unpack_from('<II',icons,20+i*sz) for i in range(nn)}
assert st[ir[3994][1]:].split(b'\0')[0].lower()==b'interface\\icons\\spell_shaman_totemrecall'
mpq=P/'02_覆盖到客户端根目录/Data/patch-ZA.mpq';mpq.parent.mkdir(parents=True,exist_ok=True)
a=pympq.create_archive(str(mpq),[pympq.MPQ_CREATE_ARCHIVE_V1],64)
for name in content:
 f=P/'client_mpq输入'/name.replace('\\','/')
 a.add_file(str(f),name,[pympq.MPQ_FILE_COMPRESS],[pympq.MPQ_COMPRESSION_ZLIB])
a.close();a=Archive(mpq)
for k,v in content.items():assert a.read(k)==v
a.close()
save('checks/dbc_validation.json',json.dumps({'preserves_installed_LIGHT8B':True,'WD135A_9003953_preserved':True,'changed_spell':9003541,'changed_field':133,'old_icon':3062,'new_icon':3994,'warden_unchanged':True,'mpq_readback':True},indent=2))

# Exercise the actual Tooltip function against learned/unlearned mock states.
start=s.index('local function Tooltip(self)');end=s.index('local function Skin(button)',start)
test='''local known = false
function IsSpellKnown(id) return known end
local lines, links = {}, {}
GameTooltip = {
 SetOwner=function() end,
 SetText=function(self,t) lines={t} end,
 AddLine=function(self,t) lines[#lines+1]=t end,
 SetHyperlink=function(self,t) links[#links+1]=t end,
 Show=function() end,
}
'''+s[start:end]+'''
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
'''
tf=save('checks/tooltip_test.lua',test)
lua=R/'beascendBuild/modules/mod-ale/src/lualib/lua/RelWithDebInfo/lua52_interpreter.exe'
result=subprocess.run([str(lua),str(tf)],capture_output=True,text=True);assert result.returncode==0,result.stderr
save('checks/test_result.txt',result.stdout)
compiler=lua.with_name('lua52_compiler.exe')
result=subprocess.run([str(compiler),'-p',str(candidate)],capture_output=True,text=True);assert result.returncode==0,result.stderr
assert (C/rel).read_bytes()==old
text='''# WD135UI1：三项界面修复（待实机验收）

1. 灵魂链接雕像9003953登记到神像/Idol栏，只在真正学会后显示。
2. 所有未学习空槽只显示栏位名称和用途，不展示未学会技能的数值、冷却或学习要求。守卫、神像、雕像、一键放置、回收、独立守卫、大巫毒、魔像均覆盖。已学会的技能继续正常显示详情。未学习的一键放置/回收图标也置空。
3. 灵魂回收9003541改用现有图腾回收图案 Spell_Shaman_TotemRecall（图标3994）；灵魂守卫9003660保持原绿色灵魂图案。这是选用客户端已有回收图标，不是新绘制图标。

## 安装（推荐，匹配你现在的 patch-ZA）
退出游戏。将现有 Data/patch-ZA.mpq 和 Interface/AddOns/DragonUI/modules/actionbars/witchdoctorbar.lua 备份到 Data 之外。
复制 `02_覆盖到客户端根目录` 内的 Data、Interface 到 blacknight 根目录，覆盖同名两文件。
本包 patch-ZA 基于你当前安装的 LIGHT8B 内容，只修改灵魂回收的图标字段；WD135A的9003953及烈焰风暴九等级视觉、模型、粒子全部保留。不再额外放旧patch-ZZ。
DLL、INI、服务端不改。不需要编译服务端。

## 如果你改用自己导入 Patch-XA
把client_mpq输入中的DBFilesClient、Spells按原内部路径导入Patch-XA副本，同时覆盖上述Lua；将旧patch-ZA/ZZ移出Data，避免其旧Spell表覆盖新图标。两种安装方式选一种。

## 验证
酿造未学会战争魔像时悬停空魔像槽：只有用途提示。测试其他空槽相同。切换并激活学会战争魔像的方案：图标与技能详情正常恢复。
学会灵魂链接雕像后，右键神像栏展开，应见新增技能并可选入主槽。
技能书与动作条的灵魂回收应变为回收图案；灵魂守卫仍是绿色灵魂图案。重启整个游戏读取DBC，单独/reload不能保证重读DBC。
本地Lua5.2语法检查及悬停函数测试通过（8种空槽、5种已学会辅助槽）；不替代游戏3.3.5实测和战斗锁定验证。

## 回滚
退出游戏，用rollback内两文件按原位置恢复。这会回到安装本包前的LIGHT8B和原DragonUI。
'''
save('README_覆盖与测试说明.md',text)
memory='''# WD135UI1 记录
基线为blacknight现场Lua、已装patch-ZA(LIGHT8B)、Patch-XA中的SpellIcon。不是从旧WD包整表覆盖。
读取项目规则与资源目录，并应用stabilize-spelldraft-client-ui原位更新原则；图标核查沿用trace-and-port-coa-spell-resources。未使用图标染色冲突Skill的修复方法，因为本次不是染色争抢。
Tooltip先核查真实IsSpellKnown，未学习提前返回，不读取spell超链接。Paint同步隐藏所有未学会图标，不修改安全施法属性/协议/冷却逻辑。补充Idol列表9003953；现场C++ Slot已接受该ID。
client Spell仅9003541字段133从3062改3994；复用现有SpellIcon与贴图。保留全部LIGHT8B文件。没有修改服务器DBC和原客户端，也没有提交推送。
图标是原客户端Totemic Recall美术的复用，并非官方灵魂回收独有图案或新生成美术。整体待用户游戏验证。
'''
save('memory.md',memory);save('phaseFixForNewChat.md',memory+'\n'+text)
save('tutor.md','''# 大白话教学
技能栏名单像通讯录：新技能不登记，就不会出现在下拉列表，所以补上9003953。
空槽原来只隐藏图标，提示框却仍按技能编号查详细说明；现在先问“学会了吗”，没学会就只写用途并停止后续显示，学会才查技能说明。
图标编号像图片目录索引。这里只把灵魂回收的索引换成已有的回收图片；不改技能伤害、返蓝或冷却。技能守卫仍保留原索引。
MPQ里的Spell是整表，因此必须用你现有的LIGHT8B作底版，只改一个字段，避免之前的WD135A记录丢失。Lua则按实际客户端文件修改副本，回滚留原字节。
''')
save('tools/build_wd135_ui.py',Path(__file__).read_bytes())
manifest={str(f.relative_to(P)):hashlib.sha256(f.read_bytes()).hexdigest() for f in P.rglob('*') if f.is_file()}
save('checks/sha256.json',json.dumps(manifest,ensure_ascii=False,indent=2))
for name in ['updateMemory.md','tutorMemory.md']:
 with (R/name).open('a',encoding='utf8') as f:f.write('\n\n'+memory+'\n来源：'+str(P)+'\n')
with zipfile.ZipFile(P.with_suffix('.zip'),'w',zipfile.ZIP_DEFLATED) as z:
 for f in P.rglob('*'):
  if f.is_file():z.write(f,str(f.relative_to(P)))
with zipfile.ZipFile(P.with_suffix('.zip')) as z:assert z.testzip() is None
print(P.with_suffix('.zip'));print('PASS',result.returncode)
