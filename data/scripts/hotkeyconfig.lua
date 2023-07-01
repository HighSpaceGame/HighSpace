local class = require("class")

local HotkeyController = class()
local fontMultiplier = nil

function HotkeyController:init()
end

function HotkeyController:initialize(document)

    self.document = document
	
	---Load the desired font size from the save file
	if ScpuiOptionValues.Font_Multiplier then
		local fontChoice = ScpuiOptionValues.Font_Multiplier
		fontMultiplier = ScpuiOptionValues.Font_Multiplier
		self.document:GetElementById("main_background"):SetClass(("p1-" .. fontChoice), true)
		self.document:GetElementById("current_key"):SetClass(("h2-" .. fontChoice), true)
	else
		self.document:GetElementById("main_background"):SetClass("p1-5", true)
		self.document:GetElementById("current_key"):SetClass("h2-5", true)
		fontMultiplier = 5
	end
	
	if mn.isInMission() then
		ad.pauseMusic(-1, true)
		ad.pauseWeaponSounds(true)
	end
	
	ui.MissionHotkeys.initHotkeysList()
	
	self:initHotkeys()
	self:createHotkeysList()
	
	self:ChangeKey(1)
end

function HotkeyController:initHotkeys()
	
	self.hotkeys = {}
	
	local section = 0
	local ship = 0
	
	for i = 1, #ui.MissionHotkeys.Hotkeys_List do
		local entry = ui.MissionHotkeys.Hotkeys_List[i]
		
		--maybe create a new section
		if entry.Type == HOTKEY_LINE_HEADING then
			section = #self.hotkeys + 1
			self.hotkeys[section] = {}
			self.hotkeys[section].heading = entry.Text
			self.hotkeys[section].ships = {}
			
			ship = 0
		else
			ship = ship + 1
			self.hotkeys[section].ships[ship] = {}
			
			self.hotkeys[section].ships[ship].text = entry.Text
			self.hotkeys[section].ships[ship].lineType = entry.Type
			self.hotkeys[section].ships[ship].keys = {}
			self.hotkeys[section].ships[ship].index = i
			
			local shipKeys = entry.Keys
			
			--on first run lets save how many hotkeys we have total
			if self.numKeys == nil then
				self.numKeys = #shipKeys
			end
			
			for key = 1, #shipKeys do
				local keyText = "F" .. tostring(key + 4)
				if shipKeys[key] then
					self.hotkeys[section].ships[ship].keys[key] = keyText
				else
					self.hotkeys[section].ships[ship].keys[key] = "&nbsp;"
				end
			end
		end
	end
end

function HotkeyController:createHotkeysList()

	local parent_el = self.document:GetElementById("log_text_wrapper")
	
	for i = 1, #self.hotkeys do
	
		local group_el = self.document:CreateElement("div")
		group_el.id = "group_" .. i
		group_el:SetClass("hotkey_group")
		parent_el:AppendChild(group_el)
		
		--create the header for the group
		local header_el = self.document:CreateElement("div")
		header_el.id = "header_" .. i
		header_el:SetClass("hotkey_header", true)
		header_el:SetClass("brightblue", true)
		header_el.inner_rml = self.hotkeys[i].heading
		group_el:AppendChild(header_el)
		
		--create the entry list
		local list_el = self.document:CreateElement("ul")
		list_el.id = "hotkey_list"
		group_el:AppendChild(list_el)
		
		for entry = 1, #self.hotkeys[i].ships do
			local li_el = self.document:CreateElement("li")
			li_el.id = "line_" .. i .. "_" .. entry
			local entryHTML = ""
			
			--insert key texts into divs
			for key = 1, #self.hotkeys[i].ships[entry].keys do
				local keyID = "key_" .. i .. "_" .. entry .. "_" .. key
				entryHTML = entryHTML .. "<div id=\"" .. keyID .. "\" class=\"key_display\">" .. self.hotkeys[i].ships[entry].keys[key] .. "</div>"
			end
			
			--insert the wing icon div
			local wingHTML = ""
			if self.hotkeys[i].ships[entry].lineType == HOTKEY_LINE_WING then
				wingHTML = "<div class=\"wing_icon wing_icon_vis\"><img src=\"multiplayer-h.png\" class=\"psuedo_img\"></img></div>"
			else
				wingHTML = "<div class=\"wing_icon\"><img src=\"multiplayer-h.png\" class=\"psuedo_img\"></img></div>"
			end
			entryHTML = entryHTML .. wingHTML
			
			--ships in a wing get a little indent
			local shipClass = "<div class=\"ship_name\">"
			if self.hotkeys[i].ships[entry].lineType == HOTKEY_LINE_SUBSHIP then
				shipClass = "<div class=\"ship_name wing_item\">"
			end
			--insert the ship name div
			entryHTML = entryHTML .. shipClass .. self.hotkeys[i].ships[entry].text .. "</div>"
			
			li_el.inner_rml = entryHTML
			li_el:SetClass("hotkeylist_element", true)
			li_el:SetClass("button_1", true)
			li_el:AddEventListener("click", function(_, _, _)
				self:SelectEntry(self.hotkeys[i].ships[entry].index, li_el, i, entry)
			end)
			li_el:AddEventListener("dblclick", function(_, _, _)
				self:ToggleKey(self.hotkeys[i].ships[entry].index, li_el, i, entry)
			end)
			
			list_el:AppendChild(li_el)
		end
	end

end

function HotkeyController:SelectEntry(idx, element, group, item)

	self.currentEntry = idx
	
	if self.oldElement == nil then
		self.oldElement = element
	else
		self.oldElement:SetPseudoClass("checked", false)
		self.oldElement = element
	end
	
	element:SetPseudoClass("checked", true)
	
	self.selectedGroup = group
	self.selectedElement = item

end

function HotkeyController:ToggleKey(idx, element, group, item)
	
	self:SelectEntry(idx, element, group, item)
	
	local keyID = "key_" .. self.selectedGroup .. "_" .. self.selectedElement .. "_" .. self.currentKey
	local key_el = self.document:GetElementById(keyID)
	
	local keyText = "F" .. tostring(self.currentKey + 4)
	if key_el.inner_rml == keyText then
		self:RemKey()
	else
		self:AddKey()
	end
	
end

function HotkeyController:AddKey()

	if self.currentKey == nil then
		ba.warning("How did that happen? Get Mjn")
		return
	end
	
	if self.currentEntry == nil then
		--nothing to do!
		return
	end

	ui.MissionHotkeys.Hotkeys_List[self.currentEntry]:addHotkey(self.currentKey)
	
	local keyID = "key_" .. self.selectedGroup .. "_" .. self.selectedElement .. "_" .. self.currentKey
	local key_el = self.document:GetElementById(keyID)
	
	local keyText = "F" .. tostring(self.currentKey + 4)
	key_el.inner_rml = keyText
	
	self:CheckWings(keyText)
end

function HotkeyController:RemKey()

	if self.currentKey == nil then
		ba.warning("How did that happen? Get Mjn")
		return
	end
	
	if self.currentEntry == nil then
		--nothing to do!
		return
	end
	
	ui.MissionHotkeys.Hotkeys_List[self.currentEntry]:removeHotkey(self.currentKey)
	
	local keyID = "key_" .. self.selectedGroup .. "_" .. self.selectedElement .. "_" .. self.currentKey
	local key_el = self.document:GetElementById(keyID)
	
	local keyText = "&nbsp;"
	key_el.inner_rml = keyText
	
	self:CheckWings(keyText)
end

function HotkeyController:CheckWings(text)

	if ui.MissionHotkeys.Hotkeys_List[self.currentEntry].Type == HOTKEY_LINE_WING then
		local idx = self.selectedElement
		--Max 6 ships in a wing so check all six following items in the list
		for i = self.currentEntry + 1, self.currentEntry + 6 do
			idx = idx + 1
			if ui.MissionHotkeys.Hotkeys_List[i].Type == HOTKEY_LINE_SUBSHIP then
				local keyID = "key_" .. self.selectedGroup .. "_" .. idx .. "_" .. self.currentKey
				local key_el = self.document:GetElementById(keyID)
				key_el.inner_rml = text
			end
		end
		
	end
	
end

function HotkeyController:ClearEntries(parent)

	while parent:HasChildNodes() do
		parent:RemoveChild(parent.first_child)
	end

end

function HotkeyController:ChangeKey(key)
	self.currentKey = key
	local key_el = self.document:GetElementById("current_key")
	local keyText = "F" .. tostring(self.currentKey + 4)
	
	key_el.inner_rml = keyText
end

function HotkeyController:DecrementKey()

    if self.currentKey == 1 then
		self:ChangeKey(8)
	else
		self:ChangeKey(self.currentKey - 1)
	end

end

function HotkeyController:IncrementKey()

    if self.currentKey == 8 then
		self:ChangeKey(1)
	else
		self:ChangeKey(self.currentKey + 1)
	end

end

function HotkeyController:ResetKeys()

    ui.playElementSound(element, "click", "success")
	ui.MissionHotkeys.resetHotkeys()
	
	local parent_el = self.document:GetElementById("log_text_wrapper")
	self:ClearEntries(parent_el)
	self:createHotkeysList()

end

function HotkeyController:ClearKey()

    ui.playElementSound(element, "click", "success")
	self:RemKey()

end

function HotkeyController:SetDefaults()

    ui.playElementSound(element, "click", "success")
	ui.MissionHotkeys.resetHotkeysDefault()
	
	local parent_el = self.document:GetElementById("log_text_wrapper")
	self:ClearEntries(parent_el)
	self:createHotkeysList()

end

function HotkeyController:Exit(element)

    ui.playElementSound(element, "click", "success")
	if mn.isInMission() then
		ad.pauseMusic(-1, false)
		ad.pauseWeaponSounds(false)
		ui.PauseScreen.closePause()
	end
	ui.MissionHotkeys.saveHotkeys()
	ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])

end

function HotkeyController:global_keydown(_, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
        event:StopPropagation()
		if mn.isInMission() then
			ad.pauseMusic(-1, false)
			ad.pauseWeaponSounds(false)
			ui.PauseScreen.closePause()
		end
		ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])
    elseif event.parameters.key_identifier == rocket.key_identifier.F5 then
		self:ChangeKey(1)
	elseif event.parameters.key_identifier == rocket.key_identifier.F6 then
		self:ChangeKey(2)
	elseif event.parameters.key_identifier == rocket.key_identifier.F7 then
		self:ChangeKey(3)
	elseif event.parameters.key_identifier == rocket.key_identifier.F8 then
		self:ChangeKey(4)
	elseif event.parameters.key_identifier == rocket.key_identifier.F9 then
		self:ChangeKey(5)
	elseif event.parameters.key_identifier == rocket.key_identifier.F10 then
		self:ChangeKey(6)
	elseif event.parameters.key_identifier == rocket.key_identifier.F11 then
		self:ChangeKey(7)
	elseif event.parameters.key_identifier == rocket.key_identifier.F12 then
		self:ChangeKey(8)
	end
end

return HotkeyController
