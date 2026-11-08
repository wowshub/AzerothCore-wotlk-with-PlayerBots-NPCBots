#include <cassert>
#include <map>
#include <set>
#include <cstdint>

using uint32=uint32_t;
enum{CLASS_HUNTER=3};
#define LOG_ERROR(...)
bool ready=true;
bool GetSkillRaceClassInfo(uint32,int,int){return ready;}
struct SpellMgr{bool GetSpellInfo(uint32){return ready;}} mgr;
auto sSpellMgr=&mgr;
struct Player{
 int race=36,cls=3;std::map<uint32,int> skills;std::set<uint32> spells;
 int getRace(bool){return race;}int getClass(){return cls;}
 bool IsSpellFitByClassAndRace(uint32){return ready;}
 bool HasSkill(uint32 s){return skills.count(s);}
 bool HasSpell(uint32 s){return spells.count(s);}
 void LearnDefaultSkill(uint32 s,int rank){assert(rank==0);skills.emplace(s,1);}
 void learnSpell(uint32 s){spells.insert(s);}
};
void RepairHunterRangedSkills(Player* player)
{
    if (!player || (player->getRace(true) != 36 && player->getRace(true) != 37 &&
        player->getRace(true) != 39 && player->getRace(true) != 49) || player->getClass() != CLASS_HUNTER)
        return;

    static constexpr uint32 skills[] = {45, 46, 226};
    static constexpr uint32 spells[] = {264, 266, 5011, 75};
    for (uint32 skill : skills)
        if (!GetSkillRaceClassInfo(skill, player->getRace(true), player->getClass()))
        {
            LOG_ERROR("module", "RACECLASS1C: Hunter skill {} has no eligible DBC row; repair skipped", skill);
            return;
        }
    for (uint32 spell : spells)
        if (!sSpellMgr->GetSpellInfo(spell) || !player->IsSpellFitByClassAndRace(spell))
        {
            LOG_ERROR("module", "RACECLASS1C: Hunter spell {} missing/ineligible; repair skipped", spell);
            return;
        }
    for (uint32 skill : skills)
        if (!player->HasSkill(skill))
            player->LearnDefaultSkill(skill, 0);
    for (uint32 spell : spells)
        if (!player->HasSpell(spell))
            player->learnSpell(spell);
}

int main(){
 for(int race:{36,37,39,49}){
  Player p;p.race=race;p.skills[45]=143;RepairHunterRangedSkills(&p);
  assert(p.skills[45]==143&&p.skills[46]==1&&p.skills[226]==1&&p.spells.size()==4);
  auto old=p.skills;RepairHunterRangedSkills(&p);assert(p.skills==old&&p.spells.size()==4);
 }
 for(int race:{7,17}){Player p;p.race=race;RepairHunterRangedSkills(&p);assert(p.skills.empty()&&p.spells.empty());}
 Player wrong;wrong.cls=1;RepairHunterRangedSkills(&wrong);assert(wrong.skills.empty());
 ready=false;Player bad;RepairHunterRangedSkills(&bad);assert(bad.skills.empty()&&bad.spells.empty());
 RepairHunterRangedSkills(nullptr);
}
