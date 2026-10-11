#include "ScriptMgr.h"
#include "Chat.h"
#include "Player.h"
#include "Creature.h"
#include "Group.h"
#include "ObjectAccessor.h"
#include "WorldSession.h"
#include "WorldPacket.h"
#include "PlayerbotAI.h"
#include "Playerbots.h"
#include "botmgr.h"
#include "bot_ai.h"
#include "DataMap.h"
#include <chrono>
#include <sstream>

namespace RebornCompanions
{
struct Rate : public DataMap::Base { std::chrono::steady_clock::time_point next{}; };
static void Send(Player* p, uint32 request, std::string const& body)
{
    WorldPacket packet;
    ChatHandler::BuildChatPacket(packet, CHAT_MSG_WHISPER, LANG_ADDON, p, p,
        "RBCOMP1\t" + std::to_string(request) + "|" + body);
    p->GetSession()->SendPacket(&packet);
}
static std::string Hex(std::string const& text)
{
    static char const* digits="0123456789abcdef";
    std::string out;
    for (unsigned char c : text) { out+=digits[c>>4];out+=digits[c&15]; }
    return out;
}
class Commands : public CommandScript
{
public:
    Commands() : CommandScript("reborn_companion_commands") {}
    static bool Handle(ChatHandler* handler, uint32 request, std::string ownerName, std::string action, uint32 entry)
    {
        Player* caller=handler->GetSession()->GetPlayer();
        auto fail=[&](char const* reason) { Send(caller,request,std::string("E|")+reason);return true; };
        auto* rate=caller->CustomData.GetDefault<Rate>("RebornCompanions.Rate");
        auto now=std::chrono::steady_clock::now();
        if (now<rate->next) return fail("BUSY");
        rate->next=now+std::chrono::milliseconds(600);
        if (action!="list" && action!="hide" && action!="show" && action!="stay" && action!="follow") return fail("ACTION");
        Player* owner=ObjectAccessor::FindPlayerByName(ownerName);
        if (!owner || !owner->IsInWorld()) return fail("OFFLINE");
        // Same map avoids accessing another map's bot manager from this map context.
        if (!owner->IsInMap(caller)) return fail("MAP");
        auto* ai=GET_PLAYERBOT_AI(owner);
        if (owner==caller || !ai || ai->IsRealPlayer() || ai->GetMaster()!=caller ||
            !caller->GetGroup() || caller->GetGroup()!=owner->GetGroup()) return fail("OWNER");
        if (!owner->HaveBot()) { Send(caller,request,"B|0|2");Send(caller,request,"D|0");return true; }
        BotMgr* mgr=owner->GetBotMgr();
        auto const* bots=mgr->GetBotMap();
        Creature* selected=nullptr;
        if (entry) for (auto const& pair:*bots)
            if (pair.second->GetEntry()==entry) { selected=pair.second;break; }
        if (entry && (!selected || selected->IsTempBot())) return fail("MISSING");
        if (action!="list")
        {
            if (!caller->IsAlive() || !owner->IsAlive()) return fail("DEAD");
            if (caller->IsInCombat() || mgr->IsPartyInCombat(false)) return fail("COMBAT");
            if (owner->IsBeingTeleported() || owner->IsInFlight()) return fail("TRAVEL");
            if (action=="stay" || action=="follow")
            {
                // Movement commands are explicit per companion, never silently wake hidden bots.
                if (!selected) return fail("SELECT");
                if (mgr->GetBotsHidden() || mgr->IsBotIndividuallyHidden(selected->GetGUID()) ||
                    !selected->IsInWorld() || !selected->IsAlive() || selected->GetBotAI()->IsDuringTeleport()) return fail("HIDDEN");
                selected->GetBotAI()->SetBotCommandState(action=="stay" ? BOT_COMMAND_STAY : BOT_COMMAND_FOLLOW);
            }
            else
            {
                bool hidden=action=="hide";
                if (selected) mgr->SetBotHidden(selected->GetGUID(),hidden);
                else for (auto const& pair:*bots)
                    if (!pair.second->IsTempBot()) mgr->SetBotHidden(pair.first,hidden);
            }
        }
        uint32 count=0;
        for (auto const& pair:*bots) if (!pair.second->IsTempBot()) ++count;
        Send(caller,request,"B|"+std::to_string(count)+"|2");
        for (auto const& pair:*bots)
        {
            Creature* bot=pair.second;
            if (bot->IsTempBot()) continue;
            bool hidden=mgr->GetBotsHidden() || mgr->IsBotIndividuallyHidden(pair.first);
            // Flag is desired state; in-world flag exposes pending teleport separately.
            Send(caller,request,"R|"+std::to_string(bot->GetEntry())+"|"+
                std::to_string(bot->GetBotClass())+"|"+(hidden?"1":"0")+"|"+
                (bot->IsInWorld()?"1":"0")+"|"+(bot->GetBotAI()->HasBotCommandState(BOT_COMMAND_STAY)?"1":"0")+"|"+Hex(bot->GetName().substr(0,80)));
        }
        Send(caller,request,"D|"+std::to_string(count));
        return true;
    }
    Acore::ChatCommands::ChatCommandTable GetCommands() const override
    {
        using namespace Acore::ChatCommands;
        static ChatCommandTable commands={{"rcompanions",Handle,SEC_PLAYER,Console::No}};
        return commands;
    }
};
}
void Addmod_reborn_companionsScripts() { new RebornCompanions::Commands(); }
