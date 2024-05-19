--[[
	My general methodology for this spell is to quickly move the player a certain number of tiles 
	in the direction that they faced at the start of the dash while	making sure that they do not
	move through objects they are not allowed to on each step.
	
	I was not able to figure out how to have the fading player afterimage effect shown in the
	example video, so I instead decided to create a animated effect on the path you dash over
	instead.
]]--


--[[ PARAMETERS: Use these to control how the dash behaves ]]------------------------------

-- How many tiles the player moves when they dash
local MOVE_TILES = 10

-- How long does it take in ms for the player to move a single tile
local FRAME_LENGTH = 20

-- The tilestates that cannot be dashed through
local DONT_DASH_THROUGH = { TILESTATE_BLOCKSOLID, TILESTATE_BLOCKPATH }


--[[ HELPER FUNCTIONS ]]---------------------------------------------------------------------------------------

-- Checks if a tile can be dashed through
function checkTileDashable(tile)
	for _, tilestate in pairs(DONT_DASH_THROUGH) do
		if tile:hasFlag(tilestate) then
			return false
		end
	end
	return true
end

-- Returns the change in position which would be caused by moving in the input direction
function directionToPositionOffset(direction)
	local offsets = {
		Position(0, -1, 0),
		Position(1, 0, 0),
		Position(0, 1, 0),
		Position(-1, 0, 0),
		Position(-1, 1, 0),
		Position(1, 1, 0),
		Position(-1, -1, 0),
		Position(1, -1, 0)
	}

	-- 1 is added to the direction to correct for the 1-indexing of arrays
    return offsets[direction + 1]
end

-- Applies a single dash step
function doDashStep(data)
	local player = data.player
	-- If it was decided in the future that this move should do damage the variant
	-- reference can be used to create a new combat
	local variant = data.variant
	local direction = data.direction

	local positionOffsetFromDirection = directionToPositionOffset(direction)

	-- Store the position the player starts at
	local startPos = player:getPosition()

	-- Try to move the player one tile
	local newPos = startPos + positionOffsetFromDirection
	local tile = Tile(newPos)
	if tile ~= nil and checkTileDashable(tile) then
		-- If the player can move forward do so and maintain the direction they were looking
		player:teleportTo(newPos, true)
		player:setDirection(direction)

		-- I was not able to figure out how to show the player's afterimage, so I am using a
		-- default magic effect instead to show the path they have traveled
		newPos:sendMagicEffect(CONST_ME_GROUNDSHAKER)
	end
end


--[[ SPELL CASTING FUNCTION ]]-------------------------------------------------------------------------

-- When the spell is cast add events to represent the dash steps
function onCastSpell(creature, variant)
	-- I am putting the data in a dict to avoid locality arrors
	local direction = creature:getDirection()
	local data = {player = creature, variant = variant, direction = direction}

	for i = 1, MOVE_TILES do
		local timeFromStart = i * FRAME_LENGTH
		addEvent(doDashStep, timeFromStart, data)
	end

	return true
end
