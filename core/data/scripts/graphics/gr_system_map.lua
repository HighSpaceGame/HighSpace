local gr_common = require('gr_common')

local gr_system_map = {}

function gr_system_map.drawIcon(ship)
    local icon = gr_common.getIconForShip(ship)
    if icon then
        gr.drawImageCentered(icon.Texture, ship.Position.x, ship.Position.y, icon.Width, icon.Height, 0, 0, 1, 1, 1, true)
        gr.drawImageCentered(icon.Texture, ship.Position.x, ship.Position.y, icon.Width, icon.Height, 0, 0, 1, 1, 1, true)
    end
end

function gr_system_map.drawMap(mouseX, mouseY, ships, drawTarget)
    gr.setTarget(drawTarget)

    gr.clearScreen(10, 10, 10, 255)
    gr.setColor(30, 30, 30, 255)

    for _, curr_ship in pairs(ships) do
        if curr_ship.IsSelected then
            local selectedColor = gr_common.team_selected_colors[curr_ship.Team.Name]
            gr.setColor(selectedColor.r, selectedColor.g, selectedColor.b)

            if curr_ship.Team.Name == 'Friendly' then
                gr.drawLine(curr_ship.Position.x, curr_ship.Position.y, mouseX, mouseY)
            end
        else
            gr.setColor(curr_ship.Team:getColor())
        end

        gr_system_map.drawIcon(curr_ship)
    end

    gr.setTarget()
end

return gr_system_map
