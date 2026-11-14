// WOW64RACEPORT1A: native adapter for the CURRENT Reborn converted-model catalogs.
// No donor race-ID substitution, no extra appearance footer, no model rewrite.
#ifndef REBORN_CATALOG_APPEARANCE_H
#define REBORN_CATALOG_APPEARANCE_H
#include <array>
#include <cstdint>
#include <cstring>
#include <vector>
namespace RebornCatalog {
enum Profile { None, Venthyr, Centaur, Vorkai, Tarasek, Mechagnome, EarthenEyes };
struct Option { unsigned field, count, factor; };
inline Profile Resolve(uint32_t race, const char* token) {
    if (!token) return None;
    if (race==67 && !std::strcmp(token,"Mechagnome")) return Mechagnome;
    if (race==68 && !std::strcmp(token,"Earthen")) return EarthenEyes;
    if (race==99 && !std::strcmp(token,"DrakkinAlliance")) return Tarasek;
    if (race==101 && (!std::strcmp(token,"VenthyrHorde") || !std::strcmp(token,"Venthyr"))) return Venthyr;
    if (race==102 && (!std::strcmp(token,"CentaurHorde") || !std::strcmp(token,"Centaur"))) return Centaur;
    if (race==110 && (!std::strcmp(token,"SylvariAlliance") || !std::strcmp(token,"Sylvari"))) return Vorkai;
    return None;
}
inline bool Enabled(Profile p, unsigned sex) { return p!=None && sex<2 && (p!=Tarasek || sex==0); }
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
    static const std::vector<Option> none;
    if (sex>1) return none;
    return p==Mechagnome ? (sex?mf:mm) : p==EarthenEyes ? ee : p==Venthyr ? (sex?vf:vm) : p==Centaur ? (sex?cf:cm) : p==Vorkai ? vk : p==Tarasek && !sex ? tm : none;
}
inline const std::vector<const char*>& Labels(Profile p, unsigned sex) {
    static const std::vector<const char*> v={"Skin Color","Accessory Palette","Hair Color","Body Style","Hair Style","Facial Features","Collar","Headwear"};
    static const std::vector<const char*> cm={"Skin Color","Hair Style","Facial Features"}, cf={"Skin Color","Hair Style"};
    static const std::vector<const char*> tm={"Skin Color","Face","Crest Style","Eye Color","Facial Features"};
    static const std::vector<const char*> mm={"Skin Color","Face","Hair Style","Hair Color","Facial Hair","Arm Upgrade","Leg Upgrade","Modification","Eye Color","Paint","Eyesight","Eye Style"}, ee={"Skin Color","Face","Hair Style","Hair Color","Beard Style","Eye Color","Eyesight"};
    return p==Mechagnome?mm:p==EarthenEyes?ee:p==Tarasek?tm:p==Venthyr?v:p==Centaur&&sex?cf:cm;
}
inline const wchar_t* Catalog(Profile p) {
    return p==Mechagnome ? L"RebornNativeMechagnome.bin" : p==EarthenEyes ? L"RebornNativeEarthenEyes.bin" : p==Venthyr ? L"RebornNativeVenthyr.bin" : p==Centaur ? L"RebornNativeCentaur.bin" : p==Vorkai ? L"RebornNativeVorkai.bin" : p==Tarasek ? L"RebornNativeTarasek.bin" : nullptr;
}
inline float PreviewScale(Profile p) { return p==Centaur ? 0.60f : p==Venthyr ? 0.75f : 1.0f; }
}
#endif
