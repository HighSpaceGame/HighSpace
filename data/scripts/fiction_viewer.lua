local rocket_utils = require("rocket_util")
local async_util = require("async_util")

local class = require("class")

local AbstractBriefingController = require("briefingCommon")

local FictionViewerController = class(AbstractBriefingController)

function FictionViewerController:init()
end

function FictionViewerController:initialize(document)
	AbstractBriefingController.initialize(self, document)
	
	ui.maybePlayCutscene(MOVIE_PRE_FICTION, true, 0)
	
	---Load the desired font size from the save file
	if modOptionValues.Font_Multiplier then
		local fontChoice = modOptionValues.Font_Multiplier
		self.document:GetElementById("main_background"):SetClass(("p1-" .. fontChoice), true)
		self.document:GetElementById("fiction_text"):SetClass(("p2-" .. fontChoice), true)
	else
		self.document:GetElementById("main_background"):SetClass("p1-5", true)
		self.document:GetElementById("fiction_text"):SetClass("p2-5", true)
	end
	
	self.textFile = ui.FictionViewer.getFiction().TextFile
	self.voiceFile = ui.FictionViewer.getFiction().VoiceFile

	local file = cf.openFile(self.textFile, 'r', '')
	self.text = file:read('*a')
	file:close()
	
	local text_el = self.document:GetElementById("fiction_text")
	
	local color_text = rocket_utils.set_briefing_text(text_el, self.text)
	
	self.voice_handle = ad.openAudioStream(self.voiceFile, AUDIOSTREAM_VOICE)
	self.voice_handle:play(ad.MasterVoiceVolume)

end

function FictionViewerController:accept_pressed()
	if mn.hasCommandBriefing() then
		ba.postGameEvent(ba.GameEvents["GS_EVENT_CMD_BRIEF"])
	else
		if mn.isRedAlertMission() then
			ba.postGameEvent(ba.GameEvents["GS_EVENT_RED_ALERT"])
		else
			ba.postGameEvent(ba.GameEvents["GS_EVENT_START_BRIEFING"])
		end
	end
end

function FictionViewerController:global_keydown(_, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
		if RocketUiSystem.music_handle ~= nil and RocketUiSystem.music_handle:isValid() then
			RocketUiSystem.music_handle:close(true)
		end
		RocketUiSystem.music_handle = nil
		RocketUiSystem.current_played = nil
		event:StopPropagation()

		--ui.stopMission()
        ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
    end
end

return FictionViewerController
