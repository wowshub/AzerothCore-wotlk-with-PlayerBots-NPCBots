from pathlib import Path
import json,urllib.request,urllib.parse
P=Path(Path('wd113_path.txt').read_text(encoding='utf8'))
def get(url):return json.load(urllib.request.urlopen(urllib.request.Request(url,headers={'User-Agent':'WD113-source-audit'}),timeout=25))
q='repo:jealous-sound/azerothcore-wotlk-coa is:pr "Witch Doctor"'
d=get('https://api.github.com/search/issues?q='+urllib.parse.quote(q)+'&sort=updated&order=desc&per_page=8')
(P/'research/recent_prs.json').write_text(json.dumps(d),encoding='utf8')
print([(x['number'],x['title'])for x in d.get('items',[])])
for id in [1122,1379,1810]:
 d=get(f'https://api.github.com/repos/jealous-sound/azerothcore-wotlk-coa/issues/{id}/comments')
 (P/f'research/comments{id}.json').write_text(json.dumps(d),encoding='utf8')
 print(id,[v.get('body','')[:1100] for v in d])
