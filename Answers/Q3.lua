

--[[
    Q3 - Fix or improve the name and the implementation of the below method

    function do_sth_with_PlayerParty(playerId, membername)
        player = Player(playerId)
        local party = player:getParty()

        for k,v in pairs(party:getMembers()) do
            if v == Player(membername) then
                party:removeMember(Player(membername))
            end
        end
    end
]]--