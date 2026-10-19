local S=RebornTalentCollections;local X=S.Share;local C=RebornTalentTreeCanvas;local Windows=RebornTalentPanelWindows
local V={serial=0};X.ui=V
local classes={WARRIOR='战士',PALADIN='圣骑士',WITCHDOCTOR='巫医'}
local function enable(b,on)if on then b:Enable()else b:Disable()end end
local function message(text)V.message:SetText(text)end
local function invalidate()
 V.serial=V.serial+1;V.preview=nil;enable(V.confirm,false);V.summary:SetText('粘贴完整分享文本，再点击“检查导入”。\n\n导入只建立本地收藏，不自动应用、洗点或切换角色方案。')
end
local function height()
 local text=V.edit:GetText()or'';local _,lines=text:gsub('\n','')
 V.edit:SetHeight(math.max(442,(lines+math.ceil(#text/100)+2)*15))
 if V.scroll.UpdateScrollChildRect then V.scroll:UpdateScrollChildRect()end
end
local function setText(text)
 V.setting=true;V.edit:SetText(text);V.setting=false;invalidate();height();V.scroll:SetVerticalScroll(0)
end
function X.CheckInput()
 local parsed,why=X.Preview(V.edit:GetText()or'')
 invalidate()
 if not parsed then message(why);return false end
 parsed.serial=V.serial;V.preview=parsed
 local b,meta=parsed.build,parsed.profile
 local lines={parsed.name,classes[b.class]..' · '..b.level..'级 · 来源版本 '..parsed.sourceVersion,'用途：'..meta.scene..' · 职责：'..meta.role,'',parsed.valid and'✓ 配点规则有效'or'! 待完善草稿',parsed.validation or'',''}
 local diff,err,current=S.Compare(b)
 if current then
  local add,remove=0,0;for _,row in ipairs(diff)do if row.delta>0 then add=add+row.delta else remove=remove-row.delta end end
  lines[#lines+1]='与本人当前配点相比：增加 '..add..' 点，减少 '..remove..' 点。'
  if remove>0 then lines[#lines+1]='若以后应用，需先走原重置流程；本次导入不洗点。'end
 else lines[#lines+1]=err or'当前角色无法读取；仅作本地收藏'end
 if S.Class()~=b.class then lines[#lines+1]='当前角色职业不同：可收藏查看，不能应用。'end
 for _,field in ipairs({{'skills','关键技能'},{'rotation','联动顺序'},{'notes','备注'}})do if meta[field[1]]~=''then lines[#lines+1]='';lines[#lines+1]=field[2]..'：';lines[#lines+1]=meta[field[1]]end end
 if parsed.duplicateId then lines[#lines+1]='';lines[#lines+1]='已找到完全相同的本地收藏版本；确认后打开该版本，不会重复新增。'end
 V.summary:SetText(table.concat(lines,'\n'));V.content:SetHeight(math.max(442,V.summary:GetStringHeight()+24));if V.previewScroll.UpdateScrollChildRect then V.previewScroll:UpdateScrollChildRect()end
 V.confirm:SetText(parsed.duplicateId and'打开已有收藏版本'or parsed.valid and'确认收藏为新方案'or'确认收藏为待完善草稿');enable(V.confirm,true)
 message(parsed.duplicateId and'此内容已在本地收藏中。'or parsed.valid and'检查完成；确认后只新增本地收藏。'or'规则未满足；可明确收藏为草稿，不能直接应用。')
 return true
end
function X.ExportSelected()
 local e=S.editor;local db=S.DB();local item=e and e.id and db and db.builds[e.id];local rev=item and item.versions[e.version]
 if not e or e.dirty or e.readOnlyReason or not rev then return nil,'请先选择并保存一个可分享的收藏版本'end
 if rev.name~=e.name or S.Fingerprint(rev.build)~=S.Fingerprint(e.build)or S.ProfileKey(rev.profile)~=S.ProfileKey(e.profile)then return nil,'本地编辑尚未保存，请保存后再导出'end
 return X.Encode(rev.name,rev.build,rev.profile,e.version)
end
function X.ExportInput()
 local text,why=X.ExportSelected();if not text then message(why);return false end
 setText(text);X.CheckInput();message('已生成所选收藏版本。点击“选中全部”，再按 Ctrl+C 复制。');return true
end
function X.ConfirmInput()
 local parsed=V.preview;local serial=V.serial
 if not parsed or parsed.serial~=serial or parsed.raw~=(V.edit:GetText()or''):gsub('\r\n','\n'):gsub('^%s+',''):gsub('%s+$','')then message('文本已改变，请重新检查');enable(V.confirm,false);return end
 S.Change(function()
  if not V.frame:IsShown()or V.serial~=serial or V.preview~=parsed then message('导入预览已过期，请重新检查');return end
  local id,version,duplicate=X.Import(parsed);if not id then message(version);return end
  S.class=parsed.build.class;local state=S.FilterState();state.query='';state.scene='全部';state.role='全部'
  S.Load(id,version);S.frame:Show();Windows.Focus(S.frame)
  message(duplicate and'已打开已有收藏版本；未新增记录，也未应用到角色。'or'已建立新的本地收藏；尚未应用到角色。')
  invalidate()
 end)
end
local function create()
 if V.frame then return end
 local f=C.Window('RebornTalentShareFrame','天赋收藏 · 导入 / 导出 · TG13A');V.frame=f;Windows.Register('collectionShare',f)
 V.check=C.Button(f,20,-42,140,'检查导入',X.CheckInput)
 V.export=C.Button(f,174,-42,205,'导出所选收藏版本',X.ExportInput)
 V.select=C.Button(f,393,-42,205,'选中全部（Ctrl+C）',function()V.edit:SetFocus();V.edit:HighlightText()end)
 V.clear=C.Button(f,612,-42,140,'清空文本',function()setText('');message('粘贴要导入的分享文本。')end)
 V.back=C.Button(f,1060,-42,210,'返回收藏',function()if S.frame then S.frame:Show();Windows.Focus(S.frame)end end)
 C.Text(f,20,-82,750,'分享文本 · 点击后 Ctrl+V 粘贴；导出后选中全部 Ctrl+C 复制','GameFontNormal')
 C.Text(f,810,-82,460,'导入预览与配点校验','GameFontNormal')
 V.scroll=CreateFrame('ScrollFrame','RebornTalentShareTextScroll',f,'UIPanelScrollFrameTemplate');V.scroll:SetPoint('TOPLEFT',20,-108);V.scroll:SetSize(750,470)
 V.edit=CreateFrame('EditBox',nil,V.scroll);V.edit:SetSize(728,442);V.edit:SetAutoFocus(false);V.edit:SetMultiLine(true);V.edit:SetFontObject('GameFontHighlightSmall');V.edit:SetMaxLetters(X.limit)
 V.edit:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=10,insets={left=3,right=3,top=3,bottom=3}});V.edit:SetBackdropColor(.02,.035,.045,.97);V.edit:SetTextInsets(10,10,8,8);V.scroll:SetScrollChild(V.edit)
 V.edit:SetScript('OnTextChanged',function()if not V.setting then invalidate();height();message('文本已改变，请先检查导入。')end end)
 V.edit:SetScript('OnEscapePressed',function(self)self:ClearFocus()end)
 V.edit:SetScript('OnCursorChanged',function(_,x,y,w,h)
  if V.setting then return end
  local offset=V.scroll.GetVerticalScroll and V.scroll:GetVerticalScroll()or 0;local top=math.max(0,-(y or 0))
  if top<offset then offset=top elseif top+(h or 16)>offset+470 then offset=top+(h or 16)-470 end
  V.scroll:SetVerticalScroll(math.max(0,math.min(math.max(0,V.edit:GetHeight()-470),offset)))
 end)
 V.previewScroll=CreateFrame('ScrollFrame','RebornTalentSharePreviewScroll',f,'UIPanelScrollFrameTemplate');V.previewScroll:SetPoint('TOPLEFT',810,-108);V.previewScroll:SetSize(460,470)
 V.content=CreateFrame('Frame',nil,V.previewScroll);V.content:SetSize(435,442);V.previewScroll:SetScrollChild(V.content)
 V.previewScroll:SetBackdrop({bgFile='Interface\\Buttons\\WHITE8X8',edgeFile='Interface\\Tooltips\\UI-Tooltip-Border',edgeSize=10,insets={left=3,right=3,top=3,bottom=3}});V.previewScroll:SetBackdropColor(.02,.035,.045,.95)
 V.summary=C.Text(V.content,6,-6,418,'');V.summary:SetFont(STANDARD_TEXT_FONT or'Fonts\\FRIZQT__.TTF',13,'OUTLINE');V.summary:SetSpacing(3)
 for _,scroll in ipairs({V.scroll,V.previewScroll})do
  scroll:EnableMouseWheel(true);scroll:SetScript('OnMouseWheel',function(_,delta)
   if IsControlKeyDown()then return end
   local child=scroll==V.scroll and V.edit or V.content;local offset=scroll.GetVerticalScroll and scroll:GetVerticalScroll()or 0
   scroll:SetVerticalScroll(math.max(0,math.min(math.max(0,child:GetHeight()-470),offset-delta*42)))
  end)
 end
 V.confirm=C.Button(f,810,-598,460,'确认收藏为新方案',X.ConfirmInput);enable(V.confirm,false)
 V.message=C.Text(f,22,-598,735,'粘贴分享文本后，先检查再确认收藏。')
 f.note:SetText('导出只包含所选版本的名称、配点和方案资料；不自动采集账号、GUID、本地路径或应用记录。')
 f:HookScript('OnHide',function()invalidate();V.edit:ClearFocus()end)
 UISpecialFrames[#UISpecialFrames+1]='RebornTalentShareFrame';setText('')
end
function S.OpenShare()
 create();C.Fit(V.frame);V.frame:Show();Windows.Focus(V.frame)
end
