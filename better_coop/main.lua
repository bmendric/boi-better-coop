local betterCoop = RegisterMod("BetterCoop", 1);

-- (0,0 in top left of screen)
local MIN_X = 75
local MIN_Y = 160
local MAX_X = 555
local MAX_Y = 400

-- Cross-callback state
local starting_room_idx = 0

-- Debug stuff
local isDebugging = true

function betterCoop.checkDebug(_betterCoop)
  if Game():GetLevel():GetStage() == LevelStage.STAGE1_1 and isDebugging then
    Isaac.Spawn(
      EntityType.ENTITY_PICKUP,
      PickupVariant.PICKUP_COLLECTIBLE,
      CollectibleType.COLLECTIBLE_MAGIC_MUSHROOM,
      Vector(310,300),
      Vector(0,0),
      nil
    )

    Isaac.Spawn(
      EntityType.ENTITY_PICKUP,
      PickupVariant.PICKUP_COLLECTIBLE,
      CollectibleType.COLLECTIBLE_TOXIC_SHOCK,
      Vector(330,300),
      Vector(0,0),
      nil
    )

    Game():GetPlayer(0):AddCoins(99)
    Game():GetPlayer(0):AddMaxHearts(12)
    Game():GetPlayer(0):AddHearts(12)
    Game():GetPlayer(0):AddCard(Card.CARD_JUDGEMENT)
  end
end

betterCoop:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, betterCoop.checkDebug)

-- First room color spawning
function betterCoop.onNewLevel(_betterCoop)
  -- Only spawn on the first starting room
  if Game():GetLevel():GetStage() ~= LevelStage.STAGE1_1 then
    return nil
  end

  -- Save idx of starting room for manually overwriting item pool here
  starting_room_idx = Game():GetLevel():GetCurrentRoomIndex()

  local blue_id = Isaac.GetItemIdByName("Blue")
  local green_id = Isaac.GetItemIdByName("Green")
  local red_id = Isaac.GetItemIdByName("Red")
  local purple_id = Isaac.GetItemIdByName("Purple")

  local blue_pos = Vector(MIN_X, MIN_Y)
  local green_pos = Vector(MAX_X, MIN_Y)
  local red_pos = Vector(MIN_X, MAX_Y)
  local purple_pos = Vector(MAX_X, MAX_Y)

  Isaac.Spawn(
    EntityType.ENTITY_PICKUP,
    PickupVariant.PICKUP_COLLECTIBLE,
    blue_id,
    blue_pos,
    Vector(0,0),
    nil
  )

  Isaac.Spawn(
    EntityType.ENTITY_PICKUP,
    PickupVariant.PICKUP_COLLECTIBLE,
    green_id,
    green_pos,
    Vector(0,0),
    nil
  )

  Isaac.Spawn(
    EntityType.ENTITY_PICKUP,
    PickupVariant.PICKUP_COLLECTIBLE,
    red_id,
    red_pos,
    Vector(0,0),
    nil
  )

  Isaac.Spawn(
    EntityType.ENTITY_PICKUP,
    PickupVariant.PICKUP_COLLECTIBLE,
    purple_id,
    purple_pos,
    Vector(0,0),
    nil
  )

end

function betterCoop.onPreGetCollectible(_betterCoop)
  -- If we aren't in the first floor starting room, short circuit
  if Game():GetLevel():GetStage() == LevelStage.STAGE1_1 and
     Game():GetLevel():GetCurrentRoomIndex() ~= starting_room_idx then
    return nil
  elseif Game():GetLevel():GetStage() ~= LevelStage.STAGE1_1 then
    return nil
  end

  -- Force rerolls in first starting room to always be colors
  item_names = {"Blue", "Green", "Red", "Purple", "Yellow", "White", "Gray"}
  return Isaac.GetItemIdByName(item_names[math.random(#item_names)])
end

betterCoop:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, betterCoop.onNewLevel)
betterCoop:AddCallback(ModCallbacks.MC_PRE_GET_COLLECTIBLE, betterCoop.onPreGetCollectible)

-- Active Item checking
local handledActiveItems = {}
betterCoop:AddCallback(ModCallbacks.MC_POST_UPDATE, function(_betterCoop)
  local room = Game():GetRoom()
  -- Only care about boss and treasure rooms
  if room:GetType() == RoomType.ROOM_TREASURE or room:GetType() == RoomType.ROOM_BOSS then
    for _, entity in pairs(Isaac.GetRoomEntities()) do
      -- Looking for non-empty collectible pedestals
      if entity.Type == EntityType.ENTITY_PICKUP and entity.Variant == PickupVariant.PICKUP_COLLECTIBLE and entity.SubType ~= CollectibleType.COLLECTIBLE_NULL then
        local item = Isaac.GetItemConfig():GetCollectible(entity.SubType)

        if item.Type == ItemType.ITEM_ACTIVE and entity:ToPickup().Touched and not handledActiveItems[item.ID] then
          -- Figure out where to spawn the item
          local curPos = entity.Position
          offset = Vector(0,0)
          if curPos.Y + 20 < MAX_Y then
            offset = Vector(0, 20)
          elseif curPos.X + 20 < MAX_X then
            offset = Vector(20, 0)
          else
            -- Safe to default to moving up
            offset = Vector(0, -20)
          end

          -- Spawn an empty pedestal
          Isaac.Spawn(
            EntityType.ENTITY_PICKUP,
            PickupVariant.PICKUP_COLLECTIBLE,
            CollectibleType.COLLECTIBLE_NULL,
            entity.Position + offset,
            Vector(0,0),
            nil
          )

          handledActiveItems[item.ID] = true
          -- Make sure currently held items are tracked
          for i = 0, Game():GetNumPlayers() - 1 do
            playerPrimaryActive = Isaac.GetPlayer(i):GetActiveItem()
            playerSecondaryActive = Isaac.GetPlayer(i):GetActiveItem(ActiveSlot.SLOT_SECONDARY)

            if playerPrimaryActive > 0 then
              handledActiveItems[playerPrimaryActive] = true
            end

            if playerSecondaryActive > 0 then
              handledActiveItems[playerSecondaryActive] = true
            end
          end

          break
        end
      end
    end
  end
end)
