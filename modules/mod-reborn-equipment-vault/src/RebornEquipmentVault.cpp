// EV2A: server-authoritative equipment eligibility preview. No item/DB mutations.
#include "Chat.h"
#include "CommandScript.h"
#include "Config.h"
#include "DataMap.h"
#include "Player.h"
#include "Bag.h"
#include "Item.h"
#include "WorldSession.h"
#include <chrono>
#include <sstream>
using namespace Acore::ChatCommands;
namespace EV2A
{
struct Gate : DataMap::Base { std::chrono::steady_clock::time_point last{}; };
void Error(Player* p,uint32 id,char const* code)
{ ChatHandler(p->GetSession()).PSendSysMessage("EV2A|ERR|{}|{}",id,code); }
bool Ready(Player* p,uint32 id)
{
    if(!sConfigMgr->GetOption<bool>("RebornEquipmentVault.Preview.Enable",true)) { Error(p,id,"disabled");return false; }
    auto* gate=p->CustomData.GetDefault<Gate>("Reborn.EV2A");
    auto now=std::chrono::steady_clock::now();
    if(now-gate->last<std::chrono::milliseconds(250)) { Error(p,id,"busy");return false; }
    gate->last=now;return true;
}
std::string Link(Item const* it,Player* p)
{
    std::ostringstream o;o<<"item:"<<it->GetEntry()<<':'<<it->GetEnchantmentId(PERM_ENCHANTMENT_SLOT);
    for(uint8 n=0;n<3;++n)o<<':'<<it->GetEnchantmentId(EnchantmentSlot(SOCK_ENCHANTMENT_SLOT+n));
    o<<":0:"<<it->GetItemRandomPropertyId()<<':'<<it->GetItemSuffixFactor()<<':'<<uint32(p->GetLevel());return o.str();
}
uint32 BagSize(Player* p,uint32 bag)
{
    if(!bag)return INVENTORY_SLOT_ITEM_END-INVENTORY_SLOT_ITEM_START;
    auto* item=p->GetItemByPos(INVENTORY_SLOT_BAG_0,uint8(INVENTORY_SLOT_BAG_START+bag-1));
    return item && item->IsBag()?static_cast<Bag*>(item)->GetBagSize():0;
}
Item* Source(Player* p,uint32 bag,uint32 cell)
{
    if(bag>4 || !cell || cell>BagSize(p,bag))return nullptr;
    return p->GetItemByPos(bag?uint8(INVENTORY_SLOT_BAG_START+bag-1):INVENTORY_SLOT_BAG_0,
        bag?uint8(cell-1):uint8(INVENTORY_SLOT_ITEM_START+cell-1));
}
bool Read(ChatHandler* h,uint32 id)
{
    auto* p=h->GetSession()->GetPlayer();if(!Ready(p,id))return true;
    uint32 count=0;
    for(uint32 bag=0;bag<=4;++bag)for(uint32 cell=1;cell<=BagSize(p,bag);++cell)if(Source(p,bag,cell))++count;
    h->PSendSysMessage("EV2A|BEGIN|{}|{}",id,count);
    for(uint32 bag=0;bag<=4;++bag)for(uint32 cell=1;cell<=BagSize(p,bag);++cell)
        if(auto* it=Source(p,bag,cell))h->PSendSysMessage("EV2A|BAG|{}|{}|{}|{}|{}",id,bag,cell,it->GetGUID().GetCounter(),it->GetEntry());
    h->PSendSysMessage("EV2A|END|{}",id);return true;
}
bool Supported(Item const* it)
{
    if(it->IsBag() || it->GetCount()!=1 || it->IsWrapped() || it->IsInTrade() || it->IsRefundable() || it->IsBOPTradable() || it->GetUInt32Value(ITEM_FIELD_DURATION) || it->GetTemplate()->Duration)return false;
    for(uint8 n=0;n<MAX_ENCHANTMENT_SLOT;++n)if(it->GetEnchantmentDuration(EnchantmentSlot(n)))return false;
    return true;
}
bool Check(ChatHandler* h,uint32 id,uint32 bag,uint32 cell,uint32 slot,uint32 expectedGuid)
{
    auto* p=h->GetSession()->GetPlayer();if(!Ready(p,id))return true;
    if(slot<1 || slot>19 || bag>4){Error(p,id,"invalid");return true;}
    if(!p->IsAlive() || p->IsInCombat() || p->GetTradeData() || p->IsInFlight() || p->IsBeingTeleported()) {Error(p,id,"blocked");return true;}
    Item* it=Source(p,bag,cell);
    if(!it || it->GetGUID().GetCounter()!=expectedGuid || it->GetOwnerGUID()!=p->GetGUID()){Error(p,id,"changed");return true;}
    if(!Supported(it)){Error(p,id,"unsupported");return true;}
    // Client slots 1..19 map to native EQUIPMENT_SLOT_* 0..18.
    // Native checks also include current offhand/unique-equipped restrictions.
    uint16 destination=0;
    if(p->CanEquipItem(uint8(slot-1),destination,it,true)!=EQUIP_ERR_OK || (destination&255)!=slot-1)
    {Error(p,id,"requirements");return true;}
    h->PSendSysMessage("EV2A|CHECK|{}|{}|{}|{}",id,slot,expectedGuid,Link(it,p));return true;
}
class Commands : public CommandScript
{
public:Commands():CommandScript("reborn_equipment_vault_preview"){}
    ChatCommandTable GetCommands() const override
    {
        static ChatCommandTable c={{"ev2astate",Read,SEC_PLAYER,Console::No},{"ev2acheck",Check,SEC_PLAYER,Console::No}};return c;
    }
};
}


// EV2C: original GUID storage. Single active character, transactional InnoDB DML.
#include "DatabaseEnv.h"
#include "Log.h"
#include "Util.h"
#include <map>
#include <algorithm>
#include <memory>
#include <tuple>
namespace EV3
{
struct Gate : DataMap::Base { std::chrono::steady_clock::time_point last{}; uint32 page=1; uint32 recent[3]={0,0,0}; };
void Error(Player* p,uint32 id,char const* code)
{ ChatHandler(p->GetSession()).PSendSysMessage("EV3|ERR|{}|{}",id,code); }
bool Ready(Player* p,uint32 id)
{
    if(!sConfigMgr->GetOption<bool>("RebornEquipmentVault.Storage.Enable",false)) {Error(p,id,"disabled");return false;}
    if(p->VaultReconcileRequired()){Error(p,id,"relogin");return false;}
    auto* gate=p->CustomData.GetDefault<Gate>("Reborn.EV3");auto now=std::chrono::steady_clock::now();
    if(now-gate->last<std::chrono::milliseconds(500)){Error(p,id,"busy");return false;}gate->last=now;
    // Check names/engines BEFORE touching optional tables (core missing-table policy is fatal).
    auto schema=CharacterDatabase.Query("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND engine='InnoDB' AND table_name IN ('characters','character_inventory','item_instance','character_gifts','reborn_ev_head','reborn_ev_slot','reborn_ev_op','reborn_ev_unlock','reborn_ev_home')");
    if(!schema || schema->Fetch()[0].Get<uint32>()!=9){Error(p,id,"schema");return false;}
    auto columns=CharacterDatabase.Query("SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND ((table_name='reborn_ev_slot' AND column_name='wardrobe') OR (table_name='reborn_ev_op' AND column_name='wardrobe') OR (table_name='reborn_ev_unlock' AND column_name='name'))");
    auto key=CharacterDatabase.Query("SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='reborn_ev_slot' AND index_name='PRIMARY' AND ((seq_in_index=1 AND column_name='guid') OR (seq_in_index=2 AND column_name='wardrobe') OR (seq_in_index=3 AND column_name='slot'))");
    if(!columns || !key || columns->Fetch()[0].Get<uint32>()!=3 || key->Fetch()[0].Get<uint32>()!=3){Error(p,id,"schema");return false;}
    auto homeColumns=CharacterDatabase.Query("SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='reborn_ev_home' AND column_name IN ('guid','wardrobe','slot','item')");
    auto homeKey=CharacterDatabase.Query("SELECT COUNT(*) FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='reborn_ev_home' AND index_name='PRIMARY' AND ((seq_in_index=1 AND column_name='guid') OR (seq_in_index=2 AND column_name='wardrobe') OR (seq_in_index=3 AND column_name='slot'))");
    auto homeItem=CharacterDatabase.Query("SELECT COUNT(*) FROM (SELECT index_name FROM information_schema.statistics WHERE table_schema=DATABASE() AND table_name='reborn_ev_home' AND non_unique=0 GROUP BY index_name HAVING COUNT(*)=1 AND MAX(column_name)='item') k");
    if(!homeColumns||!homeKey||!homeItem||homeColumns->Fetch()[0].Get<uint32>()!=4||homeKey->Fetch()[0].Get<uint32>()!=3||!homeItem->Fetch()[0].Get<uint32>()){Error(p,id,"schema");return false;}
    auto tx=CharacterDatabase.BeginTransaction();
    tx->Append("INSERT IGNORE INTO reborn_ev_head (guid,revision) VALUES ({},0)",p->GetGUID().GetCounter());
    tx->Append("INSERT IGNORE INTO reborn_ev_unlock (guid,wardrobe,price_copper) VALUES ({},1,0)",p->GetGUID().GetCounter());
    if(CharacterDatabase.DirectCommitTransactionWithStatus(tx)!=0){Error(p,id,"database");return false;}
    return true;
}
constexpr uint32 PackLimit=2147483640; // Protocol/storage bound, not a gameplay purchase cap.
uint32 MaxPacks()
{
    int32 value=sConfigMgr->GetOption<int32>("RebornEquipmentVault.Unlock.MaxWardrobes",0);
    return value<0?1:uint32(value);
}
int64 Price(uint32 pack)
{
    if(pack<2 || pack>PackLimit || !sConfigMgr->GetOption<bool>("RebornEquipmentVault.Unlock.Enable",false))return -1;
    uint32 cap=MaxPacks();if(cap && pack>cap)return -1;
    int32 base=sConfigMgr->GetOption<int32>("RebornEquipmentVault.Unlock.PriceGold",1000);
    int32 step=sConfigMgr->GetOption<int32>("RebornEquipmentVault.Unlock.PriceGoldStep",0);
    if(base<0 || step<0)return -1;
    int64 gold=int64(base)+int64(step)*int64(pack-2);
    return gold>214748?-1:gold*10000;
}
bool Ownership(Player* p,uint32 id,uint32& count)
{
    auto result=CharacterDatabase.Query("SELECT COUNT(*),COALESCE(MAX(wardrobe),0),COALESCE(MIN(wardrobe),0) FROM reborn_ev_unlock WHERE guid={}",p->GetGUID().GetCounter());
    if(!result){Error(p,id,"database");return false;}
    auto* f=result->Fetch();count=f[0].Get<uint32>();
    if(!count || count>PackLimit || f[1].Get<uint32>()!=count || f[2].Get<uint32>()!=1){Error(p,id,"record");return false;}
    return true;
}
bool Access(Player* p,uint32 id,uint32 pack)
{
    uint32 count=0;if(!Ownership(p,id,count))return false;
    if(pack>count){Error(p,id,"locked");return false;}return true;
}

std::string Hex(std::string const& value)
{
    static char const digits[]="0123456789abcdef";std::string out;
    for(unsigned char c:value){out+=digits[c>>4];out+=digits[c&15];}
    return out.empty()?"-":out;
}
bool DecodeName(std::string const& hex,std::string& value)
{
    if(hex.empty() || hex.size()>192 || hex.size()%2)return false;
    auto nibble=[](char c)->int {if(c>='0'&&c<='9')return c-'0';if(c>='a'&&c<='f')return c-'a'+10;if(c>='A'&&c<='F')return c-'A'+10;return -1;};
    for(size_t i=0;i<hex.size();i+=2){int a=nibble(hex[i]),b=nibble(hex[i+1]);if(a<0 || b<0)return false;value+=char(a*16+b);}
    std::wstring wide;if(!Utf8toWStr(value,wide) || wide.empty() || wide.size()>16)return false;
    for(wchar_t c:wide)if(c<32 || c==127 || c==L'|')return false;
    return value.find_first_not_of(' ')!=std::string::npos;
}

std::unique_ptr<Item> LoadOriginal(uint32 guid,Player* p,uint32 entry,Field* fields)
{
    auto item=std::make_unique<Item>();
    if(!item->LoadVaultOriginal(guid,p->GetGUID(),fields,entry))return nullptr;
    // Native loader normalizes some legacy values. Refuse incompatible records, never rewrite them.
    if(item->GetItemRandomPropertyId()!=fields[7].Get<int32>() || item->GetUInt32Value(ITEM_FIELD_DURABILITY)!=fields[8].Get<uint32>() || item->GetUInt32Value(ITEM_FIELD_FLAGS)!=fields[5].Get<uint32>())return nullptr;
    item->FSetState(ITEM_UNCHANGED);return item;
}
struct BuildLinkInfo
{
    bool available=false;
    uint32 revision=0,active=0,spec=3;
    uint32 packs[3]={0,0,0};
};
BuildLinkInfo ReadBuildLinks(Player* p)
{
    BuildLinkInfo info;
    if(p->getClass()!=13 || p->getRace()!=1 ||
       !sConfigMgr->GetOption<bool>("RebornEquipmentVault.Link.Enable",true) ||
       !sConfigMgr->GetOption<bool>("RebornWD5A.Enable",false) ||
       !sConfigMgr->GetOption<bool>("RebornWD8.Enable",false))return info;
    // Link support is optional: a missing migration must not disable normal storage.
    auto schema=CharacterDatabase.Query("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND engine='InnoDB' AND table_name IN ('reborn_ev_build_link','reborn_wd5a_builds','reborn_wd13_slots','reborn_wd16_profiles')");
    if(!schema || schema->Fetch()[0].Get<uint32>()!=4)return info;
    auto columns=CharacterDatabase.Query("SELECT COUNT(*) FROM information_schema.columns WHERE table_schema=DATABASE() AND table_name='reborn_ev_build_link' AND column_name IN ('guid','build_slot','wardrobe')");
    if(!columns || columns->Fetch()[0].Get<uint32>()!=3)return info;
    auto q=CharacterDatabase.Query("SELECT b.revision,b.active,COALESCE(p.spec,3),(SELECT COUNT(*) FROM reborn_wd13_slots s WHERE s.guid=b.guid AND s.slot=b.active),COALESCE(MAX(CASE WHEN l.build_slot=0 THEN l.wardrobe END),0),COALESCE(MAX(CASE WHEN l.build_slot=1 THEN l.wardrobe END),0),COALESCE(MAX(CASE WHEN l.build_slot=2 THEN l.wardrobe END),0) FROM reborn_wd5a_builds b LEFT JOIN reborn_wd16_profiles p ON p.guid=b.guid AND p.slot=b.active LEFT JOIN reborn_ev_build_link l ON l.guid=b.guid WHERE b.guid={} GROUP BY b.guid,b.revision,b.active,p.spec",p->GetGUID().GetCounter());
    if(!q)return info;
    auto* f=q->Fetch();info.revision=f[0].Get<uint32>();info.active=f[1].Get<uint32>();info.spec=f[2].Get<uint32>();
    if(info.revision>2000000000 || info.active>2 || info.spec>3 || f[3].Get<uint32>()!=1)return BuildLinkInfo{};
    for(uint32 i=0;i<3;++i){info.packs[i]=f[i+4].Get<uint32>();if(info.packs[i]>PackLimit)return BuildLinkInfo{};}
    info.available=true;return info;
}


struct Home { uint32 pack=0,slot=0,item=0; };
std::map<uint32,Item*> CarriedItems(Player* p)
{
    std::map<uint32,Item*> items;
    for(uint8 s=0;s<EQUIPMENT_SLOT_END;++s)if(auto* it=p->GetItemByPos(INVENTORY_SLOT_BAG_0,s))items[it->GetGUID().GetCounter()]=it;
    for(uint32 b=0;b<=4;++b)for(uint32 s=1;s<=EV2A::BagSize(p,b);++s)if(auto* it=EV2A::Source(p,b,s))items[it->GetGUID().GetCounter()]=it;
    return items;
}
std::string HomeScope(Player* p,std::map<uint32,Item*> const& items)
{
    std::string ids="0";
    for(auto const& item:items)ids+=","+std::to_string(item.first);
    for(uint32 recent:p->CustomData.GetDefault<Gate>("Reborn.EV3")->recent)if(recent)ids+=","+std::to_string(recent);
    return ids; // All values are server-owned uint32 GUIDs, never user text.
}
bool Homes(Player* p,std::map<uint32,Home>& homes,uint32 pack)
{
    // Aggregate sentinel distinguishes no assignments from a failed query.
    auto q=CharacterDatabase.Query("SELECT c.item,c.wardrobe,c.slot FROM reborn_ev_head h LEFT JOIN reborn_ev_home c ON c.guid=h.guid AND (c.wardrobe={} OR c.item IN ({})) WHERE h.guid={}",pack,HomeScope(p,CarriedItems(p)),p->GetGUID().GetCounter());
    if(!q)return false;
    do{auto* f=q->Fetch();if(!f[0].IsNull()){Home h{f[1].Get<uint32>(),f[2].Get<uint32>(),f[0].Get<uint32>()};if(!h.pack||h.pack>PackLimit||!h.slot||h.slot>19)return false;homes[h.item]=h;}}while(q->NextRow());
    return true;
}
Item* Carried(Player* p,uint32 guid)
{
    for(uint8 s=0;s<EQUIPMENT_SLOT_END;++s){auto* it=p->GetItemByPos(INVENTORY_SLOT_BAG_0,s);if(it&&it->GetGUID().GetCounter()==guid)return it;}
    for(uint32 b=0;b<=4;++b)for(uint32 s=1;s<=EV2A::BagSize(p,b);++s){auto* it=EV2A::Source(p,b,s);if(it&&it->GetGUID().GetCounter()==guid)return it;}
    return nullptr;
}
bool Worn(Item* it){return it&&it->GetBagSlot()==INVENTORY_SLOT_BAG_0&&it->GetSlot()<EQUIPMENT_SLOT_END;}
void RemoveToVault(Player* p,Item* it)
{
    p->MoveItemFromInventory(it->GetBagSlot(),it->GetSlot(),true);
    for(Item*& queued:p->GetItemUpdateQueue())if(queued==it)queued=nullptr;
    delete it;
}
void InsertHome(CharacterDatabaseTransaction& tx,Player* p,uint32 pack,uint32 slot,uint32 item)
{tx->Append("INSERT INTO reborn_ev_home (guid,wardrobe,slot,item) VALUES ({},{},{},{})",p->GetGUID().GetCounter(),pack,slot,item);}
void DeleteHome(CharacterDatabaseTransaction& tx,Player* p,uint32 pack,uint32 slot,uint32 item)
{tx->Append("DELETE FROM reborn_ev_home WHERE guid={} AND wardrobe={} AND slot={} AND item={}",p->GetGUID().GetCounter(),pack,slot,item);tx->ExpectAffectedRows(1);}
struct HomeView {Home home;uint32 state;std::string link,name;};
bool HomeViews(Player* p,uint32 pack,std::vector<HomeView>& views)
{
    auto carried=CarriedItems(p);
    auto q=CharacterDatabase.Query("SELECT c.wardrobe,c.slot,c.item,COALESCE(v.item,0),COALESCE(i.itemEntry,0),COALESCE(u.name,'') FROM reborn_ev_head h LEFT JOIN reborn_ev_home c ON c.guid=h.guid AND (c.wardrobe={} OR c.item IN ({})) LEFT JOIN reborn_ev_slot v ON v.guid=c.guid AND v.wardrobe=c.wardrobe AND v.slot=c.slot AND v.item=c.item LEFT JOIN item_instance i ON i.guid=c.item AND i.owner_guid=c.guid LEFT JOIN reborn_ev_unlock u ON u.guid=c.guid AND u.wardrobe=c.wardrobe WHERE h.guid={}",pack,HomeScope(p,carried),p->GetGUID().GetCounter());
    if(!q)return false;
    do{
        auto* f=q->Fetch();if(f[0].IsNull())continue;
        Home h{f[0].Get<uint32>(),f[1].Get<uint32>(),f[2].Get<uint32>()};
        if(!h.pack||h.pack>PackLimit||!h.slot||h.slot>19||!h.item)return false;
        auto found=carried.find(h.item);auto* it=found==carried.end()?nullptr:found->second;bool stored=f[3].Get<uint32>()!=0;
        if(stored&&it)return false; // Never represent the same original at two physical locations.
        auto* g=p->CustomData.GetDefault<Gate>("Reborn.EV3");
        if(h.pack!=pack&&!it&&h.item!=g->recent[0]&&h.item!=g->recent[1]&&h.item!=g->recent[2])continue;
        uint32 state=stored?1:it?(Worn(it)?2:3):4;
        std::string link=it?EV2A::Link(it,p):"item:"+std::to_string(f[4].Get<uint32>())+":0";
        views.push_back({h,state,link,f[5].Get<std::string>()});
    }while(q->NextRow());
    return views.size()<=2048;
}

bool Snapshot(Player* p,uint32 id,uint32 pack=1)
{
    auto result=CharacterDatabase.Query("SELECT h.revision,COALESCE(v.slot,0),COALESCE(v.item,0),COALESCE(i.itemEntry,0),i.creatorGuid,i.giftCreatorGuid,i.count,i.duration,i.charges,i.flags,i.enchantments,i.randomPropertyId,i.durability,i.playedTime,i.text FROM reborn_ev_head h LEFT JOIN reborn_ev_slot v ON v.guid=h.guid AND v.wardrobe={} LEFT JOIN item_instance i ON i.guid=v.item AND i.owner_guid=h.guid WHERE h.guid={} ORDER BY v.slot",pack,p->GetGUID().GetCounter());
    if(!result){Error(p,id,"database");return false;}
    uint32 owned=0;if(!Ownership(p,id,owned))return false;
    uint32 cap=MaxPacks();uint32 last=owned;
    if(owned<PackLimit && (!cap || owned<cap))++last;
    if(pack>last){Error(p,id,"invalid");return false;}
    uint32 first=p->CustomData.GetDefault<Gate>("Reborn.EV3")->page;
    first=std::min(first,((last-1)/6)*6+1);uint32 end=std::min(last,first+5);
    std::map<uint32,std::string> labels;
    for(uint32 i=first;i<=end;++i)labels[i]="";labels[pack]="";
    auto link=ReadBuildLinks(p);
    for(uint32 linked:link.packs)if(linked && linked<=owned)labels[linked]="";
    auto names=CharacterDatabase.Query("SELECT wardrobe,name FROM reborn_ev_unlock WHERE guid={} AND ((wardrobe>={} AND wardrobe<={}) OR wardrobe={} OR wardrobe=1 OR wardrobe IN ({},{},{}))",p->GetGUID().GetCounter(),first,end,pack,link.packs[0],link.packs[1],link.packs[2]);
    if(!names){Error(p,id,"database");return false;}
    do{auto* n=names->Fetch();auto found=labels.find(n[0].Get<uint32>());if(found!=labels.end())found->second=n[1].Get<std::string>();}while(names->NextRow());
    ItemTemplate const* targetMain=nullptr;
    uint32 revision=0;std::vector<std::tuple<uint32,uint32,std::string>> items;
    do {auto* f=result->Fetch();revision=f[0].Get<uint32>();uint32 slot=f[1].Get<uint32>();if(!slot)continue;
        uint32 guid=f[2].Get<uint32>(),entry=f[3].Get<uint32>();
        if(!entry || slot>19){Error(p,id,"record");return false;}
        auto it=LoadOriginal(guid,p,entry,f+4);if(!it){Error(p,id,"record");return false;}
        if(slot==16)targetMain=it->GetTemplate();
        items.emplace_back(slot,guid,EV2A::Link(it.get(),p));
    } while(result->NextRow());
    uint32 bags=0;
    for(uint32 bag=0;bag<=4;++bag)for(uint32 cell=1;cell<=EV2A::BagSize(p,bag);++cell)if(EV2A::Source(p,bag,cell))++bags;
    uint32 equipped=0;
    for(uint8 slot=0;slot<EQUIPMENT_SLOT_END;++slot)if(p->GetItemByPos(INVENTORY_SLOT_BAG_0,slot))++equipped;
    std::vector<HomeView> homeViews;if(!HomeViews(p,pack,homeViews)){Error(p,id,"record");return false;}
    // Predict the main hand after the existing return-home phase, not just the current weapon.
    auto* wornMain=p->GetItemByPos(INVENTORY_SLOT_BAG_0,EQUIPMENT_SLOT_MAINHAND);
    bool returningMain=false;
    for(auto const& v:homeViews)
    {
        if(v.home.pack==pack && v.home.slot==16 && (v.state==2 || v.state==3))
            if(auto* it=Carried(p,v.home.item))targetMain=it->GetTemplate();
        if(wornMain && v.home.item==wornMain->GetGUID().GetCounter() && v.home.pack!=pack)returningMain=true;
    }
    if(!targetMain && wornMain && !returningMain)targetMain=wornMain->GetTemplate();
    bool noOffhand=targetMain && targetMain->Class==ITEM_CLASS_WEAPON &&
        (targetMain->SubClass==ITEM_SUBCLASS_WEAPON_POLEARM || targetMain->SubClass==ITEM_SUBCLASS_WEAPON_STAFF ||
         targetMain->SubClass==ITEM_SUBCLASS_WEAPON_FISHING_POLE ||
         (targetMain->InventoryType==INVTYPE_2HWEAPON && !p->CanTitanGrip()));
    // EV2F optional count: old clients ignore the extension; new clients require all rows.
    ChatHandler h(p->GetSession());h.PSendSysMessage("EV3|BEGIN|{}|{}|{}|{}|{}|1|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}",id,revision,bags,items.size(),equipped,pack,owned,cap,Price(owned+1),labels.size(),first,uint32(link.available),link.revision,link.active,link.spec,link.packs[0],link.packs[1],link.packs[2],homeViews.size(),uint32(noOffhand));
    for(auto const& v:homeViews)h.PSendSysMessage("EV3|HOME|{}|{}|{}|{}|{}|{}|{}",id,v.home.pack,v.home.slot,v.home.item,v.state,v.link,Hex(v.name));
    for(auto const& label:labels)h.PSendSysMessage("EV3|LABEL|{}|{}|{}",id,label.first,Hex(label.second));
    for(uint8 slot=0;slot<EQUIPMENT_SLOT_END;++slot)
        if(auto* it=p->GetItemByPos(INVENTORY_SLOT_BAG_0,slot))
            h.PSendSysMessage("EV3|EQUIPPED|{}|{}|{}|{}",id,uint32(slot)+1,it->GetGUID().GetCounter(),it->GetEntry());
    for(uint32 bag=0;bag<=4;++bag)for(uint32 cell=1;cell<=EV2A::BagSize(p,bag);++cell)
        if(auto* it=EV2A::Source(p,bag,cell))h.PSendSysMessage("EV3|BAG|{}|{}|{}|{}|{}",id,bag,cell,it->GetGUID().GetCounter(),it->GetEntry());
    for(auto const& row:items)h.PSendSysMessage("EV3|ITEM|{}|{}|{}|{}",id,std::get<0>(row),std::get<1>(row),std::get<2>(row));
    h.PSendSysMessage("EV3|END|{}",id);return true;
}
bool Read(ChatHandler* h,uint32 id)
{auto* p=h->GetSession()->GetPlayer();if(Ready(p,id))Snapshot(p,id);return true;}
// Always returns the head row; null is a DB failure, not an absent operation.
QueryResult Operation(Player* p,uint32 version)
{
    return CharacterDatabase.Query("SELECT h.revision,COALESCE(o.kind,0),COALESCE(o.item,0),COALESCE(o.slot,0),COALESCE(o.wardrobe,1) FROM reborn_ev_head h LEFT JOIN reborn_ev_op o ON o.guid=h.guid AND o.version={} WHERE h.guid={} FOR UPDATE",version,p->GetGUID().GetCounter());
}
bool Matches(Field* f,uint32 kind,uint32 item,uint32 slot,uint32 pack)
{return f[1].Get<uint32>()==kind && f[2].Get<uint32>()==item && f[3].Get<uint32>()==slot && f[4].Get<uint32>()==pack;}
// 1 new operation; 0 duplicate/stale/error already answered.
bool Begin(Player* p,uint32 id,uint32 version,uint32 kind,uint32 item,uint32 slot,uint32 pack=1)
{
    if(pack<1 || pack>PackLimit){Error(p,id,"invalid");return false;}
    if(!Ready(p,id))return false;
    if(slot<1 || slot>19 || !item || version>=2147483640){Error(p,id,"invalid");return false;}
    auto op=Operation(p,version);if(!op){Error(p,id,"database");return false;}auto* f=op->Fetch();
    if(f[1].Get<uint32>())
    {if(Matches(f,kind,item,slot,pack))Snapshot(p,id,pack);else Error(p,id,"changed");return false;}
    if(f[0].Get<uint32>()!=version){Error(p,id,"changed");return false;}
    if(!p->IsAlive() || p->IsInCombat() || p->GetTradeData() || p->IsInFlight() || p->IsBeingTeleported()) {Error(p,id,"blocked");return false;}
    if(kind!=5 && !Access(p,id,pack))return false;
    int status=p->VaultInventoryWriteStatus();
    if(status){Error(p,id,status>0?"saving":"relogin");return false;}
    return true;
}
CharacterDatabaseTransaction Start(Player* p,uint32 version)
{
    auto tx=CharacterDatabase.BeginTransaction();
    tx->Append("UPDATE reborn_ev_head SET revision=revision+1 WHERE guid={} AND revision={}",p->GetGUID().GetCounter(),version);
    tx->ExpectAffectedRows(1); // Stale version aborts before any inventory/snapshot SQL.
    p->AppendVaultInventorySnapshot(tx);
    return tx;
}
bool Commit(Player* p,uint32 id,CharacterDatabaseTransaction& tx,uint32 version,uint32 kind,uint32 item,uint32 slot,uint32 pack=1)
{
    tx->Append("INSERT INTO reborn_ev_op (guid,version,kind,item,slot,wardrobe) VALUES ({},{},{},{},{},{})",p->GetGUID().GetCounter(),version,kind,item,slot,pack);
    int result=CharacterDatabase.DirectCommitTransactionWithStatus(tx);
    if(result==0)return true;
    if(result!=TRANSACTION_RESULT_UNKNOWN){Error(p,id,"retry");return false;}
    // Locking read waits for the transaction that owned the head row to finish.
    auto op=Operation(p,version);
    if(op)
    {
        if(Matches(op->Fetch(),kind,item,slot,pack))return true;
        Error(p,id,"retry");return false;
    }
    // Never let stale in-memory inventory overwrite an unknown DB location on logout.
    LOG_ERROR("module", "EV3 transfer requires reconciliation: character {}, version {}, item {}",p->GetGUID().GetCounter(),version,item);
    p->RequireVaultReconcile();Error(p,id,"relogin");p->GetSession()->KickPlayer("Equipment vault reconciliation required");return false;
}
bool Supported(Item const* it) { return EV2A::Supported(it) && it->GetMaxStackCount()==1 && !it->GetTemplate()->HasFlag(ITEM_FLAG_HAS_LOOT); }
// Only waive the native two-hand combination rejection for storage, never for wearing.
bool StorageFits(Player* p,Item* item,uint32 slot)
{
    uint16 dest=0;auto result=p->CanEquipItem(uint8(slot-1),dest,item,true);
    if(result==EQUIP_ERR_OK)return dest==(uint16(INVENTORY_SLOT_BAG_0)<<8 | uint8(slot-1));
    return slot==17 && result==EQUIP_ERR_CANT_EQUIP_WITH_TWOHANDED;
}
// EV2Q: state 4 means outside carried/vault storage, not proof of destruction.
// Explicit confirmation releases membership only; never delete/move the old item.
bool DetachedHome(Player* p,uint32 id,uint32 pack,uint32 slot,uint32 guid,std::map<uint32,Home> const& homes)
{
    auto found=homes.find(guid);
    if(found==homes.end()||found->second.pack!=pack||found->second.slot!=slot||Carried(p,guid))
    {Error(p,id,"changed");return false;}
    auto q=CharacterDatabase.Query("SELECT COUNT(*) FROM reborn_ev_slot WHERE item={}",guid);
    if(!q){Error(p,id,"database");return false;}
    if(q->Fetch()[0].Get<uint32>()){Error(p,id,"record");return false;}
    return true;
}
void DeleteDetachedHome(CharacterDatabaseTransaction& tx,Player* p,uint32 pack,uint32 slot,uint32 guid)
{
    tx->Append("DELETE FROM reborn_ev_home WHERE guid={} AND wardrobe={} AND slot={} AND item={} AND NOT EXISTS (SELECT 1 FROM reborn_ev_slot WHERE item={})",p->GetGUID().GetCounter(),pack,slot,guid,guid);
    tx->ExpectAffectedRows(1);
}
bool PutOriginal(ChatHandler* h,uint32 id,uint32 version,uint32 bag,uint32 cell,uint32 slot,uint32 guid,bool worn,uint32 pack=1,uint32 replaceDetached=0)
{
    uint32 kind=replaceDetached?(worn?16:15):(worn?3:1); // Separate idempotency identity for confirmed replacement.
    auto* p=h->GetSession()->GetPlayer();if(!Begin(p,id,version,kind,guid,slot,pack))return true;
    Item* it=worn?p->GetItemByPos(INVENTORY_SLOT_BAG_0,uint8(slot-1)):EV2A::Source(p,bag,cell);
    if(!it || it->GetGUID().GetCounter()!=guid || it->GetOwnerGUID()!=p->GetGUID()){Error(p,id,"changed");return true;}
    if(worn && p->CanUnequipItem(uint16(INVENTORY_SLOT_BAG_0)<<8 | uint16(slot-1),false)!=EQUIP_ERR_OK){Error(p,id,"blocked");return true;}
    if(!Supported(it)){Error(p,id,"unsupported");return true;}
    std::map<uint32,Home> homes;if(!Homes(p,homes,pack)){Error(p,id,"database");return true;}
    if(replaceDetached && (replaceDetached==guid || !DetachedHome(p,id,pack,slot,replaceDetached,homes)))return true;
    auto own=homes.find(guid);
    if(own!=homes.end()&&(own->second.pack!=pack||own->second.slot!=slot)){Error(p,id,"assigned");return true;}
    for(auto const& h:homes)if(h.second.pack==pack&&h.second.slot==slot&&h.first!=guid&&h.first!=replaceDetached){Error(p,id,"occupied");return true;}
    if(own==homes.end() && !StorageFits(p,it,slot)){Error(p,id,"requirements");return true;}
    auto occupied=CharacterDatabase.Query("SELECT COUNT(*) FROM reborn_ev_slot WHERE guid={} AND slot={} AND wardrobe={}",p->GetGUID().GetCounter(),slot,pack);
    if(!occupied){Error(p,id,"database");return true;}
    if(occupied->Fetch()[0].Get<uint32>()){Error(p,id,"occupied");return true;}
    auto tx=Start(p,version);
    if(replaceDetached)DeleteDetachedHome(tx,p,pack,slot,replaceDetached);
    if(own==homes.end())InsertHome(tx,p,pack,slot,guid);
    tx->Append("INSERT INTO reborn_ev_slot (guid,slot,item,wardrobe) VALUES ({},{},{},{})",p->GetGUID().GetCounter(),slot,guid,pack);
    tx->Append("DELETE FROM character_inventory WHERE guid={} AND item={}",p->GetGUID().GetCounter(),guid);tx->ExpectAffectedRows(1);
    if(!Commit(p,id,tx,version,kind,guid,slot,pack))return true;
    // Same object/GUID, removed only after DB ownership transfer is confirmed.
    p->MoveItemFromInventory(it->GetBagSlot(),it->GetSlot(),true);
    // Some native direct saves clear uQueuePos before the player queue is drained.
    for (Item*& queued : p->GetItemUpdateQueue()) if (queued==it) queued=nullptr;
    delete it;
    Snapshot(p,id,pack);return true;
}
// These commands require the player's explicit discard-old-membership confirmation.
bool RepairHome(ChatHandler* h,uint32 id,uint32 version,uint32 bag,uint32 cell,uint32 slot,uint32 guid,uint32 oldGuid,uint32 pack,uint32 worn)
{
    if(!oldGuid||guid==oldGuid||worn>1){Error(h->GetSession()->GetPlayer(),id,"invalid");return true;}
    return PutOriginal(h,id,version,bag,cell,slot,guid,worn!=0,pack,oldGuid);
}
bool ForgetHome(ChatHandler* h,uint32 id,uint32 version,uint32 slot,uint32 guid,uint32 pack)
{
    auto* p=h->GetSession()->GetPlayer();
    if(!Begin(p,id,version,14,guid,slot,pack))return true;
    std::map<uint32,Home> homes;
    if(!Homes(p,homes,pack)){Error(p,id,"database");return true;}
    if(!DetachedHome(p,id,pack,slot,guid,homes))return true;
    auto tx=Start(p,version);DeleteDetachedHome(tx,p,pack,slot,guid);
    if(Commit(p,id,tx,version,14,guid,slot,pack))Snapshot(p,id,pack);
    return true;
}
// Bag storage retains the original command and validations.
bool Put(ChatHandler* h,uint32 id,uint32 version,uint32 bag,uint32 cell,uint32 slot,uint32 guid)
{return PutOriginal(h,id,version,bag,cell,slot,guid,false);}
bool PutWorn(ChatHandler* h,uint32 id,uint32 version,uint32 slot,uint32 guid)
{return PutOriginal(h,id,version,0,0,slot,guid,true);}
bool TakeOriginal(ChatHandler* h,uint32 id,uint32 version,uint32 slot,uint32 guid,uint32 pack=1)
{
    auto* p=h->GetSession()->GetPlayer();if(!Begin(p,id,version,2,guid,slot,pack))return true;
    auto result=CharacterDatabase.Query("SELECT i.itemEntry,i.creatorGuid,i.giftCreatorGuid,i.count,i.duration,i.charges,i.flags,i.enchantments,i.randomPropertyId,i.durability,i.playedTime,i.text FROM reborn_ev_slot v JOIN item_instance i ON i.guid=v.item AND i.owner_guid=v.guid WHERE v.guid={} AND v.slot={} AND v.item={} AND v.wardrobe={}",p->GetGUID().GetCounter(),slot,guid,pack);
    if(!result){Error(p,id,"changed");return true;}auto* f=result->Fetch();
    auto item=LoadOriginal(guid,p,f[0].Get<uint32>(),f+1);
    if(!item || !Supported(item.get())){Error(p,id,"record");return true;}
    ItemPosCountVec dest;
    if(p->CanStoreItem(NULL_BAG,NULL_SLOT,dest,item.get(),false)!=EQUIP_ERR_OK || dest.size()!=1 || dest[0].count!=1){Error(p,id,"full");return true;}
    uint8 bag=uint8(dest[0].pos>>8),cell=uint8(dest[0].pos&255);uint32 bagGuid=0;
    if(bag!=INVENTORY_SLOT_BAG_0){auto* container=p->GetItemByPos(INVENTORY_SLOT_BAG_0,bag);if(!container){Error(p,id,"changed");return true;}bagGuid=container->GetGUID().GetCounter();}
    auto tx=Start(p,version);DeleteHome(tx,p,pack,slot,guid);
    tx->Append("DELETE FROM reborn_ev_slot WHERE guid={} AND slot={} AND item={} AND wardrobe={}",p->GetGUID().GetCounter(),slot,guid,pack);tx->ExpectAffectedRows(1);
    tx->Append("INSERT INTO character_inventory (guid,bag,slot,item) VALUES ({},{},{},{})",p->GetGUID().GetCounter(),bagGuid,cell,guid);
    if(!Commit(p,id,tx,version,2,guid,slot,pack))return true;
    uint32 flags=item->GetUInt32Value(ITEM_FIELD_FLAGS);Item* original=item.release();
    p->MoveItemToInventory(dest,original,true,true);
    Item* stored=p->GetItemByPos(bag,cell);
    if(!stored || stored->GetGUID().GetCounter()!=guid)
    {p->RequireVaultReconcile();Error(p,id,"relogin");p->GetSession()->KickPlayer("Wardrobe inventory placement mismatch");return true;}
    stored->SetUInt32Value(ITEM_FIELD_FLAGS,flags); // Preserve original binding flags.
    Snapshot(p,id,pack);return true;
}
// EV2G: one wardrobe original -> equipment, displaced originals -> reserved bag cells.
// All location changes for this one equip are committed together, before native mutations.
struct Displaced
{
    Item* item;
    uint8 slot;
    uint32 guid;
    uint32 flags;
    ItemPosCountVec dest;
    uint32 bagGuid=0;
    uint32 homePack=0,homeSlot=0;
};
bool ReserveEmpty(Player* p,Displaced& row,std::vector<Displaced> const& reserved)
{
    for(uint32 bag=0;bag<=4;++bag)for(uint32 cell=1;cell<=EV2A::BagSize(p,bag);++cell)
    {
        uint8 nativeBag=bag?uint8(INVENTORY_SLOT_BAG_START+bag-1):INVENTORY_SLOT_BAG_0;
        uint8 nativeCell=bag?uint8(cell-1):uint8(INVENTORY_SLOT_ITEM_START+cell-1);
        uint16 pos=uint16(nativeBag)<<8 | nativeCell;
        if(p->GetItemByPos(nativeBag,nativeCell))continue;
        bool used=false;for(auto const& prior:reserved)if(!prior.dest.empty()&&prior.dest[0].pos==pos)used=true;
        if(used)continue;
        ItemPosCountVec dest;
        if(p->CanStoreItem(nativeBag,nativeCell,dest,row.item,false)!=EQUIP_ERR_OK || dest.size()!=1 || dest[0].count!=1 || dest[0].pos!=pos)continue;
        row.dest=dest;
        if(bag)
        {
            auto* container=p->GetItemByPos(INVENTORY_SLOT_BAG_0,nativeBag);
            if(!container)return false;
            row.bagGuid=container->GetGUID().GetCounter();
        }
        return true;
    }
    return false;
}
bool EquipOriginal(ChatHandler* h,uint32 id,uint32 version,uint32 slot,uint32 guid,uint32 oldGuid,uint32 offGuid,uint32 pack=1)
{
    auto* p=h->GetSession()->GetPlayer();if(!Begin(p,id,version,4,guid,slot,pack))return true;
    auto result=CharacterDatabase.Query("SELECT i.itemEntry,i.creatorGuid,i.giftCreatorGuid,i.count,i.duration,i.charges,i.flags,i.enchantments,i.randomPropertyId,i.durability,i.playedTime,i.text FROM reborn_ev_slot v JOIN item_instance i ON i.guid=v.item AND i.owner_guid=v.guid WHERE v.guid={} AND v.slot={} AND v.item={} AND v.wardrobe={}",p->GetGUID().GetCounter(),slot,guid,pack);
    if(!result){Error(p,id,"changed");return true;}
    auto* f=result->Fetch();auto item=LoadOriginal(guid,p,f[0].Get<uint32>(),f+1);
    if(!item || !Supported(item.get())){Error(p,id,"record");return true;}
    uint8 nativeSlot=uint8(slot-1);
    Item* old=p->GetItemByPos(INVENTORY_SLOT_BAG_0,nativeSlot);
    Item* off=p->GetItemByPos(INVENTORY_SLOT_BAG_0,EQUIPMENT_SLOT_OFFHAND);
    if((old?old->GetGUID().GetCounter():0)!=oldGuid ||
       (nativeSlot==EQUIPMENT_SLOT_MAINHAND && (off?off->GetGUID().GetCounter():0)!=offGuid))
    {Error(p,id,"changed");return true;}
    std::map<uint32,Home> homes;if(!Homes(p,homes,pack)){Error(p,id,"database");return true;}
    auto incoming=homes.find(guid);if(incoming==homes.end()||incoming->second.pack!=pack||incoming->second.slot!=slot){Error(p,id,"record");return true;}
    std::vector<Displaced> moves;
    auto plan=[&](Item* displaced)->bool
    {
        if(!displaced)return true;
        if(displaced->GetOwnerGUID()!=p->GetGUID() || !Supported(displaced))
        {Error(p,id,"unsupported");return false;}
        if(p->CanUnequipItem(uint16(INVENTORY_SLOT_BAG_0)<<8 | displaced->GetSlot(),false)!=EQUIP_ERR_OK)
        {Error(p,id,"blocked");return false;}
        Displaced row{displaced,displaced->GetSlot(),displaced->GetGUID().GetCounter(),displaced->GetUInt32Value(ITEM_FIELD_FLAGS),{},0};
        auto home=homes.find(row.guid);
        if(home!=homes.end()){row.homePack=home->second.pack;row.homeSlot=home->second.slot;}
        else if(!ReserveEmpty(p,row,moves)){Error(p,id,"equipfull");return false;}
        moves.push_back(row);return true;
    };
    // Mirror native offhand incompatibility without calling its mail fallback.
    auto* proto=item->GetTemplate();
    bool clearOff=nativeSlot==EQUIPMENT_SLOT_MAINHAND && off &&
        ((!p->CanDualWield() && (off->GetTemplate()->InventoryType==INVTYPE_WEAPONOFFHAND || off->GetTemplate()->InventoryType==INVTYPE_WEAPON)) ||
         proto->SubClass==ITEM_SUBCLASS_WEAPON_POLEARM || proto->SubClass==ITEM_SUBCLASS_WEAPON_STAFF || proto->SubClass==ITEM_SUBCLASS_WEAPON_FISHING_POLE ||
         (!p->CanTitanGrip() && (proto->InventoryType==INVTYPE_2HWEAPON || off->GetTemplate()->InventoryType==INVTYPE_2HWEAPON)));
    if(clearOff && !plan(off))return true;
    if(!plan(old))return true;
    uint16 destination=0;
    auto equipResult=p->CanEquipItem(nativeSlot,destination,item.get(),true);
    if(equipResult!=EQUIP_ERR_OK || destination!=(uint16(INVENTORY_SLOT_BAG_0)<<8 | nativeSlot))
    {Error(p,id,equipResult==EQUIP_ERR_CANT_EQUIP_WITH_TWOHANDED?"weaponconflict":"cantwear");return true;}

    // Binding caused by actual wear must also survive a crash just after COMMIT.
    if(proto->Bonding==BIND_WHEN_EQUIPPED || proto->Bonding==BIND_WHEN_PICKED_UP || proto->Bonding==BIND_QUEST_ITEM)item->SetBinding(true);
    auto tx=Start(p,version);
    item->AppendVaultSnapshot(tx);
    for(auto const& row:moves)
    {
        if(row.homePack){
            tx->Append("DELETE FROM character_inventory WHERE guid={} AND item={}",p->GetGUID().GetCounter(),row.guid);tx->ExpectAffectedRows(1);
            tx->Append("INSERT INTO reborn_ev_slot (guid,wardrobe,slot,item) VALUES ({},{},{},{})",p->GetGUID().GetCounter(),row.homePack,row.homeSlot,row.guid);
            continue;
        }
        tx->Append("UPDATE character_inventory SET bag={},slot={} WHERE guid={} AND item={} AND bag=0 AND slot={}",row.bagGuid,uint32(row.dest[0].pos&255),p->GetGUID().GetCounter(),row.guid,uint32(row.slot));
        tx->ExpectAffectedRows(1);
    }
    tx->Append("DELETE FROM reborn_ev_slot WHERE guid={} AND slot={} AND item={} AND wardrobe={}",p->GetGUID().GetCounter(),slot,guid,pack);tx->ExpectAffectedRows(1);
    tx->Append("INSERT INTO character_inventory (guid,bag,slot,item) VALUES ({},0,{},{})",p->GetGUID().GetCounter(),uint32(nativeSlot),guid);
    if(!Commit(p,id,tx,version,4,guid,slot,pack))return true;
    for(auto const& row:moves)
    {
        if(row.homePack){auto* g=p->CustomData.GetDefault<Gate>("Reborn.EV3");g->recent[1]=g->recent[0];g->recent[0]=row.guid;RemoveToVault(p,row.item);continue;}
        p->RemoveItem(INVENTORY_SLOT_BAG_0,row.slot,true);
        Item* stored=p->StoreItem(row.dest,row.item,true);
        if(!stored || stored->GetGUID().GetCounter()!=row.guid)
        {p->RequireVaultReconcile();Error(p,id,"relogin");p->GetSession()->KickPlayer("Wardrobe displaced placement mismatch");return true;}
        stored->SetUInt32Value(ITEM_FIELD_FLAGS,row.flags);
    }
    // EquipItem's merge branch must never be entered for a wardrobe original.
    if(p->GetItemByPos(INVENTORY_SLOT_BAG_0,nativeSlot))
    {p->RequireVaultReconcile();Error(p,id,"relogin");p->GetSession()->KickPlayer("Wardrobe equipment destination changed");return true;}
    Item* original=item.release();
    p->ItemAddedQuestCheck(original->GetEntry(),original->GetCount());
    Item* equipped=p->EquipItem(destination,original,true);
    Item* actual=p->GetItemByPos(INVENTORY_SLOT_BAG_0,nativeSlot);
    if(!equipped || !actual || actual->GetGUID().GetCounter()!=guid || equipped!=actual)
    {p->RequireVaultReconcile();Error(p,id,"relogin");p->GetSession()->KickPlayer("Wardrobe equipment placement mismatch");return true;}
    p->UpdateTitansGrip();
    Snapshot(p,id,pack);return true;
}

bool Take(ChatHandler* h,uint32 id,uint32 version,uint32 slot,uint32 guid)
{return TakeOriginal(h,id,version,slot,guid,1);}
bool Equip(ChatHandler* h,uint32 id,uint32 version,uint32 slot,uint32 guid,uint32 oldGuid,uint32 offGuid)
{return EquipOriginal(h,id,version,slot,guid,oldGuid,offGuid,1);}
bool Buy(ChatHandler* h,uint32 id,uint32 version,uint32 pack,uint32 quoted)
{
    auto* p=h->GetSession()->GetPlayer();
    if(pack<2 || pack>PackLimit){Error(p,id,"invalid");return true;}
    if(!Begin(p,id,version,5,pack,1,pack))return true;
    uint32 owned=0;if(!Ownership(p,id,owned))return true;
    if(pack<=owned){Snapshot(p,id,pack);return true;}
    if(pack!=owned+1){Error(p,id,"locked");return true;}
    int64 offer=Price(pack);
    if(offer<0){Error(p,id,"closed");return true;}
    if(uint32(offer)!=quoted){Error(p,id,"pricechanged");return true;}
    uint32 cost=uint32(offer),money=p->GetMoney();
    if(money<cost){Error(p,id,"nomoney");return true;}
    auto tx=Start(p,version);
    // Start synchronizes the live wallet first; all deductions share its save fence.
    tx->Append("UPDATE characters SET money=money-{} WHERE guid={} AND money={}",cost,p->GetGUID().GetCounter(),money);
    // A free unlock does not change money; MySQL affected rows may be zero.
    if(cost)tx->ExpectAffectedRows(1);
    tx->Append("INSERT INTO reborn_ev_unlock (guid,wardrobe,price_copper) VALUES ({},{},{})",p->GetGUID().GetCounter(),pack,cost);
    if(!Commit(p,id,tx,version,5,pack,1,pack))return true;
    p->SetMoney(money-cost);
    Snapshot(p,id,pack);return true;
}
bool ReadPack(ChatHandler* h,uint32 id,uint32 pack,uint32 page)
{
    auto* p=h->GetSession()->GetPlayer();if(pack<1 || pack>PackLimit){Error(p,id,"invalid");return true;}
    if(page<1 || page>PackLimit || (page-1)%6){Error(p,id,"invalid");return true;}
    if(Ready(p,id)){p->CustomData.GetDefault<Gate>("Reborn.EV3")->page=page;Snapshot(p,id,pack);}return true;
}
bool PutPack(ChatHandler* h,uint32 id,uint32 version,uint32 bag,uint32 cell,uint32 slot,uint32 guid,uint32 pack)
{return PutOriginal(h,id,version,bag,cell,slot,guid,false,pack);}
bool PutWornPack(ChatHandler* h,uint32 id,uint32 version,uint32 slot,uint32 guid,uint32 pack)
{return PutOriginal(h,id,version,0,0,slot,guid,true,pack);}
bool TakePack(ChatHandler* h,uint32 id,uint32 version,uint32 slot,uint32 guid,uint32 pack)
{return TakeOriginal(h,id,version,slot,guid,pack);}
bool EquipPack(ChatHandler* h,uint32 id,uint32 version,uint32 slot,uint32 guid,uint32 oldGuid,uint32 offGuid,uint32 pack)
{return EquipOriginal(h,id,version,slot,guid,oldGuid,offGuid,pack);}
bool Rename(ChatHandler* h,uint32 id,uint32 version,uint32 pack,std::string hex)
{
    auto* p=h->GetSession()->GetPlayer();std::string name;
    if(!DecodeName(hex,name)){Error(p,id,"badname");return true;}
    if(!Begin(p,id,version,6,pack,1,pack))return true;
    auto tx=Start(p,version);
    // Only hex digits survive DecodeName; user text never becomes SQL syntax.
    tx->Append("UPDATE reborn_ev_unlock SET name=UNHEX('{}') WHERE guid={} AND wardrobe={}",hex,p->GetGUID().GetCounter(),pack);
    // Unchanged name can report zero changed rows; entitlement was checked in Begin.
    if(!Commit(p,id,tx,version,6,pack,1,pack))return true;
    Snapshot(p,id,pack);return true;
}

bool ReturnHome(ChatHandler* handler,uint32 id,uint32 version,uint32 guid,uint32 slot,uint32 displayPack,uint32 build,uint32 wdRevision)
{
    auto* p=handler->GetSession()->GetPlayer();
    if(!Begin(p,id,version,10,guid,slot,displayPack))return true;
    std::map<uint32,Home> homes;if(!Homes(p,homes,displayPack)){Error(p,id,"database");return true;}
    auto found=homes.find(guid);if(found==homes.end()){Error(p,id,"changed");return true;}Home home=found->second;
    if(home.slot!=slot){Error(p,id,"changed");return true;}
    if(build<3){auto link=ReadBuildLinks(p);if(!link.available||link.active!=build||link.revision!=wdRevision||link.packs[build]!=displayPack){Error(p,id,"buildchanged");return true;}}
    else if(build!=3){Error(p,id,"invalid");return true;}
    auto* it=Carried(p,guid);
    if(!it||!Supported(it)){Error(p,id,"changed");return true;}
    if(Worn(it)&&p->CanUnequipItem(uint16(INVENTORY_SLOT_BAG_0)<<8|it->GetSlot(),false)!=EQUIP_ERR_OK){Error(p,id,"blocked");return true;}
    auto tx=Start(p,version);
    tx->Append("DELETE FROM character_inventory WHERE guid={} AND item={}",p->GetGUID().GetCounter(),guid);tx->ExpectAffectedRows(1);
    tx->Append("INSERT INTO reborn_ev_slot (guid,wardrobe,slot,item) VALUES ({},{},{},{})",p->GetGUID().GetCounter(),home.pack,home.slot,guid);
    if(!Commit(p,id,tx,version,10,guid,home.slot,displayPack))return true;
    p->CustomData.GetDefault<Gate>("Reborn.EV3")->recent[0]=guid;
    RemoveToVault(p,it);Snapshot(p,id,displayPack);return true;
}
bool ReleaseHome(ChatHandler* handler,uint32 id,uint32 version,uint32 slot,uint32 guid,uint32 pack)
{
    auto* p=handler->GetSession()->GetPlayer();
    if(!Begin(p,id,version,11,guid,slot,pack))return true;
    std::map<uint32,Home> homes;if(!Homes(p,homes,pack)){Error(p,id,"database");return true;}
    auto f=homes.find(guid);if(f==homes.end()||f->second.pack!=pack||f->second.slot!=slot){Error(p,id,"changed");return true;}
    auto* it=Carried(p,guid);if(!it||!Supported(it)){Error(p,id,"record");return true;}
    ItemPosCountVec dest;uint32 bagGuid=0;
    if(Worn(it)){
        if(p->CanUnequipItem(uint16(INVENTORY_SLOT_BAG_0)<<8|it->GetSlot(),false)!=EQUIP_ERR_OK){Error(p,id,"blocked");return true;}
        if(p->CanStoreItem(NULL_BAG,NULL_SLOT,dest,it,false)!=EQUIP_ERR_OK||dest.size()!=1||dest[0].count!=1){Error(p,id,"full");return true;}
        uint8 bag=uint8(dest[0].pos>>8);if(bag!=INVENTORY_SLOT_BAG_0){auto* container=p->GetItemByPos(INVENTORY_SLOT_BAG_0,bag);if(!container){Error(p,id,"changed");return true;}bagGuid=container->GetGUID().GetCounter();}
    }
    auto tx=Start(p,version);DeleteHome(tx,p,pack,slot,guid);
    if(!dest.empty()){tx->Append("UPDATE character_inventory SET bag={},slot={} WHERE guid={} AND item={}",bagGuid,uint32(dest[0].pos&255),p->GetGUID().GetCounter(),guid);tx->ExpectAffectedRows(1);}
    if(!Commit(p,id,tx,version,11,guid,slot,pack))return true;
    if(!dest.empty()){
        uint32 flags=it->GetUInt32Value(ITEM_FIELD_FLAGS);
        p->RemoveItem(it->GetBagSlot(),it->GetSlot(),true);auto* placed=p->StoreItem(dest,it,true);
        auto* actual=p->GetItemByPos(uint8(dest[0].pos>>8),uint8(dest[0].pos&255));
        if(!placed||placed!=actual||placed->GetGUID().GetCounter()!=guid){p->RequireVaultReconcile();Error(p,id,"relogin");p->GetSession()->KickPlayer("Wardrobe release placement mismatch");return true;}
        placed->SetUInt32Value(ITEM_FIELD_FLAGS,flags);p->UpdateTitansGrip();
    }
    Snapshot(p,id,pack);return true;
}

bool ReplaceHome(ChatHandler* handler,uint32 id,uint32 version,uint32 bag,uint32 cell,uint32 slot,uint32 newGuid,uint32 oldGuid,uint32 pack,uint32 wear)
{
    auto* p=handler->GetSession()->GetPlayer();uint32 kind=wear?13:12;
    if(wear>1||!oldGuid||newGuid==oldGuid){Error(p,id,"invalid");return true;}
    if(!Begin(p,id,version,kind,newGuid,slot,pack))return true;
    std::map<uint32,Home> homes;if(!Homes(p,homes,pack)){Error(p,id,"database");return true;}
    auto oldHome=homes.find(oldGuid);
    if(oldHome==homes.end()||oldHome->second.pack!=pack||oldHome->second.slot!=slot){Error(p,id,"changed");return true;}
    if(homes.count(newGuid)){Error(p,id,"assigned");return true;}
    auto* fresh=EV2A::Source(p,bag,cell);
    if(!fresh||fresh->GetGUID().GetCounter()!=newGuid||fresh->GetOwnerGUID()!=p->GetGUID()||!Supported(fresh)){Error(p,id,"changed");return true;}
    uint16 equipPos=0;uint8 nativeSlot=uint8(slot-1);
    // Same item eligibility as an ordinary deposit; wear additionally uses native displaced checks.
    if(wear ? (p->CanEquipItem(nativeSlot,equipPos,fresh,true)!=EQUIP_ERR_OK||equipPos!=(uint16(INVENTORY_SLOT_BAG_0)<<8|nativeSlot)) : !StorageFits(p,fresh,slot)){Error(p,id,"cantwear");return true;}
    auto* former=Carried(p,oldGuid);std::unique_ptr<Item> stored;
    if(!former){
        auto q=CharacterDatabase.Query("SELECT i.itemEntry,i.creatorGuid,i.giftCreatorGuid,i.count,i.duration,i.charges,i.flags,i.enchantments,i.randomPropertyId,i.durability,i.playedTime,i.text FROM reborn_ev_slot v JOIN item_instance i ON i.guid=v.item AND i.owner_guid=v.guid WHERE v.guid={} AND v.wardrobe={} AND v.slot={} AND v.item={}",p->GetGUID().GetCounter(),pack,slot,oldGuid);
        if(!q){Error(p,id,"record");return true;}auto* f=q->Fetch();stored=LoadOriginal(oldGuid,p,f[0].Get<uint32>(),f+1);former=stored.get();
    }
    if(!former||!Supported(former)){Error(p,id,"unsupported");return true;}
    std::vector<Displaced> moves;
    auto plan=[&](Item* it,bool fromStore)->bool {
        if(!it)return true;
        for(auto const& r:moves)if(r.item==it)return true;
        if(!Supported(it)||it->GetOwnerGUID()!=p->GetGUID()){Error(p,id,"unsupported");return false;}
        if(!fromStore&&p->CanUnequipItem(uint16(INVENTORY_SLOT_BAG_0)<<8|it->GetSlot(),false)!=EQUIP_ERR_OK){Error(p,id,"blocked");return false;}
        Displaced r{it,fromStore?uint8(255):it->GetSlot(),it->GetGUID().GetCounter(),it->GetUInt32Value(ITEM_FIELD_FLAGS),{},0};
        auto home=homes.find(r.guid);
        // Explicitly replaced former member leaves the collection; other displaced members return home.
        if(r.guid!=oldGuid&&home!=homes.end()){r.homePack=home->second.pack;r.homeSlot=home->second.slot;}
        else if(!ReserveEmpty(p,r,moves)){Error(p,id,"equipfull");return false;}
        moves.push_back(r);return true;
    };
    if(stored){if(!plan(former,true))return true;}
    else if(Worn(former)&&!plan(former,false))return true;
    auto* proto=fresh->GetTemplate();
    if(wear){
        auto* off=p->GetItemByPos(INVENTORY_SLOT_BAG_0,EQUIPMENT_SLOT_OFFHAND);
        bool clearOff=nativeSlot==EQUIPMENT_SLOT_MAINHAND&&off&&
          ((!p->CanDualWield()&&(off->GetTemplate()->InventoryType==INVTYPE_WEAPONOFFHAND||off->GetTemplate()->InventoryType==INVTYPE_WEAPON))||
           proto->SubClass==ITEM_SUBCLASS_WEAPON_POLEARM||proto->SubClass==ITEM_SUBCLASS_WEAPON_STAFF||proto->SubClass==ITEM_SUBCLASS_WEAPON_FISHING_POLE||
           (!p->CanTitanGrip()&&(proto->InventoryType==INVTYPE_2HWEAPON||off->GetTemplate()->InventoryType==INVTYPE_2HWEAPON)));
        if(clearOff&&!plan(off,false))return true;
        if(!plan(p->GetItemByPos(INVENTORY_SLOT_BAG_0,nativeSlot),false))return true;
    }
    auto tx=Start(p,version);
    DeleteHome(tx,p,pack,slot,oldGuid);InsertHome(tx,p,pack,slot,newGuid);
    if(stored){tx->Append("DELETE FROM reborn_ev_slot WHERE guid={} AND wardrobe={} AND slot={} AND item={}",p->GetGUID().GetCounter(),pack,slot,oldGuid);tx->ExpectAffectedRows(1);}
    tx->Append("DELETE FROM character_inventory WHERE guid={} AND item={}",p->GetGUID().GetCounter(),newGuid);tx->ExpectAffectedRows(1);
    for(auto const& r:moves){
        if(r.slot!=255){tx->Append("DELETE FROM character_inventory WHERE guid={} AND item={}",p->GetGUID().GetCounter(),r.guid);tx->ExpectAffectedRows(1);}
        if(r.homePack)tx->Append("INSERT INTO reborn_ev_slot (guid,wardrobe,slot,item) VALUES ({},{},{},{})",p->GetGUID().GetCounter(),r.homePack,r.homeSlot,r.guid);
        else tx->Append("INSERT INTO character_inventory (guid,bag,slot,item) VALUES ({},{},{},{})",p->GetGUID().GetCounter(),r.bagGuid,uint32(r.dest[0].pos&255),r.guid);
    }
    if(wear){
        tx->Append("INSERT INTO character_inventory (guid,bag,slot,item) VALUES ({},0,{},{})",p->GetGUID().GetCounter(),uint32(nativeSlot),newGuid);
        if(proto->Bonding==BIND_WHEN_EQUIPPED||proto->Bonding==BIND_WHEN_PICKED_UP||proto->Bonding==BIND_QUEST_ITEM)
            tx->Append("UPDATE item_instance SET flags=flags|{} WHERE guid={} AND owner_guid={}",uint32(ITEM_FIELD_FLAG_SOULBOUND),newGuid,p->GetGUID().GetCounter());
    }else tx->Append("INSERT INTO reborn_ev_slot (guid,wardrobe,slot,item) VALUES ({},{},{},{})",p->GetGUID().GetCounter(),pack,slot,newGuid);
    if(!Commit(p,id,tx,version,kind,newGuid,slot,pack))return true;
    for(auto const& r:moves){
        if(r.homePack){auto* g=p->CustomData.GetDefault<Gate>("Reborn.EV3");g->recent[1]=g->recent[0];g->recent[0]=r.guid;RemoveToVault(p,r.item);continue;}
        if(r.slot==255){Item* old=stored.release();p->MoveItemToInventory(r.dest,old,true,true);}
        else{p->RemoveItem(INVENTORY_SLOT_BAG_0,r.slot,true);p->StoreItem(r.dest,r.item,true);}
        auto* actual=p->GetItemByPos(uint8(r.dest[0].pos>>8),uint8(r.dest[0].pos&255));
        if(!actual||actual->GetGUID().GetCounter()!=r.guid){p->RequireVaultReconcile();Error(p,id,"relogin");p->GetSession()->KickPlayer("Wardrobe replacement placement mismatch");return true;}
        actual->SetUInt32Value(ITEM_FIELD_FLAGS,r.flags);
    }
    if(!wear)RemoveToVault(p,fresh);
    else{
        p->MoveItemFromInventory(fresh->GetBagSlot(),fresh->GetSlot(),true);
        p->ItemAddedQuestCheck(fresh->GetEntry(),fresh->GetCount());
        if(p->GetItemByPos(INVENTORY_SLOT_BAG_0,nativeSlot)){p->RequireVaultReconcile();Error(p,id,"relogin");p->GetSession()->KickPlayer("Wardrobe replacement equipment conflict");return true;}
        auto* equipped=p->EquipItem(equipPos,fresh,true);
        if(!equipped||equipped->GetGUID().GetCounter()!=newGuid){p->RequireVaultReconcile();Error(p,id,"relogin");p->GetSession()->KickPlayer("Wardrobe replacement equip mismatch");return true;}
    }
    p->UpdateTitansGrip();Snapshot(p,id,pack);return true;
}

bool LinkBuild(ChatHandler* h,uint32 id,uint32 version,uint32 buildRevision,uint32 build,uint32 pack,uint32 linked)
{
    auto* p=h->GetSession()->GetPlayer();
    if(build>2 || pack<1 || pack>PackLimit || linked>1){Error(p,id,"invalid");return true;}
    auto info=ReadBuildLinks(p);
    if(!info.available){Error(p,id,"linkdisabled");return true;}
    if(info.revision!=buildRevision || info.active!=build || info.spec==3){Error(p,id,"buildchanged");return true;}
    uint32 target=linked?pack:0,kind=linked?7:8;
    if(!Begin(p,id,version,kind,pack,build+1,pack))return true;
    auto tx=Start(p,version);
    tx->Append("DELETE FROM reborn_ev_build_link WHERE guid={} AND build_slot={}",p->GetGUID().GetCounter(),build);
    // INSERT SELECT is the build revision fence, including for unlink (wardrobe=0).
    tx->Append("INSERT INTO reborn_ev_build_link (guid,build_slot,wardrobe) SELECT guid,{},{} FROM reborn_wd5a_builds WHERE guid={} AND revision={} AND active={}",build,target,p->GetGUID().GetCounter(),buildRevision,build);
    tx->ExpectAffectedRows(1);
    if(!Commit(p,id,tx,version,kind,pack,build+1,pack))return true;
    Snapshot(p,id,pack);return true;
}
bool EquipLinked(ChatHandler* h,uint32 id,uint32 version,uint32 slot,uint32 guid,uint32 oldGuid,uint32 offGuid,uint32 pack,uint32 build,uint32 buildRevision)
{
    auto* p=h->GetSession()->GetPlayer();auto info=ReadBuildLinks(p);
    if(!info.available){Error(p,id,"linkdisabled");return true;}
    if(build>2 || info.active!=build || info.revision!=buildRevision || info.spec==3 || info.packs[build]!=pack)
    {Error(p,id,"buildchanged");return true;}
    return EquipOriginal(h,id,version,slot,guid,oldGuid,offGuid,pack);
}


// Display-only saved-build notes. Independent revision: never activates or resets talents.
void NameError(Player* p,uint32 id,char const* code)
{ChatHandler(p->GetSession()).PSendSysMessage("WDNAME|ERR|{}|{}",id,code);}
bool NameReady(Player* p,uint32 id)
{
    if(p->getClass()!=13 || p->getRace()!=1 || !sConfigMgr->GetOption<bool>("RebornWD8.Enable",false))
    {NameError(p,id,"disabled");return false;}
    auto* gate=p->CustomData.GetDefault<Gate>("Reborn.WDNames");auto now=std::chrono::steady_clock::now();
    if(now-gate->last<std::chrono::milliseconds(200)){NameError(p,id,"busy");return false;}gate->last=now;
    auto q=CharacterDatabase.Query("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND engine='InnoDB' AND table_name IN ('reborn_wd_build_names','reborn_wd5a_builds','reborn_wd13_slots')");
    if(!q || q->Fetch()[0].Get<uint32>()!=3){NameError(p,id,"schema");return false;}
    return true;
}
bool NamesReply(Player* p,uint32 id)
{
    auto q=CharacterDatabase.Query("SELECT COALESCE(n.revision,0),COALESCE(n.note0,''),COALESCE(n.note1,''),COALESCE(n.note2,'') FROM reborn_wd5a_builds b LEFT JOIN reborn_wd_build_names n ON n.guid=b.guid WHERE b.guid={}",p->GetGUID().GetCounter());
    if(!q){NameError(p,id,"database");return true;}
    auto* f=q->Fetch();ChatHandler h(p->GetSession());
    h.PSendSysMessage("WDNAME|BEGIN|{}|{}",id,f[0].Get<uint32>());
    for(uint32 i=0;i<3;++i)h.PSendSysMessage("WDNAME|NOTE|{}|{}|{}",id,i,Hex(f[i+1].Get<std::string>()));
    h.PSendSysMessage("WDNAME|END|{}",id);return true;
}
bool ReadNames(ChatHandler* h,uint32 id)
{auto* p=h->GetSession()->GetPlayer();if(NameReady(p,id))NamesReply(p,id);return true;}
bool RenameBuild(ChatHandler* h,uint32 id,uint32 version,uint32 wdRevision,uint32 slot,std::string hex)
{
    auto* p=h->GetSession()->GetPlayer();
    if(slot>2 || version>=2000000000){NameError(p,id,"invalid");return true;}
    std::string note;
    if(hex!="-" && !DecodeName(hex,note)){NameError(p,id,"badname");return true;}
    if(!NameReady(p,id))return true;
    // Explicit INSERT/UPDATE transaction; only this display-name table is written.
    auto tx=CharacterDatabase.BeginTransaction();
    tx->Append("INSERT IGNORE INTO reborn_wd_build_names (guid) VALUES ({})",p->GetGUID().GetCounter());
    tx->Append("UPDATE reborn_wd_build_names n JOIN reborn_wd5a_builds b ON b.guid=n.guid SET n.note{}=UNHEX('{}'),n.revision=n.revision+1 WHERE n.guid={} AND n.revision={} AND b.revision={} AND EXISTS (SELECT 1 FROM reborn_wd13_slots s WHERE s.guid=n.guid AND s.slot={})",slot,hex=="-"?"":hex,p->GetGUID().GetCounter(),version,wdRevision,slot);
    tx->ExpectAffectedRows(1);
    int status=CharacterDatabase.DirectCommitTransactionWithStatus(tx);
    if(status!=0 && status!=TRANSACTION_RESULT_UNKNOWN){NameError(p,id,"changed");return true;}
    // Unknown commit outcome is reconciled by readback; no inventory state is involved.
    return NamesReply(p,id);
}

class Commands : public CommandScript
{
public:Commands():CommandScript("reborn_equipment_vault_storage"){}
    ChatCommandTable GetCommands()const override
    {static ChatCommandTable c={{"ev7repair",RepairHome,SEC_PLAYER,Console::No},{"ev7forget",ForgetHome,SEC_PLAYER,Console::No},{"ev3state",Read,SEC_PLAYER,Console::No},{"ev3put",Put,SEC_PLAYER,Console::No},{"ev3take",Take,SEC_PLAYER,Console::No},{"ev3putw",PutWorn,SEC_PLAYER,Console::No},{"ev3equip",Equip,SEC_PLAYER,Console::No},{"ev4state",ReadPack,SEC_PLAYER,Console::No},{"ev4put",PutPack,SEC_PLAYER,Console::No},{"ev4take",TakePack,SEC_PLAYER,Console::No},{"ev4putw",PutWornPack,SEC_PLAYER,Console::No},{"ev4equip",EquipPack,SEC_PLAYER,Console::No},{"ev4buy",Buy,SEC_PLAYER,Console::No},{"ev4name",Rename,SEC_PLAYER,Console::No},{"wdnames",ReadNames,SEC_PLAYER,Console::No},{"wdrename",RenameBuild,SEC_PLAYER,Console::No},{"ev6replace",ReplaceHome,SEC_PLAYER,Console::No},{"ev6return",ReturnHome,SEC_PLAYER,Console::No},{"ev6release",ReleaseHome,SEC_PLAYER,Console::No},{"ev5link",LinkBuild,SEC_PLAYER,Console::No},{"ev5equip",EquipLinked,SEC_PLAYER,Console::No}};return c;}
};
}

void AddRebornEquipmentVaultScripts(){new EV2A::Commands();new EV3::Commands();}
