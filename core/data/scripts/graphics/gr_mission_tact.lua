local inspect                            = require('inspect')

local gr_mission_tact = {}

function gr_mission_tact.drawSelection(from, mouseState)
    --ba.println("drawSelection: " .. inspect(mouseState))
    if mouseState.buttons[0] and from then
        gr.setColor(0, 255, 0, 255)
        gr.drawRectangle(from.x, from.y, mouseState.x, mouseState.y, false)
    end
end

return gr_mission_tact
