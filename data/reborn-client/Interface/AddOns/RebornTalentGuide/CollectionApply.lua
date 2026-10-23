-- TG5A. A confirmation is permission to submit, not proof the server accepted it.
local S=RebornTalentCollections;local G=RebornTalentGuide;local P=RebornTalentGuidePaladin
local function visibleOwner(owner)
 local T=G.TalentCenter
 if owner==S.frame and T and T.tab=='favorites'and T.frame and T.frame:IsShown()then return T.frame end
 return owner
end
function S.Compare(b)
 local shape,invalid=S.Shape(b);if not shape then return {},invalid end
 local current,why=S.Capture(b.class);if not current then return {},why end
 local rows={};local nodes=S.Nodes(b.class)
 for id,n in pairs(nodes)do local a,z=current.ranks[id]or 0,b.ranks[id]or 0;if a~=z then rows[#rows+1]={id=id,name=n.name,current=a,target=z,delta=z-a}end end
 table.sort(rows,function(a,b)return a.id<b.id end);return rows,nil,current
end
function S.CanApply(b,owner)
 owner=visibleOwner(owner)
 local valid,why=S.Validate(b);if not valid then return nil,why end
 if S.Class()~=b.class or G.fromBot then return nil,'仅能应用到自己同职业的当前专精'end
 if InCombatLockdown()or UnitIsDeadOrGhost('player')then return nil,'请脱战并复活后应用'end
 if owner and not owner:IsShown()then return nil,'请先打开收藏窗口'end
 if b.level>UnitLevel('player')then return nil,'角色等级低于此方案等级'end
 if P.job or RebornTalentGuideWarriorCollection.job or G.job or S.waiting then return nil,'已有应用任务，等待结束或先停止'end
 local diff,err,current=S.Compare(b);if not current then return nil,err end
 for _,row in ipairs(diff)do if row.delta<0 then return nil,'需要移除已保存点数：'..row.name..'；请自行按原流程重置，不会代付费或洗点'end end
 local ctx={epoch=G.Lifecycle and G.Lifecycle.epoch or 0,guid=UnitGUID('player'),before=S.Fingerprint(current),current=current,diff=diff}
 if S.NativeData(b.class)then
  local job,msg=S.NativeEngine(b.class).Check(S.NativePlan(b),owner);if not job then return nil,msg end
  ctx.group=job.group;ctx.plan=S.NativePlan(b);ctx.signature=ctx.guid..':'..ctx.group..':'..ctx.before..':'..ctx.epoch;return ctx
 end
 local M=RebornWD8
 if not M.loaded or not M.modern or not M.layoutReady or M.pending or type(M.Save)~='function'then return nil,'巫医方案尚未完整同步，或缺少原保存接口'end
 if M.slot~=M.active or M.slot>=M.unlocked or M.specs[M.active+1]~=b.spec or M.draftSpec~=b.spec then return nil,'请先在原巫医面板激活并查看同专精的已解锁方案'end
 if M.dirty or M.aeDirty then return nil,'实际巫医面板有未保存草稿，请先保存或撤回'end
 local v=RebornEquipmentVault and RebornEquipmentVault.server;if v and v.IsBusy and v.IsBusy()then return nil,'衣柜正在处理装备，请稍后再应用'end
 local mask,msg=S.Mask(b);if not mask then return nil,msg end
 local ok,reason=G.WD.Validate(mask,b.spec,M.level,M.aeBudget,M.teBudget);if not ok then return nil,reason end
 ctx.slot=M.active;ctx.revision=M.revision;ctx.mask=mask;ctx.signature=ctx.guid..':'..ctx.slot..':'..ctx.revision..':'..ctx.before..':'..ctx.epoch
 return ctx
end
local function mark(r,state,message)
 r.state=state;r.message=message;r.updated=S.Now();S.status=message
 if S.waiting==r then S.waiting=nil end
 if S.Refresh then S.Refresh()end
end
function S.Record(id,version,b,ctx)
 local d=S.DB();d.receiptSerial=(tonumber(d.receiptSerial)or 0)+1
 local r={request=d.receiptSerial,id=id,version=version,guid=ctx.guid,group=ctx.group,slot=ctx.slot,revision=ctx.revision,build=S.Copy(b),fingerprint=S.Fingerprint(b),started=S.Now(),state='submitted',message='请求已提交，尚未确认'}
 d.receipts[#d.receipts+1]=r;if #d.receipts>200 then table.remove(d.receipts,1)end;return r
end
function S.Verify(r)
 if type(r)~='table'or not S.Shape(r.build)then return false,'应用记录格式或节点版本不匹配'end
 if r.build.class=='WITCHDOCTOR'and type(r.revision)~='number'then return false,'应用记录缺少服务器修订号'end
 if UnitGUID('player')~=r.guid then return nil,'当前角色不同'end
 if r.build.layout~=S.Layout(r.build.class)then return false,'节点版本改变，不能核对旧请求'end
 if S.NativeData(r.build.class)then
  if GetActiveTalentGroup(false,false)~=r.group then return false,'当前专精已经改变'end
  local current,why=S.Capture(r.build.class);if not current then return nil,why end
  for id in pairs(S.Nodes(r.build.class))do if(current.ranks[id]or 0)~=(r.build.ranks[id]or 0)then return false,'当前天赋未达到收藏版本'end end
  return true
 end
 local M=RebornWD8
 if not M or not M.loaded or not M.layoutReady or M.pending then return nil,'等待巫医完整服务器快照'end
 if M.active~=r.slot or M.specs[r.slot+1]~=r.build.spec then return false,'激活方案或专精已经改变'end
 local mask=S.Mask(r.build)
 return M.MaskEqual(M.aeMasks[r.slot+1],mask)and M.revision>r.revision,'服务器已保存点数尚不一致'
end
function S.Submit(id,version,b,ctx,owner)
 owner=visibleOwner(owner)
 local now,why=S.CanApply(b,owner);if not now then return false,why end
 if now.signature~=ctx.signature then return false,'当前方案已改变，请重新比较并确认'end
 local r=S.Record(id,version,b,now)
 if S.NativeData(b.class)then
  local ok,msg=S.NativeEngine(b.class).StartPlan(now.plan,owner,function(success,reason)
   local matches=S.Verify(r)
   mark(r,success and matches and'verified_reply'or'stopped',success and matches and'应用完成：服务器当前点数与收藏版本一致'or(reason or'应用停止；已投入点数保留'))
  end)
  if not ok then mark(r,'failed',msg);return false,msg end
  return true,r
 end
 local M=RebornWD8
 if #now.diff==0 then mark(r,'verified_snapshot','当前服务器快照已与收藏一致，无需保存');return true,r end
 M.draftAE=now.mask;M.aeDirty=true;M.dirty=true
 if M.changed then M.changed()end;if M.homeChanged then M.homeChanged()end
 S.waiting=r
 local ok,err=pcall(M.Save)
 if not ok or not M.pending or M.operation~='save'then mark(r,'failed','原保存接口没有提交成功；草稿保留，请到原面板核对');return false,r.message end
 S.status='已提交巫医原保存请求，等待服务器修订号和点数确认';return true,r
end
function S.RequestApply()
 local e=S.editor
 if not e or e.readOnlyReason or not e.id or e.dirty then S.status=e and e.readOnlyReason and('只读版本不能应用：'..e.readOnlyReason)or'请先保存为收藏版本再应用';if S.Refresh then S.Refresh()end;return end
 local d=S.DB();local item=d and d.builds[e.id];local rev=item and item.versions[e.version]
 if not rev or S.Fingerprint(rev.build)~=S.Fingerprint(e.build)then return end
 local b=S.Copy(rev.build);local ctx,why=S.CanApply(b,S.frame);if not ctx then S.status=why;S.Refresh();return end
 local id,version=e.id,e.version;local title=rev.name
 StaticPopupDialogs.REBORN_COLLECTION_APPLY={text='应用「'..title..'」版本 '..version..' 到自己的当前方案？\n已列出 '..#ctx.diff..' 个差异节点。'..(b.class=='WITCHDOCTOR'and'将通过原巫医保存接口提交，服务器确认后才算完成。'or'将通过原生接口逐点补齐；停止不撤销已加点。')..'\n不会自动重置、收费、切专精或安装雕文。',button1='确认应用',button2=CANCEL,timeout=0,whileDead=false,hideOnEscape=true,OnAccept=function()
  local current=S.editor;local db=S.DB();local entry=db and db.builds[id];local target=entry and entry.versions[version]
  if not current or not target or current.id~=id or current.version~=version or current.dirty or S.Fingerprint(current.build)~=S.Fingerprint(b)then S.status='收藏选择已改变，请重新确认';S.Refresh();return end
  local ok,result=S.Submit(id,version,b,ctx,S.frame);if not ok then S.status=result end;S.Refresh()
 end};
 local center=G.TalentCenter;local locale=G.CenterLocale
 if center and center.frame and center.frame:IsShown()and locale and locale.English()then
  local dialog=StaticPopupDialogs.REBORN_COLLECTION_APPLY
  dialog.text='Apply "'..title..'" version '..version..' to your current build?\n'..#ctx.diff..' differing nodes. '..(b.class=='WITCHDOCTOR'and'Uses the original Witch Doctor save interface; completion requires server confirmation.'or'Adds points through the native interface. Stopping does not undo spent points.')..'\nNo automatic reset, charge, spec switch or glyph installation.'
  dialog.button1='Confirm Apply';dialog.button2='Cancel'
 end
 StaticPopup_Show('REBORN_COLLECTION_APPLY')
end
function S.CheckReceipts()
 local d=S.DB();if not d then return end
 for _,r in ipairs(d.receipts)do
  if type(r)=='table'and type(r.build)=='table'and type(r.started)=='number'and r.state=='submitted'and r.guid==UnitGUID('player')then
   if S.NativeData(r.build.class)and S.NativeEngine(r.build.class).job then return end
   local same,why=S.Verify(r)
   if same then
    local reply=S.waiting==r and not r.rechecking and RebornWD8 and RebornWD8.revision==r.revision+1
    mark(r,reply and'verified_reply'or'verified_snapshot',reply and'巫医应用完成：服务器修订号与全部保存点数已确认'or'当前服务器快照已与收藏版本一致')
   elseif S.Now()-r.started>12 then mark(r,'unknown','未确认应用完成，请刷新原面板核对；不会自动重发')
   elseif same==false and r.build.class=='WITCHDOCTOR'and RebornWD8 and RebornWD8.loaded and not RebornWD8.pending then mark(r,'failed','未确认收藏应用：'..(why or'保存快照不一致')..'；请核对原面板')
   elseif same==false and S.NativeData(r.build.class)then mark(r,'unknown','先前应用已中止或重登，请核对当前点数后手动重试')end
  end
 end
end
function S.RecheckLast()
 local d=S.DB();local e=S.editor;if not d or not e or not e.id then return end
 for i=#d.receipts,1,-1 do local r=d.receipts[i]
  if type(r)=='table'and r.id==e.id and r.version==e.version and r.guid==UnitGUID('player')then
   local same,why=S.Verify(r)
   if same then mark(r,'verified_snapshot','重新核对完成：当前服务器快照与收藏一致')
   elseif same==nil and r.build.class=='WITCHDOCTOR'then
    local M=RebornWD8;r.started=S.Now();r.state='submitted';r.rechecking=true;S.waiting=r
    if M and not M.pending and M.Query then M.Query()end
    S.SetStatus('正在刷新原巫医服务器快照；不会重新提交保存')
   else S.SetStatus(why or'当前点数与收藏不一致；没有重发应用')end
   return
  end
 end
 S.SetStatus('此收藏版本没有本角色的应用记录')
end
local f=CreateFrame('Frame');local elapsed=0
f:SetScript('OnUpdate',function(_,dt)elapsed=elapsed+dt;if elapsed<.3 then return end;elapsed=0;S.CheckReceipts();if S.frame and S.frame:IsShown()and S.UpdateStatus then S.UpdateStatus()end end)
