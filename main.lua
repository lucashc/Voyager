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

-- Number of ticks
local num_ticks = 0

-- Other players
-- A list of other players
-- Each player is a tabel indexed by id with the following fields:
-- - pos: The player's positions, [1] is last, contains last 5 positions
-- - direction: Difference between the player's last position and current position
-- - mobility: The player's mobility
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


-- Array of directions to sample
local theta = {}
for i = 1, 360 do
    theta[i] = i/360 * 2 * math.pi
end
local directions = {}
for i = 1, 360 do
    directions[i] = vec.new(math.cos(theta[i]), math.sin(theta[i]))
end


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


-- Multiply sclar with vec
-- @param scalar Scalar
-- @param vec Vector
-- @return scalar * vec
function mul_scalar_vec(scalar, vec1)
    return vec.new(scalar * vec1:x(), scalar * vec1:y())
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

-- Count elements in a table
function count_table(table)
    local count = 0
    for _, _ in pairs(table) do
        count = count + 1
    end
    return count
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
    for _, entity in pairs(entities) do
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
                    mobility = 0,
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
                others[id].mobility = 0.8 * others[id].mobility + 0.2 * vec.distance(new_pos, old_pos[5])
            end
        end
        ::continue::
    end
end

function update_others_bullets(me)
    local entities = me:visible()
    -- Update other players
    for _, entity in pairs(entities) do
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
                print("Adding bullet")
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

function find_line_eq(pos1, pos2)
    local a=pos2:y()-pos1:y()
    local b=pos1:x()-pos2:x()
    local c= a*(-pos1:x())-pos1:y()*b
    return a,b,c
end

function perp_dist(our_coord, bullet_coord, bullet_direction)
    local a,b,c = find_line_eq(bullet_coord, bullet_coord:add(bullet_direction))
    local dist = math.abs(a*our_coord:x()+b*our_coord:y()+c)/math.sqrt(a*a+b*b)
    return dist
end

function danger_perp_dist(dist)
    if dist < 2 then
        return 1
    else
        return math.exp(-.1*dist)+(1-math.exp(-.1*2))
    end
    return dist
end

function danger_bullet_proximity(our_pos, bullet)
    local dist = vec.distance(our_pos, bullet.position)
    -- if bullet is moving away, then no danger
    if dist < vec.distance(our_pos, bullet.position:add(bullet.direction)) then
        -- print("bullet is moving away")
        return 0
    elseif dist<8 then
        return 1
    else
        return math.exp(-.1*dist) + (1-math.exp(-.1*8))
    end
end

function danger_of_position(our_pos)
    local total_danger = 0
    -- print("entering danger_of_position")
    for _, bullet in pairs(bullets) do
        -- print("danger_bullet_proximity" .. danger_bullet_proximity(our_pos, bullet))
        -- print("danger_perp_dist" .. danger_perp_dist(perp_dist(our_pos, bullet.position, bullet.direction)))
        local danger = danger_bullet_proximity(our_pos, bullet)*danger_perp_dist(perp_dist(our_pos, bullet.position, bullet.direction))
        total_danger = total_danger + danger
    end
    return total_danger
end

function find_best_pos(our_pos)
    local best_dir = vec.new(0,0)
    local best_danger = danger_of_position(our_pos)
    -- print("danger for not moving pos: " .. best_danger)
    for _, dir in ipairs(directions) do
        local new_danger = danger_of_position(our_pos:add(dir))
        if new_danger<best_danger then
            best_danger = new_danger
            best_dir = dir
        end
        -- print("danger for direction " .. dir:x() .. ", " .. dir:y() .. ": " .. new_danger)
    end
    return best_dir
end

local DANGER_PLAYER_DASH_COOLDOWN = 10
local DANGER_PLAYER_PROXIMITY = 45
local DANGER_PLAYER_DIRECTION = 15
local DANGER_PLAYER_AGGRESSIVE = 15
local DANGER_PLAYER_MOBILITY = 15

-- Evaluate other players
-- - cooldown: (max_cooldown - player_cooldown) / max_cooldown
-- - proximity: 1 / (distance + 0.5)
-- - direction: abs(dot(normalise(player_direction), normalise(connection_direction)))
-- - aggressive: TODO
-- @param me The bot
-- @param other The other player
-- @return The score of the other player
function score_danger_player(current_position, player)
    local danger_score = 0

    -- Dashing
    danger_score = (DASH_COOLDOWN - player.dash_cooldown) / DASH_COOLDOWN * DANGER_PLAYER_DASH_COOLDOWN
    
    -- Proximity
    local distance = vec.distance(current_position, player.pos[1])
    local distance_score = nil
    if distance < 2 then
        distance_score = 1
    else
        distance_score = 1 / (distance + 0.25)
    end
    danger_score = danger_score + distance_score * DANGER_PLAYER_PROXIMITY

    -- Direction
    local direction = normalise(player.direction)
    local connection_direction = normalise(player.pos[1]:sub(current_position))
    local direction_score = -dot_vec(direction, connection_direction)
    if direction_score < 0 then
        direction_score = 0
    end
    danger_score = danger_score + direction_score * DANGER_PLAYER_DIRECTION

    -- Aggressiveness
    local aggressive_score = player.bullets_spawned / (num_ticks / BULLET_COOLDOWN) * DANGER_PLAYER_AGGRESSIVE
    danger_score = danger_score + aggressive_score

    -- Mobility
    local mobility_score = player.mobility / (BASE_SPEED_PER_TICK*5) * DANGER_PLAYER_MOBILITY

    return danger_score
end


function next_cod(ticks, radius)
    if ticks > 1500 then
        return 1700, 10
    elseif ticks > 1200 then
        return 1500, 40
    elseif ticks > 800 then
        return 1200, 90
    else
        return 800, 500
    end
end


local DANGER_COD = 100

-- Evaluate COD
-- @return The score of the COD
function score_danger_cod(me, current_position)
    -- TODO: fill with tick counter
    time = 0
    radius = norm(current_position)

    next_cod_time, next_cod_radius = next_cod(time, radius)

    if radius <= next_cod_radius then
        -- Inside future COD, safe for now
        return 0
    end

    remaining_time = next_cod_time - time
    time_to_reach_cod = (radius - next_cod_radius) / BASE_SPEED_PER_SECOND
    return math.max(0, 1 - 0.3 * remaining_time / time_to_reach_cod) * DANGER_COD
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

local PLAYER_DANGER_WEIGHT = 0.5
local COD_DANGER_WEIGHT = 0.5
local BULLET_DANGER_WEIGHT = 2

function score_move(me, possible_position)

    -- Evaluate other players
    local player_danger = 0
    local number_of_players = count_table(others)
    for _, player in pairs(others) do
        player_danger = player_danger + score_danger_player(possible_position, player)
    end
    player_danger = player_danger / number_of_players

    -- Evaluate COD
    cod_danger = score_danger_cod(me, possible_position)

    print(player_danger)
    print(cod_danger)

    return PLAYER_DANGER_WEIGHT * player_danger + COD_DANGER_WEIGHT * cod_danger
end


function determine_best_move(me, current_position)
    -- Note, high score is BAD!
    local best_move = nil
    local best_score = 1000000

    for _, move in pairs(MOVE_DIRECTIONS) do
        local new_position = current_position:add(mul_scalar_vec(BASE_SPEED_PER_TICK, normalise(move)))
        local score = score_move(me, new_position)
        if score < best_score then
            best_score = score
            best_move = move
        end
    end
    print(best_move)
    return best_move
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
            -- print(score_danger_player(me:pos(), others[entity:id()]))
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
    print_table(bullets)
    -- Update tick count
    num_ticks = num_ticks + 1
    -- Update enemy positions and cooldowns
    update_others(me)

    -- Our actions
    best_move = determine_best_move(me, me:pos())
    me:move(best_move)
    shoot_people(me)

    -- local dir = find_best_pos(me:pos())
    -- -- print("Direction that is best is " .. dir:x() .. ", " .. dir:y())
    -- me:move(dir)

    -- Administrative Functions
    update_others_cooldowns()
end