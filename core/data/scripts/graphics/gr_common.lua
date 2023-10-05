local GrCommon = {}

GrCommon.TeamSelectedColors = {
    ["Friendly"] = function() return 0, 255, 255, 255 end,
    ["Hostile"] = function() return 255, 255, 0, 255 end,
}

function GrCommon.loadTexture(filename, link)
    local texInfo = { ["Texture"] = gr.loadTexture(filename, true, true) }
    texInfo.Height = texInfo.Texture:getHeight()
    texInfo.Width  = texInfo.Texture:getWidth()

    if link then
        texInfo.Url    = ui.linkTexture(texInfo.Texture)
    end

    return texInfo
end

GrCommon.WaypointIcon = GrCommon.loadTexture("waypoint", true)
GrCommon.TargetIcon =  GrCommon.loadTexture("target", true)

return GrCommon