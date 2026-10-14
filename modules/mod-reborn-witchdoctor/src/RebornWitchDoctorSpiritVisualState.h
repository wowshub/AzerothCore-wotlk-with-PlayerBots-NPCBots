#ifndef REBORN_WD147_DIAGNOSTICS_H
#define REBORN_WD147_DIAGNOSTICS_H
#include "DataMap.h"
namespace WD147Diagnostic {
constexpr char Key[]="RebornWD147B.OrbState";
struct State : DataMap::Base {
    uint32 updates=0, attempts=0, failures=0, missing=0;
};
}
#endif
