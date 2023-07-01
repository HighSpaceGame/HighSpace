local dialogs = require("dialogs")
local class = require("class")

local TechCutscenesController = class()

function TechCutscenesController:init()
	self.show_all = false
	self.Counter = 0
end

function TechCutscenesController:initialize(document)
    self.document = document
    self.elements = {}

	---Load the desired font size from the save file
	if modOptionValues.Font_Multiplier then
		local fontChoice = modOptionValues.Font_Multiplier
		self.document:GetElementById("main_background"):SetClass(("p1-" .. fontChoice), true)
	else
		self.document:GetElementById("main_background"):SetClass("p1-5", true)
	end
	
	--ba.warning(ui.TechRoom.Cutscenes[1].Filename)
	
	self.document:GetElementById("data_btn"):SetPseudoClass("checked", false)
	self.document:GetElementById("mission_btn"):SetPseudoClass("checked", false)
	self.document:GetElementById("cutscene_btn"):SetPseudoClass("checked", true)
	self.document:GetElementById("credits_btn"):SetPseudoClass("checked", false)
	
	self.SelectedEntry = nil
	self.list = {}
	
	local cutsceneList = ui.TechRoom.Cutscenes
	local i = 0
	while (i ~= #cutsceneList) do
		self.list[i+1] = {
			Name = cutsceneList[i].Name,
			Filename = cutsceneList[i].Filename,
			Description = cutsceneList[i].Description,
			isVisible = cutsceneList[i].isVisible,
			Index = i + 1
		}
		i = i + 1
	end
	
	--Only create entries if there are any to create
	if self.list[1] then
		self.visibleList = {}
		self:CreateEntries(self.list)
		if self.list[1].Name then
			self:SelectEntry(self.list[1])
		end
	end
	
end

function TechCutscenesController:ReloadList()

	local list_items_el = self.document:GetElementById("cutscene_list_ul")
	self:ClearEntries(list_items_el)
	self.SelectedEntry = nil
	self.visibleList = {}
	self.Counter = 0
	self:CreateEntries(self.list)
	self:SelectEntry(self.visibleList[1])

end

function TechCutscenesController:CreateEntryItem(entry, index)

	self.Counter = self.Counter + 1

	local li_el = self.document:CreateElement("li")

	li_el.inner_rml = "<div class=\"cutscenelist_name\">" .. entry.Name .. "</div>"
	li_el.id = entry.Filename

	li_el:SetClass("cutscenelist_element", true)
	li_el:SetClass("button_1", true)
	li_el:AddEventListener("click", function(_, _, _)
		self:SelectEntry(entry)
	end)
	self.visibleList[self.Counter] = entry
	entry.key = li_el.id
	
	self.visibleList[self.Counter].Index = self.Counter

	return li_el
end

function TechCutscenesController:CreateEntries(list)

	local list_names_el = self.document:GetElementById("cutscene_list_ul")
	
	self:ClearEntries(list_names_el)

	for i, v in pairs(list) do
		if self.show_all then
			list_names_el:AppendChild(self:CreateEntryItem(v, i))
		elseif v.isVisible == true then
			list_names_el:AppendChild(self:CreateEntryItem(v, i))
		end
	end
end

function TechCutscenesController:SelectEntry(entry)

	if entry.key ~= self.SelectedEntry then
		
		if self.SelectedEntry then
			local oldEntry = self.document:GetElementById(self.SelectedEntry)
			if oldEntry then oldEntry:SetPseudoClass("checked", false) end
		end
		
		local thisEntry = self.document:GetElementById(entry.key)
		self.SelectedEntry = entry.key
		self.SelectedIndex = entry.Index
		thisEntry:SetPseudoClass("checked", true)
		
		self.document:GetElementById("cutscene_desc").inner_rml = entry.Description
		
	end

end

function TechCutscenesController:ChangeTechState(state)

	if state == 1 then
		ba.postGameEvent(ba.GameEvents["GS_EVENT_TECH_MENU"])
	end
	if state == 2 then
		ba.postGameEvent(ba.GameEvents["GS_EVENT_SIMULATOR_ROOM"])
	end
	if state == 3 then
		--This is where we are already, so don't do anything
		--ba.postGameEvent(ba.GameEvents["GS_EVENT_GOTO_VIEW_CUTSCENES_SCREEN"])
	end
	if state == 4 then
		ba.postGameEvent(ba.GameEvents["GS_EVENT_CREDITS"])
	end
	
end

function TechCutscenesController:ClearEntries(parent)

	while parent:HasChildNodes() do
		parent:RemoveChild(parent.first_child)
	end

end

function TechCutscenesController:global_keydown(element, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
        event:StopPropagation()

        ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
    elseif event.parameters.key_identifier == rocket.key_identifier.S and event.parameters.ctrl_key == 1 and event.parameters.shift_key == 1 then
		self.show_all  = not self.show_all
		self:ReloadList()
	elseif event.parameters.key_identifier == rocket.key_identifier.UP and event.parameters.ctrl_key == 1 then
		self:ChangeTechState(2)
	elseif event.parameters.key_identifier == rocket.key_identifier.DOWN and event.parameters.ctrl_key == 1 then
		self:ChangeTechState(4)
	elseif event.parameters.key_identifier == rocket.key_identifier.TAB then
		--do nothing
	elseif event.parameters.key_identifier == rocket.key_identifier.UP and event.parameters.shift_key == 1 then
		self:ScrollList(self.document:GetElementById("cutscene_list"), 0)
	elseif event.parameters.key_identifier == rocket.key_identifier.DOWN and event.parameters.shift_key == 1 then
		self:ScrollList(self.document:GetElementById("cutscene_list"), 1)
	elseif event.parameters.key_identifier == rocket.key_identifier.UP then
		self:prev_pressed()
	elseif event.parameters.key_identifier == rocket.key_identifier.DOWN then
		self:next_pressed()
	elseif event.parameters.key_identifier == rocket.key_identifier.LEFT then
		--self:select_prev()
	elseif event.parameters.key_identifier == rocket.key_identifier.RIGHT then
		--self:select_next()
	elseif event.parameters.key_identifier == rocket.key_identifier.F1 then
		--self:help_clicked(element)
	elseif event.parameters.key_identifier == rocket.key_identifier.F2 then
		--self:options_button_clicked(element)
	end
end

function TechCutscenesController:global_keyup(element, event)
	if event.parameters.key_identifier == rocket.key_identifier.RETURN then
		self:play_pressed(element)
	end
end

function TechCutscenesController:ScrollList(element, direction)
	if direction == 0 then
		element.scroll_top = element.scroll_top - 15
	else
		element.scroll_top = element.scroll_top + 15
	end
end

function TechCutscenesController:prev_pressed(element)
	if self.SelectedEntry ~= nil then
		if self.SelectedIndex == 1 then
			ui.playElementSound(element, "click", "error")
		else
			self:SelectEntry(self.visibleList[self.SelectedIndex - 1])
		end
	end
end

function TechCutscenesController:next_pressed(element)
	if self.SelectedEntry ~= nil then
		local num = #self.visibleList
		
		if self.SelectedIndex == num then
			ui.playElementSound(element, "click", "error")
		else
			self:SelectEntry(self.visibleList[self.SelectedIndex + 1])
		end
	end
end

function TechCutscenesController:play_pressed(element)
	if self.SelectedEntry ~= nil then
		RocketUiSystem.cutscene = self.SelectedEntry
		RocketUiSystem:beginSubstate("Cutscene")
		self.document:Close()
	end
end

function TechCutscenesController:exit_pressed(element)
    ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
end

return TechCutscenesController
