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
-- - pos: The player's last position
-- - direction: Difference between the player's last position and current position
-- - dash_cooldown: The player's last dash cooldown
local others = {}

-- Bullets in the air
-- List of all bullets
-- - id: The bullet's id (might be unstable)
-- - position: The bullet's position
-- - direction: The bullet's direction
local bullets = {}


----------------------
-- Helper Functions --
----------------------

-- Returns the norm of a vector
-- @param vector to take norm of
-- @return norm of vector
function norm(vector)
    return vec.distance(vector, vec.new(0, 0))
end

-- Dot product
-- @param vec1 First vector
-- @param vec2 Second vector
-- @return Dot product of vec1 and vec2
function dot_vec(vec1, vec2)
    return vec1.x * vec2.x + vec1.y * vec2.y
end

-- Vector div
-- @param vec1 First vector
-- @param vec2 Second vector
-- @return vec1 / vec2
function div_vec(vec1, vec2)
    return vec.new(vec1.x / vec2.x, vec1.y / vec2.y)
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
    cooldowns.melee = MELEE_COOLDOWN
end


-- Does a projectile attack
-- Has a cooldown of 1 tick
-- @param me The bot
-- @param direction The direction to fire the projectile
function do_projectile(me, direction)
    me:cast(0, direction)
    cooldowns.bullet = BULLET_COOLDOWN
end

function do_projectile_at(me, target_pos)
    local direction = target_pos:sub(me:pos())
    do_projectile(me, direction)
    cooldowns.bullet = BULLET_COOLDOWN
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
    cooldowns.dash = DASH_COOLDOWN
end


-----------------------------
-- Other Agent's functions --
-----------------------------

function update_others(me)
    -- Get all entities
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
            local pos = entity:pos()
            -- Not seen before
            if others[id] == nil then
                others[id] = {
                    pos = pos,
                    direction = vec.new(0, 0),
                    dash_cooldown = 0
                }
            -- Seen before
            else
                -- Check if dashed
                if vec.distance(pos, others[id].pos) > BASE_SPEED_PER_TICK then
                    others[id].dash_cooldown = DASH_COOLDOWN
                elseif others[id].dash_cooldown > 0 then
                    others[id].dash_cooldown = others[id].dash_cooldown - 1
                end
                -- Update
                others[id].direction = pos:sub(others[id].pos)
                others[id].pos = pos
            end
        -- Then check bullets
        elseif entity:type() == "bullet" then
            local id = entity:id()
            local pos = entity:pos()
            -- Not seen before
            if bullets[id] == nil then
                bullets[id] = {
                    position = pos,
                    direction = vec.new(0, 0)
                }
            -- Seen before
            else
                bullets[id] = {
                    position = pos,
                    direction = pos:sub(bulles[id].pos)
                }
            end
        end
        ::continue::
    end
end

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
local shoot_delay = 0

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
    -- Shoot every other turn?
    if shoot_delay > 0 then
        shoot_delay = shoot_delay - 1
    end
    if shoot_delay ~= 0 then
        return
    end
    shoot_delay = 10

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
    shoot_people(me)

    -- me:move(vec.new(1, 0))

    shoot_people(me)

    -- Administrative Functions
    update_others(me)
end