local dialogs = require("dialogs")
local class = require("class")

local CutsceneController = class()

function CutsceneController:init()
	ad.stopMusic(0, true, "mainhall")
	ui.MainHall.stopAmbientSound()
	ui.playCutscene(ScpuiSystem.cutscene, true, 0)
end

function CutsceneController:initialize(document)
	self.document = document
	ui.MainHall.startAmbientSound()
	ui.MainHall.startMusic()
	ScpuiSystem.cutscene = "none"
	ba.postGameEvent(ba.GameEvents["GS_EVENT_GOTO_VIEW_CUTSCENES_SCREEN"])
	self.document:Close()
end

return CutsceneController
