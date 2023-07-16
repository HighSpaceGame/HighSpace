local Inspect			= require("inspect")
local GameMissionTact	= require("game_mission")
local GameState			= require("game_state")
local GameSystemMap		= require("game_system_map")
local Utils				= require("utils")

local updateCategory = engine.createTracingCategory("UpdateRocket", false)
local renderCategory = engine.createTracingCategory("RenderRocket", true)

local get_rocket_ui_handle = function(state)
	if state.Name == "GS_STATE_SCRIPTING" then
		return {Name = RocketUiSystem.Substate }
	else
		return state
	end
end

RocketUiSystem = {
	Replacements = {},
	SkipUi = { ["GS_STATE_GAME_PLAY"] = true},
	Substate = "none",
}

--RUN AWAY IT'S FRED!
if ba.inMissionEditor() then
	return
end

RocketUiSystem.Context = rocket:CreateContext("menuui", Vector2i.new(gr.getCenterWidth(), gr.getCenterHeight()));

function RocketUiSystem:init()
    for _, v in ipairs(cf.listFiles("data/config", "*-ui.cfg")) do
        parse.readFileText(v, "data/config")

        parse.requiredString("#State Replacement")

        while parse.optionalString("$State:") do
            local state = parse.getString()

			if state == "GS_STATE_SCRIPTING" then
				parse.requiredString("+Substate:")
				local state = parse.getString()
				parse.requiredString("+Markup:")
				local markup = parse.getString()
				ba.print("SCPUI found definition for script substate " .. state .. " : " .. markup .. "\n")
				self.Replacements[state] = {
					markup = markup
				}
			else
				parse.requiredString("+Markup:")
				local markup = parse.getString()
				ba.print("SCPUI found definition for game state " .. state .. " : " .. markup .. "\n")
				self.Replacements[state] = {
					markup = markup
				}
			end
        end

        parse.requiredString("#End")

        parse.stop()
    end
end

function RocketUiSystem:getDef(state)
    return self.Replacements[state]
end

function RocketUiSystem:stateStart()

	--This allows for states to correctly return to the previous state even if has no rocket ui defined
	RocketUiSystem.currentState = ba.getCurrentGameState()
	
	--If hv.NewState is nil then use the Current Game State; This allows for Script UIs to jump from substate to substate
	local state = hv.NewState or ba.getCurrentGameState()
	
    if not self:hasOverrideForState(get_rocket_ui_handle(state)) then
        return
    end

    local def = self:getDef(get_rocket_ui_handle(state).Name)
    def.document = self.Context:LoadDocument(def.markup)
    def.document:Show()

	if state.Name ~= "GS_STATE_GAME_PLAY" then
		ui.enableInput(self.Context)
		io.setCursorHidden(false)
	end
end

function RocketUiSystem:stateFrame()
    if not self:showUIForCurrentState() then
        return
    end

    -- Add some tracing scopes here to see how long this stuff takes
    updateCategory:trace(function()
        self.Context:Update()
    end)
    renderCategory:trace(function()
        self.Context:Render()
    end)
end

function RocketUiSystem:stateEnd()

	--This allows for states to correctly return to the previous state even if has no rocket ui defined
	RocketUiSystem.lastState = RocketUiSystem.currentState

    if not self:hasOverrideForState(get_rocket_ui_handle(hv.OldState)) then
        return
    end

    local def = self:getDef(get_rocket_ui_handle(hv.OldState).Name)

    def.document:Close()
    def.document = nil

    ui.disableInput()
	
	if hv.OldState.Name == "GS_STATE_SCRIPTING" then
		RocketUiSystem.Substate = "none"
	end
end

function RocketUiSystem:beginSubstate(state) 
	local old_substate = RocketUiSystem.Substate
	RocketUiSystem.Substate = state
	--If we're already in GS_STATE_SCRIPTING then force loading the new scpui define
	if ba.getCurrentGameState().Name == "GS_STATE_SCRIPTING" then
		ba.print("Got event SCPUI SCRIPTING SUBSTATE " .. RocketUiSystem.Substate .. " in SCPUI SCRIPTING SUBSTATE " .. old_substate .. "\n")
		RocketUiSystem:stateStart()
	else
		ba.print("Got event SCPUI SCRIPTING SUBSTATE " .. RocketUiSystem.Substate .. "\n")
		ba.postGameEvent(ba.GameEvents["GS_EVENT_SCRIPTING"])
	end
end

--This allows for states to correctly return to the previous state even if has no rocket ui defined
function RocketUiSystem:ReturnToState(state)

	local event

	if state.Name == "GS_STATE_BRIEFING" then
		event = "GS_EVENT_START_BRIEFING"
	elseif state.Name == "GS_STATE_VIEW_CUTSCENES" then
		event = "GS_EVENT_GOTO_VIEW_CUTSCENES_SCREEN"
	else
		event = string.gsub(state.Name, "STATE", "EVENT")
	end

	ba.postGameEvent(ba.GameEvents[event])

end

function RocketUiSystem:hasOverrideForState(state)
    return self:getDef(state.Name) ~= nil
end

function RocketUiSystem:hasOverrideForCurrentState()
    return self:hasOverrideForState(get_rocket_ui_handle(ba.getCurrentGameState()))
end

function RocketUiSystem:showUIForCurrentState()
	return self:hasOverrideForState(get_rocket_ui_handle(ba.getCurrentGameState())) and not self.SkipUi[ba.getCurrentGameState().Name]
end

function RocketUiSystem:dialogStart()
    ui.enableInput(self.Context)
    
    local dialogs = require('dialogs')
	if hv.IsDeathPopup then
		self.DeathDialog = { Abort = {}, Submit = nil }
	else
		self.Dialog = { Abort = {}, Submit = nil }
	end
    local dialog = dialogs.new()
        dialog:title(hv.Title)
        dialog:text(hv.Text)
		dialog:input(hv.IsInputPopup)

		if hv.IsDeathPopup then
			dialog:style(2)
			--dialog:escape("deathpopup")
		else
			dialog:escape(-1) --Assuming that all non-death built-in popups can be cancelled safely with a negative response!
		end
    
    for i, button in ipairs(hv.Choices) do
        local positivity = nil
        if button.Positivity == 0 then
            positivity = dialogs.BUTTON_TYPE_NEUTRAL
        elseif button.Positivity == 1 then
            positivity = dialogs.BUTTON_TYPE_POSITIVE
        elseif button.Positivity == -1 then
            positivity = dialogs.BUTTON_TYPE_NEGATIVE
        end
        dialog:button(positivity, button.Text, i - 1, button.Shortcut)
    end
	
	if hv.IsDeathPopup then
		dialog:show(self.Context, self.DialogAbort)
			:continueWith(function(response)
				self.DeathDialog.Submit = response
			end)
	else
		dialog:show(self.Context, self.DialogAbort)
			:continueWith(function(response)
				self.Dialog.Submit = response
			end)
	end
end

function RocketUiSystem:dialogFrame()
    -- Add some tracing scopes here to see how long this stuff takes
    updateCategory:trace(function()
		if hv.Freeze ~= nil and hv.Freeze ~= true then
			self.Context:Update()
		end
    end)
    renderCategory:trace(function()
        self.Context:Render()
    end)
	
	--So that the skip mission popup can re-enable the death popup on dialog end
	if self.Reenable ~= nil and self.Reenable == true then
		ui.enableInput(self.Context)
		self.Reenable = nil
	end
		
    
	if hv.IsDeathPopup then
		if self.DeathDialog.Submit ~= nil then
			local submit = self.DeathDialog.Submit
			self.DeathDialog = nil
			hv.Submit(submit)
		end
	else
		if self.Dialog.Submit ~= nil then
			local submit = self.Dialog.Submit
			self.Dialog = nil
			hv.Submit(submit)
		end
	end
end

function RocketUiSystem:dialogEnd()
    ui.disableInput(self.Context)
	
	if not hv.IsDeathPopup then
		self.Reenable = true
	end

	if hv.IsDeathPopup then
		if self.DeathDialog ~= nil and self.DeathDialog.Abort ~= nil then
			self.DeathDialog.Abort.Abort()
		end
	else
		if self.Dialog ~= nil and self.Dialog.Abort ~= nil then
			self.Dialog.Abort.Abort()
		end
	end
end

RocketUiSystem:init()

engine.addHook("On State Start", function()
    RocketUiSystem:stateStart()

	-- The "On State Start" hook doesn't seem to work in the game_state script... maybe because of the "override" callback?
	-- So we call it here manually
	GameState.stateChanged()
end, {}, function()
    return hv.NewState ~= nil and hv.NewState.Name ~= "GS_STATE_GAME_PLAY" and RocketUiSystem:hasOverrideForState(get_rocket_ui_handle(hv.NewState))
end)

engine.addHook("On Frame", function()
    RocketUiSystem:stateFrame()
end, {}, function()
	return ba.getCurrentGameState().Name ~= "GS_STATE_GAME_PLAY" and RocketUiSystem:hasOverrideForCurrentState()
end)

engine.addHook("On State End", function()
    RocketUiSystem:stateEnd()
end, {}, function()
    return hv.OldState ~= nil and hv.OldState.Name ~= "GS_STATE_GAME_PLAY" and RocketUiSystem:hasOverrideForState(get_rocket_ui_handle(hv.OldState))
end)

--[[
engine.addHook("On Dialog Init", function()
    RocketUiSystem:dialogStart()
end, {}, function()
    return true
end)

engine.addHook("On Dialog Frame", function()
    RocketUiSystem:dialogFrame()
end, {}, function()
    return true
end)

engine.addHook("On Dialog Close", function()
    RocketUiSystem:dialogEnd()
end, {}, function()
    return true
end)

]]--