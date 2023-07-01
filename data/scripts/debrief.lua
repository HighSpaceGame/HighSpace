local rocket_utils = require("rocket_util")
local async_util = require("async_util")
local dialogs = require("dialogs")

local class = require("class")

--local AbstractBriefingController = require("briefingCommon")

--local FictionViewerController = class(AbstractBriefingController)

local DebriefingController = class()

function DebriefingController:init()
	self.stages = {}
	self.recommendVisible = false
	self.player = nil
	self.page = 1
end

function DebriefingController:initialize(document)
	--AbstractBriefingController.initialize(self, document)
	self.document = document
	self.selectedSection = 1
	self.audioPlaying = 0
	
	if not RocketUiSystem.debriefInit then
		ui.maybePlayCutscene(MOVIE_PRE_DEBRIEF, true, 0)
		ui.Debriefing.initDebriefing()
		if not mn.hasDebriefing() then
			ui.Debriefing.acceptMission()
		end
		self:startMusic()
		RocketUiSystem.debriefInit = true
	end
	
	self.player = ba.getCurrentPlayer()	
	
	if self.player.ShowSkipPopup and ui.Debriefing.canSkip() and ui.Debriefing.mustReplay() then
		self:OfferSkip()
	end
	
	---Load the desired font size from the save file
	if modOptionValues.Font_Multiplier then
		local fontChoice = modOptionValues.Font_Multiplier
		self.document:GetElementById("main_background"):SetClass(("p1-" .. fontChoice), true)
	else
		self.document:GetElementById("main_background"):SetClass("p1-5", true)
	end
	
	self.document:GetElementById("mission_name").inner_rml = mn.getMissionTitle()
	self.document:GetElementById("awards_wrapper"):SetClass("hidden", true)
	
	local li_el = self.document:CreateElement("li")
	
	local promoStage, promoName, promoFile = ui.Debriefing.getEarnedPromotion()
	local badgeStage, badgeName, badgeFile = ui.Debriefing.getEarnedBadge()
	local medalName, medalFile = ui.Debriefing.getEarnedMedal()
	
	local numStages = 0
	self.audioPlaying = 0
	
	local traitorStage = ui.Debriefing.getTraitor()
	
	if not traitorStage then
		if promoName then
			numStages = numStages + 1
			self.stages[numStages] = promoStage
			self.document:GetElementById("awards_wrapper"):SetClass("hidden", false)
			local awards_el = self.document:GetElementById("medal_image_wrapper")
			local imgEl = self.document:CreateElement("img")
			imgEl:SetAttribute("src", promoFile)
			imgEl:SetClass("medal_img", true)
			awards_el:AppendChild(imgEl)
			self.document:GetElementById("promotion_text").inner_rml = promoName
		end
		
		if badgeName then
			numStages = numStages + 1
			self.stages[numStages] = badgeStage
			self.document:GetElementById("awards_wrapper"):SetClass("hidden", false)
			local awards_el = self.document:GetElementById("medal_image_wrapper")
			local imgEl = self.document:CreateElement("img")
			imgEl:SetAttribute("src", badgeFile)
			imgEl:SetClass("medal_img", true)
			awards_el:AppendChild(imgEl)
			self.document:GetElementById("badge_text").inner_rml = badgeName
		end
		
		if medalName then
			self.document:GetElementById("awards_wrapper"):SetClass("hidden", false)
			local awards_el = self.document:GetElementById("medal_image_wrapper")
			local imgEl = self.document:CreateElement("img")
			imgEl:SetAttribute("src", medalFile)
			imgEl:SetClass("medal_img", true)
			awards_el:AppendChild(imgEl)
			self.document:GetElementById("medal_text").inner_rml = medalName
		end
		
		local debriefing = ui.Debriefing.getDebriefing()

		for i = 1, #debriefing do
			--- @type debriefing_stage
			local stage = debriefing[i]
			if stage:checkVisible() then
				numStages = numStages + 1
				self.stages[numStages] = stage
				--This is where we should replace variables and containers probably!
			end
		end
	else
		numStages = 1
		self.stages[1] = traitorStage
	end
	
	self:BuildText()
	
	self:PlayVoice()
	
	self.document:GetElementById("debrief_btn"):SetPseudoClass("checked", true)
	
	--local defaultColorTag = ui.DefaultTextColorTag(2)
	--[[local text_el = self.document:GetElementById("fiction_text")
	
	local color_text = rocket_utils.set_briefing_text(text_el, self.text)
	
	self.voice_handle = ad.openAudioStream(self.voiceFile, AUDIOSTREAM_VOICE)
	self.voice_handle:play(ad.MasterVoiceVolume)]]--

end

function DebriefingController:PlayVoice()
	async.run(function()
        -- First, wait until the text has been shown fully
        async.await(async_util.wait_for(1.0))

        -- And now we can start playing the voice file
		if self.stages[self.audioPlaying + 1] then
			if self.stages[self.audioPlaying + 1].AudioFilename then
				self.audioPlaying = self.audioPlaying + 1
				local file = self.stages[self.audioPlaying].AudioFilename
				if #file > 0 and string.lower(file) ~= "none" then
					self.current_voice_handle = ad.openAudioStream(file, AUDIOSTREAM_VOICE)
					self.current_voice_handle:play(ad.MasterVoiceVolume)
				end
			end
		end

        self:waitForStageFinishAsync()
		
		if self.selectedSection == 1 then
			self:PlayVoice()
		end
    end, async.OnFrameExecutor)
end

function DebriefingController:waitForStageFinishAsync()
    if self.current_voice_handle ~= nil and self.current_voice_handle:isValid() then
        while self.current_voice_handle:isPlaying() do
            async.await(async.yield())
        end
    else
        --Do nothing
    end

    -- Voice part is done so wait for a bit before saying we are actually finished
    async.await(async_util.wait_for(0.5))
end

function DebriefingController:BuildText()
	
	local text_el = self.document:GetElementById("debrief_text")
	
	self.RecIDs = {}

	for i = 1, #self.stages do
		local paragraph = self.document:CreateElement("p")
		text_el:AppendChild(paragraph)
		paragraph:SetClass("debrief_text_actual", true)
		local color_text = rocket_utils.set_briefing_text(paragraph, self.stages[i].Text)
		if self.stages[i].Recommendation ~= "" then
			local recommendation = self.document:CreateElement("p")
			self.RecIDs[i] = recommendation
			text_el:AppendChild(recommendation)
			recommendation.inner_rml = self.stages[i].Recommendation
			recommendation:SetClass("hidden", true)
			recommendation:SetClass("red", true)
			recommendation:SetClass("recommendation", true)
		end
	end

	if #self.RecIDs == 0 then
		local paragraph = self.document:CreateElement("p")
		text_el:AppendChild(paragraph)
		local recommendation = self.document:CreateElement("p")
		self.RecIDs[1] = recommendation
		text_el:AppendChild(recommendation)
		recommendation.inner_rml = ba.XSTR("We have no recommendations for you.", -1)
		recommendation:SetClass("hidden", true)
		recommendation:SetClass("red", true)
		recommendation:SetClass("recommendation", true)
	end

end

function DebriefingController:BuildStats()

	local stats = self.player.Stats
	local name = self.player:getName()
	local difficulty = ba.getGameDifficulty()
	local missionTime = mn.getMissionTime()
	
	--Convert mission time to minutes + seconds
	missionTime = (math.floor(missionTime/60)) .. ":" .. (math.floor(missionTime % 60))
	
	if difficulty == 1 then difficulty = "very easy" end
	if difficulty == 2 then difficulty = "easy" end
	if difficulty == 3 then difficulty = "medium" end
	if difficulty == 4 then difficulty = "hard" end
	if difficulty == 5 then difficulty = "very hard" end
	
	local text_el = self.document:GetElementById("debrief_text")
	
	local titles = ""
	local numbers = ""
	
	--Build stats header
	local header = self.document:CreateElement("div")
	text_el:AppendChild(header)
	header:SetClass("blue", true)
	header:SetClass("stats_header", true)
	local name_el = self.document:CreateElement("p")
	local page_el = self.document:CreateElement("p")
	header:AppendChild(name_el)
	name_el:SetClass("stats_header_left", true)
	header:AppendChild(page_el)
	page_el:SetClass("stats_header_right", true)
	name_el.inner_rml = name
	page_el.inner_rml = self.page .. " of 4"
	
	--Build stats sub header
	local subheader = self.document:CreateElement("div")
	text_el:AppendChild(subheader)
	subheader:SetClass("stats_subheader", true)
	local name_el = self.document:CreateElement("p")
	local page_el = self.document:CreateElement("p")
	subheader:AppendChild(name_el)
	name_el:SetClass("stats_left", true)
	subheader:AppendChild(page_el)
	page_el:SetClass("stats_right", true)
	name_el.inner_rml = "Skill Level"
	page_el.inner_rml = difficulty
	
	--Build stats page 1
	if self.page == 1 then
		titles = "Mission Time<br></br><br></br>Mission Stats<br></br><br></br>Total Kills<br></br><br></br>Primary Weapon Shots<br></br>Primary Weapon Hits<br></br>Primary Friendly Hits<br></br>Primary Hit %<br></br>Primary Friendly Hit %<br></br><br></br>Secondary Weapon Shots<br></br>Secondary Weapon Hits<br></br>Secondary Friendly Hits<br></br>Secondary Hit %<br></br>Secondary Friendly Hit %<br></br><br></br>Assists"
		
		local primaryHitPer = math.floor((stats.MissionPrimaryShotsHit / stats.MissionPrimaryShotsFired) * 100) .. "%"
		local primaryFrHitPer = math.floor((stats.MissionPrimaryFriendlyHit / stats.MissionPrimaryShotsFired) * 100) .. "%"
		local secondaryHitPer = math.floor((stats.MissionSecondaryShotsHit / stats.MissionSecondaryShotsFired) * 100) .. "%"
		local secondaryFrHitPer = math.floor((stats.MissionSecondaryFriendlyHit / stats.MissionSecondaryShotsFired) * 100) .. "%"
		
		--Zero out percentages if appropriate
		if stats.MissionPrimaryShotsHit == 0 then
			primaryHitPer = 0 .. "%"
			primaryFrHitPer = 0 .. "%"
		end
		if stats.MissionSecondaryShotsHit == 0 then
			secondaryHitPer = 0 .. "%"
			secondaryFrHitPer = 0 .. "%"
		end
		
		numbers = missionTime .. "<br></br><br></br><br></br><br></br>" .. stats.MissionTotalKills .. "<br></br><br></br>" .. stats.MissionPrimaryShotsFired .. "<br></br>" .. stats.MissionPrimaryShotsHit  .. "<br></br>" .. stats.MissionPrimaryFriendlyHit .. "<br></br>" .. primaryHitPer .. "<br></br>" .. primaryFrHitPer .. "<br></br><br></br>" .. stats.MissionSecondaryShotsFired .. "<br></br>" .. stats.MissionSecondaryShotsHit .. "<br></br>" .. stats.MissionSecondaryFriendlyHit .. "<br></br>" .. secondaryHitPer .. "<br></br>" .. secondaryFrHitPer .. "<br></br><br></br>" .. stats.MissionAssists
	end
	
	if self.page == 2 then
		titles = "Mission Kills by Ship Type<br></br><br></br>"
		numbers = "<br></br><br></br>"
		
		for i = 1, #tb.ShipClasses do
			local kills = stats:getMissionShipclassKills(tb.ShipClasses[i])
			if kills > 0 then
				titles = titles .. tb.ShipClasses[i].Name .. "<br></br><br></br>"
				numbers = numbers .. kills .. "<br></br><br></br>"
			end
		end
	end
	
	if self.page == 3 then
		titles = "Mission Stats<br></br><br></br>Total Kills<br></br><br></br>Primary Weapon Shots<br></br>Primary Weapon Hits<br></br>Primary Friendly Hits<br></br>Primary Hit %<br></br>Primary Friendly Hit %<br></br><br></br>Secondary Weapon Shots<br></br>Secondary Weapon Hits<br></br>Secondary Friendly Hits<br></br>Secondary Hit %<br></br>Secondary Friendly Hit %<br></br><br></br>Assists"
		
		local primaryHitPer = math.floor((stats.PrimaryShotsHit / stats.PrimaryShotsFired) * 100) .. "%"
		local primaryFrHitPer = math.floor((stats.PrimaryFriendlyHit / stats.PrimaryShotsFired) * 100) .. "%"
		local secondaryHitPer = math.floor((stats.SecondaryShotsHit / stats.SecondaryShotsFired) * 100) .. "%"
		local secondaryFrHitPer = math.floor((stats.SecondaryFriendlyHit / stats.SecondaryShotsFired) * 100) .. "%"
		
		--Zero out percentages if appropriate
		if stats.MissionPrimaryShotsHit == 0 then
			primaryHitPer = 0 .. "%"
			primaryFrHitPer = 0 .. "%"
		end
		if stats.MissionSecondaryShotsHit == 0 then
			secondaryHitPer = 0 .. "%"
			secondaryFrHitPer = 0 .. "%"
		end
		
		numbers = "<br></br><br></br>" .. stats.TotalKills .. "<br></br><br></br>" .. stats.PrimaryShotsFired .. "<br></br>" .. stats.PrimaryShotsHit  .. "<br></br>" .. stats.PrimaryFriendlyHit .. "<br></br>" .. primaryHitPer .. "<br></br>" .. primaryFrHitPer .. "<br></br><br></br>" .. stats.SecondaryShotsFired .. "<br></br>" .. stats.SecondaryShotsHit .. "<br></br>" .. stats.SecondaryFriendlyHit .. "<br></br>" .. secondaryHitPer .. "<br></br>" .. secondaryFrHitPer .. "<br></br><br></br>" .. stats.Assists
	end
	
	if self.page == 4 then
		titles = "Mission Kills by Ship Type<br></br><br></br>"
		numbers = "<br></br><br></br>"
		
		for i = 1, #tb.ShipClasses do
			local kills = stats:getShipclassKills(tb.ShipClasses[i])
			if kills > 0 then
				titles = titles .. tb.ShipClasses[i].Name .. "<br></br><br></br>"
				numbers = numbers .. kills .. "<br></br><br></br>"
			end
		end
	end
	
	--Actually write the stats data here
	local stats = self.document:CreateElement("div")
	text_el:AppendChild(stats)
	local titles_el = self.document:CreateElement("p")
	local numbers_el = self.document:CreateElement("p")
	stats:AppendChild(titles_el)
	titles_el:SetClass("stats_left", true)
	stats:AppendChild(numbers_el)
	numbers_el:SetClass("stats_right", true)
	titles_el.inner_rml = titles
	numbers_el.inner_rml = numbers

end

function DebriefingController:ClearText()
	self.document:GetElementById("debrief_text").inner_rml = ""
	self.audioPlaying = 0
end

function DebriefingController:startMusic()
	local filename = ui.Debriefing.getDebriefingMusicName()
	
	RocketUiSystem.debrief_music = ad.openAudioStream(filename, AUDIOSTREAM_MENUMUSIC)
	async.run(function()
		async.await(async_util.wait_for(2.5))
		RocketUiSystem.debrief_music:play(ad.MasterEventMusicVolume, true, 0)
	end, async.OnFrameExecutor)
end

function DebriefingController:Show(text, title, buttons)
	--Create a simple dialog box with the text and title

	currentDialog = true
	
	local dialog = dialogs.new()
		dialog:title(title)
		dialog:text(text)
		dialog:escape("cancel")
		for i = 1, #buttons do
			dialog:button(buttons[i].b_type, buttons[i].b_text, buttons[i].b_value, buttons[i].b_keypress)
		end
		dialog:show(self.document.context)
		:continueWith(function(response)
        self:dialog_response(response)
    end)
	-- Route input to our context until the user dismisses the dialog box.
	ui.enableInput(self.document.context)
end

function DebriefingController:dialog_response(response)
	local switch = {
		accept = function()
			self:close()
			ui.Debriefing.acceptMission()
		end, 
		acceptquit = function()
			self:close()
			ui.Debriefing.acceptMission(false)
			--ui.stopMission()
			ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
		end,
		replay = function()
			self:close()
			ui.Debriefing.clearMissionStats()
			ui.Debriefing.replayMission()
		end,
		quit = function()
			self:close()
			ui.Debriefing.clearMissionStats()
			ui.Debriefing.replayMission(false)
			--ui.stopMission()
			ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
		end,
		skip = function()
			self:close()
			ui.Debriefing.acceptMission(false)
			ui.Briefing.skipMission()
		end,
		optout = function()
			self.player.ShowSkipPopup = false
		end,
		cancel = function()
			--Do Nothing   
		end,
	}

	if switch[response] then
		switch[response]()
	else
		switch["cancel"]()
	end
end

function DebriefingController:GetCharacterAtWord(text, index)

	local words = {}
	for word in text:gmatch("%S+") do table.insert(words, word) end
	
	if index > #words then index = #words end
	if index < 1 then index = 1 end
	
	return string.sub(words[index], 1, 1)

end

function DebriefingController:OfferSkip()
	local text = ba.XSTR("You have failed this mission five times.  If you like, you may advance to the next mission.", 1472)
	local title = ""
	local buttons = {}
	
	
	
	buttons[1] = {
		b_type = dialogs.BUTTON_TYPE_NEGATIVE,
		b_text = ba.XSTR("Do Not Skip This Mission", 1473),
		b_value = "cancel",
		b_keypress = self:GetCharacterAtWord(ba.XSTR("Do Not Skip This Mission", 1473), 2)
	}
	buttons[2] = {
		b_type = dialogs.BUTTON_TYPE_POSITIVE,
		b_text = ba.XSTR("Advance To The Next Mission", 1474),
		b_value = "skip",
		b_keypress = self:GetCharacterAtWord(ba.XSTR("Advance To The Next Mission", 1474), 1)
	}
	buttons[3] = {
		b_type = dialogs.BUTTON_TYPE_NEUTRAL,
		b_text = ba.XSTR("Don't Show Me This Again", 1475),
		b_value = "optout",
		b_keypress = self:GetCharacterAtWord(ba.XSTR("Don't Show Me This Again", 1475), 1)
	}
		
	self:Show(text, title, buttons)
end

function DebriefingController:page_pressed(command)
	if self.selectedSection == 1 then
		ui.playElementSound(element, "click", "failure")
		--FIXMEEEE
	else
		if command == 1 then
			self.page = 1
		end
		if command == 4 then
			self.page = 4
		end
		if command == 2 then
			self.page = self.page - 1
			if self.page <= 0 then
				self.page = 1
			end
		end
		if command == 3 then
			self.page = self.page + 1
			if self.page >= 5 then
				self.page = 4
			end
		end
		
		ui.playElementSound(element, "click", "success")
		self:ClearText()
		self:BuildStats()
	end
end

function DebriefingController:debrief_pressed(element)
	if self.selectedSection ~= 1 then
		ui.playElementSound(element, "click", "success")
		self.document:GetElementById("debrief_btn"):SetPseudoClass("checked", true)
		self.document:GetElementById("stats_btn"):SetPseudoClass("checked", false)
		self.selectedSection = 1
		
		self.document:GetElementById("stage_select"):SetPseudoClass("hidden", true)
		
		self:ClearText()
		self:BuildText()
		self:PlayVoice()
		
		self.recommendVisible = false
	end
end

function DebriefingController:stats_pressed(element)
	if self.selectedSection ~= 2 then
		ui.playElementSound(element, "click", "success")
		self.document:GetElementById("debrief_btn"):SetPseudoClass("checked", false)
		self.document:GetElementById("stats_btn"):SetPseudoClass("checked", true)
		self.selectedSection = 2
		
		self.document:GetElementById("stage_select"):SetPseudoClass("hidden", false)
		
		self:ClearText()
		if self.current_voice_handle ~= nil and self.current_voice_handle:isValid() then
			self.current_voice_handle:close(false)
		end
		self:BuildStats()
		
		self.recommendVisible = false
	end
end

function DebriefingController:recommend_pressed(element)
	ui.playElementSound(element, "click", "success")
	
	for i = 1, #self.RecIDs do
		self.RecIDs[i]:SetClass("hidden", self.recommendVisible)
	end
	
	self.recommendVisible = not self.recommendVisible
end
	

function DebriefingController:replay_pressed(element)
    ui.playElementSound(element, "click", "success")
	if ui.Debriefing:mustReplay() then
		ui.Debriefing.clearMissionStats()
		self:close()
		ui.Debriefing.replayMission()
	else
		local text = ba.XSTR("If you choose to replay this mission, you will be required to complete it again before proceeding to future missions.\n\nIn addition, any statistics gathered during this mission will be discarded if you choose to replay.", 452)
		text = string.gsub(text,"\n","<br></br>")
		local title = ""
		local buttons = {}
		buttons[1] = {
			b_type = dialogs.BUTTON_TYPE_NEGATIVE,
			b_text = ba.XSTR("Cancel", 504),
			b_value = "cancel",
			b_keypress = self:GetCharacterAtWord(ba.XSTR("Cancel", 504), 1)
		}
		buttons[2] = {
			b_type = dialogs.BUTTON_TYPE_POSITIVE,
			b_text = ba.XSTR("Replay", 451),
			b_value = "replay",
			b_keypress = self:GetCharacterAtWord(ba.XSTR("Replay", 451), 1)
		}
			
		self:Show(text, title, buttons)
	end
end

function DebriefingController:accept_pressed()
	if ui.Debriefing:mustReplay() then
		local text = nil
		if ui.Debriefing.getTraitor() then
			text = ba.XSTR("Your career is over, Traitor!  You can't accept new missions!", 439)
		else
			text = ba.XSTR("You have failed this mission and cannot accept.  What do you you wish to do instead?", 441)
		end
		local title = ""
		local buttons = {}
		buttons[1] = {
			b_type = dialogs.BUTTON_TYPE_NEUTRAL,
			b_text = ba.XSTR("Return to Debriefing", 442),
			b_value = "cancel",
			b_keypress = self:GetCharacterAtWord(ba.XSTR("Return to Debriefing", 442), 3)
		}
		buttons[2] = {
			b_type = dialogs.BUTTON_TYPE_NEUTRAL,
			b_text = ba.XSTR("Go to Flight Deck", 443),
			b_value = "quit",
			b_keypress = self:GetCharacterAtWord(ba.XSTR("Go to Flight Deck", 443), 1)
		}
		buttons[3] = {
			b_type = dialogs.BUTTON_TYPE_NEUTRAL,
			b_text = ba.XSTR("Replay Mission", 444),
			b_value = "replay",
			b_keypress = self:GetCharacterAtWord(ba.XSTR("Replay Mission", 444), 1)
		}
			
		self:Show(text, title, buttons)
	else
		self:close()
		ui.Debriefing.acceptMission()
	end
end

function DebriefingController:medals_button_clicked(element)
    ui.playElementSound(element, "click", "success")
	self.selectedSection = 0
    ba.postGameEvent(ba.GameEvents["GS_EVENT_VIEW_MEDALS"])
end

function DebriefingController:options_button_clicked(element)
    ui.playElementSound(element, "click", "success")
	self.selectedSection = 0
    ba.postGameEvent(ba.GameEvents["GS_EVENT_OPTIONS_MENU"])
end

function DebriefingController:help_clicked(element)
    ui.playElementSound(element, "click", "success")
    --TODO
end

function DebriefingController:global_keydown(_, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
		event:StopPropagation()
		if ui.Debriefing:mustReplay() then
			local text = ba.XSTR("Because this mission was a failure, you must replay this mission when you continue your campaign.\n\nReturn to the Flight Deck?", 457)
			text = string.gsub(text,"\n","<br></br>")
			local title = ""
			local buttons = {}
			buttons[1] = {
				b_type = dialogs.BUTTON_TYPE_NEGATIVE,
				b_text = ba.XSTR("No", 506),
				b_value = "cancel",
				b_keypress = self:GetCharacterAtWord(ba.XSTR("No", 506), 1)
			}
			buttons[2] = {
				b_type = dialogs.BUTTON_TYPE_POSITIVE,
				b_text = ba.XSTR("Yes", 505),
				b_value = "quit",
				b_keypress = self:GetCharacterAtWord(ba.XSTR("Yes", 505), 1)
			}
				
			self:Show(text, title, buttons)
		else
			local text = ba.XSTR("Accept this mission outcome?", 440)
			local title = ""
			local buttons = {}
			buttons[1] = {
				b_type = dialogs.BUTTON_TYPE_NEGATIVE,
				b_text = ba.XSTR("Cancel", 504),
				b_value = "cancel",
				b_keypress = self:GetCharacterAtWord(ba.XSTR("Cancel", 504), 1)
			}
			buttons[2] = {
				b_type = dialogs.BUTTON_TYPE_POSITIVE,
				b_text = ba.XSTR("Yes", 454),
				b_value = "acceptquit",
				b_keypress = self:GetCharacterAtWord(ba.XSTR("Yes", 454), 1)
			}
			buttons[3] = {
				b_type = dialogs.BUTTON_TYPE_NEUTRAL,
				b_text = ba.XSTR("No, retry later", 455),
				b_value = "quit",
				b_keypress = self:GetCharacterAtWord(ba.XSTR("No, retry later", 455), 1)
			}
				
			self:Show(text, title, buttons)
		end
    end
end

function DebriefingController:close()
	if RocketUiSystem.debrief_music ~= nil and RocketUiSystem.debrief_music:isValid() then
        RocketUiSystem.debrief_music:close(false)
		RocketUiSystem.debrief_music = nil
    end
	RocketUiSystem.debriefInit = false
end

function DebriefingController:unload()
    if self.current_voice_handle ~= nil and self.current_voice_handle:isValid() then
        self.current_voice_handle:close(false)
    end
end

return DebriefingController
