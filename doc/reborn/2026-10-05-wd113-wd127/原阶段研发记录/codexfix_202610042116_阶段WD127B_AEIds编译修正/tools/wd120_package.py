# coding: utf-8
from pathlib import Path
import json,zipfile,hashlib,datetime
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO');P=Path(Path('wd120_path.txt').read_text());stamp=datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=-7))).strftime('%Y%m%d%H%M')
required=['README_覆盖与测试说明.md','memory.md','tutor.md','handoff.md','checks/mysql_results.json','checks/data.json','checks/ui_numeric.txt','checks/ui_book.txt','checks/native_visual_closure.json']
for f in required:assert (P/f).exists(),f
assert json.loads((P/'checks/mysql_results.json').read_text())['status']=='passed'
assert json.loads((P/'checks/native_visual_closure.json').read_text(encoding='utf8'))['status']=='all referenced native assets found'
files={str(f.relative_to(P)).replace('\\','/'):hashlib.sha256(f.read_bytes()).hexdigest() for f in P.rglob('*') if f.is_file() and f.name!='sha256.json'}
(P/'checks/sha256.json').write_text(json.dumps(files,ensure_ascii=False,indent=2),encoding='utf8')
target=Path(str(P)+'.zip');assert not target.exists(),'Do not overwrite a delivered ZIP'
with zipfile.ZipFile(target,'w',zipfile.ZIP_DEFLATED,compresslevel=4) as z:
 for rel in files:z.write(P/rel,rel)
 z.write(P/'checks/sha256.json','checks/sha256.json')
with zipfile.ZipFile(target) as z:
 assert z.testzip() is None
 assert not any(n.lower().endswith(('.exe','.bat','.ps1','.patch')) for n in z.namelist())
sha=hashlib.sha256(target.read_bytes()).hexdigest();Path(str(target)+'.sha256.txt').write_text(sha+'  '+target.name+'\n',encoding='utf8')
note=f'''\n\n## {stamp} WD120A 酿造基础三节点（候选待编译/实测）
已完成4005大锅酿造、12645丛林蘑菇、12646药水投掷的有界接入：免费酿造节点、配料6秒范围治疗、投掷7级+18秒HoT。保存扩87位，旧位与购买账本保留；World手动系数避免重复加成；节点/技能书/拖动图标一致。当前治疗参考范围读取服务端，不依赖草稿。基线WD119A累计+已验收WD119B+候选WD119C；WD119C和本批尚未实机通过。
上游在线固定d7620151fa4267ab90c7e0554b32628017df241a；字段232是描述变量ID，实际802703等级缩放来自ScalingBase实现。不能将早期字段误判继续复用。仅蘑菇一种配料，其他配料和泼洒仍未开放；外观复用既有洛阿佳酿887925，36项引用资源已只读找到，不宣称大锅模型或专属药瓶弹道完成。
403项临时MySQL与累计Lua/DBC检查通过；C++没有编译，没有修改运行目录或生产数据库。一次历史GM测试断言未复现，原路径未声称修复，详见memory。
[覆盖说明]({P.as_posix()}/README_覆盖与测试说明.md)；[逐步教程]({P.as_posix()}/tutor.md)；[交接]({P.as_posix()}/handoff.md)。ZIP SHA256 `{sha}`。旧ZIP不改写。
'''
for rel in ['updateMemory.md','updateListAscend.md','tutorMemory.md','refResourceAscend.md','beascendskills/skillsAscend.md','beascendtutor/tutorsAscend.md','beascendskills/plan-coa-class-migration/SKILL.md','beascendtutor/plan-coa-class-migration/TUTOR.md','beascendskills/trace-and-port-coa-spell-resources/SKILL.md','beascendtutor/trace-and-port-coa-spell-resources/TUTOR.md','beascendskills/build-wotlk-three-build-projection/SKILL.md','beascendtutor/build-wotlk-three-build-projection/TUTOR.md','beascendskills/stabilize-spelldraft-client-ui/SKILL.md','beascendtutor/stabilize-spelldraft-client-ui/TUTOR.md']:
 f=R/rel;assert f.exists()
 with f.open('a',encoding='utf8') as out:out.write(note)
print(target);print('SHA256',sha);print('bytes',target.stat().st_size)
