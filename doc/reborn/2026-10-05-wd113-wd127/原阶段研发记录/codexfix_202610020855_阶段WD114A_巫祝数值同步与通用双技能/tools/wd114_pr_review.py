from pathlib import Path
import json,urllib.request
P=Path(Path('wd114_path.txt').read_text(encoding='utf8').strip())
root='https://api.github.com/repos/jealous-sound/azerothcore-wotlk-coa/'
def read(url):return json.loads(urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'WD114-readonly-audit'}),timeout=25).read())
out={}
for n in [6077,6123]:
 p=read(root+'pulls/'+str(n));files=read(root+'pulls/'+str(n)+'/files?per_page=100')
 out[n]={'title':p['title'],'url':p['html_url'],'state':p['state'],'merged':p['merged'],'body':p['body'],'files':files}
 print(n,p['title'],[f['filename'] for f in files if 'witch' in f['filename'].lower()])
(P/'research/reviewed_prs.json').write_text(json.dumps(out,ensure_ascii=False,indent=2),encoding='utf8')
