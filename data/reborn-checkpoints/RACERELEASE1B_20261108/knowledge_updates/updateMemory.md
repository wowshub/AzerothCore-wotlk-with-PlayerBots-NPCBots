## 2026-11-08 RACERELEASE1B分项发布完成
七项分别commit/tag/Release，七附件uploaded且大小/SHA256匹配。保留Claude7612c6f祖先和PB gitlink e85232a；四族十职业建角底座按用户指示不发布。正式源码提取Hunter补缺和图腾fallback，分别MSVC /Zs通过，未宣称整树重链接或独立全40组合安装包。当前已测用户无需重装，生产SQL/部署由用户负责。证据：000Ascendupdate/000Ascendupdate20261108/release_RACERELEASE1B_20261108/publication.json；详见发布结果与交接.md。


## 2026-11-08 RACERELEASE1B：猎人与首登验收更新（建角底座不发布）
用户确认四族猎人弓/枪/弩与自动射击、首登I三模式→经典介绍→开始冒险不小退通过。猎人技能45/46/226、法术264/266/5011/75必须出生发物品前补缺，旧角色幂等，不降低熟练度；本次只提取Hunter补缺，保留正式建角资格，RACECLASS1A四族十职业底座用户明确暂不发布。
永久避坑：射击通过不等于弹药槽通过。原生Hunter3/HUNTER也要进入AmmoFix队列，不能仅custom13/14/15/圣物；原生Update后可能再次Hide，最终Show仍保留native slot0/OnClick。新种族必须测弓枪弩技能+法术、实际远程武器/匹配弹药、人物面板原生槽、穿脱/缓存晚到/战斗/重登/冷启动及射击。只测背包有箭或自动射击不充分。
用户弹药修复“通过可以推送”，Zann随后“一会显示了”并截图，记基本显示通过、冷启动观察到延迟，未证明唯一事件根因，不以清空WTF/缓存掩盖。HUNTERAMMO1A=556095cc33a2dcaa98ca549790dda7da1bb8d6aa；HUNTERRANGED1C=e84ef372f4390444d1e18277bafc127f98064659。
模式旧A/B/C/G/H失败不删除；I前先用户现场确认IsVisible1/alpha1/尺寸正常但坐标nil，显式CENTER立即恢复。Show后必须检查有效屏幕坐标，再ACK；不能靠超时强解锁或仅靠mock通过。MODEGATE1I=9f0833f7b4d48c7d940ca2f74a572a859632cdf8。资源与边界见当日release_RACERELEASE1B_20261108/publication.json及发布结果与交接.md。


## 2026-11-08 RACERELEASE1B：外观组件分项验收发布
用户确认背盾NPC对话不再放大、预览不再双臂闪烁，头盔与最终四族图腾通过。G以Claude v8为底，helper158恒定global0 TRS避免Talk外部.anim错误基址；OVERLAY INTACT、UV2和其它顶点差异均0。只带男性一M2，不带Claude skin/底图/女性。当前后续SETHANIM1A仅5项动画lookup候选，不随本次发布；不可用G反盖后续候选。
图腾16M2/16skin/64BLP闭包匹配当前YJ；库尔用海潮祭柱原资源，scale0.60，最终name attachment18解决悬字。K1B边界改动单独没有解决名字；原始静态概念/网格图不代表游戏动态结果。六表各自正式基线仅追加16图腾记录，不带暂缓的CLASS1A飞行记录。已测当前累计表不可整表反盖。
HELMKT1A=27ade201d4f7afe64a85039e8d07fb483cca3ace；PREVIEW1F=235ca8631cbda99b5b52eb338dc745ef5af88d75；SETHSHIELD1G=2d02b70cc30e61c5d112f3c00582f263142240fe；RACETOTEM1C=b847488239a57324ae19295f0a27bd8c961a6fe4。对应tag/附件全哈希见当日release_RACERELEASE1B_20261108/publication.json。未逐项全装备/动画/男女/PvP，不扩大验收。
