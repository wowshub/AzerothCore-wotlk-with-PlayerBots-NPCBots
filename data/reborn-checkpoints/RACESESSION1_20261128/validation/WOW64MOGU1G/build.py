from probe import *
from struct import pack, pack_into
import ctypes as ct
from tempfile import TemporaryDirectory
from zipfile import ZipFile, ZIP_DEFLATED
import re

out=w.parent/'codexfix_202611260546_阶段WOW64MOGU1G_魔古十职业出生装WORLD兼容'
prior=next(w.parent.glob('codexfix_*WOW64MOGU1E*.zip'))
srv=next((r/'beascendserver').glob('*20261122Ascend'))
repo=r/'beascendcode/AzerothCore-wotlk-with-PlayerBots-NPCBots'
outfit_file='DBFilesClient/CharStartOutfit.dbc'
stock=read(c/'Data/enUS/patch-enUS-2.MPQ',outfit_file)
donors={3:3,7:11,11:4}
keys={(cls,sex) for cls in donors for sex in (0,1)}
compatibility={}
records={}
for cls,sex in sorted(keys):
    source=[row for row in rows(stock)[1] if row[4:8]==bytes((donors[cls],cls,sex,0))]
    assert len(source)==1
    records[cls,sex]=source[0]
    compatibility[cls,sex]={item for item in u('<24i',source[0],8) if item>0}
needed=set().union(*compatibility.values())
assert {12282,2102,2508,2516} <= compatibility[3,0]
assert all(n<900000 for n in needed)
installed_items=read(c/'Data/Patch-XA.mpq','DBFilesClient/Item.dbc')
lookup_items={u('<I',row)[0]:row for row in rows(installed_items)[1]}
assert needed<=lookup_items.keys()
installed_displays=read(c/'Data/Patch-XA.mpq','DBFilesClient/ItemDisplayInfo.dbc')
display_ids={u('<I',row)[0] for row in rows(installed_displays)[1]}
preview_overrides=set()
world_items={}
path=repo/'data/sql/base/db_world/item_template.sql'
for line in path.open(encoding='utf8'):
    id_match=re.match(r'^\((\d+),',line)
    if id_match and (id:=int(id_match[1])) in needed:
        head=re.match(r"""^\(\d+,\d+,\d+,-?\d+,'(?:\\.|[^'\\])*',((?:-?\d+,){14})""",line)
        assert head,id
        world_items[id]=[int(value) for value in head[1].rstrip(',').split(',')]
assert set(world_items)==needed,(needed-set(world_items))
for key,expected in compatibility.items():
    cls=key[0]
    stock_record=records[key]
    for item,disp,slot in zip(*(u('<24i',stock_record,field) for field in (8,104,200))):
        if item<=0:
            continue
        world=world_items[item]
        assert world[0]==disp and world[7]==slot,(key,item,disp,slot,world[:10])
        preview,preview_slot=u('<2i',lookup_items[item],20)
        assert preview_slot==slot and preview in display_ids,(item,preview,preview_slot,slot)
        if preview!=disp:
            preview_overrides.add((item,disp,preview))
        assert world[8]==-1 or world[8] & (1<<(cls-1)), (item,world[8])
        assert world[9]==-1 and world[11]<=1,(item,world[9],world[11])

def save(path,data):
    target=out/path
    target.parent.mkdir(parents=True,exist_ok=True)
    target.write_bytes(data)
    return target

def compose(original,rows_new):
    sig,_,cols,width,_=u('<4s4I',original)
    _,_,strings=rows(original)
    assert sig==b'WDBC' and all(len(row)==width for row in rows_new)
    data=pack('<4s4I',sig,len(rows_new),cols,width,len(strings))+b''.join(rows_new)+strings
    assert rows(data)[1]==rows_new
    return data

def fits(row):
    return row[4]==123 and row[5] in donors

def outfit(original,known_previous,is_client):
    width,base,_=rows(original)
    assert width==296
    now=[row for row in base if fits(row)]
    reference={tuple(row[5:8]):row[5:] for row in rows(known_previous)[1] if fits(row)}
    assert len(reference)==6
    if now:
        assert len(now)==6 and {tuple(row[5:8]):row[5:] for row in now}==reference
    next_id=max(u('<I',row)[0] for row in base)+1
    def make(key,entry):
        result=bytearray(records[key])
        result[4]=123
        pack_into('<I',result,0,entry)
        if is_client:
            for column,item in enumerate(u('<24i',result,8)):
                if item>0:
                    pack_into('<i',result,104+4*column,u('<i',lookup_items[item],20)[0])
        return bytes(result)
    if now:
        result=[make(tuple(row[5:7]),u('<I',row)[0]) if fits(row) else row for row in base]
    else:
        result=base+[make(key,next_id+i) for i,key in enumerate(sorted(keys))]
    assert [row for row in result if not fits(row)]==[row for row in base if not fits(row)]
    assert {(row[5],row[6]) for row in result if fits(row)}==keys
    return compose(original,result)

def base_info(original):
    width,current,_=rows(original)
    assert width==2
    seen={row[1] for row in current if row[0]==123}
    original_classes={1,2,4,5,6,8,9}
    target=original_classes|set(donors)
    assert seen in (original_classes,target),seen
    return compose(original,current+[bytes((123,cls)) for cls in sorted(target-seen)])

checks=[]
client_items=[('Patch-YB.mpq','CharBaseInfo',base_info),('Patch-XA.mpq','CharStartOutfit',outfit)]
client_outputs=[]
with ZipFile(prior) as previous:
    for archive,name,operation in client_items:
        key='DBFilesClient/'+name+'.dbc'
        for source,prefix,old_prefix in (
            (c/'Data'/archive,f'01_导入现有{archive}/DBFilesClient/',f'01_客户端_导入现有{archive}/DBFilesClient/'),
            (srv/'Data/dbc','02_覆盖服务端根目录/Data/dbc/','02_服务端_覆盖根目录/Data/dbc/'),
            (srv/'Data/dbc/zhCN','02_覆盖服务端根目录/Data/dbc/zhCN/','02_服务端_覆盖根目录/Data/dbc/zhCN/'),
        ):
            is_mpq=source.suffix=='.mpq'
            filename=name+'.dbc'
            base=read(source,key) if is_mpq else (source/filename).read_bytes()
            prior_name=old_prefix+filename
            prior_payload=previous.read(prior_name)
            after=operation(base,prior_payload,is_mpq) if operation is outfit else operation(base)
            # Old 1E files already copied by the user are also valid inputs.
            before_1e=previous.read('backup_原文件/'+prior_name)
            for alternate in (before_1e,prior_payload):
                normalized=operation(alternate,prior_payload,is_mpq) if operation is outfit else operation(alternate)
                assert normalized==after,(prefix,filename,'alternate does not match live-based output')
            path=prefix+filename
            save('backup_准备时现场/'+path,base)
            new_file=save(path,after)
            accepted=' '.join(sorted({sha256(data).hexdigest() for data in (base,before_1e,prior_payload)}))
            checks.append(f'{path}\n  live {sha256(base).hexdigest()}\n  alternate hash set {accepted}\n  output {sha256(after).hexdigest()}')
            if is_mpq:
                client_outputs.append((archive,key,new_file,after))
    header_name='03_服务端源码_覆盖源码根目录/src/server/shared/RebornClassicRaceClasses.h'
    header=previous.read(header_name)
    assert b'constexpr std::uint8_t donors[] = {0,1,1,3,1,1,1,11,1,1,0,4};' in header
    save(header_name,header)
    header_path=header_name.split('/',1)[1]
    file=(repo/header_path).read_bytes()
    assert file in (header,previous.read('backup_原文件/'+header_name))
    save('backup_准备时现场/'+header_name,file)
    old_sql=previous.read('04_WORLD_数据库/01_MOGU1E_WORLD.sql').decode()
    start=old_sql.index('    IF (SELECT COUNT(*) FROM item_template')
    end=old_sql.index('    -- Keep',start)
    ids=', '.join(map(str,sorted(needed)))
    guard='''    SELECT GROUP_CONCAT(required_items.entry ORDER BY required_items.entry)
      INTO missing_items
      FROM JSON_TABLE('[ITEM_IDS]', '$[*]' COLUMNS (entry INT PATH '$')) required_items
      LEFT JOIN item_template item ON item.entry = required_items.entry
      WHERE item.entry IS NULL;
    IF missing_items IS NOT NULL THEN
        SET error_detail = CONCAT('MOGU1G: missing stock item IDs: ', missing_items);
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = error_detail;
    END IF;

'''.replace('ITEM_IDS',ids)
    sql=(old_sql[:start]+guard+old_sql[end:]).replace('    DECLARE EXIT HANDLER','    DECLARE missing_items TEXT;\n    DECLARE error_detail VARCHAR(128);\n    DECLARE EXIT HANDLER',1)
    sql=sql.replace('codex_mogu1e_install','codex_mogu1g_install')
    sql=sql.replace('MOGU1E:', 'MOGU1G:')
    # An old failed CALL may have left its procedure installed in the same schema.
    sql=sql.replace('DROP PROCEDURE IF EXISTS codex_mogu1g_install;', 'DROP PROCEDURE IF EXISTS codex_mogu1e_install;\nDROP PROCEDURE IF EXISTS codex_mogu1g_install;',1)
    save('04_WORLD/01_MOGU1G_WORLD.sql',sql.encode())

d,H,U,check=(mpq[name] for name in ('d','H','U','require'))
d.SFileCreateArchive.argtypes=[ct.c_wchar_p,U,U,ct.POINTER(H)]
d.SFileCreateArchive.restype=ct.c_bool
with TemporaryDirectory(dir=w) as temp:
    for archive,key,new_file,data in client_outputs:
        test=Path(temp)/archive
        handle=H()
        check(d.SFileCreateArchive(str(test),0x00100000,64,ct.byref(handle)))
        try:
            check(d.SFileAddFileEx(handle,str(new_file),key.replace('/',chr(92)).encode(),0x80000200,2,2))
        finally:
            check(d.SFileCloseArchive(handle))
        assert read(test,key)==data
        checks.append(f'{archive}/{key}: readback OK')

checks += [f'Native outfit source: patch-enUS-2.MPQ/{outfit_file} {sha256(stock).hexdigest()}',
           f'Base item_template verified display, slot, class, race and level for IDs: {sorted(needed)}',
           f'Client preview keeps installed Item.dbc display overrides: {sorted(preview_overrides)}']
checks += [f'123/{cls}/{sex}: {sorted(gear)}' for (cls,sex),gear in sorted(compatibility.items())]
save('checks/records.txt',('\n'.join(checks)+'\n').encode())
print(out.name, sorted(needed))
