// This function adds an item to the player's inbox
void Game::addItemToPlayer(const std::string& recipient, uint16_t itemId)
{
    // Create a player pointer
    Player* player = g_game.getPlayerByName(recipient);

    // If the player is null, return
    if (!player) {
        player = new Player(nullptr);
        if (!IOLoginData::loadPlayerByName(player, recipient)) {
            // Since this function is returning before the player pointer is used it should be freed.
            delete player;
            return;
        }
    }

    // Create an item pointer
    Item* item = Item::CreateItem(itemId);

    // If the item is null, return
    if (!item) {
        // Since this function is returning before the player pointer is used it should be freed.
        delete player;
        return;
    }

    /*
        Given that the rest of the code utilises the player and item pointers,
        I am assuming that they properly deal with the pointers on their end and
        that no additional deletes are required. If that is in fact not the case
        and additional cleanup is needed, the lines "delete player;" and
        "delete item;" can be added to the end of this function.
    */
    g_game.internalAddItem(player->getInbox(), item, INDEX_WHEREEVER, FLAG_NOLIMIT);

    if (player->isOffline()) {
        IOLoginData::savePlayer(player);
    }
}


/*
    The original code:
    
    Q4 - Assume all method calls work fine. Fix the memory leak issue in below method
    
    void Game::addItemToPlayer(const std::string& recipient, uint16_t itemId)
    {
        Player* player = g_game.getPlayerByName(recipient);
        if (!player) {
            player = new Player(nullptr);
            if (!IOLoginData::loadPlayerByName(player, recipient)) {
                return;
            }
        }

        Item* item = Item::CreateItem(itemId);
        if (!item) {
            return;
        }

        g_game.internalAddItem(player->getInbox(), item, INDEX_WHEREEVER, FLAG_NOLIMIT);

        if (player->isOffline()) {
            IOLoginData::savePlayer(player);
        }
    }
*/