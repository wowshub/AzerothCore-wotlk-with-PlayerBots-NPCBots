// EV3S: references never own an item. Pool rows alone denote physical storage.
struct SharedRow { uint32 pack,slot,item,state; std::string link; };
bool SharedSnapshot(Player* p,uint32 id,uint32 pack)
{
 uint32 owned=0;if(!Ownership(p,id,owned))return false;
 if(pack<1||pack>owned+1){Error(p,id,"invalid");return false;}
 auto head=CharacterDatabase.Query("SELECT revision FROM reborn_ev_head WHERE guid={}",p->GetGUID().GetCounter());
 if(!head){Error(p,id,"database");return false;}
 auto carried=CarriedItems(p);std::map<uint32,std::string> pool;
 auto q=CharacterDatabase.Query("SELECT v.item,COALESCE(i.itemEntry,0),i.creatorGuid,i.giftCreatorGuid,i.count,i.duration,i.charges,i.flags,i.enchantments,i.randomPropertyId,i.durability,i.playedTime,i.text FROM reborn_ev_head h LEFT JOIN reborn_ev_pool v ON v.guid=h.guid LEFT JOIN item_instance i ON i.guid=v.item AND i.owner_guid=h.guid WHERE h.guid={}",p->GetGUID().GetCounter());
 if(!q){Error(p,id,"database");return false;}
 do{auto* f=q->Fetch();if(f[0].IsNull())continue;uint32 guid=f[0].Get<uint32>();
  if(carried.count(guid)||!f[1].Get<uint32>()){Error(p,id,"record");return false;}
  auto it=LoadOriginal(guid,p,f[1].Get<uint32>(),f+2);if(!it){Error(p,id,"record");return false;}
  pool[guid]=EV2A::Link(it.get(),p);
 }while(q->NextRow());
 std::vector<SharedRow> refs;
 q=CharacterDatabase.Query("SELECT r.wardrobe,r.slot,r.item,COALESCE(i.itemEntry,0) FROM reborn_ev_head h LEFT JOIN reborn_ev_outfit r ON r.guid=h.guid LEFT JOIN item_instance i ON i.guid=r.item AND i.owner_guid=h.guid WHERE h.guid={} ORDER BY r.wardrobe,r.slot",p->GetGUID().GetCounter());
 if(!q){Error(p,id,"database");return false;}
 do{auto*f=q->Fetch();if(f[0].IsNull())continue;uint32 a=f[0].Get<uint32>(),s=f[1].Get<uint32>(),g=f[2].Get<uint32>();
  if(!a||a>owned||!s||s>19||!g){Error(p,id,"record");return false;}
  auto c=carried.find(g);auto v=pool.find(g);uint32 state=v!=pool.end()?1:c!=carried.end()?(Worn(c->second)?2:3):4;
  std::string link=v!=pool.end()?v->second:c!=carried.end()?EV2A::Link(c->second,p):"item:"+std::to_string(f[3].Get<uint32>())+":0";
  refs.push_back({a,s,g,state,link});
 }while(q->NextRow());
 std::map<uint32,std::string> names;
 q=CharacterDatabase.Query("SELECT wardrobe,name FROM reborn_ev_unlock WHERE guid={} ORDER BY wardrobe",p->GetGUID().GetCounter());
 if(!q){Error(p,id,"database");return false;}
 do{auto*f=q->Fetch();names[f[0].Get<uint32>()]=f[1].Get<std::string>();}while(q->NextRow());
 if(refs.size()>19000||pool.size()>2000||names.size()>1000){Error(p,id,"limit");return false;}
 auto build=ReadBuildLinks(p);ChatHandler h(p->GetSession());
 h.PSendSysMessage("EVS|BEGIN|{}|{}|{}|{}|{}|{}|{}|{}|{}|{}",id,head->Fetch()[0].Get<uint32>(),pack,owned,Price(owned+1),refs.size(),pool.size(),carried.size(),names.size(),std::clamp(sConfigMgr->GetOption<int32>("RebornEquipmentVault.Shared.MaxItems",200),1,2000));
 for(auto const& n:names)h.PSendSysMessage("EVS|NAME|{}|{}|{}",id,n.first,Hex(n.second));
 for(auto const& r:refs)h.PSendSysMessage("EVS|REF|{}|{}|{}|{}|{}|{}",id,r.pack,r.slot,r.item,r.state,r.link);
 for(auto const& r:pool)h.PSendSysMessage("EVS|POOL|{}|{}|{}",id,r.first,r.second);
 for(auto const& r:carried)h.PSendSysMessage("EVS|CARRY|{}|{}|{}|{}|{}",id,r.first,uint32(Worn(r.second)?2:3),uint32(Worn(r.second)?r.second->GetSlot()+1:0),EV2A::Link(r.second,p));
 h.PSendSysMessage("EVS|BUILD|{}|{}|{}|{}|{}|{}|{}|{}",id,uint32(build.available),build.revision,build.active,build.available?build.packs[build.active]:0,build.packs[0],build.packs[1],build.packs[2]);
 h.PSendSysMessage("EVS|END|{}",id);return true;
}
// Save the complete worn snapshot in ONE transaction; no inventory movement.
bool SharedSave(ChatHandler* h,uint32 id,uint32 version,uint32 pack)
{
 auto*p=h->GetSession()->GetPlayer();if(!Begin(p,id,version,20,pack,1,pack))return true;
 auto tx=Start(p,version);tx->Append("DELETE FROM reborn_ev_outfit WHERE guid={} AND wardrobe={}",p->GetGUID().GetCounter(),pack);
 for(uint8 s=0;s<EQUIPMENT_SLOT_END;++s)if(auto*it=p->GetItemByPos(INVENTORY_SLOT_BAG_0,s))
  tx->Append("INSERT INTO reborn_ev_outfit (guid,wardrobe,slot,item) VALUES ({},{},{},{})",p->GetGUID().GetCounter(),pack,uint32(s)+1,it->GetGUID().GetCounter());
 if(Commit(p,id,tx,version,20,pack,1,pack))Snapshot(p,id,pack);return true;
}
bool SharedClear(ChatHandler* h,uint32 id,uint32 version,uint32 pack)
{
 auto*p=h->GetSession()->GetPlayer();if(!Begin(p,id,version,21,pack,1,pack))return true;
 auto tx=Start(p,version);tx->Append("DELETE FROM reborn_ev_outfit WHERE guid={} AND wardrobe={}",p->GetGUID().GetCounter(),pack);
 if(Commit(p,id,tx,version,21,pack,1,pack))Snapshot(p,id,pack);return true;
}
bool SharedPut(ChatHandler* h,uint32 id,uint32 version,uint32 guid,uint32 pack)
{
 auto*p=h->GetSession()->GetPlayer();if(!Begin(p,id,version,22,guid,1,pack))return true;
 auto*it=Carried(p,guid);if(!it||Worn(it)||it->GetOwnerGUID()!=p->GetGUID()){Error(p,id,"changed");return true;}
 if(auto reason=EV2A::UnsupportedReason(it)){Error(p,id,reason);return true;}
 if(!Supported(it)){Error(p,id,"unsupported");return true;}
 auto capacity=CharacterDatabase.Query("SELECT COUNT(*) FROM reborn_ev_pool WHERE guid={}",p->GetGUID().GetCounter());
 uint32 maxItems=uint32(std::clamp(sConfigMgr->GetOption<int32>("RebornEquipmentVault.Shared.MaxItems",200),1,2000));
 if(!capacity||capacity->Fetch()[0].Get<uint32>()>=maxItems){Error(p,id,"limit");return true;}
 auto ref=CharacterDatabase.Query("SELECT COUNT(*) FROM reborn_ev_outfit WHERE guid={} AND wardrobe={} AND item={}",p->GetGUID().GetCounter(),pack,guid);
 if(!ref||!ref->Fetch()[0].Get<uint32>()){Error(p,id,"changed");return true;}
 auto tx=Start(p,version);
 tx->Append("INSERT INTO reborn_ev_pool (guid,item) VALUES ({},{})",p->GetGUID().GetCounter(),guid);
 tx->Append("DELETE FROM character_inventory WHERE guid={} AND item={}",p->GetGUID().GetCounter(),guid);tx->ExpectAffectedRows(1);
 if(!Commit(p,id,tx,version,22,guid,1,pack))return true;
 RemoveToVault(p,it);Snapshot(p,id,pack);return true;
}
std::unique_ptr<Item> SharedLoad(Player* p,uint32 guid)
{
 auto q=CharacterDatabase.Query("SELECT i.itemEntry,i.creatorGuid,i.giftCreatorGuid,i.count,i.duration,i.charges,i.flags,i.enchantments,i.randomPropertyId,i.durability,i.playedTime,i.text FROM reborn_ev_pool v JOIN item_instance i ON i.guid=v.item AND i.owner_guid=v.guid WHERE v.guid={} AND v.item={}",p->GetGUID().GetCounter(),guid);
 if(!q)return nullptr;auto*f=q->Fetch();return LoadOriginal(guid,p,f[0].Get<uint32>(),f+1);
}
bool SharedTake(ChatHandler* h,uint32 id,uint32 version,uint32 guid,uint32 pack)
{
 auto*p=h->GetSession()->GetPlayer();if(!Begin(p,id,version,23,guid,1,pack))return true;
 auto it=SharedLoad(p,guid);if(!it||Carried(p,guid)){Error(p,id,"changed");return true;}
 ItemPosCountVec dest;
 if(p->CanStoreItem(NULL_BAG,NULL_SLOT,dest,it.get(),false)!=EQUIP_ERR_OK||dest.size()!=1||dest[0].count!=1){Error(p,id,"full");return true;}
 uint8 bag=uint8(dest[0].pos>>8),cell=uint8(dest[0].pos&255);uint32 bagGuid=0;
 if(bag!=INVENTORY_SLOT_BAG_0){auto*c=p->GetItemByPos(INVENTORY_SLOT_BAG_0,bag);if(!c){Error(p,id,"changed");return true;}bagGuid=c->GetGUID().GetCounter();}
 auto tx=Start(p,version);
 tx->Append("DELETE FROM reborn_ev_pool WHERE guid={} AND item={}",p->GetGUID().GetCounter(),guid);tx->ExpectAffectedRows(1);
 tx->Append("INSERT INTO character_inventory (guid,bag,slot,item) VALUES ({},{},{},{})",p->GetGUID().GetCounter(),bagGuid,uint32(cell),guid);
 if(!Commit(p,id,tx,version,23,guid,1,pack))return true;
 uint32 flags=it->GetUInt32Value(ITEM_FIELD_FLAGS);p->MoveItemToInventory(dest,it.release(),true,true);
 auto*actual=p->GetItemByPos(bag,cell);if(!actual||actual->GetGUID().GetCounter()!=guid){p->RequireVaultReconcile();p->GetSession()->KickPlayer("EV3S withdrawal mismatch");return true;}
 actual->SetUInt32Value(ITEM_FIELD_FLAGS,flags);Snapshot(p,id,pack);return true;
}
bool SharedEquip(ChatHandler*h,uint32 id,uint32 version,uint32 slot,uint32 guid,uint32 oldGuid,uint32 offGuid,uint32 pack)
{
 auto*p=h->GetSession()->GetPlayer();if(!Begin(p,id,version,24,guid,slot,pack))return true;
 auto ref=CharacterDatabase.Query("SELECT COUNT(*) FROM reborn_ev_outfit WHERE guid={} AND wardrobe={} AND slot={} AND item={}",p->GetGUID().GetCounter(),pack,slot,guid);
 if(!ref||!ref->Fetch()[0].Get<uint32>()){Error(p,id,"changed");return true;}
 auto*incoming=Carried(p,guid);std::unique_ptr<Item> loaded;
 if(!incoming){loaded=SharedLoad(p,guid);incoming=loaded.get();}
 if(!incoming||incoming->GetOwnerGUID()!=p->GetGUID()){Error(p,id,"missing");return true;}
 uint8 nativeSlot=uint8(slot-1);auto*old=p->GetItemByPos(INVENTORY_SLOT_BAG_0,nativeSlot);auto*off=p->GetItemByPos(INVENTORY_SLOT_BAG_0,EQUIPMENT_SLOT_OFFHAND);
 if((old?old->GetGUID().GetCounter():0)!=oldGuid||(nativeSlot==EQUIPMENT_SLOT_MAINHAND&&(off?off->GetGUID().GetCounter():0)!=offGuid)){Error(p,id,"changed");return true;}
 if(incoming==old){Snapshot(p,id,pack);return true;}
 if(Worn(incoming)){Error(p,id,"wornelsewhere");return true;}
 std::vector<Displaced> moves;
 auto plan=[&](Item*it)->bool{
  if(!it)return true;
  if(p->CanUnequipItem(uint16(INVENTORY_SLOT_BAG_0)<<8|it->GetSlot(),false)!=EQUIP_ERR_OK){Error(p,id,"blocked");return false;}
  Displaced r{it,it->GetSlot(),it->GetGUID().GetCounter(),it->GetUInt32Value(ITEM_FIELD_FLAGS),{},0};
  if(!ReserveEmpty(p,r,moves)){Error(p,id,"equipfull");return false;}moves.push_back(r);return true;
 };
 auto*proto=incoming->GetTemplate();
 bool clearOff=nativeSlot==EQUIPMENT_SLOT_MAINHAND&&off&&
 ((!p->CanDualWield()&&(off->GetTemplate()->InventoryType==INVTYPE_WEAPONOFFHAND||off->GetTemplate()->InventoryType==INVTYPE_WEAPON))||
 proto->SubClass==ITEM_SUBCLASS_WEAPON_POLEARM||proto->SubClass==ITEM_SUBCLASS_WEAPON_STAFF||proto->SubClass==ITEM_SUBCLASS_WEAPON_FISHING_POLE||
 (!p->CanTitanGrip()&&(proto->InventoryType==INVTYPE_2HWEAPON||off->GetTemplate()->InventoryType==INVTYPE_2HWEAPON)));
 if(clearOff&&!plan(off))return true;if(!plan(old))return true;
 uint16 destination=0;if(p->CanEquipItem(nativeSlot,destination,incoming,true)!=EQUIP_ERR_OK||destination!=(uint16(INVENTORY_SLOT_BAG_0)<<8|nativeSlot)){Error(p,id,"cantwear");return true;}
 // Save the post-equip binding into the transaction without mutating a live bag item before COMMIT.
 uint32 originalFlags=incoming->GetUInt32Value(ITEM_FIELD_FLAGS);
 bool bind=proto->Bonding==BIND_WHEN_EQUIPPED||proto->Bonding==BIND_WHEN_PICKED_UP||proto->Bonding==BIND_QUEST_ITEM;
 auto tx=Start(p,version);if(bind)incoming->SetFlag(ITEM_FIELD_FLAGS,ITEM_FIELD_FLAG_SOULBOUND);
 incoming->AppendVaultSnapshot(tx);incoming->SetUInt32Value(ITEM_FIELD_FLAGS,originalFlags);
 for(auto const&r:moves){tx->Append("UPDATE character_inventory SET bag={},slot={} WHERE guid={} AND item={} AND bag=0 AND slot={}",r.bagGuid,uint32(r.dest[0].pos&255),p->GetGUID().GetCounter(),r.guid,uint32(r.slot));tx->ExpectAffectedRows(1);}
 if(loaded){tx->Append("DELETE FROM reborn_ev_pool WHERE guid={} AND item={}",p->GetGUID().GetCounter(),guid);tx->ExpectAffectedRows(1);tx->Append("INSERT INTO character_inventory (guid,bag,slot,item) VALUES ({},0,{},{})",p->GetGUID().GetCounter(),uint32(nativeSlot),guid);}
 else {tx->Append("UPDATE character_inventory SET bag=0,slot={} WHERE guid={} AND item={}",uint32(nativeSlot),p->GetGUID().GetCounter(),guid);tx->ExpectAffectedRows(1);}
 if(!Commit(p,id,tx,version,24,guid,slot,pack))return true;
 auto reconcile=[&](){p->RequireVaultReconcile();p->GetSession()->KickPlayer("EV3S equip mismatch");};
 for(auto const&r:moves){p->RemoveItem(INVENTORY_SLOT_BAG_0,r.slot,true);auto*stored=p->StoreItem(r.dest,r.item,true);if(!stored||stored->GetGUID().GetCounter()!=r.guid){reconcile();return true;}stored->SetUInt32Value(ITEM_FIELD_FLAGS,r.flags);}
 if(loaded){loaded.release();p->ItemAddedQuestCheck(incoming->GetEntry(),incoming->GetCount());}
 else p->RemoveItem(incoming->GetBagSlot(),incoming->GetSlot(),true);
 if(p->GetItemByPos(INVENTORY_SLOT_BAG_0,nativeSlot)){reconcile();return true;}
 auto*actual=p->EquipItem(destination,incoming,true);if(!actual||actual->GetGUID().GetCounter()!=guid){reconcile();return true;}
 p->UpdateTitansGrip();Snapshot(p,id,pack);return true;
}
bool SharedMoveToBag(ChatHandler*h,uint32 id,uint32 version,uint32 slot,uint32 guid,uint32 pack,bool returning)
{
 auto*p=h->GetSession()->GetPlayer();uint32 kind=returning?26:25;if(!Begin(p,id,version,kind,guid,slot,pack))return true;
 auto*it=p->GetItemByPos(INVENTORY_SLOT_BAG_0,uint8(slot-1));
 if(!it||it->GetGUID().GetCounter()!=guid){Error(p,id,"changed");return true;}
 // Only clear a target-empty slot, or move an original used in another target slot.
 auto q=CharacterDatabase.Query("SELECT COUNT(*) FROM reborn_ev_outfit WHERE guid={} AND wardrobe={} AND slot={} AND item={}",p->GetGUID().GetCounter(),pack,slot,guid);
 if(returning)
 {
  // Explicit return allows only an original referenced by this selected outfit.
  q=CharacterDatabase.Query("SELECT COUNT(*) FROM reborn_ev_outfit WHERE guid={} AND wardrobe={} AND item={}",p->GetGUID().GetCounter(),pack,guid);
  if(!q||!q->Fetch()[0].Get<uint32>()){Error(p,id,"changed");return true;}
 }
 else if(!q||q->Fetch()[0].Get<uint32>()){Error(p,id,"changed");return true;}
 if(p->CanUnequipItem(uint16(INVENTORY_SLOT_BAG_0)<<8|uint16(slot-1),false)!=EQUIP_ERR_OK){Error(p,id,"blocked");return true;}
 Displaced row{it,uint8(slot-1),guid,it->GetUInt32Value(ITEM_FIELD_FLAGS),{},0};std::vector<Displaced> none;
 if(!ReserveEmpty(p,row,none)){Error(p,id,"equipfull");return true;}
 auto tx=Start(p,version);tx->Append("UPDATE character_inventory SET bag={},slot={} WHERE guid={} AND item={} AND bag=0 AND slot={}",row.bagGuid,uint32(row.dest[0].pos&255),p->GetGUID().GetCounter(),guid,slot-1);tx->ExpectAffectedRows(1);
 if(!Commit(p,id,tx,version,kind,guid,slot,pack))return true;
 p->RemoveItem(INVENTORY_SLOT_BAG_0,uint8(slot-1),true);auto*actual=p->StoreItem(row.dest,it,true);
 if(!actual||actual->GetGUID().GetCounter()!=guid){p->RequireVaultReconcile();p->GetSession()->KickPlayer("EV3S unequip mismatch");return true;}
 actual->SetUInt32Value(ITEM_FIELD_FLAGS,row.flags);Snapshot(p,id,pack);return true;
}
bool SharedUnequip(ChatHandler*h,uint32 id,uint32 version,uint32 slot,uint32 guid,uint32 pack)
{return SharedMoveToBag(h,id,version,slot,guid,pack,false);}
bool SharedReturn(ChatHandler*h,uint32 id,uint32 version,uint32 slot,uint32 guid,uint32 pack)
{return SharedMoveToBag(h,id,version,slot,guid,pack,true);}
bool SharedLinked(ChatHandler*h,uint32 id,uint32 version,uint32 slot,uint32 guid,uint32 oldGuid,uint32 offGuid,uint32 pack,uint32 build,uint32 buildRevision,uint32 clear)
{
 auto*p=h->GetSession()->GetPlayer();auto info=ReadBuildLinks(p);
 if(!info.available||build>2||info.active!=build||info.revision!=buildRevision||info.spec==3||info.packs[build]!=pack||clear>1){Error(p,id,"buildchanged");return true;}
 return clear?SharedUnequip(h,id,version,slot,guid,pack):SharedEquip(h,id,version,slot,guid,oldGuid,offGuid,pack);
}
