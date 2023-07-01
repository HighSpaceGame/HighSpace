local dialogs = require("dialogs")
local class = require("class")
local async_util = require("async_util")

local TechCreditsController = class()

local creditsImage = {}

function TechCreditsController:init()
end

function TechCreditsController:initialize(document)
    self.document = document
    self.elements = {}
    self.section = 1
	self.scroll = 0

	---Load the desired font size from the save file
	if ScpuiOptionValues.Font_Multiplier then
		local fontChoice = ScpuiOptionValues.Font_Multiplier
		self.document:GetElementById("main_background"):SetClass(("p1-" .. fontChoice), true)
	else
		self.document:GetElementById("main_background"):SetClass("p1-5", true)
	end
	
	ui.TechRoom.buildCredits()
	
	self.rate = ui.TechRoom.Credits.ScrollRate
	
	ad.stopMusic(0, true, "mainhall")
	ui.MainHall.stopAmbientSound()
	self:startMusic()
	
	local text_el = self.document:GetElementById("credits_text")
	
	local CompleteCredits = string.gsub(ui.TechRoom.Credits.Complete,"\n","<br></br>")
	
	--We need to calculate how much empty space to add before and after the credits
	--so that we can cleanly loop the text. Get the height of the div, the height of
	--a line, and do some math. Add that number of line breaks before and after!
	local creditsHeight = text_el.offset_height
	local lineHeight = self.document:GetElementById("bullet_img").next_sibling.offset_height
	local numBreaks = (math.ceil((creditsHeight / lineHeight) + ((10 - ScpuiOptionValues.Font_Multiplier) * 1.3)))
	local creditsBookend = ""
	
	while(numBreaks > 0) do
		creditsBookend = creditsBookend .. "<br></br>"
		numBreaks = numBreaks - 1
	end
	
	--Append new lines to the top and bottom of Credits so we can loop it later seamlessly
	CompleteCredits = creditsBookend .. CompleteCredits .. creditsBookend
	text_el.inner_rml = CompleteCredits
	
	self.creditsElement = text_el
	
	self:ScrollCredits()
	
	local image_el = self.document:GetElementById("credits_image")
	local image_x1 = image_el.offset_left + image_el.parent_node.offset_left
	local image_y1 = image_el.offset_top + image_el.parent_node.offset_top
	
	creditsImage = {
		x1 = image_x1,
		y1 = image_y1,
		x2 = image_x1 + image_el.offset_width,
		y2 = image_y1 + image_el.offset_height,
		index = ui.TechRoom.Credits.StartIndex,
		alpha = 0,
		fadeAmount = 0.01 / ui.TechRoom.Credits.FadeTime,
		timer = ui.TechRoom.Credits.DisplayTime,
		fadeTimer = ui.TechRoom.Credits.FadeTime,
		imageFile1 = nil,
		imageFile2 = nil
	}
	
	self:chooseImage()
	self:timeImages()

	
	self.document:GetElementById("data_btn"):SetPseudoClass("checked", false)
	self.document:GetElementById("mission_btn"):SetPseudoClass("checked", false)
	self.document:GetElementById("cutscene_btn"):SetPseudoClass("checked", false)
	self.document:GetElementById("credits_btn"):SetPseudoClass("checked", true)
	
end

function TechCreditsController:ChangeTechState(state)

	if state == 1 then
		ba.postGameEvent(ba.GameEvents["GS_EVENT_TECH_MENU"])
	end
	if state == 2 then
		ba.postGameEvent(ba.GameEvents["GS_EVENT_SIMULATOR_ROOM"])
	end
	if state == 3 then
		ba.postGameEvent(ba.GameEvents["GS_EVENT_GOTO_VIEW_CUTSCENES_SCREEN"])
	end
	if state == 4 then
		--This is where we are already, so don't do anything
		--ba.postGameEvent(ba.GameEvents["GS_EVENT_CREDITS"])
	end
	
end

function TechCreditsController:chooseImage()
	local imageIndex = creditsImage.index
	
	if creditsImage.timer <= 0 then
		if not creditsImage.imageFile2 then
			creditsImage.index = creditsImage.index + 1
			creditsImage.imageFile2 = creditsImage.imageFile1
			creditsImage.alpha = 1.0
		end
		if creditsImage.fadeTimer > 0 then
			creditsImage.fadeTimer = creditsImage.fadeTimer - 0.01
			creditsImage.alpha = creditsImage.alpha - creditsImage.fadeAmount
		else
			creditsImage.fadeTimer = ui.TechRoom.Credits.FadeTime
			creditsImage.timer = ui.TechRoom.Credits.DisplayTime
			creditsImage.imageFile2 = nil
			creditsImage.alpha = 0
		end
	end
	
	if creditsImage.index >= ui.TechRoom.Credits.NumImages then
		creditsImage.index = 0
	end
	
	if creditsImage.index < 10 then
		imageIndex = "0" .. creditsImage.index
	end
	
	creditsImage.imageFile1 = "2_Crim" .. imageIndex .. ".png"
end

function TechCreditsController:timeImages()
	async.run(function()
        async.await(async_util.wait_for(0.01))
        creditsImage.timer = creditsImage.timer - 0.01
		self:chooseImage()
		self:timeImages()
    end, async.OnFrameExecutor)
end

function TechCreditsController:drawImage()
	if creditsImage.imageFile2 then
		gr.drawImage(creditsImage.imageFile2, creditsImage.x1, creditsImage.y1, creditsImage.x2, creditsImage.y2, 0, 0 , 1, 1, creditsImage.alpha)
	end
	if creditsImage.imageFile1 then
		gr.drawImage(creditsImage.imageFile1, creditsImage.x1, creditsImage.y1, creditsImage.x2, creditsImage.y2, 0, 0 , 1, 1, (1.0 - creditsImage.alpha))
	end
end

function TechCreditsController:startMusic()
    
	local filename = ui.TechRoom.Credits.Music

    self.music_handle = ad.openAudioStream(filename, AUDIOSTREAM_MENUMUSIC)
    async.run(function()
        async.await(async_util.wait_for(1.5))
        self.music_handle:play(ad.MasterEventMusicVolume, true)
    end, async.OnFrameExecutor)
end

function TechCreditsController:ScrollCredits()
	if self.scroll >= self.creditsElement.scroll_height then
		self.scroll = 0
	else
		self.scroll = self.scroll + self.rate / 50
	end
	self.creditsElement.scroll_top = self.scroll
	
	async.run(function()
        async.await(async_util.wait_for(0.01))
        self:ScrollCredits()
    end, async.OnFrameExecutor)
end

function TechCreditsController:global_keydown(element, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
        event:StopPropagation()

        ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
    elseif event.parameters.key_identifier == rocket.key_identifier.TAB then
		self.rate = ui.TechRoom.Credits.ScrollRate * 10
	elseif event.parameters.key_identifier == rocket.key_identifier.UP and event.parameters.ctrl_key == 1 then
		self:ChangeTechState(3)
	elseif event.parameters.key_identifier == rocket.key_identifier.DOWN and event.parameters.ctrl_key == 1 then
		self:ChangeTechState(1)
	end
end

function TechCreditsController:global_keyup(element, event)
    if event.parameters.key_identifier == rocket.key_identifier.TAB then
		self.rate = ui.TechRoom.Credits.ScrollRate
	end
end

function TechCreditsController:exit_pressed(element)
    ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
end

function TechCreditsController:unload()
	if self.music_handle ~= nil and self.music_handle:isValid() then
        self.music_handle:close(true)
    end
	ui.MainHall.startAmbientSound()
	ui.MainHall.startMusic()
end

engine.addHook("On Frame", function()
	if ba.getCurrentGameState().Name == "GS_STATE_CREDITS" then
		TechCreditsController:drawImage()
	end
end, {}, function()
    return false
end)

return TechCreditsController
