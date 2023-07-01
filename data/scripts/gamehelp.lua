local class = require("class")

local GamehelpController = class()
local fontMultiplier = nil

function GamehelpController:init()
end

function GamehelpController:initialize(document)

    self.document = document
	
	---Load the desired font size from the save file
	if ScpuiOptionValues.Font_Multiplier then
		local fontChoice = ScpuiOptionValues.Font_Multiplier
		fontMultiplier = ScpuiOptionValues.Font_Multiplier
		self.document:GetElementById("main_background"):SetClass(("p1-" .. fontChoice), true)
	else
		self.document:GetElementById("main_background"):SetClass("p1-5", true)
		fontMultiplier = 5
	end
	
	if mn.isInMission() then
		ad.pauseMusic(-1, true)
		ad.pauseWeaponSounds(true)
	end
	
	ui.GameHelp.initGameHelp()
	
	self.numSections = #ui.GameHelp.Help_Sections
	self.sections = {}
	
	for i = 1, self.numSections do
		self.sections[i] = {
			Title = nil,
			Subtitle = nil,
			Header = nil,
			Keys = {},
			Texts = {}
		}
		self.sections[i].Title = ui.GameHelp.Help_Sections[i].Title
		self.sections[i].Subtitle = "Page " .. i.. " of " .. self.numSections
		self.sections[i].Header = ui.GameHelp.Help_Sections[i].Header
		self.sections[i].Keys = ui.GameHelp.Help_Sections[i].Keys
		self.sections[i].Texts = ui.GameHelp.Help_Sections[i].Texts
	end
	
	ui.GameHelp.closeGameHelp()
	
	self:ChangeSection(1)
	
end

function GamehelpController:ChangeSection(section)

	self.currentSection = section
	self:CreateEntries(section)
	self.document:GetElementById("gamehelp_title").inner_rml = self.sections[section].Title
	self.document:GetElementById("gamehelp_subtitle").inner_rml = self.sections[section].Subtitle
	self.document:GetElementById("gamehelp_header").inner_rml = self.sections[section].Header
	
end

function GamehelpController:CreateEntries(section)

	local list_el = self.document:GetElementById("list_keys_ul")

	self:ClearEntries(list_el)
	
	for i = 1, #self.sections[self.currentSection].Keys do
		local line = self.sections[self.currentSection].Keys[i]
		local li_el = self.document:CreateElement("li")
		li_el.inner_rml = line
		list_el:AppendChild(li_el)
	end
	
	local list_el = self.document:GetElementById("list_texts_ul")

	self:ClearEntries(list_el)
	
	for i = 1, #self.sections[self.currentSection].Texts do
		local line = self.sections[self.currentSection].Texts[i]
		local li_el = self.document:CreateElement("li")
		li_el.inner_rml = line
		list_el:AppendChild(li_el)
	end
end

function GamehelpController:ClearEntries(parent)

	while parent:HasChildNodes() do
		parent:RemoveChild(parent.first_child)
	end

end

function GamehelpController:DecrementSection(element)

    if self.currentSection == 1 then
		self:ChangeSection(self.numSections)
	else
		self:ChangeSection(self.currentSection - 1)
	end

end

function GamehelpController:IncrementSection(element)

    if self.currentSection == self.numSections then
		self:ChangeSection(1)
	else
		self:ChangeSection(self.currentSection + 1)
	end

end

function GamehelpController:Exit(element)

    ui.playElementSound(element, "click", "success")
	if mn.isInMission() then
		ad.pauseMusic(-1, false)
		ad.pauseWeaponSounds(false)
		ui.PauseScreen.closePause()
	end
	ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])

end

function GamehelpController:global_keydown(_, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
        event:StopPropagation()
		if mn.isInMission() then
			ad.pauseMusic(-1, false)
			ad.pauseWeaponSounds(false)
			ui.PauseScreen.closePause()
		end
		ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])
    end
end

return GamehelpController
