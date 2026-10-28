-- WD68A: six Class nodes, Voodoo identity and the first TE node.
local M=RebornWDBotTalents
local L=RebornWDNodeLayout
local index,maximum=L.index,L.maximum
M.aeMasks={0,0,0};M.draftAE=0
local function Changed() if M.changed then M.changed() end;if M.homeChanged then M.homeChanged() end end
local function Message(s) M.message=s;Changed() end
function M.IsAENode(id) return M.modern and index[id]~=nil end
local function Shift(i) return L.nodes[i].offset end
function M.AERank(id,mask)
 local i=index[id];if not i then return 0 end
 mask=mask or M.draftAE or 0
 return M.MaskRank(mask,Shift(i),L.nodes[i].width)
end
function M.AESpent(mask)
 local total=0;for id,i in pairs(index) do if i==163 or i==144 or i==145 or i==146 or i==141 or i==142 or i==143 or i==133 or i<6 or (i>=39 and i<=41) or (i>=46 and i<=48) or (i>=58 and i<=60) or (i>=63 and i<=73) or (i>=116 and i<=117) or (i>=108 and i<=110) then total=total+M.AERank(id,mask) end end;return total
end
function M.TEFoundation(mask) return M.AERank(31154,mask)+M.AERank(31344,mask)+M.AERank(31340,mask)+M.AERank(7157,mask)+M.AERank(6058,mask)+M.AERank(29928,mask)+M.AERank(30973,mask)+M.AERank(31345,mask) end
function M.BrewingFoundation(mask) return M.AERank(7128,mask)+ M.AERank(7131,mask)+M.AERank(30884,mask)+M.AERank(29736,mask)+M.AERank(5055,mask)+M.AERank(7129,mask) end
function M.BrewingSpent(mask) return M.AERank(7133,mask)+M.AERank(29740,mask)+M.AERank(6026,mask)+M.AERank(30333,mask)+M.AERank(6027,mask)+M.AERank(6015,mask)+M.AERank(29310,mask)+M.AERank(29754,mask)+M.AERank(6016,mask)+M.AERank(6009,mask)+ M.AERank(30823,mask)+M.AERank(6022,mask)+M.AERank(6013,mask)+ M.AERank(6021,mask)+M.AERank(6014,mask)+ M.AERank(6645,mask)+M.AERank(4112,mask)+M.AERank(7130,mask)+ M.AERank(35051,mask)+M.AERank(30888,mask)+M.AERank(29738,mask)+ M.AERank(35065,mask)+M.AERank(35064,mask)+M.AERank(35068,mask)+ M.AERank(7128,mask)+ M.AERank(6020,mask)+M.AERank(29737,mask)+ M.AERank(6498,mask)+M.AERank(29303,mask)+ M.AERank(7131,mask)+M.AERank(30884,mask)+M.AERank(29736,mask)+M.AERank(5055,mask)+M.AERank(7129,mask)+M.AERank(7948,mask)+M.AERank(31137,mask)+M.AERank(7132,mask)+M.AERank(29753,mask) end
function M.TESpent(mask) return M.AERank(29978,mask)+ M.AERank(5235,mask)+M.AERank(6388,mask)+ M.AERank(7781,mask)+M.AERank(6076,mask)+ M.AERank(7103,mask)+M.AERank(4423,mask)+M.AERank(29977,mask)+ M.AERank(7102,mask)+M.AERank(5303,mask)+M.AERank(4177,mask)+M.AERank(11177,mask)+ M.AERank(4572,mask)+M.AERank(6035,mask)+M.AERank(7355,mask)+ M.AERank(6010,mask)+M.AERank(11164,mask)+M.AERank(29981,mask)+ M.AERank(7031,mask)+M.AERank(11330,mask)+M.AERank(29930,mask)+ M.AERank(6011,mask)+M.AERank(6073,mask)+M.AERank(29729,mask)+ M.AERank(30892,mask)+M.AERank(6983,mask)+M.AERank(5164,mask)+ M.AERank(5253,mask)+M.AERank(6853,mask)+ M.AERank(6069,mask)+ M.AERank(8574,mask)+M.AERank(30895,mask)+M.AERank(6063,mask)+ M.AERank(7086,mask)+M.AERank(6072,mask)+M.AERank(6074,mask)+ M.AERank(1969,mask)+M.AERank(7779,mask)+ M.BrewingSpent(mask)+ M.AERank(31154,mask)+M.AERank(31344,mask)+M.AERank(31340,mask)+M.AERank(7157,mask)+M.AERank(6058,mask)+M.AERank(29928,mask)+M.AERank(30973,mask)+M.AERank(31341,mask)+M.AERank(6045,mask)+M.AERank(31347,mask)+M.AERank(31348,mask)+M.AERank(6644,mask)+M.AERank(6046,mask)+M.AERank(6062,mask)+M.AERank(30889,mask)+M.AERank(31343,mask)+M.AERank(6053,mask)+M.AERank(31350,mask)+M.AERank(5333,mask)+M.AERank(6059,mask)+M.AERank(5332,mask)+M.AERank(31345,mask)+M.AERank(6007,mask)+M.AERank(29121,mask)+M.AERank(31346,mask)+M.AERank(7100,mask)+M.AERank(29768,mask)+M.AERank(6057,mask)+M.AERank(30596,mask)+M.AERank(31349,mask)+M.AERank(29929,mask)+M.AERank(6055,mask) end
function M.AEValid(mask)
 if M.MaskRank(mask,67,1)>0 or not M.LayoutValid(mask) or (M.AERank(35064,mask)>2 or M.AERank(6498,mask)>2 or M.AERank(9347,mask)>2 or M.AERank(6047,mask)>2 or M.AERank(6062,mask)>2 or M.AERank(31345,mask)>2 or M.AERank(6007,mask)>2 or M.AERank(7088,mask)>2 or M.AERank(7131,mask)>2 or M.AERank(30884,mask)>2 or M.AERank(29736,mask)>2) then return false,"加点数据无效，请刷新方案" end
 if M.TESpent(mask)>(M.teBudget or 0) then return false,"专精点数TE不足；AE不能代替TE" end
 local function rank(id) return M.AERank(id,mask) end
 if rank(29978)>0 and (M.level<30 or M.specs[M.slot+1]~=2 or rank(1969)+rank(7779)+rank(7086)+rank(6072)+rank(6074)+rank(8574)+rank(30895)+rank(6063)+rank(6069)+rank(5253)+rank(6853)+rank(30892)+rank(6983)+rank(5164)+rank(6011)+rank(6073)+rank(29729)+rank(7031)+rank(11330)+rank(29930)+rank(6010)+rank(11164)+rank(29981)<8)then return false,"狂暴需要30级暗影方案及8点此前暗影TE"end
 if rank(5113)>0 and (M.level<58 or rank(29744)+rank(6054)+rank(6047)+rank(7092)+rank(29309)+rank(29301)+rank(7088)+rank(30147)+rank(4132)+rank(7033)+rank(6051)+rank(6048)+rank(30891)+rank(6030)+rank(6381)+rank(12048)+rank(11323)+rank(31118)+rank(12264)+rank(6042)+rank(9347)+rank(29306)+rank(6031)+rank(6525)+rank(12525)+rank(12749)+rank(29749)+rank(29743)+rank(29747)+rank(7154)+rank(11154)+rank(6044)<24)then return false,"诅咒雕像需要58级及24点此前通用AE"end
 if rank(5235)+rank(6388)>0 and (M.specs[M.slot+1]~=2 or rank(1969)+rank(7779)+rank(7086)+rank(6072)+rank(6074)+rank(8574)+rank(30895)+rank(6063)+rank(6069)+rank(5253)+rank(6853)+rank(30892)+rank(6983)+rank(5164)+rank(6011)+rank(6073)+rank(29729)+rank(7031)+rank(11330)+rank(29930)+rank(6010)+rank(11164)+rank(29981)+rank(4572)+rank(6035)+rank(7355)+rank(7102)+rank(5303)+rank(4177)+rank(11177)+rank(7103)+rank(4423)+rank(29977)+rank(7781)+rank(6076)+rank(29978)<23)then return false,"需要暗影方案及23点此前暗影TE"end
 if rank(5235)>0 and (M.level<20 or rank(6035)>0 or rank(4572)+rank(29978)==0)then return false,"毒蛇需要相连前置，与驭蛇者互斥"end
 if rank(6388)>0 and (M.level<31 or rank(4572)+rank(11330)+rank(29930)==0)then return false,"愚者把戏需要31级及相连前置"end
 if rank(12145)+rank(7781)+rank(6076)>0 and M.specs[M.slot+1]~=2 then return false,"需要暗影方案"end
 if rank(12145)>0 and (M.level<50 or rank(4423)==0)then return false,"需要50级及森金学徒"end
 if rank(7781)+rank(6076)>0 and (M.level<20 or rank(1969)+rank(7779)+rank(7086)+rank(6072)+rank(6074)+rank(8574)+rank(30895)+rank(6063)+rank(6069)+rank(5253)+rank(6853)+rank(30892)+rank(6983)+rank(5164)+rank(6011)+rank(6073)+rank(29729)+rank(7031)+rank(11330)+rank(29930)+rank(6010)+rank(11164)+rank(29981)+rank(4572)+rank(6035)+rank(7355)+rank(7102)+rank(5303)+rank(4177)+rank(11177)+rank(7103)+rank(4423)+rank(29977)+rank(29978)<23)then return false,"需要23点此前暗影TE"end
 if rank(7781)>0 and rank(6035)+rank(29981)+rank(5235)==0 then return false,"需要驭蛇者或巨蛇诡计"end
 if rank(6076)>0 and rank(6035)+rank(5235)+rank(6388)==0 then return false,"需要驭蛇者"end
 if rank(7103)+rank(4423)+rank(29977)>0 and M.specs[M.slot+1]~=2 then return false,"需要暗影方案"end
 if rank(7103)>0 and (M.level<30 or rank(4506)==0)then return false,"需要30级及洛阿灵魂前置"end
 if rank(4423)>0 and (M.level<40 or rank(7103)==0)then return false,"需要40级及幽影战刃"end
 if rank(29977)>0 and (M.level<31 or rank(1969)+rank(7779)+rank(7086)+rank(6072)+rank(6074)+rank(8574)+rank(30895)+rank(6063)+rank(6069)+rank(5253)+rank(6853)+rank(30892)+rank(6983)+rank(5164)+rank(6011)+rank(6073)+rank(29729)+rank(7031)+rank(11330)+rank(29930)+rank(6010)+rank(11164)+rank(29981)+rank(4572)+rank(6035)+rank(7355)+rank(7102)+rank(5303)+rank(4177)+rank(11177)<8 or rank(4177)+rank(5303)+rank(11177)==0)then return false,"需要31级、8点此前暗影TE及相连前置"end
 if rank(7102)+rank(5303)+rank(4177)+rank(11177)>0 and (M.level<27 or M.specs[M.slot+1]~=2 or rank(1969)+rank(7779)+rank(7086)+rank(6072)+rank(6074)+rank(8574)+rank(30895)+rank(6063)+rank(6069)+rank(5253)+rank(6853)+rank(30892)+rank(6983)+rank(5164)+rank(6011)+rank(6073)+rank(29729)+rank(7031)+rank(11330)+rank(29930)+rank(6010)+rank(11164)+rank(29981)+rank(4572)+rank(6035)+rank(7355)<8)then return false,"需要27级暗影方案及8点此前暗影TE"end
 if rank(7102)>0 and rank(6072)+rank(6074)==0 then return false,"需要相连前置"end
 if rank(5303)+rank(4177)+rank(11177)>0 and rank(7102)==0 then return false,"需要暗影追猎"end
 if rank(4177)>0 and rank(11177)>0 then return false,"死亡妖术与灵魂狩猎二选一"end
 if rank(4572)+rank(6035)+rank(7355)>0 and (M.level<20 or M.specs[M.slot+1]~=2)then return false,"需要20级暗影方案"end
 if rank(4572)>0 and (rank(1969)+rank(7779)+rank(7086)+rank(6072)+rank(6074)+rank(8574)+rank(30895)+rank(6063)+rank(6069)+rank(5253)+rank(6853)+rank(30892)+rank(6983)+rank(5164)+rank(6011)+rank(6073)+rank(29729)+rank(7031)+rank(11330)+rank(29930)+rank(6010)+rank(11164)+rank(29981)<8 or rank(5164)+rank(11164)==0)then return false,"需要相连前置及8点此前暗影TE"end
 if rank(6035)+rank(7355)>0 and rank(1969)+rank(7779)+rank(7086)+rank(6072)+rank(6074)+rank(8574)+rank(30895)+rank(6063)+rank(6069)+rank(5253)+rank(6853)+rank(30892)+rank(6983)+rank(5164)+rank(6011)+rank(6073)+rank(29729)+rank(7031)+rank(11330)+rank(29930)+rank(6010)+rank(11164)+rank(29981)+rank(4572)+rank(29978)<23 then return false,"需要23点前层暗影TE；本层不计入"end
 if rank(6035)>0 and rank(4572)+rank(29978)==0 then return false,"需要金布尔之眼或相连前置"end
 if rank(7355)>0 and rank(6035)==0 then return false,"需要驭蛇者"end
 if rank(6044)>0 and (M.level<10 or rank(6030)+rank(7088)==0)then return false,"需要相连通用前置"end
 if rank(6050)+rank(6049)>0 and (M.level<56 or rank(29744)+rank(6054)+rank(6047)+rank(7092)+rank(29309)+rank(29301)+rank(7088)+rank(30147)+rank(4132)+rank(7033)+rank(6051)+rank(6048)+rank(30891)+rank(6030)+rank(6381)+rank(12048)+rank(11323)+rank(31118)+rank(12264)+rank(6042)+rank(9347)+rank(29306)+rank(6031)+rank(6525)+rank(12525)+rank(12749)+rank(29749)+rank(29743)+rank(29747)+rank(7154)+rank(11154)+rank(6044)<24)then return false,"需要56级及24点此前通用AE，本层不计入"end
 if rank(6050)>0 and rank(4132)+rank(11323)+rank(29743)==0 then return false,"需要加速或相连诅咒前置"end
 if rank(6049)>0 and rank(6050)==0 then return false,"需要独臂华尔兹"end
 if (rank(29747)+rank(7154)+rank(11154)>0)and M.level<10 then return false,"需要10级"end
 if rank(7154)>0 and rank(11154)>0 then return false,"森金的迅捷与智慧二选一"end
 if rank(7154)+rank(11154)>0 and rank(7088)==0 then return false,"需要相连通用前置"end
 if rank(6010)>0 and (M.level<15 or M.specs[M.slot+1]~=2 or rank(8574)==0)then return false,"需要15级、暗影方案和灵魂战刃"end
 if rank(11164)>0 and (M.level<20 or M.specs[M.slot+1]~=2 or rank(6983)==0 or rank(1969)+rank(7779)+rank(7086)+rank(6072)+rank(6074)+rank(8574)+rank(30895)+rank(6063)+rank(6069)+rank(5253)+rank(6853)+rank(30892)+rank(6983)+rank(5164)+rank(6011)+rank(6073)+rank(29729)+rank(7031)+rank(11330)+rank(29930)<8)then return false,"需要巫毒之火和8点此前暗影TE"end
 if rank(29981)>0 and (M.level<20 or M.specs[M.slot+1]~=2 or rank(6011)==0 or rank(1969)+rank(7779)+rank(7086)+rank(6072)+rank(6074)+rank(8574)+rank(30895)+rank(6063)+rank(6069)+rank(5253)+rank(6853)+rank(30892)+rank(6983)+rank(5164)+rank(6011)+rank(6073)+rank(29729)+rank(7031)+rank(11330)+rank(29930)+rank(6010)+rank(11164)<23)then return false,"需要暗影附魔和23点此前暗影TE"end
 if (rank(7031)+rank(11330)+rank(29930)>0) and (M.level<20 or M.specs[M.slot+1]~=2 or rank(1969)+rank(7779)+rank(7086)+rank(6072)+rank(6074)+rank(8574)+rank(30895)+rank(6063)+rank(6069)+rank(5253)+rank(6853)+rank(30892)+rank(6983)+rank(5164)+rank(6011)+rank(6073)+rank(29729)<8)then return false,"需要20级、暗影方案和8点此前暗影TE"end
 if rank(7031)>0 and rank(6069)+rank(6983)==0 then return false,"需要残余能量或巫毒之火"end
 if rank(11330)+rank(29930)>0 and rank(6073)+rank(7031)==0 then return false,"需要黑暗洛阿咒语或暗矛传统派"end
 if rank(11330)>0 and rank(29930)>0 then return false,"邦桑迪之刃与丹巴拉的致命二选一"end
 if (rank(6011)>0 or rank(6073)>0 or rank(29729)>0) and (M.level<20 or M.specs[M.slot+1]~=2 or rank(1969)+rank(7779)+rank(7086)+rank(6072)+rank(6074)+rank(8574)+rank(30895)+rank(6063)+rank(6069)+rank(5253)+rank(6853)+rank(30892)+rank(6983)+rank(5164)<8)then return false,"需要20级、暗影方案和8点此前暗影TE"end
 if rank(6011)>0 and rank(29729)==0 then return false,"需要洛阿之力（团队）前置"end
 if rank(29729)>0 and rank(6983)==0 then return false,"需要巫毒之火前置"end
 if rank(6073)>0 and rank(5253)+rank(6069)+rank(6853)==0 then return false,"需要弑神者、残余能量或真灵魂中的一个前置"end
 if rank(29743)>0 and (M.level<26 or rank(29744)+rank(6054)+rank(6047)+rank(7092)+rank(29309)+rank(29301)+rank(7088)+rank(6030)+rank(31118)+rank(29747)+rank(7154)+rank(11154)+rank(6044)<9 or rank(12264)+rank(30891)==0 or rank(11323)>0)then return false,"需要26级、9基础AE和相连前置；与显性诅咒互斥"end
 if rank(30892)>0 and (M.level<20 or M.specs[M.slot+1]~=2 or rank(6072)==0 or rank(1969)+rank(7779)+rank(7086)+rank(6072)+rank(6074)+rank(8574)+rank(30895)+rank(6063)+rank(6069)+rank(5253)+rank(6853)<8)then return false,"需要20级、灵魂信徒和8点既有暗影TE"end
 if rank(6983)>0 and rank(30892)==0 then return false,"需要瑟拉图斯的召唤"end
 if rank(5164)>0 and rank(6983)==0 then return false,"需要巫毒之火"end
 if rank(5253)>0 and rank(6853)>0 then return false,"弑神者和真灵魂互斥" end
 if (rank(5253)>0 or rank(6853)>0) and (M.specs[M.slot+1]~=2 or M.level<20 or rank(6063)==0) then return false,"需要20级、暗影方案和沃金的祝福" end
 if rank(6069)>0 and (M.specs[M.slot+1]~=2 or M.level<20 or rank(6063)==0) then return false,"需要20级、暗影方案和沃金的祝福" end
 if (rank(8574)>0 or rank(30895)>0 or rank(6063)>0) and (M.specs[M.slot+1]~=2 or rank(4006)==0) then return false,"需要暗影猎手方案" end
 if rank(8574)>0 and (M.level<15 or rank(1969)==0) then return false,"需要15级和强化恶毒箭" end
 if rank(30895)>0 and (M.level<15 or rank(8574)==0) then return false,"需要灵魂战刃" end
 if rank(6063)>0 and (M.level<20 or rank(30895)==0 or rank(1969)+rank(7779)+rank(7086)+rank(6072)+rank(6074)+rank(8574)+rank(30895)<8) then return false,"需要20级、噬魂者及8点基础暗影TE" end
 if (rank(7086)>0 or rank(4506)>0 or rank(6072)>0 or rank(6074)>0) and (M.specs[M.slot+1]~=2 or rank(4006)==0) then return false,"需要暗影猎手方案" end
 if rank(7086)>0 and (M.level<15 or rank(7779)==0) then return false,"需要15级和洛阿之力" end
 if rank(4506)>0 and M.level<20 then return false,"需要20级" end
 if (rank(6072)>0 or rank(6074)>0) and (M.level<15 or rank(7086)==0) then return false,"需要灵魂蚀" end
 if (rank(1969)>0 or rank(7779)>0) and (M.level<11 or M.specs[M.slot+1]~=2 or rank(4006)==0) then return false,"需要11级和暗影猎手方案" end
 if rank(1969)>0 and rank(12086)==0 then return false,"需要恶毒箭" end
 if rank(7779)>0 and rank(4505)==0 then return false,"需要灵魂回收" end
 if rank(12749)>0 and rank(29749)>0 then return false,"腐朽诅咒与巨蛇意志只能选择一项" end
 if (rank(12749)>0 or rank(29749)>0) and (M.level<26 or rank(31118)==0 or rank(29744)+rank(7088)+rank(6030)+rank(6054)+rank(6047)+rank(7092)+rank(29309)+rank(29301)+rank(31118)<9) then return false,"需要26级、死亡药剂和9点基础通用AE" end
 if (rank(4006)>0 or rank(12086)>0 or rank(4505)>0) and (M.level<10 or M.specs[M.slot+1]~=2) then return false,"暗影起始能力需要10级和暗影方案" end
 if (rank(12086)>0 or rank(4505)>0) and rank(4006)==0 then return false,"需要暗影猎手；不需要付费幻影" end
 if (rank(30203)>0 or rank(6052)>0 or rank(29757)>0) and (M.level<56 or M.AESpent(mask)-rank(30203)-rank(6052)-rank(29757)-rank(6050)-rank(6049)<24) then return false,"需要56级和24点既有通用AE（本层不计入）" end
 if rank(6052)>0 and (M.level<58 or rank(30203)==0) then return false,"洛阿共鸣需要58级和黑暗帷幕" end
 if (rank(30333)>0 or rank(6027)>0) and (M.level<57 or M.specs[M.slot+1]~=1 or rank(4005)==0 or M.BrewingSpent(mask)-rank(7133)-rank(29740)-rank(30333)-rank(6027)<23) then return false,"需要57级、大锅及23点既有酿造TE" end
 if rank(30333)>0 and rank(6014)==0 and rank(6020)==0 and rank(29737)==0 then return false,"需要相连酿造前置" end
 if rank(6027)>0 and rank(30333)==0 then return false,"需要巫毒大锅" end
 if (rank(6015)>0 or rank(29310)>0 or rank(29754)>0) and (M.level<10 or M.specs[M.slot+1]~=1 or rank(4005)==0 or M.BrewingFoundation(mask)<8) then return false,"需要酿造方案、大锅和8基础TE" end
 if rank(6015)>0 and (M.level<16 or rank(29738)==0) then return false,"魔精：鱼骨需要16级和配料：蛙骨；鱼油16级自动学习，不需要灵魂之触" end
 if rank(29310)>0 and rank(6009)==0 and rank(7132)==0 and rank(29753)==0 then return false,"需要相连酿造前置" end
 if rank(29754)>0 and (rank(29310)==0 or M.BrewingSpent(mask)-rank(7133)-rank(29740)-rank(29754)<23) then return false,"需要野兽之血及23点既有酿造TE" end
 if rank(7133)>0 and (M.level<24 or M.specs[M.slot+1]~=1 or rank(29754)==0) then return false,"需要24级、酿造方案和水晶之水" end
 if rank(29740)>0 and (M.level<59 or M.specs[M.slot+1]~=1 or rank(6026)==0) then return false,"需要59级、酿造方案和调制大师" end
 if rank(6026)>0 and (M.level<57 or M.specs[M.slot+1]~=1 or rank(4005)==0 or rank(12645)==0 or rank(6014)==0 or M.BrewingSpent(mask)-rank(7133)-rank(29740)-rank(6026)-rank(30333)-rank(6027)-rank(29754)<23) then return false,"需要57级、大锅、丛林蘑菇、森金之仪和23点前层酿造TE" end
 if rank(13133)>0 and (M.level<50 or rank(4733)==0 or M.specs[M.slot+1]~=1) then return false,"需要50级、魔精波动及酿造方案" end
 if rank(4733)>0 and (M.level<40 or rank(4715)==0 or M.specs[M.slot+1]~=1) then return false,"需要40级、洛阿祝福及酿造方案" end
 if (rank(6016)>0 or rank(6009)>0) and (M.level<10 or rank(4005)==0 or rank(12645)==0 or M.BrewingFoundation(mask)<8) then return false,"需要大锅、蘑菇和8基础酿造TE" end
 if rank(6016)>0 and rank(29738)==0 then return false,"需要蛙骨配料" end
 if rank(6009)>0 and rank(6021)==0 then return false,"需要血蓟配料" end
 if (rank(30823)>0 or rank(6022)>0 or rank(6013)>0) and (M.level<10 or rank(4005)==0 or M.BrewingFoundation(mask)<8) then return false,"需要大锅和8点基础酿造TE" end
 if rank(30823)>0 and (M.level<29 or (rank(7128)==0 and rank(29303)==0)) then return false,"魔精光束需要29级及泼洒或药水增效" end
 if rank(6022)>0 and rank(7128)==0 then return false,"需要泼洒药水" end
 if rank(6013)>0 and ((rank(29303)==0 and rank(29738)==0) or rank(7948)>0) then return false,"需要药水增效或蛙骨，并与灵魂之触互斥" end
 if (rank(6021)>0 or rank(6014)>0) and (M.level<10 or rank(4005)==0 or M.BrewingFoundation(mask)<8) then return false,"需要大锅酿造及8点基础酿造TE" end
 if rank(4112)>0 and rank(7130)>0 then return false,"两种香料互斥" end
 if (rank(6645)>0 or rank(4112)>0 or rank(7130)>0) and rank(4005)==0 then return false,"需要大锅酿造" end
 if (rank(4112)>0 or rank(7130)>0) and M.BrewingFoundation(mask)<8 then return false,"需先投入8点基础酿造TE" end
 if M.AESpent(mask)>(M.aeBudget or 0) then return false,"通用点数AE不足；TE不能代替AE" end
 if rank(6054)>0 and rank(29744)==0 and rank(29301)==0 then return false,"灵性传统需要治疗守卫或拟态守卫" end
 if (rank(6047)>0 or rank(7092)>0) and rank(6054)==0 then return false,"睿智／寻觅者需要灵性传统" end
 if rank(29309)>0 and M.level<16 then return false,"净化神像需要角色等级16" end
 if rank(29309)>0 and rank(6047)==0 and rank(7092)==0 then return false,"净化神像需要睿智或寻觅者" end
 if (rank(4004)>0 or rank(4533)>0 or rank(11532)>0 or rank(4532)>0 or rank(11133)>0 or M.TESpent(mask)-M.BrewingSpent(mask)-rank(1969)-rank(7779)-rank(7086)-rank(6072)-rank(6074)-rank(8574)-rank(30895)-rank(6063)-rank(6069)-rank(5253)-rank(6853)-rank(30892)-rank(6983)-rank(5164)-rank(6011)-rank(6073)-rank(29729)-rank(7031)-rank(11330)-rank(29930)-rank(6010)-rank(11164)-rank(29981)-rank(4572)-rank(6035)-rank(7355)-rank(7102)-rank(5303)-rank(4177)-rank(11177)-rank(7103)-rank(4423)-rank(29977)-rank(7781)-rank(6076)-rank(5235)-rank(6388)-rank(29978)>0) and M.specs[M.slot+1]~=0 then return false,"本方案需要绑定巫毒专精" end
 if (M.BrewingSpent(mask)>0 or rank(9311)>0 or rank(4715)>0) and M.specs[M.slot+1]~=1 then return false,"本方案需要绑定酿造专精" end
 if (rank(4005)>0 or rank(12645)>0 or rank(12646)>0) and M.specs[M.slot+1]~=1 then return false,"本方案需要绑定酿造专精" end
 if (rank(12645)>0 or rank(12646)>0) and rank(4005)==0 and rank(29744)==0 then return false,"需要大锅酿造或治疗守卫" end
 if (rank(6498)>0 or rank(29303)>0 or rank(6020)>0 or rank(29737)>0) and M.BrewingFoundation(mask)<8 then return false,"需要先投入8点基础酿造TE；同层不计前置" end
 if rank(6020)>0 and rank(29737)>0 then return false,"丛林绽放与丛林医师二选一" end
 if rank(7128)>0 and M.level<17 then return false,"泼洒药水需要17级" end
 if (rank(35065)>0 or rank(35064)>0 or rank(35068)>0 or rank(29738)>0 or rank(30888)>0 or rank(35051)>0) and M.BrewingFoundation(mask)<8 then return false,"需先投入8点基础酿造TE" end
 if rank(12646)>0 and M.level<14 then return false,"药水投掷需要14级" end
 if rank(9311)>0 and M.level<20 then return false,"灵魂医者需要等级20" end
 if rank(4715)>0 and M.level<30 then return false,"洛阿祝福需要等级30" end
 if (rank(7948)>0 or rank(31137)>0) and M.BrewingFoundation(mask)<8 then return false,"需要先投入8点基础酿造TE；这两个节点不能互相凑前置" end
 if rank(7948)>0 and M.level<16 then return false,"灵魂之触需要16级" end
 if rank(31137)>0 and M.level<30 then return false,"丛林秘法需要30级" end
 if (rank(30891)>0) and M.AESpent(mask)-rank(30147)-rank(4132)-rank(7033)-rank(6051)-rank(6048)-rank(5113)-rank(30891)-rank(6381)-rank(12048)-rank(11323)-rank(12264)-rank(6042)-rank(9347)-rank(29306)-rank(6031)-rank(6525)-rank(12525)-rank(29743)-rank(6050)-rank(6049)<9 then return false,"先投入9点基础AE；同层不能互相凑点" end
 if rank(5113)>0 and M.level<58 then return false,"诅咒雕像需要58级" end
 if rank(30891)>0 and M.level<30 then return false,"穆厄扎拉之触需要30级" end
 if (rank(7132)>0 or rank(29753)>0) and M.level<31 then return false,"佳酿需要31级" end
 if rank(7132)>0 and rank(29753)>0 then return false,"怒气佳酿与奥术佳酿二选一" end
 if (rank(7132)>0 or rank(29753)>0) and M.BrewingFoundation(mask)<8 then return false,"先投入8点基础酿造TE" end
 if (rank(6031)>0 or rank(6525)>0 or rank(12525)>0) and M.level<26 then return false,"蛙变术及祝福需要26级" end
 if (rank(6525)>0 or rank(12525)>0) and rank(6031)==0 then return false,"需先学习蛙变术" end
 if rank(6525)>0 and rank(12525)>0 then return false,"贡克与克拉格瓦祝福二选一" end
 if rank(29306)>0 and M.level<30 then return false,"化蛇需要角色等级30" end
 if (rank(6381)>0 or rank(12048)>0 or rank(11323)>0 or rank(12264)>0 or rank(6042)>0 or rank(9347)>0 or rank(29306)>0 or rank(6031)>0 or rank(6525)>0 or rank(12525)>0) and rank(29744)+rank(6054)+rank(6047)+rank(7092)+rank(29309)+rank(29301)+rank(7088)+rank(6030)+rank(31118)+rank(29747)+rank(7154)+rank(11154)+rank(6044)<9 then return false,"先投入9点基础AE；同层不能互相凑点" end
 if rank(12048)>0 and rank(6048)>0 then return false,"希里克的祝福与黑暗魔精二选一" end
 if rank(31154)>0 then
  if M.level<11 then return false,"暗影傀儡需要角色等级11" end
  if rank(29301)==0 and rank(4004)==0 then return false,"暗影傀儡缺少前置：拟态守卫和傀儡师之线" end
  if rank(29301)==0 then return false,"暗影傀儡缺少前置：拟态守卫（左侧通用树最上排中间）" end
  if rank(4004)==0 then return false,"暗影傀儡缺少前置：傀儡师之线（巫毒最右竖列顶部，免费）" end
  if (M.teBudget or 0)<1 then return false,"暗影傀儡需要1点TE" end
 end
 if (rank(30147)>0 or rank(4132)>0 or rank(7033)>0 or rank(6051)>0 or rank(6048)>0) and M.AESpent(mask)-rank(30147)-rank(4132)-rank(7033)-rank(6051)-rank(6048)-rank(5113)-rank(30891)-rank(6381)-rank(12048)-rank(11323)-rank(12264)-rank(6042)-rank(9347)-rank(29306)-rank(6031)-rank(6525)-rank(12525)-rank(29743)-rank(6050)-rank(6049)<9 then return false,"需要先投入9 AE；同层节点不能互相凑前置" end
 if rank(6051)>0 and M.level<28 then return false,"迅捷神像需要等级28" end
 if rank(6048)>0 and M.level<32 then return false,"黑暗魔精需要等级32" end
 if rank(30147)>0 and M.level<28 then return false,"炼金强化需要等级28" end
 if rank(11133)>0 and M.level<50 then return false,"妖火进阶需要等级50" end
 if rank(31349)>0 and (M.level<59 or M.TEFoundation(mask)<8) then return false,"战争魔像需要59级与8点基础TE" end
 if rank(6055)>0 and M.level<59 then return false,"灵魂提线需要59级" end
 if (rank(29929)>0 or rank(6055)>0) and (M.level<57 or M.TESpent(mask)-rank(31346)-rank(7100)-rank(29768)-rank(6057)-rank(29929)-rank(6055)<23) then return false,"需要23点前层TE，高阶节点不能互相凑点" end
 if rank(30596)>0 and (M.level<27 or M.TEFoundation(mask)<8) then return false,"傀儡师之握需要27级及8点基础巫毒TE" end
 if rank(4532)>0 and M.level<30 then return false,"涌动巫毒需要等级30" end
 if rank(29121)>0 and M.level<33 then return false,"恶毒诅咒需要等级33" end
 if rank(6057)>0 and rank(29768)==0 then return false,"力量的代价需要邦桑迪之声" end
 if (rank(29768)>0 or rank(6057)>0) and (M.level<57 or M.TESpent(mask)-rank(31346)-rank(7100)-rank(29768)-rank(6057)-rank(29929)-rank(6055)<23) then return false,"需要57级及23点前层巫毒TE" end
 if rank(7100)>0 and M.TESpent(mask)-rank(31346)-rank(7100)-rank(29768)-rank(6057)-rank(29929)-rank(6055)<23 then return false,"黑暗雕像需要先投入23 TE，不能用自身凑前置" end
 if rank(31346)>0 and M.TESpent(mask)-rank(31346)-rank(7100)-rank(29768)-rank(6057)-rank(29929)-rank(6055)<23 then return false,"彼界需要先投入23 TE，不能用自身凑前置" end
 if rank(11532)>0 and M.level<40 then return false,"巫毒灵魂需要角色等级40" end
 if rank(4533)>0 and M.level<20 then return false,"巫毒之力需要角色等级20" end
 if rank(31341)>0 and rank(6045)>0 then return false,"空灵之魂与这就是巫毒只能选择一个" end
 if (rank(31341)>0 or rank(6045)>0 or rank(31347)>0 or rank(31348)>0 or rank(6644)>0 or rank(6046)>0 or rank(6062)>0 or rank(30889)>0 or rank(31343)>0 or rank(6053)>0 or rank(31350)>0 or rank(5333)>0 or rank(6059)>0 or rank(5332)>0 or rank(6007)>0 or rank(29121)>0) and M.TEFoundation(mask)<8 then return false,"需要先在已开放的基础巫毒节点投入8 TE；高阶节点不能互相凑前置" end
 if rank(29928)>0 and M.level<15 then return false,"邪恶巫毒需要角色等级15" end
 if rank(7157)>0 and M.level<15 then return false,"妖火需要角色等级15" end
 if M.level<10 and not M.MaskEqual(mask,0) then return false,"天赋加点需要角色等级10" end
 return true
end
