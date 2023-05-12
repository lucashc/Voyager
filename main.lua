-- Global Game Constants

-- Base Speed
local BASE_SPEED <const> = 1

-- Base Health
local BASE_HEALTH <const> = 100

-- Cooldowns
local DASH_COOLDOWN <const> = 260
local PROJECTILE_COOLDOWN <const> = 1
local MELEE_COOLDOWN <const> = 50

-- Melee Range
local MELEE_RANGE <const> = 2

-- Dash Speed
local DASH_SPEED <const> = 10


-- Globals

-- Cooldowns
local cooldowns = {
    dash = 0,
    projectile = 0,
    melee = 0
}


-- Helper Functions

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
    cooldowns.projectile = PROJECTILE_COOLDOWN
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
function update_cooldowns():
    for i = 1, 3 do
        if cooldowns[i] > 0 then
            cooldowns[i] = cooldowns[i] - 1
        end
    end
end


-- Initialisation
-- Called when the bot is initialised
-- @param me The bot
function bot_init(me)
end


-- Main bot function
-- Called every tick
-- @param me The bot
function bot_main(me)

    -- Administrative Functions
    update_cooldowns()
end