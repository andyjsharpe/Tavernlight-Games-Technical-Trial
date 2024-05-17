--[[
  My general methodology for this menu was to have a toggleable window like the one found in the
  game_spellist module, but to have it contain a button which continously moves to the left until hitting
  the edge of the window, but when clicked resets its position to the right side of the window at a random
  height.

  To create the illusion of continous movement I use a function which recursively schedules itself at a
  set interval and moves the button a set number of pixels, which at lwo enough values will look smooth to
  the user. The animation behavior and window layout can be controlled using the vales in the parameters section.

  To test this in-game make sure to load the game_jumpmenu module in the OTClient, then when in-game click
  the box in the top-right corner with an arrow symbol pointing up (it will have the hover text "Jump Menu").
]]--

--[[ PARAMETERS: These change how the window and animation behave ]]---------------------------------------

-- Window size values
WINDOW_SIZE = 400
JUMP_BOUNDRY_X = 100
JUMP_BOUNDRY_Y = 75

-- How long each step should last in ms, smaller values look smoother
STEP_MS = 10
-- How large each step should be in pixels, smaller values look smoother
STEP_PIXELS = 1


--[[ GLOBAL VALUES: These are values used in multiple of the functions below ]]-----------------------------

-- UI references
jumpWindow = nil
jumpToggleButton = nil
jumpButton = nil

-- These values store the locatiion of the "Jump!" button
buttonX = 0
buttonY = 0

-- These values store the upper bounds of where the button can be placed
maxSizeX = WINDOW_SIZE - JUMP_BOUNDRY_X
maxSizeY = WINDOW_SIZE - JUMP_BOUNDRY_Y


--[[ FUNCTIONS: See each function's comment for what it does ]]-----------------------------------------------

-- This function sets up the ui for this script
function init()
  connect(g_game, { onGameStart = online,
                    onGameEnd   = offline })

  -- Create the window to hold this ui, then hide it
  jumpWindow = g_ui.displayUI('jumpmenu', modules.game_interface.getRightPanel())
  jumpWindow:setWidth(WINDOW_SIZE)
  jumpWindow:setHeight(WINDOW_SIZE)
  jumpWindow:hide()

  -- Create the button that toggles the window
  jumpToggleButton = modules.client_topmenu.addRightGameToggleButton('jumpButton', tr('Jump Menu'), '/images/topbuttons/hotkeys', toggle)
  jumpToggleButton:setOn(false)

  -- Get a reference to the "jump!" button
  jumpButton = jumpWindow:getChildById('buttonJump')

  -- This starts continously moving the button left
  moveJumpLeft()

  if g_game.isOnline() then
    online()
  end
end

-- This function is called on unload, closes this window and disconnects from the game
function terminate()
  disconnect(g_game, { onGameStart = online,
                       onGameEnd   = offline })

  jumpWindow:destroy()
  jumpToggleButton:destroy()
end

-- This function is called when the "Jump!" button is pressed
function doJump()
  -- Randomize the y position of the button
  buttonY = math.random(0, maxSizeY)
  -- Reset the x position of the button
  buttonX = 0
  reloadJumpButton()
end

-- This function changes the button's position to match the values set by the
-- buttonX and buttonY variables
local function reloadJumpButton()
  -- I am setting the position of the button by using the margins as that avoids
  -- having to do some addition math
  jumpButton:setMarginRight(buttonX)
  jumpButton:setMarginBottom(buttonY)
end

-- This moves the jump button left 
function moveJumpLeft()
  -- Only move the button if the window is toggled on
  if jumpToggleButton:isOn() then
    buttonX = buttonX + STEP_PIXELS
    -- This ensures that the button does not move out of the window
    if buttonX > maxSizeX then
      buttonX = maxSizeX
    end
    reloadJumpButton()
  end
  -- Schedule this same event to occur after a set period to create
  -- continous movement
  scheduleEvent(function() moveJumpLeft() end, STEP_MS)
end

-- Hides the ui for this file
local function toggleWindowOff()
  jumpWindow:hide()
  jumpToggleButton:setOn(false)
end

-- This function is used to toggle the window on and off
function toggle()
  if jumpToggleButton:isOn() then
    toggleWindowOff()
  else
    jumpToggleButton:setOn(true)
    jumpWindow:show()
    jumpWindow:raise()
    jumpWindow:focus()
    -- Since we want the button to start on the right when we open the window,
    -- we do our own jump when the window is toggled on
    doJump()
  end
end

-- Since the client attempts to call this when going online I am leaving
-- an empty function with this name here even though it does nothing
function online() end

-- When going offline toggle the window off
function offline()
  toggleWindowOff()
end