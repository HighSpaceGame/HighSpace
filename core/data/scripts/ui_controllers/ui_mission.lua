local Class                              = require("class")
local Inspect                            = require('inspect')
local UIController                       = require('ui_controller')
local GrCommon                           = require('gr_common')
local GrMission                          = require('gr_mission')

local MissionTacticalUIController = Class(UIController)()

MissionTacticalUIController.SelectionFrom = nil

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
    local selected_ships_container = MissionTacticalUIController.Document:GetElementById("selected-ships").first_child
    selected_ships_container:SetClass("hidden", true)

    for _, ship in pairs(GameMission.SelectedShips) do
        selected_ships_container:SetClass("hidden", false)

        set_ship_info(selected_ships_container.first_child.first_child, ship)

        if ship.MissionShipInstance.Target and ship.MissionShipInstance.Target:isValid() then
            local target_ship = GameState.Ships[ship.MissionShipInstance.Target.Name]
            set_ship_info(selected_ships_container.last_child.first_child, target_ship)
            selected_ships_container.last_child:SetClass("hidden", false)
        else
            selected_ships_container.last_child:SetClass("hidden", true)
        end

        break
    end
end

function MissionTacticalUIController:initialize(document)
    self.Document = document
end

function MissionTacticalUIController:wheel(event, _, _)
    --placeholder
    --SystemMapDrawing.cam_dist = SystemMapDrawing.cam_dist * (1+event.parameters.wheel_delta * 0.1)
end

function MissionTacticalUIController:mouseDown(event, document, element)
    self:storeMouseDown(event, document, element)

    if event.parameters.button == UIController.MOUSE_BUTTON_LEFT then
        self.SelectionFrom = { ["X"] = self.Mouse.X, ["Y"] = self.Mouse.Y }
    elseif event.parameters.button == UIController.MOUSE_BUTTON_RIGHT then
        GameMission:giveRightClickCommand({ ["X"] = self.Mouse.X, ["Y"] = self.Mouse.Y })
    end
end

function MissionTacticalUIController:mouseUp(event, document, element)
    self:storeMouseUp(event, document, element)

    if event.parameters.button == UIController.MOUSE_BUTTON_LEFT then
        GameMission:selectShips(self.SelectionFrom, { ["X"] = self.Mouse.X, ["Y"] = self.Mouse.Y })

        self.SelectionFrom = nil
    end
end

function MissionTacticalUIController:mouseMove(event, document, element)
    self:storeMouseMove(event, document, element)
end

function MissionTacticalUIController:keyDown(_, event)
    if event.parameters.key_identifier == rocket.key_identifier.RETURN then
        event:StopPropagation()

        GameMission:toggleMode()
    end
end

engine.addHook("On Frame", function()
    if GameMission:showTacticalView() then
        GrMission.drawSelectionBox(MissionTacticalUIController.SelectionFrom, MissionTacticalUIController.Mouse)
        GrMission.drawSelectionBrackets()
        update_selection_info()
    end
end, {}, function()
    return false
end)

return MissionTacticalUIController
