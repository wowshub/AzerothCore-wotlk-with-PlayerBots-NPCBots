#include "Chat.h"
#include "CommandScript.h"
#include "Config.h"
#include "DatabaseEnv.h"
#include "DBCStores.h"
#include "SpellMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptDefines/PlayerScript.h"
#include "WorldSession.h"

#include <algorithm>
#include <chrono>
#include <string>
#include <unordered_map>
#include <unordered_set>

using namespace Acore::ChatCommands;

namespace
{
struct UnlockQuote
{
    uint32 account;
    uint32 token;
    uint32 price;
    std::string currency;
    std::chrono::steady_clock::time_point created;
};
std::unordered_map<uint32, UnlockQuote> quotes;
uint32 nextQuoteToken = 0;
bool ValidIdentifier(std::string const& value)
{
    return !value.empty() && value.size() <= 64 &&
        std::all_of(value.begin(), value.end(), [](unsigned char c)
        {
            return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') ||
                (c >= '0' && c <= '9') || c == '_';
        });
}

class RebornMonkSpecCommands final : public CommandScript
{
public:
    RebornMonkSpecCommands() : CommandScript("RebornMonkSpecCommands") { }

    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable commands =
        {
            { "monkspecstatus", HandleStatus, SEC_GAMEMASTER, Console::No },
            { "monkspecsave", HandleArchive, SEC_GAMEMASTER, Console::No },
            { "monkspecnew", HandleNewArchive, SEC_GAMEMASTER, Console::No },
            { "monkspeccommit", HandleWorkingSave, SEC_GAMEMASTER, Console::No },
            { "monkspecworking", HandleWorkingInfo, SEC_GAMEMASTER, Console::No },
            { "monkspecview1", HandleViewFirst, SEC_PLAYER, Console::No },
            { "monkspecview2", HandleViewSecond, SEC_PLAYER, Console::No },
            { "monkspecview3", HandleViewThird, SEC_PLAYER, Console::No },
            { "monkspecunlock", HandleBlankThird, SEC_PLAYER, Console::No },
            { "monkspecbuy", HandleBuy, SEC_PLAYER, Console::No },
            { "monkspecgrant", HandleGrant, SEC_GAMEMASTER, Console::No },
            { "monkspecstate", HandleOnlineState, SEC_PLAYER, Console::No },
            { "monkspecgo2", HandleOnlineSecond, SEC_PLAYER, Console::No },
            { "monkspecgo1", HandleOnlineFirst, SEC_PLAYER, Console::No },
            { "monkspecgo3", HandleOnlineThird, SEC_PLAYER, Console::No },
            { "monkspecsaved", HandleArchiveInfo, SEC_GAMEMASTER, Console::No },
            { "monkspeccheck", HandleCheck, SEC_GAMEMASTER, Console::No }
        };
        return commands;
    }



    static bool HandleCheck(ChatHandler* handler)
    {
        Player* player = handler->GetPlayer();
        if (!player || !player->GetSession())
            return false;
        if (!sConfigMgr->GetOption<bool>("RebornMonkSpec.ArchiveTesting", false))
        {
            handler->SendSysMessage("[MONKSPEC4] Archive testing disabled / 存档测试未开启。");
            return true;
        }
        if (player->getClass() != 14)
        {
            handler->SendSysMessage("[MONKSPEC4] Monk required / 仅限武僧。");
            return true;
        }
        uint32 guid = player->GetGUID().GetCounter();
        QueryResult mode = CharacterDatabase.Query("SELECT mode FROM spelldraft_character_mode WHERE guid={}", guid);
        if (!mode || mode->Fetch()[0].Get<uint32>() != 1)
        {
            handler->SendSysMessage("[MONKSPEC4] Classic mode required / 仅限经典模式。");
            return true;
        }
        // One statement obtains the header and all child rows in one DB snapshot.
        QueryResult result = CharacterDatabase.Query(
            "SELECT 0 AS kind,a.format_version AS x,a.source_level AS y,a.source_spec AS z "
            "FROM reborn_monk_spec_archive a WHERE a.guid={0} AND a.account_id={1} "
            "UNION ALL SELECT 1,t.spell,0,0 FROM reborn_monk_spec_archive_talent t "
            "JOIN reborn_monk_spec_archive a ON a.guid=t.guid WHERE a.guid={0} AND a.account_id={1} "
            "UNION ALL SELECT 2,g.slot,g.glyph,0 FROM reborn_monk_spec_archive_glyph g "
            "JOIN reborn_monk_spec_archive a ON a.guid=g.guid WHERE a.guid={0} AND a.account_id={1} "
            "UNION ALL SELECT 3,b.button,b.action,b.type FROM reborn_monk_spec_archive_action b "
            "JOIN reborn_monk_spec_archive a ON a.guid=b.guid WHERE a.guid={0} AND a.account_id={1}",
            guid, player->GetSession()->GetAccountId());
        if (!result)
        {
            handler->SendSysMessage("[MONKSPEC4] No archive or query failure / 无存档或查询失败，请检查SQL日志。");
            return true;
        }
        uint32 errors = 0, warnings = 0, header = 0, spent = 0, glyphs = 0, actions = 0;
        auto error = [&](char const* reason, uint32 id)
        {
            ++errors;
            if (errors <= 20)
                handler->PSendSysMessage("[MONKSPEC4] BLOCK {} ID={}", reason, id);
        };
        std::unordered_map<uint32, uint32> ranks;
        std::unordered_set<uint32> glyphSlots, glyphIds, buttons;
        do
        {
            Field* f = result->Fetch();
            uint32 kind = f[0].Get<uint32>(), x = f[1].Get<uint32>(), y = f[2].Get<uint32>(), z = f[3].Get<uint32>();
            if (kind == 0)
            {
                ++header;
                if (x != 1) error("format / 格式版本无效", x);
                if (z > 1) error("source spec / 来源套数无效", z);
                if (y > player->GetLevel()) error("level decreased / 当前等级低于存档", y);
            }
            else if (kind == 1)
            {
                TalentSpellPos const* pos = GetTalentSpellPos(x);
                TalentEntry const* talent = pos ? sTalentStore.LookupEntry(pos->talent_id) : nullptr;
                TalentTabEntry const* tab = talent ? sTalentTabStore.LookupEntry(talent->TalentTab) : nullptr;
                if (!pos || !talent || !tab || !sSpellMgr->GetSpellInfo(x) || pos->rank >= MAX_TALENT_RANK)
                { error("talent DBC missing / 天赋记录不存在", x); continue; }
                if (!(tab->ClassMask & player->getClassMask())) error("wrong talent class / 天赋职业不符", x);
                if (!ranks.emplace(talent->TalentID, pos->rank + 1).second)
                    error("duplicate talent rank / 同一天赋多个等级", x);
                else
                    spent += pos->rank + 1;
            }
            else if (kind == 2)
            {
                if (x >= MAX_GLYPH_SLOT_INDEX || !glyphSlots.insert(x).second)
                    error("glyph slot / 雕文槽无效", x);
                if (!y) continue;
                ++glyphs;
                GlyphPropertiesEntry const* glyph = sGlyphPropertiesStore.LookupEntry(y);
                if (!glyph) error("GlyphProperties missing / 雕文DBC不存在", y);
                else if (!sSpellMgr->GetSpellInfo(glyph->SpellId)) error("glyph spell missing / 雕文法术不存在", glyph->SpellId);
                if (!glyphIds.insert(y).second) error("duplicate glyph / 重复雕文", y);
            }
            else if (kind == 3)
            {
                ++actions;
                if (x >= MAX_ACTION_BUTTONS || !buttons.insert(x).second || y >= MAX_ACTION_BUTTON_ACTION_VALUE)
                    error("action slot/value / 动作槽或编号无效", x);
                if (z == ACTION_BUTTON_SPELL)
                {
                    if (!sSpellMgr->GetSpellInfo(y)) error("action spell missing / 动作条法术不存在", y);
                }
                else if (z == ACTION_BUTTON_MACRO || z == ACTION_BUTTON_CMACRO || z == ACTION_BUTTON_EQSET || z == ACTION_BUTTON_C)
                    ++warnings; // Client-side references need inspection during restoration.
                else if (z != ACTION_BUTTON_ITEM)
                    error("action type / 动作类型未知", z);
            }
        } while (result->NextRow());
        if (header != 1) error("header count / 存档头数量异常", header);
        if (glyphSlots.size() != MAX_GLYPH_SLOT_INDEX) error("glyph slots incomplete / 雕文槽不完整", uint32(glyphSlots.size()));
        if (spent > player->CalculateTalentsPoints()) error("talent budget / 天赋点超出当前额度", spent);
        for (auto const& rank : ranks)
        {
            TalentEntry const* talent = sTalentStore.LookupEntry(rank.first);
            if (talent->DependsOn)
            {
                auto dependency = ranks.find(talent->DependsOn);
                if (dependency == ranks.end() || dependency->second < talent->DependsOnRank + 1)
                    error("talent prerequisite / 天赋前置不足", rank.first);
            }
            uint32 earlierPoints = 0;
            for (auto const& other : ranks)
            {
                TalentEntry const* previous = sTalentStore.LookupEntry(other.first);
                if (previous->TalentTab == talent->TalentTab && previous->Row < talent->Row)
                    earlierPoints += other.second;
            }
            if (earlierPoints < talent->Row * MAX_TALENT_RANK)
                error("talent tier / 低层天赋点不足，需核对自定义规则", rank.first);
        }
        handler->PSendSysMessage("[MONKSPEC4] Check / 校验: errors={}, client references={}, talents={}, points={}, glyphs={}, actions={}.",
            errors, warnings, uint32(ranks.size()), spent, glyphs, actions);
        handler->SendSysMessage(errors ?
            "[MONKSPEC4] 存档不满足恢复条件，原存档未改动 / Blocked; original archive unchanged." :
            "[MONKSPEC4] 原始存档结构检查通过；雕文与宏仍需核验。此处不查询当前三套 / Original archive structure passed; glyph/macro checks remain; not live builds.");
        return true;
    }

    static bool HandleViewFirst(ChatHandler* h) { return HandleView(h, 0); }
    static bool HandleViewSecond(ChatHandler* h) { return HandleView(h, 1); }
    static bool HandleViewThird(ChatHandler* h) { return HandleView(h, 2); }
    static bool HandleView(ChatHandler* handler, uint8 view)
    {
        Player* player = handler->GetPlayer();
        if (!player) return false;
        if (!player->SetMonkViewSpec(view)) player->SendMonkSpecState();
        return true;
    }
    static bool Eligible(Player* player, ChatHandler* handler)
    {
        if (!player || !player->GetSession()) return false;
        if (player->HasMonkThirdSpec())
        {
            handler->SendSysMessage("[MONKSPEC16] 已开通，保留三套，不重复收费 / Already unlocked; no charge.");
            player->SendTalentsInfoData(false);
            return false;
        }
        if (player->getClass() != 14 || player->GetSpecsCount() != 2 || player->GetLevel() < 10 ||
            player->IsSpecActionLoading() || player->IsMonkSpecCasting() || !player->IsAlive() ||
            player->IsInCombat() || player->IsNonMeleeSpellCast(false) || player->IsInFlight() ||
            player->GetVehicle() || player->GetTransport())
        {
            handler->SendSysMessage("[MONKSPEC16] 需要10级以上已学双天赋的武僧，存活且脱战 / Level10+ dual-spec Monk, alive and out of combat required.");
            return false;
        }
        uint32 const guid = player->GetGUID().GetCounter();
        QueryResult check = CharacterDatabase.Query(
            "SELECT (SELECT COUNT(*) FROM spelldraft_character_mode WHERE guid={0} AND mode=1),"
            "(SELECT COUNT(*) FROM character_talent WHERE guid={0} AND specMask & 4),"
            "(SELECT COUNT(*) FROM character_glyphs WHERE guid={0} AND talentGroup=2),"
            "(SELECT COUNT(*) FROM character_action WHERE guid={0} AND spec=2),"
            "(SELECT COUNT(*) FROM character_spell WHERE guid={0} AND specMask<>255 AND specMask & 4),"
            "(SELECT COUNT(*) FROM reborn_monk_spec8_backup WHERE guid={0} AND state=1)", guid);
        if (!check)
        {
            handler->SendSysMessage("[MONKSPEC16] 数据检查失败，未扣费 / Database check failed; no charge.");
            return false;
        }
        Field* f = check->Fetch();
        if (f[0].Get<uint64>() != 1 || f[1].Get<uint64>() || f[2].Get<uint64>() ||
            f[3].Get<uint64>() || f[4].Get<uint64>() || f[5].Get<uint64>())
        {
            handler->SendSysMessage("[MONKSPEC16] 仅Classic模式；旧迁移或第三套数据需先核对，未扣费 / Classic only; existing migration/third data needs review; no charge.");
            return false;
        }
        return true;
    }

    // A durable VP receipt is an entitlement, not an instruction to pay again.
    static bool RecoverVP(Player* player, ChatHandler* handler)
    {
        QueryResult result = CharacterDatabase.Query(
            "SELECT COUNT(*) FROM reborn_monk_spec16_vp_receipt WHERE guid={} AND account_id={}",
            player->GetGUID().GetCounter(), player->GetSession()->GetAccountId());
        if (!result)
        {
            handler->SendSysMessage("[MONKSPEC16] 请先导入本阶段导入1.sql；开通未执行 / Install this stage's SQL first; unlock not performed.");
            return true; // Fail closed: never fall through and charge on a query error.
        }
        if (!result->Fetch()[0].Get<uint64>()) return false;
        if (Eligible(player, handler) && player->EnableBlankMonkThirdSpec())
            handler->SendSysMessage("[MONKSPEC16] 已按原VP购买记录补办第三套，未再次扣费 / Third build restored from purchase receipt; no new charge.");
        return true;
    }

    static bool HandleBlankThird(ChatHandler* handler)
    {
        Player* player = handler->GetPlayer();
        if (!Eligible(player, handler)) return true;
        if (RecoverVP(player, handler)) return true;
        auto const currency = sConfigMgr->GetOption<std::string>("RebornMonkSpec.UnlockCurrency", "gold");
        uint32 const price = sConfigMgr->GetOption<uint32>("RebornMonkSpec.UnlockPrice", 1000);
        bool const open = sConfigMgr->GetOption<bool>("RebornMonkSpec.UnlockEnabled", false);
        if (!open || (currency != "gold" && currency != "vp" && currency != "free") ||
            (currency == "gold" && (price == 0 || price > 200000)) ||
            (currency == "vp" && (price == 0 || price > 2000000000)) ||
            (currency == "free" && price != 0))
        {
            handler->SendSysMessage("[MONKSPEC16] 第三套开通未开放或价格配置无效 / Third-build purchase closed or invalid price configuration.");
            return true;
        }
        uint32 const token = ++nextQuoteToken;
        quotes[player->GetGUID().GetCounter()] = {player->GetSession()->GetAccountId(), token, price, currency, std::chrono::steady_clock::now()};
        handler->PSendSysMessage("[MONKSPEC16] QUOTE={} CURRENCY={} PRICE={}",token,currency,price);
        return true;
    }

    static bool HandleBuy(ChatHandler* handler, uint32 token)
    {
        Player* player = handler->GetPlayer();
        if (!player || !player->GetSession()) return false;
        auto it = quotes.find(player->GetGUID().GetCounter());
        if (it == quotes.end() || it->second.token != token || it->second.account != player->GetSession()->GetAccountId())
        {
            handler->SendSysMessage("[MONKSPEC16] 请重新点击第三图标获取价格 / Click the third icon for a fresh quote.");
            return true;
        }
        UnlockQuote quote = it->second;
        quotes.erase(it); // Single use even if validation fails.
        if (std::chrono::steady_clock::now() - quote.created > std::chrono::seconds(60) ||
            !sConfigMgr->GetOption<bool>("RebornMonkSpec.UnlockEnabled", false) ||
            quote.currency != sConfigMgr->GetOption<std::string>("RebornMonkSpec.UnlockCurrency", "gold") ||
            quote.price != sConfigMgr->GetOption<uint32>("RebornMonkSpec.UnlockPrice", 1000))
        {
            handler->SendSysMessage("[MONKSPEC16] 价格已变更或报价过期，未扣费 / Price changed or quote expired; no charge.");
            return true;
        }
        if (!Eligible(player, handler) || RecoverVP(player, handler)) return true;
        if (quote.currency == "vp")
        {
            if (sConfigMgr->GetOption<std::string>("RebornMonkSpec.WalletDatabase", "sahtout_site") != "sahtout_site")
            {
                handler->SendSysMessage("[MONKSPEC16] VP钱包配置与安装SQL不一致，未扣费 / VP wallet config does not match installed SQL; no charge.");
                return true;
            }
            QueryResult receipt = CharacterDatabase.Query("CALL reborn_monk_spec16_buy_vp({},{},{})",
                player->GetGUID().GetCounter(),player->GetSession()->GetAccountId(),quote.price);
            if (!receipt)
            {
                handler->SendSysMessage("[MONKSPEC16] 购买结果未确认；重新点击将先核对记录 / Purchase result unconfirmed; clicking again checks the receipt first.");
                return true;
            }
            uint32 const result = uint32(receipt->Fetch()[0].Get<uint64>());
            if (result != 1 && result != 2)
            {
                handler->SendSysMessage("[MONKSPEC16] VP不足、角色不匹配或数据库检查失败，未开通 / Insufficient VP, character mismatch or database failure; not unlocked.");
                return true;
            }
        }
        uint32 const copper = quote.currency == "gold" ? quote.price * 10000u : 0;
        if (player->GetMoney() < copper)
        {
            handler->SendSysMessage("[MONKSPEC16] 金币不足，未扣费 / Insufficient gold; no charge.");
            return true;
        }
        uint32 const goldBefore = player->GetMoney();
        if (copper && (!player->ModifyMoney(-int32(copper)) || player->GetMoney() != goldBefore - copper))
        {
            player->SetMoney(goldBefore);
            handler->SendSysMessage("[MONKSPEC16] 金币扣除未成功，未开通 / Gold debit failed; not unlocked.");
            return true;
        }
        if (!player->EnableBlankMonkThirdSpec())
        {
            if (copper) player->SetMoney(goldBefore);
            handler->SendSysMessage("[MONKSPEC16] 开通未完成；金币已退回，VP购买可凭记录补办 / Unlock incomplete; gold restored, VP purchase recoverable from receipt.");
            return true;
        }
        handler->SendSysMessage("[MONKSPEC16] 空白第三套已开通；第一、第二套保留，切换不再收费 / Blank third unlocked; first and second retained; switching is free.");
        return true;
    }

    static bool HandleGrant(ChatHandler* handler)
    {
        Player* gm = handler->GetPlayer();
        if (!gm || !gm->GetSession() || gm->GetSession()->GetSecurity() < SEC_GAMEMASTER) return false;
        Player* player = handler->getSelectedPlayer();
        if (!player) player = handler->GetPlayer();
        if (!Eligible(player, handler)) return true;
        if (player->EnableBlankMonkThirdSpec())
            handler->SendSysMessage("[MONKSPEC16] GM已免费开通选中角色第三套 / GM granted selected character a free third build.");
        return true;
    }
    static bool HandleOnlineFirst(ChatHandler* handler) { return HandleOnlineSwitch(handler, 0); }
    static bool HandleOnlineSecond(ChatHandler* handler) { return HandleOnlineSwitch(handler, 1); }
    static bool HandleOnlineThird(ChatHandler* handler) { return HandleOnlineSwitch(handler, 2); }
    static bool HandleOnlineState(ChatHandler* handler)
    {
        Player* player = handler->GetPlayer();
        if (!player) return false;
        player->SendTalentsInfoData(false);
        return true;
    }
    static bool HandleOnlineSwitch(ChatHandler* handler, uint8 target)
    {
        Player* player = handler->GetPlayer();
        if (!player || !player->GetSession()) return false;
        if (!sConfigMgr->GetOption<bool>("RebornMonkSpec.OnlineTesting", false) || !player->HasMonkThirdSpec())
        {
            handler->SendSysMessage("[MONKSPEC13] 请先完成三套迁移并开启OnlineTesting / Complete three-build migration and enable OnlineTesting.");
            player->SendMonkSpecState();
            return true;
        }
        if (player->IsSpecActionLoading() || !player->IsAlive() || player->IsInCombat() ||
            player->IsNonMeleeSpellCast(false) || player->IsInFlight() || player->GetVehicle() || player->GetTransport())
        {
            handler->SendSysMessage("[MONKSPEC13] 正在加载或当前状态不能切换 / Loading or invalid switch state.");
            player->SendMonkSpecState();
            return true;
        }
        if (target >= 3 || player->GetActiveSpec() == target)
        {
            player->SendTalentsInfoData(false);
            return true;
        }
        if (!player->StartMonkSpecCast(target))
        {
            handler->SendSysMessage("[MONKSPEC15] 未能开始切换，请检查当前状态。 / Could not start the switch; check your current state.");
            player->SendMonkSpecState();
        }
        return true;
    }

    static bool HandleWorkingSave(ChatHandler* handler)
    {
        Player* player = handler->GetPlayer();
        if (!player || !player->GetSession()) return false;
        if (player->IsSpecActionLoading())
        {
            handler->SendSysMessage("[MONKSPEC11] 动作条加载中，暂不保存 / Actions loading; save after completion.");
            return true;
        }
        if (!sConfigMgr->GetOption<bool>("RebornMonkSpec.WorkingArchiveTesting", false))
        {
            handler->SendSysMessage("[MONKSPEC9] 回存测试未开启 / Working save testing disabled.");
            return true;
        }
        if (player->getClass() != 14 || !player->IsAlive() || player->IsInCombat() ||
            player->IsNonMeleeSpellCast(false) ||
            !(player->HasMonkThirdSpec() ? player->GetActiveSpec() == 2 : (player->GetSpecsCount() == 2 && player->GetActiveSpec() == 1)))
        {
            handler->SendSysMessage("[MONKSPEC9] 请激活第三方案并脱战停止施法 / Activate the third build, out of combat and casting.");
            return true;
        }
        uint32 guid = player->GetGUID().GetCounter();
        uint32 account = player->GetSession()->GetAccountId();
        QueryResult ready = CharacterDatabase.Query(
            "SELECT b.guid FROM reborn_monk_spec8_backup b "
            "JOIN spelldraft_character_mode m ON m.guid=b.guid "
            "WHERE b.guid={} AND b.account_id={} AND b.state=1 AND b.source_spec=0 AND b.target_spec=1 AND m.mode=1", guid, account);
        if (!ready)
        {
            handler->SendSysMessage("[MONKSPEC9] 未找到本角色已应用的SPEC8备份，或查询失败；请勿对普通第二套回存 / Applied SPEC8 backup required; check SQL log.");
            return true;
        }
        for (uint8 slot = 0; slot < MAX_GLYPH_SLOT_INDEX; ++slot)
        {
            uint32 id = player->GetGlyph(slot);
            if (!id) continue;
            GlyphPropertiesEntry const* glyph = sGlyphPropertiesStore.LookupEntry(id);
            if (!glyph || !sSpellMgr->GetSpellInfo(glyph->SpellId))
            {
                handler->PSendSysMessage("[MONKSPEC9] 无效雕文，未回存 / Invalid glyph: {}", id);
                return true;
            }
        }
        // Each save is a new immutable revision. One transaction owns one DB connection;
        // LAST_INSERT_ID() refers to this header, never another session's revision.
        auto transaction = CharacterDatabase.BeginTransaction();
        transaction->Append("INSERT INTO reborn_monk_spec_working (guid,account_id,format_version,source_spec,source_level,free_points) VALUES ({},{},1,1,{},{})",
            guid, account, player->GetLevel(), player->GetFreeTalentPoints());
        uint32 talents = 0, glyphs = 0, actions = 0;
        for (auto const& entry : player->GetTalentMap())
        {
            if (entry.second->State == PLAYERSPELL_REMOVED || !(entry.second->specMask & player->GetActiveSpecMask())) continue;
            transaction->Append("INSERT INTO reborn_monk_spec_working_talent (revision,spell) VALUES (LAST_INSERT_ID(),{})", entry.first);
            ++talents;
        }
        for (uint8 slot = 0; slot < MAX_GLYPH_SLOT_INDEX; ++slot)
        {
            uint32 glyph = player->GetGlyph(slot);
            transaction->Append("INSERT INTO reborn_monk_spec_working_glyph (revision,slot,glyph) VALUES (LAST_INSERT_ID(),{},{})", uint32(slot), glyph);
            if (glyph) ++glyphs;
        }
        for (uint8 button = 0; button < MAX_ACTION_BUTTONS; ++button)
        {
            ActionButton const* action = player->GetActionButton(button);
            if (!action) continue;
            transaction->Append("INSERT INTO reborn_monk_spec_working_action (revision,button,action,type) VALUES (LAST_INSERT_ID(),{},{},{})",
                uint32(button), action->GetAction(), uint32(action->GetType()));
            ++actions;
        }
        WorldSession* session = player->GetSession();
        session->AddTransactionCallback(CharacterDatabase.AsyncCommitTransaction(transaction))
            .AfterComplete([session, guid, talents, glyphs, actions](bool success)
            {
                if (!session->GetPlayer() || session->GetPlayer()->GetGUID().GetCounter() != guid) return;
                ChatHandler response(session);
                if (success)
                    response.PSendSysMessage("[MONKSPEC9] 已新增第三方案工作版本 / Working revision saved: talents={}, glyphs={}, actions={}. 原存档及备份保留，未切换未扣款 / Originals retained; no switch or charge.", talents, glyphs, actions);
                else
                    response.SendSysMessage("[MONKSPEC9] 回存失败，旧版本保留；检查角色库SQL / Save failed; previous revisions retained. Check SQL log.");
            });
        handler->SendSysMessage("[MONKSPEC9] 正在提交工作版本，请等待结果 / Working save pending.");
        return true;
    }

    static bool HandleWorkingInfo(ChatHandler* handler)
    {
        Player* player = handler->GetPlayer();
        if (!player || !player->GetSession()) return false;
        if (!sConfigMgr->GetOption<bool>("RebornMonkSpec.WorkingArchiveTesting", false))
        {
            handler->SendSysMessage("[MONKSPEC9] 回存测试未开启 / Working save testing disabled.");
            return true;
        }
        QueryResult result = CharacterDatabase.Query(
            "SELECT a.revision,a.source_level,a.free_points,"
            "(SELECT COUNT(*) FROM reborn_monk_spec_working_talent t WHERE t.revision=a.revision),"
            "(SELECT COUNT(*) FROM reborn_monk_spec_working_glyph g WHERE g.revision=a.revision AND g.glyph<>0),"
            "(SELECT COUNT(*) FROM reborn_monk_spec_working_action b WHERE b.revision=a.revision) "
            "FROM reborn_monk_spec_working a WHERE a.guid={} AND a.account_id={} ORDER BY a.revision DESC LIMIT 1",
            player->GetGUID().GetCounter(), player->GetSession()->GetAccountId());
        if (!result)
        {
            handler->SendSysMessage("[MONKSPEC9] 无工作版本或查询失败 / No working revision or query failure; check SQL log.");
            return true;
        }
        Field* f = result->Fetch();
        handler->PSendSysMessage("[MONKSPEC9] 工作版本 / Revision={} level={} free points={} talents={} glyphs={} actions={}. 历史工作版本，只读；不会替换当前方案 / Historical revision; read only, current builds unchanged.",
            f[0].Get<uint64>(), f[1].Get<uint32>(), f[2].Get<uint32>(), f[3].Get<uint32>(), f[4].Get<uint32>(), f[5].Get<uint32>());
        return true;
    }

    static bool HandleArchive(ChatHandler* handler)
    {
        return CreateArchive(handler, false);
    }

    static bool HandleNewArchive(ChatHandler* handler)
    {
        return CreateArchive(handler, true);
    }

    static bool CreateArchive(ChatHandler* handler, bool blank)
    {
        Player* player = handler->GetPlayer();
        if (!player || !player->GetSession())
            return false;
        if (player->IsSpecActionLoading())
        {
            handler->SendSysMessage("[MONKSPEC11] 动作条加载中，暂不保存 / Actions loading; save after completion.");
            return true;
        }
        if (!sConfigMgr->GetOption<bool>("RebornMonkSpec.ArchiveTesting", false))
        {
            handler->SendSysMessage("[MONKSPEC3] 存档测试未开启 / Archive testing disabled.");
            return true;
        }
        if (player->getClass() != 14 || !player->IsAlive() || player->IsInCombat() ||
            player->IsNonMeleeSpellCast(false) || player->GetSpecsCount() < 1 ||
            player->GetSpecsCount() > 2 || player->GetActiveSpec() >= player->GetSpecsCount())
        {
            handler->SendSysMessage("[MONKSPEC3] 仅限存活、脱战且未施法的武僧，原生套数必须正常 / Invalid archive state.");
            return true;
        }
        if (blank && !sConfigMgr->GetOption<bool>("RebornMonkSpec.BlankArchiveTesting", false))
        {
            handler->SendSysMessage("[MONKSPEC7] 空白方案测试未开启 / Blank archive testing disabled.");
            return true;
        }
        // Blank archives do not import current glyphs.
        // Reject invalid nonzero glyphs before creating a new immutable archive.
        for (uint8 slot = 0; !blank && slot < MAX_GLYPH_SLOT_INDEX; ++slot)
        {
            uint32 id = player->GetGlyph(slot);
            if (!id) continue;
            GlyphPropertiesEntry const* glyph = sGlyphPropertiesStore.LookupEntry(id);
            if (!glyph || !sSpellMgr->GetSpellInfo(glyph->SpellId))
            {
                handler->PSendSysMessage("[MONKSPEC4] 无效雕文阻止新存档 / Invalid glyph blocks new archive: slot={}, ID={}. 未删除或修改已有存档。", uint32(slot), id);
                return true;
            }
        }
        uint32 guid = player->GetGUID().GetCounter();
        QueryResult mode = CharacterDatabase.Query(
            "SELECT mode FROM spelldraft_character_mode WHERE guid={}", guid);
        if (!mode || mode->Fetch()[0].Get<uint32>() != 1)
        {
            handler->SendSysMessage("[MONKSPEC3] 仅限经典模式 / Classic mode required.");
            return true;
        }

        // Create-once snapshot. Plain INSERT (never REPLACE) protects an existing
        // archive even under duplicate clicks or concurrent transactions.
        // Read live state: do not call SaveToDB or reset native dirty flags.
        auto transaction = CharacterDatabase.BeginTransaction();
        transaction->Append(
            "INSERT INTO reborn_monk_spec_archive "
            "(guid,account_id,format_version,source_spec,source_level,free_points) "
            "VALUES ({},{},1,{},{},{})", guid, player->GetSession()->GetAccountId(),
            uint32(player->GetActiveSpec()), player->GetLevel(),
            blank ? player->CalculateTalentsPoints() : player->GetFreeTalentPoints());
        uint32 talents = 0, glyphs = 0, actions = 0;
        for (auto const& entry : player->GetTalentMap())
        {
            if (blank) break;
            if (entry.second->State == PLAYERSPELL_REMOVED ||
                !(entry.second->specMask & player->GetActiveSpecMask()))
                continue;
            transaction->Append("INSERT INTO reborn_monk_spec_archive_talent (guid,spell) VALUES ({},{})",
                guid, entry.first);
            ++talents;
        }
        for (uint8 slot = 0; slot < MAX_GLYPH_SLOT_INDEX; ++slot)
        {
            uint32 glyph = blank ? 0 : player->GetGlyph(slot);
            transaction->Append("INSERT INTO reborn_monk_spec_archive_glyph (guid,slot,glyph) VALUES ({},{},{})",
                guid, uint32(slot), glyph);
            if (glyph)
                ++glyphs;
        }
        for (uint8 button = 0; !blank && button < MAX_ACTION_BUTTONS; ++button)
        {
            ActionButton const* action = player->GetActionButton(button);
            if (!action)
                continue;
            transaction->Append("INSERT INTO reborn_monk_spec_archive_action (guid,button,action,type) VALUES ({},{},{},{})",
                guid, uint32(button), action->GetAction(), uint32(action->GetType()));
            ++actions;
        }
        WorldSession* session = player->GetSession();
        session->AddTransactionCallback(CharacterDatabase.AsyncCommitTransaction(transaction))
            .AfterComplete([session, guid, talents, glyphs, actions, blank](bool success)
            {
                // Session owns the callback; do not retain a Player or ChatHandler.
                if (!session->GetPlayer() || session->GetPlayer()->GetGUID().GetCounter() != guid)
                    return;
                ChatHandler response(session);
                if (success && blank)
                    response.SendSysMessage("[MONKSPEC7] 空白第三方案已保存：天赋、雕文、动作条均为空；点数按等级及服务器规则计算。尚未激活、未扣款 / Blank archive saved; no activation or charge.");
                else if (success)
                    response.PSendSysMessage("[MONKSPEC3] 已保存第三方案存档 / Archive saved: talents={}, glyphs={}, actions={}. 未切换、未扣款 / No switch or charge.",
                        talents, glyphs, actions);
                else
                    response.SendSysMessage("[MONKSPEC3] 未新增存档：可能已存在或数据库出错；旧存档未覆盖 / Archive not created; check existing archive and server SQL log.");
            });
        handler->SendSysMessage("[MONKSPEC3] 正在提交存档，请等待结果 / Archive pending.");
        return true;
    }

    static bool HandleArchiveInfo(ChatHandler* handler)
    {
        Player* player = handler->GetPlayer();
        if (!player || !player->GetSession())
            return false;
        if (!sConfigMgr->GetOption<bool>("RebornMonkSpec.ArchiveTesting", false))
        {
            handler->SendSysMessage("[MONKSPEC3] 存档测试未开启 / Archive testing disabled.");
            return true;
        }
        QueryResult result = CharacterDatabase.Query(
            "SELECT a.guid,a.format_version,a.source_spec,a.source_level,"
            "(SELECT COUNT(*) FROM reborn_monk_spec_archive_talent t WHERE t.guid=a.guid),"
            "(SELECT COUNT(*) FROM reborn_monk_spec_archive_glyph g WHERE g.guid=a.guid AND g.glyph<>0),"
            "(SELECT COUNT(*) FROM reborn_monk_spec_archive_action b WHERE b.guid=a.guid) "
            "FROM reborn_monk_spec_archive a WHERE a.guid={} AND a.account_id={}",
            player->GetGUID().GetCounter(), player->GetSession()->GetAccountId());
        if (!result)
        {
            handler->SendSysMessage("[MONKSPEC3] 未查到存档，或查询失败 / No archive or query failed; check SQL installation/log.");
            return true;
        }
        Field* f = result->Fetch();
        handler->PSendSysMessage("[MONKSPEC3] 存档 / Archive: version={}, source spec={}, level={}, talents={}, glyphs={}, actions={}. 原始历史存档，只读 / Original historical archive; read only.",
            f[1].Get<uint32>(), f[2].Get<uint32>() + 1, f[3].Get<uint32>(),
            f[4].Get<uint32>(), f[5].Get<uint32>(), f[6].Get<uint32>());
        return true;
    }

    static bool HandleStatus(ChatHandler* handler)
    {
        Player* player = handler->GetPlayer();
        if (!player || !player->GetSession())
            return false;

        if (!sConfigMgr->GetOption<bool>("RebornMonkSpec.Diagnostics", false))
        {
            handler->SendSysMessage("[MONKSPEC2] Diagnostics disabled / 诊断未开启。");
            return true;
        }

        handler->PSendSysMessage("[MONKSPEC2] 原生套数 / Native count: {}; 当前 / Active: {}; 第三套收费未接入 / Third-slot purchase unavailable.",
            uint32(player->GetSpecsCount()), uint32(player->GetActiveSpec()) + 1);

        std::string database = sConfigMgr->GetOption<std::string>(
            "RebornMonkSpec.WalletDatabase", "sahtout_site");
        if (!ValidIdentifier(database))
        {
            handler->SendSysMessage("[MONKSPEC2] Invalid wallet database / 钱包数据库配置无效。");
            return true;
        }

        // Exactly one row for the current account, including the no-wallet case.
        // The audited schema has a PRIMARY KEY on account_id. Never use username.
        QueryResult result = LoginDatabase.Query(
            "SELECT IF(w.account_id IS NULL,0,1), COALESCE(w.points,0) "
            "FROM (SELECT {} AS account_id) a "
            "LEFT JOIN `{}`.`user_currencies` w ON w.account_id=a.account_id",
            player->GetSession()->GetAccountId(), database);
        if (!result)
        {
            handler->SendSysMessage("[MONKSPEC2] Wallet unavailable / 钱包查询失败；不是余额为零，请检查数据库及权限。");
            return true;
        }

        Field* fields = result->Fetch();
        if (!fields[0].Get<uint32>())
        {
            handler->SendSysMessage("[MONKSPEC2] No account wallet / 当前账号尚无钱包记录。");
            return true;
        }

        handler->PSendSysMessage("[MONKSPEC2] 当前账号共享 VP / Account-shared VP: {}. 本次未扣款 / No charge.",
            fields[1].Get<uint32>());
        return true;
    }
};

class RebornMonkSpecPurchaseRecovery final : public PlayerScript
{
public:
    RebornMonkSpecPurchaseRecovery() : PlayerScript("RebornMonkSpecPurchaseRecovery") { }
    void OnPlayerLogin(Player* player) override
    {
        if (player->getClass() != 14 || player->HasMonkThirdSpec() || player->GetSpecsCount() != 2) return;
        ChatHandler handler(player->GetSession());
        RebornMonkSpecCommands::RecoverVP(player, &handler);
    }
    void OnPlayerLogout(Player* player) override
    {
        quotes.erase(player->GetGUID().GetCounter());
    }
};
}

void AddRebornMonkSpecScripts()
{
    new RebornMonkSpecCommands();
    new RebornMonkSpecPurchaseRecovery();
}
