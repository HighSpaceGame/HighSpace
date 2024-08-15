local Class       = require("class")
local Inspect     = require("inspect")
local Json        = require("dkjson")
local Ship        = require("ship")
local ShipGroup   = require("ship_group")
local StarSystem  = require('star_system')
local Utils       = require('utils')
local Wing        = require("wing")

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

    local system = StarSystem(system_data.StarSystem)
    GameState.System = system
    system:forEach(function(astral)
        astral:update()
    end, "Astral")

    self:loadShips(system, system_data.Ships)

    return system
end

local ship_init_func = function(data) return Ship(data) end
local ship_initializers

ship_initializers = {
    ["Ship"] = ship_init_func,
    ["Fighter"] = ship_init_func,
    ["Bomber"] = ship_init_func,
    ["Transport"] = ship_init_func,
    ["Cruiser"] = ship_init_func,
    ["Capital"] = ship_init_func,
    ["Group"] = function(data)
        local ships = {}
        for _, ship_data in pairs(data.Ships) do
            table.insert(ships, ship_initializers[ship_data.Type](ship_data))
        end

        data.Ships = ships
        return ShipGroup(data)
    end,
    ["Wing"] = function(data)
        local ships = {}
        for _, ship_data in pairs(data.Ships) do
            table.insert(ships, ship_initializers[ship_data.Type](ship_data))
        end

        data.Ships = ships
        return Wing(data)
    end
}

function SystemFile:loadShips(system, ships_data)
    local neutrals = {}
    for _, ship_data in pairs(ships_data) do
        if ship_data.Team ~= "Hostile" then
            ba.println("Adding: " .. Inspect({ ship_data.Name }))
            local ship = ship_initializers[ship_data.Type](ship_data)

            if ship.Type == "Group" and ship:getTopShip().Name == "Taganrog" then
                ship.SemiMajorAxis = Utils.Math.AU * 50
                ship.MeanAnomalyEpoch = math.random() * 360
                system:get("Sol"):add(ship)
            else
                GameMapGenerator.addShipToRandomOrbit(ship, system)
            end

            if ship.Team.Name == "Unknown" then
                table.insert(neutrals, ship)
            end
        end
    end

    for _, ship_data in pairs(ships_data) do
        if ship_data.Team == "Hostile" then
            ba.println("Adding: " .. Inspect({ ship_data.Name }))

            local ship = ship_initializers[ship_data.Type](ship_data)
            GameMapGenerator.chaseRandomShip(ship, neutrals)
        end
    end
end

return SystemFile