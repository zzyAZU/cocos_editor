--[[====================================
=
=         extending lua math API
=
========================================]]
function math.newrandomseed()
    local ok, socket = pcall(function()
        return require("socket")
    end)

    if ok then
        math.randomseed(socket.gettime() * 1000)
    else
        math.randomseed(os.time())
    end
    math.random()
    math.random()
    math.random()
    math.random()
end

local pi_div_180 = math.pi / 180
function math.angle2radian(angle)
    return angle * pi_div_180
end

function math.radian2angle(radian)
    return radian * 180 / math.pi
end

-- 四舍五入到整数
function math.round_number(val)
    return math.floor(val  + 0.5)
end

function math.fequal(f1, f2)
    return math.abs(f1 - f2) < 0.0001
end

local mmin = math.min
local mmax = math.max
function math.clamp(n, min, max)
    return mmax(mmin(n, max), min)
end