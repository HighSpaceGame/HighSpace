local gr_common                          = require('gr_common')
local Inspect                            = require('inspect')
local Vector                             = require('vector')

local gr_system_map = {}

local drawTexture = function(texture, screen_position, screen_size, text)
    --ba.println("gr_system_map.drawTexture(texture, world_position): " .. Inspect({ screen_position.x, screen_position.y }))
    gr.drawImageCentered(texture, screen_position.x, screen_position.y, screen_size, screen_size, 0, 0, 1, 1, 1, true)

    if text then
        local text_width = gr.getStringWidth(text)
        gr.drawString(
                text,
                screen_position.x - text_width/2,
                screen_position.y - screen_size - gr.CurrentFont.Height - 12
        )
    end
end

function gr_system_map.drawSystem(body, parent)
    --ba.println("gr_system_map.drawSystem(system): " .. Inspect(system.Stars))
    local world_position = Vector()

    if parent then
        world_position.x = 1
        world_position = world_position * body.SemiMajorAxis * 149597870700.0
        world_position = world_position:rotate(0, math.rad(body.MeanAnomalyEpoch), 0) + parent.WorldPosition
    end

    body.WorldPosition = world_position

    local screen_size = body.Radius / GameSystemMap.Camera.Zoom * 2
    local screen_position = GameSystemMap.Camera:getScreenCoords(world_position)
    local alpha_factor = 1.0

    if parent then
        local screen_position_diff = GameSystemMap.Camera:getScreenCoords(parent.WorldPosition) - screen_position
        alpha_factor = math.min(screen_position_diff:getMagnitude() / 30, 1.0)
        alpha_factor = 1.0 - (1.0 - alpha_factor)*2
    end

    gr.setColor(255, 255, 255, math.max(255 * math.min(screen_size, 10) / 10, 128) * alpha_factor)
    gr.CurrentFont = gr.Fonts["font01"]
    screen_size = math.max(screen_size, 10)
    drawTexture(body.Texture, screen_position, screen_size, body.Name)

    if not body.Satellites then
        return
    end

    for _, satellite in pairs(body.Satellites) do
        gr_system_map.drawSystem(satellite, body)
    end
end

function gr_system_map.drawShip(ship)
    local icon = gr_common.getIconForShip(ship)
    if icon then
        local screen_position = GameSystemMap.Camera:getScreenCoords(ship.System.Position)
        --ba.println("gr_system_map.drawShip: " .. Inspect({ship.System.Position.y, screen_position.x, screen_position.y}))
        gr.drawImageCentered(icon.Texture, screen_position.x, screen_position.y, icon.Width, icon.Height, 0, 0, 1, 1, 1, true)
        gr.drawImageCentered(icon.Texture, screen_position.x, screen_position.y, icon.Width, icon.Height, 0, 0, 1, 1, 1, true)

        gr.CurrentFont = gr.Fonts["font01"]
        local text_width = gr.getStringWidth(ship:getMapDisplayName())
        gr.drawString(
                ship:getMapDisplayName(),
                screen_position.x - text_width/2,
                screen_position.y - icon.Height/2 - gr.CurrentFont.Height - 12
        )
    end
end

function gr_system_map.drawMap(mouseX, mouseY, ships, system, drawTarget)
    gr.setTarget(drawTarget)

    gr.clearScreen(10, 10, 10, 255)
    gr.setColor(30, 30, 30, 255)

    gr_system_map.drawSystem(system.Stars["1"])

    ships:forEach(function(curr_ship)
        if curr_ship.IsSelected then
            local screen_position = GameSystemMap.Camera:getScreenCoords(curr_ship.System.Position)
            local selected_color = gr_common.TeamSelectedColors[curr_ship.Team.Name]
            gr.setColor(selected_color.R, selected_color.G, selected_color.B)

            if curr_ship.Team.Name == 'Friendly' then
                gr.drawLine(screen_position.x, screen_position.y, mouseX, mouseY)
            end
        else
            gr.setColor(curr_ship.Team:getColor())
        end

        gr_system_map.drawShip(curr_ship)
    end)

    gr.setTarget()
end

return gr_system_map
