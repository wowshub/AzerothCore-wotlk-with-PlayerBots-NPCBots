from pathlib import Path
import json,urllib.request,urllib.parse,concurrent.futures,re
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO')
P=R/'000Ascendupdate/000Ascendupdate20261002/codexfix_202610022030_阶段WD115A_假死图标与强效混合来源审计'
P.mkdir(parents=True,exist_ok=True);(P/'research').mkdir(exist_ok=True)
Path('D:/000rebornWOW/wd115_path.txt').write_text(str(P),encoding='utf8')
def get(url):return urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'WD115-audit'}),timeout=35).read()
base='https://api.github.com/repos/jealous-sound/azerothcore-wotlk-coa'
head=json.loads(get(base+'/commits/HEAD'));sha=head['sha'];print('HEAD',sha)
(P/'research/head.json').write_text(json.dumps(head),encoding='utf8')
def search(term):
 d=json.loads(get('https://api.github.com/search/issues?q='+urllib.parse.quote('repo:jealous-sound/azerothcore-wotlk-coa '+term)))
 (P/('research/search_'+re.sub(r'\W','_',term)+'.json')).write_text(json.dumps(d),encoding='utf8')
 print(term,[(x['number'],x['title'],x.get('body','')[:2500]) for x in d.get('items',[])])
with concurrent.futures.ThreadPoolExecutor(3) as ex:list(ex.map(search,['"Potent Mixes"','"Death Draught"']))
tree=json.loads(get(base+'/git/trees/'+sha+'?recursive=1'))
(P/'research/tree.json').write_text(json.dumps(tree),encoding='utf8')
paths=[x['path'] for x in tree['tree'] if any(y in x['path'].lower() for y in ['witchdoctor','treespelldata','characteradvancement'])]
print('PATHS',paths)
for i,path in enumerate(paths):
 if path.endswith(('.cpp','.h','.json')):
  (P/('research/upstream_'+str(i)+'_'+Path(path).name)).write_bytes(get('https://raw.githubusercontent.com/jealous-sound/azerothcore-wotlk-coa/'+sha+'/'+path))
