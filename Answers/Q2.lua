-- This function prints names of all guilds that have less than memberCount max members
function printSmallGuildNames(memberCount)
    -- SQL query for getting the names of the guilds with small enough memberCounts
    local selectGuildQuery = "SELECT name FROM guilds WHERE max_members < %d;"
    local resultId = db.storeQuery(string.format(selectGuildQuery, memberCount))

    --[[
        This follows the format found in the other files in theforgottenserver where first the result is
        checked to ensure it returned properly, then its values are looped over in a repeat statement.
        This needs to be done as the storeQuery is likely to return more than one name.
    ]]--
    if resultId ~= false then
		repeat
            local guildName = result.getString("name")
			print(guildName)
		until not result.next(resultId)
		result.free(resultId)
	end
end

--[[
    The original code:

    Q2 - Fix or improve the implementation of the below method

    function printSmallGuildNames(memberCount)
        -- this method is supposed to print names of all guilds that have less than memberCount max members
        local selectGuildQuery = "SELECT name FROM guilds WHERE max_members < %d;"
        local resultId = db.storeQuery(string.format(selectGuildQuery, memberCount))
        local guildName = result.getString("name")
        print(guildName)
    end
]]--