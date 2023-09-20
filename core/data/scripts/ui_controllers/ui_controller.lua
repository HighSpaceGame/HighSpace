local Class         = require("class")
local Inspect       = require('inspect')
local Vector        = require('vector')

local UIController  = Class()

UI_CONST = {}
UI_CONST.MOUSE_BUTTON_LEFT   = 0
UI_CONST.MOUSE_BUTTON_RIGHT  = 1
UI_CONST.MOUSE_BUTTON_MIDDLE = 2

UIController.Mouse = {
    ["Cursor"] = Vector(),
    ["Buttons"] = {
        [0] = false,
        [1] = false,
        [2] = false,
    }
}

UIController.Keys = {}

function UIController:frame()

end

function UIController:frameOverride()
    return true
end

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
    self.Mouse.Cursor.x = event.parameters.mouse_x - element.offset_left
    self.Mouse.Cursor.y = event.parameters.mouse_y - element.offset_top

    --ba.println("mouseMove: " .. inspect(self.Mouse))
end

--- Stores the key state after a key was pressed
--- @generic Ev
--- @generic El
--- @generic D
--- @param event Ev[] the onkeydown event
--- @param element El[] the element firing the event
--- @param document D[] the document firing the event
function UIController:storeKeyDown(event, _, _)
    UIController.Keys[event.parameters.key_identifier] = true
    ba.println("keyDown: " .. Inspect({ event.parameters.key_identifier }))
end

--- Stores the key state after a key was released
--- @generic Ev
--- @generic El
--- @generic D
--- @param event Ev[] the onkeydown event
--- @param element El[] the element firing the event
--- @param document D[] the document firing the event
function UIController:storeKeyUp(event, _, _)
    UIController.Keys[event.parameters.key_identifier] = false
    ba.println("keyUp: " .. event.parameters.key_identifier)
end

return UIController