local dialogs = require("dialogs")
local class = require("class")
local async_util = require("async_util")

--local AbstractBriefingController = require("briefingCommon")

--local BriefingController = class(AbstractBriefingController)

local WeaponSelectController = class()

local modelDraw = nil

function WeaponSelectController:init()
	if not RocketUiSystem.selectInit then
		ui.ShipWepSelect.initSelect()
		RocketUiSystem.selectInit = true
	end
	modelDraw = {}
end

function WeaponSelectController:initialize(document)
    --AbstractBriefingController.initialize(self, document)
	self.document = document
	self.elements = {}
	self.slots = {}
	self.aniEl = self.document:CreateElement("img")
	self.aniWepEl = self.document:CreateElement("ani")
	self.requiredWeps = {}
	self.emptyWingSlot = {}
	modelDraw.banks = {
		bank1 = self.document:GetElementById("primary_one"),
		bank2 = self.document:GetElementById("primary_two"),
		bank3 = self.document:GetElementById("primary_three"),
		bank4 = self.document:GetElementById("secondary_one"),
		bank5 = self.document:GetElementById("secondary_two"),
		bank6 = self.document:GetElementById("secondary_three"),
		bank7 = self.document:GetElementById("secondary_four")
	}
	self.secondaryAmountEls = {
		self.document:GetElementById("secondary_amount_one"),
		self.document:GetElementById("secondary_amount_two"),
		self.document:GetElementById("secondary_amount_three"),
		self.document:GetElementById("secondary_amount_four")
	}
	
	
	self.weapon3d, self.weaponEffect, self.icon3d = ui.ShipWepSelect.get3dWeaponChoices()
	
	self.overhead3d, self.overheadEffect = ui.ShipWepSelect.get3dOverheadChoices()
	
	--Get all the required weapons
	j = 1
	while (j < #tb.WeaponClasses) do
		if tb.WeaponClasses[j]:isWeaponRequired() then
			self.requiredWeps[#self.requiredWeps + 1] = tb.WeaponClasses[j].Name
		end
		j = j + 1
	end
	
	--Create the anim here so that it can be restarted with each new selection
	local aniWrapper = self.document:GetElementById("ship_view")
	aniWrapper:AppendChild(self.aniEl)

	local aniWrapper = self.document:GetElementById("weapon_view")
	aniWrapper:ReplaceChild(self.aniWepEl, aniWrapper.first_child)
	

	---Load the desired font size from the save file
	if modOptionValues.Font_Multiplier then
		fontChoice = modOptionValues.Font_Multiplier
		self.document:GetElementById("main_background"):SetClass(("p1-" .. fontChoice), true)
	else
		self.document:GetElementById("main_background"):SetClass("p1-5", true)
	end
	
	self.document:GetElementById("brief_btn"):SetPseudoClass("checked", false)
	self.document:GetElementById("s_select_btn"):SetPseudoClass("checked", false)
	self.document:GetElementById("w_select_btn"):SetPseudoClass("checked", true)
	
	--ui.ShipWepSelect.initSelect()
	
	self.SelectedEntry = nil
	self.SelectedShip = nil
	self.shipList = {}
	self.primaryList = {}
	self.secondaryList = {}
	
	local shipList = tb.ShipClasses
	local i = 1
	local j = 1
	while (i ~= #shipList) do
		if ui.ShipWepSelect.Ship_Pool[i] > 0 then
			if rocketUiIcons[shipList[i].Name] == nil then
				ba.warning("No generated icon was found for " .. shipList[i].Name .. "! This means it is missing custom data in the table to flag for pre-generation or it is not meant to be available in the loadout pool. Generating one now.")
				RocketUiSystem:setIconFrames(shipList[i].Name)
			end
			self.shipList[j] = {
				Index = i,
				Amount = ui.ShipWepSelect.Ship_Pool[i],
				Icon = shipList[i].SelectIconFilename,
				GeneratedIcon = {},
				Anim = shipList[i].SelectAnimFilename,
				Overhead = shipList[i].SelectOverheadFilename,
				Name = shipList[i].Name,
				Type = "ship",
				GeneratedWidth = rocketUiIcons[shipList[i].Name].Width,
				GeneratedHeight = rocketUiIcons[shipList[i].Name].Height,
				GeneratedIcon = rocketUiIcons[shipList[i].Name].Icon
			}
			j = j + 1
		end
		i = i + 1
	end
	
	--Add any ships that exist in wings but have 0 in the pool
	self:CheckShipSlots()
	--Now sort the lists by the ship index
	table.sort(self.shipList, function(a,b) return a.Index < b.Index end)
	
	--generate usable icons
	--self:getIconFrames(self.shipList)
	self:getEmptySlotFrames()
	
	local weaponList = tb.WeaponClasses
	local i = 1
	local j = 1
	local k = 1
	while (i ~= #weaponList) do
		if ui.ShipWepSelect.Weapon_Pool[i] > 0 then
			if rocketUiIcons[weaponList[i].Name] == nil then
				ba.warning("No generated icon was found for " .. weaponList[i].Name .. "! This means it is missing custom data in the table to flag for pre-generation or it is not meant to be available in the loadout pool. Generating one now.")
				RocketUiSystem:setIconFrames(weaponList[i].Name)
			end
			if tb.WeaponClasses[i]:isPrimary() then
				self.primaryList[j] = {
					Index = i,
					Amount = ui.ShipWepSelect.Weapon_Pool[i],
					Icon = weaponList[i].SelectIconFilename,
					GeneratedIcon = {},
					Anim = weaponList[i].SelectAnimFilename,
					Name = weaponList[i].Name,
					Title = weaponList[i].TechTitle,
					Description = string.gsub(weaponList[i].Description, "Level", "<br></br>Level"),
					Velocity = math.floor(weaponList[i].Speed*10)/10,
					Range = weaponList[i].Range/100,
					Damage = math.floor(weaponList[i].Damage*10)/10,
					ArmorFactor = math.floor(weaponList[i].ArmorFactor*10)/10,
					ShieldFactor = math.floor(weaponList[i].ShieldFactor*10)/10,
					SubsystemFactor = math.floor(weaponList[i].SubsystemFactor*10)/10,
					FireWait = math.floor(weaponList[i].FireWait*10)/10,
					Power = weaponList[i].EnergyConsumed,
					Type = "primary",
					GeneratedWidth = rocketUiIcons[weaponList[i].Name].Width,
					GeneratedHeight = rocketUiIcons[weaponList[i].Name].Height,
					GeneratedIcon = rocketUiIcons[weaponList[i].Name].Icon
				}
				j = j + 1
			elseif tb.WeaponClasses[i]:isSecondary() then
				self.secondaryList[k] = {
					Index = i,
					Amount = ui.ShipWepSelect.Weapon_Pool[i],
					Icon = weaponList[i].SelectIconFilename,
					GeneratedIcon = {},
					Anim = weaponList[i].SelectAnimFilename,
					Name = weaponList[i].Name,
					Title = weaponList[i].TechTitle,
					Description = string.gsub(weaponList[i].Description, "Level", "<br></br>Level"),
					Velocity = math.floor(weaponList[i].Speed*10)/10,
					Range = weaponList[i].Range/100,
					Damage = math.floor(weaponList[i].Damage*10)/10,
					ArmorFactor = math.floor(weaponList[i].ArmorFactor*10)/10,
					ShieldFactor = math.floor(weaponList[i].ShieldFactor*10)/10,
					SubsystemFactor = math.floor(weaponList[i].SubsystemFactor*10)/10,
					FireWait = math.floor(weaponList[i].FireWait*10)/10,
					Power = weaponList[i].EnergyConsumed,
					Type = "secondary",
					GeneratedWidth = rocketUiIcons[weaponList[i].Name].Width,
					GeneratedHeight = rocketUiIcons[weaponList[i].Name].Height,
					GeneratedIcon = rocketUiIcons[weaponList[i].Name].Icon
				}
				k = k + 1
			end
		end
		i = i + 1
	end
	
	--Add any weapons that exists on ships but have 0 in the pool
	self:CheckSlots()
	--Now sort the lists by the weapon index
	table.sort(self.primaryList, function(a,b) return a.Index < b.Index end)
	table.sort(self.secondaryList, function(a,b) return a.Index < b.Index end)
	
	--generate usable icons
	--self:getIconFrames(self.primaryList)
	--self:getIconFrames(self.secondaryList)
	
	--Only create entries if there are any to create
	if self.primaryList[1] then
		self:CreateEntries(self.primaryList)
	end
	
	if self.secondaryList[1] then
		self:CreateEntries(self.secondaryList)
	end
	
	--self:InitSlots()
	self:BuildWings()
	
	self:SelectInitialItems()
	
	self:startMusic()

end

function WeaponSelectController:getEmptySlotFrames()

	--Create a texture and then draw to it, save the output
	local imag_h = gr.loadTexture("iconwing01", true, true)
	local width = imag_h:getWidth()
	local height = imag_h:getHeight()
	local tex_h = gr.createTexture(width, height)
	gr.setTarget(tex_h)
	for j = 1, 2, 1 do
		gr.clearScreen(0,0,0,0)
		gr.drawImage(imag_h[j], 0, 0, width, height, 0, 1, 1, 0, 1)
		self.emptyWingSlot[j] = gr.screenToBlob()
	end
	self.emptyWingSlot.GeneratedWidth = width
	self.emptyWingSlot.GeneratedHeight = height
	
	--clean up
	gr.setTarget()
	imag_h:unload()
	tex_h:unload()

end

function WeaponSelectController:BuildWings()

	local slotNum = 1
	local wrapperEl = self.document:GetElementById("wings_wrapper")
	self:ClearEntries(wrapperEl)

	--#ui.ShipWepSelect.Loadout_Wings
	for i = 1, #ui.ShipWepSelect.Loadout_Wings, 1 do
		--First create a wrapper for the whole wing
		local wingEl = self.document:CreateElement("div")
		wingEl:SetClass("wing", true)
		wrapperEl:AppendChild(wingEl)
		
		--Add the wrapper for the slots
		local slotsEl = self.document:CreateElement("div")
		slotsEl:SetClass("slot_wrapper", true)
		wingEl:ReplaceChild(slotsEl, wingEl.first_child)
		
		--Add the wing name
		local nameEl = self.document:CreateElement("div")
		nameEl:SetClass("wing_name", true)
		nameEl.inner_rml = ui.ShipWepSelect.Loadout_Wings[i].Name
		wingEl:AppendChild(nameEl)
		
		--Now we add the actual wing slots
		for j = 1, #ui.ShipWepSelect.Loadout_Wings[i], 1 do
			self.slots[slotNum] = {}
			
			self.slots[slotNum].isPlayer = ui.ShipWepSelect.Loadout_Wings[i][j].isPlayer
			self.slots[slotNum].isDisabled = ui.ShipWepSelect.Loadout_Wings[i][j].isDisabled
			self.slots[slotNum].isFilled = true
			if ui.ShipWepSelect.Loadout_Ships[slotNum].ShipClassIndex < 1 then
				self.slots[slotNum].isFilled = false
			end
			self.slots[slotNum].isWeaponLocked = ui.ShipWepSelect.Loadout_Wings[i][j].isWeaponLocked
			if ui.ShipWepSelect.Loadout_Wings[i][j].isShipLocked or ui.ShipWepSelect.Loadout_Wings[i][j].isWeaponLocked then
				self.slots[slotNum].isLocked = true
			end
			
			local slotEl = self.document:CreateElement("div")
			slotEl:SetClass("wing_slot", true)
			slotsEl:AppendChild(slotEl)
			
			--default to empty slot image for now, but don't show disabled slots
			local slotIcon = self.emptyWingSlot[2]
			if self.slots[slotNum].isDisabled then
				slotIcon = self.emptyWingSlot[1]
			end
			self.slots[slotNum].Name = nil
			local shipIndex = 0
			
			--This is messy, but we have to check which exact slot we are in the wing
			if j == 1 then
				slotEl:SetClass("wing_one", true)
				self.slots[slotNum].Callsign = ui.ShipWepSelect.Loadout_Wings[i].Name .. " 1"
				--Get the current ship in this slot
				shipIndex = ui.ShipWepSelect.Loadout_Ships[slotNum].ShipClassIndex
				if shipIndex > 0 then
					local entry = self:GetShipEntry(shipIndex)
					if self.slots[slotNum].isPlayer then
						slotIcon = entry.GeneratedIcon[4]
					elseif self.slots[slotNum].isLocked then
						slotIcon = entry.GeneratedIcon[6]
					else
						slotIcon = entry.GeneratedIcon[1]
					end
					self.slots[slotNum].Name = tb.ShipClasses[shipIndex].Name
				end
			elseif j == 2 then
				slotEl:SetClass("wing_two", true)
				self.slots[slotNum].Callsign = ui.ShipWepSelect.Loadout_Wings[i].Name .. " 2"
				--Get the current ship in this slot
				shipIndex = ui.ShipWepSelect.Loadout_Ships[slotNum].ShipClassIndex
				if shipIndex > 0 then
					local entry = self:GetShipEntry(shipIndex)
					if self.slots[slotNum].isPlayer then
						slotIcon = entry.GeneratedIcon[4]
					elseif self.slots[slotNum].isLocked then
						slotIcon = entry.GeneratedIcon[6]
					else
						slotIcon = entry.GeneratedIcon[1]
					end
					self.slots[slotNum].Name = tb.ShipClasses[shipIndex].Name
				end
			elseif j == 3 then
				slotEl:SetClass("wing_three", true)
				self.slots[slotNum].Callsign = ui.ShipWepSelect.Loadout_Wings[i].Name .. " 3"
				--Get the current ship in this slot
				shipIndex = ui.ShipWepSelect.Loadout_Ships[slotNum].ShipClassIndex
				if shipIndex > 0 then
					local entry = self:GetShipEntry(shipIndex)
					if self.slots[slotNum].isPlayer then
						slotIcon = entry.GeneratedIcon[4]
					elseif self.slots[slotNum].isLocked then
						slotIcon = entry.GeneratedIcon[6]
					else
						slotIcon = entry.GeneratedIcon[1]
					end
					self.slots[slotNum].Name = tb.ShipClasses[shipIndex].Name
				end
			else
				slotEl:SetClass("wing_four", true)
				self.slots[slotNum].Callsign = ui.ShipWepSelect.Loadout_Wings[i].Name .. " 4"
				--Get the current ship in this slot
				shipIndex = ui.ShipWepSelect.Loadout_Ships[slotNum].ShipClassIndex
				if shipIndex > 0 then
					local entry = self:GetShipEntry(shipIndex)
					if self.slots[slotNum].isPlayer then
						slotIcon = entry.GeneratedIcon[4]
					elseif self.slots[slotNum].isLocked then
						slotIcon = entry.GeneratedIcon[6]
					else
						slotIcon = entry.GeneratedIcon[1]
					end
					self.slots[slotNum].Name = tb.ShipClasses[shipIndex].Name
				end
			end
			
			local slotImg = self.document:CreateElement("img")
			slotImg:SetAttribute("src", slotIcon)
			slotEl:AppendChild(slotImg)
			
			slotEl.id = "slot_" .. slotNum
			local index = slotNum
			if not self.slots[slotNum].isDisabled then
				if shipIndex > 0 then
					local thisEntry = self:GetShipEntry(shipIndex)
					if thisEntry == nil then
						ba.warning("got nil, appending to pool!")
						thisEntry = self:AppendToPool(shipIndex)
					end
					local callsign = self.slots[slotNum].Callsign
					self.slots[slotNum].entry = thisEntry
					local thisSlot = slotNum
					
					--Add click detection
					slotEl:SetClass("button_3", true)
					slotEl:AddEventListener("click", function(_, _, _)
						self:SelectShip(shipIndex, callsign, thisSlot)
					end)
					
					if self.icon3d then
						if not self.slots[slotNum].isLocked then
							slotEl:SetClass("available", true)
						elseif self.slots[slotNum].isWeaponLocked then
							slotEl:SetClass("locked", true)
						else
							slotEl:SetClass("available", true)
						end
					end
				else
					--do nothing
				end
			end
			
			slotNum = slotNum + 1
		end
	end

end

function WeaponSelectController:GetShipEntry(shipIndex)

	for i, v in ipairs(self.shipList) do
		if v.Index == shipIndex then
			return v
		end
	end

end

function WeaponSelectController:GetPrimaryEntry(classIndex)

	for i, v in ipairs(self.primaryList) do
		if v.Index == classIndex then
			return v
		end
	end

end

function WeaponSelectController:GetSecondaryEntry(classIndex)

	for i, v in ipairs(self.secondaryList) do
		if v.Index == classIndex then
			return v
		end
	end

end

function WeaponSelectController:GetWeaponEntry(classIndex)
	if tb.WeaponClasses[classIndex]:isPrimary() then
		return self:GetPrimaryEntry(classIndex)
	elseif tb.WeaponClasses[classIndex]:isSecondary() then
		return self:GetSecondaryEntry(classIndex)
	else
		return nil
	end
end

function WeaponSelectController:AppendToPool(ship)

	if rocketUiIcons[tb.ShipClasses[ship].Name] == nil then
		ba.warning("No generated icon was found for " .. tb.ShipClasses[ship].Name .. "! This means it is missing custom data in the table to flag for pre-generation or it is not meant to be available in the loadout pool. Generating one now.")
		RocketUiSystem:setIconFrames(tb.ShipClasses[ship].Name)
	end

	i = #self.shipList + 1
	self.shipList[i] = {
		Index = tb.ShipClasses[ship]:getShipClassIndex(),
		Amount = 0,
		Icon = tb.ShipClasses[ship].SelectIconFilename,
		GeneratedIcon = {},
		Anim = tb.ShipClasses[ship].SelectAnimFilename,
		Overhead = tb.ShipClasses[ship].SelectOverheadFilename,
		Name = tb.ShipClasses[ship].Name,
		Type = "ship",
		key = tb.ShipClasses[ship].Name,
		GeneratedWidth = rocketUiIcons[tb.ShipClasses[ship].Name].Width,
		GeneratedHeight = rocketUiIcons[tb.ShipClasses[ship].Name].Height,
		GeneratedIcon = rocketUiIcons[tb.ShipClasses[ship].Name].Icon
	}
	return self.shipList[i]
end

function WeaponSelectController:IsSlotDisabled(slot)

	if slot < 5 then
		return ui.ShipWepSelect.Loadout_Wings[1][slot].isDisabled
	elseif slot < 9 then
		local t_slot = slot - 4
		return ui.ShipWepSelect.Loadout_Wings[2][t_slot].isDisabled
	elseif slot < 13 then
		local t_slot = slot - 8
		return ui.ShipWepSelect.Loadout_Wings[2][t_slot].isDisabled
	else
		return false
	end

end

function WeaponSelectController:CheckShipSlots()

	for i = 1, #ui.ShipWepSelect.Loadout_Ships, 1 do
		if not self:IsSlotDisabled(i) then
			local ship = ui.ShipWepSelect.Loadout_Ships[i].ShipClassIndex
			if ship > 0 then
				ship = self:GetShipEntry(ship)
				if ship == nil then
					self:AppendToPool(ui.ShipWepSelect.Loadout_Ships[i].ShipClassIndex)
				end
			end
		end
	end

end

function WeaponSelectController:CheckSlots()

	for i = 1, #ui.ShipWepSelect.Loadout_Ships, 1 do
		if not self:IsSlotDisabled(i) then
			if ui.ShipWepSelect.Loadout_Ships[i].ShipClassIndex > 0 then
				for j = 1, #ui.ShipWepSelect.Loadout_Ships[i].Weapons, 1 do
					local wep = ui.ShipWepSelect.Loadout_Ships[i].Weapons[j]
					if ui.ShipWepSelect.Loadout_Ships[i].Amounts[j] > 0 then
						wep = self:GetWeaponEntry(wep)
						
						if wep == nil then
							self:AppendWeaponToPool(ui.ShipWepSelect.Loadout_Ships[i].Weapons[j])
						end
					end
				end
			end
		end
	end

end
			

function WeaponSelectController:AppendWeaponToPool(classIndex)

	if rocketUiIcons[tb.WeaponClasses[classIndex].Name] == nil then
		ba.warning("No generated icon was found for " .. tb.WeaponClasses[classIndex].Name .. "! This means it is missing custom data in the table to flag for pre-generation or it is not meant to be available in the loadout pool. Generating one now.")
		RocketUiSystem:setIconFrames(tb.WeaponClasses[classIndex].Name)
	end
	
	local list = {}
	local type_v = nil
	if tb.WeaponClasses[classIndex]:isPrimary() then
		list = self.primaryList
		type_v = "primary"
	else
		list = self.secondaryList
		type_v = "secondary"
	end
	i = #list + 1
	list[i] = {
		Index = classIndex,
		Amount = 0,
		Icon = tb.WeaponClasses[classIndex].SelectIconFilename,
		GeneratedIcon = {},
		Anim = tb.WeaponClasses[classIndex].SelectAnimFilename,
		Name = tb.WeaponClasses[classIndex].Name,
		Title = tb.WeaponClasses[classIndex].TechTitle,
		Description = string.gsub(tb.WeaponClasses[classIndex].Description, "Level", "<br></br>Level"),
		Velocity = math.floor(tb.WeaponClasses[classIndex].Speed*10)/10,
		Range = tb.WeaponClasses[classIndex].Range/100,
		Damage = math.floor(tb.WeaponClasses[classIndex].Damage*10)/10,
		ArmorFactor = math.floor(tb.WeaponClasses[classIndex].ArmorFactor*10)/10,
		ShieldFactor = math.floor(tb.WeaponClasses[classIndex].ShieldFactor*10)/10,
		SubsystemFactor = math.floor(tb.WeaponClasses[classIndex].SubsystemFactor*10)/10,
		FireWait = math.floor(tb.WeaponClasses[classIndex].FireWait*10)/10,
		Power = tb.WeaponClasses[classIndex].EnergyConsumed,
		Type = type_v,
		key = tb.WeaponClasses[classIndex].Name,
		GeneratedWidth = rocketUiIcons[tb.WeaponClasses[classIndex].Name].Width,
		GeneratedHeight = rocketUiIcons[tb.WeaponClasses[classIndex].Name].Height,
		GeneratedIcon = rocketUiIcons[tb.WeaponClasses[classIndex].Name].Icon
	}
end

function WeaponSelectController:ResetAmounts()
	for i = 1, #self.primaryList, 1 do
		self.primaryList[i].Amount = ui.ShipWepSelect.Weapon_Pool[self.primaryList[i].Index]
	end
	for i = 1, #self.secondaryList, 1 do
		self.secondaryList[i].Amount = ui.ShipWepSelect.Weapon_Pool[self.secondaryList[i].Index]
	end
end

function WeaponSelectController:SelectInitialItems()

	local selectSlot = 0
	for i = 1, #ui.ShipWepSelect.Loadout_Ships, 1 do
		if ui.ShipWepSelect.Loadout_Ships[1].ShipClassIndex > 0 then
			selectSlot = i
			break
		end
	end
	
	if selectSlot > 0 then
		local wing = self:GetWingSlot(selectSlot)
		local callsign = ui.ShipWepSelect.Loadout_Wings[wing].Name .. " 1"
		self:SelectShip(ui.ShipWepSelect.Loadout_Ships[selectSlot].ShipClassIndex, callsign, 1)
		
		if self.primaryList[1] then
			self:SelectEntry(self.primaryList[1])
		elseif self.secondaryList[1] then
			self:SelectEntry(self.secondaryList[1])		
		end
	end
	
end

function WeaponSelectController:ReloadList()

	modelDraw.class = nil
	modelDraw.OverheadClass = nil
	local list_items_el = self.document:GetElementById("primary_icon_list_ul")
	self:ClearEntries(list_items_el)
	local list_items_el = self.document:GetElementById("secondary_icon_list_ul")
	self:ClearEntries(list_items_el)
	self.SelectedEntry = nil
	self.SelectedShip = nil
	ui.ShipWepSelect.initSelect()
	self:ResetAmounts()
	if self.primaryList[1] then
		self:CreateEntries(self.primaryList)
	end
	if self.secondaryList[1] then
		self:CreateEntries(self.secondaryList)
	end
	self:BuildWings()
	self:SelectInitialItems()
end

function WeaponSelectController:ChangeIconAvailability(shipIndex)

	for i, v in pairs(self.primaryList) do
		local iconEl = self.document:GetElementById(v.key).first_child.first_child.next_sibling
		if tb.ShipClasses[shipIndex]:isWeaponAllowedOnShip(v.Index) then
			iconEl:SetClass("drag", true)
			if self.icon3d then
				iconEl:SetClass("available", true)
				iconEl:SetClass("locked", false)
			end
			iconEl:SetAttribute("src", v.GeneratedIcon[1])
		else
			iconEl:SetClass("drag", false)
			if self.icon3d then
				iconEl:SetClass("available", false)
				iconEl:SetClass("locked", true)
			end
			iconEl:SetAttribute("src", v.GeneratedIcon[4])
		end
	end
	
	for i, v in pairs(self.secondaryList) do
		local iconEl = self.document:GetElementById(v.key).first_child.first_child.next_sibling
		if tb.ShipClasses[shipIndex]:isWeaponAllowedOnShip(v.Index) then
			iconEl:SetClass("drag", true)
			if self.icon3d then
				iconEl:SetClass("available", true)
				iconEl:SetClass("locked", false)
			end
			iconEl:SetAttribute("src", v.GeneratedIcon[1])
		else
			iconEl:SetClass("drag", false)
			if self.icon3d then
				iconEl:SetClass("available", false)
				iconEl:SetClass("locked", true)
			end
			iconEl:SetAttribute("src", v.GeneratedIcon[4])
		end
	end

end

function WeaponSelectController:CreateEntryItem(entry, idx)

	local li_el = self.document:CreateElement("li")
	local iconWrapper = self.document:CreateElement("div")
	iconWrapper.id = entry.Name
	iconWrapper:SetClass("select_item", true)
	
	li_el:AppendChild(iconWrapper)
	
	local countEl = self.document:CreateElement("div")
	countEl.inner_rml = entry.Amount
	countEl:SetClass("amount", true)
	entry.countEl = countEl
	
	iconWrapper:AppendChild(countEl)
	
	--local aniWrapper = self.document:GetElementById(entry.Icon)
	local iconEl = self.document:CreateElement("img")
	iconEl:SetAttribute("src", entry.GeneratedIcon[1])
	iconWrapper:AppendChild(iconEl)
	--iconWrapper:ReplaceChild(iconEl, iconWrapper.first_child)
	li_el.id = entry.Name

	--iconEl:SetClass("shiplist_element", true)
	iconEl:SetClass("button_3", true)
	iconEl:SetClass("icon", true)
	iconEl:SetClass("drag", true)
	iconEl:AddEventListener("click", function(_, _, _)
		self:SelectEntry(entry)
	end)
	iconEl:AddEventListener("dragend", function(_, _, _)
		self:DragPoolEnd(iconEl, entry, entry.Index)
	end)
	entry.key = li_el.id

	return li_el
end

function WeaponSelectController:CreateEntries(list)

	local list_names_el = nil
	
	if tb.WeaponClasses[list[1].Index]:isPrimary() then
		list_names_el = self.document:GetElementById("primary_icon_list_ul")
	elseif tb.WeaponClasses[list[1].Index]:isSecondary() then
		list_names_el = self.document:GetElementById("secondary_icon_list_ul")
	end
	
	if list_names_el ~= nil then
		self:ClearEntries(list_names_el)

		for i, v in pairs(list) do
			list_names_el:AppendChild(self:CreateEntryItem(v, i))
		end
	end
end

function WeaponSelectController:SelectEntry(entry)
	if entry ~= nil then
		if entry.key ~= self.SelectedEntry then
			
			self.SelectedEntry = entry.key
			
			self:HighlightWeapon()
			
			self:BuildInfo(entry)
			
			if self.weapon3d or entry.Anim == nil then
				modelDraw.class = entry.Index
				modelDraw.element = self.document:GetElementById("weapon_view_window")
				modelDraw.start = true
			else
				--the anim is already created so we only need to remove and reset the src
				self.aniWepEl:RemoveAttribute("src")
				self.aniWepEl:SetAttribute("src", entry.Anim)
			end
			
		end
	end
end

function WeaponSelectController:SelectAssignedEntry(element, slot)

	local weapon = ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].Weapons[slot]
	
	local selectedEntry = nil
	
	if slot < 4 then
		selectedEntry = self:GetPrimaryEntry(weapon)
	else
		selectedEntry = self:GetSecondaryEntry(weapon)
	end
	
	self:SelectEntry(selectedEntry)

end

function WeaponSelectController:HighlightWeapon()

	local shipIndex = ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].ShipClassIndex 

	for i, v in pairs(self.primaryList) do
		local iconEl = self.document:GetElementById(v.key).first_child.first_child.next_sibling
		if tb.ShipClasses[shipIndex]:isWeaponAllowedOnShip(v.Index) then
			if v.key == self.SelectedEntry then
				if self.icon3d then
					iconEl:SetClass("highlighted", true)
				end
				iconEl:SetAttribute("src", v.GeneratedIcon[3])
			else
				if self.icon3d then
					iconEl:SetClass("highlighted", false)
				end
				iconEl:SetAttribute("src", v.GeneratedIcon[1])
			end
		end
	end
	
	for i, v in pairs(self.secondaryList) do
		local iconEl = self.document:GetElementById(v.key).first_child.first_child.next_sibling
		if tb.ShipClasses[shipIndex]:isWeaponAllowedOnShip(v.Index) then
			if v.key == self.SelectedEntry then
				if self.icon3d then
					iconEl:SetClass("highlighted", true)
				end
				iconEl:SetAttribute("src", v.GeneratedIcon[3])
			else
				if self.icon3d then
					iconEl:SetClass("highlighted", false)
				end
				iconEl:SetAttribute("src", v.GeneratedIcon[1])
			end
		end
	end
	
	for i, v in pairs(modelDraw.banks) do
		local index = string.sub(i, -1)
		local weapon = ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].Weapons[index]
		if weapon > 0 then
			local thisEntry = self:GetWeaponEntry(weapon)
			if v.first_child ~= nil then
				if tb.WeaponClasses[weapon].Name == self.SelectedEntry then
					v.first_child:SetAttribute("src", thisEntry.GeneratedIcon[3])
				else
					v.first_child:SetAttribute("src", thisEntry.GeneratedIcon[1])
				end
			end
		end
	end

end

function WeaponSelectController:HighlightShip(slot)
	
	for i = 1, 12, 1 do
		local slotEl = self.document:GetElementById("slot_" .. i)
		local shipIdx = ui.ShipWepSelect.Loadout_Ships[i].ShipClassIndex
		local thisEntry = self:GetShipEntry(shipIdx)
		if thisEntry ~= nil then
			local icon = nil
			if slot == i then
				if self.slots[i].isPlayer then
					icon = thisEntry.GeneratedIcon[4]
				elseif self.slots[i].isLocked then
					icon = thisEntry.GeneratedIcon[5]
				else
					icon = thisEntry.GeneratedIcon[3]
				end
			else
				if self.slots[i].isPlayer then
					icon = thisEntry.GeneratedIcon[4]
				elseif self.slots[i].isLocked then
					icon = thisEntry.GeneratedIcon[6]
				else
					icon = thisEntry.GeneratedIcon[1]
				end
			end
			
			slotEl.first_child:SetAttribute("src", icon)
			
		end
	end
				
end

function WeaponSelectController:SelectShip(shipIndex, callsign, slot)

	if callsign ~= self.SelectedShip then
		
		self.SelectedShip = callsign
		self.currentShipSlot = slot
		
		self.document:GetElementById("ship_name").inner_rml = callsign
		
		local thisEntry = self:GetShipEntry(shipIndex)

		self:HighlightShip(slot)
		
		local overhead = thisEntry.Overhead

		self:BuildWeaponSlots(shipIndex)
		
		self:ChangeIconAvailability(shipIndex)
		
		self:HighlightWeapon()
		
		if self.overhead3d or overhead == nil then
			modelDraw.OverheadClass = shipIndex
			modelDraw.OverheadElement = self.document:GetElementById("ship_view_wrapper")
			modelDraw.Slot = slot
			--STILL GOTTA HANDLE THIS!
			modelDraw.Hover = self.hoverSlot
			modelDraw.overheadEffect = self.overheadEffect
		else
			--the anim is already created so we only need to remove and reset the src
			self.aniEl:RemoveAttribute("src")
			self.aniEl:SetAttribute("src", overhead)
		end
		
	end

end

function WeaponSelectController:ClearWeaponSlots()
	self:ClearEntries(modelDraw.banks.bank1)
	self:ClearEntries(modelDraw.banks.bank2)
	self:ClearEntries(modelDraw.banks.bank3)
	self:ClearEntries(modelDraw.banks.bank4)
	self:ClearEntries(modelDraw.banks.bank5)
	self:ClearEntries(modelDraw.banks.bank6)
	self:ClearEntries(modelDraw.banks.bank7)
	
	for i, v in pairs(modelDraw.banks) do
		v:SetClass("slot_3d", false)
		v:SetClass("button_3", false)
	end
	
	for i, v in pairs(self.secondaryAmountEls) do
		v.inner_rml = ""
	end
end

function WeaponSelectController:BuildWeaponSlots(ship)

	self:ClearWeaponSlots()

	if tb.ShipClasses[ship].numPrimaryBanks > 0 then
		self:BuildSlot(modelDraw.banks.bank1, 1)
		if self.overhead3d then
			modelDraw.banks.bank1:SetClass("slot_3d", true)
		end
	end
	
	if tb.ShipClasses[ship].numPrimaryBanks > 1 then
		self:BuildSlot(modelDraw.banks.bank2, 2)
		if self.overhead3d then
			modelDraw.banks.bank2:SetClass("slot_3d", true)
		end
	end
	
	if tb.ShipClasses[ship].numPrimaryBanks > 2 then
		self:BuildSlot(modelDraw.banks.bank3, 3)
		if self.overhead3d then
			modelDraw.banks.bank3:SetClass("slot_3d", true)
		end
	end
	
	if tb.ShipClasses[ship].numSecondaryBanks > 0 then
		self:BuildSlot(modelDraw.banks.bank4, 4)
		if self.overhead3d then
			modelDraw.banks.bank4:SetClass("slot_3d", true)
		end
	end
	
	if tb.ShipClasses[ship].numSecondaryBanks > 1 then
		self:BuildSlot(modelDraw.banks.bank5, 5)
		if self.overhead3d then
			modelDraw.banks.bank5:SetClass("slot_3d", true)
		end
	end
	
	if tb.ShipClasses[ship].numSecondaryBanks > 2 then
		self:BuildSlot(modelDraw.banks.bank6, 6)
		if self.overhead3d then
			modelDraw.banks.bank6:SetClass("slot_3d", true)
		end
	end
	
	if tb.ShipClasses[ship].numSecondaryBanks > 3 then
		self:BuildSlot(modelDraw.banks.bank7, 7)
		if self.overhead3d then
			modelDraw.banks.bank7:SetClass("slot_3d", true)
		end
	end

end

function WeaponSelectController:BuildSlot(parentEl, bank)
	local slotImg = self.document:CreateElement("img")
		
	--Get the weapon currently loaded in the slot
	local weapon = ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].Weapons[bank]
	local amount = ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].Amounts[bank]
	if amount < 1 then amount = "" end
	if bank > 3 then
		self.secondaryAmountEls[bank - 3].inner_rml = amount
	end
	local slotIcon = nil
	if weapon > 0 then
		slotIcon = self:GetWeaponEntry(weapon).GeneratedIcon[1]
		--slotIcon = tb.WeaponClasses[weapon].SelectIconFilename
		slotImg:SetClass("drag", true)
		slotImg:SetClass("button_3", true)
		slotImg:SetAttribute("src", slotIcon)
		parentEl:AppendChild(slotImg)
	end
end

function WeaponSelectController:ClearEntries(parent)

	while parent:HasChildNodes() do
		parent:RemoveChild(parent.first_child)
	end

end

function WeaponSelectController:BuildInfo(entry)

	self.document:GetElementById("weapon_name").inner_rml = entry.Title
	
	local infoEl = self.document:GetElementById("weapon_stats")
	
	local weaponDescription    = "<p>" .. entry.Description .. "</p>"
	local WeaponLine2 = "<p>" .. ba.XSTR("Velocity", -1) .. ": " .. entry.Velocity .. " " .. ba.XSTR("Range", -1) .. ": " .. entry.Range .. "</p>"
	local WeaponLine3 = "<p class=\"info\">" .. ba.XSTR("Damage", -1) .. ": " .. entry.ArmorFactor .. " " .. ba.XSTR("Hull", -1) .. ", " .. entry.ShieldFactor .. " " .. ba.XSTR("Shield", -1) .. ", " .. entry.SubsystemFactor .. " " .. ba.XSTR("Subsystem", -1) .. "</p>"
	local WeaponLine4 = "<p class=\"info\">" .. ba.XSTR("Power Use", -1) .. ": " .. entry.Power .. ba.XSTR("W", -1) .. " " .. ba.XSTR("ROF", -1) .. ": " .. entry.FireWait .. "</p>"

	local completeRML = weaponDescription .. WeaponLine2 .. WeaponLine3 .. WeaponLine4
	
	infoEl.inner_rml = completeRML

end

function WeaponSelectController:GetWingSlot(slot)
	if slot < 5 then
		return 1, slot
	elseif slot < 9 then
		return 2, slot - 4
	elseif slot < 13 then
		return 3, slot - 8
	else
		return nil, nil
	end
end

function WeaponSelectController:ChangeBriefState(state)
	if state == 1 then
		ba.postGameEvent(ba.GameEvents["GS_EVENT_START_BRIEFING"])
	elseif state == 2 then
		if mn.isScramble() then
			ad.playInterfaceSound(10)
		else
			ba.postGameEvent(ba.GameEvents["GS_EVENT_SHIP_SELECTION"])
		end
	elseif state == 3 then
		--Do nothing because we're this is the current state!
	end
end

function WeaponSelectController:DragDrop(element, slot)
	self.replace = element
	self.activeSlot = slot
end

function WeaponSelectController:DragOver(element, slot)
	if ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].Weapons[slot] > 0 then
		modelDraw.Hover = slot
	end
end

function WeaponSelectController:DragOut(element, slot)
	modelDraw.Hover = -1
end

function WeaponSelectController:ConvertBankSlotToBank(ship, bank, w_type)
	local primaryBanks = tb.ShipClasses[ship].numPrimaryBanks
	local secondaryBanks = tb.ShipClasses[ship].numSecondaryBanks

	if (bank <= 3) and (w_type == 1) then
		if bank > primaryBanks then
			return -1
		else
			return bank
		end
	elseif (bank <= 7)  and (w_type == 2) then
		if (bank - 3) > secondaryBanks then
			return -1
		else
			return bank - 3
		end
	else
		return -1
	end
end

function WeaponSelectController:IsWeaponAllowed(shipIndex, weaponIndex)

	local primaryBanks = tb.ShipClasses[shipIndex].numPrimaryBanks
	local secondaryBanks = tb.ShipClasses[shipIndex].numSecondaryBanks
	local actualBank = nil
	
	if tb.WeaponClasses[weaponIndex]:isPrimary() then
		actualBank = self:ConvertBankSlotToBank(shipIndex, self.activeSlot, 1)
	else
		actualBank = self:ConvertBankSlotToBank(shipIndex, self.activeSlot, 2)
	end

	if actualBank == -1 then
		return false
	else
		return tb.ShipClasses[shipIndex]:isWeaponAllowedOnShip(weaponIndex, actualBank)
	end

end

function WeaponSelectController:CopyToWing(element)

	local sourceSlot = self.currentShipSlot
	
	--Now get what the other slots are that we will copy to
	local slots = {}
	if sourceSlot < 5 then
		slots[1] = 1
		slots[2] = 2
		slots[3] = 3
		slots[4] = 4
	elseif sourceSlot < 9 then
		slots[1] = 5
		slots[2] = 6
		slots[3] = 7
		slots[4] = 8
	elseif sourceSlot < 13 then
		slots[1] = 9
		slots[2] = 10
		slots[3] = 11
		slots[4] = 12
	else
		--do nothing because how did this happen?
		return
	end
	
	local sourceShip = ui.ShipWepSelect.Loadout_Ships[sourceSlot].ShipClassIndex
	--Now get the weapons that we will try to copy over
	for j = 1, #slots, 1 do
		if slots[j] ~= sourceSlot then
			local targetShip = ui.ShipWepSelect.Loadout_Ships[slots[j]].ShipClassIndex
			--ba.warning(slots[j] .. " " .. tostring(self.slots[slots[j]].isDisabled) .. " " .. tostring(self.slots[slots[j]].isFilled))
			if (not self.slots[slots[j]].isDisabled) and self.slots[slots[j]].isFilled then
				if not self.slots[slots[j]].isWeaponLocked then
					for i = 1, #ui.ShipWepSelect.Loadout_Ships[sourceSlot].Weapons, 1 do
						--ba.warning(sourceShip .. " " .. targetShip .. " " .. slots[j] .. " " .. i)
						--Does the bank exist on the source ship?
						if self:ShipHasBank(sourceShip, i) then
							--Does the bank exist on the target ship?
							if self:ShipHasBank(targetShip, i) then
								--The weapon we want to copy
								local weapon = ui.ShipWepSelect.Loadout_Ships[sourceSlot].Weapons[i]
								--The weapon's type
								local w_type = 2
								if tb.WeaponClasses[weapon]:isPrimary() then
									w_type = 1
								end
								local actualBank = self:ConvertBankSlotToBank(targetShip, i, w_type)
								--Can that bank accept the weapon?
								if tb.ShipClasses[targetShip]:isWeaponAllowedOnShip(weapon, actualBank) then
									--Get the capacity the bank can hold of the source weapon
									local capacity = self:GetWeaponAmount(targetShip, weapon, actualBank)
									--Do we have that much in the pool?
									local thisEntry = self:GetWeaponEntry(weapon)
									local count = tonumber(thisEntry.countEl.inner_rml)
									if count < capacity then
										capacity = count
									end
									if capacity > 0 then
										--Return what's in the bank to the pool
										local targetWeapon = ui.ShipWepSelect.Loadout_Ships[slots[j]].Weapons[i]
										local targetAmount = ui.ShipWepSelect.Loadout_Ships[slots[j]].Amounts[i]
										self:ReturnWeaponToPool(targetWeapon, targetAmount)
										--Now add the source weapon copy
										self:SubtractWeaponFromPool(weapon, capacity)
										ui.ShipWepSelect.Loadout_Ships[slots[j]].Weapons[i] = weapon
										ui.ShipWepSelect.Loadout_Ships[slots[j]].Amounts[i] = capacity
									end
								else
									--Return what's in the bank to the pool
									local targetWeapon = ui.ShipWepSelect.Loadout_Ships[slots[j]].Weapons[i]
									local targetAmount = ui.ShipWepSelect.Loadout_Ships[slots[j]].Amounts[i]
									self:ReturnWeaponToPool(targetWeapon, targetAmount)
									ui.ShipWepSelect.Loadout_Ships[slots[j]].Weapons[i] = -1
									ui.ShipWepSelect.Loadout_Ships[slots[j]].Amounts[i] = -1
								end
							end
						end
					end
				end
			end
		end
	end
end

function WeaponSelectController:ApplyWeaponToSlot(parentEl, slot, bank, weapon)

	local entry = self:GetWeaponEntry(weapon)
	local slotIcon = nil
	if entry.Name == self.SelectedEntry then
		slotIcon = entry.GeneratedIcon[3]
	else
		slotIcon = entry.GeneratedIcon[1]
	end
	if parentEl.first_child == nil then
		local slotEl = self.document:CreateElement("img")
		parentEl:AppendChild(slotEl)
	end
	parentEl.first_child:SetAttribute("src", slotIcon)
	parentEl.first_child:SetClass("drag", true)

	
	--Apply to the actual loadout
	ui.ShipWepSelect.Loadout_Ships[slot].Weapons[bank] = weapon

end

function WeaponSelectController:ReturnWeaponToPool(weapon, amount)
	if amount > 0 then
		local wep
		if tb.WeaponClasses[weapon]:isPrimary() then
			wep = self:GetPrimaryEntry(weapon)
		else
			wep = self:GetSecondaryEntry(weapon)
		end
		wep.Amount = wep.Amount + amount
		wep.countEl.inner_rml = wep.Amount
	end
end

function WeaponSelectController:EmptySlot(element, slot)
	ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].Weapons[slot] = -1
	--ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].Amounts[slot] = -1
	element:RemoveChild(element.first_child)
	if slot > 3 then
		local amountEl = self.secondaryAmountEls[slot-3]
		amountEl.inner_rml = ""
	end
end

function WeaponSelectController:SubtractWeaponFromPool(weapon, amount)
	if amount > 0 then
		local wep
		if tb.WeaponClasses[weapon]:isPrimary() then
			wep = self:GetPrimaryEntry(weapon)
		else
			wep = self:GetSecondaryEntry(weapon)
		end
		wep.Amount = wep.Amount - amount
		if wep.Amount < 0 then
			wep.Amount = 0
		end
		wep.countEl.inner_rml = wep.Amount
	end
end

function WeaponSelectController:ShipHasBank(ship, bank)
	local primaryBanks = tb.ShipClasses[ship].numPrimaryBanks
	local secondaryBanks = tb.ShipClasses[ship].numSecondaryBanks
	
	if bank < 1 then return false end
	if bank == 1 and primaryBanks > 0 then return true end
	if bank == 2 and primaryBanks > 1 then return true end
	if bank == 3 and primaryBanks > 2 then return true end
	if bank == 4 and secondaryBanks > 0 then return true end
	if bank == 5 and secondaryBanks > 1 then return true end
	if bank == 6 and secondaryBanks > 2 then return true end
	if bank == 7 and secondaryBanks > 3 then return true end
	if bank > 7 then return false end
end

function WeaponSelectController:DragPoolEnd(element, entry, weaponIndex)
	if (self.replace ~= nil) and (self.activeSlot > 0) then
		
		--Get the slot information: ship, weapon, and amount
		local slotShip = ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].ShipClassIndex 
		local slotWeapon = ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].Weapons[self.activeSlot]
		local slotAmount = ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].Amounts[self.activeSlot]
	
		--Get the amount of the weapon we're dragging
		local count = tonumber(entry.countEl.inner_rml)

		--If the pool count is 0 then abort!
		if count < 1 then
			self.replace = nil
			return
		end
		
		--If the ship is weapon locked then abort!
		local wing, wingSlot = self:GetWingSlot(self.currentShipSlot)
		if ui.ShipWepSelect.Loadout_Wings[wing][wingSlot].isWeaponLocked then
			self.replace = nil
			return
		end
		
		--If the slot can't accept the weapon then abort!
		if not self:IsWeaponAllowed(slotShip, weaponIndex) then
			self.replace = nil
			return
		end
		
		--If the slot already has that weapon then abort!
		if weaponIndex == slotWeapon then
			self.replace = nil
			return
		end
		
		--If slot doesn't exist on current ship then abort!
		if not self:ShipHasBank(slotShip, self.activeSlot) then
			self.replace = nil
			return
		end
		
		if count > 0 then
			self:ApplyWeaponToSlot(self.replace, self.currentShipSlot, self.activeSlot, weaponIndex)
				
			local w_type = 1
			if tb.WeaponClasses[weaponIndex]:isSecondary() then
				w_type = 2
			end
			
			local capacity = self:GetWeaponAmount(slotShip, weaponIndex, self:ConvertBankSlotToBank(slotShip, self.activeSlot, w_type))

			if count > capacity then
				ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].Amounts[self.activeSlot] = capacity
				self:SubtractWeaponFromPool(weaponIndex, capacity)
			else
				ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].Amounts[self.activeSlot] = count
				self:SubtractWeaponFromPool(weaponIndex, count)
			end

			if tb.WeaponClasses[weaponIndex]:isSecondary() then
				self.secondaryAmountEls[self.activeSlot - 3].inner_rml = ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].Amounts[self.activeSlot]
			end

			--return weapons to pool if appropriate
			self:ReturnWeaponToPool(slotWeapon, slotAmount)
			
			self.replace = nil
		end
	end
end

function WeaponSelectController:DragSlotEnd(element, slot)
	if (self.replace ~= nil) and (self.activeSlot > -1) then
		
		--Get the slot information of what's being dragged: ship, weapon, and amount
		local slotShip = ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].ShipClassIndex 
		local slotWeapon = ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].Weapons[slot]
		local slotAmount = ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].Amounts[slot]
		
		--Get the slot information of what's being dropped onto: weapon, and amount
		local activeWeapon = ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].Weapons[self.activeSlot]
		local activeAmount = ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].Amounts[self.activeSlot]
		
		--If we're just returning something to the pool then empty the slot and abort!
		if self.activeSlot == 0 then
			self:ReturnWeaponToPool(slotWeapon, slotAmount)
			
			self:EmptySlot(element, slot)
			
			self.replace = nil
			return
		end
		
		--If the ship is weapon locked then abort!
		local wing, wingSlot = self:GetWingSlot(self.currentShipSlot)
		if ui.ShipWepSelect.Loadout_Wings[wing][wingSlot].isWeaponLocked then
			self.replace = nil
			return
		end
		
		--If the slot can't accept the weapon then abort!
		if not self:IsWeaponAllowed(slotShip, slotWeapon) then
			self.replace = nil
			return
		end
		
		--If the slot already has that weapon then abort!
		if activeWeapon == slotWeapon then
			self.replace = nil
			return
		end

		--If slot doesn't exist on current ship then abort!
		if not self:ShipHasBank(slotShip, self.activeSlot) then
			self.replace = nil
			return
		end
		
		--Just double checking we aren't dragging a 0 amount
		if slotAmount > 0 then
			self:ApplyWeaponToSlot(self.replace, self.currentShipSlot, self.activeSlot, slotWeapon)
				
			local w_type = 1
			if tb.WeaponClasses[slotWeapon]:isSecondary() then
				w_type = 2
			end
			
			local capacity = self:GetWeaponAmount(slotShip, slotWeapon, self:ConvertBankSlotToBank(slotShip, self.activeSlot, w_type))

			if slotAmount > capacity then
				ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].Amounts[self.activeSlot] = capacity
				--Get what's leftover to return to the pool
				local difference = slotAmount - capacity
				self:ReturnWeaponToPool(slotWeapon, difference)
			else
				ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].Amounts[self.activeSlot] = slotAmount
			end
			
			if tb.WeaponClasses[slotWeapon]:isSecondary() then
				self.secondaryAmountEls[self.activeSlot - 3].inner_rml = ui.ShipWepSelect.Loadout_Ships[self.currentShipSlot].Amounts[self.activeSlot]
			end

			self:ReturnWeaponToPool(activeWeapon, activeAmount)
			
			self:EmptySlot(element, slot)
			
			self.replace = nil
		end
	end		
end

function WeaponSelectController:SetFilled(thisSlot, status)

	local curWing = 0
	local curSlot = 0
	if thisSlot < 5 then
		curWing = 1
		curSlot = thisSlot
	elseif thisSlot < 9 then
		curWing = 2
		curSlot = thisSlot - 4
	else
		curWing = 3
		curSlot = thisSlot - 8
	end
	ui.ShipWepSelect.Loadout_Wings[curWing][curSlot].isFilled = status
			
end

function WeaponSelectController:GetWeaponAmount(shipIndex, weaponIndex, bank)
	
	--Primaries always get set to 1, even ballistics
	if tb.WeaponClasses[weaponIndex]:isPrimary() then
		return 1
	end
	
	local capacity = tb.ShipClasses[shipIndex]:getSecondaryBankCapacity(bank)
	local amount = capacity / tb.WeaponClasses[weaponIndex].CargoSize
	return math.floor(amount+0.5)

end

function WeaponSelectController:GetFirstAllowedWeapon(shipIndex, bank, category)

	i = 1
	while (i < #tb.WeaponClasses) do
		if (tb.WeaponClasses[i]:isPrimary() and (category == 1)) or (tb.WeaponClasses[i]:isSecondary() and (category == 2)) then
			if ui.ShipWepSelect.Weapon_Pool[i] > 0 then
				if tb.ShipClasses[shipIndex]:isWeaponAllowedOnShip(i, bank) then
					return i
				end
			end
		end
		i = i + 1
	end
	
	return -1

end

function WeaponSelectController:Show(text, title, buttons)
	--Create a simple dialog box with the text and title

	currentDialog = true
	
	local dialog = dialogs.new()
		dialog:title(title)
		dialog:text(text)
		dialog:escape("")
		for i = 1, #buttons do
			dialog:button(buttons[i].b_type, buttons[i].b_text, buttons[i].b_value, buttons[i].b_keypress)
		end
		dialog:show(self.document.context)
		:continueWith(function(response)
        --do nothing
    end)
	-- Route input to our context until the user dismisses the dialog box.
	ui.enableInput(self.document.context)
end

function WeaponSelectController:reset_pressed(element)
    ui.playElementSound(element, "click", "success")
    ui.ShipWepSelect:resetSelect()
	self:ReloadList()
end

function WeaponSelectController:accept_pressed()
    
	local errorValue = ui.Briefing.commitToMission()
	local text = ""
	
	--General Fail
	if errorValue == 1 then
		text = ba.XSTR("An error has occured", -1)
	--A player ship has no weapons
	elseif errorValue == 2 then
		text = ba.XSTR("Player ship has no weapons", 461)
	--The required weapon was not loaded on a ship
	elseif errorValue == 3 then
		text = ba.XSTR("The " .. self.requiredWeps[1] .. " is required for this mission, but it has not been added to any ship loadout.", 1624)
	--Two or more required weapons were not loaded on a ship
	elseif errorValue == 4 then
		local WepsString = ""
		for i = 1, #self.requiredWeps, 1 do
			WepsString = WepsString .. self.requiredWeps[i] .. "\n"
		end
		text = ba.XSTR("The following weapons are required for this mission, but at least one of them has not been added to any ship loadout:\n\n" .. WepsString, 1625)
	--There is a gap in a ship's weapon banks
	elseif errorValue == 5 then
		text = ba.XSTR("At least one ship has an empty weapon bank before a full weapon bank.\n\nAll weapon banks must have weapons assigned, or if there are any gaps, they must be at the bottom of the set of banks.", 1642)
	--A player has no weapons
	elseif errorValue == 6 then
		local player = ba.getCurrentPlayer():getName()
		text = ba.XSTR("Player " .. player .. " must select a place in player wing", 462)
	--Success!
	else
		text = nil
		RocketUiSystem.selectInit = false
		if RocketUiSystem.music_handle ~= nil and RocketUiSystem.music_handle:isValid() then
			RocketUiSystem.music_handle:close(true)
		end
		RocketUiSystem.music_handle = nil
		RocketUiSystem.current_played = nil
	end

	if text ~= nil then
		text = string.gsub(text,"\n","<br></br>")
		local title = ""
		local buttons = {}
		buttons[1] = {
			b_type = dialogs.BUTTON_TYPE_POSITIVE,
			b_text = ba.XSTR("Okay", -1),
			b_value = "",
			b_keypress = string.sub(ba.XSTR("Ok", -1), 1, 1)
		}
		
		self:Show(text, title, buttons)
	end

end

function WeaponSelectController:options_button_clicked(element)
    ui.playElementSound(element, "click", "success")
    ba.postGameEvent(ba.GameEvents["GS_EVENT_OPTIONS_MENU"])
end

function WeaponSelectController:help_clicked(element)
    ui.playElementSound(element, "click", "success")
    --TODO
end

function WeaponSelectController:global_keydown(element, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
		if RocketUiSystem.music_handle ~= nil and RocketUiSystem.music_handle:isValid() then
			RocketUiSystem.music_handle:close(true)
		end
		RocketUiSystem.music_handle = nil
		RocketUiSystem.current_played = nil
        event:StopPropagation()

		ba.postGameEvent(ba.GameEvents["GS_EVENT_START_BRIEFING"])
        --ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
	--elseif event.parameters.key_identifier == rocket.key_identifier.UP and event.parameters.ctrl_key == 1 then
	--	self:ChangeTechState(3)
	--elseif event.parameters.key_identifier == rocket.key_identifier.DOWN and event.parameters.ctrl_key == 1 then
	--	self:ChangeTechState(1)
	end
end

function WeaponSelectController:unload()

	modelDraw.class = nil
	ui.ShipWepSelect:saveLoadout()
	
end

function WeaponSelectController:startMusic()
	local filename = ui.Briefing.getBriefingMusicName()

    if #filename <= 0 then
        return
    end
	
	if filename ~= RocketUiSystem.current_played then
	
		if RocketUiSystem.music_handle ~= nil and RocketUiSystem.music_handle:isValid() then
			RocketUiSystem.music_handle:close(true)
		end

		RocketUiSystem.music_handle = ad.openAudioStream(filename, AUDIOSTREAM_MENUMUSIC)
		RocketUiSystem.music_handle:play(ad.MasterEventMusicVolume, true)
		RocketUiSystem.current_played = filename
	end
end

function WeaponSelectController:drawSelectModel()

	if modelDraw.class and (ba.getCurrentGameState().Name == "GS_STATE_WEAPON_SELECT") and (modelDraw.element ~= nil) then  --Haaaaaaacks
		
		--local thisItem = tb.ShipClasses(modelDraw.class)
		modelView = modelDraw.element	
		local modelLeft = modelView.parent_node.offset_left + modelView.offset_left --This is pretty messy, but it's functional
		local modelTop = modelView.parent_node.offset_top + modelView.parent_node.parent_node.offset_top + modelView.offset_top
		local modelWidth = modelView.offset_width
		local modelHeight = modelView.offset_height
		
		--This is just a multipler to make the rendered model a little bigger
		--renderSelectModel() has forced centering, so we need to calculate
		--the screen size so we can move it slightly left and up while it
		--multiple it's size
		local val = -0.3
		local ratio = (gr.getScreenWidth() / gr.getScreenHeight()) * 2
		
		--Increase by percentage and move slightly left and up.
		modelLeft = modelLeft * (1 - (val/ratio))
		modelTop = modelTop * (1 - val)
		modelWidth = modelWidth * (1 + val)
		modelHeight = modelHeight * (1 + val)
		
		local test = tb.WeaponClasses[modelDraw.class]:renderSelectModel(modelDraw.start, modelLeft, modelTop, modelWidth, modelHeight)
		
		modelDraw.start = false
		
	end

end

function WeaponSelectController:drawOverheadModel()

	if modelDraw.OverheadClass and ba.getCurrentGameState().Name == "GS_STATE_WEAPON_SELECT" then  --Haaaaaaacks
	
		if modelDraw.class == nil then modelDraw.class = -1 end
		if modelDraw.Hover == nil then modelDraw.Hover = -1 end
		
		--local thisItem = tb.ShipClasses(modelDraw.class)
		modelView = modelDraw.OverheadElement	
		local modelLeft = modelView.parent_node.offset_left + modelView.offset_left --This is pretty messy, but it's functional
		local modelTop = modelView.parent_node.offset_top + modelView.parent_node.parent_node.offset_top + modelView.offset_top
		local modelWidth = modelView.offset_width
		local modelHeight = modelView.offset_height
		
		--Get bank coords. This is all super messy but it's the best we can do
		--without absolute coords available in the librocket Lua API
		local primary_offset = 15
		local secondary_offset = -15
		
		local bank1_x = modelDraw.banks.bank1.offset_left + modelDraw.banks.bank1.parent_node.offset_left + modelLeft + modelDraw.banks.bank1.offset_width + primary_offset
		local bank1_y = modelDraw.banks.bank1.offset_top + modelDraw.banks.bank1.parent_node.offset_top + modelTop + (modelDraw.banks.bank1.offset_height / 2)
		
		local bank2_x = modelDraw.banks.bank2.offset_left + modelDraw.banks.bank2.parent_node.offset_left + modelLeft + modelDraw.banks.bank2.offset_width + primary_offset
		local bank2_y = modelDraw.banks.bank2.offset_top + modelDraw.banks.bank2.parent_node.offset_top + modelTop + (modelDraw.banks.bank2.offset_height / 2)
		
		local bank3_x = modelDraw.banks.bank3.offset_left + modelDraw.banks.bank3.parent_node.offset_left + modelLeft + modelDraw.banks.bank3.offset_width + primary_offset
		local bank3_y = modelDraw.banks.bank3.offset_top + modelDraw.banks.bank3.parent_node.offset_top + modelTop + (modelDraw.banks.bank3.offset_height / 2)
		
		local bank4_x = modelDraw.banks.bank4.offset_left + modelDraw.banks.bank4.parent_node.offset_left + modelLeft + secondary_offset
		local bank4_y = modelDraw.banks.bank4.offset_top + modelDraw.banks.bank4.parent_node.offset_top + modelTop + (modelDraw.banks.bank4.offset_height / 2)
		
		local bank5_x = modelDraw.banks.bank4.offset_left + modelDraw.banks.bank5.parent_node.offset_left + modelLeft + secondary_offset
		local bank5_y = modelDraw.banks.bank5.offset_top + modelDraw.banks.bank5.parent_node.offset_top + modelTop + (modelDraw.banks.bank5.offset_height / 2)
		
		local bank6_x = modelDraw.banks.bank4.offset_left + modelDraw.banks.bank6.parent_node.offset_left + modelLeft + secondary_offset
		local bank6_y = modelDraw.banks.bank6.offset_top + modelDraw.banks.bank6.parent_node.offset_top + modelTop + (modelDraw.banks.bank6.offset_height / 2)
		
		local bank7_x = modelDraw.banks.bank4.offset_left + modelDraw.banks.bank7.parent_node.offset_left + modelLeft + secondary_offset
		local bank7_y = modelDraw.banks.bank7.offset_top + modelDraw.banks.bank7.parent_node.offset_top + modelTop + (modelDraw.banks.bank7.offset_height / 2)
		
		--This is just a multipler to make the rendered model a little bigger
		--renderSelectModel() has forced centering, so we need to calculate
		--the screen size so we can move it slightly left and up while it
		--multiple it's size
		local val = 0.0
		local ratio = (gr.getScreenWidth() / gr.getScreenHeight()) * 2
		
		--Increase by percentage and move slightly left and up.
		modelLeft = modelLeft * (1 - (val/ratio))
		modelTop = modelTop * (1 - val)
		modelWidth = modelWidth * (1 + val)
		modelHeight = modelHeight * (1 + val)
		
		local test = tb.ShipClasses[modelDraw.OverheadClass]:renderOverheadModel(modelLeft, modelTop, modelWidth, modelHeight, modelDraw.Slot, modelDraw.class, modelDraw.Hover, bank1_x, bank1_y, bank2_x, bank2_y, bank3_x, bank3_y, bank4_x, bank4_y, bank5_x, bank5_y, bank6_x, bank6_y, bank7_x, bank7_y, modelDraw.overheadEffect)
		
		modelDraw.start = false
		
	end

end

engine.addHook("On Frame", function()
	if ba.getCurrentGameState().Name == "GS_STATE_WEAPON_SELECT" then
		WeaponSelectController:drawSelectModel()
		WeaponSelectController:drawOverheadModel()
	end
end, {}, function()
    return false
end)

return WeaponSelectController
