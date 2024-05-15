

--[[
    Q2 - Fix or improve the implementation of the below method

    function printSmallGuildNames(memberCount)
        -- this method is supposed to print names of all guilds that have less than memberCount max members
        local selectGuildQuery = "SELECT name FROM guilds WHERE max_members < %d;"
        local resultId = db.storeQuery(string.format(selectGuildQuery, memberCount))
        local guildName = result.getString("name")
        print(guildName)
    end
]]--