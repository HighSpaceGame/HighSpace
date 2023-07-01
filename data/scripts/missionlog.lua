local class = require("class")

local MissionlogController = class()
local fontMultiplier = nil

function MissionlogController:init()
end

function MissionlogController:initialize(document)

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
	
	local mTime = mn.getMissionTime()
	local hours = math.floor(mTime/3600)
	local minutes = math.floor(math.fmod(mTime,3600)/60)
	local seconds = math.floor(math.fmod(mTime,60))
	
	self.document:GetElementById("gametime").inner_rml = string.format("%02d:%02d:%02d", hours,minutes,seconds) .. "  Current Time"
	
	ui.MissionLog.initMissionLog()
	
	self:initMissionLog()
	self:initMessageLog()
	self:initGoalsLog()
	
	ui.MissionLog.closeMissionLog()
	
	self:ChangeSection(ScpuiSystem.logSection)
	
end

function MissionlogController:initMissionLog()

	self.logTimestamps = {}
	self.logSubjects = {}
	self.logDescriptions = {}
	
	for logs = 1, #ui.MissionLog.Log_Entries do
		local entry = ui.MissionLog.Log_Entries[logs]
		
		local segment = ""
		
		for segments = 1, #entry.SegmentTexts do
			segment = segment .. "<span style=\"color:rgba(" .. entry.SegmentColors[segments].Red .. "," .. entry.SegmentColors[segments].Green .. "," .. entry.SegmentColors[segments].Blue .. "," .. entry.SegmentColors[segments].Alpha .. ");\">" .. entry.SegmentTexts[segments] .. " </span>"
		end
		
		local subject = "<span style=\"color:rgba(" .. entry.ObjectiveColor.Red .. "," .. entry.ObjectiveColor.Green .. "," .. entry.ObjectiveColor.Blue .. "," .. entry.ObjectiveColor.Alpha .. ");\">" .. entry.ObjectiveText .. " </span>"
		
		self.logTimestamps[logs] = entry.Timestamp
		self.logSubjects[logs] = subject
		self.logDescriptions[logs] = segment
	end
end

function MissionlogController:initMessageLog()

	self.messageTimestamps = {}
	self.messageTexts = {}
	
	for logs = 1, #ui.MissionLog.Log_Messages do
		local entry = ui.MissionLog.Log_Messages[logs]
		
		local textString = entry.Text .. ":"
		local textElements = {}
		--ba.warning(textString)
		local count = 1
		for i in string.gmatch(textString, "(.-):") do
			textElements[count] = i
			count = count + 1
		end
		
		--If element 2 is nil then we didn't actually split any text which means it's
		--special message that doesn't need any underlining.
		if textElements[2] ~= nil then
			textString = "<span class=\"underline\">" .. textElements[1] .. ":</span>" .. textElements[2]
		end
		
		local text = "<span style=\"color:rgba(" .. entry.Color.Red .. "," .. entry.Color.Green .. "," .. entry.Color.Blue .. "," .. entry.Color.Alpha .. ");\">" .. textString .. " </span>"
		
		self.messageTimestamps[logs] = entry.Timestamp
		self.messageTexts[logs] = text
	end
end

function MissionlogController:initGoalsLog()

	goals = ui.Briefing.Objectives
	local incompleteBulletHTML = "<div id=\"goalsdot_img_incomplete\" class=\"goalsdot brightblue\"><img src=\"goal-incomplete.png\" class=\"psuedo_img\"></img></div>"
	local completeBulletHTML = "<div id=\"goalsdot_img_complete\" class=\"goalsdot\"><img src=\"goal-complete.png\" class=\"psuedo_img\"></img></div>"
	local failedBulletHTML = "<div id=\"goalsdot_img_failed\" class=\"goalsdot\"><img src=\"goal-failed.png\" class=\"psuedo_img\"></img></div>"
	local primaryWrapper = self.document:GetElementById("primary_goal_list")
	local primaryText = ""
	local secondaryWrapper = self.document:GetElementById("secondary_goal_list")
	local secondaryText = ""
	local bonusWrapper = self.document:GetElementById("bonus_goal_list")
	local bonusText = ""
	for i = 1, #goals do
		goal = goals[i]
		if goal.isGoalValid and goal.Message ~= "" then
			local status = goal.isGoalSatisfied
			local bulletHTML = nil
			
			if status == 0 then
				bulletHTML = failedBulletHTML
			elseif status == 1 then
				bulletHTML = completeBulletHTML
			else
				bulletHTML = incompleteBulletHTML
			end
			
			if goal.Type == "primary" then
				local text = "<div class=\"goal\">" .. bulletHTML .. goal.Message .. "<br></br></div>"
				primaryText = primaryText .. text
			end
			if goal.Type == "secondary" then
				local text = bulletHTML .. goal.Message .. "<br></br></div>"
				secondaryText = "<div class=\"goal\">" .. secondaryText .. text
			end
			if goal.Type == "bonus" then
				local text = bulletHTML .. goal.Message .. "<br></br></div>"
				bonusText = "<div class=\"goal\">" .. bonusText .. text
				
				--unhide bonus goals if they are completed
				if status == 1 then
					self.unhideBonus = true
				end
			end
		end
	end
	
	primaryWrapper.inner_rml = primaryText
	secondaryWrapper.inner_rml = secondaryText
	bonusWrapper.inner_rml = bonusText
	
	--Reset these for the goals key
	local incompleteBulletHTML = "<div id=\"goalsdot_img_incomplete\" class=\"goalsdot_key brightblue\"><img src=\"goal-incomplete.png\" class=\"psuedo_img\"></img></div>"
	local completeBulletHTML = "<div id=\"goalsdot_img_complete\" class=\"goalsdot_key\"><img src=\"goal-complete.png\" class=\"psuedo_img\"></img></div>"
	local failedBulletHTML = "<div id=\"goalsdot_img_failed\" class=\"goalsdot_key\"><img src=\"goal-failed.png\" class=\"psuedo_img\"></img></div>"
	
	self.document:GetElementById("goal_complete").inner_rml = completeBulletHTML .. "   Complete"
	self.document:GetElementById("goal_incomplete").inner_rml = incompleteBulletHTML .. "   Incomplete"
	self.document:GetElementById("goal_failed").inner_rml = failedBulletHTML .. "   Failed"
	
	self.document:GetElementById("briefing_goals"):SetClass("hidden", true)
	self.document:GetElementById("goal_key"):SetClass("hidden", true)
	self.document:GetElementById("bonus_goals"):SetClass("hidden", true)

end

function MissionlogController:ChangeSection(section)
	
	local changeSection = false
	
	if self.currentSection == nil then
		changeSection = true
	elseif self.currentSection ~= section then
		changeSection = true
	end
	
	if changeSection then
	
		ui.playElementSound(element, "click", "success")
	
		--first we clean up
		if self.currentSection == 1 then
			self:CleanupGoalsLog()
			self.document:GetElementById("objectives_btn"):SetPseudoClass("checked", false)
		end
		if self.currentSection == 2 then
			self:CleanupMessageLog()
			self.document:GetElementById("messages_btn"):SetPseudoClass("checked", false)
		end
		if self.currentSection == 3 then
			self:CleanupMissionLog()
			self.document:GetElementById("events_btn"):SetPseudoClass("checked", false)
		end

		--set the section
		self.currentSection = section
		ScpuiSystem.logSection = section

		if section == 1 then
			self:CreateGoalsLog()
			self.document:GetElementById("objectives_btn"):SetPseudoClass("checked", true)
		end

		if section == 2 then
			self:CreateMessageLog()
			self.document:GetElementById("messages_btn"):SetPseudoClass("checked", true)
		end

		if section == 3 then
			self:CreateMissionLog()
			self.document:GetElementById("events_btn"):SetPseudoClass("checked", true)
		end
		
	end
	
end

function MissionlogController:CreateMissionLog()

	local parent_el = self.document:GetElementById("log_text_wrapper")
	
	--create the list container
	local list_el = self.document:CreateElement("ul")
	list_el.id = "list_entries"
	parent_el:AppendChild(list_el)
	
	for i = 1, #self.logTimestamps do
		
		--create the list item
		local item_el = self.document:CreateElement("li")
		list_el:AppendChild(item_el)
		
		--create the time div
		local entry_el = self.document:CreateElement("div")
		entry_el.id = "list_times_ul"
		
		--fill the time div with text
		local line = self.logTimestamps[i]
		entry_el.inner_rml = line
		item_el:AppendChild(entry_el)
		
		--create the subject div
		local entry_el = self.document:CreateElement("div")
		entry_el.id = "list_subjects_ul"
		
		--fill the subject div with text
		local line = self.logSubjects[i]
		entry_el.inner_rml = line
		item_el:AppendChild(entry_el)
		
		--create the description div
		local entry_el = self.document:CreateElement("div")
		entry_el.id = "list_descriptions_ul"
		
		--fill the description div with text
		local line = self.logDescriptions[i]
		entry_el.inner_rml = line
		item_el:AppendChild(entry_el)
	end
	
	--now scroll to the bottom by default
	parent_el.scroll_top = parent_el.scroll_height
end

function MissionlogController:CreateMessageLog()

	local parent_el = self.document:GetElementById("log_text_wrapper")
	
	--create the list container
	local list_el = self.document:CreateElement("ul")
	list_el.id = "list_entries"
	parent_el:AppendChild(list_el)

	for i = 1, #self.messageTexts do
	
		--create the list item
		local item_el = self.document:CreateElement("li")
		list_el:AppendChild(item_el)
	
		--create the time div
		local entry_el = self.document:CreateElement("div")
		entry_el.id = "list_times_ul"

		--fill the time div with text
		local line = self.messageTimestamps[i]
		entry_el.inner_rml = line
		item_el:AppendChild(entry_el)

		--create the message div
		local entry_el = self.document:CreateElement("div")
		entry_el.id = "list_messages_ul"
		
		--fill the message div with text
		local line = self.messageTexts[i]
		entry_el.inner_rml = line
		item_el:AppendChild(entry_el)
	end

	--now scroll to the bottom by default
	parent_el.scroll_top = parent_el.scroll_height
end

function MissionlogController:CreateGoalsLog()

	self.document:GetElementById("briefing_goals"):SetClass("hidden", false)
	self.document:GetElementById("goal_key"):SetClass("hidden", false)
	
	if self.unhideBonus then
		self.document:GetElementById("bonus_goals"):SetClass("hidden", false)
	end
	
end

function MissionlogController:CleanupMissionLog()

	local parent_el = self.document:GetElementById("log_text_wrapper")
	
	self:ClearEntries(parent_el)
	
end

function MissionlogController:CleanupMessageLog()

	local parent_el = self.document:GetElementById("log_text_wrapper")
	
	self:ClearEntries(parent_el)

end

function MissionlogController:CleanupGoalsLog()

	self.document:GetElementById("briefing_goals"):SetClass("hidden", true)
	self.document:GetElementById("goal_key"):SetClass("hidden", true)
	
end

function MissionlogController:ClearEntries(parent)

	while parent:HasChildNodes() do
		parent:RemoveChild(parent.first_child)
	end

end

function MissionlogController:DecrementSection(element)

    if self.currentSection == 1 then
		self:ChangeSection(self.numSections)
	else
		self:ChangeSection(self.currentSection - 1)
	end

end

function MissionlogController:IncrementSection(element)

    if self.currentSection == self.numSections then
		self:ChangeSection(1)
	else
		self:ChangeSection(self.currentSection + 1)
	end

end

function MissionlogController:Exit(element)

    ui.playElementSound(element, "click", "success")
	if mn.isInMission() then
		ad.pauseMusic(-1, false)
		ad.pauseWeaponSounds(false)
		ui.PauseScreen.closePause()
	end
	ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])

end

function MissionlogController:global_keydown(_, event)
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

return MissionlogController
