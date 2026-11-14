exec((__import__('pathlib').Path(__file__).parent/'inspect_inputs.py').read_text('utf8').split("for n in ['Patch-YB.mpq'")[0])
import subprocess,shutil,zipfile
m=R(str(c/'Data/Patch-YB.mpq'));before=m.read_file(r'Interface\GlueXML\CharacterSelect.lua');m.close();(w/'before.lua').write_bytes(before)
hw=w.parent/'codexwork_WOW64CREATOR1H';assert before==(hw/'client_patch/Interface/GlueXML/CharacterSelect.lua').read_bytes(),'current is not H; merge required'
t=before.decode('utf8');start=t.index(' local function button(b)');end=t.index(' function RebornCharacterSelect_ApplyStyle()',start);block=t[start:end]
block=block.replace("  if not b or b._rebornActionFrameH then return end", "  if not b then return end\n  if b._rebornFitActionI then b._rebornFitActionI();return end")
block=block.replace("  local function state(setter,color,layer)","  local box=CreateFrame('Frame',nil,b);box:SetPoint('CENTER',b,'CENTER',0,0);box:EnableMouse(false)\n  b._rebornFitActionI=function()\n   local fs=b:GetFontString()\n   box:SetSize(math.ceil((fs and fs:GetStringWidth() or 60)+24),math.ceil(math.max(14,fs and fs:GetStringHeight() or 14)+12))\n  end\n  local function state(setter,color,layer)")
block=block.replace("t:SetAllPoints(b)","t:SetAllPoints(box)")
block=block.replace("edge:SetPoint(side..'LEFT',b,side..'LEFT',0,0);edge:SetPoint(side..'RIGHT',b,side..'RIGHT',0,0)","edge:SetPoint(side..'LEFT',box,side..'LEFT',0,0);edge:SetPoint(side..'RIGHT',box,side..'RIGHT',0,0)")
block=block.replace("edge:SetPoint('TOP'..side,b,'TOP'..side,0,0);edge:SetPoint('BOTTOM'..side,b,'BOTTOM'..side,0,0)","edge:SetPoint('TOP'..side,box,'TOP'..side,0,0);edge:SetPoint('BOTTOM'..side,box,'BOTTOM'..side,0,0)")
block=block.replace("  b:SetDisabledFontObject(RebornSelectActionDisabledH)","  b:SetDisabledFontObject(RebornSelectActionDisabledH)\n  b._rebornFitActionI()")
new=t[:start]+block+t[end:];assert new[:start]==t[:start] and new[start+len(block):]==t[end:]
(w/'after.lua').write_text(new,'utf8');(w/'syntax.lua').write_text('do return end\n'+new,'utf8');runner=r/'000Ascendupdate/000Ascendupdate20261111/codexwork_WOW64CREATOR1A/lua_runner.exe';res=subprocess.run([str(runner),str(w/'syntax.lua')],capture_output=True);assert res.returncode==0,res.stdout+res.stderr
p=w.parent/'codexfix_20261113_阶段WOW64CREATOR1I_选角按钮底框贴合文字候选';p.mkdir(exist_ok=True)
def put(src,rel):
 d=p/rel;d.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(src,d)
put(w/'after.lua','01_导入Patch-YB.mpq/Interface/GlueXML/CharacterSelect.lua');put(w/'before.lua','backup_原文件/Interface/GlueXML/CharacterSelect.lua')
changes={'input_sha256':hashlib.sha256(before).hexdigest(),'output_sha256':hashlib.sha256((w/'after.lua').read_bytes()).hexdigest(),'only':'styling helper visual frame bounds','padding':'horizontal 12 each side; vertical 6 each side; min text height14','game_tested':False}
(p/'checks').mkdir(exist_ok=True);(p/'checks/file-changes.json').write_text(json.dumps(changes,indent=2),'utf8')
(p/'README.md').write_text('''# WOW64CREATOR1I：按钮底框贴合文字（候选，未实机）

完全退出游戏，把01内Interface导入现有 Data/Patch-YB.mpq，覆盖一个CharacterSelect.lua。保存并关闭MPQEditor再启动。不更换EXE，不重新安装H，不动Claude退出/声音修复和机械侏儒资源。

H按原按钮尺寸填底色，导致进入游戏/设置等按钮框很大。I改为实际字体测量宽度+24、高度+12（最小文字高度14），相当于左右各12、上下各6像素留白；框仍居中。普通/按下/高亮/禁用填充与细边全部随小框。每次刷新按实际文字重新量尺寸，避免中文/英文变化后沿用旧宽度。原按钮点击区域及布局、回调保留，只缩小可见底框。

Lua5.1语法解析与表现helper之外字节不变检查通过；未实机。请看进入游戏/删除/后退/设置框是否贴字、悬停/按下和翻页后是否仍正常。

输入输出哈希见checks。输入不匹配先合并，勿整文件回盖。回退仅限未叠加后续Lua变更：退出游戏将backup中原Lua导回YB，会恢复H大框。无DBC/SQL/EXE/模型，无运行端写入和提交推送。顶部偶发种手错字仍未修。
''','utf8')
(p/'SHA256SUMS.txt').write_text('\n'.join(hashlib.sha256(x.read_bytes()).hexdigest()+'  '+x.relative_to(p).as_posix() for x in sorted(p.rglob('*')) if x.is_file())+'\n','utf8')
z=p.with_suffix('.zip')
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED) as f:
 for x in p.rglob('*'):
  if x.is_file():f.write(x,x.relative_to(p).as_posix())
with zipfile.ZipFile(z) as f:
 for n in f.namelist():assert f.read(n)==(p/n).read_bytes()
h=hashlib.sha256(z.read_bytes()).hexdigest();(w/'delivery.json').write_text(json.dumps({'zip':str(z),'sha256':h},ensure_ascii=False,indent=2),'utf8')
(r/'交接_Codex_WOW64CREATOR1I_按钮底框贴文字_20261113.md').write_text(f'# WOW64CREATOR1I 未实机\n包：{z}\nSHA256：{h}\n\n'+(p/'README.md').read_text('utf8')+'\n当前H实装逐字节匹配，出包前读协作尾表/当前项目AGENTS/最近H交接，沿用已读并行及UI规范；仅视觉helper，未触及其它源或运行端。\n','utf8')
with (r/'协作说明_并行开发.md').open('a',encoding='utf8') as f:f.write(f'\n| 2026-11-13 | Codex | WOW64CREATOR1I | 已释放 | 按钮文字加留白小框候选未实机 | 仅YB CharacterSelect.lua表现helper | 当前H逐字匹配；Lua语法/其它字节不变/ZIP通过；SHA256 {h} | {z}；无EXE/模型/SQL/运行端写入 |\n')
print(json.dumps({'zip':str(z),'sha256':h},ensure_ascii=False,indent=2))
