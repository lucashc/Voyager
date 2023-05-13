-- Copyright © OutLauz

-------------------
-- Main Bot code --
-------------------

function bot_init(me)
end

-- Main bot function
-- Called every tick
-- @param me The bot
function bot_main(me)
    -- Select closest player
    local entities = me:visible()
    local closest_player_distance = 1000
    local closest_player_pos = nil
    local closest_player_direction = nil
    for _, entity in ipairs(entities) do
        if entity:type() == "player" then
            if entity:id() == me:id() then
                goto continue
            end

            local pos = entity:pos()
            if vec.distance(pos, me:pos()) < closest_player_distance then
                closest_player_pos = pos
                closest_player_distance = vec.distance(pos, me:pos())
                closest_player_direction = pos:sub(me:pos())
            end
        end
        ::continue::
    end
    me:move(closest_player_direction)
    if closest_player_distance < 2 then
        me:cast(2, vec.new(0, 0))
    else
        me:cast(0, closest_player_direction)
    end
end