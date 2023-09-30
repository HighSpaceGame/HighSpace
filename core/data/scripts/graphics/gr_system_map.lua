local gr_common                          = require('gr_common')
local Inspect                            = require('inspect')
local Utils                              = require('utils')
local Vector                             = require('vector')

local gr_system_map = {}

local drawTexture = function(texture, text, screen_position, width, height)
    --ba.println("gr_system_map.drawTexture(texture, world_position): " .. Inspect({ screen_position.x, screen_position.y }))
    gr.drawImageCentered(texture, screen_position.x, screen_position.y, width, height, 0, 0, 1, 1, 1, true)

    if text then
        local text_width = gr.getStringWidth(text)
        gr.drawString(
                text,
                screen_position.x - text_width/2,
                screen_position.y - height - gr.CurrentFont.Height - 12
        )
    end
end

function gr_system_map.drawSystem(body, parent)
    --ba.println("gr_system_map.drawSystem(system): " .. Inspect(system.Stars))
    local screen_size = body.Radius / GameSystemMap.Camera.Zoom * 2
    local screen_position = GameSystemMap.Camera:getScreenCoords(body.System.Position)
    local alpha = 255

    if parent then
        local parent_screen_position = GameSystemMap.Camera:getScreenCoords(parent.System.Position)
        local screen_position_diff = (parent_screen_position - screen_position):getMagnitude()
        alpha = math.min(screen_position_diff / 30, 1.0)
        alpha = 1.0 - (1.0 - alpha)*2
        alpha = math.max(255 * math.min(screen_size, 10) / 10, 128) * alpha

        if screen_position_diff < 20000 then
            if screen_position_diff < 4 then
                return
            end

            local orbit_alpha = Utils.Math.lerp(128, 0, math.max((screen_position_diff - 10000) / 10000, 0.0))
            gr.setColor(255, 255, 255, orbit_alpha)
            gr.drawCircle(screen_position_diff, parent_screen_position.x, parent_screen_position.y, false)
        end
    end

    if GameSystemMap.Camera:isOnScreen(screen_position, 2000) then
        gr.setColor(255, 255, 255, alpha)
        gr.CurrentFont = gr.Fonts["font01"]
        screen_size = math.max(screen_size, 10)
        drawTexture(body.Icon, body.Name, screen_position, screen_size, screen_size)
    end

    if not body.Satellites then
        return
    end

    for _, satellite in pairs(body.Satellites) do
        gr_system_map.drawSystem(satellite, body)
    end
end

function gr_system_map:drawCluster(cluster)
    local rel_screen_position = Vector(0, -15)
    for obj_idx, object in ipairs(cluster.Objects) do
        local icon = gr_common.getIconForShip(object)
        if icon then
            local icon_width, icon_height = icon.Width, icon.Height
            local text = object:getMapDisplayName()
            local screen_position = GameSystemMap.Camera:getScreenCoords(cluster.AvgPosition)

            if #cluster.Objects > 1 then
                --TODO: different text for different object types?
                text =  #cluster.Objects .. " ships"
                if obj_idx > 1 then
                    text = ""
                    rel_screen_position:rotate(0, math.rad(360 / #cluster.Objects), 0)
                end

                icon_width, icon_height = icon.Width/4, icon.Height/4
                screen_position = screen_position + rel_screen_position
            end

            --ba.println("ships_screen_map:drawCluster: " .. Inspect({rel_screen_position, screen_position}))
            gr.setColor(object.Team:getColor())
            if object.IsSelected then
                local selected_color = gr_common.TeamSelectedColors[object.Team.Name]
                gr.setColor(selected_color.R, selected_color.G, selected_color.B)
            end

            --ba.println("ships_screen_map:draw: " .. Inspect({ship.Name, GameSystemMap.Camera.ScreenOffset.x, GameSystemMap.Camera.ScreenOffset.y, screen_position.x, screen_position.y, screen_sector.x, screen_sector.y}))
            drawTexture(icon.Texture, text, screen_position, icon_width, icon_height)
        end
    end
end

function gr_system_map.drawMap(mousePos, drawTarget)
    gr.setTarget(drawTarget)

    gr.clearScreen(10, 10, 10, 255)
    gr.setColor(30, 30, 30, 255)

    for _, star in pairs(GameSystemMap.System.Stars) do
        gr_system_map.drawSystem(star)
    end

    if GameSystemMap.SelectedShip and GameSystemMap.SelectedShip.Team.Name == 'Friendly' then
        local screen_position = GameSystemMap.Camera:getScreenCoords(GameSystemMap.SelectedShip.System.Position)
        local color = gr_common.TeamSelectedColors[GameSystemMap.SelectedShip.Team.Name]

        if not GameSystemMap.Camera:isOnScreen(screen_position) then
            screen_position = screen_position - mousePos
            screen_position = screen_position:normalize() * 2000
            screen_position = screen_position + mousePos
        end

        gr.setColor(color.R, color.G, color.B)
        gr.drawLine(screen_position.x, screen_position.y, mousePos.x, mousePos.y)
    end

    local screen_objects = GameSystemMap.ObjectKDTree:findObjectsWithin(GameSystemMap.Camera.Position, math.pow(2000 * GameSystemMap.Camera.Zoom,2), math.pow(40 * GameSystemMap.Camera.Zoom,2))

    for _, cluster in pairs(screen_objects) do
        --ba.println("ships_screen_map:drawMap ship: " .. Inspect({cluster.AvgPosition.x, cluster.AvgPosition.y, #cluster.Objects, cluster.Objects[1].Name}))
        gr_system_map:drawCluster(cluster)
    end


    --gr.drawCircle(10, 500, 280)
    --GameSystemMap.ObjectKDTree:draw() -- for debugging
    gr.setTarget()
end

return gr_system_map
