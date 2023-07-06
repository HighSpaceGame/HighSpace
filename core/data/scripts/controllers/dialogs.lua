local templates              = require("rocket_templates")

local module                = {}

-- The type of a dialog
module.TYPE_SIMPLE          = 1

-- The various button
module.BUTTON_TYPE_POSITIVE = 1
module.BUTTON_TYPE_NEGATIVE = 2
module.BUTTON_TYPE_NEUTRAL  = 3

module.BUTTON_MAPPING       = {
    [module.BUTTON_TYPE_POSITIVE] = "button_positive",
    [module.BUTTON_TYPE_NEGATIVE] = "button_negative",
	[module.BUTTON_TYPE_NEUTRAL] = "button_neutral"
}

local function initialize_buttons(document, properties, finish_func)
    local button_container = document:GetElementById("button_container")

    for _, v in ipairs(properties.buttons) do
        local actual_el, text_el, image_container, image_el = templates.instantiate_template(document, "button_template",
                                                                                            nil, {
                                                                                                "button_text_id",
                                                                                                "button_image_container",
                                                                                                "button_image_id"
                                                                                            })
        button_container:AppendChild(actual_el)

        actual_el.id = "" -- Reset the ID so that there are no duplicate IDs
        actual_el:SetClass(module.BUTTON_MAPPING[v.type], true)
		
		local str = v.text
		
		if v.keypress ~= nil then
		
			local s1 = ""
			local s2 = ""

			--find the uppercase letter if it exists
			local s, e = string.find(str, string.upper(v.keypress))
			if s then
				str = string.sub(str, 1, s - 1) .. "<span class=\"underline\">" .. string.upper(v.keypress) .. "</span>" .. string.sub(str, e + 1)
			else
				--didn't find it so let's try lowercase			
				local s, e = string.find(str, v.keypress)
				if s then
					str = string.sub(str, 1, s - 1) .. "<span class=\"underline\">" .. v.keypress .. "</span>" .. string.sub(str, e + 1)
				else
					--still didn't find it so no underlining!
					str = v.text
				end
			end
			
		end

        text_el.inner_rml = str

        local style       = image_container.style
        for i, v in pairs(style) do
            -- This is pretty ugly but somehow the __index function is broken
            if i == "background-image" then
                image_el:SetAttribute("src", v)
                break
            end
        end

        actual_el:AddEventListener("click", function(_, _, _)
            if finish_func then
                finish_func(v.value)
            end
            document:Close()
        end)
    end
end

local function show_dialog(context, properties, finish_func, reject, abortCBTable)
    local dialog_doc = nil
	
	if properties.style_value == 2 then
		dialog_doc                                       = context:LoadDocument("data/interface/markup/deathdialog.rml")
	else
		dialog_doc                                       = context:LoadDocument("data/interface/markup/dialog.rml")
	end

    dialog_doc:GetElementById("title_container").inner_rml = properties.title_string
    dialog_doc:GetElementById("text_container").inner_rml  = properties.text_string
    if modOptionValues.Font_Multiplier then
        dialog_doc:GetElementById("dialog_body"):SetClass(("p1-" .. modOptionValues.Font_Multiplier), true)
    else
        dialog_doc:GetElementById("dialog_body"):SetClass("p1-5", true)
    end

    if properties.text_class then
        dialog_doc:GetElementById("text_container"):SetClass(properties.text_class, true)
    end
	
	if properties.input_choice then
		local input_el = dialog_doc:CreateElement("input")
		dialog_doc:GetElementById("text_container"):AppendChild(input_el)
		input_el.type = "text"
		input_el.maxlength = 32
		
		input_el:AddEventListener("change", function(event, _, _)
            if event.parameters.linebreak == 1 then
                finish_func(event.parameters.value)
				dialog_doc:Close()
			end
        end)
	end

    if #properties.buttons > 0 then
	
		--verify that all key shortcuts are unique
		local keys = {}
		
		for i = 1, #properties.buttons, 1 do
			if properties.buttons[i].keypress ~= nil then
				if #keys == 0 then
					table.insert(keys, properties.buttons[i].keypress)
				else
					for j = 1, #keys, 1 do
						if properties.buttons[i].keypress == keys[j] then
							properties.buttons[i].keypress = nil
						else
							table.insert(keys, properties.buttons[i].keypress)
						end
					end
				end
			end
		end
	
        initialize_buttons(dialog_doc, properties, finish_func)
    end
	
	dialog_doc:AddEventListener("keydown", function(event, _, _)
		if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
			if properties.escape_value ~= nil then
				finish_func(properties.escape_value)
				dialog_doc:Close()
			end
		end
		for i = 1, #properties.buttons, 1 do
			if properties.buttons[i].keypress ~= nil then
				thisKey = string.upper(properties.buttons[i].keypress)
				if event.parameters.key_identifier == rocket.key_identifier[thisKey] then
					finish_func(properties.buttons[i].value)
					dialog_doc:Close()
				end
			end
		end
	end)
    
    if abortCBTable ~= nil then
        abortCBTable.Abort = function()
            dialog_doc:Close()
            reject()
        end
    end

    dialog_doc:Show(DocumentFocus.FOCUS) -- MODAL would be better than FOCUS but then the debugger cannot be used anymore
end


---@class DialogFactory A dialog factory
local factory_mt   = {}

factory_mt.__index = factory_mt

function factory_mt:type(type)
    self.type_val = type
    return self
end

function factory_mt:title(title)
    self.title_string = ""
	if title ~= nil then
		self.title_string = title
	end
    return self
end

function factory_mt:text(text)
	self.text_string = ""
	if text ~= nil then
		self.text_string = text
	end
    return self
end

function factory_mt:textClass(text_class)
    self.text_class = ""
    if text_class ~= nil then
        self.text_class = text_class
    end
    return self
end

function factory_mt:button(type, text, value, keypress)
    if value == nil then
        value = #self.buttons + 1
    end

    table.insert(self.buttons, {
        type  = type,
        text  = text,
        value = value,
		keypress = keypress
    })
    return self
end

function factory_mt:input(input)
    self.input_choice = input
    return self
end

function factory_mt:escape(escape)
    self.escape_value = escape
    return self
end

function factory_mt:style(style)
    self.style_value = style
    return self
end

function factory_mt:show(context, abortCBTable)
    return async.promise(function(resolve, reject)
        show_dialog(context, self, resolve, reject, abortCBTable)
    end)
end

--- Creates a new dialog factory
--- @return DialogFactory A factory for creating dialogs
function module.new()
    local factory = {
        type_val     = module.TYPE_SIMPLE,
        buttons      = {},
        title_string = "",
        text_string  = "",
        text_class = "",
		input_choice = false,
		escape_value = nil,
		style_value = 1,
    }
    setmetatable(factory, factory_mt)
    return factory
end

return module
