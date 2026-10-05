from pathlib import Path
import json,hashlib,re,zipfile,shutil
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd123b_path.txt').read_text());B=Path(Path('wd123_path.txt').read_text());F=Path(Path('wd122b_path.txt').read_text())
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
rel=Path('01_覆盖到源代码根目录/modules/mod-reborn-witchdoctor/src/RebornWitchDoctorBrewingFoundation.inc')
assert (P/rel).read_bytes()==(B/rel).read_bytes().replace(b'TARGET_UNIT_SRC_AREA_RAID',b'TARGET_UNIT_CASTER_AREA_RAID')
header=(R/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots/src/server/shared/SharedDefines.h').read_text(encoding='utf-8-sig')
assert re.search(r'TARGET_UNIT_CASTER_AREA_RAID\s*=\s*56',header)
unchanged=0
for prefix in ['01_覆盖到源代码根目录','02_覆盖到客户端根目录','03_覆盖到服务端根目录','client_mpq输入_导入现有Patch-XA','server_SQL']:
 for src in (B/prefix).rglob('*'):
  if src.is_file() and src.relative_to(B)!=rel:
   assert src.read_bytes()==(P/src.relative_to(B)).read_bytes(),src
   unchanged+=1
readme=(P/'README_覆盖与测试说明.md').read_text(encoding='utf8')
readme=readme.replace('# WD123A','# WD123B').replace('基于WD122A，保留已通过的WD121A治疗双天赋、WD121B蛙变冷却，以及待验收WD122A蘑菇二选一。','基于WD123A候选合入WD122B编译修正。用户已确认WD122本批测试通过；保留WD121A治疗双天赋、WD121B蛙变冷却与WD122蘑菇二选一。使用本包全部累计文件，不再叠加旧WD123A或选择WD122B分支。')
readme=readme.replace('未编译、未部署、未实机，WD122A和WD123A均待用户验收。','本次重新运行累计Lua、书页、冷却提示和双端DBC检查通过。441项隔离MySQL为WD123A历史结果，本次SQL字节未变，未重复执行。未代编译、未部署；WD122用户本批已通过，新增泼洒仍待用户编译和实机验证。')
readme+='\n\n## 本次累计整理说明\n\n修正后的源码使用TARGET_UNIT_CASTER_AREA_RAID=56。WD123A其他交付源码、SQL、双端数据和Lua逐文件保持一致；回滚目录也合入WD122编译修正。SQL文件名保留WD123A，这是同一套迁移，不是漏更。\n\n本次尝试读取GitHub HEAD和Issue6294失败，最新线上状态未核对。沿用WD123A已归档commit e7c0ccabb18456bb8aac2aaba55bc799381b9b26及官方20260925资源证据，不宣称最新上游一致。\n'
(P/'README_覆盖与测试说明.md').write_text(readme,encoding='utf8')
note='''\n\n## WD123B 续批交接
用户确认WD122本批基本测试通过，不能外推全部组合。当前下一批是此前已完成但尚未验收的WD123泼洒药水；本包累计合并WD122B编译修正，未虚构额外新技能。
本次复核Lua93位保存/等级/专精/点数门槛、技能书原生接口隔离、提示刷新、双端独立DBC字符串、七等级及隐藏HoT、图标双路径、WD121B核心文件保留，均通过。安装载荷除一处枚举外与WD123A完全相同。SQL使用历史441项隔离验证，本轮未再运行数据库。
未代用户编译或部署，泼洒尚待实机。第一次准备脚本回滚目录层级遗漏，复制时失败；修正为rollback_WD122A/01_覆盖到源代码根目录后完成，不涉及生产目录。
本轮GitHub读取失败，未刷新上游审计。历史固定commit和官方证据仍附包。使用trace-and-port-coa-spell-resources与build-wotlk-three-build-projection技能。
'''
for name in ['memory.md','handoff.md','tutor.md','来源与适配说明.md']:
 with (P/name).open('a',encoding='utf8') as f:f.write(note)
for name in ['wd123b_stage.py','wd123b_test.py','wd123b_finish.py']:shutil.copy2(name,P/'tools'/name)
(P/'checks/WD123B.json').write_text(json.dumps({'unchanged_install_files':unchanged,'source_change':'one enum identifier only','lua_dbc':'rerun PASS','sql':'unchanged; historical isolated 441 checks only','compile':'not run','game':'pending','upstream_refresh':'failed'},indent=2),encoding='utf8')
(P/'SHA256.json').write_text(json.dumps({str(p.relative_to(P)):sha(p) for p in P.rglob('*') if p.is_file() and p.name!='SHA256.json'},ensure_ascii=False,indent=2),encoding='utf8')
z=P.with_suffix('.zip')
with zipfile.ZipFile(z,'w',zipfile.ZIP_DEFLATED) as f:
 for p in P.rglob('*'):
  if p.is_file():f.write(p,str(p.relative_to(P)))
with zipfile.ZipFile(z) as f:assert f.testzip() is None
entry=f'\n\n## 2026-10-04 WD123B 泼洒药水累计候选\n承接用户WD122测试通过，将WD123A七级范围治疗与12秒/3秒蘑菇HoT合并WD122B正确枚举；累计Lua/DBC检查重跑通过，{unchanged}个其余安装文件与WD123A字节一致。SQL历史441项隔离验证，本轮未重跑。未编译/部署/实机，上游刷新失败已明示。\n[覆盖说明]({P.as_posix()}/README_覆盖与测试说明.md) · [教学]({P.as_posix()}/tutor.md)。ZIP SHA256 `{sha(z)}`。\n'
for name in ['updateMemory.md','updateListAscend.md','tutorMemory.md','refResourceAscend.md','beascendskills/skillsAscend.md','beascendskills/trace-and-port-coa-spell-resources/SKILL.md','beascendtutor/tutorAscend.md','beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md']:
 with (R/name).open('a',encoding='utf8') as f:f.write(entry)
(P.parent/'phaseFixForNewChat_WD123B.md').write_text(note+entry,encoding='utf8')
print(str(z));print(sha(z));print('Unchanged install files:',unchanged)
