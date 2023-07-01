local rocket_utils = require("rocket_util")

local class = require("class")

local MedalsController = class(AbstractBriefingController)

ScpuiSystem.drawMedalText = nil

function MedalsController:init()
	ScpuiSystem.drawMedalText = {
		name = nil,
		x = 0,
		y = 0
	}
end

function MedalsController:initialize(document)
	
	self.document = document
	
	---Load the desired font size from the save file
	if ScpuiOptionValues.Font_Multiplier then
		local fontChoice = ScpuiOptionValues.Font_Multiplier
		self.document:GetElementById("main_background"):SetClass(("p1-" .. fontChoice), true)
	else
		self.document:GetElementById("main_background"):SetClass("p1-5", true)
	end
	
	self.playerMedals = ba.getCurrentPlayer().Stats.Medals
	self.playerRank = ba.getCurrentPlayer().Stats.Rank.Name
	self.playerName = ba.getCurrentPlayer():getName()
	
	for i = 1, #self.playerMedals do
		if self.playerMedals[i] > 0 then
			self:showMedal(i)
		end
		
		--rank can be zero
		if ui.Medals.Medals_List[i].Name == "Rank" then
			self:showMedal(i)
		end
	end
	
	self.document:GetElementById("medals_text").inner_rml = self.playerName

end

function MedalsController:showMedal(idx)
	local medal = ui.Medals.Medals_List[idx]
	
	--get the div
	local medal_el = self.document:GetElementById(string.lower(medal.Bitmap:match("(.+)%..+$")))
	
	--create new image element based on number earned
	local img_el = self.document:CreateElement("img")
	
	local num = math.min(self.playerMedals[idx], ui.Medals.Medals_List[idx].NumMods)
	
	--create the display string
	local display = medal.Name
	if num > 1 then
		display = medal.Name .. " (" .. self.playerMedals[idx] .. ")"
	end
	
	--rank is special because reasons
	if medal.Name == "Rank" then
		num = num + 1
		display = self.playerRank
	end
	
	--now setup for the png name
	if num < 10 then
		num = "_0" .. num
	else
		num = "_" .. num
	end
	
	local filename = medal_el.id .. num .. ".png"
	
	img_el:SetAttribute("src", filename)
	
	--replace the old image
	medal_el:ReplaceChild(img_el, medal_el.first_child)
	
	--add mouseover listener
	medal_el:AddEventListener("mouseover", function()
		ScpuiSystem.drawMedalText.name = display
	end)
	
	medal_el:AddEventListener("mouseout", function()
		ScpuiSystem.drawMedalText.name = nil
	end)
end

function MedalsController:accept_pressed()
	ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])
end

function MedalsController:global_keydown(_, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
        ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])
    end
end

function MedalsController:mouse_move(element, event)
	ScpuiSystem.drawMedalText.x = event.parameters.mouse_x
	ScpuiSystem.drawMedalText.y = event.parameters.mouse_y
end

function MedalsController:drawText()
	if ScpuiSystem.drawMedalText.name ~= nil then
		--save the current color
		local r, g, b, a = gr.getColor()
		
		--set the color to white
		gr.setColor(255, 255, 255, 255)
		
		--get the string width
		local w = gr.getStringWidth(ScpuiSystem.drawMedalText.name)
		
		--draw the string
		gr.drawString(ScpuiSystem.drawMedalText.name, ScpuiSystem.drawMedalText.x - w, ScpuiSystem.drawMedalText.y - 15)
		
		--reset the color
		gr.setColor(r, g, b, a)
	end
end		

engine.addHook("On Frame", function()
	if ba.getCurrentGameState().Name == "GS_STATE_VIEW_MEDALS" then
		MedalsController:drawText()
	end
end, {}, function()
    return false
end)

return MedalsController
