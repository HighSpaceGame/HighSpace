local Class                              = require("class")
local Inspect                            = require('inspect')
local UIController                       = require('ui_controller')
local GrCommon                           = require('gr_common')
local GrMission                          = require('gr_mission')
local Vector                             = require('vector')

local MissionUIController = Class(UIController)()

MissionUIController.SelectionFrom = nil

local function set_ship_info(elem, ship)
    if elem and ship then
        elem = elem.next_sibling --skip static text
        elem:SetAttribute("src", ship:getIcon().Url)

        elem = elem.next_sibling
        elem.inner_rml = ship.Name
        elem.style.color = string.format("rgb(%d, %d, %d)", ship.Team:getColor())
        elem = elem.next_sibling
        elem.inner_rml = string.format("Class: %s", ship.Class)
        elem = elem.next_sibling
        elem.inner_rml = string.format("Health: %d%%", ship.Mission.Instance.HitpointsLeft / ship.Mission.Instance.HitpointsMax * 100)
    end
end

local function update_selection_info()
    local selected_ships_container = MissionUIController.Document:GetElementById("selected-ships").first_child
    selected_ships_container:SetClass("hidden", true)

    for _, ship in pairs(GameMission.SelectedShips) do
        selected_ships_container:SetClass("hidden", false)

        set_ship_info(selected_ships_container.first_child.first_child, ship)

        if ship.Mission.Instance.Target and ship.Mission.Instance.Target:isValid() then
            local target_ship = GameMission.Ships:get(ship.Mission.Instance.Target.Name)
            set_ship_info(selected_ships_container.last_child.first_child, target_ship)
            selected_ships_container.last_child:SetClass("hidden", false)
        else
            selected_ships_container.last_child:SetClass("hidden", true)
        end

        break
    end
end

function MissionUIController:initialize(document)
    self.Document = document
    RocketUiSystem.Controller = self
end

function MissionUIController:mouseDown(event, document, element)
    self:storeMouseDown(event, document, element)

    if event.parameters.button == UI_CONST.MOUSE_BUTTON_LEFT then
        self.SelectionFrom = self.Mouse.Cursor:copy()
    elseif event.parameters.button == UI_CONST.MOUSE_BUTTON_RIGHT then
        GameMission:giveRightClickCommand(self.Mouse.Cursor:copy())
    end
end

function MissionUIController:mouseUp(event, document, element)
    self:storeMouseUp(event, document, element)

    if event.parameters.button == UI_CONST.MOUSE_BUTTON_LEFT then
        GameMission:selectShips(self.SelectionFrom, self.Mouse.Cursor:copy())

        self.SelectionFrom = nil
    end
end

local camera_move_keys = {
    [rocket.key_identifier.W] = { ["z"] = 1.0 },
    [rocket.key_identifier.S] = { ["z"] = -1.0 },
    [rocket.key_identifier.A] = { ["x"] = -1.0 },
    [rocket.key_identifier.D] = { ["x"] = 1.0 },
}

local camera_movement = ba.createVector(0, 0 ,0)


function MissionUIController:wheel(event, _, _)
    GameMission.TacticalCamera:zoom(1+event.parameters.wheel_delta * 0.1)
end

function MissionUIController:keyDown(_, event)
    if event.parameters.key_identifier == rocket.key_identifier.RETURN then
        event:StopPropagation()

        GameMission:toggleMode()
    end

    if camera_move_keys[event.parameters.key_identifier] then
        event:StopPropagation()

        for coord, value in pairs(camera_move_keys[event.parameters.key_identifier]) do
            camera_movement[coord] = value
        end

        GameMission.TacticalCamera:setMovement(camera_movement)
    end

    self:storeKeyDown(event)
end

function MissionUIController:keyUp(_, event)
    if camera_move_keys[event.parameters.key_identifier] then
        event:StopPropagation()

        for coord, _ in pairs(camera_move_keys[event.parameters.key_identifier]) do
            camera_movement[coord] = 0
        end

        GameMission.TacticalCamera:setMovement(camera_movement)
    end

    self:storeKeyUp(event)
end

function MissionUIController:mouseMove(event, document, element)
    --ba.println("MissionUIController:mouseMove: " .. Inspect({ ["ctrl"] = event.parameters.ctrl_key, ["m"] = self.Mouse}))
    if event.parameters.ctrl_key > 0 and self.Mouse.Cursor.x > 0 and self.Mouse.Cursor.y then
        local pitch = (event.parameters.mouse_y - self.Mouse.Cursor.y) / 500.0
        local heading = (event.parameters.mouse_x - self.Mouse.Cursor.x) / 500.0
        GameMission.TacticalCamera:rotateBy(pitch, heading)
    end

    self:storeMouseMove(event, document, element, Vector())
end

function MissionUIController:frame()
    if GameMission:showTacticalView() then
        GrMission.drawGrid()
        GameMission.TacticalCamera:update()

        -- Uncomment when the light_reset() bug in mn.renderFrame() is fixed
        mn.simulateFrame()
        mn.renderFrame()

        GrMission.drawSelectionBox(self.SelectionFrom, self.Mouse)
        GrMission.drawSelectionBrackets()
        GrMission.drawIconsIfShipsTooSmall()
        GrMission.drawWaypointsAndTargets()
        update_selection_info()
    end
end

function MissionUIController:frameOverride()
    return GameMission:showTacticalView() -- Uncomment when the light_reset() bug in mn.renderFrame() is fixed
end

return MissionUIController
