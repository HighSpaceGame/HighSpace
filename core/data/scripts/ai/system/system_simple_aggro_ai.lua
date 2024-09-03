local Class           = require("class")
local Ship            = require("ship")
local SystemAI        = require("system_ai")
local Utils           = require('utils')

--- Symple System Map AI that chases the ship that generated the most Aggro
--- @class SystemSimpleAggroAI
local SystemSimpleAggroAI = Class(SystemAI)

--- Initialize object
--- @param ship Ship
function SystemSimpleAggroAI:init(ship)
    self.Ship = ship
    self.Aggro = {}
    self._highest_aggro = nil

    local playerShip = GameState.System:get("Taganrog").Parent
    self.Aggro[playerShip.Name] = { ["Ship"] = playerShip, ["Level"] = 50 }
end

function SystemSimpleAggroAI:aggroLevel(aggroInfo)
    if not aggroInfo then aggroInfo = self._highest_aggro end
    if not aggroInfo then return 0 end

    local distance = (aggroInfo.Ship.System.Position - self.Ship.System.Position):getMagnitude() / Utils.Math.AU
    return aggroInfo.Level / distance
end

function SystemSimpleAggroAI:update()
    self._highest_aggro = Utils.Table.areduce(self.Aggro, function(acc, el)
        return (not acc or self:aggroLevel(el) > self:aggroLevel(acc)) and el or acc
    end, nil)

    if not self._highest_aggro then return end

    local level = self:aggroLevel()
    if level < 100 then return end

    self.Ship.System.Destination = { ["Position"] = self._highest_aggro.Ship.System.Position - self._highest_aggro.Ship.Parent.System.Position }
    self.Ship.System.Destination.Parent = self._highest_aggro.Ship.Parent
    self.Ship.System.IsInSubspace = true
end

--- React to a ShipGroup splitting
--- @param group ShipGroup
--- @param ship Ship
function SystemSimpleAggroAI:onShipGroupSplit(group, ship)
    if not self.Aggro[group.Name] then return end

    self.Aggro[ship.Name] = { ["Ship"] = ship, ["Level"] = self.Aggro[group.Name].Level }
    if group.Ships:count() <= 0 then
        self.Aggro[group.Name] = nil
    end
end

--- React to a ShipGroupMerge event
--- @param ship1 Ship
--- @param ship2 Ship
--- @param group ShipGroup
function SystemSimpleAggroAI:onShipGroupMerge(ship1, ship2, group)
    local max_aggro = self.Aggro[ship1.Name] and self.Aggro[ship1.Name].Level or 0
    max_aggro = math.max(max_aggro, self.Aggro[ship2.Name] and self.Aggro[ship2.Name].Level or 0)

    self.Aggro[ship1.Name] = nil
    self.Aggro[ship2.Name] = nil
    self.Aggro[group.Name] = { ["Ship"] = group, ["Level"] = max_aggro }
end

--- React to a onShipDeath event
--- @param ship1 Ship
--- @param ship2 Ship
--- @param group ShipGroup
function SystemSimpleAggroAI:onShipDeath(died, killer)
    while killer.Parent and killer.Parent:is_a(Ship) do
        killer = killer.Parent
    end

    if not (self.Aggro[killer.Name]) then
        self.Aggro[killer.Name] = { ["Ship"] = killer, ["Level"] = 0 }
    end

    self.Aggro[killer.Name].Level = self.Aggro[killer.Name].Level + Utils.Game.getShipScore(died)
end

return SystemSimpleAggroAI