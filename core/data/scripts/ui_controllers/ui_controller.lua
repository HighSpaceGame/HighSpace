local Class         = require("class")
local Inspect       = require('inspect')
local UIController  = Class()

UIController.MOUSE_BUTTON_LEFT   = 0
UIController.MOUSE_BUTTON_RIGHT  = 1
UIController.MOUSE_BUTTON_MIDDLE = 2

UIController.Mouse = {
    ["X"] = 0.0, ["Y"] = 0.0,
    ["Buttons"] = {
        [0] = false,
        [1] = false,
        [2] = false,
    }
}

--- Stores the mouse button state after a button was pressed
--- @generic Ev
--- @generic El
--- @generic D
--- @param event Ev[] the onmousedown event
--- @param element El[] the element firing the event
--- @param document D[] the document firing the event
function UIController:storeMouseDown(event, _, _)
    UIController.Mouse.Buttons[event.parameters.button] = true
    ba.println("mouseDown: " .. event.parameters.button)
end

--- Stores the mouse button state after a button was released
--- @generic Ev
--- @generic El
--- @generic D
--- @param event Ev[] the onmousedown event
--- @param element El[] the element firing the event
--- @param document D[] the document firing the event
function UIController:storeMouseUp(event, _, _)
    UIController.Mouse.Buttons[event.parameters.button] = false
    ba.println("mouseUp: " .. event.parameters.button)
end

--- Stores the mouse cursor coordinates on mouse move
--- @generic Ev
--- @generic El
--- @generic D
--- @param event Ev[] the onmousedown event
--- @param element El[] the element firing the event
--- @param document D[] the document firing the event
function UIController:storeMouseMove(event, _, element)
    self.Mouse.X = event.parameters.mouse_x - element.offset_left
    self.Mouse.Y = event.parameters.mouse_y - element.offset_top

    --ba.println("mouseMove: " .. inspect(self.Mouse))
end

return UIController