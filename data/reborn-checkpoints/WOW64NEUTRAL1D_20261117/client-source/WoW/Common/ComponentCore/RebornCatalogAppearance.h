// WOW64RACEPORT1A: native adapter for the CURRENT Reborn converted-model catalogs.
// No donor race-ID substitution, no extra appearance footer, no model rewrite.
#ifndef REBORN_CATALOG_APPEARANCE_H
#define REBORN_CATALOG_APPEARANCE_H
#include <array>
#include <cstdint>
#include <cstring>
#include <vector>
namespace RebornCatalog {
enum Profile { None, Venthyr, Centaur, Vorkai, Tarasek, Mechagnome, EarthenEyes, Gnoll, Saberon, Drakonid, Banshee, Hozen, Mantid };
struct Option { unsigned field, count, factor; };
inline Profile Resolve(uint32_t race, const char* token) {
    if (!token) return None;
    if (race==67 && !std::strcmp(token,"Mechagnome")) return Mechagnome;
    if (race==68 && !std::strcmp(token,"Earthen")) return EarthenEyes;
    if (race==99 && !std::strcmp(token,"DrakkinAlliance")) return Tarasek;
    if (race==101 && (!std::strcmp(token,"VenthyrHorde") || !std::strcmp(token,"Venthyr"))) return Venthyr;
    if (race==102 && (!std::strcmp(token,"CentaurHorde") || !std::strcmp(token,"Centaur"))) return Centaur;
    if (race==110 && (!std::strcmp(token,"SylvariAlliance") || !std::strcmp(token,"Sylvari"))) return Vorkai;
    if (race==83 && !std::strcmp(token,"GnollHorde")) return Gnoll;
    if (race==97 && !std::strcmp(token,"SaberonHorde")) return Saberon;
    if (race==98 && !std::strcmp(token,"DrakonidHorde")) return Drakonid;
    if (race==90 && !std::strcmp(token,"BansheeHorde")) return Banshee;
    if (race==112 && !std::strcmp(token,"HozenAlliance")) return Hozen;
    if (race==106 && !std::strcmp(token,"MantidHorde")) return Mantid;
    return None;
}
inline bool Enabled(Profile p, unsigned sex) { return p!=None && sex<2 && ((p!=Tarasek && p!=Gnoll && p!=Saberon && p!=Drakonid) || sex==0); }
inline const std::vector<Option>& Options(Profile p, unsigned sex) {
    // Selector order taken from the installed EHM1 catalogs, NOT from donor race numbers.
    static const std::vector<Option> vm={{0,7,1},{2,8,1},{3,7,1},{1,1,1},{4,8,1},{4,4,8},{1,1,1},{1,1,1}};
    static const std::vector<Option> vf={{0,6,1},{2,6,1},{3,6,1},{1,1,1},{4,8,1},{4,5,8},{1,1,1},{1,1,1}};
    static const std::vector<Option> cm={{0,16,1},{2,4,1},{4,8,1}};
    static const std::vector<Option> cf={{0,16,1},{2,8,1}};
    static const std::vector<Option> vk={{0,8,1},{2,3,1},{4,3,1}};
    static const std::vector<Option> tm={{0,7,1},{1,1,1},{2,5,1},{3,7,1},{4,1,1}};
    static const std::vector<Option> mm={{0,8,1},{1,14,1},{2,7,1},{3,7,1},{1,6,14},{2,4,7},{2,2,28},{4,20,1},{3,33,7},{0,3,8},{0,4,24},{4,3,20}};
    static const std::vector<Option> mf={{0,8,1},{1,14,1},{2,9,1},{3,7,1},{1,1,14},{2,4,9},{2,2,36},{4,20,1},{3,33,7},{0,3,8},{0,4,24},{4,3,20}};
    static const std::vector<Option> ee={{0,14,1},{1,10,1},{2,11,1},{3,14,1},{4,11,1},{3,14,14},{1,4,10}};
    static const std::vector<Option> gn={{0,10,1},{1,6,1},{1,3,6},{1,3,18},{0,3,10},{2,3,1},{2,4,3},{2,5,12},{3,2,1},{3,2,2},{0,4,30},{3,2,4},{3,3,8},{3,2,24},{4,3,1}};
    static const std::vector<Option> sb={{0,4,1},{1,10,1},{2,3,1},{3,3,1},{4,1,1}};
    static const std::vector<Option> dk={{0,17,1},{1,2,1},{2,6,1},{1,2,2},{3,76,1}};
    static const std::vector<Option> bs={{0,6,1},{1,8,1}}, hz={{0,18,1}}, mt={{0,8,1},{2,6,1}};
    static const std::vector<Option> none;
    if (sex>1) return none;
    return p==Gnoll?gn:p==Saberon?sb:p==Drakonid?dk:p==Banshee?bs:p==Hozen?hz:p==Mantid?mt:p==Mechagnome ? (sex?mf:mm) : p==EarthenEyes ? ee : p==Venthyr ? (sex?vf:vm) : p==Centaur ? (sex?cf:cm) : p==Vorkai ? vk : p==Tarasek && !sex ? tm : none;
}
inline const std::vector<const char*>& Labels(Profile p, unsigned sex) {
    static const std::vector<const char*> v={"Skin Color","Accessory Palette","Hair Color","Body Style","Hair Style","Facial Features","Collar","Headwear"};
    static const std::vector<const char*> cm={"Skin Color","Hair Style","Facial Features"}, cf={"Skin Color","Hair Style"};
    static const std::vector<const char*> tm={"Skin Color","Face","Crest Style","Eye Color","Facial Features"};
    static const std::vector<const char*> mm={"Skin Color","Face","Hair Style","Hair Color","Facial Hair","Arm Upgrade","Leg Upgrade","Modification","Eye Color","Paint","Eyesight","Eye Style"}, ee={"Skin Color","Face","Hair Style","Hair Color","Beard Style","Eye Color","Eyesight"};
    static const std::vector<const char*> gn={"Fur Color","Mane","Beard","Ears","Eyes","Outfit Color","Chest Sling","Cuffs","Waist","Loincloth","Tail","Leg Wraps","Pauldrons","Belt Strap","Trousers"};
    static const std::vector<const char*> dk={"Skin Color","Head","Horns","Tail","Eye Color"};
    static const std::vector<const char*> sb={"Fur Color","Outfit Style","Armor Color","Cloth Color","Facial Features"},bs={"Skin Color","Outfit Color"},hz={"Fur Color"},mt={"Skin Color","Crest Style"};
    return p==Gnoll?gn:p==Saberon?sb:p==Drakonid?dk:p==Banshee?bs:p==Hozen?hz:p==Mantid?mt:p==Mechagnome?mm:p==EarthenEyes?ee:p==Tarasek?tm:p==Venthyr?v:p==Centaur&&sex?cf:cm;
}
inline const wchar_t* Catalog(Profile p) {
    return p==Gnoll?L"EsteriaGnoll.bin":p==Saberon?L"EsteriaSaberon.bin":p==Drakonid?L"EsteriaDrakonid.bin":p==Banshee?L"EsteriaBanshee.bin":p==Hozen?L"EsteriaHozen.bin":p==Mantid?L"EsteriaMantid.bin":p==Mechagnome ? L"RebornNativeMechagnome.bin" : p==EarthenEyes ? L"RebornNativeEarthenEyes.bin" : p==Venthyr ? L"RebornNativeVenthyr.bin" : p==Centaur ? L"RebornNativeCentaur.bin" : p==Vorkai ? L"RebornNativeVorkai.bin" : p==Tarasek ? L"RebornNativeTarasek.bin" : nullptr;
}
inline float PreviewScale(Profile p) { return p==Centaur ? 0.60f : p==Venthyr ? 0.75f : 1.0f; }
}
#endif
