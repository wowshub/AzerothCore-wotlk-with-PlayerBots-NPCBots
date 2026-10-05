// WD87B: read-only owner status. Included after WD68A; no SQL registration.
namespace WD87B
{
struct Status : DataMap::Base
{
    uint32 lifetime=0;
    std::chrono::steady_clock::time_point lastRequest{};
};
constexpr char Key[]="RebornWD87B.Status";
void Snapshot(Player* player)
{
    SpellInfo const* info=sSpellMgr->GetSpellInfo(WD68A::Mimic);
    SpellInfo const* spirit=sSpellMgr->GetSpellInfo(9003574);
    if (!info || !spirit) return;
    // Reading modifiers must not call ApplySpellMod: that can consume charges.
    int32 bonus=0;
    for (SpellModifier const* mod:player->GetSpellModList(SPELLMOD_DURATION))
        if (mod && (mod->spellId==9003752 || mod->spellId==9003753) && mod->type==SPELLMOD_FLAT)
            bonus+=mod->value;
    uint32 remaining=0, lifetime=0;
    auto* slot=player->CustomData.Get<WD68A::State>(WD68A::Key);
    if (slot && player->IsAlive() && player->HasSpell(WD68A::Mimic))
        for (ObjectGuid guid : {slot->mimic,slot->extra})
        if (Creature* creature=ObjectAccessor::GetCreature(*player,guid))
            if (creature->GetEntry()==WD68A::MimicEntry && creature->GetOwnerGUID()==player->GetGUID() &&
                creature->IsAlive() && creature->IsInWorld() && creature->IsInMap(player) && creature->InSamePhase(player))
                if (TempSummon* summon=creature->ToTempSummon())
                {
                    remaining=std::max(remaining,summon->GetTimer());
                    lifetime=player->CustomData.GetDefault<Status>(Key)->lifetime;
                }
    std::ostringstream out;
    out << "RBWD87B\tS " << info->GetDuration() << ' ' << bonus << ' ' << spirit->GetDuration()
        << ' ' << remaining << ' ' << lifetime;
    WorldPacket packet;
    ChatHandler::BuildChatPacket(packet,CHAT_MSG_WHISPER,LANG_ADDON,player,player,out.str());
    player->GetSession()->SendPacket(&packet);
}
class StatusScript : public PlayerScript
{
public:
    StatusScript():PlayerScript("reborn_wd87b_mimic_status") { }
    bool OnPlayerCanUseChat(Player* player,uint32,uint32 language,std::string& message,Player* receiver) override
    {
        if (language!=LANG_ADDON || message.compare(0,8,"RBWD87B\t")!=0) return true;
        // Consume all packets in this namespace, including attempts to relay forged status.
        if (receiver!=player || !IsDoctor(player) || !player->IsInWorld() || message!="RBWD87B\tQ") return false;
        auto* state=player->CustomData.GetDefault<Status>(Key);
        auto now=std::chrono::steady_clock::now();
        if (now-state->lastRequest<std::chrono::milliseconds(400)) return false;
        state->lastRequest=now;
        Snapshot(player);
        return false;
    }
};
}

// WD89A: read-only evidence; select your Puppet target, then .wdpuppetcheck.
namespace WD89A
{
class Diagnostics : public CommandScript
{
public:
    Diagnostics():CommandScript("reborn_wd89a_puppet_check") { }
    static bool Check(ChatHandler* h)
    {
        Player* p=h->GetSession()->GetPlayer();
        if (!IsDoctor(p)) return true;
        SpellInfo const* info=sSpellMgr->GetSpellInfo(9003688);
        if (!info) return true;
        h->PSendSysMessage("WD89A base_ms={} current_mind_percent={} own_blessing={} expected_now_ms={}",
            info->GetDuration(),WD86A::MindPercent(p),WD86A::Owns(p,WD86A::Blessing)?1:0,WD86A::Duration(p,info->GetDuration()));
        // IsAffectedBySpellmod is read-only; never ApplySpellMod during a diagnostic.
        for (SpellModifier* mod:p->GetSpellModList(SPELLMOD_DURATION))
            h->PSendSysMessage("WD89A duration_mod={} value={} puppet_match={}",mod->spellId,mod->value,p->IsAffectedBySpellmod(info,mod,nullptr)?1:0);
        bool found=false;
        if (Unit* target=p->GetSelectedUnit())
            for (uint32 id=WD68A::PuppetFirst;id<=WD68A::PuppetLast;++id)
                if (Aura* aura=target->GetAura(id,p->GetGUID()))
                {
                    found=true;
                    AuraEffect* effect=aura->GetEffect(EFFECT_0);
                    h->PSendSysMessage("WD89A active_spell={} max_ms={} remaining_ms={} interval_ms={} ticks={}",
                        id,aura->GetMaxDuration(),aura->GetDuration(),effect?effect->GetAmplitude():0,effect?effect->GetTickNumber():0);
                }
        if (!found) h->SendSysMessage("WD89A no owned Shadow Puppets aura on selected target.");
        return true;
    }
    Acore::ChatCommands::ChatCommandTable GetCommands() const override
    {
        using namespace Acore::ChatCommands;
        static ChatCommandTable commands={{"wdpuppetcheck",Check,SEC_PLAYER,Console::No}};
        return commands;
    }
};
}
