local dialogs = require("dialogs")
local class = require("class")

local TechDatabaseController = class()

local modelDraw = nil

function TechDatabaseController:init()
	self.show_all = false
	modelDraw = {}
	self.Counter = 0
end

--Iterate over all the ships, weapons, and intel but only grab the necessary data
function TechDatabaseController:LoadData()

	local list = nil
	
	self.ships = {}
	self.weapons = {}
	self.intel = {}
	
	list = tb.ShipClasses
	
	i = 1
	while (i ~= #list + 1) do
		self.ships[i] = {
			Name = tostring(list[i]),
			Description = list[i].TechDescription,
			Visibility = list[i].InTechDatabase
		}
		i = i + 1
	end
	
	list = tb.WeaponClasses
	
	i = 1
	while (i ~= #list + 1) do
		self.weapons[i] = {
			Name = tostring(list[i]),
			Description = list[i].TechDescription,
			Anim = list[i].TechAnimationFilename,
			Visibility = list[i].InTechDatabase
		}
		i = i + 1
	end
	
	list = tb.IntelEntries
	
	i = 1
	while (i ~= #list + 1) do
		self.intel[i] = {
			Name = tostring(list[i]),
			Description = list[i].Description,
			Anim = list[i].AnimFilename,
			Visibility = list[i].InTechDatabase
		}
		i = i + 1
	end

end

function TechDatabaseController:initialize(document)
    self.document = document
    self.elements = {}
    self.section = 1

	---Load the desired font size from the save file
	if modOptionValues.Font_Multiplier then
		local fontChoice = modOptionValues.Font_Multiplier
		self.document:GetElementById("main_background"):SetClass(("p1-" .. fontChoice), true)
	else
		self.document:GetElementById("main_background"):SetClass("p1-5", true)
	end
	
	self.document:GetElementById("data_btn"):SetPseudoClass("checked", true)
	self.document:GetElementById("mission_btn"):SetPseudoClass("checked", false)
	self.document:GetElementById("cutscene_btn"):SetPseudoClass("checked", false)
	self.document:GetElementById("credits_btn"):SetPseudoClass("checked", false)
	
	--Get all the table data fresh each time in case there are changes
	self:LoadData()
	
	self.SelectedEntry = nil
	
	self.SelectedSection = nil
	self:ChangeSection(1)
	
end

function TechDatabaseController:ReloadList()

	local list_items_el = self.document:GetElementById("list_items_ul")
	self:ClearEntries(list_items_el)
	self:ClearData()
	self.SelectedEntry = nil
	self.visibleList = {}
	self.Counter = 0
	self:CreateEntries(self.currentList)
	self:SelectEntry(self.visibleList[1])

end

function TechDatabaseController:ChangeTechState(state)

	if state == 1 then
		--This is where we are already, so don't do anything
		--ba.postGameEvent(ba.GameEvents["GS_EVENT_TECH_MENU"])
	end
	if state == 2 then
		ba.postGameEvent(ba.GameEvents["GS_EVENT_SIMULATOR_ROOM"])
	end
	if state == 3 then
		ba.postGameEvent(ba.GameEvents["GS_EVENT_GOTO_VIEW_CUTSCENES_SCREEN"])
	end
	if state == 4 then
		ba.postGameEvent(ba.GameEvents["GS_EVENT_CREDITS"])
	end
	
end

function TechDatabaseController:ChangeSection(section)

	self.sectionIndex = section
	
	if section == 1 then section = "ships" end
	if section == 2 then section = "weapons" end
	if section == 3 then section = "intel" end
	
	self.show_all = false
	self.Counter = 0

	if section ~= self.SelectedSection then
	
		self.currentList = {}
	
		if section == "ships" then
			self.currentList = self.ships
		elseif section == "weapons" then
			self.currentList = self.weapons
		elseif section == "intel" then
			self.currentList = self.intel
		end
		
		if self.SelectedEntry then
			self:ClearEntry()
		end
		
		--If we had an old section on, remove the active class
		if self.SelectedSection then
			local oldbullet = self.document:GetElementById(self.SelectedSection.."_btn")
			oldbullet:SetPseudoClass("checked", false)
		end
		
		self.SelectedSection = section
		modelDraw.section = section
		
		--Only create entries if there are any to create
		if self.currentList[1] then
			self.visibleList = {}
			self:CreateEntries(self.currentList)
			self:SelectEntry(self.visibleList[1])
		else
			local list_items_el = self.document:GetElementById("list_items_ul")
			self:ClearEntries(list_items_el)
			self:ClearData()
		end

		local newbullet = self.document:GetElementById(self.SelectedSection.."_btn")
		newbullet:SetPseudoClass("checked", true)
		
	end
	
end

function TechDatabaseController:CreateEntryItem(entry, index)

	self.Counter = self.Counter + 1
	
	if self.show_all then
		--ba.warning(self.currentList[self.Counter].Name)
	end

	local li_el = self.document:CreateElement("li")

	li_el.inner_rml = "<span>" .. entry.Name .. "</span>"
	li_el.id = entry.Name

	li_el:SetClass("list_element", true)
	li_el:SetClass("button_1", true)
	li_el:AddEventListener("click", function(_, _, _)
		self:SelectEntry(entry)
	end)
	self.visibleList[self.Counter] = entry
	entry.key = li_el.id
	
	self.visibleList[self.Counter].Index = self.Counter

	return li_el
end

function TechDatabaseController:CreateEntries(list)

	local list_names_el = self.document:GetElementById("list_items_ul")

	self:ClearEntries(list_names_el)

	for i, v in pairs(list) do
		if self.show_all then
			list_names_el:AppendChild(self:CreateEntryItem(v, i))
		elseif v.Visibility then
			list_names_el:AppendChild(self:CreateEntryItem(v, i))
		end
	end
end

function TechDatabaseController:SelectEntry(entry)

	if entry.key ~= self.SelectedEntry then
		self.document:GetElementById(entry.key):SetPseudoClass("checked", true)

		self.SelectedIndex = entry.Index

		modelDraw.Rot = 40
		
		local aniWrapper = self.document:GetElementById("tech_view")
		aniWrapper:RemoveChild(aniWrapper.first_child)
	
		if self.SelectedEntry then
			local oldEntry = self.document:GetElementById(self.SelectedEntry)
			if oldEntry then oldEntry:SetPseudoClass("checked", false) end
		end
		
		local thisEntry = self.document:GetElementById(entry.key)
		self.SelectedEntry = entry.key
		thisEntry:SetPseudoClass("checked", true)
		
		--Decide if item is a weapon or a ship
		if self.SelectedSection == "ships" then
			self.document:GetElementById("tech_desc").inner_rml = entry.Description
			
			modelDraw.class = entry.Name
			modelDraw.element = self.document:GetElementById("tech_view")

		elseif self.SelectedSection == "weapons" then			
			self.document:GetElementById("tech_desc").inner_rml = entry.Description
			
			if entry.Anim ~= "" then
				modelDraw.class = nil

				local aniEl = self.document:CreateElement("ani")
				aniEl:SetAttribute("src", entry.Anim)
				aniEl:SetClass("anim", true)
				aniWrapper:ReplaceChild(aniEl, aniWrapper.first_child)
			else --If we don't have an anim, then draw the tech model
				modelDraw.class = entry.Name
				modelDraw.element = self.document:GetElementById("tech_view")
			end
		elseif self.SelectedSection == "intel" then			
			self.document:GetElementById("tech_desc").inner_rml = entry.Description
			
			if entry.Anim then
				modelDraw.class = nil

				local aniEl = self.document:CreateElement("ani")
				aniEl:SetAttribute("src", entry.Anim)
				aniEl:SetClass("anim", true)
				aniWrapper:ReplaceChild(aniEl, aniWrapper.first_child)
			else
				--Do nothing because we have nothing to do!
			end
		end

	end	


end

function TechDatabaseController:DrawModel()

	if modelDraw.class and ba.getCurrentGameState().Name == "GS_STATE_TECH_MENU" then  --Haaaaaaacks

		local thisItem = nil
		if modelDraw.section == "ships" then
			thisItem = tb.ShipClasses[modelDraw.class]
		elseif modelDraw.section == "weapons" then
			thisItem = tb.WeaponClasses[modelDraw.class]
		end
		
		modelDraw.Rot = modelDraw.Rot + (7 * ba.getRealFrametime())

		if modelDraw.Rot >= 100 then
			modelDraw.Rot = modelDraw.Rot - 100
		end
		
		modelView = modelDraw.element
						
		local modelLeft = modelView.offset_left + modelView.parent_node.offset_left + modelView.parent_node.parent_node.offset_left --This is pretty messy, but it's functional
		local modelTop = modelView.parent_node.offset_top + modelView.parent_node.parent_node.offset_top - 7 --Does not include modelView.offset_top because that element's padding is set for anims also subtracts 7px for funsies
		local modelWidth = modelView.offset_width
		local modelHeight = modelView.offset_height
		
		local test = thisItem:renderTechModel(modelLeft, modelTop, modelLeft + modelWidth, modelTop + modelHeight, modelDraw.Rot, -15, 0, 1.1)
		
	end

end

function TechDatabaseController:ClearEntry()

	self.document:GetElementById(self.SelectedEntry):SetPseudoClass("checked", false)
	self.SelectedEntry = nil

end

function TechDatabaseController:ClearData()

	modelDraw.class = nil
	local aniWrapper = self.document:GetElementById("tech_view")
	aniWrapper:RemoveChild(aniWrapper.first_child)
	self.document:GetElementById("tech_desc").inner_rml = "<p></p>"
	
end

function TechDatabaseController:ClearEntries(parent)

	while parent:HasChildNodes() do
		parent:RemoveChild(parent.first_child)
	end

end

function TechDatabaseController:global_keydown(element, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
        event:StopPropagation()

        ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
    elseif event.parameters.key_identifier == rocket.key_identifier.S and event.parameters.ctrl_key == 1 and event.parameters.shift_key == 1 then
		self.show_all  = not self.show_all
		self:ReloadList()
	elseif event.parameters.key_identifier == rocket.key_identifier.UP and event.parameters.ctrl_key == 1 then
		self:ChangeTechState(4)
	elseif event.parameters.key_identifier == rocket.key_identifier.DOWN and event.parameters.ctrl_key == 1 then
		self:ChangeTechState(2)
	elseif event.parameters.key_identifier == rocket.key_identifier.TAB then
		local newSection = self.sectionIndex + 1
		if newSection == 4 then
			newSection = 1
		end
		self:ChangeSection(newSection)
	elseif event.parameters.key_identifier == rocket.key_identifier.UP and event.parameters.shift_key == 1 then
		self:ScrollList(self.document:GetElementById("tech_list"), 0)
	elseif event.parameters.key_identifier == rocket.key_identifier.DOWN and event.parameters.shift_key == 1 then
		self:ScrollList(self.document:GetElementById("tech_list"), 1)
	elseif event.parameters.key_identifier == rocket.key_identifier.UP then
		self:ScrollText(self.document:GetElementById("tech_desc"), 0)
	elseif event.parameters.key_identifier == rocket.key_identifier.DOWN then
		self:ScrollText(self.document:GetElementById("tech_desc"), 1)
	elseif event.parameters.key_identifier == rocket.key_identifier.LEFT then
		self:select_prev()
	elseif event.parameters.key_identifier == rocket.key_identifier.RIGHT then
		self:select_next()
	elseif event.parameters.key_identifier == rocket.key_identifier.RETURN then
		--self:commit_pressed(element)
	elseif event.parameters.key_identifier == rocket.key_identifier.F1 then
		self:help_clicked(element)
	elseif event.parameters.key_identifier == rocket.key_identifier.F2 then
		self:options_button_clicked(element)
	end
end

function TechDatabaseController:ScrollList(element, direction)
	if direction == 0 then
		element.scroll_top = element.scroll_top - 15
	else
		element.scroll_top = element.scroll_top + 15
	end
end

function TechDatabaseController:ScrollText(element, direction)
	if direction == 0 then
		element.scroll_top = (element.scroll_top - 5)
	else
		element.scroll_top = (element.scroll_top + 5)
	end
end

function TechDatabaseController:select_next()
    local num = #self.visibleList
	
	if self.SelectedIndex == num then
		ui.playElementSound(element, "click", "error")
	else
		self:SelectEntry(self.visibleList[self.SelectedIndex + 1])
	end
end

function TechDatabaseController:select_prev()	
	if self.SelectedIndex == 1 then
		ui.playElementSound(element, "click", "error")
	else
		self:SelectEntry(self.visibleList[self.SelectedIndex - 1])
	end
end

function TechDatabaseController:commit_pressed(element)
    ui.playElementSound(element, "click", "success")
    ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
end

function TechDatabaseController:options_button_clicked(element)
    ui.playElementSound(element, "click", "success")
    ba.postGameEvent(ba.GameEvents["GS_EVENT_OPTIONS_MENU"])
end

function TechDatabaseController:help_clicked(element)
    ui.playElementSound(element, "click", "success")
    --TODO
end

engine.addHook("On Frame", function()
	if ba.getCurrentGameState().Name == "GS_STATE_TECH_MENU" then
		TechDatabaseController:DrawModel()
	end
end, {}, function()
	return false
end)

return TechDatabaseController
