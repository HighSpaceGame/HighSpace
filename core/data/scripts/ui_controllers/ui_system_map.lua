local Class                              = require("class")
local Inspect                            = require('inspect')
local GrSystemMap                        = require('gr_system_map')
local UIController                       = require('ui_controller')
local Vector                             = require('vector')

local SystemMapUIController = Class(UIController)()

local draw_map = nil

function SystemMapUIController:initialize(document)
    self.Document = document
    RocketUiSystem.Controller = self

    ba.println("SystemMapController:init()")

    draw_map = {
        Tex = nil,
    }

    local system_map = self.Document:GetElementById("system-map")
    draw_map.Tex = gr.createTexture(system_map.offset_width, system_map.offset_height)
    draw_map.Url = ui.linkTexture(draw_map.Tex)
    draw_map.Draw = true

    GameSystemMap.Camera:init(system_map.offset_width, system_map.offset_height)
    local ani_el = self.Document:CreateElement("img")
    ani_el:SetAttribute("src", draw_map.Url)
    system_map:ReplaceChild(ani_el, system_map.first_child)
end

function SystemMapUIController:mouseDown(event, _, _)
    if event.parameters.button == UI_CONST.MOUSE_BUTTON_LEFT then
        ba.println("selecting ship: " .. Inspect(self.Mouse))
        GameSystemMap:selectShip(self.Mouse.X, self.Mouse.Y)
    elseif event.parameters.button == UI_CONST.MOUSE_BUTTON_RIGHT then
        GameSystemMap:moveShip(self.Mouse.X, self.Mouse.Y)
    end
end

function SystemMapUIController:mouseMove(event, document, element)
    self:storeMouseMove(event, document, element)
end

local camera_move_keys = {
    [rocket.key_identifier.W] = { ["y"] = 1.0 },
    [rocket.key_identifier.S] = { ["y"] = -1.0 },
    [rocket.key_identifier.A] = { ["x"] = -1.0 },
    [rocket.key_identifier.D] = { ["x"] = 1.0 },
}

local camera_movement = Vector()

function SystemMapUIController:wheel(event, _, _)
    GameSystemMap.Camera:zoom(1+event.parameters.wheel_delta * 0.1)
end

function SystemMapUIController:keyDown(_, event)
    if camera_move_keys[event.parameters.key_identifier] then
        event:StopPropagation()

        for coord, value in pairs(camera_move_keys[event.parameters.key_identifier]) do
            camera_movement[coord] = value
        end

        GameSystemMap.Camera:setMovement(camera_movement)
    end

    self:storeKeyDown(event)
end

function SystemMapUIController:keyUp(_, event)
    if camera_move_keys[event.parameters.key_identifier] then
        event:StopPropagation()

        for coord, _ in pairs(camera_move_keys[event.parameters.key_identifier]) do
            camera_movement[coord] = 0
        end

        GameSystemMap.Camera:setMovement(camera_movement)
    end

    self:storeKeyUp(event)
end

function SystemMapUIController:frame()
    if ba.getCurrentGameState().Name == "GS_STATE_BRIEFING" then
        GameSystemMap.Camera:update()
        GrSystemMap.drawMap(SystemMapUIController.Mouse.X, SystemMapUIController.Mouse.Y, GameState.Ships, GameSystemMap.System, draw_map.Tex)

        GameSystemMap.processEncounters()
    end
end

return SystemMapUIController
