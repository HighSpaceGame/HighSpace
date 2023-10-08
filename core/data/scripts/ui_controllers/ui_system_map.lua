local Class                              = require("class")
local Inspect                            = require('inspect')
local GrSystemMap                        = require('gr_system_map')
local UIController                       = require('ui_controller')
local Vector                             = require('vector')

local SystemMapUIController = Class(UIController)()

local draw_map = nil
local last_time_button
local current_time_display
local system_map_offset = Vector(0,0)

function SystemMapUIController:initialize(document)
    self.Document = document
    RocketUiSystem.Controller = self

    ba.println("SystemMapController:init()")

    draw_map = {
        Tex = nil,
    }

    last_time_button = self.Document:GetElementById("system-time-pause")
    current_time_display = self.Document:GetElementById("system-current-time")

    local system_map = self.Document:GetElementById("system-map")
    draw_map.Tex = gr.createTexture(system_map.offset_width, system_map.offset_height)
    draw_map.Url = ui.linkTexture(draw_map.Tex)
    draw_map.Draw = true

    GameSystemMap.Camera:init(system_map.offset_width, system_map.offset_height)
    local ani_el = self.Document:CreateElement("img")
    ani_el:SetAttribute("src", draw_map.Url)
    system_map:ReplaceChild(ani_el, system_map.first_child)

    system_map_offset = Vector(0,0)
    while system_map do
        system_map_offset = system_map_offset + Vector(system_map.offset_left, system_map.offset_top)
        system_map = system_map.offset_parent
    end

    ba.println("SystemMapUIController:initialize: " .. Inspect({ system_map_offset.x, system_map_offset.y }))
end

function SystemMapUIController:mouseDown(event, _, _)
    if event.parameters.button == UI_CONST.MOUSE_BUTTON_LEFT then
        GameSystemMap:onLeftClick(self.Mouse.Cursor)
    elseif event.parameters.button == UI_CONST.MOUSE_BUTTON_RIGHT then
        GameSystemMap:moveShip(self.Mouse.Cursor)
    end
end

function SystemMapUIController:mouseMove(event, document, element)
    self:storeMouseMove(event, document, element, system_map_offset)
end

local camera_move_keys = {
    [rocket.key_identifier.W] = { ["y"] = 1.0 },
    [rocket.key_identifier.S] = { ["y"] = -1.0 },
    [rocket.key_identifier.A] = { ["x"] = -1.0 },
    [rocket.key_identifier.D] = { ["x"] = 1.0 },
}

local camera_movement = Vector()

function SystemMapUIController:wheel(event, _, _)
    GameSystemMap.Camera:zoom(event.parameters.wheel_delta)
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

function SystemMapUIController:setTimeSpeed(speed, event, element)
    event:StopPropagation()

    if last_time_button then
        last_time_button:SetClass("active", false)
    end

    element:SetClass("active", true)
    last_time_button = element

    GameState.TimeSpeed = speed
end

function SystemMapUIController:frame()
    if ba.getCurrentGameState().Name == "GS_STATE_BRIEFING" then
        GameSystemMap:update()

        current_time_display.inner_rml = os.date('!%Y-%m-%d %H:%M:%S', GameState.CurrentTime)
        GrSystemMap.drawMap(self.Mouse.Cursor:copy(), draw_map.Tex)

        GameSystemMap.processEncounters()
    end
end

return SystemMapUIController
