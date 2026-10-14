// WD147B: synchronize after native aura updates; inherit the parent lifetime.
// Adapted from upstream SyncSpirits, commit e9913e963e1cd9a275d2387d72ded75da064f464.
namespace WD147
{
constexpr uint32 Spirit = 9003574, FirstOrb = 9004050;
class visuals : public PlayerScript
{
public:
    visuals() : PlayerScript("reborn_wd147_spirit_visuals") { }
    void OnPlayerUpdate(Player* p, uint32) override
    {
        if (!IsDoctor(p) || !p->IsInWorld()) return;
        auto* state=p->CustomData.GetDefault<WD147Diagnostic::State>(WD147Diagnostic::Key);
        ++state->updates;
        Aura* spirit=p->IsAlive()?p->GetAura(Spirit,p->GetGUID()):nullptr;
        uint32 count=spirit?std::min<uint32>(5,spirit->GetStackAmount()):0;
        int32 duration=spirit?spirit->GetDuration():0;
        int32 maximum=spirit?spirit->GetMaxDuration():0;
        for(uint32 i=0;i<5;++i)
        {
            uint32 id=FirstOrb+i;
            if(i>=count) { p->RemoveAurasDueToSpell(id,p->GetGUID()); continue; }
            Aura* shown=p->GetAura(id,p->GetGUID());
            if(!shown)
            {
                if(!sSpellMgr->GetSpellInfo(id)) { ++state->missing; continue; }
                ++state->attempts;
                shown=p->AddAura(id,p);
                if(!shown) { ++state->failures; continue; }
            }
            // Do not reset to the donor's 1000 ms before Unit::_UpdateSpells.
            // Every frame reconciles expiration, dispel, death and reduced stacks.
            if(shown->GetMaxDuration()!=maximum)
                shown->SetMaxDuration(maximum);
            if(shown->GetDuration()!=duration)
                shown->SetDuration(duration);
        }
    }
};
void Register() { new visuals(); }
}
