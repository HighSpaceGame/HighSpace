local utils = {}

utils.table = {}

function utils.loadOptionsFromFile()

	local json = require('dkjson')
  
	local location = 'data/players'
  
	local file = nil
	local config = {}
  
	if cf.fileExists('scpui_options.cfg') then
		file = cf.openFile('scpui_options.cfg', 'r', location)
		config = json.decode(file:read('*a'))
		file:close()
		if not config then
			config = {}
		end
	end
  
	if not config[ba.getCurrentPlayer():getName()] then
		config[ba.getCurrentPlayer():getName()] = {}
	end
	
	local mod = ba.getModTitle()
	
	if mod == "" then
		ba.error("SCPUI requires the current mod have a title in game_settings.tbl!")
	end
	
	if not config[ba.getCurrentPlayer():getName()][mod] then
		return nil
	else
		return config[ba.getCurrentPlayer():getName()][mod]
	end
end

function utils.saveOptionsToFile(data)

	local json = require('dkjson')
  
	local location = 'data/players'
  
	local file = nil
	local config = {}
  
	if cf.fileExists('scpui_options.cfg') then
		file = cf.openFile('scpui_options.cfg', 'r', location)
		config = json.decode(file:read('*a'))
		file:close()
		if not config then
			config = {}
		end
	end
  
	if not config[ba.getCurrentPlayer():getName()] then
		config[ba.getCurrentPlayer():getName()] = {}
	end
	
	local mod = ba.getModTitle()
	
	if mod == "" then
		ba.error("SCPUI requires the current mod have a title in game_settings.tbl!")
	end
	
	config[ba.getCurrentPlayer():getName()][mod] = data
	
	config = utils.cleanPilotsFromSaveData(config)
  
	file = cf.openFile('scpui_options.cfg', 'w', location)
	file:write(json.encode(config))
	file:close()
end

function utils.cleanPilotsFromSaveData(data)
	
	--get the pilots list
	local pilots = ui.PilotSelect.enumeratePilots()
	
	local cleanData = {}
	
	-- for each existing pilot, keep the data
	for _, v in ipairs(pilots) do
		if data[v] ~= nil then
			cleanData[v] = data[v]
		end
    end

	return cleanData
end

function utils.parseOptions(data)

	parse.readFileText(data, "data/tables")

	parse.requiredString("#Custom Options")
	
	while parse.optionalString("$Name:") do
		local entry = {}
		
		entry.Title = parse.getString()
		
		if parse.optionalString("+Description:") then
			entry.Description = parse.getString()
		end
		
		parse.requiredString("+Key:")
		entry.Key = parse.getString()
		--Create warning if Key already exists for another option here
		
		parse.requiredString("+Type:")
		entry.Type = utils.verifyParsedType(parse.getString())
		
		if parse.optionalString("+Column:") then
			entry.Column = parse.getInt()
			if entry.Column < 1 then
				entry.Column = 1
			end
			if entry.Column > 4 then
				entry.Column = 4
			end
		else
			entry.Column = 1
		end
		
		if entry.Type ~= "Header" then
		
			local valCount = 0
			local nameCount = 0
		
			if entry.Type == "Binary" or entry.Type == "Multi" then
				parse.requiredString("+Valid Values")
				
				entry.ValidValues = {}
				
				while parse.optionalString("+Val:") do
					local val = parse.getString()
					local save = true
					
					if val ~= nil then
						valCount = valCount + 1
						if entry.Type == "Binary" and valCount > 2 then
							parse.displayMessage("Option " .. entry.Title .. " is Binary but has more than 2 values. The rest will be ignored!", false)
							save = false
						end
						
						if entry.Type == "FivePoint" and valCount > 5 then
							parse.displayMessage("Option " .. entry.Title .. " is FivePoint but has more than 5 values. The rest will be ignored!", false)
							save = false
						end
						
						if save then
							entry.ValidValues[valCount] = val
						end
					end
				end
				
				if entry.Type == "Binary" and valCount < 2 then
					parse.displayMessage("Option " .. entry.Title .. " is Binary but only has " .. valCount .. "values! Binary types must have exactly 2 values.", true)
				end
				
				if entry.Type == "Multi" and valCount < 2 then
					parse.displayMessage("Option " .. entry.Title .. " is Multi but only has " .. valCount .. "values! Multi types must have at least 2 values.", true)
				end
				
				if entry.Type == "FivePoint" and valCount < 5 then
					parse.displayMessage("Option " .. entry.Title .. " is FivePoint but only has " .. valCount .. "values! FivePoint types must have exactly 5 values.", true)
				end
				
			end
				
			if entry.Type == "Binary" or entry.Type == "Multi" or entry.Type == "FivePoint" then
			
				parse.requiredString("+Display Names")
				
				entry.DisplayNames = {}
				
				while parse.optionalString("+Val:") do
					local val = parse.getString()
					local save = true
					
					if val ~= nil then
						nameCount = nameCount + 1
						if entry.Type == "Binary" and nameCount > 2 then
							parse.displayMessage("Option " .. entry.Title .. " is Binary but has more than 2 display names. The rest will be ignored!", false)
							save = false
						end
						
						if entry.Type == "FivePoint" and nameCount > 5 then
							parse.displayMessage("Option " .. entry.Title .. " is FivePoint but has more than 5 display names. The rest will be ignored!", false)
							save = false
						end
						
						if save then
							if entry.Type == "FivePoint" then
								entry.DisplayNames[nameCount] = val
							else
								entry.DisplayNames[entry.ValidValues[nameCount]] = val
							end
						end
					end
				end
				
				if entry.Type == "Binary" and nameCount < 2 then
					parse.displayMessage("Option " .. entry.Title .. " is Binary but only has " .. nameCount .. "display names! Binary types must have exactly 2 display names.", true)
				end
				
				if entry.Type == "Multi" and nameCount < 2 then
					parse.displayMessage("Option " .. entry.Title .. " is Multi but only has " .. nameCount .. "display names! Multi types must have at least 2 display names.", true)
				end
				
				if entry.Type == "FivePoint" and nameCount < 5 then
					parse.displayMessage("Option " .. entry.Title .. " is FivePoint but only has " .. nameCount .. "display names! FivePoint types must have exactly 5 display names.", true)
				end
				
				if entry.Type ~= "FivePoint" and valCount ~= nameCount then
					parse.displayMessage("Option " .. entry.Title .. " has " .. valCount .. " values but only has " .. nameCount .. " display names. There must be one display name for each value!", true)
				end
			end
			
			if entry.Type == "Range" then
				parse.requiredString("+Min:")
				entry.Min = parse.getFloat()
				
				if entry.Min < 0 then
					entry.Min = 0
				end
				
				parse.requiredString("+Max:")
				entry.Max = parse.getFloat()
				
				if entry.Max <= entry.Min then
					parse.displayMessage("Option " .. entry.Title .. " has a Max value that is less than or equal to its Min value!", true)
				end
			end
			
			parse.requiredString("+Default Value:")
			if entry.Type == "Binary" or entry.Type == "Multi" then
				entry.Value = parse.getString()
			elseif entry.Type == "Range" then
				local val = parse.getFloat()
				if val < entry.Min then
					val = entry.Min
				end
				if val > entry.Max then
					val = entry.Max
				end
				entry.Value = val
			elseif entry.Type == "FivePoint" or entry.Type == "TenPoint" then
				local val = parse.getInt()
				if val < 1 then
					val = 1
				end
				if entry.Type == "FivePoint" and val > 5 then
					val = 5
				end
				if entry.Type == "TenPoint" and val > 10 then
					val = 10
				end
				entry.Value = val
			end
			
			if parse.optionalString("+Force Selector:") then
				entry.ForceSelector = parse.getBoolean()
			else
				entry.ForceSelector = false
			end
			
			if parse.optionalString("+No Default:") then --this needs a better name
				entry.NoDefault = parse.getBoolean()
			else
				entry.NoDefault = false
			end
		end
		
		table.insert(ScpuiSystem.CustomOptions, entry)
	end
	
	parse.requiredString("#End")

	parse.stop()

end

function utils.verifyParsedType(val)

	if string.lower(val) == "header" then
		return "Header"
	end
	
	if string.lower(val) == "binary" then
		return "Binary"
	end
	
	if string.lower(val) == "multi" then
		return "Multi"
	end
	
	if string.lower(val) == "range" then
		return "Range"
	end
	
	if string.lower(val) == "fivepoint" then
		return "FivePoint"
	end
	
	if string.lower(val) == "tenpoint" then
		return "TenPoint"
	end
	
	parse.displayMessage("Option type " .. val .. " is not valid!", true)
	
end

function utils.animExists(name)
	--remove extension if it's included
	local file = name:match("(.+)%..+")
	
	if file == nil then
		file = name
	end
	
	--now see if it exists
	local theseExts = {".png", ".ani", ".eff"}
	for i = 1, #theseExts do
		local thisFile = file .. theseExts[i]
		if cf.fileExists(thisFile, "", true) then
			return true
		end
	end
	return false
end

function utils.strip_extension(name)
    return string.gsub(name, "%..+$", "")
end

function utils.split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
end

function utils.loadConfig(filename)
  -- Load the config file.
  local file = cf.openFile(filename, 'r', 'data/config')
  local config = require('dkjson').decode(file:read('*a'))
  file:close()
  if not config then
    ba.error('Please ensure that ' .. filename .. ' exists in data/config and is valid JSON.')
  end
  return config
end

function utils.xstr(message)
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
function utils.find_first_either(str, patterns, startIdx)
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
function utils.rml_escape(inputStr)
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

function utils.table.ifind(tbl, val, compare)
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

function utils.table.find(tbl, val, compare)
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

function utils.table.contains(tbl, val, compare)
    return utils.table.find(tbl, val, compare) ~= nil
end

function utils.table.iremove_el(tbl, val, compare)
    local i = utils.table.ifind(tbl, val, compare)
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
function utils.table.map(tbl, map_fun)
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
function utils.table.reduce(tbl, reduceFn, initial)
    local acc = initial
    for _, v in ipairs(tbl) do
        acc = reduceFn(acc, v)
    end
    return acc
end

--- Computes the sum of the specified table
--- @param tbl number[]
--- @return number
function utils.table.sum(tbl)
    return utils.table.reduce(tbl, function(sum, el)
        return sum + el
    end, 0)
end

return utils
