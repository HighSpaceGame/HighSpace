local class                              = require("class")
local GameState                          = require('game_state')
local SystemMapDrawing                   = require('system_map_drawing')
local MissionTacticalController          = class()


function MissionTacticalController:init()
end

function MissionTacticalController:initialize(document)
    self.document  = document
end

local mouse_buttons = {
    ["button0"] = false,
    ["button1"] = false,
    ["button2"] = false,
}
local mouseX = 0.0
local mouseY = 0.0

function MissionTacticalController:wheel(event, _, _)
    SystemMapDrawing.cam_dist = SystemMapDrawing.cam_dist * (1+event.parameters.wheel_delta * 0.1)
end

function MissionTacticalController:mouseDown(event, _, _)
    mouse_buttons["button" .. event.parameters.button] = true
    ba.println("mouseDown: " .. event.parameters.button)

    if mouse_buttons["button0"] then
        GameState.selectShip(mouseX, mouseY)
    elseif mouse_buttons["button1"] then
        GameState.moveShip(mouseX, mouseY)
    end
end

function MissionTacticalController:mouseUp(event, _, _)
    mouse_buttons["button" .. event.parameters.button] = false
    ba.println("mouseUp: " .. event.parameters.button)
end

function MissionTacticalController:mouseMove(event, _, _)
    if mouse_buttons["button0"] then
        SystemMapDrawing.cam_x = SystemMapDrawing.cam_x - (event.parameters.mouse_x - mouseX) * SystemMapDrawing.cam_dist / 400
        SystemMapDrawing.cam_y = SystemMapDrawing.cam_y + (event.parameters.mouse_y - mouseY) * SystemMapDrawing.cam_dist / 400
    end

    mouseX = event.parameters.mouse_x - drawMap.x1
    mouseY = event.parameters.mouse_y - drawMap.y1
    --ba.println("mouseMove: " .. inspect({mouseX, mouseY}))
end

function MissionTacticalController:global_keydown(_, event)
    if event.parameters.key_identifier == rocket.key_identifier.RETURN then
        event:StopPropagation()

        GameState.MissionTactical:toggleMode()
    end
end

return MissionTacticalController
