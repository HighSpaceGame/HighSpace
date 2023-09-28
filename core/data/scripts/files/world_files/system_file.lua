local Class       = require("class")
local Inspect     = require("inspect")
local Json        = require("dkjson")
local StarSystem  = require('star_system')
local Utils       = require('utils')

local SystemFile = Class()

function SystemFile:loadSystem(filename)
    local system_file = cf.openFile(filename, "r", "data/config")
    if not system_file:isValid() then
        ba.error("Could not open system file: " .. filename)
        return
    end

    local system_data = Json.decode(system_file:read("*a"))

    ba.println("loadSystem: " .. Inspect({ system_data }))

    system_file:close()

    return StarSystem(system_data.StarSystem)
end

return SystemFile