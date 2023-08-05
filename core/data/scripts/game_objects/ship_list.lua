local Class     = require("class")
local Inspect   = require('inspect')
local Utils     = require('utils')

local ShipList = Class()

function ShipList:init(properties)
    self._list = {}
end

function ShipList:clear()
    self._list = {}
end

function ShipList:add(ship)
    self._list[ship.Name] = ship
end

function ShipList:remove(ship_name)
    self._list[ship_name] = nil
end

function ShipList:get(ship_name)
    return self._list[ship_name]
end

function ShipList:forEach(callback)
    for _, ship in pairs(self._list) do
        local ret = callback(ship)

        if ret ~= nil and ret == false then
            break
        end
    end
end

return ShipList