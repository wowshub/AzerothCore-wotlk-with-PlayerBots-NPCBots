// WD187A: private Witch Doctor placement only. Not a native totem-slot change.
#pragma once
namespace WD187
{
// Relative to facing: Ward front-left, Idol rear-left, Effigy rear-right,
// Mimic front-right. A single summon uses the same corner as a ritual cast.
inline float Angle(int slot) { return 0.785398163f + float(slot) * 1.570796327f; }
inline Position MimicPosition(Player* player, uint32 index)
{
    Position pos=player->GetPosition();
    // Keep the first copy in its corner; talented extra copies fan outward
    // within that quadrant. Existing counts, ownership and replacement stay intact.
    float angle=Angle(3)+(index==1 ? -0.30f : index==2 ? 0.30f : 0.0f);
    player->MovePositionToFirstCollision(pos,index ? 2.5f : 1.5f,angle);
    return pos;
}
}
