from pathlib import Path
p=Path(Path('D:/000rebornWOW/wd114b_path.txt').read_text(encoding='utf-8'))
s=Path('D:/000rebornWOW/wd114_numeric_test.lua').read_text(encoding='utf-8-sig')
s=s.replace('function hooksecurefunc() end','local setters={}\nfunction hooksecurefunc(_,name,fn) setters[name]=fn end')
s=s.replace('function GameTooltip:SetHyperlink()end','function GameTooltip:Show() self.shows=(self.shows or 0)+1;self.hooks.OnTooltipSetSpell(self) end\nfunction GameTooltip:SetSpell()end\nfunction GetSpellLink()return "spell:"..id end\nfunction GameTooltip:SetHyperlink()end')
s+='''
-- WD114B: native setters, native FontString rebuild and synchronous Show hooks.
locale='zhCN';id=9003143;reset();sent={};now=100
M=assert(loadfile(file))()
setters.SetSpell(GameTooltip,1,'spell')
local previousShows=GameTooltip.shows
M.receive('WD114|'..seq()..'|9003143|ok|165|0|0|10|1')
assert(GameTooltip.shows>previousShows and GameTooltipTextLeft2.text=='165法力值')
local stableShows=GameTooltip.shows
M.refresh(GameTooltip);assert(GameTooltip.shows==stableShows) -- no unnecessary relayout loop
-- Native UI overwrites fonts while retaining the tooltip object.
GameTooltipTextLeft2:SetText('440法力值')
setters.SetAction(GameTooltip,1)
assert(GameTooltipTextLeft2.text=='165法力值')
M.invalidate();now=101.1;setters.SetSpellBookItem(GameTooltip,1,'spell')
assert(GameTooltipTextLeft2.text=='440法力值（同步中）') -- use current base, not cached330
M.receive('WD114|'..seq()..'|9003143|ok|220|0|0|10|1')
assert(GameTooltipTextLeft2.text=='220法力值')
-- A reused cost FontString is now a range; it must no longer be overwritten.
GameTooltipTextLeft2:SetText('30码射程');M.refresh(GameTooltip)
assert(GameTooltipTextLeft2.text=='30码射程')
-- Reply arrives after native spell switched, before our normal update hook.
reset();M.invalidate();now=102.2;M.refresh(GameTooltip);local late=seq()
id=9003112;GameTooltipTextLeft2:SetText('835法力值')
M.receive('WD114|'..late..'|9003143|ok|165|0|0|10|1')
assert(GameTooltipTextLeft2.text=='835法力值')
-- Hyperlink entrance and colored comma-formatted cost; zero is a valid server result.
id=9003143;reset('|cffffffff1,100法力值|r');M.invalidate();now=103.3
setters.SetHyperlink(GameTooltip,'spell:9003143')
M.receive('WD114|'..seq()..'|9003143|ok|0|0|0|10|1')
assert(GameTooltipTextLeft2.text=='0法力值')
setters.SetSpellByID(GameTooltip,9003143)
assert(GameTooltipTextLeft2.text=='0法力值' and not GameTooltip.wd114Drawing)
print('PASS WD114B: native book/action/link hooks, reentrant layout, stable layout, refreshed base cost, reused range font, late reply isolation, colored comma cost and zero cost')
'''
(p/'tools'/'test_numeric_tooltip.lua').write_text(s,encoding='utf-8')
