local dialogs = require("dialogs")
local class = require("class")
local async_util = require("async_util")

local HudConfigController = class()
local fontMultiplier = nil

ScpuiSystem.drawHUD = nil

function HudConfigController:init()

	ScpuiSystem.drawHUD = {}
	
	self.default = "hud_3.hcf"
	
	self.presetColors = {}
	
	--green
	self.presetColors[1] = {
		Name = "green",
		r = 0,
		g = 255,
		b = 0,
		a = 255
	}
	--amber
	self.presetColors[2] = {
		Name = "amber",
		r = 255,
		g = 297,
		b = 0,
		a = 255
	}
	--blue
	self.presetColors[3] = {
		Name = "blue",
		r = 67,
		g = 123,
		b = 203,
		a = 255
	}

end

function HudConfigController:initialize(document)

    self.document = document
	
	---Load the desired font size from the save file
	if ScpuiOptionValues.Font_Multiplier then
		local fontChoice = ScpuiOptionValues.Font_Multiplier
		fontMultiplier = ScpuiOptionValues.Font_Multiplier
		self.document:GetElementById("main_background"):SetClass(("p1-" .. fontChoice), true)
	else
		self.document:GetElementById("main_background"):SetClass("p1-5", true)
		fontMultiplier = 5
	end
	
	hud_el = self.document:GetElementById("hud_drawn_content")
	
	--get coords to draw at
	local hx = hud_el.offset_left + hud_el.parent_node.offset_left  + hud_el.parent_node.parent_node.offset_left
	local hy = hud_el.offset_top + hud_el.parent_node.offset_top  + hud_el.parent_node.parent_node.offset_top
	local hw = hud_el.offset_width
	
	--increase those coords by percentage
	hx = hx + (0.02 * hx)
	hy = hy + (-0.2 * hy)
	hw = hw + (0.2 * hw)
	
	ui.HudConfig.initHudConfig(hx, hy, hw)
	
	ScpuiSystem.drawHUD.mx = 0
	ScpuiSystem.drawHUD.my = 0
	ScpuiSystem.drawHUD.draw = true
	
	self.r = 0
	self.g = 0
	self.b = 0
	self.a = 0
	
	self.mutex = true -- stop circulur updates at start
	
	self:value_update(self.r, self.g, self.b, self.a)
	
	self.mutex = false -- now allow updates
	
	self.document:GetElementById("popup_btn"):SetClass("hidden", true)
	self.document:GetElementById("hud_on_btn"):SetClass("hidden", true)
	self.document:GetElementById("hud_off_btn"):SetClass("hidden", true)
	
	self.selectAll = false
	
	self:initPresets()
end

function HudConfigController:initPresets()
	local parent_el = self.document:GetElementById("list_presets_ul")
	
	self:ClearEntries(parent_el)
	
	self.oldPreset = nil
	
	for i = 1, #self.presetColors do
		local entry = self.presetColors[i]
		
		local li_el = self.document:CreateElement("li")
		li_el.id = "preset_" .. i
		
		li_el:SetClass("preset_list_element", true)
		li_el:SetClass("button_1", true)
		
		li_el.inner_rml = entry.Name
		
		li_el:AddEventListener("click", function(_, _, _)
				self:SelectPreset(i, entry.Name)
			end)
		
		parent_el:AppendChild(li_el)
	end
	
	for i = 1, #ui.HudConfig.GaugePresets do
		local entry = ui.HudConfig.GaugePresets[i]
		
		local li_el = self.document:CreateElement("li")
		li_el.id = "preset_" .. i + #self.presetColors
		
		li_el:SetClass("preset_list_element", true)
		li_el:SetClass("button_1", true)
		
		li_el.inner_rml = entry.Name
		
		li_el:AddEventListener("click", function(_, _, _)
				self:SelectPreset(i + #self.presetColors, entry.Name)
			end)
		
		parent_el:AppendChild(li_el)
	end
	
end

function HudConfigController:setColor(idx)

	local entry = self.presetColors[idx]

	self.r = entry.r
	self.g = entry.g
	self.b = entry.b
	self.a = entry.a
	
	for i = 1, #ui.HudConfig.GaugeConfigs do
		self:changeGaugeColor(ui.HudConfig.GaugeConfigs[i])
	end

end

function HudConfigController:SelectPreset(idx, name)

	--deselect all if all is selected
	if self.selectAll == true then
		self:select_all()
	end

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
	
	--is this a built-in preset?
	local builtin = 0
	for i = 1, #self.presetColors do
		local entry = self.presetColors[i]
		
		if entry.Name == name then
			builtin = i
			break
		end
	end
	
	if builtin > 0 then
		self:setColor(builtin)
	else
		ui.HudConfig.usePresetFile(name)
	end
	
	self.currentPresetName = name
	
	--causes nothing to be selected and updates the UI accordingly
	self:mouse_click()

end

function HudConfigController:UnselectAllPresets()
	if not self.click then
		if self.oldPreset ~= nil then
			local presetID = "preset_" .. self.oldPreset
			self.document:GetElementById(presetID):SetPseudoClass("checked", false)
		end
				
		self.oldPreset = nil
		self.currentPreset = nil
		self.currentPresetName = nil
	end
end

function HudConfigController:savePreset(name)

	local continue = true

	for i = 1, #ui.HudConfig.GaugePresets do
		local entry = ui.HudConfig.GaugePresets[i]
		if entry.Name == name then
			continue = false
			break
		end
	end
	
	--is this a built-in preset?
	for i = 1, #self.presetColors do
		local entry = self.presetColors[i]
		
		if entry.Name == name then
			continue = false
			break
		end
	end
	
	if continue == true then
		ui.HudConfig.saveToPreset(name)
		self:initPresets()
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

function HudConfigController:deletePreset()

	if self.currentPresetName == nil then
		return
	end

	local preset = self.currentPresetName
	
	for i = 1, #ui.HudConfig.GaugePresets do
		local entry = ui.HudConfig.GaugePresets[i]
		
		if entry.Name == preset then
			entry:deletePreset()
			break
		end
	end
	
	self:initPresets()
	
end

function HudConfigController:ClearEntries(parent)

	while parent:HasChildNodes() do
		parent:RemoveChild(parent.first_child)
	end

end

function HudConfigController:Exit(element)

    ui.playElementSound(element, "click", "success")
	self.draw = nil
	ui.HudConfig.closeHudConfig(true)
	ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])

end

function HudConfigController:global_keydown(_, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
        event:StopPropagation()
		self.draw = nil
		ui.HudConfig.closeHudConfig(false)
		ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])
	end
end

function HudConfigController:drawHUD()
	if ScpuiSystem.drawHUD ~= nil then
		if ScpuiSystem.drawHUD.draw == false then
			return
		end
		ScpuiSystem.drawHUD.gauge = ui.HudConfig.drawHudConfig(ScpuiSystem.drawHUD.mx, ScpuiSystem.drawHUD.my)
	end
end

function HudConfigController:changeGaugeColor(gauge)
	local color = gr.createColor(self.r, self.g, self.b, self.a)
	gauge.CurrentColor = color
end

function HudConfigController:convert_slider_to_val(num)
	--reverse the order first
	local rev = 1 - num
	return math.floor(rev * 255)
end

function HudConfigController:convert_val_to_slider(num)
	local rev = num / 255
	--now reverse the value
	return 1 - rev
end

function HudConfigController:recalc_alpha()
	self.a = math.floor((self.r + self.g + self.b) / 3)
end

function HudConfigController:recalc_colors()
	if self.a > self.a_old then
		local pct = (self.a - self.a_old) / (255 - self.a_old)
		
		self.r = self.r + ((255 - self.r) * pct)
		self.g = self.g + ((255 - self.g) * pct)
		self.b = self.b + ((255 - self.b) * pct)
	else
		local pct = (self.a_old - self.a) / self.a_old
		
		self.r = self.r - (self.r * pct)
		self.g = self.g - (self.g * pct)
		self.b = self.b - (self.b * pct)
	end
end

function HudConfigController:slider_update(element, event, id)
	if id == 1 then
		if self.r ~= self:convert_slider_to_val(event.parameters.value) and not self.mutex then
			self.mutex = true
			self.r = self:convert_slider_to_val(event.parameters.value)
			self:recalc_alpha()
		else
			return
		end
	end
	if id == 2 then
		if self.g ~= self:convert_slider_to_val(event.parameters.value) and not self.mutex then
			self.mutex = true
			self.g = self:convert_slider_to_val(event.parameters.value)
			self:recalc_alpha()
		else
			return
		end
	end
	if id == 3 then
		if self.b ~= self:convert_slider_to_val(event.parameters.value) and not self.mutex then
			self.mutex = true
			self.b = self:convert_slider_to_val(event.parameters.value)
			self:recalc_alpha()
		else
			return
		end
	end
	if id == 4 then
		if self.a ~= self:convert_slider_to_val(event.parameters.value) and not self.mutex then
			self.mutex = true
			self.a_old = self.a
			self.a = self:convert_slider_to_val(event.parameters.value)
			self:recalc_colors()
		else
			return
		end
	end
	
	if self.selectAll then
		for i = 1, #ui.HudConfig.GaugeConfigs do
			self:changeGaugeColor(ui.HudConfig.GaugeConfigs[i])
		end
	else	
		if self.curGaugeName ~= nil then
			self:changeGaugeColor(self.selectedGauge)
		end
	end
	
	self:value_update(self.r, self.g, self.b, self.a)
	
	self.mutex = false
	self:UnselectAllPresets()
end

function HudConfigController:value_update(r, g, b, a)
	Element.As.ElementFormControlInput(self.document:GetElementById("r_slider")).value = self:convert_val_to_slider(r)
	Element.As.ElementFormControlInput(self.document:GetElementById("g_slider")).value = self:convert_val_to_slider(g)
	Element.As.ElementFormControlInput(self.document:GetElementById("b_slider")).value = self:convert_val_to_slider(b)
	Element.As.ElementFormControlInput(self.document:GetElementById("a_slider")).value = self:convert_val_to_slider(a)
end

function HudConfigController:lockColorControls(lock)
	local color_lock_el = self.document:GetElementById("color_lock")
	
	if lock then
		color_lock_el:SetClass("locked", true)
		color_lock_el:SetClass("unlocked", false)
	else
		color_lock_el:SetClass("locked", false)
		color_lock_el:SetClass("unlocked", true)
	end
end

function HudConfigController:setGaugeFlags(flag)
	
	if flag == 1 then
		self.selectedGauge.ShowGaugeFlag = true
		self:lockColorControls(false)
	end
	
	if flag == 2 then
		self.selectedGauge.ShowGaugeFlag = false
		self:lockColorControls(true)
	end
	
	if flag == 3 then
		self.selectedGauge.PopupGaugeFlag = not self.selectedGauge.PopupGaugeFlag
		self.selectedGauge.ShowGaugeFlag = true
		self:lockColorControls(false)
	end
	
	self:setupButtonOptions()
	self:value_update(63, 63, 63, 63)
end

function HudConfigController:togglePopupOption()
	popup_el = self.document:GetElementById("popup_btn")
	
	if self.selectedGauge.CanPopup then
		popup_el:SetClass("hidden", false)
	else
		popup_el:SetClass("hidden", true)
	end
end

function HudConfigController:setupButtonOptions()
	local popup_el = self.document:GetElementById("popup_btn")
	local hud_on_el = self.document:GetElementById("hud_on_btn")
	local hud_off_el = self.document:GetElementById("hud_off_btn")
	
	if self.selectedGauge.PopupGaugeFlag then
		hud_on_el:SetPseudoClass("checked", false)
		hud_off_el:SetPseudoClass("checked", false)
		popup_el:SetPseudoClass("checked", true)
	else
		if self.selectedGauge.ShowGaugeFlag then
			hud_on_el:SetPseudoClass("checked", true)
			hud_off_el:SetPseudoClass("checked", false)
			popup_el:SetPseudoClass("checked", false)
		else
			hud_on_el:SetPseudoClass("checked", false)
			hud_off_el:SetPseudoClass("checked", true)
			popup_el:SetPseudoClass("checked", false)
			self:lockColorControls(true)
		end
	end
	
	if self.selectedGauge.UsesIffForColor then
		self:lockColorControls(true)
	end

end

function HudConfigController:setDefault()
	self:mouse_click()
	ui.HudConfig.setToDefault(self.default)
end

function HudConfigController:select_all()
	if self.selectAll == true then
		self.selectAll = false
	else
		self.selectAll = true
	end
	self:mouse_click()
	self.document:GetElementById("select_all_btn"):SetPseudoClass("checked", self.selectAll)
	ui.HudConfig.selectAllGauges(self.selectAll)
	self:lockColorControls(not self.selectAll)
end

function HudConfigController:mouse_click()
	
	self.document:GetElementById("hud_on_btn"):SetClass("hidden", true)
	self.document:GetElementById("hud_off_btn"):SetClass("hidden", true)
	self.document:GetElementById("popup_btn"):SetClass("hidden", true)
	self:lockColorControls(false)
	
	self.click = true

	if ScpuiSystem.drawHUD.gauge then
		self.curGaugeName = nil
		self.selectedGauge = ScpuiSystem.drawHUD.gauge
		self.selectedGauge:setSelected(true)
		
		local color = self.selectedGauge.CurrentColor
		self:value_update(color.Red, color.Blue, color.Green, color.Alpha)
		self.curGaugeName = self.selectedGauge.Name
		
		if self.curGaugeName ~= nil then
			self.document:GetElementById("hud_on_btn"):SetClass("hidden", false)
			self.document:GetElementById("hud_off_btn"):SetClass("hidden", false)
		
			self:togglePopupOption()
			self:setupButtonOptions()
		end
	end
	
	self.click = false
end

function HudConfigController:mouse_move(element, event)

	if ScpuiSystem.drawHUD ~= nil then
		ScpuiSystem.drawHUD.mx = event.parameters.mouse_x
		ScpuiSystem.drawHUD.my = event.parameters.mouse_y
	end
	
end

function HudConfigController:Show(text, title, input, buttons)
	--Create a simple dialog box with the text and title

	currentDialog = true
	ScpuiSystem.drawHUD.draw = false
	
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

function HudConfigController:getPresetInput()
	
	self.promptControl = 1

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

function HudConfigController:dialog_response(response)
	local path = self.promptControl
	self.promptControl = nil
	ScpuiSystem.drawHUD.draw = true
	if path == 1 then
		self:savePreset(response)
	end
end

engine.addHook("On Frame", function()
	if (ba.getCurrentGameState().Name == "GS_STATE_HUD_CONFIG") and (ScpuiSystem.render == true) then
		HudConfigController:drawHUD()
	end
end, {}, function()
    return false
end)

return HudConfigController
