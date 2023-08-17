local gr_common = require('gr_common')

local Inspect                            = require('inspect')
local gr_system_map = {}

function gr_system_map.drawIcon(ship)
    local icon = gr_common.getIconForShip(ship)
    if icon then
        local screen_position = GameSystemMap.Camera:getScreenCoords(ship.System.Position)
        --ba.println("gr_system_map.drawIcon: " .. Inspect({ship.System.Position.y, screen_position.x, screen_position.y}))
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

function gr_system_map.drawMap(mouseX, mouseY, ships, drawTarget)
    gr.setTarget(drawTarget)

    gr.clearScreen(10, 10, 10, 255)
    gr.setColor(30, 30, 30, 255)

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

        gr_system_map.drawIcon(curr_ship)
    end)

    gr.setTarget()
end

return gr_system_map
