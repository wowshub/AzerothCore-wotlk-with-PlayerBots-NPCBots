#include "CharacterSelectionDisplay.h"

#include "Engine/Source/Model2/M2Model.h"

#include "WoW/Common/ComponentCore/CharacterComponent.h"

#include "WoW/Common/ComponentCore/RetailRace.h"

#include "WoW/Source/Glue/CGlueMgr.h"

#include "WoW/Source/Glue/CharacterSelection.h"

#include "WoW/Source/Glue/ComponentData.h"

#include "WoW/Source/Glue/CGlueLoading.h"

#include "WoW/Source/Glue/CSimpleModelFFX.h"

#include "Engine/Source/Model2/M2Scene.h"

#include <cstdlib>



CCharacterComponent* CharacterSelectionDisplay::m_formMirror;
static CM2Model* s_readyMirror=nullptr;
static float s_readyMirrorAlpha=1.0f;



// Sideways offset of the second form from the selected one, along the model frame's horizontal axis.

// WOW_FORM_SELECT_SPACING and WOW_FORM_SELECT_AXIS ("x" or "y") tune it without a rebuild.

static void FormMirrorOffset(float& x, float& y) {

    x = y = 0.0f;

    const char* spacing = std::getenv("WOW_FORM_SELECT_SPACING");

    const char* axis = std::getenv("WOW_FORM_SELECT_AXIS");

    (axis && (axis[0] == 'x' || axis[0] == 'X') ? x : y) = spacing ? static_cast<float>(std::atof(spacing)) : 1.2f;

}



void CharacterSelectionDisplay::ClearFormMirror() {

    CCharacterComponent* mirror = m_formMirror;

    if (!mirror) {

        return;

    }



    if(s_readyMirror&&mirror->m_data.m_model==s_readyMirror)
        s_readyMirror->m_fadeAlpha=s_readyMirrorAlpha;
    s_readyMirror=nullptr;
    m_formMirror = nullptr;



    if (mirror->m_data.m_model && mirror->m_data.m_model->m_attachParent) {

        mirror->m_data.m_model->DetachFromParent();

    }



    // HELM2B: detach only. The roster entry owns and releases the cached second form.

}



void CharacterSelectionDisplay::TickFormMirror() {
    if(!m_formMirror||!m_formMirror->m_data.m_model)return;
    auto* model=m_formMirror->m_data.m_model;
    if(s_readyMirror!=model){s_readyMirror=model;s_readyMirrorAlpha=model->m_fadeAlpha;}
    const bool prepared=m_formMirror->RenderPrep(0);
    const bool drawable=model->IsDrawable(0,1);
    if(m_formMirror->m_data.m_preferences.m_raceID==27)
        model->m_fadeAlpha=prepared&&!m_formMirror->m_dirtySections&&!(m_formMirror->m_flags&1)&&drawable?s_readyMirrorAlpha:0.0f;
}

void CharacterSelectionDisplay::ShowFormMirror(CharacterSelectionDisplay& display) {

    ClearFormMirror();



    const CHARACTER_INFO& info = display.m_characterInfo;

    uint32_t form = 0;



    if (!CCharacterSelection::m_modelFrame || !CCharacterSelection::m_modelFrame->m_model || !display.m_component || !display.m_component->m_data.m_model

        || !RetailRaceParkedForm(info.m_guid.m_guid, form)) {

        return;

    }



    // Reuse only within this roster snapshot. A roster refresh destroys the entry.

    if (display.m_cachedFormMirror) {

        m_formMirror = display.m_cachedFormMirror;

        m_formMirror->m_data.m_model->m_lightingArg = CCharacterSelection::m_modelFrame->m_lightArray2;

        m_formMirror->m_data.m_model->AttachToParent(CCharacterSelection::m_modelFrame->m_model, 0, nullptr, 0);

        return;

    }



    char path[260];



    if (!RetailRaceModelPath(info.m_raceID, info.m_sexID, path, sizeof(path), form)) {

        return;

    }



    ComponentData data;

    data.m_preferences.m_raceID = info.m_raceID;

    data.m_preferences.m_sexID = info.m_sexID;

    data.m_preferences.m_classId = info.m_classID;

    data.m_model = CCharacterSelection::m_modelFrame->GetScene()->CreateModel(path, 0);



    if (!data.m_model) {

        return;

    }



    data.m_flags |= 0x2;

    CCharacterComponent* mirror = CCharacterComponent::AllocComponent();

    mirror->Init(&data, nullptr);



    if (!RetailRaceApplyParkedTo(mirror, info.m_guid.m_guid)) {

        CCharacterComponent::FreeComponent(mirror);

        return;

    }



    data.m_model->m_lightingCallback = &CCharacterSelection::GenericLightingCallback;

    data.m_model->m_lightingArg = CCharacterSelection::m_modelFrame->m_lightArray2;

    data.m_model->SetBoneSequence(0xFFFFFFFF, 0, 0xFFFFFFFF, 0, 1.0f, 1, 1);



    CCharacterSelection::DressComponent(info, mirror);

    data.m_model->AttachToParent(CCharacterSelection::m_modelFrame->m_model, 0, nullptr, 0);

    m_formMirror = mirror;

    display.m_cachedFormMirror = mirror;

    // Queue texture/equipment work; do not synchronously wait for the second form.

    TickFormMirror();

}



// INLINED

CharacterSelectionDisplay::CharacterSelectionDisplay() {

    this->m_component = nullptr;

    this->m_cachedFormMirror = nullptr;

    this->m_petAlpha = 1.0f;

    this->m_petModel = nullptr;

}



// INLINED

CharacterSelectionDisplay::~CharacterSelectionDisplay() {

    if (m_formMirror == this->m_cachedFormMirror) ClearFormMirror();

    if (this->m_cachedFormMirror) {

        CCharacterComponent::FreeComponent(this->m_cachedFormMirror);

        this->m_cachedFormMirror = nullptr;

    }



    if (this->m_petModel) {

        this->m_petModel->Release();

    }



    if (this->m_component) {

        CCharacterComponent::FreeComponent(this->m_component);

        this->m_component = nullptr;

    }

}



// VERIFY: 4e7bb4fe auto

// OFFSET: 0x004D9160

int32_t CharacterSelectionDisplay::SetSelectedCharacterInfo(CHARACTER_INFO* info) {

    CGlueMgr::m_characterInfo = info;



    if (!info) {

        return 0;

    }



    CGlueMgr::s_displayedCharacterIndex = CCharacterSelection::s_selectionIndex;

    return 1;

}



// VERIFY: 96adbffe manual

// OFFSET: 0x004E2E70

void CharacterSelectionDisplay::SetCharacterFacing(float rotation) {

    if (!CCharacterSelection::s_characterCount) {

        return;

    }



    CCharacterSelection::s_charFacing = rotation;



    if (CCharacterSelection::s_characterList.Count() <= 0) {

        return;

    }



    CharacterSelectionDisplay& display = CCharacterSelection::s_characterList[CCharacterSelection::s_selectionIndex];



    if (display.m_component->m_data.m_model) {

        C3Vector position(0.0f, 0.0f, 0.0f);

        display.m_component->m_data.m_model->SetWorldTransform(position, rotation,

            RetailRacePreviewScale(display.m_characterInfo.m_raceID) *

            (display.m_characterInfo.m_raceID == 78 ? 0.68f :
             display.m_characterInfo.m_raceID == 41 ? 0.70f :
             display.m_characterInfo.m_raceID == 108 ? 0.60f :

             display.m_characterInfo.m_raceID == 57 && display.m_characterInfo.m_sexID == 0 ? 0.55f : 1.0f) *

            (display.m_characterInfo.m_classID == 6 ? 0.78f : 1.0f)); // EQUIP1A: match the accepted creator framing, selection only.

    }



    if (m_formMirror && m_formMirror->m_data.m_model) {

        C3Vector position(0.0f, 0.0f, 0.0f);

        FormMirrorOffset(position.x, position.y);

        m_formMirror->m_data.m_model->SetWorldTransform(position, rotation,

            RetailRacePreviewScale(display.m_characterInfo.m_raceID) *

            (display.m_characterInfo.m_classID == 6 ? 0.78f : 1.0f)); // WOW64CREATOR1E: selection-only DK framing

    }

}

