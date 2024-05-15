-- This function removes a player from another player's party based on their name
--[[
    I decided to rename the function to this to make its use clearer.
    While it is a bit long, I believe that it is an appropriate tradeoff
    for the clarity it brings.
]]--
function removePlayerFromPartyByName(playerId, membername)
    player = Player(playerId)
    local party = player:getParty()

    -- Loop over the members in the party and remove any with a matching name
    for k,v in pairs(party:getMembers()) do
        -- I created an additional variable to avoid having repeated code for Player(membername)
        local playerToFind = Player(membername)

        if v == playerToFind then
            party:removeMember(playerToFind)
        end
    end
end

--[[
    The original code:
    
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