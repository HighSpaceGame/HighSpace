local dialogs = require("dialogs")
local class = require("class")
local async_util = require("async_util")

local AbstractBriefingController = require("briefingCommon")

local BriefingController = class(AbstractBriefingController)

local drawMap = nil

--Option to render briefing map to "texture" or directly to "screen"
local renderMapTo = "screen"

function BriefingController:init()
    --- @type briefing_stage[]
    self.stages = {}
	
    self.element_names = {
        pause_btn = "cmdpause_btn",
        last_btn = "cmdlast_btn",
        next_btn = "cmdnext_btn",
        prev_btn = "cmdprev_btn",
        first_btn = "cmdfirst_btn",
        text_el = "brief_text_el",
        stage_text_el = "brief_stage_text_el",
    }
	
	drawMap = {
		tex = nil,
		target = renderMapTo
	}
	
	if not RocketUiSystem.selectInit then
		ui.ShipWepSelect.initSelect()
		RocketUiSystem.selectInit = true
	end
	
end

function BriefingController:initialize(document)
    AbstractBriefingController.initialize(self, document)
	
	ui.maybePlayCutscene(MOVIE_PRE_BRIEF, true, 0)
	
	--Default width is 888, default height is 371
	
	briefView = self.document:GetElementById("briefing_grid")
						
	local viewLeft = briefView.offset_left + briefView.parent_node.offset_left + briefView.parent_node.parent_node.offset_left
	local viewTop = briefView.offset_top + briefView.parent_node.offset_top + briefView.parent_node.parent_node.offset_top
	
	--The grid needs to be a very specific aspect ratio, so we'll calculate
	--the percent change here and use that to calculate the height below.
	local percentChange = ((briefView.offset_width - 888) / 888) * 100
	
	drawMap.x1 = viewLeft
	drawMap.y1 = viewTop
	drawMap.x2 = briefView.offset_width
	drawMap.y2 = self:calcPercent(371, (100 + percentChange))
	
	ui.Briefing.initBriefing()

	--ui.Briefing.startBriefingMap(drawMap.x1, drawMap.y1, drawMap.x2, drawMap.y2)
	
	if mn.hasNoBriefing() then
		RocketUiSystem.selectInit = false
		if RocketUiSystem.music_handle ~= nil and RocketUiSystem.music_handle:isValid() then
			RocketUiSystem.music_handle:close(true)
		end
		RocketUiSystem.music_handle = nil
		RocketUiSystem.current_played = nil
		ui.Briefing.commitToMission()
	end
	
	if mn.isScramble() or mn.isTraining() then
		local ss_btn = self.document:GetElementById("s_select_btn")
		local ws_btn = self.document:GetElementById("w_select_btn")
		
		ss_btn:SetClass("button_1", false)
		ws_btn:SetClass("button_1", false)
	end
		

	---Load the desired font size from the save file
	if modOptionValues.Font_Multiplier then
		fontChoice = modOptionValues.Font_Multiplier
		self.document:GetElementById("main_background"):SetClass(("p1-" .. fontChoice), true)
	else
		self.document:GetElementById("main_background"):SetClass("p1-5", true)
	end
	
	self.document:GetElementById("mission_title").inner_rml = mn.getMissionTitle()

    local briefing = ui.Briefing.getBriefing()
	
	local numStages = 0
	
    for i = 1, #briefing do
        --- @type briefing_stage
        local stage = briefing[i]
		if stage then
			self.stages[i] = stage
			numStages = numStages + 1
			--This is where we should replace variables and containers probably!
		end
    end
	if mn.hasGoalsStage() then
		local g = numStages + 1
		self.stages[g] = {
			Text = ba.XSTR( "Please review your objectives for this mission.", 395)
		}
		numStages = numStages + 1
	end
	if #self.stages > 0 then
		self:go_to_stage(1)
	end
	
	if mn.isInCampaign() then
		if mn.isTraining() then
			self.document:GetElementById("skip_m_text").inner_rml = ba.XSTR("Skip Training", -1)
			self.document:GetElementById("top_panel_a"):SetClass("hidden", false)
		elseif mn.isInCampaignLoop() then
			self.document:GetElementById("skip_m_text").inner_rml = ba.XSTR("Exit Loop", -1)
			self.document:GetElementById("top_panel_a"):SetClass("hidden", false)
		elseif mn.isMissionSkipAllowed() then
			self.document:GetElementById("skip_m_text").inner_rml = ba.XSTR("Skip Mission", -1)
			self.document:GetElementById("top_panel_a"):SetClass("hidden", false)
		else
			self.document:GetElementById("top_panel_a"):SetClass("hidden", true)
		end
	else
		self.document:GetElementById("top_panel_a"):SetClass("hidden", true)
	end
	
	if ba.inDebug() then
		local missionFile = mn.getMissionFilename() .. ".fs2"
		local missionDate = mn.getMissionModifiedDate()
		self.document:GetElementById("mission_debug_info").inner_rml = missionFile .. " mod " .. missionDate
	end
	
	self.document:GetElementById("brief_btn"):SetPseudoClass("checked", true)
	
	self:buildGoals()
	
	drawMap.tex = gr.createTexture(drawMap.x2, drawMap.y2)
	drawMap.url = ui.linkTexture(drawMap.tex)
	drawMap.draw = true
	local aniEl = self.document:CreateElement("img")
    aniEl:SetAttribute("src", drawMap.url)
	briefView:ReplaceChild(aniEl, briefView.first_child)
end

function BriefingController:calcPercent(value, percent)
    if value == nil or percent == nil then  
		return false;
	end
    return value * (percent/100)
end

function BriefingController:buildGoals()
    if mn.hasGoalsStage() then
		goals = ui.Briefing.Objectives
		local bulletHTML = "<div id=\"goalsdot_img\" class=\"goalsdot brightblue\"><img src=\"scroll-button.png\" class=\"psuedo_img\"></img></div>"
		local primaryWrapper = self.document:GetElementById("primary_goal_list")
		local primaryText = ""
		local secondaryWrapper = self.document:GetElementById("secondary_goal_list")
		local secondaryText = ""
		local bonusWrapper = self.document:GetElementById("bonus_goal_list")
		local bonusText = ""
		for i = 1, #goals do
			goal = goals[i]
			if goal.isGoalValid and goal.Message ~= "" then
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
				end
			end
		end
		primaryWrapper.inner_rml = primaryText
		secondaryWrapper.inner_rml = secondaryText
		bonusWrapper.inner_rml = bonusText
	end
end

function BriefingController:ChangeBriefState(state)
	if state == 1 then
		--Do nothing because we're this is the current state!
		--ba.postGameEvent(ba.GameEvents["GS_EVENT_START_BRIEFING"])
	elseif state == 2 then
		if mn.isScramble() then
			ad.playInterfaceSound(10)
		else
			ba.postGameEvent(ba.GameEvents["GS_EVENT_SHIP_SELECTION"])
		end
	elseif state == 3 then
		if mn.isScramble() then
			ad.playInterfaceSound(10)
		else
			ba.postGameEvent(ba.GameEvents["GS_EVENT_WEAPON_SELECTION"])
		end
	end
end

function BriefingController:go_to_stage(stage_idx)
    self:leaveStage()

    local stage = self.stages[stage_idx]

	local brief_img = "brief-main-window.png"

	if mn.hasGoalsStage() and stage_idx == #self.stages then
		self:initializeStage(stage_idx, stage.Text, stage.AudioFilename)
		self.document:GetElementById("briefing_goals"):SetClass("hidden", false)
		drawMap.goals = true
	else
		self:initializeStage(stage_idx, stage.Text, stage.AudioFilename)
		self.document:GetElementById("briefing_goals"):SetClass("hidden", true)
		drawMap.goals = false
	end
	
	local brief_bg_src = self.document:CreateElement("img")
	brief_bg_src:SetAttribute("src", brief_img)
	local brief_bg_el = self.document:GetElementById("brief_grid_window")
	brief_bg_el:ReplaceChild(brief_bg_src, brief_bg_el.last_child)
end

function BriefingController:CutToStage()
	ad.playInterfaceSound(42)
	drawMap.draw = false
	self.aniWrapper = self.document:GetElementById("brief_grid_cut")
	ad.playInterfaceSound(42)
    local aniEl = self.document:CreateElement("ani")
    aniEl:SetAttribute("src", "static.png")
	self.aniWrapper:ReplaceChild(aniEl, self.aniWrapper.first_child)
	
	async.run(function()
        async.await(async_util.wait_for(0.7))
        drawMap.draw = true
		self.aniWrapper:RemoveChild(self.aniWrapper.first_child)
    end, async.OnFrameExecutor, self.uiActiveContext)
end

function BriefingController:drawMap()

	gr.setTarget(drawMap.tex)
	
	
	if drawMap.draw == true then
		if drawMap.target == "texture" then
			gr.setTarget(drawMap.tex)
			gr.clearScreen(0,0,0,0)
			ui.Briefing.drawBriefingMap(0, 0, drawMap.x2, drawMap.y2)
		elseif drawMap.target == "screen" then
			gr.clearScreen(0,0,0,0)
			gr.setTarget()
			ui.Briefing.drawBriefingMap(drawMap.x1, drawMap.y1, drawMap.x2, drawMap.y2)
		end
	else
		gr.clearScreen(0,0,0,0)	
	end
	
	gr.setTarget()

end

function BriefingController:Show(text, title, buttons)
	--Create a simple dialog box with the text and title

	currentDialog = true
	drawMap.draw = false
	
	local dialog = dialogs.new()
		dialog:title(title)
		dialog:text(text)
		for i = 1, #buttons do
			dialog:button(buttons[i].b_type, buttons[i].b_text, buttons[i].b_value, buttons[i].b_keypress)
		end
		dialog:escape("")
		dialog:show(self.document.context)
		:continueWith(function(response)
			drawMap.draw = true
    end)
	-- Route input to our context until the user dismisses the dialog box.
	ui.enableInput(self.document.context)
end

function BriefingController:acceptPressed()
    
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
		if drawMap then
			drawMap.tex:unload()
			drawMap.tex = nil
			drawMap = nil
		end
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
			b_keypress = string.sub(ba.XSTR("Okay", -1), 1, 1)
		}
		
		self:Show(text, title, buttons)
	end

end

function BriefingController:skip_pressed()
    
	if mn.isTraining() then
		ui.Briefing.skipTraining()
	elseif mn.isInCampaignLoop() then
		ui.Briefing.exitLoop()
	elseif mn.isMissionSkipAllowed() then
		ui.Briefing.skipMission()
	end

end

engine.addHook("On Frame", function()
	if ba.getCurrentGameState().Name == "GS_STATE_BRIEFING" then
		BriefingController:drawMap()
	end
end, {}, function()
    return false
end)

--Prevent the briefing UI from being drawn if we're just going
--to skip it in a frame or two
engine.addHook("On Frame", function()
	if ba.getCurrentGameState().Name == "GS_STATE_BRIEFING" and mn.hasNoBriefing() then
		gr.clearScreen()
	end
end, {}, function()
    return false
end)

return BriefingController
