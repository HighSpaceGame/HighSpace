local dialogs = require("dialogs")
local class = require("class")
local async_util = require("async_util")

--local AbstractBriefingController = require("briefingCommon")

--local BriefingController = class(AbstractBriefingController)

local ShipSelectController = class()

local modelDraw = nil

function ShipSelectController:init()
	if not RocketUiSystem.selectInit then
		ui.ShipWepSelect.initSelect()
		RocketUiSystem.selectInit = true
	end
	modelDraw = {}
end

function ShipSelectController:initialize(document)
    --AbstractBriefingController.initialize(self, document)
	self.document = document
	self.elements = {}
	self.slots = {}
	self.aniEl = self.document:CreateElement("ani")
	self.requiredWeps = {}
	self.emptyWingSlot = {}
	
	
	self.ship3d, self.shipEffect, self.icon3d = ui.ShipWepSelect.get3dShipChoices()
	
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
	aniWrapper:ReplaceChild(self.aniEl, aniWrapper.first_child)

	---Load the desired font size from the save file
	if modOptionValues.Font_Multiplier then
		fontChoice = modOptionValues.Font_Multiplier
		self.document:GetElementById("main_background"):SetClass(("p1-" .. fontChoice), true)
	else
		self.document:GetElementById("main_background"):SetClass("p1-5", true)
	end
	
	self.document:GetElementById("brief_btn"):SetPseudoClass("checked", false)
	self.document:GetElementById("s_select_btn"):SetPseudoClass("checked", true)
	self.document:GetElementById("w_select_btn"):SetPseudoClass("checked", false)
	
	--ui.ShipWepSelect.initSelect()
	
	self.SelectedEntry = nil
	self.list = {}
	
	local shipList = tb.ShipClasses
	local i = 1
	local j = 1
	while (i ~= #shipList) do
		if ui.ShipWepSelect.Ship_Pool[i] > 0 then
			if rocketUiIcons[shipList[i].Name] == nil then
				ba.warning("No generated icon was found for " .. shipList[i].Name .. "! This means it is missing custom data in the table to flag for pre-generation or it is not meant to be available in the loadout pool. Generating one now.")
				RocketUiSystem:setIconFrames(shipList[i].Name)
			end
			self.list[j] = {
				Index = i,
				Amount = ui.ShipWepSelect.Ship_Pool[i],
				Icon = shipList[i].SelectIconFilename,
				GeneratedIcon = {},
				Anim = shipList[i].SelectAnimFilename,
				Overhead = shipList[i].SelectOverheadFilename,
				Name = shipList[i].Name,
				Type = shipList[i].TypeString,
				Length = shipList[i].LengthString,
				Velocity = shipList[i].VelocityString,
				Maneuverability = shipList[i].ManeuverabilityString,
				Armor = shipList[i].ArmorString,
				GunMounts = shipList[i].GunMountsString,
				MissileBanks = shipList[i].MissileBanksString,
				Manufacturer = shipList[i].ManufacturerString,
				GeneratedWidth = rocketUiIcons[shipList[i].Name].Width,
				GeneratedHeight = rocketUiIcons[shipList[i].Name].Height,
				GeneratedIcon = rocketUiIcons[shipList[i].Name].Icon
			}
			j = j + 1
		end
		i = i + 1
	end
	
	--Add any ships that exist in wings but have 0 in the pool
	self:CheckSlots()
	--Now sort the lists by the ship index
	table.sort(self.list, function(a,b) return a.Index < b.Index end)
	
	--generate usable icons
	--self:getIconFrames(self.list)
	self:getEmptySlotFrames()
	
	--Only create entries if there are any to create
	if self.list[1] then
		self:CreateEntries(self.list)
	end
	
	--self:InitSlots()
	self:BuildWings()
	
	if self.list[1] then
		self:SelectEntry(self.list[1])
	end
	
	self:startMusic()

end

function ShipSelectController:getEmptySlotFrames()

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

function ShipSelectController:BuildWings()

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
						thisEntry = self:AppendToPool(self.slots[slotNum].Name)
					end
					self.slots[slotNum].entry = thisEntry
					
					if not self.slots[slotNum].isLocked then
						--Add dragover detection
						slotEl:AddEventListener("dragdrop", function(_, _, _)
							self:DragOver(slotEl, index)
						end)
						
						--Add drag detection
						slotEl:SetClass("drag", true)
						slotEl:AddEventListener("dragend", function(_, _, _)
							self:DragSlotEnd(slotEl, thisEntry, thisEntry.Index, index)
						end)
						
						if self.icon3d then
							slotEl:SetClass("available", true)
						end
					else
						if self.icon3d then
							slotEl:SetClass("locked", true)
						end
					end
					
					--Add click detection
					slotEl:SetClass("button_3", true)
					slotEl:AddEventListener("click", function(_, _, _)
						self:SelectEntry(thisEntry)
					end)
				else
					--Add dragover detection
					slotEl:AddEventListener("dragdrop", function(_, _, _)
						self:DragOver(slotEl, index)
					end)
				end
			end
			
			slotNum = slotNum + 1
		end
	end

end

function ShipSelectController:CheckSlots()

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

function ShipSelectController:IsSlotDisabled(slot)

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

function ShipSelectController:GetShipEntry(shipIndex)

	for i, v in ipairs(self.list) do
		if v.Index == shipIndex then
			return v
		end
	end

end

function ShipSelectController:AppendToPool(ship)

	if rocketUiIcons[tb.ShipClasses[ship].Name] == nil then
		ba.warning("No generated icon was found for " .. tb.ShipClasses[ship].Name .. "! This means it is missing custom data in the table to flag for pre-generation or it is not meant to be available in the loadout pool. Generating one now.")
		RocketUiSystem:setIconFrames(tb.ShipClasses[ship].Name, true)
	end

	i = #self.list + 1
	self.list[i] = {
		Index = tb.ShipClasses[ship]:getShipClassIndex(),
		Amount = 0,
		Icon = tb.ShipClasses[ship].SelectIconFilename,
		GeneratedIcon = {},
		Anim = tb.ShipClasses[ship].SelectAnimFilename,
		Name = tb.ShipClasses[ship].Name,
		Type = tb.ShipClasses[ship].TypeString,
		Length = tb.ShipClasses[ship].LengthString,
		Velocity = tb.ShipClasses[ship].VelocityString,
		Maneuverability = tb.ShipClasses[ship].ManeuverabilityString,
		Armor = tb.ShipClasses[ship].ArmorString,
		GunMounts = tb.ShipClasses[ship].GunMountsString,
		MissileBanks = tb.ShipClasses[ship].MissileBanksString,
		Manufacturer = tb.ShipClasses[ship].ManufacturerString,
		key = tb.ShipClasses[ship].Name,
		GeneratedWidth = rocketUiIcons[tb.ShipClasses[ship].Name].Width,
		GeneratedHeight = rocketUiIcons[tb.ShipClasses[ship].Name].Height,
		GeneratedIcon = rocketUiIcons[tb.ShipClasses[ship].Name].Icon
	}
	return self.list[i]
end

function ShipSelectController:ReloadList()

	modelDraw.class = nil
	local list_items_el = self.document:GetElementById("ship_icon_list_ul")
	self:ClearEntries(list_items_el)
	self.SelectedEntry = nil
	self:CreateEntries(self.list)
	self:BuildWings()
	if self.list[1] then
		self:SelectEntry(self.list[1])
	end
end

function ShipSelectController:CreateEntryItem(entry, idx)

	local li_el = self.document:CreateElement("li")
	local iconWrapper = self.document:CreateElement("div")
	iconWrapper.id = entry.Name
	iconWrapper:SetClass("select_item", true)
	
	li_el:AppendChild(iconWrapper)
	
	local countEl = self.document:CreateElement("div")
	countEl.inner_rml = entry.Amount
	countEl:SetClass("amount", true)
	
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

function ShipSelectController:CreateEntries(list)

	local list_names_el = self.document:GetElementById("ship_icon_list_ul")
	
	self:ClearEntries(list_names_el)

	for i, v in pairs(list) do
		list_names_el:AppendChild(self:CreateEntryItem(v, i))
	end
end

function ShipSelectController:HighlightShip(entry)

	for i, v in pairs(self.list) do
		local iconEl = self.document:GetElementById(v.key).first_child.first_child.next_sibling
		if v.key == entry.key then
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
	
	for i = 1, 12, 1 do
		local element = self.document:GetElementById("slot_" .. i)
		local shipIndex = ui.ShipWepSelect.Loadout_Ships[i].ShipClassIndex
		if shipIndex > 0 then
			local thisEntry = self:GetShipEntry(shipIndex)
			if self.slots[i].Name == entry.Name then
				if not self.slots[i].isPlayer then
					if self.slots[i].isLocked then
						element.first_child:SetAttribute("src", thisEntry.GeneratedIcon[5])
					else
						element.first_child:SetAttribute("src", thisEntry.GeneratedIcon[3])
					end
				end
			else
				if not self.slots[i].isPlayer then
					if self.slots[i].isLocked then
						element.first_child:SetAttribute("src", thisEntry.GeneratedIcon[6])
					else
						element.first_child:SetAttribute("src", thisEntry.GeneratedIcon[1])
					end
				end
			end
		end
	end
				
end

function ShipSelectController:SelectEntry(entry)

	if entry.key ~= self.SelectedEntry then
		
		self.SelectedEntry = entry.key
		
		self:HighlightShip(entry)
		
		self:BuildInfo(entry)
		
		if self.ship3d or entry.Anim == nil then
			modelDraw.class = entry.Index
			modelDraw.element = self.document:GetElementById("ship_view_wrapper")
			modelDraw.start = true
		else
			--the anim is already created so we only need to remove and reset the src
			self.aniEl:RemoveAttribute("src")
			self.aniEl:SetAttribute("src", entry.Anim)
		end
		
	end

end

function ShipSelectController:ClearEntries(parent)

	while parent:HasChildNodes() do
		parent:RemoveChild(parent.first_child)
	end

end

function ShipSelectController:BuildInfo(entry)

	local infoEl = self.document:GetElementById("ship_stats_info")
	
	local midString = "</p><p class=\"info\">"
	
	local shipClass    = "<p>" .. ba.XSTR("Class", 739) .. midString .. entry.Name .. "</p>"
	local shipType     = "<p>" .. ba.XSTR("Type", 740) .. midString .. entry.Type .. "</p>"
	local shipLength   = "<p>" .. ba.XSTR("Length", 741) .. midString .. entry.Length .. "</p>"
	local shipVelocity = "<p>" .. ba.XSTR("Max Velocity", 742) .. midString .. entry.Velocity .. "</p>"
	local shipManeuv   = "<p>" .. ba.XSTR("Maneuverability", 744) .. midString .. entry.Maneuverability .. "</p>"
	local shipArmor    = "<p>" .. ba.XSTR("Armor", 745) .. midString .. entry.Armor .. "</p>"
	local shipGuns     = "<p>" .. ba.XSTR("Gun Mounts", 746) .. midString .. entry.GunMounts .. "</p>"
	local shipMissiles = "<p>" .. ba.XSTR("Missile Banks", 747) .. midString .. entry.MissileBanks .. "</p>"
	local shipManufac  = "<p>" .. ba.XSTR("Manufacturer", 748) .. midString .. entry.Manufacturer .. "</p>"

	local completeRML = shipClass .. shipType .. shipLength .. shipVelocity .. shipManeuv .. shipArmor .. shipGuns .. shipMissiles .. shipManufac
	
	infoEl.inner_rml = completeRML

end

function ShipSelectController:ChangeBriefState(state)
	if state == 1 then
		ba.postGameEvent(ba.GameEvents["GS_EVENT_START_BRIEFING"])
	elseif state == 2 then
		--Do nothing because we're this is the current state!
	elseif state == 3 then
		if mn.isScramble() then
			ad.playInterfaceSound(10)
		else
			ba.postGameEvent(ba.GameEvents["GS_EVENT_WEAPON_SELECTION"])
		end
	end
end

function ShipSelectController:DragOver(element, slot)
	self.replace = element
	self.activeSlot = slot
end

function ShipSelectController:DragPoolEnd(element, entry, shipIndex)
	if (self.replace ~= nil) and (self.activeSlot > 0) then
		--Get the amount of the ship we're dragging
		local countEl = self.document:GetElementById(entry.Name).first_child
		local count = tonumber(countEl.first_child.inner_rml)
		
		--If the pool count is 0 then abort!
		if count < 1 then
			self.replace = nil
			return
		end
		
		if count > 0 then
			if self.slots[self.activeSlot].Name == nil then
				self.slots[self.activeSlot].Name = entry.Name
				count = count - 1
				countEl.first_child.inner_rml = count
			else
				--Get the amount of the ship we're sending back
				local countBackEl = self.document:GetElementById(self.slots[self.activeSlot].Name).first_child
				local countBack = tonumber(countBackEl.first_child.inner_rml) + 1
				countBackEl.first_child.inner_rml = countBack
				self.slots[self.activeSlot].Name = entry.Name
				count = count - 1
				countEl.first_child.inner_rml = count
			end
			local replace_el = self.document:GetElementById(self.replace.id)
			local imgEl = self.document:CreateElement("img")
			imgEl:SetAttribute("src", element:GetAttribute("src"))
			self.document:GetElementById(replace_el.id):RemoveChild(replace_el.first_child)
			self.document:GetElementById(replace_el.id):AppendChild(imgEl)
			replace_el:SetClass("drag", true)
			
			self:SetFilled(self.activeSlot, true)
			
			--This is where we return the previous ship and its weapons to the pool
			if ui.ShipWepSelect.Loadout_Ships[self.activeSlot].ShipClassIndex > 1 then
				self:ReturnShip(self.activeSlot)
			end
			--Now set the new ship and weapons
			ui.ShipWepSelect.Loadout_Ships[self.activeSlot].ShipClassIndex = shipIndex
			self:SetDefaultWeapons(self.activeSlot, shipIndex)
			replace_el:SetClass("button_3", true)
			replace_el:AddEventListener("click", function(_, _, _)
				self:SelectEntry(entry)
			end)
			
			self.replace = nil
		end
	end
end

function ShipSelectController:DragSlotEnd(element, entry, shipIndex, currentSlot)
	if (self.replace ~= nil) and (self.activeSlot > 0) then
		if self.slots[self.activeSlot].Name ~= nil then
			--Get the amount of the ship we're sending back
			local countBackEl = self.document:GetElementById(self.slots[self.activeSlot].Name).first_child
			local countBack = tonumber(countBackEl.first_child.inner_rml) + 1
			countBackEl.first_child.inner_rml = countBack
		end
		
		self.slots[self.activeSlot].Name = entry.Name
		
		local replace_el = self.document:GetElementById(self.replace.id)
		local imgEl = self.document:CreateElement("img")
		imgEl:SetAttribute("src", element.first_child:GetAttribute("src"))
		self.document:GetElementById(replace_el.id):RemoveChild(replace_el.first_child)
		self.document:GetElementById(replace_el.id):AppendChild(imgEl)
		replace_el:SetClass("drag", true)
		
		element.first_child:SetAttribute("src", self.emptyWingSlot[2])
		ui.ShipWepSelect.Loadout_Ships[currentSlot].ShipClassIndex = -1
		self.slots[currentSlot].Name = nil
		element:SetClass("drag", false)
		
		self:SetFilled(currentSlot, false)
		self:SetFilled(self.activeSlot, true)
		
		--This is where we return the previous ship and its weapons to the pool
		if ui.ShipWepSelect.Loadout_Ships[self.activeSlot].ShipClassIndex > 1 then
			self:ReturnShip(self.activeSlot)
		end
		--Now set the new ship and weapons
		ui.ShipWepSelect.Loadout_Ships[self.activeSlot].ShipClassIndex = shipIndex
		self:SetDefaultWeapons(self.activeSlot, shipIndex)
		
		replace_el:SetClass("button_3", true)
		replace_el:AddEventListener("click", function(_, _, _)
			self:SelectEntry(entry)
		end)
		
		self.replace = nil
	elseif (self.replace ~= nil) and (self.activeSlot == 0) then	
		--Get the amount of the ship we're sending back
		local countBackEl = self.document:GetElementById(self.slots[currentSlot].Name).first_child
		local countBack = tonumber(countBackEl.first_child.inner_rml) + 1
		countBackEl.first_child.inner_rml = countBack
		element:SetClass("drag", false)
		
		element.first_child:SetAttribute("src", self.emptyWingSlot[2])
		self:ReturnShip(currentSlot)
		ui.ShipWepSelect.Loadout_Ships[currentSlot].ShipClassIndex = -1
		self.slots[currentSlot].Name = nil
		
		self:SetFilled(currentSlot, false)
	end
end

function ShipSelectController:SetFilled(thisSlot, status)

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
	ui.ShipWepSelect.Loadout_Ships[thisSlot].ShipClassIndex = -1
			
end

function ShipSelectController:ReturnShip(slot)

	--Return all the weapons to the pool
	for i = 1, #ui.ShipWepSelect.Loadout_Ships[slot].Weapons, 1 do
		local weapon = ui.ShipWepSelect.Loadout_Ships[slot].Weapons[i]
		if weapon > 0 then
			local amount = ui.ShipWepSelect.Loadout_Ships[slot].Amounts[i]
			ui.ShipWepSelect.Weapon_Pool[weapon] = ui.ShipWepSelect.Weapon_Pool[weapon] + amount
		end
	end
	
	--Return the ship
	local ship = ui.ShipWepSelect.Loadout_Ships[slot].ShipClassIndex
	ui.ShipWepSelect.Ship_Pool[ship] = ui.ShipWepSelect.Ship_Pool[ship] + 1

end

function ShipSelectController:SetDefaultWeapons(slot, shipIndex)

	--Primaries
	for i = 1, #tb.ShipClasses[shipIndex].defaultPrimaries, 1 do
		local weapon = tb.ShipClasses[shipIndex].defaultPrimaries[i]:getWeaponClassIndex()
		--Check the weapon pool
		if ui.ShipWepSelect.Weapon_Pool[weapon] <= 0 then
			--Find a new weapon
			weapon = self:GetFirstAllowedWeapon(shipIndex, i, 1)
		end
		--Primaries always get amount of 1
		local amount = 1
		--Set the weapon
		ui.ShipWepSelect.Loadout_Ships[slot].Weapons[i] = weapon
		ui.ShipWepSelect.Loadout_Ships[slot].Amounts[i] = amount
		--Subtract from the pool
		ui.ShipWepSelect.Weapon_Pool[weapon] = ui.ShipWepSelect.Weapon_Pool[weapon] - amount
	end
	
	--Secondaries
	for i = 1, #tb.ShipClasses[shipIndex].defaultSecondaries, 1 do
		local weapon = tb.ShipClasses[shipIndex].defaultSecondaries[i]:getWeaponClassIndex()
		--Check the weapon pool
		if ui.ShipWepSelect.Weapon_Pool[weapon] <= 0 then
			--Find a new weapon
			weapon = self:GetFirstAllowedWeapon(shipIndex, i, 2)
		end
		--Get an appropriate amount for the weapon and bank
		local amount = self:GetWeaponAmount(shipIndex, weapon, i)
		if amount > ui.ShipWepSelect.Weapon_Pool[weapon] then
			amount = ui.ShipWepSelect.Weapon_Pool[weapon]
		end
		--Set the weapon
		ui.ShipWepSelect.Loadout_Ships[slot].Weapons[i + 3] = weapon
		ui.ShipWepSelect.Loadout_Ships[slot].Amounts[i + 3] = amount
		--Subtract from the pool
		ui.ShipWepSelect.Weapon_Pool[weapon] = ui.ShipWepSelect.Weapon_Pool[weapon] - amount
	end

end

function ShipSelectController:GetWeaponAmount(shipIndex, weaponIndex, bank)
	
	--Primaries always get set to 1, even ballistics
	if tb.WeaponClasses[weaponIndex]:isPrimary() then
		return 1
	end
	
	local capacity = tb.ShipClasses[shipIndex]:getSecondaryBankCapacity(bank)
	local amount = capacity / tb.WeaponClasses[weaponIndex].CargoSize
	return math.floor(amount+0.5)

end

function ShipSelectController:GetFirstAllowedWeapon(shipIndex, bank, category)

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

function ShipSelectController:Show(text, title, buttons)
	--Create a simple dialog box with the text and title

	currentDialog = true
	modelDraw.save = modelDraw.class
	modelDraw.class = nil
	
	local dialog = dialogs.new()
		dialog:title(title)
		dialog:text(text)
		dialog:escape("")
		for i = 1, #buttons do
			dialog:button(buttons[i].b_type, buttons[i].b_text, buttons[i].b_value, buttons[i].b_keypress)
		end
		dialog:show(self.document.context)
		:continueWith(function(response)
			modelDraw.class = modelDraw.save
			modelDraw.save = nil
    end)
	-- Route input to our context until the user dismisses the dialog box.
	ui.enableInput(self.document.context)
end

function ShipSelectController:reset_pressed(element)
    ui.playElementSound(element, "click", "success")
    ui.ShipWepSelect:resetSelect()
	self:ReloadList()
end

function ShipSelectController:accept_pressed()
    
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

function ShipSelectController:options_button_clicked(element)
    ui.playElementSound(element, "click", "success")
    ba.postGameEvent(ba.GameEvents["GS_EVENT_OPTIONS_MENU"])
end

function ShipSelectController:help_clicked(element)
    ui.playElementSound(element, "click", "success")
    --TODO
end

function ShipSelectController:global_keydown(element, event)
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

function ShipSelectController:unload()

	modelDraw.class = nil
	ui.ShipWepSelect:saveLoadout()
	
end

function ShipSelectController:startMusic()
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

function ShipSelectController:drawSelectModel()

	if modelDraw.class and ba.getCurrentGameState().Name == "GS_STATE_SHIP_SELECT" then  --Haaaaaaacks

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
		local val = 0.3
		local ratio = (gr.getScreenWidth() / gr.getScreenHeight()) * 2
		
		--Increase by percentage and move slightly left and up.
		modelLeft = modelLeft * (1 - (val/ratio))
		modelTop = modelTop * (1 - val)
		modelWidth = modelWidth * (1 + val)
		modelHeight = modelHeight * (1 + val)
		
		local test = tb.ShipClasses[modelDraw.class]:renderSelectModel(modelDraw.start, modelLeft, modelTop, modelWidth, modelHeight)
		
		modelDraw.start = false
		
	end

end

engine.addHook("On Frame", function()
	if ba.getCurrentGameState().Name == "GS_STATE_SHIP_SELECT" then
		ShipSelectController:drawSelectModel()
	end
end, {}, function()
    return false
end)

return ShipSelectController
