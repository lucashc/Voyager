-- Copyright © OutLauz

---------------------------
-- Global Game Constants --
---------------------------

-- Playing Field Size
-- It is 500×500, with center (250, 250)
local FIELD_SIZE = 500
local FIELD_CENTER = vec.new(FIELD_SIZE / 2, FIELD_SIZE / 2)

-- Tick Statistics
local TICKS_PER_SECOND = 30

-- Base Speed
local BASE_SPEED_PER_SECOND = 1
local BASE_SPEED_PER_TICK = BASE_SPEED_PER_SECOND / TICKS_PER_SECOND

-- Base Health
local BASE_HEALTH = 100

-- Cooldowns
local DASH_COOLDOWN = 250
local BULLET_COOLDOWN = 30
local MELEE_COOLDOWN = 50

-- Dash Speed
local DASH_SPEED = 10

-- Bullet Statistics
local BULLET_SPEED_PER_SECOND = BASE_SPEED_PER_SECOND * 4
local BULLET_SPEED_PER_TICK = BULLET_SPEED_PER_SECOND / TICKS_PER_SECOND
local BULLET_DAMAGE = 10

-- Melee Statistics
local MELEE_RANGE = 2
local MELEE_DAMAGE = 20

-- Circle of Deatch Statistics (per tick)
local COD_DAMAGE = 1


-------------
-- Globals --
-------------

-- Other players
-- A list of other players
-- Each player is a tabel indexed by id with the following fields:
-- - pos: The player's positions, [1] is last, contains last 5 positions
-- - direction: Difference between the player's last position and current position
-- - dash_cooldown: The player's last dash cooldown
-- - bullet_cooldown: The player's last bullet cooldown
-- - bullets_spawned: Number of bullets spawned by the player for the entire game
local others = {}

-- Bullets in the air
-- List of all bullets
-- - id: The bullet's id (now stable!)
-- - position: The bullet's position
-- - direction: The bullet's direction
local bullets = {}


----------------------
-- Helper Functions --
----------------------

-- Print all the functions in an object's metatable
function dump_functions(x)
    local t = getmetatable(x)

    if t == nil then
        return
    end

    for k, v in pairs(t) do
        print(k, v)
    end
end

-- Returns the norm of a vector
-- @param vector to take norm of
-- @return norm of vector
function norm(vector)
    return vec.distance(vector, vec.new(0, 0))
end


-- Normalise a vector
-- @param vector to normalise
-- @return normalised vector
function normalise(vector)
    local norm_vec = norm(vector)
    if norm_vec <= 1e-9 then
        return vector
    end
    return div_vec(vector, vec.new(norm_vec, norm_vec))
end

-- Dot product
-- @param vec1 First vector
-- @param vec2 Second vector
-- @return Dot product of vec1 and vec2
function dot_vec(vec1, vec2)
    return vec1:x() * vec2:x() + vec1:y() * vec2:y()
end

-- Vector div
-- @param vec1 First vector
-- @param vec2 Second vector
-- @return vec1 / vec2
function div_vec(vec1, vec2)
    return vec.new(vec1:x() / vec2:x(), vec1:y() / vec2:y())
end

-- Check if floats are close
-- @param num1 First number
-- @param num2 Second number
-- @return true if num1 and num2 are close, false otherwise
function is_close(num1, num2)
    return math.abs(num1 - num2) < 0.0001
end

---------------------------
-- Our Agent's functions --
---------------------------

-- Does a melee attack
-- Has a cooldown of 50 ticks
-- @param me The bot
function do_melee(me)
    local fake_direction = vec.new(0, 0)
    me:cast(2, fake_direction)
end


-- Does a projectile attack
-- Has a cooldown of 1 tick
-- @param me The bot
-- @param direction The direction to fire the projectile
function do_projectile(me, direction)
    me:cast(0, direction)
end

function do_projectile_at(me, target_pos)
    local direction = target_pos:sub(me:pos())
    do_projectile(me, direction)
end


-- Does a dash
-- Has a cooldown of 260 ticks
-- @param me The bot
-- @param direction The direction to dash
function do_dash(me, direction)
    me:cast(1, direction)
end


-----------------------------
-- Other Agent's functions --
-----------------------------

function update_others_players(me)
    local entities = me:visible()
    -- Update other players
    for _, entity in ipairs(entities) do
        -- First check players
        if entity:type() == "player" then
            local id = entity:id()
            -- Check if it is us
            if id == me:id() then
                goto continue
            end
            -- Update others
            local new_pos = entity:pos()
            -- Not seen before
            if others[id] == nil then
                others[id] = {
                    pos = {new_pos, new_pos, new_pos, new_pos, new_pos},
                    direction = vec.new(0, 0),
                    dash_cooldown = 0,
                    bullet_cooldown = 0,
                    bullets_spawned = 0
                }
            -- Seen before
            else
                -- Check if dashed
                if vec.distance(new_pos, others[id].pos[1]) > BASE_SPEED_PER_TICK then
                    others[id].dash_cooldown = DASH_COOLDOWN
                end
                -- Update
                others[id].direction = new_pos:sub(others[id].pos[1])
                local old_pos = others[id].pos
                others[id].pos = {new_pos, old_pos[1], old_pos[2], old_pos[3], old_pos[4]}
            end
        end
        ::continue::
    end
end

function update_others_bullets(me)
    local entities = me:visible()
    -- Update other players
    for _, entity in ipairs(entities) do
        -- Then check bullets
        if entity:type() == "small_proj" then
            local id = entity:id()
            local bullet_pos = entity:pos()
            -- print("bullet with id " .. id .. " has position " .. pos:x() .. ", " .. pos:y())
            -- Not seen before
            if bullets[id] == nil then
                local owner_id = entity:owner_id()
                if owner_id == me:id() then
                    goto continue
                end

                local old_user_pos = others[owner_id].pos[2]
                local direction = bullet_pos:sub(old_user_pos)
                direction = normalise(direction)

                others[owner_id].bullet_cooldown = BULLET_COOLDOWN
                others[owner_id].bullets_spawned = others[owner_id].bullets_spawned + 1

                bullets[id] = {
                    owner_id = owner_id,
                    position = bullet_pos,
                    direction = direction
                }
            -- Seen before
            else
                bullets[id].position = bullet_pos
            end
        end

        ::continue::
    end
end

function update_others(me)
    update_others_players(me)
    update_others_bullets(me)
end

function update_others_cooldowns(me)
    for _, player in pairs(others) do
        if player.dash_cooldown > 0 then
            player.dash_cooldown = player.dash_cooldown - 1
        end
        if player.bullet_cooldown > 0 then
            player.bullet_cooldown = player.bullet_cooldown - 1
        end
    end
end


----------------
-- Evaluation --
----------------


local DANGER_PLAYER_DASH_COOLDOWN = 10
local DANGER_PLAYER_PROXIMITY = 50
local DANGER_PLAYER_DIRECTION = 10
local DANGER_PLAYER_AGGRESSIVE = 30

-- Evaluate other players
-- - cooldown: (max_cooldown - player_cooldown) / max_cooldown
-- - proximity: 1 / (distance + 0.5)
-- - direction: abs(dot(normalise(player_direction), normalise(connection_direction)))
-- - aggressive: TODO
-- @param me The bot
-- @param other The other player
-- @return The score of the other player
function score_danger_player(me, player)
    local danger_score = 0

    -- Dashing
    danger_score = (DASH_COOLDOWN - player.dash_cooldown) / DASH_COOLDOWN * DANGER_PLAYER_DASH_COOLDOWN
    
    -- Proximity
    local distance = vec.distance(me:pos(), player.pos[1])
    local distance_score = nil
    if distance < 2 then
        distance_score = 1
    else
        distance_score = 1 / (distance + 0.25)
    end
    danger_score = danger_score + distance_score * DANGER_PLAYER_PROXIMITY

    -- Direction
    local direction = normalise(player.direction)
    local connection_direction = normalise(player.pos[1]:sub(me:pos()))
    local direction_score = dot_vec(direction, connection_direction):neg()
    if direction_score < 0 then
        direction_score = 0
    end
    danger_score = danger_score + direction_score * DANGER_PLAYER_DIRECTION

    -- Bullet
    -- TODO

    return danger_score
end


local DANGER_COD = 100

-- Evaluate COD
-- - Zero if inside
-- - Outside: 1 / ((distance - radius)/radius + 0.5) / 2
-- @param me The bot
-- @return The score of the COD
function score_danger_cod(me)
    local cod = me:cod()
    -- No COD yet
    if cod:x() == -1 then
        return 0
    end
    local dist_to_cod = vec.distance(me:pos(), vec.new(cod:x(), cod:y()))
    if dist_to_cod < cod:radius() then
        return 0
    else
        return 1 / ((dist_to_cod - cod:radius())/cod:radius() + 0.5) / 2 * DANGER_COD
    end
end


-- Possible Next moves
local MOVE_DIRECTIONS = {
    N = vec.new(0, 1),
    NE = vec.new(1, 1),
    E = vec.new(1, 0),
    SE = vec.new(1, -1),
    S = vec.new(0, -1),
    SW = vec.new(-1, -1),
    W = vec.new(-1, 0),
    NW = vec.new(-1, 1),
    STAY = vec.new(0, 0)
}


-------------------
-- Main Bot code --
-------------------

MOVE_TARGET = vec.new(250, 230)

function move_toward_cod(me)
    if vec.distance(me:pos(), FIELD_CENTER) > 30 then
        me:move(MOVE_TARGET:sub(me:pos()))
    -- Uncomment to stop bouncing back and forth
    -- else
    --    me:move(vec.new(0, 0))
    end
end

local shot_players = {}

function try_shoot_player(me, player)
    -- Let's not shoot ourselves
    if me:id() == player:id() then
        return false
    end

    local id = player:id()
    if shot_players[id] == nil then
        shot_players[id] = 0
    end

    if shot_players[id] < 15 then
        do_projectile_at(me, player:pos())
        shot_players[id] = shot_players[id] + 1
        return true
    else
        return false
    end
end

function shoot_people(me)
    if me:cooldown(0) > 0 then
        return
    end

    local close = me:visible()

    for _, entity in ipairs(close) do
        if entity:type() == "player" and try_shoot_player(me, entity) then
            return
        end
    end
end

-- Initialisation
-- Called when the bot is initialised
-- @param me The bot
function bot_init(me)
    -- Administrative Functions
    update_others(me)
end

-- Main bot function
-- Called every tick
-- @param me The bot
function bot_main(me)
    -- Update enemy positions and cooldowns
    update_others(me)

    -- Our actions
    move_toward_cod(me)
    shoot_people(me)

    -- Administrative Functions
    update_others_cooldowns()
end