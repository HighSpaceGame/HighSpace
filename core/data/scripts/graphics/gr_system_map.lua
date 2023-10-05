local gr_common                          = require('gr_common')
local Inspect                            = require('inspect')
local Ship                               = require('ship')
local ShipGroup                          = require('ship_group')
local Utils                              = require('utils')
local Vector                             = require('vector')

local gr_system_map = {}

local function drawTexture(texture, text, screen_position, width, height)
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

local function drawAstral(body)
    --ba.println("gr_system_map.drawSystem(system): " .. Inspect(system.Stars))
    local screen_size = body.Radius / GameSystemMap.Camera.Zoom * 2
    local screen_position = GameSystemMap.Camera:getScreenCoords(body.System.Position)
    local alpha = 255

    if body.Parent then
        local parent_screen_position = GameSystemMap.Camera:getScreenCoords(body.Parent.System.Position)
        local screen_position_diff = (parent_screen_position - screen_position):getMagnitude()
        alpha = math.min(screen_position_diff / 30, 1.0)
        alpha = 1.0 - (1.0 - alpha)*2
        alpha = math.max(255 * math.min(screen_size, 10) / 10, 128) * alpha

        if screen_position_diff < 20000 then
            if screen_position_diff < 4 then
                return
            end

            local orbit_alpha = Utils.Math.lerp(128, 0, math.max((screen_position_diff - 10000) / 10000, 0.0))
            --ba.println("gr_system:drawAstral: " .. Inspect({body.Name, orbit_alpha, screen_position_diff}))
            gr.setColor(255, 255, 255, orbit_alpha)
            gr.drawCircle(screen_position_diff, parent_screen_position.x, parent_screen_position.y, false)
        end
    end

    if GameSystemMap.Camera:isOnScreen(screen_position, 2000) then
        gr.setColor(255, 255, 255, alpha)
        gr.CurrentFont = gr.Fonts["font01"]
        screen_size = math.max(screen_size, 10)
        drawTexture(body.Icon.Texture, body.Name, screen_position, screen_size, screen_size)
    end
end

local function drawClusterShip(obj_idx, object, obj_count, screen_position, rel_screen_position)
    local icon = object:getIcon()
    local icon_width, icon_height = icon.Width, icon.Height
    local text = object:getMapDisplayName()

    if obj_count > 1 then
        --TODO: different text for different object types?
        text =  obj_count .. " ships"
        if obj_idx > 1 then
            text = ""
            rel_screen_position:rotate(0, math.rad(360 / obj_count), 0)
        end

        icon_width, icon_height = icon_width/4, icon_height/4
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

function gr_system_map:drawCluster(cluster)
    for group_name, object_group in pairs(cluster.Groups) do
        local rel_screen_position = Vector(0, -15)
        local screen_position = GameSystemMap.Camera:getScreenCoords(object_group.AvgPosition)
        for obj_idx, object in ipairs(object_group.Objects) do
            if object:is_a(ShipGroup) or object:is_a(Ship) then
                --ba.println("ships_screen_map:drawMap clusterShip: " .. Inspect({group_name, obj_idx, object.Name, screen_position.x, screen_position.y, cluster.AvgPosition.x, cluster.AvgPosition.y}))
                drawClusterShip(obj_idx, object, #object_group.Objects, screen_position, rel_screen_position)
            else
                drawAstral(object)
            end
        end
    end
end

function gr_system_map.drawMap(mousePos, drawTarget)
    gr.setTarget(drawTarget)

    gr.clearScreen(10, 10, 10, 255)
    gr.setColor(30, 30, 30, 255)

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

    local screen_objects = GameSystemMap.ObjectKDTree:findObjectsWithin(
            GameSystemMap.Camera.Position,
            2000 * GameSystemMap.Camera.Zoom,
            40 * GameSystemMap.Camera.Zoom,
            nil,
            'Category'
    )

    for cidx, cluster in ipairs(screen_objects) do
        --ba.println("ships_screen_map:drawMap cluster: " .. Inspect({cidx, #cluster.Objects.All, cluster.Objects.All[1].Name}))
        gr_system_map:drawCluster(cluster)
    end

    --GameSystemMap.ObjectKDTree:draw() -- TODO: for debugging, do not commit uncommented
    gr.setTarget()
end

return gr_system_map
