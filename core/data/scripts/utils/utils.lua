local Utils = {}

Utils.DateTime = {}
Utils.Game = {}
Utils.Math = {}
Utils.Table = {}

function Utils.stripExtension(name)
    return string.gsub(name, "%..+$", "")
end

function Utils.split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function Utils.loadConfig(filename)
  -- Load the config file.
  local file = cf.openFile(filename, 'r', 'data/config')
  local config = require('dkjson').decode(file:read('*a'))
  file:close()
  if not config then
    ba.error('Please ensure that ' .. filename .. ' exists in data/config and is valid JSON.')
  end
  return config
end

function Utils.xstr(message)
  if type(message) == 'string' then
    ba.print('SCPUI: Got string with missing XSTR index: ' .. message .. "\n")
    return message
  else
    return ba.XSTR(message[1], message[2])
  end
end

--- find_first
---@param str string
---@param patterns string[]
---@param startIdx number
---
function Utils.findFirstEither(str, patterns, startIdx)
    local firstResult = nil
    for i, v in ipairs(patterns) do
        local values = { str:find(v, startIdx) }

        if values[1] ~= nil then
            if firstResult == nil then
                firstResult = values
            elseif values[1] < firstResult[1] then
                firstResult = values
            end
        end
    end

    if firstResult == nil then
        return nil
    else
        return unpack(firstResult)
    end
end

---
--- @param inputStr string
--- @return string
function Utils.rmlEscape(inputStr)
    return inputStr:gsub('[<>&"]', function(char)
        if char == "<" then
            return "&lt;"
        end

        if char == ">" then
            return "&gt;"
        end

        if char == "&" then
            return "&amp;"
        end

        if char == "\"" then
            return "&quot;"
        end
    end)
end

function Utils.Table.ifind(tbl, val, compare)
    for i, v in ipairs(tbl) do
        if compare ~= nil then
            if compare(v, val) then
                return i
            end
        else
            if v == val then
                return i
            end
        end
    end

    return -1
end

function Utils.Table.find(tbl, val, compare)
    for i, v in pairs(tbl) do
        if compare ~= nil then
            if compare(v, val) then
                return i
            end
        else
            if v == val then
                return i
            end
        end
    end

    return nil
end

function Utils.Table.contains(tbl, val, compare)
    return Utils.Table.find(tbl, val, compare) ~= nil
end

function Utils.Table.iremoveEl(tbl, val, compare)
    local i = Utils.Table.ifind(tbl, val, compare)
    if i >= 1 then
        table.remove(tbl, i)
    end
    return i
end

--- Maps an input array using a function
--- @generic T
--- @generic V
--- @param tbl T[]
--- @param map_fun fun(el:T):V
--- @return V[]
function Utils.Table.map(tbl, map_fun)
    local out = {}
    for i, v in ipairs(tbl) do
        out[i] = map_fun(v)
    end
    return out
end

--- Reduces an associative table to a single value
--- @generic T
--- @generic V
--- @param tbl T[] The table to reduce
--- @param reduceFn fun(accumulator: V, el: T):V
--- @param initial V Initial value to use
--- @return V The final value after all elements have been looked at
function Utils.Table.areduce(tbl, reduceFn, initial)
    local acc = initial
    for _, v in pairs(tbl) do
        acc = reduceFn(acc, v)
    end
    return acc
end

--- Reduces a list of values to a single value
--- @generic T
--- @generic V
--- @param tbl T[] The table to reduce
--- @param reduceFn fun(accumulator: V, el: T):V
--- @param initial V Initial value to use
--- @return V The final value after all elements have been looked at
function Utils.Table.reduce(tbl, reduceFn, initial)
    local acc = initial
    for _, v in ipairs(tbl) do
        acc = reduceFn(acc, v)
    end
    return acc
end

--- Computes the sum of the specified table
--- @param tbl number[]
--- @return number
function Utils.Table.sum(tbl)
    return Utils.Table.reduce(tbl, function(sum, el)
        return sum + el
    end, 0)
end

--- Computes the sum of the specified table
--- @generic T
--- @param tbl T[]
--- @return T[]
function Utils.Table.copy(tbl)
    local orig_type = type(tbl)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, tbl, nil do
            copy[orig_key] = Utils.Table.copy(orig_value)
        end
        setmetatable(copy, Utils.Table.copy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = tbl
    end
    return copy
end

function Utils.DateTime.parse(datetime_string)
    local inYear, inMonth, inDay, inHour, inMinute, inSecond, inZone =
    string.match(datetime_string, '^(%d%d%d%d)-(%d%d)-(%d%d)T(%d%d):(%d%d):(%d%d)(.-)$')

    return os.time({year=inYear, month=inMonth, day=inDay, hour=inHour, min=inMinute, sec=inSecond, isdst=false})
end

function Utils.Game.getMandatoryProperty(properties, prop_name)
    if not properties[prop_name] then ba.error(prop_name .. " is required:" .. "\n\n" .. debug.traceback()) end
    return properties[prop_name]
end

local ship_type_scores = {
    ["Wing"] = 1,
    ["Cruiser"] = 2,
    ["Transport"] = 2,
    ["Corvette"] = 3,
    ["Capital"] = 4,
}

function Utils.Game.getShipScore(ship)
    return ship_type_scores[ship.Type]
end

function Utils.Math.isInsideBox(point, box_start, box_end)
    return (point.x > box_start.x and point.y > box_start.y and point.x < box_end.x and point.y < box_end.y)
end

function Utils.Math.lerp(a, b, f)
    return a + f * (b - a)
end

function Utils.Math.clamp(value, min, max)
    return math.min(max, math.max(min, value))
end

Utils.Math.AU = 149597870700.0
Utils.Math.GravConst = 6.67384e-11
Utils.Math.PITwo = math.pi*2

function Utils.Math.orbitalPeriod(semiMajorAxis, mass)
    return Utils.Math.PITwo * math.sqrt(math.pow(semiMajorAxis, 3) / (Utils.Math.GravConst * mass));
end

function Utils.Math.orbitalVelocity(semiMajorAxis, mass)
    return Utils.Math.PITwo * semiMajorAxis / Utils.Math.orbitalPeriod(semiMajorAxis, mass)
end

function Utils.Math.escapeVelocity(semiMajorAxis, mass)
    return math.sqrt(2 * Utils.Math.GravConst * mass / semiMajorAxis)
end

function Utils.Math.hasEscapedFromOrbit(semi_major_obj, semi_major_par, mass_par, mass_par_par)
    local esc_velocity = Utils.Math.escapeVelocity(semi_major_obj, mass_par)
    local orb_velocity = Utils.Math.orbitalVelocity(semi_major_par, mass_par_par)
    orb_velocity = orb_velocity - Utils.Math.orbitalVelocity(semi_major_par + semi_major_obj, mass_par_par)
    orb_velocity = orb_velocity + Utils.Math.orbitalVelocity(semi_major_obj, mass_par)

    return ( orb_velocity > esc_velocity )
end

--- Returns a random number within the given range
--- @param min number @The lowest number that can be generated
--- @param max number @The highest number that can be generated
--- @return number @A random number within the given range
function Utils.Math.randomBetween(min, max)
    return min + math.random()  * (max - min)
end

--- Randomly returns 1 or -1
--- @return number @1 or -1
function Utils.Math.randomSign()
    return (math.random(2) % 2 == 0 and -1 or 1)
end

function Utils.Math.deviateFromAbs(value, min_abs, max_abs)
    return Utils.Math.deviateFromPct(value, min_abs / value, max_abs / value)
end

function Utils.Math.deviateFromPct(value, min_pct, max_pct)
    local deviation = Utils.Math.randomBetween(min_pct, max_pct) * Utils.Math.randomSign()

    return value + value * deviation
end

--- Calculates the distance between two points given in polar coordinates
--- @param r1 number @The distance polar coordinate of the first point
--- @param a1 number @The angle polar coordinate of the first point
--- @param r2 number @The distance polar coordinate of the second point
--- @param a2 number @The angle polar coordinate of the second point
--- @return number @The distance between two points
function Utils.Math.polarDistance(r1, a1, r2, a2)
    return math.sqrt(r1*r1 + r2*r2 - 2*r1*r2*math.cos(a2-a1))
end

--- Calculates the angle that will result in a provided distance, for 2 points in polar coordinates
--- @param dist number @The desired distance if the first point uses the returned angle
--- @param r1 number @The distance polar coordinate of the first point (with an unknown angle)
--- @param r2 number @The distance polar coordinate of the second point
--- @param a2 number @The angle polar coordinate of the second point
--- @return number @The angle that will result in the provided distance
function Utils.Math.angleForDistance(dist, r1, r2, a2)
    -- dist = math.sqrt(r1*r1 + r2*r2 - 2*r1*r2*math.cos(a2-a1))
    -- dist^2 = r1*r1 + r2*r2 - 2*r1*r2*math.cos(a2-a1)
    -- 2*r1*r2*math.cos(a2-a1) = r1*r1 + r2*r2 - dist^2
    -- math.cos(a2-a1) = (r1*r1 + r2*r2 - dist^2) / (2*r1*r2)
    -- a2-a1 = math.acos((r1*r1 + r2*r2 - dist^2) / (2*r1*r2))
    -- a1 = a2 - math.acos((r1*r1 + r2*r2 - dist^2) / (2*r1*r2))
    local cosA = (r1*r1 + r2*r2 - dist^2) / (2*r1*r2)
    if cosA > 1 or cosA < -1 then
        ba.error("Utils.Math.angleForDistance: cosA outside of [-1; 1] bounds - " .. cosA)
    end

    return a2 - (math.acos(cosA) * Utils.Math.randomSign())
end

--- Calculates the angle that will result in a provided distance, for 2 points in polar coordinates
--- @param min_dist number @The minimum desired distance if the first point uses the returned angle
--- @param max_dist number @The maximum desired distance if the first point uses the returned angle
--- @param r1 number @The distance polar coordinate of the first point (with an unknown angle)
--- @param r2 number @The distance polar coordinate of the second point
--- @param a2 number @The angle polar coordinate of the second point
--- @return number @The angle that will result in the provided distance
function Utils.Math.angleRangeForDistance(min_dist, max_dist, r1, r2, a2)
    local min_a = Utils.Math.angleForDistance(min_dist, r1, r2, a2)
    local max_a = Utils.Math.angleForDistance(max_dist, r1, r2, a2)

    return Utils.Math.randomBetween(min_a, max_a)
end

return Utils
