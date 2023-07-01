local system_map_drawing = {}

local icon_map = {
    ["Terran"] = {
        ["Fighter"] = {["Texture"] = gr.loadTexture("iconT-fighter", true, true),},
        ["Bomber"] = {["Texture"] = gr.loadTexture("icont-bomber", true, true),},
        ["Cruiser"] = {["Texture"] = gr.loadTexture("icont-cruiser", true, true),},
        ["Corvette"] = {["Texture"] = gr.loadTexture("iconT-vette", true, true),},
        ["Capital"] = {["Texture"] = gr.loadTexture("icont-cap", true, true),},
        ["Super Cap"] = {["Texture"] = gr.loadTexture("icont-super", true, true),},
        ["Transport"] = {["Texture"] = gr.loadTexture("icont-transport", true, true),},
    },
    ["Vasudan"] = {
        ["Fighter"] = {["Texture"] = gr.loadTexture("iconV-fighter", true, true),},
        ["Bomber"] = {["Texture"] = gr.loadTexture("iconv-bomber", true, true),},
        ["Cruiser"] = {["Texture"] = gr.loadTexture("iconv-cruiser", true, true),},
        ["Corvette"] = {["Texture"] = gr.loadTexture("iconV-vette", true, true),},
        ["Capital"] = {["Texture"] = gr.loadTexture("iconv-cap", true, true),},
        ["Transport"] = {["Texture"] = gr.loadTexture("iconv-transport", true, true),},
    },
    ["Shivan"] = {
        ["Fighter"] = {["Texture"] = gr.loadTexture("iconS-fighter", true, true),},
        ["Bomber"] = {["Texture"] = gr.loadTexture("icons-bomber", true, true),},
        ["Cruiser"] = {["Texture"] = gr.loadTexture("icons-cruiser", true, true),},
        ["Corvette"] = {["Texture"] = gr.loadTexture("iconS-vette", true, true),},
        ["Capital"] = {["Texture"] = gr.loadTexture("icons-cap", true, true),},
        ["Super Cap"] = {["Texture"] = gr.loadTexture("icons-super", true, true),},
        ["Transport"] = {["Texture"] = gr.loadTexture("icons-transport", true, true),},
    },
}

local team_selected_colors = {
    ["Friendly"] = {["r"] = 0, ["g"] = 255, ["b"] = 255},
    ["Hostile"] = {["r"] = 255, ["g"] = 255, ["b"] = 0},
}

for species, shipTypes in pairs(icon_map) do
    for type, texInfo in pairs(shipTypes) do
        icon_map[species][type].Height = texInfo.Texture:getHeight()
        icon_map[species][type].Width = texInfo.Texture:getWidth()
    end
end

local getIconName = function(ship)
    if icon_map[ship.Species] and icon_map[ship.Species][ship.Type] then
        return icon_map[ship.Species][ship.Type]
    end

    ba.println("ICON NOT FOUND: " .. ship.Species .. " " .. ship.Type)
    return nil
end

system_map_drawing.camera = nil
system_map_drawing.cam_x = 0.0
system_map_drawing.cam_y = 0.0
system_map_drawing.cam_angle = 0.0
system_map_drawing.cam_dist = 50

function system_map_drawing.drawIcon(ship)
    local iconName = getIconName(ship)
    if iconName then
        gr.drawImageCentered(iconName.Texture, ship.Position.x, ship.Position.y, iconName.Width, iconName.Height, 0, 0, 1, 1, 1, true)
        gr.drawImageCentered(iconName.Texture, ship.Position.x, ship.Position.y, iconName.Width, iconName.Height, 0, 0, 1, 1, 1, true)
    end
end

function system_map_drawing.drawMap(mouseX, mouseY, ships, drawTarget)
    gr.setTarget(drawTarget)

    gr.clearScreen(10, 10, 10, 255)
    gr.setColor(30, 30, 30, 255)

    for si = 1, #ships do
        local curr_ship = ships[si]

        if curr_ship.IsSelected then
            local selectedColor = team_selected_colors[curr_ship.Team.Name]
            gr.setColor(selectedColor.r, selectedColor.g, selectedColor.b)
            gr.drawLine(curr_ship.Position.x, curr_ship.Position.y, mouseX, mouseY)--, curr_ship.Name)
        else
            gr.setColor(curr_ship.Team:getColor())
        end

        system_map_drawing.drawIcon(curr_ship)
    end

    gr.setTarget()
end

return system_map_drawing
