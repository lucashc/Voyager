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
local MOVE_DIRECTIONS = {}
NUM_DIRECTIONS = 24
for i = 1, NUM_DIRECTIONS do
    local theta = i/NUM_DIRECTIONS * 2 * math.pi
    MOVE_DIRECTIONS[i] = vec.new(math.cos(theta), math.sin(theta))
end
MOVE_DIRECTIONS[NUM_DIRECTIONS+1] = vec.new(0, 0)


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
                -- print("Adding bullet")
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


function proximity_score(position, player)
    -- Proximity
    local distance = vec.distance(current_position, player.pos[1])
    local distance_score = nil
    if distance < 2 then
        distance_score = 1
    else
        distance_score = 1 / (distance + 0.25)
    end
    return distance_score
end


function direction_score(position, player)
    local direction = normalise(player.direction)
    local connection_direction = normalise(player.pos[1]:sub(current_position))
    local direction_score = -dot_vec(direction, connection_direction)
    if direction_score < 0 then
        direction_score = 0
    end
    return direction_score
end


function aggressive_score(position, player)
    local aggressive_score = player.bullets_spawned / (num_ticks / BULLET_COOLDOWN)
    return aggressive_score
end


local DANGER_PLAYER_DASH_COOLDOWN = 0.10
local DANGER_PLAYER_PROXIMITY = 0.45
local DANGER_PLAYER_DIRECTION = 0.15
local DANGER_PLAYER_AGGRESSIVE = 0.15
local DANGER_PLAYER_MOBILITY = 0.15

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

    -- Direction
    local direction_score = direction_score(current_position, player)
    danger_score = danger_score + direction_score * DANGER_PLAYER_DIRECTION

    -- Aggressiveness
    local aggressive_score = aggressive_score(current_position, player)
    danger_score = danger_score + aggressive_score * DANGER_PLAYER_AGGRESSIVE

    -- Mobility
    local mobility_score = player.mobility / (BASE_SPEED_PER_TICK*5) * DANGER_PLAYER_MOBILITY
    danger_score = danger_score + mobility_score * DANGER_PLAYER_MOBILITY

    -- Distance
    local distance_score = proximity_score(current_position, player)
    danger_score = danger_score*distance_score

    return danger_score
end


function interpolate(x1, x2, y1, y2, x)
    return y1 + (y2 - y1) / (x2 - x1) * (x - x1)
end

function get_smoothed_cod(ticks)
    if ticks < 800 then
        return interpolate(0, 800, 500, 150, ticks)
    elseif ticks < 1200 then
        return interpolate(800, 1200, 150, 90, ticks)
    elseif ticks < 1500 then
        return interpolate(1200, 1500, 90, 40, ticks)
    elseif ticks < 1700 then
        return interpolate(1500, 1700, 40, 10, ticks)
    elseif ticks < 1900 then
        return interpolate(1700, 1900, 10, 0, ticks)
    else
        return 0
    end
end

-- Evaluate COD
-- @return The score of the COD
function score_danger_cod(me, current_position)
    local radius = vec.distance(current_position, FIELD_CENTER)

    local next_cod_radius = get_smoothed_cod(num_ticks) * 0.8

    return math.exp((radius - next_cod_radius) / next_cod_radius * 0.1)
end

-- Penalize wall distance
function score_danger_walls(current_position)
    local dist_x = 0
    local dist_y = 0
    local dist_to_wall = 0
    local x = current_position:x()
    local y = current_position:y()
    
    if x < FIELD_CENTER:x() then
        dist_x = x 
    else
        dist_x = FIELD_SIZE - x 
    end
    if y < FIELD_CENTER:y() then
        dist_y = y
    else
        dist_y = FIELD_SIZE - y 
    end
    dist_to_wall = math.min(dist_x, dist_y)
    if dist_x < 20 and dist_y < 20 then 
        dist_to_wall = dist_to_wall * 0.5
    end
    return 1 / (dist_to_wall+1) 
end

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

function score_danger_bullet(our_pos)
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

function get_all_scores(me, possible_position)
    -- Evaluate other players
    local player_danger = 0
    local number_of_players = count_table(others)
    for _, player in pairs(others) do
        player_danger = player_danger + score_danger_player(possible_position, player)
    end

    -- Evaluate COD
    local cod_danger = score_danger_cod(me, possible_position)

    -- Evaluate walls
    local wall_danger = score_danger_walls(possible_position)

    -- Evaluate bullets
    local bullet_danger = score_danger_bullet(possible_position)

    return player_danger, cod_danger, wall_danger, bullet_danger
end

local PLAYER_DANGER_WEIGHT = 0.3
local COD_DANGER_WEIGHT = 2.0
local BULLET_DANGER_WEIGHT = 1
local WALL_DANGER_WEIGHT = 0.1

function score_move(me, possible_position)
    local player, cod, wall, bullet = get_all_scores(me, possible_position)

    return PLAYER_DANGER_WEIGHT * player + COD_DANGER_WEIGHT * cod + WALL_DANGER_WEIGHT * wall + BULLET_DANGER_WEIGHT * bullet
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

    local player, cod, wall, bullet = get_all_scores(me, current_position)
    print("Best move" .. best_move:x() .. " " .. best_move:y() .. " with score " .. best_score .. " player " .. player .. " cod " .. cod .. " wall " .. wall .. " bullet " .. bullet)
    return best_move
end


-------------------
-- Main Bot code --
-------------------

function spell_people(me)
    -- find: 1. clostest player, 2. most threatening player (hitman)
    local distance_to_run = 3
    local closest_player = others[1]
    local min_distance = FIELD_SIZE
    local dangerous_player = others[1]
    local max_danger = 0

    for _, player in pairs(others) do
        local player_danger = 0.8*proximity_score(me:pos(), player) + 0.2*direction_score(me:pos(), player)
        if player_danger>max_danger then
            max_danger = player_danger
            dangerous_player = player
        end
        local player_distance = vec.distance(me:pos(), player.pos[1])
        if player_distance<min_distance then
            min_distance = player_distance
            closest_player = player
        end
    end

    -- if oppenents are close... run!!
    if min_distance<= distance_to_run then
        -- if dash cooldown 
        if me:cooldown(1)==0 then
            -- TODO add dash
            local direction = determine_best_move(me, me:pos(), true)
            return 1, direction
        -- we cannot run, so might as well stab
        elseif min_distance<=2 and me:cooldown(2)==0 then
            local cp_pos = closest_player.pos[1]
            return 2, cp_pos:sub(me:pos())
        end
    end

    -- shoot at the most dangerous player
    local dp_pos = dangerous_player.pos[1]
    -- could consider where the enemy is moving
    return 0, dp_pos:sub(me:pos())
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
    -- Update tick count
    num_ticks = num_ticks + 1
    -- Update enemy positions and cooldowns
    update_others(me)

    -- Our actions
    local best_move = determine_best_move(me, me:pos())
    me:move(best_move)

    -- Spell casting
    local spell, direction = spell_people(me)
    me:cast(spell, direction)

    PLAYER_DANGER_WEIGHT = PLAYER_DANGER_WEIGHT*0.999

    -- Administrative Functions
    update_others_cooldowns()
end