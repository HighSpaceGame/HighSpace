local rocket_utils = require("rocket_util")
local async_util = require("async_util")

local class = require("class")

local RedAlertController = class()

function RedAlertController:init()
	if not RocketUiSystem.selectInit then
		ui.ShipWepSelect.initSelect()
		RocketUiSystem.selectInit = true
	end
end

local alert_el = nil
local alert_bool = true

function RedAlertController:initialize(document)
	self.document = document

	ui.maybePlayCutscene(MOVIE_PRE_BRIEF, true, 0)
	---Load the desired font size from the save file
	if modOptionValues.Font_Multiplier then
		fontChoice = modOptionValues.Font_Multiplier
		self.document:GetElementById("main_background"):SetClass(("p1-" .. fontChoice), true)
	else
		self.document:GetElementById("main_background"):SetClass("p1-5", true)
	end

    local alert_info = ui.RedAlert.getRedAlert()
	
	local text_el = self.document:GetElementById("red_alert_text")
	
	local color_text = rocket_utils.set_briefing_text(text_el, alert_info.Text)
	
	if alert_info.AudioFilename then
		self.current_voice_handle = ad.openAudioStream(alert_info.AudioFilename, AUDIOSTREAM_VOICE)
		self.current_voice_handle:play(ad.MasterVoiceVolume)
	end
	
	alert_el = self.document:GetElementById("incoming_transmission")
	RedAlertController:blink()

end

function RedAlertController:blink()
	
	async.run(function()
        async.await(async_util.wait_for(0.5))
		if alert_bool then
			alert_el:SetClass("hidden", true)
			alert_bool = false
			RedAlertController:blink()
		else
			alert_el:SetClass("hidden", false)
			alert_bool = true
			RedAlertController:blink()
		end
    end, async.OnFrameExecutor, async.context.captureGameState())

end

function RedAlertController:commit_pressed()
	RocketUiSystem.selectInit = false
	ba.postGameEvent(ba.GameEvents["GS_EVENT_ENTER_GAME"])
end

function RedAlertController:replay_pressed()
    if ui.RedAlert.replayPreviousMission() and mn.isInCampaign() then
		ba.postGameEvent(ba.GameEvents["GS_EVENT_START_GAME"])
	end
end

function RedAlertController:unload()
    if self.current_voice_handle ~= nil and self.current_voice_handle:isValid() then
        self.current_voice_handle:close(false)
    end
end

function RedAlertController:global_keydown(_, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
        --self.music_handle:stop()
		event:StopPropagation()
		RocketUiSystem.selectInit = false
		
		--ui.stopMission()
        ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
    end
end

return RedAlertController
