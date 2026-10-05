from pathlib import Path
import shutil,datetime,json,hashlib,urllib.request,urllib.parse
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');B=Path(Path('wd123_path.txt').read_text().strip());F=Path(Path('wd122b_path.txt').read_text().strip())
t=datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=-7))).strftime('%Y%m%d%H%M')
P=Path(Path('wd123b_path.txt').read_text()) if Path('wd123b_path.txt').exists() else R/f'000Ascendupdate/000Ascendupdate{t[:8]}/codexfix_{t}_阶段WD123B_泼洒药水累计与编译修正'
if not P.exists():shutil.copytree(B,P)
Path('wd123b_path.txt').write_text(str(P),encoding='utf8')
rel=Path('modules/mod-reborn-witchdoctor/src/RebornWitchDoctorBrewingFoundation.inc')
shutil.copy2(F/'WD123A/01_覆盖到源代码根目录'/rel,P/'01_覆盖到源代码根目录'/rel)
dest=P/'rollback_WD122A/01_覆盖到源代码根目录'/rel
dest.parent.mkdir(parents=True,exist_ok=True)
shutil.copy2(F/'WD122A/01_覆盖到源代码根目录'/rel,dest)
s=Path('wd123_test.py').read_text(encoding='utf8').replace("Path('wd123_path.txt')","Path('wd123b_path.txt')")
Path('wd123b_test.py').write_text(s,encoding='utf8')
accept='''\n\n## 2026-10-04 WD122A 用户本批测试通过
用户明确反馈“WD122A 累计测试包测试通过继续下一批技能的开发”。在WD122B编译修正交付后登记WD122本批基本测试通过；未获得逐项日志，不扩大成全部数值、多人、机器人、切方案矩阵均验证。下一累计版本必须合并TARGET_UNIT_CASTER_AREA_RAID=56的兼容修正，历史WD122A原ZIP仍有已知编译错误，不能重新直接使用。WD123泼洒药水仍候选待测。
来源：000Ascendupdate20261003/codexfix_202610031523_阶段WD122A_丛林蘑菇互斥双天赋；修正：000Ascendupdate20261004/codexfix_202610040721_阶段WD122B_范围目标枚举编译修正。
复用：互斥天赋的保存、激活被动、目标人数和周期提示一并接入；枚举须查目标核心声明。周期重新计时不能凭空增加治疗跳数。基本验收不能替代未测边界。
'''
for n in ['updateMemory.md','updateListAscend.md','tutorMemory.md','beascendskills/skillsAscend.md','beascendskills/trace-and-port-coa-spell-resources/SKILL.md','beascendtutor/tutorAscend.md','beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md']:
 with (R/n).open('a',encoding='utf8') as f:f.write(accept)
(P/'WD122_用户验收.md').write_text(accept,encoding='utf8')
print(str(P))
