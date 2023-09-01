local Utils = {}

Utils.Table = {}
Utils.Math = {}
Utils.Game = {}

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

function Utils.Math.isInsideBox(point, box_start, box_end)
    return (point.X > box_start.X and point.Y > box_start.Y and point.X < box_end.X and point.Y < box_end.Y)
end

function Utils.Math.lerp(a, b, f)
    return a + f * (b - a)
end

function Utils.Game.getMandatoryProperty(properties, prop_name)
    if not properties[prop_name] then ba.error("Ship:init - " .. prop_name .. " is required") end
    return properties[prop_name]
end

return Utils
