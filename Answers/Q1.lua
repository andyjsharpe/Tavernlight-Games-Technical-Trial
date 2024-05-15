-- This function clears releases the storage value with storageKey from the player's storage
--[[
    I changed this implementation to not be hardcoded to use key 1000 to make it more reusable,
    as it seems likely that there many be multiple situations were releasing storage may be wanted.
    For this reason I also removed the local identifier so it would be able to be used in other files.
]]--
function releaseStorage(player, storageKey)
    -- This behavior where -1 causes a clear is explained here:
    -- https://otland.net/threads/whats-the-reason-you-cant-set-storage-to-1.279950/post-2687474
    player:setStorageValue(storageKey, -1)
end

-- This function is called when the player logs out 
--[[
    I am assuming this would be placed in logout.lua, which also has a onLogout function
]]--
function onLogout(player)
    --[[
        I did not find the key 1000 in storages.lua, so I am going to assume it acts like way to mark
        if a player is online or not. I am unsure if it would then be better to release this value
        from storage right on logout (rather than after 1 second) to avoid issues in other parts of
        the code, but I am leaving it for now as I do not have the ability to make a more informed
        decision.
    ]]--
    -- I created an additional variable to avoid having multiple hardcoded 1000 values for the key
    local keyToClear = 1000

    -- If the storage value with key 1000 is 1, release it from the database after 1 second (1000 ms)
    if player:getStorageValue(keyToClear) == 1 then
        addEvent(releaseStorage, 1000, player, keyToClear)
    end
    
    return true
end

--[[
    The original code:

    Q1 - Fix or improve the implementation of the below methods

    local function releaseStorage(player)
        player:setStorageValue(1000, -1)
    end

    function onLogout(player)
        if player:getStorageValue(1000) == 1 then
            addEvent(releaseStorage, 1000, player)
        end
        return true
    end
]]--