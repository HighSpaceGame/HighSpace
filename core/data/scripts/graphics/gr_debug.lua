local Class                     = require("class")

local gr_debug = Class()

function gr_debug:drawAggro()
    for _, ai in pairs(AIController._system_ais) do
        local screen_position = GameSystemMap.Camera:getScreenCoords(ai.Ship.System.Position)

        local text = "Aggro: " .. ai:aggroLevel() .. " - " .. ai._highest_aggro.Ship.Name .. " - " .. ai._highest_aggro.Level
        local text_width = gr.getStringWidth(text)
        local r,g,b = ai.Ship.Team:getColor()
        gr.setColor(r,g,b)
        gr.drawString(
                text,
                screen_position.x - text_width/2,
                screen_position.y + 24
        )

        -- gr.drawCircle(screen_position_diff, parent_screen_position.x, parent_screen_position.y, false)
    end
end

return gr_debug