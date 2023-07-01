local utils                    = require("utils")
local tblUtil                  = utils.table

local dialogs                  = require("dialogs")

local class                    = require("class")

local PilotSelectController    = require("pilotSelect")

local BarracksScreenController = class(PilotSelectController)

function BarracksScreenController:init()
    self.mode       = PilotSelectController.MODE_BARRACKS
    self.help_shown = false
end

function BarracksScreenController:initialize(document)
    self.pilotImages = ui.Barracks.listPilotImages()
    self.squadImages = ui.Barracks.listSquadImages()

    PilotSelectController.initialize(self, document)
	
	---Load the desired font size from the save file
	if modOptionValues.Font_Multiplier then
		fontChoice = modOptionValues.Font_Multiplier
		self.document:GetElementById("main_background"):SetClass(("p1-" .. fontChoice), true)
	else
		self.document:GetElementById("main_background"):SetClass("p1-5", true)
	end
	
end

function BarracksScreenController:changeImage(new_img)
    if new_img == nil then
        self.document:GetElementById("pilot_head_text_el").inner_rml = ""
        self.document:GetElementById("pilot_head_img_el"):SetAttribute("src", "")
        return
    end

    new_img     = utils.strip_extension(new_img) -- The image may have an extension
    local index = tblUtil.ifind(self.pilotImages, new_img)

    if index <= 0 then
        local text_el     = self.document:GetElementById("pilot_head_text_el")
        text_el.inner_rml = ""

        self.document:GetElementById("pilot_head_img_el"):SetAttribute("src", "")
    else
        local text_el     = self.document:GetElementById("pilot_head_text_el")
        text_el.inner_rml = string.format("%d of %d", index, #self.pilotImages)

        self.document:GetElementById("pilot_head_img_el"):SetAttribute("src", new_img)
    end
end

function BarracksScreenController:change_img_index(element, diff)
    if self.selection == nil or #self.pilotImages <= 0 then
        ui.playElementSound(element, "click", "error")
        return
    end

    local current_img = utils.strip_extension(self.selectedPilot.ImageFilename) -- The image may have an extension
    local index       = tblUtil.ifind(self.pilotImages, current_img)

    index             = index + diff
    if index > #self.pilotImages then
        index = 1
    elseif index < 1 then
        index = #self.pilotImages
    end

    self.selectedPilot.ImageFilename = self.pilotImages[index]
    self:changeImage(self.pilotImages[index])

    ui.playElementSound(element, "click", "success")
end

function BarracksScreenController:next_image_pressed(element)
    self:change_img_index(element, 1)
end

function BarracksScreenController:prev_image_pressed(element)
    self:change_img_index(element, -1)
end

function BarracksScreenController:add_heading_element(parent, text)
    local container = self.document:CreateElement("div")
    local text_el   = self.document:CreateTextNode(text)

    container:AppendChild(text_el)
    container:SetClass("stats_heading", true)
    container:SetClass("header_text", true)

    parent:AppendChild(container)
end

function BarracksScreenController:add_value_element(parent, text, value)
    local text_container = self.document:CreateElement("div")
    local text_el        = self.document:CreateTextNode(text)
    text_container:AppendChild(text_el)
    text_container:SetClass("stats_value_label", true)

    local value_container = self.document:CreateElement("div")
    local value_el        = self.document:CreateTextNode(tostring(value))
    value_container:AppendChild(value_el)
    value_container:SetClass("stats_value_text", true)

    parent:AppendChild(text_container)
    parent:AppendChild(value_container)
end

function BarracksScreenController:add_empty_line(parent)
    local text_container = self.document:CreateElement("div")
    text_container:SetClass("stats_empty_line", true)

    parent:AppendChild(text_container)
end

local function compute_percentage(fract, total)
    if total <= 0 then
        return "0%"
    end

    return string.format("%.2f%%", (fract / total) * 100)
end

function BarracksScreenController:initialize_stats_text()
    local text_container     = self.document:GetElementById("pilot_stats_text")

    -- Always clear the container to remove old elements
    text_container.inner_rml = ""
    if self.selectedPilot == nil then
        return
    end

    local stats = self.selectedPilot.Stats

    self:add_heading_element(text_container, "All Time Stats")
    self:add_value_element(text_container, "Primary weapon shots:", stats.PrimaryShotsFired)
    self:add_value_element(text_container, "Primary weapon hits:", stats.PrimaryShotsHit)
    self:add_value_element(text_container, "Primary friendly hits:", stats.PrimaryFriendlyHit)
    self:add_value_element(text_container, "Primary hit %:",
                           compute_percentage(stats.PrimaryShotsHit, stats.PrimaryShotsFired))
    self:add_value_element(text_container, "Primary friendly hit %:",
                           compute_percentage(stats.PrimaryFriendlyHit, stats.PrimaryShotsFired))
    self:add_empty_line(text_container)

    self:add_value_element(text_container, "Secondary weapon shots:", stats.SecondaryShotsFired)
    self:add_value_element(text_container, "Secondary weapon hits:", stats.SecondaryShotsHit)
    self:add_value_element(text_container, "Secondary friendly hits:", stats.SecondaryFriendlyHit)
    self:add_value_element(text_container, "Secondary hit %:",
                           compute_percentage(stats.SecondaryShotsHit, stats.SecondaryShotsFired))
    self:add_value_element(text_container, "Secondary friendly hit %:",
                           compute_percentage(stats.SecondaryFriendlyHit, stats.SecondaryShotsFired))
    self:add_empty_line(text_container)

    self:add_value_element(text_container, "Total kills:", stats.TotalKills)
    self:add_value_element(text_container, "Assists:", stats.Assists)
    self:add_empty_line(text_container)

    self:add_value_element(text_container, "Current Score:", stats.Score)
    self:add_empty_line(text_container)
    self:add_empty_line(text_container)

    self:add_heading_element(text_container, "Kills by Ship Type")
    local score_from_kills = 0
    for i = 1, #tb.ShipClasses do
        local ship_cls = tb.ShipClasses[i]
        local kills    = stats:getShipclassKills(ship_cls)

        if kills > 0 then
            score_from_kills = score_from_kills + kills * ship_cls.Score
            self:add_value_element(text_container, ship_cls.Name .. ":", kills)
        end
    end
    self:add_value_element(text_container, "Score from kills only:", score_from_kills)
end

function BarracksScreenController:selectPilot(pilot)
    PilotSelectController.selectPilot(self, pilot)

    if self.selectedPilot ~= nil then
        self.selectedPilot:loadCampaignSavefile()
    end

    if pilot == nil then
        self:changeImage(nil)
        self:changeSquad(nil)
    else
        self:changeImage(self.selectedPilot.ImageFilename)
        if self.current_mode == "multi" then
            self:changeSquad(self.selectedPilot.MultiSquadFilename)
        else
            self:changeSquad(self.selectedPilot.SingleSquadFilename)
        end
    end

    self:initialize_stats_text()
end

function BarracksScreenController:getInitialCallsign()
    return ba.getCurrentPlayer():getName()
end

function BarracksScreenController:commit_pressed(element)
    if self.selection == nil then
        ui.playElementSound(element, "click", "error")
        return
    end

    if not ui.PilotSelect.checkPilotLanguage(self.selection) then
        ui.playElementSound(element, "click", "error")

        self:showWrongPilotLanguageDialog()
        return
    end

    ui.playElementSound(element, "click", "commit")
    ui.Barracks.acceptPilot(self.selectedPilot)
end

function BarracksScreenController:medals_button_clicked()
    if self.selectedPilot ~= nil then
        ba.savePlayer(self.selectedPilot) -- Save the player in case there were changes
    end
    ba.postGameEvent(ba.GameEvents['GS_EVENT_VIEW_MEDALS'])
end

function BarracksScreenController:options_button_clicked()
    if self.selectedPilot ~= nil then
        ba.savePlayer(self.selectedPilot) -- Save the player in case there were changes
    end
    ba.postGameEvent(ba.GameEvents['GS_EVENT_OPTIONS_MENU'])
end

function BarracksScreenController:set_player_mode(element, mode)
    if not PilotSelectController.set_player_mode(self, element, mode) then
        return false
    end

    local is_multi     = mode == "multi"

    ba.MultiplayerMode = is_multi
    if self.selectedPilot then
        self.selectedPilot.IsMultiplayer = is_multi
    end

    self.document:GetElementById("squad_select_right_btn"):SetClass("hidden", not is_multi)
    self.document:GetElementById("squad_select_left_btn"):SetClass("hidden", not is_multi)
    self.document:GetElementById("pilot_squad_counter"):SetClass("hidden", not is_multi)

    if self.current_mode == "multi" then
        self:changeSquad(self.selectedPilot.MultiSquadFilename)
    else
        self:changeSquad(self.selectedPilot.SingleSquadFilename)
    end

    return true
end

function BarracksScreenController:changeSquad(new_img)
    if new_img == nil then
        self.document:GetElementById("pilot_squad_text_el").inner_rml = ""
        self.document:GetElementById("pilot_squad_img_el"):SetAttribute("src", "")
        return
    end

    new_img     = utils.strip_extension(new_img) -- The image may have an extension
    local index = tblUtil.ifind(self.squadImages, new_img)

    if index <= 0 then
        -- Invalid image found. Let's try to avoid displaying a warning here
        local text_el     = self.document:GetElementById("pilot_squad_text_el")
        text_el.inner_rml = ""

        self.document:GetElementById("pilot_squad_img_el"):SetAttribute("src", "")
    else
        local text_el     = self.document:GetElementById("pilot_squad_text_el")
        text_el.inner_rml = string.format("%d of %d", index, #self.squadImages)

        self.document:GetElementById("pilot_squad_img_el"):SetAttribute("src", new_img)
    end
end

function BarracksScreenController:change_squad_index(element, diff)
    if self.selection == nil or #self.squadImages <= 0 then
        ui.playElementSound(element, "click", "error")
        return
    end

    local squad
    if self.current_mode == "multi" then
        squad = self.selectedPilot.MultiSquadFilename
    else
        squad = self.selectedPilot.SingleSquadFilename
    end

    local current_img = utils.strip_extension(squad) -- The image may have an extension
    local index       = tblUtil.ifind(self.squadImages, current_img)

    index             = index + diff
    if index > #self.squadImages then
        index = 1
    elseif index < 1 then
        index = #self.squadImages
    end

    if self.current_mode == "multi" then
        self.selectedPilot.MultiSquadFilename = self.squadImages[index]
    else
        self.selectedPilot.SingleSquadFilename = self.squadImages[index]
    end
    self:changeSquad(self.squadImages[index])

    ui.playElementSound(element, "click", "success")
end

function BarracksScreenController:next_squad_pressed(element)
    self:change_squad_index(element, 1)
end

function BarracksScreenController:prev_squad_pressed(element)
    self:change_squad_index(element, -1)
end

function BarracksScreenController:help_clicked()
    self.help_shown  = not self.help_shown

    local help_texts = self.document:GetElementsByClassName("tooltip")
    for _, v in ipairs(help_texts) do
        v:SetPseudoClass("shown", self.help_shown)
    end
end

return BarracksScreenController
