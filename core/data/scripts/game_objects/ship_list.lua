local Class     = require("class")
local Inspect   = require('inspect')
local Utils     = require('utils')

local ShipList = Class()

function ShipList:init(properties)
    self._list = {}
    self._count = 0
end

function ShipList:clear()
    self._list = {}
    self._count = 0
end

function ShipList:add(ship)
    self._list[ship.Name] = ship
    self._count = self._count + 1
end

function ShipList:remove(ship)
    if self._list[ship.Name] then
        self._list[ship.Name] = nil
        self._count = self._count - 1
    end
end

function ShipList:get(ship_name)
    return self._list[ship_name]
end

function ShipList:count()
    return self._count
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