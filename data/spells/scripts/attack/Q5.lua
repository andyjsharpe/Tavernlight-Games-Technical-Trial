-- My method is partially based on this post: https://otland.net/threads/tfs-1-x-animated-spells-dynamic-vs-static.268186/

-- These masks represent the areas that the tornados can cover
local smallTornadoMask = {
	{0, 0, 0, 1, 0, 0, 0},
	{0, 0, 0, 0, 0, 0, 0},
	{0, 1, 0, 1, 0, 1, 0},
	{0, 0, 0, 0, 0, 0, 0},
	{0, 1, 0, 1, 0, 1, 0},
	{0, 0, 0, 0, 0, 0, 0},
	{0, 0, 0, 1, 0, 0, 0}
}

local bigTornadoMask = {
	{0, 0, 0, 0, 0, 0, 0},
	{0, 0, 1, 0, 1, 0, 0},
	{0, 0, 0, 0, 0, 0, 0},
	{1, 0, 1, 0, 1, 0, 1},
	{0, 0, 0, 0, 0, 0, 0},
	{0, 0, 1, 0, 1, 0, 0},
	{0, 0, 0, 0, 0, 0, 0}
}

-- Makes it so that only the values in the area which also have mask values are used
local function applyMaskToArea(area, mask, size)
	local newArea = {
		{0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0},
		{0, 0, 0, 0, 0, 0, 0}
	}
	for a=1,size do
		for b=1,size do
			local maskVal = mask[a][b]
			if maskVal ~= 0 then
				-- Masking with multiplication should be fast enough, though a comparison may be faster
				newArea[a][b] = area[a][b] * maskVal;
			end
		end
	end
	return newArea
end

-- Used to interpolate the probability of tornados appearing
-- Equation created in Desmos at: https://www.desmos.com/calculator/soyrxugvjn
-- The exponent controls the falloff, should be an int to work properly
local function getCutoff(normalizedCompletion, exponent)
	local toPower = 1 - 2 * normalizedCompletion
	-- Since the power function in Lua is depreciated, I am calculating using a loop instead
	local product = 1
	for z=1,exponent do
		product = product * toPower
	end
	return 1 - product
end

-- Setup the combat arrays
local smallTornadoCombats = {}
local bigTornadoCombats = {}

-- The number of animation frames (equal to the length of the tornado arrays)
local totalFrames = 8

-- How long we consider a frame to be in ms
local frameLength = 200

-- Damage values are hardcoded for now
local min = 20
local max = 50

-- Pre-calculate the combat data for the spell on each timestep
for i = 1, totalFrames do
	local completion = i / (totalFrames + 1)

	-- Exponent is hardcoded to 2 since that seems to work well
	local cutoff = getCutoff(completion, 2)
	-- print(i .. "/" .. totalFrames .. ": " .. completion .. ": " .. cutoff)

	-- Create a new random area
	local area = {
		{0, 0, 0, 1, 0, 0, 0},
		{0, 0, 1, 0, 1, 0, 0},
		{0, 1, 0, 1, 0, 1, 0},
		{1, 0, 1, 0, 1, 0, 1},
		{0, 1, 0, 1, 0, 1, 0},
		{0, 0, 1, 0, 1, 0, 0},
		{0, 0, 0, 1, 0, 0, 0}
	}
	-- The area size is hardcoded for now, in the future it could be made to be more generic
	-- if it would be helpful elsewhere
	local size = 7

	for k=1,size do
		for j=1,size do
			if area[k][j] ~= 0 then
				-- If the random value chosen is higher than the cutoff,
				-- then do not spawn a torando at that location
				local randomVal = math.random()
				if randomVal > cutoff then
					area[k][j] = 0
				end
			end
		end
	end

	-- Add the small torando attack
	local smallTornadoCombat = Combat()
	smallTornadoCombat:setParameter(COMBAT_PARAM_TYPE, COMBAT_ENERGYDAMAGE)
	smallTornadoCombat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_HITAREA)
	smallTornadoCombat:setFormula(COMBAT_FORMULA_LEVELMAGIC, 0, -min, 0, -max)
	local maskedAreaSmall = applyMaskToArea(area, smallTornadoMask, size)
	smallTornadoCombat:setArea(createCombatArea(maskedAreaSmall))

	smallTornadoCombats[i] = smallTornadoCombat

	-- Add the big torando attack
	local bigTornadoCombat = Combat()
	bigTornadoCombat:setParameter(COMBAT_PARAM_TYPE, COMBAT_ENERGYDAMAGE)
	smallTornadoCombat:setParameter(COMBAT_PARAM_EFFECT, CONST_ME_ENERGYHIT)
	bigTornadoCombat:setFormula(COMBAT_FORMULA_LEVELMAGIC, 0, -min, 0, -max)
	local maskedAreaBig = applyMaskToArea(area, bigTornadoMask, size)
	bigTornadoCombat:setArea(createCombatArea(maskedAreaBig))

	bigTornadoCombats[i] = bigTornadoCombat
end

-- Checks that everything is still valid when the damage is applied in the future
function executeCombat(data, combat)
    if not data.player then
        return false
    end
    if not data.player:isPlayer() then
        return false
    end
    combat:execute(data.player, data.var)
end

function onCastSpell(creature, variant)
	local data = {player = creature, var = variant}
	-- Add the combat events
	for l = 1, totalFrames do
		local deltaFromStart = l * frameLength
		addEvent(executeCombat, deltaFromStart, data, smallTornadoCombats[l])
		addEvent(executeCombat, deltaFromStart, data, bigTornadoCombats[l])
	end
	
	return true
end