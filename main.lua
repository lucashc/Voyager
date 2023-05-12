-- Globals

-- Dash, Projectile, Melee
local cooldowns = {0, 0, 0}


-- Helper Functions

function do_melee(me, direction)
    me:cast(2, direction)
    cooldowns[3] = 50
end

function do_projectile(me, direction)
    me:cast(0, direction)
    cooldowns[2] = 1
end

function do_dash(me, direction)
    me:cast(1, direction)
    cooldowns[1] = 260
end


-- Initialisation
function bot_init(me)
end


-- Main bot function
function bot_main(me)

    -- Update Cooldowns
    for i = 1, 3 do
        if cooldowns[i] > 0 then
            cooldowns[i] = cooldowns[i] - 1
        end
    end

end