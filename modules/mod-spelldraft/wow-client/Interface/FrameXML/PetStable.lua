-- 99格右侧扩展仓库：原版1-4格不动，右侧5列x8行浏览第5-99格。
NUM_PET_STABLE_SLOTS = 99;
NUM_PET_STABLE_BASE_SLOTS = 4;
NUM_PET_STABLE_VISIBLE_SLOTS = 40;
NUM_PET_STABLE_COLUMNS = 5;
NUM_PET_STABLE_VISIBLE_ROWS = 8;
PET_STABLE_FIRST_VISIBLE_SLOT = 5;
PET_STABLE_LAST_NUM_SLOTS = nil;
PET_STABLE_UPDATING_SCROLLBAR = nil;

function PetStableExtensionPanel_OnLoad(self)
	self:SetBackdropColor(0.015, 0.02, 0.03, 0.92);
	self:SetBackdropBorderColor(0.62, 0.48, 0.16, 0.95);

	for i=1, NUM_PET_STABLE_VISIBLE_SLOTS do
		local button = CreateFrame("CheckButton", "PetStableExtendedPet"..i, self, "PetStableExtendedSlotTemplate");
		local column = mod(i - 1, NUM_PET_STABLE_COLUMNS);
		local row = floor((i - 1) / NUM_PET_STABLE_COLUMNS);
		button:SetPoint("TOPLEFT", self, "TOPLEFT", 18 + column * 44, -42 - row * 44);
		button:SetID(NUM_PET_STABLE_BASE_SLOTS + i);
	end
end

function PetStableSlotScrollUp_OnClick(self)
	local scrollBar = self:GetParent();
	scrollBar:SetValue(scrollBar:GetValue() - 1);
	PlaySound("UChatScrollButton");
end

function PetStableSlotScrollDown_OnClick(self)
	local scrollBar = self:GetParent();
	scrollBar:SetValue(scrollBar:GetValue() + 1);
	PlaySound("UChatScrollButton");
end

function PetStableSlotScrollBar_OnValueChanged(self, value)
	if ( PET_STABLE_UPDATING_SCROLLBAR ) then
		return;
	end

	local rowOffset = floor(value + 0.5);
	local firstSlot = NUM_PET_STABLE_BASE_SLOTS + 1 + rowOffset * NUM_PET_STABLE_COLUMNS;
	if ( firstSlot ~= PET_STABLE_FIRST_VISIBLE_SLOT ) then
		PET_STABLE_FIRST_VISIBLE_SLOT = firstSlot;
		if ( PetStableFrame and PetStableFrame:IsShown() ) then
			PetStable_Update();
		end
	end
end

function PetStable_UpdateSlotScrollBar(numSlots)
	-- 购买成功后自动把最新栏位滚入可见区域。
	if ( PET_STABLE_LAST_NUM_SLOTS and numSlots > PET_STABLE_LAST_NUM_SLOTS ) then
		local newestRow = max(0, floor((numSlots - NUM_PET_STABLE_BASE_SLOTS - 1) / NUM_PET_STABLE_COLUMNS));
		local firstRow = max(0, newestRow - NUM_PET_STABLE_VISIBLE_ROWS + 1);
		PET_STABLE_FIRST_VISIBLE_SLOT = NUM_PET_STABLE_BASE_SLOTS + 1 + firstRow * NUM_PET_STABLE_COLUMNS;
	end
	PET_STABLE_LAST_NUM_SLOTS = numSlots;

	-- 右侧只计算第5-99格，并额外展示下一个待购买栏位。
	local contentSlots = max(0, min(NUM_PET_STABLE_SLOTS, numSlots + 1) - NUM_PET_STABLE_BASE_SLOTS);
	local totalRows = floor((contentSlots + NUM_PET_STABLE_COLUMNS - 1) / NUM_PET_STABLE_COLUMNS);
	local maxRowOffset = max(0, totalRows - NUM_PET_STABLE_VISIBLE_ROWS);
	local currentRowOffset = floor((PET_STABLE_FIRST_VISIBLE_SLOT - NUM_PET_STABLE_BASE_SLOTS - 1) / NUM_PET_STABLE_COLUMNS);
	currentRowOffset = min(max(0, currentRowOffset), maxRowOffset);
	PET_STABLE_FIRST_VISIBLE_SLOT = NUM_PET_STABLE_BASE_SLOTS + 1 + currentRowOffset * NUM_PET_STABLE_COLUMNS;

	PET_STABLE_UPDATING_SCROLLBAR = 1;
	PetStableSlotScrollBar:SetMinMaxValues(0, maxRowOffset);
	PetStableSlotScrollBar:SetValueStep(1);
	PetStableSlotScrollBar:SetValue(currentRowOffset);
	PET_STABLE_UPDATING_SCROLLBAR = nil;

	local lastVisibleSlot = min(NUM_PET_STABLE_SLOTS, PET_STABLE_FIRST_VISIBLE_SLOT + NUM_PET_STABLE_VISIBLE_SLOTS - 1);
	PetStableSlotRangeText:SetFormattedText("扩展兽栏 %d - %d / %d", PET_STABLE_FIRST_VISIBLE_SLOT, lastVisibleSlot, NUM_PET_STABLE_SLOTS);

	if ( maxRowOffset > 0 ) then
		PetStableSlotScrollBar:Enable();
		PetStableSlotScrollBarScrollUpButton:Enable();
		PetStableSlotScrollBarScrollDownButton:Enable();
	else
		PetStableSlotScrollBar:Disable();
		PetStableSlotScrollBarScrollUpButton:Disable();
		PetStableSlotScrollBarScrollDownButton:Disable();
	end
end

function PetStable_OnLoad(self)
	self:RegisterEvent("PET_STABLE_SHOW");
	self:RegisterEvent("PET_STABLE_UPDATE");
	self:RegisterEvent("PET_STABLE_UPDATE_PAPERDOLL");
	self:RegisterEvent("PET_STABLE_CLOSED");
	self:RegisterEvent("UNIT_PET");
	self:RegisterEvent("UNIT_NAME_UPDATE");
end

-- The stock 3.3.5 client reports the second HasPetUI result as false whenever the
-- PLAYER class is not Hunter, even when SpellDraft has given that character a real
-- HUNTER_PET.  Accept Tame Beast / Call Pet as the client-side hunter-pet identity.
-- This is deliberately spell-gated so warlock demons, DK ghouls and mage elementals
-- still cannot be placed in the hunter stable.
function PetStable_GetHunterPetUI()
	local hasPetUI, isHunterPet = HasPetUI();
	if ( isHunterPet ) then
		return hasPetUI, true;
	end

	local knowsHunterPetSystem = IsSpellKnown and
		(IsSpellKnown(1515) or IsSpellKnown(883));
	if ( knowsHunterPetSystem and
		((UnitExists("pet") and hasPetUI) or GetStablePetInfo(0)) ) then
		return true, true;
	end

	return hasPetUI, false;
end

function PetStable_OnEvent(self, event, ...)
	local arg1 = ...;
	if ( event == "PET_STABLE_SHOW" ) then
		ShowUIPanel(self);
		if ( not self:IsShown() ) then
			ClosePetStables();
			return;
		end

		PetStable_Update();
	elseif ( event == "PET_STABLE_UPDATE" or
	         (event == "UNIT_PET" and arg1 == "player") or
			 (event == "UNIT_NAME_UPDATE" and arg1 == "pet") ) then
		PetStable_Update();
	elseif ( event == "PET_STABLE_UPDATE_PAPERDOLL" ) then
		-- So warlock pets don't show
		local hasPetUI, isHunterPet = PetStable_GetHunterPetUI();
		if ( UnitExists("pet") and (not hasPetUI or not isHunterPet) ) then
			PetStable_NoPetsAllowed();
			return;
		end
		SetPetStablePaperdoll(PetStableModel);
	elseif ( event == "PET_STABLE_CLOSED" ) then
		HideUIPanel(self);
		StaticPopup_Hide("CONFIRM_BUY_STABLE_SLOT");
	end
end

function PetStable_Update()
	-- Set stablemaster portrait
	SetPortraitTexture(PetStableFramePortrait, "player");

	-- So warlock pets don't show
	local hasPetUI, isHunterPet = PetStable_GetHunterPetUI();
	if ( UnitExists("pet") and hasPetUI and not isHunterPet ) then
		PetStable_NoPetsAllowed();
		PetStableCurrentPet:Disable();
		return;
	else
		PetStableCurrentPet:Enable();
	end

	-- If no selected pet try to set one
	local selectedPet = GetSelectedStablePet();
	if ( selectedPet == -1 ) then
		if ( GetPetIcon() ) then
			selectedPet = 0;
			ClickStablePet(0);
		else
			for i=0, GetNumStableSlots() do
				if ( GetStablePetInfo(i) ) then
					selectedPet = i;
					ClickStablePet(i);
					break;
				end 
			end
		end
	end

	-- Set slot cost
	MoneyFrame_Update("PetStableCostMoneyFrame", GetNextStableSlotCost());	

	-- Set slot statuseses
	local numSlots = GetNumStableSlots();
	local numPets = GetNumStablePets();
	PetStable_UpdateSlotScrollBar(numSlots);

	local button, buttonName;
	local background;
	local icon, name, level, family, talent;
	for i=1, NUM_PET_STABLE_BASE_SLOTS + NUM_PET_STABLE_VISIBLE_SLOTS do
		local stableSlot;
		local slotNumber;
		if ( i <= NUM_PET_STABLE_BASE_SLOTS ) then
			stableSlot = i;
			buttonName = "PetStableStabledPet"..i;
		else
			local extensionIndex = i - NUM_PET_STABLE_BASE_SLOTS;
			stableSlot = PET_STABLE_FIRST_VISIBLE_SLOT + extensionIndex - 1;
			buttonName = "PetStableExtendedPet"..extensionIndex;
			slotNumber = _G[buttonName.."SlotNumber"];
		end
		button = _G[buttonName];
		button:SetID(stableSlot);
		if ( slotNumber ) then
			slotNumber:SetText(stableSlot);
		end
		background = _G[buttonName.."Background"];
		icon, name, level, family, talent = GetStablePetInfo(stableSlot);
		SetItemButtonTexture(button, icon);
		if ( stableSlot <= numSlots ) then
			background:SetVertexColor(1.0,1.0,1.0);
			if ( slotNumber ) then
				slotNumber:SetTextColor(1.0, 0.82, 0.0);
			end
			button:Enable();
			if ( icon ) then
				button.tooltip = name;
				button.tooltipSubtext = format(STABLE_PET_INFO_TOOLTIP_TEXT, level, family, talent);
			else
				button.tooltip = EMPTY_STABLE_SLOT;
				button.tooltipSubtext = "";
			end
			if ( stableSlot == selectedPet ) then
				if ( icon ) then
					button:SetChecked(1);
					PetStableLevelText:SetFormattedText(STABLE_PET_INFO_TEXT, name, level, family, talent);
					SetPetStablePaperdoll(PetStableModel);
					PetStablePetInfo.tooltip = format(PET_DIET_TEMPLATE, BuildListString(GetStablePetFoodTypes(stableSlot)));
					if ( not PetStableModel:IsShown() ) then
						PetStableModel:Show();
					end
				else
					button:SetChecked(nil);
					PetStableLevelText:SetText("");
					PetStableModel:Hide();
				end
				
			else
				button:SetChecked(nil);
			end
			if ( GameTooltip:IsOwned(button) ) then
				GameTooltip:SetOwner(button, "ANCHOR_RIGHT");
				GameTooltip:SetText(button.tooltip);
				GameTooltip:AddLine(button.tooltipSubtext, 1.0, 1.0, 1.0);
				GameTooltip:Show();
			end
		else
			background:SetVertexColor(1.0, 0.1, 0.1);
			if ( slotNumber ) then
				slotNumber:SetTextColor(0.85, 0.2, 0.2);
			end
			button:Disable();
		end
	end

	-- Current pet slot
	if ( selectedPet == 0 ) then
		if ( UnitExists("pet") and hasPetUI ) then
			PetStableCurrentPet:SetChecked(1);
			name = UnitName("pet") or "";
			level = UnitLevel("pet");
			family = UnitCreatureFamily("pet") or "";
			talent = GetPetTalentTree() or "";
			PetStableLevelText:SetFormattedText(STABLE_PET_INFO_TEXT, name, level, family, talent);
			SetPetStablePaperdoll(PetStableModel);
			if ( not PetStableModel:IsShown() ) then
				PetStableModel:Show();
			end
			if ( GetPetFoodTypes() ) then
				PetStablePetInfo.tooltip = format(PET_DIET_TEMPLATE, BuildListString(GetPetFoodTypes()));
			end
		elseif ( GetStablePetInfo(0) ) then
			-- If pet doesn't exist it might be dismissed, so check stable slot 0 for current pet info
			PetStableCurrentPet:SetChecked(1);
			icon, name, level, family, talent = GetStablePetInfo(0);
			PetStableLevelText:SetFormattedText(STABLE_PET_INFO_TEXT, name, level, family, talent);
			SetPetStablePaperdoll(PetStableModel);
			if ( not PetStableModel:IsShown() ) then
				PetStableModel:Show();
			end
			if ( GetStablePetFoodTypes(0) ) then
				PetStablePetInfo.tooltip = format(PET_DIET_TEMPLATE, BuildListString(GetStablePetFoodTypes(0)));
			end
		else
			PetStableCurrentPet:SetChecked(nil);
			PetStableLevelText:SetText("");
			PetStableModel:Hide();
		end
	else
		PetStableCurrentPet:SetChecked(nil);
	end

	-- Set tooltip and icon info
	if ( GetPetIcon() and UnitCreatureFamily("pet") ) then
		SetItemButtonTexture(PetStableCurrentPet, GetPetIcon());
		name = UnitName("pet") or "";
		level = UnitLevel("pet");
		family = UnitCreatureFamily("pet") or "";
		talent = GetPetTalentTree() or "";
		PetStableCurrentPet.tooltip = name;
		PetStableCurrentPet.tooltipSubtext = format(STABLE_PET_INFO_TOOLTIP_TEXT, level, family, talent);
	elseif ( GetStablePetInfo(0) ) then
		icon, name, level, family, talent = GetStablePetInfo(0);
		SetItemButtonTexture(PetStableCurrentPet, icon);
		PetStableCurrentPet.tooltip = name;
		PetStableCurrentPet.tooltipSubtext = format(STABLE_PET_INFO_TOOLTIP_TEXT, level, family, talent);
	else
		SetItemButtonTexture(PetStableCurrentPet, "");
		PetStableCurrentPet.tooltip = EMPTY_STABLE_SLOT;
		PetStableCurrentPet.tooltipSubtext = "";
		PetStableCurrentPet:SetChecked(nil);
	end
	if ( GameTooltip:IsOwned(PetStableCurrentPet) ) then
		GameTooltip:SetOwner(PetStableCurrentPet, "ANCHOR_RIGHT");
		GameTooltip:SetText(PetStableCurrentPet.tooltip);
		GameTooltip:AddLine(PetStableCurrentPet.tooltipSubtext, 1.0, 1.0, 1.0);
		GameTooltip:Show();
	end

	-- If no selected pet clear everything out
 	if ( selectedPet == -1 ) then
 		-- no pet
 		PetStableModel:Hide();
 		PetStableLevelText:SetText("");
 	end

	-- Enable, disable, or hide purchase button
	PetStablePurchaseButton:Show();
	if ( GetNumStableSlots() >= NUM_PET_STABLE_SLOTS or (not IsAtStableMaster())) then
		PetStablePurchaseButton:Hide();
		PetStableCostLabel:Hide();
		PetStableCostMoneyFrame:Hide();
		PetStableSlotText:Hide();
	elseif ( GetMoney() >= GetNextStableSlotCost() ) then
		PetStablePurchaseButton:Show();
		PetStablePurchaseButton:Enable();
		PetStableCostLabel:Show();
		PetStableCostMoneyFrame:Show();
		PetStableSlotText:Show();
		SetMoneyFrameColor("PetStableCostMoneyFrame", "white");
	else
		PetStablePurchaseButton:Show();
		PetStablePurchaseButton:Disable();
		PetStableCostLabel:Show();
		PetStableCostMoneyFrame:Show();
		PetStableSlotText:Show();
		SetMoneyFrameColor("PetStableCostMoneyFrame", "red");
	end
end

function PetStable_NoPetsAllowed()
	local button;
	for i=1, NUM_PET_STABLE_BASE_SLOTS + NUM_PET_STABLE_VISIBLE_SLOTS do
		if ( i <= NUM_PET_STABLE_BASE_SLOTS ) then
			button = _G["PetStableStabledPet"..i];
		else
			button = _G["PetStableExtendedPet"..(i - NUM_PET_STABLE_BASE_SLOTS)];
		end
		button.tooltip = EMPTY_STABLE_SLOT;
		button:SetChecked(nil);
	end
	
	PetStableCurrentPet:SetChecked(nil);
	PetStableLevelText:SetText("");
	PetStableModel:Hide();
	SetItemButtonTexture(PetStableCurrentPet, "");
	PetStableCurrentPet.tooltip = EMPTY_STABLE_SLOT;
	PetStableCurrentPet:SetChecked(nil);
	PetStablePurchaseButton:Hide();
	PetStableCostLabel:Hide();
	PetStableCostMoneyFrame:Hide();
	PetStableSlotText:Hide();
end
