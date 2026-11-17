#ifndef ENGINE_MODEL2_SEQUENCE_ALIASES_H
#define ENGINE_MODEL2_SEQUENCE_ALIASES_H
#include <cstdint>
#include <vector>
// JOY2A: on disk, aliasNext is meaningful only for flag-0x40 aliases.
// Runtime streaming walks a circular list which includes the owning sequence.
template<class Array> bool M2BuildSequenceAliasRings(Array& sequences) {
    const uint32_t count=sequences.m_count;
    if(count>65535)return false;
    std::vector<uint16_t> owner(count,0xffff),next(count);
    for(uint32_t i=0;i<count;++i)
        if(!(sequences[i].m_flags&0x40))owner[i]=static_cast<uint16_t>(i);
    // CENTAUR2B: converted HD models may contain unused cyclic aliases.
    // Keep their valid animations/model loadable; redirect only broken chains
    // to the first real owner (normally Stand), preserving all flags/tracks.
    uint32_t fallback=count;
    for(uint32_t i=0;i<count;++i)if(owner[i]!=0xffff){fallback=i;break;}
    if(count&&fallback==count)return false;
    for(uint32_t i=0;i<count;++i) {
        uint32_t current=i,steps=0;
        std::vector<uint16_t> path;
        while(current<count&&owner[current]==0xffff&&steps++<count) {
            path.push_back(static_cast<uint16_t>(current));
            current=sequences[current].m_aliasNext;
        }
        const uint16_t resolved=current<count&&owner[current]!=0xffff?owner[current]:static_cast<uint16_t>(fallback);
        for(uint16_t alias:path)owner[alias]=resolved;
    }
    for(uint32_t i=0;i<count;++i)next[i]=static_cast<uint16_t>(i);
    for(uint32_t i=0;i<count;++i)if(owner[i]!=i) {
        next[i]=next[owner[i]];next[owner[i]]=static_cast<uint16_t>(i);
    }
    for(uint32_t i=0;i<count;++i)sequences[i].m_aliasNext=next[i];
    return true;
}
#endif
