// WD161: retain old IDs, manage their ownership only for modern saved builds.
namespace WD161
{
std::vector<Creature*> Wards(Player* p)
{
    std::vector<Creature*> result;if(!IsDoctor(p)||!p->IsInWorld())return result;
    std::vector<ObjectGuid> ids;ids.push_back(p->CustomData.GetDefault<WD21A::State>(WD21A::Key)->guid);
    if(auto* state=p->CustomData.Get<WD150::State>(WD150::Key))ids.insert(ids.end(),state->wards.begin(),state->wards.end());
    if(auto* state=p->CustomData.Get<WD153::State>(WD153::Key))ids.insert(ids.end(),state->wards.begin(),state->wards.end());
    for(ObjectGuid id:ids)if(Creature* c=ObjectAccessor::GetCreature(*p,id))
        if(c->GetEntry()==900190&&c->IsAlive()&&c->GetOwnerGUID()==p->GetGUID()&&p->IsInMap(c)&&p->InSamePhase(c)&&
            std::find(result.begin(),result.end(),c)==result.end())result.push_back(c);
    if(Creature* c=WD160::Viper(p))result.push_back(c);return result;
}
bool HasWard(Player* p){return !Wards(p).empty();}
void Haste(Player* p,bool apply){for(Creature* c:Wards(p))if(apply)p->AddAura(9003533,c);else c->RemoveAurasDueToSpell(9003533,p->GetGUID());}
}
namespace WD161Bridge
{
void Apply(Player* p,bool berserking,bool effigy)
{
    for(auto const& pair:std::array<std::pair<uint32,bool>,2>{{{9003532,berserking},{9003430,effigy}}})
    {
        if(pair.second){if(!p->HasSpell(pair.first))p->learnSpell(pair.first);if(pair.first==9003532&&!p->HasAura(pair.first,p->GetGUID()))p->CastSpell(p,pair.first,true);}
        else {if(pair.first==9003532)WD161::Haste(p,false);p->RemoveAurasDueToSpell(pair.first,p->GetGUID());if(p->HasSpell(pair.first))p->removeSpell(pair.first,3,false);}
    }
    if(!effigy&&p->IsInWorld())if(Creature* c=ObjectAccessor::GetCreature(*p,p->CustomData.GetDefault<WD41A::State>(WD41A::Key)->guid))
        if(c->GetEntry()==900201&&c->GetOwnerGUID()==p->GetGUID())WD41A::Clear(p);
}
}
