local dialogs = require("dialogs")
local class = require("class")
local async_util = require("async_util")

local ControlConfigController = class()
local fontMultiplier = nil

function ControlConfigController:init()

	self.uiActiveContext = async.context.combineContexts(async.context.captureGameState(),
        async.context.createLuaState(function()
            if not self.loaded then
                return CONTEXT_INVALID
            end

            return CONTEXT_VALID
        end))

end

function ControlConfigController:initialize(document)

    self.document = document
	self.conflict = false
	
	---Load the desired font size from the save file
	if ScpuiOptionValues.Font_Multiplier then
		local fontChoice = ScpuiOptionValues.Font_Multiplier
		fontMultiplier = ScpuiOptionValues.Font_Multiplier
		self.document:GetElementById("main_background"):SetClass(("p1-" .. fontChoice), true)
		self.document:GetElementById("conflict_warning"):SetClass(("h1-" .. fontChoice), true)
	else
		self.document:GetElementById("main_background"):SetClass("p1-5", true)
		self.document:GetElementById("conflict_warning"):SetClass("h1-5", true)
		fontMultiplier = 5
	end
	
	ui.ControlConfig.initControlConfig()
	
	self:initPresets()
	self.document:GetElementById("new_lock"):SetClass("hidden", false)
	
	self:changeSection(0)
end

function ControlConfigController:initPresets()
	local parent_el = self.document:GetElementById("list_presets_ul")
	
	self:ClearEntries(parent_el)
	
	for i = 1, #ui.ControlConfig.ControlPresets do
		local entry = ui.ControlConfig.ControlPresets[i]
		
		local li_el = self.document:CreateElement("li")
		li_el.id = "preset_" .. i
		
		li_el:SetClass("preset_list_element", true)
		li_el:SetClass("button_3", true)
		
		li_el.inner_rml = entry.Name
		
		li_el:AddEventListener("click", function(_, _, _)
				self:SelectPreset(i, entry.Name)
			end)
		
		parent_el:AppendChild(li_el)
		
		local curPreset = ui.ControlConfig:getCurrentPreset()
		
		if entry.Name == curPreset then
			li_el:SetPseudoClass("checked", true)
			self.currentPreset = i
			self.oldPreset = i
			
			--unlock clone and delete
			self.document:GetElementById("clone_lock"):SetClass("hidden", true)
			if entry.Name ~= "default" then
				self.document:GetElementById("delete_lock"):SetClass("hidden", true)
			else
				self.document:GetElementById("delete_lock"):SetClass("hidden", false)
			end
		end
	end
	
end

function ControlConfigController:SelectPreset(idx, name)

	if self.currentPreset == idx then
		return
	end

	self.currentPreset = idx
	
	if self.oldPreset == nil then
		self.oldPreset = idx
	else
		local presetID = "preset_" .. self.oldPreset
		self.document:GetElementById(presetID):SetPseudoClass("checked", false)
			
		self.oldPreset = idx
	end
	
	local presetID = "preset_" .. self.oldPreset
	self.document:GetElementById(presetID):SetPseudoClass("checked", true)
	
	ui.ControlConfig.usePreset(name)
	
	--unlock clone and delete
	self.document:GetElementById("clone_lock"):SetClass("hidden", true)
	if name ~= "default" then
		self.document:GetElementById("delete_lock"):SetClass("hidden", true)
	else
		self.document:GetElementById("delete_lock"):SetClass("hidden", false)
	end
	
	--reload the keys list
	self:changeSection(self.currentTab)

end

function ControlConfigController:UnselectPreset()
	if self.oldPreset == nil then
		return
	else
		presetID = "preset_" .. self.oldPreset
		self.document:GetElementById(presetID):SetPseudoClass("checked", false)
		
		self.oldPreset = nil
		self.currentPreset = nil
	end
	
	--lock clone and delete
	self.document:GetElementById("clone_lock"):SetClass("hidden", false)
	self.document:GetElementById("delete_lock"):SetClass("hidden", false)
end

function ControlConfigController:CheckPresets()
	local cur = ui.ControlConfig.getCurrentPreset()
	
	if cur == nil then
		self:UnselectPreset()
		self.document:GetElementById("new_lock"):SetClass("hidden", true)
	end
	
	for i = 1, #ui.ControlConfig.ControlPresets do
		local entry = ui.ControlConfig.ControlPresets[i]
		
		if entry.Name == cur then
			self:SelectPreset(i, cur)
			self.document:GetElementById("new_lock"):SetClass("hidden", false)
			break
		end
	end
end

function ControlConfigController:getPresetInput(presetType)
	
	self.promptControl = presetType

	local text = "Please enter a name for the preset: "
	local title = ""
	local buttons = {}
	buttons[1] = {
		b_type = dialogs.BUTTON_TYPE_POSITIVE,
		b_text = ba.XSTR("Okay", -1),
		b_value = "",
		b_keypress = string.sub(ba.XSTR("Okay", -1), 1, 1)
	}
	
	self:Show(text, title, true, buttons)
end

function ControlConfigController:newPreset(name)

	if ui.ControlConfig.createPreset(name) then
		self:initPresets()
		self:changeSection(self.currentTab)
	else
		local text = "An identical preset already exists!"
		local title = ""
		local buttons = {}
		buttons[1] = {
			b_type = dialogs.BUTTON_TYPE_POSITIVE,
			b_text = ba.XSTR("Okay", -1),
			b_value = "",
			b_keypress = string.sub(ba.XSTR("Okay", -1), 1, 1)
		}
		
		self:Show(text, title, false, buttons)
	end
	
end

function ControlConfigController:clonePreset(name)

	local preset = ui.ControlConfig.ControlPresets[self.currentPreset]
	
	if preset:clonePreset(name) then
		self:initPresets()
		self:changeSection(self.currentTab)
	else
		local text = "A preset with that name already exists! Please try again."
		local title = ""
		local buttons = {}
		buttons[1] = {
			b_type = dialogs.BUTTON_TYPE_POSITIVE,
			b_text = ba.XSTR("Okay", -1),
			b_value = "",
			b_keypress = string.sub(ba.XSTR("Okay", -1), 1, 1)
		}
		
		self:Show(text, title, false, buttons)
	end
	
end

function ControlConfigController:verifyDelete()
	
	self.promptControl = 5

	local text = "Are you sure you want to delete the preset?"
	local title = ""
	local buttons = {}
	buttons[1] = {
		b_type = dialogs.BUTTON_TYPE_POSITIVE,
		b_text = ba.XSTR("Yes", -1),
		b_value = true,
		b_keypress = string.sub(ba.XSTR("Yes", -1), 1, 1)
	}
	buttons[2] = {
		b_type = dialogs.BUTTON_TYPE_NEGATIVE,
		b_text = ba.XSTR("No", -1),
		b_value = false,
		b_keypress = string.sub(ba.XSTR("No", -1), 1, 1)
	}
	
	self:Show(text, title, false, buttons)
end

function ControlConfigController:deletePreset()

	local preset = ui.ControlConfig.ControlPresets[self.currentPreset] -- the default preset
	
	ui.ControlConfig.usePreset("default")
	
	preset:deletePreset()
	
	self:initPresets()
	self:changeSection(self.currentTab)
	
end

function ControlConfigController:initKeysList(tab)
	local parent_el = self.document:GetElementById("list_items_ul")
	
	for i = 1, #ui.ControlConfig.ControlConfigs do
		local entry = ui.ControlConfig.ControlConfigs[i]
		
		if entry.Tab == tab and not entry.Disabled then
		
			local li_el = self.document:CreateElement("li")
			li_el.id = "line_" .. i
			
			li_el:SetClass("control_configlist_element", true)
			li_el:SetClass("button_3", true)
			
			parent_el:AppendChild(li_el)
			
			--build the name div
			local na_el = self.document:CreateElement("div")
			na_el.id = "name_" .. i
			na_el:SetClass("name_display", true)
			na_el:SetClass("button_3", true)
			na_el.inner_rml = entry.Name
			
			na_el:AddEventListener("click", function(_, _, _)
				self:SelectEntry(i)
			end)
			
			li_el:AppendChild(na_el)
			
			--build the binds divs
			local bindings = entry.Bindings
			
			for j = 1, #bindings do
				local bi_el = self.document:CreateElement("div")
				bi_el.id = "bind_" .. j .. "_" .. i
				bi_el:SetClass("bind_display", true)
				bi_el:SetClass("button_3", true)
				bi_el.inner_rml = bindings[j]
				
				bi_el:AddEventListener("click", function(_, _, _)
					self:SelectBind(i, j)
				end)
				
				bi_el:AddEventListener("dblclick", function(_, _, _)
					self:BindKey(i, j)
				end)
			
				li_el:AppendChild(bi_el)
			end
			
			--on first run save total number of bindings
			if self.numBinds == nil then
				self.numBinds = #bindings
			end
			
		end
	end
	
end

function ControlConfigController:changeSection(tab)
	
	--uncheck all tabs
	self.document:GetElementById("target_btn"):SetPseudoClass("checked", false)
	self.document:GetElementById("ship_btn"):SetPseudoClass("checked", false)
	self.document:GetElementById("weapon_btn"):SetPseudoClass("checked", false)
	self.document:GetElementById("misc_btn"):SetPseudoClass("checked", false)
	
	--unckeck all modifiers
	self.document:GetElementById("alt_btn"):SetPseudoClass("checked", false)
	self.document:GetElementById("shift_btn"):SetPseudoClass("checked", false)
	self.document:GetElementById("invert_btn"):SetPseudoClass("checked", false)
	
	--set selections to nil
	self.currentEntry = nil
	self.currentBind = nil
	self.oldEntry = nil
	self.currentTab = tab
	
	self:checkLocks()
	
	if tab == 0 then
		self.document:GetElementById("target_btn"):SetPseudoClass("checked", true)
	elseif tab == 1 then
		self.document:GetElementById("ship_btn"):SetPseudoClass("checked", true)
	elseif tab == 2 then
		self.document:GetElementById("weapon_btn"):SetPseudoClass("checked", true)
	else
		self.document:GetElementById("misc_btn"):SetPseudoClass("checked", true)
		--just in case
		tab = 3
	end
	
	self:ClearEntries(self.document:GetElementById("list_items_ul"))
	self:initKeysList(tab)
	
	self:checkConflict()
end

function ControlConfigController:SelectEntry(idx)

	self.currentEntry = idx
	self.currentBind = nil
	
	if self.oldEntry == nil then
		self.oldEntry = idx
	else
		local oldName_ID = "name_" .. self.oldEntry
		self.document:GetElementById(oldName_ID):SetPseudoClass("checked", false)
		
		for i = 1, self.numBinds do
			local oldBind_ID = "bind_" .. i .. "_" .. self.oldEntry
			self.document:GetElementById(oldBind_ID):SetPseudoClass("checked", false)
			self.document:GetElementById(oldBind_ID):SetPseudoClass("enabled", false)
		end
			
		self.oldEntry = idx
	end
	
	local nameID = "name_" .. self.oldEntry
	self.document:GetElementById(nameID):SetPseudoClass("checked", true)
	
	for i = 1, self.numBinds do
		local bindID = "bind_" .. i .. "_" .. self.oldEntry
		self.document:GetElementById(bindID):SetPseudoClass("checked", true)
	end
	
	self:checkModifiers()
	self:checkConflict()
	self:checkLocks()
	self:CheckPresets()
end

function ControlConfigController:SelectBind(idx, bind)

	self.currentEntry = idx
	self.currentBind = bind
	
	if self.oldEntry == nil then
		self.oldEntry = idx
	else
		local oldName_ID = "name_" .. self.oldEntry
		self.document:GetElementById(oldName_ID):SetPseudoClass("checked", false)
		
		for i = 1, self.numBinds do
			local oldBind_ID = "bind_" .. i .. "_" .. self.oldEntry
			self.document:GetElementById(oldBind_ID):SetPseudoClass("checked", false)
			self.document:GetElementById(oldBind_ID):SetPseudoClass("enabled", false)
		end
			
		self.oldEntry = idx
	end
	
	local nameID = "name_" .. self.oldEntry
	self.document:GetElementById(nameID):SetPseudoClass("checked", true)
	
	for i = 1, self.numBinds do
		local bindID = "bind_" .. i .. "_" .. self.oldEntry
		if i == bind then
			self.document:GetElementById(bindID):SetPseudoClass("enabled", true)
		else
			self.document:GetElementById(bindID):SetPseudoClass("checked", true)
		end
	end
	
	self:checkModifiers()
	self:checkConflict()
	self:checkLocks()
	self:CheckPresets()
end

function ControlConfigController:checkConflict()
	
	self.conflict = false
	for i = 1, #ui.ControlConfig.ControlConfigs do
		local entry = ui.ControlConfig.ControlConfigs[i]
		if entry.Conflicted ~= nil then
			self.conflict = true
		end
	end
	
	--no conflicts, bail
	if self.conflict == false then
		self.document:GetElementById("conflict_warning").inner_rml = ""
		self.document:GetElementById("conflict_description").inner_rml = ""
		return
	end
	
	--nothing selected, bail
	if self.currentEntry == nil then
		self.document:GetElementById("conflict_description").inner_rml = ""
		return
	end
	
	self.document:GetElementById("conflict_warning").inner_rml = "CONFLICT!"

	local conflict = ui.ControlConfig.ControlConfigs[self.currentEntry].Conflicted
	
	if conflict ~= nil then
		self.document:GetElementById("conflict_description").inner_rml = conflict
	else
		self.document:GetElementById("conflict_description").inner_rml = ""
	end
end

function ControlConfigController:checkModifiers()
	self:checkShifts()
	self:checkAlts()
	self:checkInverts()
end

function ControlConfigController:checkLocks()
	local generalLock = false
	local invertLock = false
	local conflictLock = false
	local modifierLock = false
	if self.currentEntry ~= nil then
		generalLock = true
		if ui.ControlConfig.ControlConfigs[self.currentEntry].Conflicted ~= nil then
			conflictLock = true
		end
		if ui.ControlConfig.ControlConfigs[self.currentEntry].IsAxis == true then
			invertLock = true
		else
			modifierLock = true
		end
	end
	
	--conflict
	self.document:GetElementById("clear_conflict_lock"):SetClass("hidden", conflictLock)
	
	--invert
	self.document:GetElementById("invert_lock"):SetClass("hidden", invertLock)
	
	--modifier
	self.document:GetElementById("alt_lock"):SetClass("hidden", modifierLock)
	self.document:GetElementById("shift_lock"):SetClass("hidden", modifierLock)
	
	--rest
	self.document:GetElementById("clear_selected_lock"):SetClass("hidden", generalLock)
	self.document:GetElementById("bind_lock"):SetClass("hidden", generalLock)
end	

function ControlConfigController:checkShifts()

	local shifted = ui.ControlConfig.ControlConfigs[self.currentEntry].Shifted
	
	if shifted then
		self.document:GetElementById("shift_btn"):SetPseudoClass("checked", true)
	else
		self.document:GetElementById("shift_btn"):SetPseudoClass("checked", false)
	end

end

function ControlConfigController:checkAlts()

	local alted = ui.ControlConfig.ControlConfigs[self.currentEntry].Alted
	
	if alted then
		self.document:GetElementById("alt_btn"):SetPseudoClass("checked", true)
	else
		self.document:GetElementById("alt_btn"):SetPseudoClass("checked", false)
	end

end

function ControlConfigController:checkInverts()

	local inverted = false
	if self.currentBind ~= nil then
		inverted = ui.ControlConfig.ControlConfigs[self.currentEntry]:isBindInverted(self.currentBind)
	end
	
	if inverted then
		self.document:GetElementById("invert_btn"):SetPseudoClass("checked", true)
	else
		self.document:GetElementById("invert_btn"):SetPseudoClass("checked", false)
	end

end

function ControlConfigController:toggleAlt()

	if self.currentEntry == nil then
		return
	else --maybe also check that alt is allowed
		ui.ControlConfig.ControlConfigs[self.currentEntry]:toggleAlted()
		local idx = self.currentEntry
		self:changeSection(self.currentTab)
		self:SelectEntry(idx)
	end

end

function ControlConfigController:toggleShift()

	if self.currentEntry == nil then
		return
	else --maybe also check that shift is allowed
		ui.ControlConfig.ControlConfigs[self.currentEntry]:toggleShifted()
		local idx = self.currentEntry
		self:changeSection(self.currentTab)
		self:SelectEntry(idx)
	end

end

function ControlConfigController:toggleInvert()

	if self.currentEntry == nil then
		return
	else --maybe also check that invert is allowed
		if self.currentBind == nil then
			return
		else
			ui.ControlConfig.ControlConfigs[self.currentEntry]:toggleInverted(self.currentBind)
			local idx = self.currentEntry
			local item = self.currentBind
			self:changeSection(self.currentTab)
			self:SelectBind(idx, item)
		end
	end

end

function ControlConfigController:clearConflict()

	if self.currentEntry == nil then
		return
	else --maybe also check that shift is allowed
		ui.ControlConfig.ControlConfigs[self.currentEntry]:clearConflicts()
		local idx = self.currentEntry
		self:changeSection(self.currentTab)
		self:SelectEntry(idx)
	end

end

function ControlConfigController:clearSelected()

	if self.currentEntry == nil then
		return
	else --maybe also check that shift is allowed
		local idx = self.currentEntry
		local bind = self.currentBind
		if bind == nil then
			bind = 1
		else
			bind = bind + 1 --convert 1/2 to 2/3
		end
			
		ui.ControlConfig.ControlConfigs[self.currentEntry]:clearBind(bind)
		self:changeSection(self.currentTab)
		if bind == 3 then
			self:SelectEntry(idx)
		else
			self:SelectBind(idx, bind)
		end
	end

end

function ControlConfigController:clearAll()

	self.promptControl = 3

	local text = "Are you sure you want to clear all binds?"
	local title = ""
	local buttons = {}
	buttons[1] = {
		b_type = dialogs.BUTTON_TYPE_POSITIVE,
		b_text = ba.XSTR("Yes", -1),
		b_value = true,
		b_keypress = string.sub(ba.XSTR("Yes", -1), 1, 1)
	}
	buttons[2] = {
		b_type = dialogs.BUTTON_TYPE_NEGATIVE,
		b_text = ba.XSTR("No", -1),
		b_value = false,
		b_keypress = string.sub(ba.XSTR("No", -1), 1, 1)
	}
	
	self:Show(text, title, false, buttons)

end

function ControlConfigController:clearAllActual()
	
	ui.ControlConfig.clearAll()
	
	local idx = self.currentEntry
	
	self:changeSection(self.currentTab)
	
	if idx ~= nil then
		self:SelectEntry(idx)
	end
end

function ControlConfigController:undoChange()
	
	ui.ControlConfig.undoLastChange()
	
	local idx = self.currentEntry
	local bind = self.currentBind
	
	self:changeSection(self.currentTab)
	
	if idx ~= nil then
		self:SelectEntry(idx)
	else
		if bind ~= nil then
			self:SelectBind(idx, bind)
		end
	end

end

function ControlConfigController:ClearEntries(parent)

	while parent:HasChildNodes() do
		parent:RemoveChild(parent.first_child)
	end

end

function ControlConfigController:Exit(element)

	local continue = true

	if self.conflict then
		continue = false

		local text = "You must resolve conflicts first!"
		local title = ""
		local buttons = {}
		buttons[1] = {
			b_type = dialogs.BUTTON_TYPE_POSITIVE,
			b_text = ba.XSTR("Okay", -1),
			b_value = true,
			b_keypress = string.sub(ba.XSTR("Okay", -1), 1, 1)
		}
		
		self:Show(text, title, false, buttons)
	end
	if ui.ControlConfig.getCurrentPreset() == nil then
		self.promptControl = 4
		continue = false

		local text = "You must save your controls as a preset. Do so now?"
		local title = ""
		local buttons = {}
		buttons[1] = {
			b_type = dialogs.BUTTON_TYPE_POSITIVE,
			b_text = ba.XSTR("Yes", -1),
			b_value = true,
			b_keypress = string.sub(ba.XSTR("Yes", -1), 1, 1)
		}
		buttons[2] = {
			b_type = dialogs.BUTTON_TYPE_NEGATIVE,
			b_text = ba.XSTR("No", -1),
			b_value = false,
			b_keypress = string.sub(ba.XSTR("No", -1), 1, 1)
		}
		
		self:Show(text, title, false, buttons)
	end
	
	if continue then
		if ui.ControlConfig.acceptBinding() then
			ui.playElementSound(element, "click", "success")
			ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])
			ui.ControlConfig.closeControlConfig()
		else
			local text = "Something went wrong, please try again!"
			local title = ""
			local buttons = {}
			buttons[1] = {
				b_type = dialogs.BUTTON_TYPE_POSITIVE,
				b_text = ba.XSTR("Okay", -1),
				b_value = true,
				b_keypress = string.sub(ba.XSTR("Okay", -1), 1, 1)
			}
			
			self:Show(text, title, false, buttons)
		end
	end

end	

function ControlConfigController:global_keydown(_, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
        event:StopPropagation()
		ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])
		ui.ControlConfig.cancelBinding()
		ui.ControlConfig.closeControlConfig()
	elseif event.parameters.key_identifier == rocket.key_identifier.Z and event.parameters.ctrl_key == 1 then
		self:undoChange()
	end
end

function ControlConfigController:searchForBind()
	
	async.run(function()
        ui.disableInput()
        
        --Do anything needed to lock the UI during the binding phase
		
		local search = 0
    
        while (search == 0) do 
			search = ui.ControlConfig.searchBinds()
			async.await(async.yield())
		end
        
        --Do anything needed to unlock the UI after the binding phase
		
		if search > 0 then
		
			local bind = ui.ControlConfig.ControlConfigs[search]
			
			ui.enableInput(ScpuiSystem.context)
			self:changeSection(bind.Tab)
			self:SelectEntry(search)
		else
			ui.enableInput(ScpuiSystem.context)
		end
    end, async.OnFrameExecutor)
	
end

function ControlConfigController:Show(text, title, input, buttons)
	--Create a simple dialog box with the text and title

	currentDialog = true
	
	local dialog = dialogs.new()
		dialog:title(title)
		dialog:text(text)
		dialog:input(input)
		for i = 1, #buttons do
			dialog:button(buttons[i].b_type, buttons[i].b_text, buttons[i].b_value, buttons[i].b_keypress)
		end
		dialog:escape("")
		dialog:show(self.document.context)
		:continueWith(function(response)
			self:dialog_response(response)
    end)
	-- Route input to our context until the user dismisses the dialog box.
	ui.enableInput(self.document.context)
end

function ControlConfigController:dialog_response(response)
	local path = self.promptControl
	self.promptControl = nil
	if path == 1 then
		self:newPreset(response)
	elseif path == 2 then
		self:clonePreset(response)
	elseif path == 3 then
		if response == true then
			self:clearAllActual()
		end
	elseif path == 4 then
		if response == true then
			self:getPresetInput(1)
		end
	elseif path == 5 then
		if response == true then
			self:deletePreset()
		end
	end
end

function ControlConfigController:beginBind()
	if self.currentEntry == nil then
		return
	end
	
	if self.currentBind == nil then
		self.currentBind = 1
	end
	
	self:BindKey(self.currentEntry, self.currentBind)
end

function ControlConfigController:BindKey(idx, item)

	local entry = ui.ControlConfig.ControlConfigs[idx]
	local bindID = "bind_" .. item .. "_" .. idx
	
	self.document:GetElementById(bindID).inner_rml = ">>"
	
	async.run(function()
        ui.disableInput()
        
        --Do anything needed to lock the UI during the binding phase
		
		local status = 0
    
        while (status == 0) do 
			status = ui.ControlConfig.ControlConfigs[idx]:detectKeypress(item)
			async.await(async.yield())
		end
        
        --Do anything needed to unlock the UI after the binding phase
        
		ui.enableInput(ScpuiSystem.context)
		if status < 0 then
			local text = "That key cannot be bound! Please try again."
			local title = ""
			local buttons = {}
			buttons[1] = {
				b_type = dialogs.BUTTON_TYPE_POSITIVE,
				b_text = ba.XSTR("Okay", -1),
				b_value = "",
				b_keypress = string.sub(ba.XSTR("Okay", -1), 1, 1)
			}
			
			self:Show(text, title, false, buttons)
		end
		self:changeSection(self.currentTab)
		self:SelectBind(idx, item)
    end, async.OnFrameExecutor)
	
end

return ControlConfigController
