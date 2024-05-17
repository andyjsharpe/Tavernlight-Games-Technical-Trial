--[[
	My general methodology for this spell is to pre-calculate a number of randomized "frames"
	for the spell to be in, then to set up a number of events which apply combat and visual effects
	when it is time for each frame to occur.
	
	I decided to decouple the combat and visual effects as I did not know if one may want to also have
	the damage randomly applyed to tiles like the visual effects area, or if the visuals are just
	flair and the damage is meant to be applied uniformly. As of now the damage and visuals
	are aligned, but switching the code so that is not the case should be easy and is explained in a
	comment lower down in this file where the createCombatArea function is used.
]]--


--[[ PARAMETERS: Use these to control how the spell's animation behaves ]]------------------------------

-- The number of animation frames (this is how many times damage is applied and visuals are changed)
local TOTAL_FRAMES = 20

-- How long we consider a frame to be in ms (this is how often damage applies and visuals change)
local FRAME_LENGTH = 200

-- The length of a effect animation in ms (in this case a tornado appearing and dissapearing)
local ANIM_LENGTH = 800

--[[
	This represents the damage done over the entire spell duration for each space,
	so they should equal the damage for a single hit multiplied by the TOTAL_FRAMES value.
	The reason I did it this way is because I felt that it is more important for designers to
	consider the total damage output of a spell rather than each indivisual hit for a multi-frame
	attack such as this.

	As I am not yet familiar with how damage calculations are made I just have these values for now
	which are used to set the COMBAT_FORMULA_LEVELMAGIC formula later in the file. The spell still
	applies damage in-game so I believe this is acceptable for the time being
]]--
local MIN_TOTAL_DAMAGE = 50
local MAX_TOTAL_DAMAGE = 100

-- How much falloff the ramp up/down of the animation has
--[[
	Higher values have less falloff, lower values have more
	Look at the getCutoff function for more info about what this does
	I set it to 2 since that seems to work well, but you can use any even positive number
]]--
local ANIMATION_FALLOFF = 2

-- The damage area for the spell, this code assumes the table will be square (same width and height)
-- I made this a bit bigger than in the example to make it easier to see the randomness
local DAMAGE_AREA = {
	{0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0},
	{0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0},
	{0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0},
	{0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0},
	{0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0},
	{1, 1, 1, 1, 1, 3, 1, 1, 1, 1, 1},
	{0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0},
	{0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0},
	{0, 0, 0, 1, 1, 1, 1, 1, 0, 0, 0},
	{0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0},
	{0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0}
}


--[[ HELPER FUNCTIONS ]]------------------------------------------------------------------------------

-- This function is used to interpolate the probability of tornados appearing
-- depending on how far into the spell we are
-- Equation created in Desmos at: https://www.desmos.com/calculator/soyrxugvjn
local function getCutoff(normalizedCompletion, exponent)
	local toPower = 1 - 2 * normalizedCompletion
	-- Since the Math.Pow function in Lua is depreciated, I am calculating the
	-- power using a loop instead just to be safe
	local product = 1
	for i=1,exponent do
		product = product * toPower
	end
	return 1 - product
end

-- Executes combat and visual effects after validation
-- This is intended to be used in an addEvent call
function executeCombat(data, combat, effectArea)
	local player = data.player
	local variant = data.variant

	-- Validate the player
    if not player then
        return false
    end
    if not player:isPlayer() then
        return false
    end

	-- Executes the combat
    combat:execute(player, variant)

	-- Create the spell effects
	local areaSize = #effectArea
	local playerPos = player:getPosition()
	local centerOffset = math.ceil(areaSize / 2)

	for j=1,areaSize do
		for k=1,areaSize do
			if effectArea[j][k] ~= 0 then
				local spellPos = playerPos + Position(j - centerOffset, k - centerOffset, 0)
				spellPos:sendMagicEffect(CONST_ME_ICETORNADO)
			end
		end
	end
end

-- Used to deep copy the DAMAGE_AREA for each frame to be modified
local function copyArea(area)
	local areaSize = #area
	local newArea = {}
	for j=1,areaSize do
		local row = {}
		for k=1,areaSize do
			row[k] = area[j][k]
		end
		newArea[j] = row
	end
	return newArea
end


--[[ PRE-CALCULATE FRAME DATA ]]---------------------------------------------------------------

-- How much to reduce the probability of an attack effect to correct for animation overlap
local animOverlapCorrection = FRAME_LENGTH / ANIM_LENGTH

-- Setup the combat and effect tables
local tornadoCombats = {}
local tornadoEffects = {}

local areaSize = #DAMAGE_AREA

local minDamagePerFrame = -MIN_TOTAL_DAMAGE / TOTAL_FRAMES
local maxDamagePerFrame = -MAX_TOTAL_DAMAGE / TOTAL_FRAMES

-- Pre-calculate each frame's data
for i = 1, TOTAL_FRAMES do
	local completion = i / (TOTAL_FRAMES + 1)

	-- Calculates the probability of an attack effect occuring this frame
	local cutoff = getCutoff(completion, ANIMATION_FALLOFF) * animOverlapCorrection

	local effectArea = copyArea(DAMAGE_AREA)
	
	-- Randomize the effect area
	for j=1,areaSize do
		for k=1,areaSize do
			local positionValue = effectArea[j][k]
			if positionValue ~= 0 then
				-- If the random value chosen is higher than the cutoff,
				-- then do not spawn a torando at that location
				local randomVal = math.random()
				if randomVal > cutoff then
					if positionValue == 1 then
						effectArea[j][k] = 0
					else
						-- If this is the casting position, change it from 3 to 2
						effectArea[j][k] = 2
					end
				end
			end
		end
	end

	-- Save this frame's effect
	tornadoEffects[i] = effectArea

	-- Add the torando combat for this frame
	local tornadoCombat = Combat()
	tornadoCombat:setParameter(COMBAT_PARAM_TYPE, COMBAT_ICEDAMAGE)
	tornadoCombat:setFormula(COMBAT_FORMULA_LEVELMAGIC, 0, minDamagePerFrame, 0, maxDamagePerFrame)

	-- If you want to seperate the damage and visual effects, use damageArea instead of
	-- effectArea in the following line
	tornadoCombat:setArea(createCombatArea(effectArea))

	-- Save this frame's conbat info
	tornadoCombats[i] = tornadoCombat
end


--[[ SPELL CASTING FUNCTION ]]-------------------------------------------------------------------------

-- When the spell is cast add events to represent the spell frames
function onCastSpell(creature, variant)
	-- I am putting the data in a dict to avoid locality arrors
	local data = {player = creature, variant = variant}
	for i = 1, TOTAL_FRAMES do
		local timeFromStart = i * FRAME_LENGTH
		addEvent(executeCombat, timeFromStart, data, tornadoCombats[i], tornadoEffects[i])
	end
	
	return true
end