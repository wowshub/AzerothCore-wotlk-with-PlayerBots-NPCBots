from pathlib import Path
import re, shutil, json
P=Path(Path('D:/000rebornWOW/wd127f_path.txt').read_text(encoding='utf-8'))
R=Path('D:/000rebornWOW/000RebornWOWHighForkPRO')
prior=R/'000Ascendupdate/000Ascendupdate20261004/codexfix_202610040834_阶段WD124A_酿造治疗三节点/tools/wd123_numeric_test.lua'
text=prior.read_text(encoding='utf-8-sig')
(P/'checks/previous_numeric_test.lua').write_text(text,encoding='utf-8')
test=text[:text.index('reset();M.refresh(GameTooltip)')]+'''
local cases=0
for _,lang in ipairs({'zhCN','enUS'}) do
 locale=lang;now=0;frames={};sent={};M=assert(loadfile(file))()
 for _,first in ipairs({9003870,9003890}) do
  for rank=0,6 do
   id=first+rank
   for _,cooldown in ipairs({10000,15000,10000}) do
    M.invalidate();now=now+3;reset('826 Mana')
    GameTooltipTextRight3=font(lang=='zhCN' and '15秒冷却时间' or '15 sec Cooldown')
    GameTooltipTextLeft4=font(lang=='zhCN' and '蘑菇持续12秒，每3秒；15秒冷却。' or 'Shrooms 12 sec every 3 sec. 15 sec cooldown.')
    M.refresh(GameTooltip)
    assert(GameTooltipTextRight3.text:find('syncing',1,true) or GameTooltipTextRight3.text:find('同步中',1,true))
    M.receive('WD114|'..seq()..'|'..id..'|ok|826|293|319|10|1|160|12000|'..cooldown)
    local sec=tostring(cooldown/1000):gsub('%.0$','')
    assert(GameTooltipTextRight3.text==(lang=='zhCN' and sec..'秒冷却时间' or sec..' sec Cooldown'),GameTooltipTextRight3.text)
    assert(GameTooltipTextLeft4.text:find(lang=='zhCN' and sec..'秒冷却' or sec..' sec cooldown',1,true))
    assert(GameTooltipTextLeft4.text:find(lang=='zhCN' and '持续12秒' or '12 sec',1,true))
    assert(GameTooltipTextLeft5.text:find('cooldown '..sec..' sec',1,true))
    for rep=1,5 do M.refresh(GameTooltip) end
    assert(GameTooltip:NumLines()==5)
    -- Native action/book setter can rebuild the original Right heading in place.
    GameTooltipTextRight3:SetText(lang=='zhCN' and '15秒冷却时间' or '15 sec Cooldown')
    M.refresh(GameTooltip)
    assert(GameTooltipTextRight3.text==(lang=='zhCN' and sec..'秒冷却时间' or sec..' sec Cooldown'))
    cases=cases+1
   end
  end
 end
 -- No authoritative cooldown field: never invent a green 15-second result.
 id=9003876;M.invalidate();now=now+3;reset()
 GameTooltipTextRight3=font('15 sec Cooldown');M.refresh(GameTooltip)
 M.receive('WD114|'..seq()..'|'..id..'|ok|0|100|200|10|1|0|0')
 assert(GameTooltipTextLeft5.text:find('cooldown syncing',1,true))
 -- Late response for Toss must not repaint Splash.
 M.invalidate();now=now+3;id=9003876;reset();M.refresh(GameTooltip);local late=seq()
 id=9003896;reset();GameTooltipTextRight3=font('15 sec Cooldown');M.refresh(GameTooltip)
 M.receive('WD114|'..late..'|9003876|ok|0|100|200|10|1|0|0|10000')
 assert(GameTooltipTextRight3.text~='10 sec Cooldown')
end
print('PASS WD127F: '..cases..' potion rank/locale/build cases, Right header, Left description, green values, rebuild, stale replies, missing field and independent HoT duration')
'''
(P/'checks/potion_numeric_test.lua').write_text(test,encoding='utf-8')
src=P/'01_覆盖到源代码根目录'
s=(src/'src/server/game/Spells/Spell.cpp').read_text(encoding='utf-8-sig')
block=s[s.index('    SendSpellGo();',s.index('// WD63E:')-100):s.index('    bool resetAttackTimers',s.index('// WD63E:'))]
assert block.index('SendSpellGo();')<block.index('SendClearCooldown')<block.index('BuildCooldownPacket')<block.index('SendDirectMessage')
assert all(str(i) in block for i in [9003870,9003876,9003890,9003896,9003897])
assert 'GetSpellCooldownDelay(m_spellInfo->Id)' in block
t=(src/'modules/mod-reborn-witchdoctor/src/RebornWitchDoctorTalents.cpp').read_text(encoding='utf-8-sig')
for line in t.splitlines():
 if 'sequence,id,cost,lo,hi,s->revision,s->active' in line:
  fmt=re.search(r'PSendSysMessage\("([^"]+)"',line)[1]
  args=line.split('"',2)[2].split(',',1)[1].rsplit(');',1)[0]
  # commas nested in std::max do not count as arguments.
  args=re.sub(r'std::max\(0,cooldown\)','cooldown',args)
  assert fmt.count('{}')==len(args.split(',')),line
# Compile the actual delivered post-GO block and signed expressions with MSVC.
probe='''#include <algorithm>
#include <initializer_list>
#include <cstdint>
using uint32=uint32_t; using int32=int32_t;
enum {EFFECT_0, SPELLMOD_COOLDOWN, TRIGGERED_IGNORE_SPELL_AND_CATEGORY_CD, TRIGGERED_IGNORE_EFFECTS, SPELL_COOLDOWN_FLAG_NONE};
struct SpellModifier {int op;};
struct AuraEffect {SpellModifier* GetSpellModifier(){return nullptr;}};
struct Info {uint32 Id=0; bool IsPassive(){return false;} bool IsCooldownStartedOnEvent(){return false;}};
struct WorldPacket {};
struct Player {
 int getClass(){return 13;} bool HasAura(uint32){return true;}
 AuraEffect* GetAuraEffect(uint32,int){return nullptr;}
 bool IsAffectedBySpellmod(Info*,SpellModifier*,void*){return true;}
 uint32 GetSpellCooldownDelay(uint32){return 10000;}
 void SendClearCooldown(uint32,Player*){} void BuildCooldownPacket(WorldPacket&,int,uint32,uint32){} void SendDirectMessage(WorldPacket*){}
};
struct Caster {Player* ToPlayer(){return nullptr;}};
struct Spell {Caster* m_caster=nullptr;Info* m_spellInfo=nullptr;void* m_CastItem=nullptr;
 void SendSpellGo(){} bool HasTriggeredCastFlag(int){return false;}
 void Test(){
'''+block+'''} };
constexpr int32 clamp(int32 rec,uint32 base){return std::min<int32>(rec,std::max<int32>(0,int32(base)-5000));}
static_assert(clamp(10000,15000)==10000,"no double reduction");
static_assert(clamp(15000,15000)==10000,"fallback");
static_assert(clamp(8000,15000)==8000,"preserve stronger modifiers");
static_assert(clamp(0,15000)==0,"zero");
'''
Q=Path('D:/000rebornWOW/wd127f_checks');Q.mkdir(exist_ok=True)
(Q/'post_go.cpp').write_text(probe,encoding='utf-8')
shutil.copy2(Q/'post_go.cpp',P/'checks/post_go.cpp')
print(P)
print('PASS packet ordering, both complete rank families, Toss/Splash protocol argument counts')
