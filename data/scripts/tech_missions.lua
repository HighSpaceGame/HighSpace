local dialogs = require("dialogs")
local class = require("class")
local async_util = require("async_util")
local utils = require("utils")

local TechMissionsController = class()

function TechMissionsController:init()
	self.help_shown = false
	self.show_all = false
	self.Counter = 0
	self.help_shown = false
end

function TechMissionsController:initialize(document)
    self.document = document
    self.elements = {}
    self.section = 1

	---Load the desired font size from the save file
	if ScpuiOptionValues.Font_Multiplier then
		local fontChoice = ScpuiOptionValues.Font_Multiplier
		self.document:GetElementById("main_background"):SetClass(("p1-" .. fontChoice), true)
	else
		self.document:GetElementById("main_background"):SetClass("p1-5", true)
	end
	
	ui.TechRoom.buildMissionList()
	
	self:GetCampaign()
	
	self.document:GetElementById("campaign_title").inner_rml = self.campaignName
	self.document:GetElementById("campaign_file").inner_rml = self.campaignFilename
	
	self.document:GetElementById("data_btn"):SetPseudoClass("checked", false)
	self.document:GetElementById("mission_btn"):SetPseudoClass("checked", true)
	self.document:GetElementById("cutscene_btn"):SetPseudoClass("checked", false)
	self.document:GetElementById("credits_btn"):SetPseudoClass("checked", false)
	
	self.SelectedEntry = nil
	
	--Check for last loaded section
	local newSection = nil
	if ScpuiSystem.missionSection ~= nil then
		newSection = ScpuiSystem.missionSection
	else
		local uidata = ScpuiOptionValues.simRoomChoice
		if uidata == nil then
			newSection = 1
		else
			newSection = uidata
		end
	end
	
	self.SelectedSection = nil
	self:ChangeSection(newSection)
	
end

function TechMissionsController:ChangeTechState(state)

	if state == 1 then
		ba.postGameEvent(ba.GameEvents["GS_EVENT_TECH_MENU"])
	end
	if state == 2 then
		--This is where we are already, so don't do anything
		--ba.postGameEvent(ba.GameEvents["GS_EVENT_SIMULATOR_ROOM"])
	end
	if state == 3 then
		ba.postGameEvent(ba.GameEvents["GS_EVENT_GOTO_VIEW_CUTSCENES_SCREEN"])
	end
	if state == 4 then
		ba.postGameEvent(ba.GameEvents["GS_EVENT_CREDITS"])
	end
	
end

function TechMissionsController:ReloadList()

	local list_items_el = self.document:GetElementById("list_item_names_ul")
	self:ClearEntries(list_items_el)
	self:ClearData()
	self.SelectedEntry = nil
	self.visibleList = {}
	self.Counter = 0
	self:CreateEntries(self.currentList)
	if #self.visibleList > 0 then
		self:SelectEntry(self.visibleList[1])
	end

end

function TechMissionsController:ChangeSection(section)

	self.sectionIndex = section
	ScpuiSystem.missionSection = section

	if section == 1 then 
		section = "single"
	elseif section == 2 then
		section = "campaign"
	else
		section = "single"
		self.sectionIndex = 1
		ScpuiSystem.missionSection = 1
	end
	
	--save the choice to the player file
	ScpuiOptionValues.simRoomChoice = self.sectionIndex
	utils.saveOptionsToFile(ScpuiOptionValues)
	
	self.show_all = false
	self.Counter = 0

	if section ~= self.SelectedSection then
	
		local missionList = nil
		self.currentList = {}
	
		if section == "single" then
			self.document:GetElementById("campaign_name_wrapper"):SetClass("hidden", true)
			missionList = ui.TechRoom.SingleMissions
			local i = 0
			while (i ~= #missionList) do
				self.currentList[i+1] = {
					Name = missionList[i].Name,
					Filename = missionList[i].Filename,
					Description = missionList[i].Description,
					Author = missionList[i].Author,
					isVisible = true
				}
				i = i + 1
			end
		elseif section == "campaign" then
			self.document:GetElementById("campaign_name_wrapper"):SetClass("hidden", false)
			missionList = ui.TechRoom.CampaignMissions
			local i = 0
			while (i ~= #missionList) do
				self.currentList[i+1] = {
					Name = missionList[i].Name,
					Filename = missionList[i].Filename,
					Description = missionList[i].Description,
					Author = missionList[i].Author,
					isVisible = missionList[i].isVisible
				}
				i = i + 1
			end
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
		
		--Only create entries if there are any to create
		if self.currentList[1] then
			self.visibleList = {}
			self:CreateEntries(self.currentList)
			--Only select an entry if there is one available to select
			if #self.visibleList > 0 then
				self:SelectEntry(self.visibleList[1])
			end
		else
			local list_names_el = self.document:GetElementById("list_item_names_ul")
			self:ClearEntries(list_names_el)
			self:ClearData()
		end

		local newbullet = self.document:GetElementById(self.SelectedSection.."_btn")
		newbullet:SetPseudoClass("checked", true)
		
	end
	
end

function TechMissionsController:ScrollEntry(element)
	if self.scrollingEl == element then
		if self.scrollingEl.scroll_left < math.floor(self.scrollingEl.scroll_width -  self.scrollingEl.client_width) then
			if self.scrollTimer == nil then
				self.scrollTimer = 15
			elseif self.scrollTimer > 0 then
				self.scrollTimer = self.scrollTimer - 1
			else
				self.scrollingEl.scroll_left = self.scrollingEl.scroll_left + 0.5
				self.scrollTimer = -1
			end
		else
			if self.scrollTimer ~= nil then
				if self.scrollTimer == -1 then
					self.scrollTimer = 50
				elseif self.scrollTimer > 0 then
					self.scrollTimer = self.scrollTimer - 1
				else
					self.scrollingEl.scroll_left = 0
					self.scrollTimer = nil
				end
			end
		end
		
		async.run(function()
			async.await(async_util.wait_for(0.05))
			self:ScrollEntry(element)
		end, async.OnFrameExecutor)
	end
end

function TechMissionsController:StartScrollEntry(element)
	if element ~= nil and element.inner_rml ~= self.scrollingEl then
		if self.scrollingEl ~= nil then
			self.scrollingEl.scroll_left = 0
		end
		self.scrollTimer = nil
		self.scrollingEl = element
		self:ScrollEntry(element)
	end
end

function TechMissionsController:ResetEntry(element)
	if element ~= nil then
		self.scrollTimer = nil
		self.scrollingEl = nil
		element.scroll_left = 0
	end
end

function TechMissionsController:CreateEntryItem(entry, index)

	self.Counter = self.Counter + 1

	local li_el = self.document:CreateElement("li")

	li_el.inner_rml = "<div class=\"missionlist_name\">" .. entry.Name .. "</div><div class=\"missionlist_author\">" .. entry.Author .. "</div><div class=\"missionlist_filename\">" .. entry.Filename .. "</div><div class=\"missionlist_description\">" .. entry.Description .. "</div>"
	li_el.id = entry.Filename

	li_el:SetClass("missionlist_element", true)
	li_el:SetClass("button_1", true)
	li_el:AddEventListener("click", function(_, _, _)
		self:SelectEntry(entry)
	end)
	li_el:AddEventListener("mouseover", function(_, _, _)
		self:StartScrollEntry(li_el.first_child.next_sibling.next_sibling.next_sibling)
	end)
	li_el:AddEventListener("mouseout", function(_, _, _)
		self:ResetEntry(li_el.first_child.next_sibling.next_sibling.next_sibling)
	end)
	self.visibleList[self.Counter] = entry
	entry.key = li_el.id
	
	self.visibleList[self.Counter].Index = self.Counter

	return li_el
end

function TechMissionsController:CreateEntries(list)

	local list_names_el = self.document:GetElementById("list_item_names_ul")

	self:ClearEntries(list_names_el)

	for i, v in pairs(list) do
		if self.show_all then
			list_names_el:AppendChild(self:CreateEntryItem(v, i))
		elseif v.isVisible == true then
			list_names_el:AppendChild(self:CreateEntryItem(v, i))
		end
	end
end

function TechMissionsController:ClearEntry()

	self.document:GetElementById(self.SelectedEntry):SetPseudoClass("checked", false)
	self.SelectedEntry = nil

end

function TechMissionsController:ClearData()

	--We have nothing to clear here!
	
end

function TechMissionsController:ClearEntries(parent)

	while parent:HasChildNodes() do
		parent:RemoveChild(parent.first_child)
	end

end

function TechMissionsController:SelectEntry(entry)

	if entry.key ~= self.SelectedEntry then
	
		self.SelectedIndex = entry.Index
		
		if self.SelectedEntry then
			local oldEntry = self.document:GetElementById(self.SelectedEntry)
			if oldEntry then oldEntry:SetPseudoClass("checked", false) end
		end
		
		local thisEntry = self.document:GetElementById(entry.key)
		self.SelectedEntry = entry.key
		thisEntry:SetPseudoClass("checked", true)
		
	end

end

function TechMissionsController:GetCampaign()

	ui.CampaignMenu.loadCampaignList();

    local names, fileNames, descriptions = ui.CampaignMenu.getCampaignList()

    local currentCampaignFile = ba.getCurrentPlayer():getCampaignFilename()
    local selectedCampaign = nil

    self.names = names
    self.descriptions = {}
    self.fileNames = {}
    for i, v in ipairs(names) do
        self.descriptions[v] = descriptions[i]
        self.fileNames[v] = fileNames[i]

        if fileNames[i] == currentCampaignFile then
            selectedCampaign = v
        end
    end
	
	self.campaignFilename = currentCampaignFile .. ".fc2"
	self.campaignName = selectedCampaign
	
end

function TechMissionsController:global_keydown(element, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
        event:StopPropagation()

        ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
    elseif event.parameters.key_identifier == rocket.key_identifier.S and event.parameters.ctrl_key == 1 and event.parameters.shift_key == 1 then
		self.show_all = not self.show_all
		self:ReloadList()
	elseif event.parameters.key_identifier == rocket.key_identifier.UP and event.parameters.ctrl_key == 1 then
		self:ChangeTechState(1)
	elseif event.parameters.key_identifier == rocket.key_identifier.DOWN and event.parameters.ctrl_key == 1 then
		self:ChangeTechState(3)
	elseif event.parameters.key_identifier == rocket.key_identifier.TAB then
		local newSection = nil
		if self.sectionIndex == 2 then
			newSection = 1
		else
			newSection = 2
		end
		self:ChangeSection(newSection)
	elseif event.parameters.key_identifier == rocket.key_identifier.UP and event.parameters.shift_key == 1 then
		self:ScrollList(self.document:GetElementById("mission_list"), 0)
	elseif event.parameters.key_identifier == rocket.key_identifier.DOWN and event.parameters.shift_key == 1 then
		self:ScrollList(self.document:GetElementById("mission_list"), 1)
	elseif event.parameters.key_identifier == rocket.key_identifier.UP then
		self:select_prev()
	elseif event.parameters.key_identifier == rocket.key_identifier.DOWN then
		self:select_next()
	elseif event.parameters.key_identifier == rocket.key_identifier.LEFT then
		--self:select_prev()
	elseif event.parameters.key_identifier == rocket.key_identifier.RIGHT then
		--self:select_next()
	elseif event.parameters.key_identifier == rocket.key_identifier.RETURN then
		self:commit_pressed(element)
	elseif event.parameters.key_identifier == rocket.key_identifier.F1 then
		self:help_clicked(element)
	elseif event.parameters.key_identifier == rocket.key_identifier.F2 then
		self:options_button_clicked(element)
	end
end

function TechMissionsController:ScrollList(element, direction)
	if direction == 0 then
		element.scroll_top = element.scroll_top - 15
	else
		element.scroll_top = element.scroll_top + 15
	end
end

function TechMissionsController:select_next()
    local num = #self.visibleList
	
	if self.SelectedIndex == num then
		ui.playElementSound(element, "click", "error")
	else
		self:SelectEntry(self.visibleList[self.SelectedIndex + 1])
	end
end

function TechMissionsController:select_prev()	
	if self.SelectedIndex == 1 then
		ui.playElementSound(element, "click", "error")
	else
		self:SelectEntry(self.visibleList[self.SelectedIndex - 1])
	end
end

function TechMissionsController:commit_pressed(element)
	if self.SelectedEntry then
		mn.startMission(self.SelectedEntry)
	end
end

function TechMissionsController:options_button_clicked(element)
    ba.postGameEvent(ba.GameEvents["GS_EVENT_OPTIONS_MENU"])
end

function TechMissionsController:help_clicked(element)
    self.help_shown  = not self.help_shown

    local help_texts = self.document:GetElementsByClassName("tooltip")
    for _, v in ipairs(help_texts) do
        v:SetPseudoClass("shown", self.help_shown)
    end
end

return TechMissionsController
