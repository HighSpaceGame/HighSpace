local class                              = require("class")
local inspect                            = require('inspect')
local UIController                       = require('ui_controller')
local GrCommon                           = require('gr_common')
local GrMissionTact                      = require('gr_mission_tact')

local MissionTacticalController          = class(UIController)()

MissionTacticalController.selectionFrom = nil

local set_ship_info = function(elem, ship)
    if elem and ship then
        elem = elem.next_sibling --skip static text
        elem:SetAttribute("src", GrCommon.getIconForShip(ship).Url)

        elem = elem.next_sibling
        elem.inner_rml = ship.Name
        elem.style.color = string.format("rgb(%d, %d, %d)", ship.Team:getColor())
        elem = elem.next_sibling
        elem.inner_rml = string.format("Class: %s", ship.Class)
        elem = elem.next_sibling
        elem.inner_rml = string.format("Health: %d%%", ship.MissionShipInstance.HitpointsLeft / ship.MissionShipInstance.HitpointsMax * 100)
    end
end

local update_selection_info = function()
    local selected_ships_container = MissionTacticalController.document:GetElementById("selected-ships").first_child
    selected_ships_container:SetClass("hidden", true)

    for _, ship in pairs(GameMissionTactical.SelectedShips) do
        selected_ships_container:SetClass("hidden", false)

        set_ship_info(selected_ships_container.first_child.first_child, ship)

        if ship.MissionShipInstance.Target and ship.MissionShipInstance.Target:isValid() then
            local target_ship = GameState.ships[ship.MissionShipInstance.Target.Name]
            set_ship_info(selected_ships_container.last_child.first_child, target_ship)
            selected_ships_container.last_child:SetClass("hidden", false)
        else
            selected_ships_container.last_child:SetClass("hidden", true)
        end

        break
    end
end

function MissionTacticalController:initialize(document)
    self.document  = document
end

function MissionTacticalController:wheel(event, _, _)
    --placeholder
    --SystemMapDrawing.cam_dist = SystemMapDrawing.cam_dist * (1+event.parameters.wheel_delta * 0.1)
end

function MissionTacticalController:mouseDown(event, document, element)
    self:storeMouseDown(event, document, element)

    if event.parameters.button == UIController.MOUSE_BUTTON_LEFT then
        self.selectionFrom = { ["x"] = self.mouse.x, ["y"] = self.mouse.y }
    elseif event.parameters.button == UIController.MOUSE_BUTTON_RIGHT then
        GameMissionTactical:giveRightClickCommand({ ["x"] = self.mouse.x, ["y"] = self.mouse.y })
    end
end

function MissionTacticalController:mouseUp(event, document, element)
    self:storeMouseUp(event, document, element)

    if event.parameters.button == UIController.MOUSE_BUTTON_LEFT then
        GameMissionTactical:selectShips(self.selectionFrom, { ["x"] = self.mouse.x, ["y"] = self.mouse.y })

        self.selectionFrom = nil
    end
end

function MissionTacticalController:mouseMove(event, document, element)
    self:storeMouseMove(event, document, element)
end

function MissionTacticalController:global_keydown(_, event)
    if event.parameters.key_identifier == rocket.key_identifier.RETURN then
        event:StopPropagation()

        GameMissionTactical:toggleMode()
    end
end

engine.addHook("On Frame", function()
    if GameMissionTactical:showTacticalView() then
        GrMissionTact.drawSelectionBox(MissionTacticalController.selectionFrom, MissionTacticalController.mouse)
        GrMissionTact.drawSelectionBrackets()
        update_selection_info()
    end
end, {}, function()
    return false
end)

return MissionTacticalController
