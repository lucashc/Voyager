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
local BULLET_COOLDOWN = 1
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

-- Cooldowns
local cooldowns = {
    dash = 0,
    bullet = 0,
    melee = 0
}


----------------------
-- Helper Functions --
----------------------

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
    cooldowns.bullet = bullet_COOLDOWN
end


-- Does a dash
-- Has a cooldown of 260 ticks
-- @param me The bot
-- @param direction The direction to dash
function do_dash(me, direction)
    me:cast(1, direction)
    cooldowns.dash = DASH_COOLDOWN
end


-- Updates the cooldowns
-- Should be called every tick
function update_cooldowns()
    if cooldowns.dash > 0 then
        cooldowns.dash = cooldowns.dash - 1
    end
    if cooldowns.bullet > 0 then
        cooldowns.bullet = cooldowns.bullet - 1
    end
    if cooldowns.melee > 0 then
        cooldowns.melee = cooldowns.melee - 1
    end
end


-------------------
-- Main Bot code --
-------------------

-- Initialisation
-- Called when the bot is initialised
-- @param me The bot
function bot_init(me)
end


-- Main bot function
-- Called every tick
-- @param me The bot
function bot_main(me)
    me:move(vec.new(1, 0))
    -- Administrative Functions
    update_cooldowns()
end