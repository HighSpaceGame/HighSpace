local class                              = require("class")
local GameState                          = require('game_state')
local SystemMapDrawing                   = require('system_map_drawing')
local SystemMapController              = class()

SystemMapController.MODE_PLAYER_SELECT = 1
SystemMapController.MODE_BARRACKS      = 2

local drawMap = nil

--Option to render briefing map to "texture" or directly to "screen"
local renderMapTo = "screen"

function SystemMapController:init()
    self.selection = nil
    self.elements = {}
    self.callsign_input_active = false

    drawMap = {
        tex = nil,
        target = renderMapTo
    }

    self.mode                  = SystemMapController.MODE_PLAYER_SELECT
end

function SystemMapController:initialize(document)
    self.document  = document

    local briefView = self.document:GetElementById("strat-map")

    drawMap.x1 = briefView.offset_left
    drawMap.y1 = briefView.offset_top
    drawMap.x2 = briefView.offset_width
    drawMap.y2 = briefView.offset_height

    drawMap.tex = gr.createTexture(drawMap.x2, drawMap.y2)
    drawMap.url = ui.linkTexture(drawMap.tex)
    drawMap.draw = true

    local aniEl = self.document:CreateElement("img")
    aniEl:SetAttribute("src", drawMap.url)
    briefView:ReplaceChild(aniEl, briefView.first_child)
end

local mouse_buttons = {
    ["button0"] = false,
    ["button1"] = false,
    ["button2"] = false,
}
local mouseX = 0.0
local mouseY = 0.0

function SystemMapController:wheel(event, _, _)
    SystemMapDrawing.cam_dist = SystemMapDrawing.cam_dist * (1+event.parameters.wheel_delta * 0.1)
end

function SystemMapController:mouseDown(event, _, _)
    mouse_buttons["button" .. event.parameters.button] = true
    ba.println("mouseDown: " .. event.parameters.button)

    if mouse_buttons["button0"] then
        GameState.selectShip(mouseX, mouseY)
    elseif mouse_buttons["button1"] then
        GameState.moveShip(mouseX, mouseY)
    end
end

function SystemMapController:mouseUp(event, _, _)
    mouse_buttons["button" .. event.parameters.button] = false
    ba.println("mouseUp: " .. event.parameters.button)
end

function SystemMapController:mouseMove(event, _, _)
    if mouse_buttons["button0"] then
        SystemMapDrawing.cam_x = SystemMapDrawing.cam_x - (event.parameters.mouse_x - mouseX) * SystemMapDrawing.cam_dist / 400
        SystemMapDrawing.cam_y = SystemMapDrawing.cam_y + (event.parameters.mouse_y - mouseY) * SystemMapDrawing.cam_dist / 400
    end

    mouseX = event.parameters.mouse_x - drawMap.x1
    mouseY = event.parameters.mouse_y - drawMap.y1
    --ba.println("mouseMove: " .. inspect({mouseX, mouseY}))
end

function SystemMapController:global_keydown(_, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE or event.parameters.key_identifier == rocket.key_identifier.PAUSE then
        event:StopPropagation()

        gr.setCamera()
        ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])
    end
end

engine.addHook("On Frame", function()
    GameState.processEncounters()
    SystemMapDrawing.drawMap(mouseX, mouseY, GameState.ships, drawMap.tex)
end, {}, function()
    return (not GameState.missionLoaded)
end)

return SystemMapController
