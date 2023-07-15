local gr_common = {}

gr_common.icon_map = {
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

for species, shipTypes in pairs(gr_common.icon_map) do
    for type, texInfo in pairs(shipTypes) do
        gr_common.icon_map[species][type].Height = texInfo.Texture:getHeight()
        gr_common.icon_map[species][type].Width  = texInfo.Texture:getWidth()
        gr_common.icon_map[species][type].Url    = ui.linkTexture(gr_common.icon_map[species][type].Texture)
    end
end

gr_common.team_selected_colors = {
    ["Friendly"] = {["r"] = 0, ["g"] = 255, ["b"] = 255},
    ["Hostile"] = {["r"] = 255, ["g"] = 255, ["b"] = 0},
}

function gr_common.getIconForShip(ship)
    if gr_common.icon_map[ship.Species] and gr_common.icon_map[ship.Species][ship.Type] then
        return gr_common.icon_map[ship.Species][ship.Type]
    end

    ba.println("ICON NOT FOUND: " .. ship.Species .. " " .. ship.Type)
    return nil
end

return gr_common