#include "Config.h"
#include "DBCStores.h"
#include "DatabaseEnv.h"
#include "Log.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptDefines/WorldScript.h"
#include "SpellInfo.h"
#include "SpellMgr.h"

#include <algorithm>
#include <cctype>
#include <map>
#include <sstream>
#include <string>

namespace
{
struct GlyphIdentity
{
    uint32 PropertyId = 0;
    uint32 SpellId = 0;
    uint32 TypeFlags = 0;
};

bool IsEnabled()
{
    return sConfigMgr->GetOption<bool>("SpellDraft.Enable", true) &&
        sConfigMgr->GetOption<bool>("SpellDraft.GlyphCollection.Enable", true);
}

bool ResolveGlyph(ItemTemplate const* itemTemplate, GlyphIdentity& out)
{
    if (!itemTemplate || itemTemplate->Class != ITEM_CLASS_GLYPH)
        return false;

    for (uint8 spellIndex = 0; spellIndex < MAX_ITEM_PROTO_SPELLS; ++spellIndex)
    {
        SpellInfo const* applySpell = sSpellMgr->GetSpellInfo(itemTemplate->Spells[spellIndex].SpellId);
        if (!applySpell)
            continue;

        for (SpellEffectInfo const& effect : applySpell->GetEffects())
        {
            if (effect.Effect != SPELL_EFFECT_APPLY_GLYPH || effect.MiscValue <= 0)
                continue;

            GlyphPropertiesEntry const* glyph = sGlyphPropertiesStore.LookupEntry(uint32(effect.MiscValue));
            if (!glyph || !glyph->SpellId)
                continue;

            out.PropertyId = glyph->Id;
            out.SpellId = glyph->SpellId;
            out.TypeFlags = glyph->TypeFlags;
            return true;
        }
    }
    return false;
}

std::string Lower(std::string value)
{
    std::transform(value.begin(), value.end(), value.begin(),
        [](unsigned char ch) { return char(std::tolower(ch)); });
    return value;
}

bool HasAny(std::string const& text, std::initializer_list<char const*> words)
{
    for (char const* word : words)
        if (text.find(word) != std::string::npos)
            return true;
    return false;
}

std::string ClassifyGlyph(std::string const& itemName, std::string const& effectName, uint32 typeFlags)
{
    std::string text = Lower(itemName + " " + effectName);
    if (HasAny(text, {"orca", "bear", "lynx", "wolf", "penguin", "polymorph", "appearance", "form"}))
        return "appearance";
    if (HasAny(text, {"pet", "imp", "voidwalker", "succubus", "felhunter", "felguard", "demon", "ghoul", "gargoyle", "elemental", "treant", "spirit wolf"}))
        return "pet";
    if (HasAny(text, {"heal", "rejuvenation", "regrowth", "lifebloom", "renew", "penance", "prayer", "riptide", "holy light", "flash of light", "earth shield"}))
        return "healing";
    if (HasAny(text, {"shield", "armor", "barkskin", "survival instincts", "icebound", "fortitude", "pain suppression", "guardian spirit", "divine protection", "evasion", "cloak of shadows", "block", "parry"}))
        return "defense";
    if (HasAny(text, {"mana", "rage", "energy", "runic", "life tap", "innervate", "water shield", "wisdom", "focus", "rune"}))
        return "resource";
    if (HasAny(text, {"stun", "root", "fear", "hex", "polymorph", "sap", "blind", "cyclone", "trap", "chains", "strangulate", "silence", "death grip", "interrupt"}))
        return "control";
    return typeFlags == 1 ? "utility" : "damage";
}

void RebuildCatalog()
{
    if (!IsEnabled())
        return;

    struct CatalogCandidate
    {
        ItemTemplate const* Item = nullptr;
        GlyphIdentity Glyph;
    };

    // The collection authority is glyph_spell_id, not the paper item. A few
    // 3.3.5 items point at the same final aura (for example two Raise Dead
    // carriers), so keep one deterministic, lowest-ItemID display row.
    std::map<uint32, CatalogCandidate> canonical;
    ItemTemplateContainer const* store = sObjectMgr->GetItemTemplateStore();
    for (auto const& pair : *store)
    {
        ItemTemplate const& item = pair.second;
        GlyphIdentity glyph;
        if (!ResolveGlyph(&item, glyph))
            continue;
        auto found = canonical.find(glyph.SpellId);
        if (found == canonical.end() || item.ItemId < found->second.Item->ItemId)
            canonical[glyph.SpellId] = { &item, glyph };
    }

    std::ostringstream values;
    uint32 count = 0;
    for (auto const& pair : canonical)
    {
        ItemTemplate const& item = *pair.second.Item;
        GlyphIdentity const& glyph = pair.second.Glyph;
        SpellInfo const* effect = sSpellMgr->GetSpellInfo(glyph.SpellId);
        std::string effectName = effect && effect->SpellName[LOCALE_enUS] ? effect->SpellName[LOCALE_enUS] : "";
        std::string itemName = item.Name1;
        WorldDatabase.EscapeString(itemName);
        WorldDatabase.EscapeString(effectName);
        std::string category = ClassifyGlyph(itemName, effectName, glyph.TypeFlags);

        if (count++)
            values << ',';
        values << '(' << item.ItemId << ',' << glyph.SpellId << ',' << glyph.PropertyId << ','
               << glyph.TypeFlags << ',' << item.Quality << ',' << item.AllowableClass << ",'"
               << itemName << "','" << effectName << "','" << category << "')";
    }

    WorldDatabase.DirectExecute("DELETE FROM spelldraft_glyph_catalog");
    if (count)
        WorldDatabase.DirectExecute(
            "INSERT INTO spelldraft_glyph_catalog "
            "(item_id, glyph_spell_id, glyph_property_id, glyph_type, quality, class_mask, item_name, effect_name, category_key) VALUES " + values.str());
    LOG_INFO("module", "[SpellDraft] Rebuilt glyph collection catalog with {} unique glyph spells.", count);
}
}

class SpellDraftGlyphCollectionWorldScript : public WorldScript
{
public:
    SpellDraftGlyphCollectionWorldScript() : WorldScript("SpellDraftGlyphCollectionWorldScript", { WORLDHOOK_ON_STARTUP }) { }
    void OnStartup() override { RebuildCatalog(); }
};

void AddSpellDraftGlyphCollectionScripts()
{
    new SpellDraftGlyphCollectionWorldScript();
}
