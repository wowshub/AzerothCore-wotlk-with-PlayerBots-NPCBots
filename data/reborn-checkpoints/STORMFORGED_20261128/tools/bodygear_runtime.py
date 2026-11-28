from pathlib import Path
import json
W=Path('stormforged-intake/bodygear1a');p=Path('helmet-work/src/WoW/Common/ComponentCore/EsteriaAppearance.cpp')
s=p.read_text('utf8');backup=W/'EsteriaAppearance.before-bodygear.cpp'
assert not backup.exists();backup.write_text(s,'utf8')
report=json.loads((W/'geometry-report.json').read_text());male=report['Male']['new_vertices'];female=report['Female']['new_vertices']
marker='static void FitStormforgedEquipment(CCharacterComponent* character) {'
helper='''// STORMFORGEDBODY1A: body armour is composed into texture type1, not
// mounted at a weapon socket. Show only the regions actually covered by gear.
static void FitStormforgedClothing(CCharacterComponent* character, bool female) {
    auto* model = character->m_data.m_model;
    const auto* data = model->m_shared->m_data;
    if (data->m_vertices.m_count != (female ? FEMALE_COUNTu : MALE_COUNTu)) return;
    uint32_t coverage = 0;
    for (unsigned slot = 2; slot <= 9; ++slot) {
        ItemDisplayInfoRec item{};
        if (!character->m_itemDisplayID[slot] || !g_itemDisplayInfoDB.GetRecord(character->m_itemDisplayID[slot], &item)) continue;
        for (unsigned region = 0; region < 8; ++region)
            if (item.m_texture[region] && *item.m_texture[region]) coverage |= 1u << region;
    }
    if (character->m_itemDisplayID[ITEMSLOT_TABARD]) coverage |= (1u << 3) | (1u << 4);
    ItemDisplayInfoRec chest{}, pants{}, cape{};
    unsigned robe = 0;
    if (character->m_itemDisplayID[ITEMSLOT_CHEST] && g_itemDisplayInfoDB.GetRecord(character->m_itemDisplayID[ITEMSLOT_CHEST], &chest))
        robe = chest.m_geosetGroup[2];
    if (!robe && !(character->m_flags & 0x20) && character->m_itemDisplayID[ITEMSLOT_PANTS]
        && g_itemDisplayInfoDB.GetRecord(character->m_itemDisplayID[ITEMSLOT_PANTS], &pants)) robe = pants.m_geosetGroup[2];
    if (robe) coverage |= (1u << 5) | (1u << 6);
    const bool ready = character->m_baseSkinTexture && !character->m_dirtySections && !(character->m_flags & 1);
    for (unsigned region = 0; region < 8; ++region)
        model->SetGeometryVisible(22001u + region, 22001u + region, ready && (coverage & (1u << region)) ? 1 : 0);
    for (unsigned variant = 0; variant < 10; ++variant)
        model->SetGeometryVisible(1301u + variant, 1301u + variant, ready && robe && variant == std::min(robe, 9u) ? 1 : 0);
    unsigned capeVariant = 0;
    bool hasCape = character->m_itemDisplayID[ITEMSLOT_CAPE]
        && g_itemDisplayInfoDB.GetRecord(character->m_itemDisplayID[ITEMSLOT_CAPE], &cape);
    if (hasCape) capeVariant = std::min(static_cast<unsigned>(cape.m_geosetGroup[0]), 9u);
    bool capeReady = false;
    if (hasCape && model->m_textures) {
        for (unsigned i = 0; i < data->m_textures.m_count; ++i)
            if (data->m_textures[i].m_type == 2 && model->m_textures[i]
                && std::strncmp(model->m_textures[i]->m_filename, "SolidTexture", 12)) capeReady = true;
    }
    for (unsigned variant = 0; variant < 10; ++variant)
        model->SetGeometryVisible(1501u + variant, 1501u + variant, capeReady && variant == capeVariant ? 1 : 0);
    // No incremental offsets/scales, no resetting the whole body on retries.
    model->OptimizeVisibleGeometry();
    static uint64_t last[2] = {~uint64_t{0},~uint64_t{0}};
    static unsigned lines[2] = {};
    const uint64_t key = coverage | (uint64_t(ready) << 8) | (uint64_t(robe) << 9)
        | (uint64_t(capeReady) << 25) | (uint64_t(capeVariant) << 26);
    if (last[female] != key && lines[female] < 64) {
        last[female] = key; char path[MAX_PATH] = {};
        if (GetModuleFileNameA(nullptr,path,MAX_PATH)) {
            char* slash = strrchr(path,'\\\\');
            if (slash) {
                strcpy(slash+1,"StormforgedClothing.log"); FILE* f = nullptr;
                if (!fopen_s(&f,path,"a") && f) {
                    fprintf(f,"BODY1A sex=%u vertices=%u coverage=%02X ready=%u robe=%u cape=%u capeVariant=%u dirty=%08X\\n",
                        female?1u:0u,data->m_vertices.m_count,coverage,ready?1u:0u,robe,capeReady?1u:0u,capeVariant,character->m_dirtySections);
                    fclose(f); ++lines[female];
                }
            }
        }
    }
}

'''.replace('FEMALE_COUNT',str(female)).replace('MALE_COUNT',str(male))
assert marker in s;s=s.replace(marker,helper+marker,1)
old='''    if (rig->m_bones.m_count != (female ? 124u : 154u)
        || rig->m_vertices.m_count != (female ? 11155u : 11175u)) return;'''
new=f'''    if (rig->m_bones.m_count != (female ? 124u : 154u)
        || (rig->m_vertices.m_count != (female ? 11155u : 11175u)
            && rig->m_vertices.m_count != (female ? {female}u : {male}u))) return;
    FitStormforgedClothing(character, female);'''
assert s.count(old)==1;s=s.replace(old,new)
s=s.replace('''    parent->SetGeometryVisible(200, 299, 0);
    parent->SetGeometryVisible(hair, hair, 1);''','''    for (unsigned g = 201; g <= 204; ++g) parent->SetGeometryVisible(g,g,g == hair ? 1 : 0);''',1)
s=s.replace('''        parent->SetGeometryVisible(100,199,0);
        parent->SetGeometryVisible(beard,beard,1);''','''        for (unsigned g = 101; g <= 104; ++g) parent->SetGeometryVisible(g,g,g == beard ? 1 : 0);''',1)
p.write_text(s,'utf8')
print('Clothing/cape/robe runtime for',male,female,'vertices; preserved head/shoulder fitting')
