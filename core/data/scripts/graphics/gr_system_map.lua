local gr_common = require('gr_common')

local gr_system_map = {}

function gr_system_map.drawIcon(ship)
    local icon = gr_common.getIconForShip(ship)
    if icon then
        gr.drawImageCentered(icon.Texture, ship.System.Position.x, ship.System.Position.y, icon.Width, icon.Height, 0, 0, 1, 1, 1, true)
        gr.drawImageCentered(icon.Texture, ship.System.Position.x, ship.System.Position.y, icon.Width, icon.Height, 0, 0, 1, 1, 1, true)
    end
end

function gr_system_map.drawMap(mouseX, mouseY, ships, drawTarget)
    gr.setTarget(drawTarget)

    gr.clearScreen(10, 10, 10, 255)
    gr.setColor(30, 30, 30, 255)

    ships:forEach(function(curr_ship)
        if curr_ship.IsSelected then
            local selected_color = gr_common.TeamSelectedColors[curr_ship.Team.Name]
            gr.setColor(selected_color.R, selected_color.G, selected_color.B)

            if curr_ship.Team.Name == 'Friendly' then
                gr.drawLine(curr_ship.System.Position.x, curr_ship.System.Position.y, mouseX, mouseY)
            end
        else
            gr.setColor(curr_ship.Team:getColor())
        end

        gr_system_map.drawIcon(curr_ship)
    end)

    gr.setTarget()
end

return gr_system_map
