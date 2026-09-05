local ffi = require("ffi")

ffi.cdef[[
    typedef struct {
        float x, y;
        uint8_t r, g, b, a;
    } Vertex;

    typedef struct {
        float x, y, z;
        float vx, vy, vz;
    } Particle;
]]

RLengine = {
    _VERSION = "2.5 Extreme FX & Performance",
    count = 0,
    maxCount = 3000000,
    fov = 500,
    bounds = {w = 1280, h = 720},
    cam = {x = 0, y = 0, z = -700, pitch = 0, yaw = 0},
    forceMode = 1,
    paletteMode = 1,
    time = 0
}

local PALETTES = {
    function(i)
        local t = i / 255
        return math.floor(255 * t), math.floor(255 * (1 - t)), 255, 255
    end,
    function(i)
        local t = i / 255
        return 255, math.floor(255 * t), math.floor(100 * (1 - t)), 255
    end,
    function(i)
        local t = i / 255
        return math.floor(150 * t), 255, math.floor(150 * t), 255
    end,
    function(i)
        local t = i / 255
        return math.floor(180 * t), math.floor(220 * t), 255, 255
    end
}

function RLengine.init(w, h)
    RLengine.bounds.w = w or love.graphics.getWidth()
    RLengine.bounds.h = h or love.graphics.getHeight()

    local vSize = ffi.sizeof("Vertex")
    local pSize = ffi.sizeof("Particle")

    RLengine.vertexData = love.data.newByteData(vSize * RLengine.maxCount)
    RLengine.particleData = love.data.newByteData(pSize * RLengine.maxCount)

    RLengine.vertexPtr = ffi.cast("Vertex*", RLengine.vertexData:getFFIPointer())
    RLengine.particles = ffi.cast("Particle*", RLengine.particleData:getFFIPointer())

    local layout = {
        {"VertexPosition", "float", 2},
        {"VertexColor", "byte", 4}
    }

    RLengine.mesh = love.graphics.newMesh(layout, RLengine.maxCount, "points", "stream")

    RLengine.colorLUT = ffi.new("uint8_t[4][256][4]")
    for pal = 1, 4 do
        for i = 0, 255 do
            local r, g, b, a = PALETTES[pal](i)
            RLengine.colorLUT[pal - 1][i][0] = r
            RLengine.colorLUT[pal - 1][i][1] = g
            RLengine.colorLUT[pal - 1][i][2] = b
            RLengine.colorLUT[pal - 1][i][3] = a
        end
    end

    RLengine.setParticleCount(1000000)
end

function RLengine.setParticleCount(target)
    target = math.max(0, math.min(RLengine.maxCount, target))
    local p = RLengine.particles

    if target > RLengine.count then
        for i = RLengine.count, target - 1 do
            p[i].x = math.random(-800, 800)
            p[i].y = math.random(-800, 800)
            p[i].z = math.random(-800, 800)
            p[i].vx = math.random(-50, 50)
            p[i].vy = math.random(-50, 50)
            p[i].vz = math.random(-50, 50)
        end
    end
    RLengine.count = target
end

function RLengine.update(dt)
    local count = RLengine.count
    if count == 0 then return end

    RLengine.time = RLengine.time + dt
    local tGlobal = RLengine.time
    local cx = RLengine.bounds.w * 0.5
    local cy = RLengine.bounds.h * 0.5
    local fov = RLengine.fov

    local cam = RLengine.cam
    local camX, camY, camZ = cam.x, cam.y, cam.z

    local cosY, sinY = math.cos(-cam.yaw), math.sin(-cam.yaw)
    local cosP, sinP = math.cos(-cam.pitch), math.sin(-cam.pitch)

    local m11, m12, m13 = cosY, 0, -sinY
    local m21, m22, m23 = sinP * sinY, cosP, sinP * cosY
    local m31, m32, m33 = cosP * sinY, -sinP, cosP * cosY

    local p = RLengine.particles
    local v = RLengine.vertexPtr
    local lut = RLengine.colorLUT[RLengine.paletteMode - 1]

    local isLmb = love.mouse.isDown(1)
    local fMode = RLengine.forceMode
    local damp = 1.0 - dt * 0.35

    for i = 0, count - 1 do
        local pt = p[i]
        local x, y, z = pt.x, pt.y, pt.z
        local vx, vy, vz = pt.vx, pt.vy, pt.vz

        if isLmb then
            local dx, dy, dz = -x, -y, -z
            local distSq = dx * dx + dy * dy + dz * dz + 2000

            if fMode == 1 then
                local force = 12000000 * dt / distSq
                vx = vx + dx * force
                vy = vy + dy * force
                vz = vz + dz * force
            elseif fMode == 2 then
                local force = 8000000 * dt / distSq
                vx = vx + (-dy * 15 + dx) * force
                vy = vy + (dx * 15 + dy) * force
                vz = vz + dz * force
            elseif fMode == 3 then
                local force = -18000000 * dt / distSq
                vx = vx + dx * force
                vy = vy + dy * force
                vz = vz + dz * force
            elseif fMode == 4 then
                vx = vx + math.sin(y * 0.01 + tGlobal * 4) * 300 * dt
                vy = vy + math.cos(z * 0.01 + tGlobal * 4) * 300 * dt
                vz = vz + math.sin(x * 0.01 + tGlobal * 4) * 300 * dt
            end
        end

        vx = vx * damp
        vy = vy * damp
        vz = vz * damp

        x = x + vx * dt
        y = y + vy * dt
        z = z + vz * dt

        if x < -900 then x = -900; vx = -vx * 0.8 elseif x > 900 then x = 900; vx = -vx * 0.8 end
        if y < -900 then y = -900; vy = -vy * 0.8 elseif y > 900 then y = 900; vy = -vy * 0.8 end
        if z < -900 then z = -900; vz = -vz * 0.8 elseif z > 900 then z = 900; vz = -vz * 0.8 end

        pt.x, pt.y, pt.z = x, y, z
        pt.vx, pt.vy, pt.vz = vx, vy, vz

        local tx = x - camX
        local ty = y - camY
        local tz = z - camZ

        local rx = tx * m11 + ty * m12 + tz * m13
        local ry = tx * m21 + ty * m22 + tz * m23
        local rz = tx * m31 + ty * m32 + tz * m33

        local vert = v[i]
        if rz > 10 then
            local invZ = fov / rz
            vert.x = cx + rx * invZ
            vert.y = cy + ry * invZ

            local speedSq = vx*vx + vy*vy + vz*vz
            local cIdx = math.min(255, math.max(0, math.floor(speedSq * 0.002)))

            local depthAlpha = 255 - math.min(255, math.floor(rz * 0.12))
            if depthAlpha < 0 then depthAlpha = 0 end

            vert.r = lut[cIdx][0]
            vert.g = lut[cIdx][1]
            vert.b = lut[cIdx][2]
            vert.a = depthAlpha
        else
            vert.x = -9999
            vert.y = -9999
            vert.a = 0
        end
    end

    RLengine.mesh:setVertices(RLengine.vertexData, 1, count)
end

function RLengine.draw()
    if RLengine.count > 0 then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setPointSize(1.5)
        RLengine.mesh:setDrawRange(1, RLengine.count)
        love.graphics.draw(RLengine.mesh)
    end

    local memMB = collectgarbage("count") / 1024
    love.graphics.setColor(0, 0, 0, 0.85)
    love.graphics.rectangle("fill", 10, 10, 490, 220)

    local modeNames = {"1: Attractor", "2: Vortex", "3: Repeller", "4: Wave Turbulence"}
    local palNames = {"1: Cyberpunk", "2: Inferno", "3: Matrix", "4: Electric Blue"}

    love.graphics.setColor(0, 1, 0.6)
    love.graphics.print("RLengine 2.5 | EXTREME PERFORMANCE EDITION", 20, 20)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print("FPS: " .. love.timer.getFPS() .. " (" .. string.format("%.2f", 1000 / math.max(1, love.timer.getFPS())) .. " ms)", 20, 45)
    love.graphics.print("Active Particles: " .. RLengine.count .. " / " .. RLengine.maxCount, 20, 65)
    love.graphics.print("Lua RAM Usage: " .. string.format("%.2f MB", memMB), 20, 85)
    love.graphics.print("Active Physics Force: " .. modeNames[RLengine.forceMode], 20, 110)
    love.graphics.print("Active Palette: " .. palNames[RLengine.paletteMode], 20, 130)

    love.graphics.setColor(0.7, 0.7, 0.7)
    love.graphics.print("[1-4] Change Force Field | [F1-F4] Change Color Palette", 20, 155)
    love.graphics.print("[UP / DOWN] Add/Remove 250k Particles", 20, 175)
    love.graphics.print("[RMB Drag] Rotate Camera | [WASD] Move Camera", 20, 195)
end

function love.load()
    love.window.setMode(1280, 720, {resizable = false, vsync = false})
    love.window.setTitle("RLengine 2.5 - Extreme Performance Point Fog Engine")
    RLengine.init()
end

function love.update(dt)
    local cam = RLengine.cam
    local speed = 700 * dt

    local forwardX = math.sin(cam.yaw) * speed
    local forwardZ = math.cos(cam.yaw) * speed
    local rightX = math.cos(cam.yaw) * speed
    local rightZ = -math.sin(cam.yaw) * speed

    if love.keyboard.isDown("w") then cam.x = cam.x + forwardX; cam.z = cam.z + forwardZ end
    if love.keyboard.isDown("s") then cam.x = cam.x - forwardX; cam.z = cam.z - forwardZ end
    if love.keyboard.isDown("a") then cam.x = cam.x - rightX; cam.z = cam.z - rightZ end
    if love.keyboard.isDown("d") then cam.x = cam.x + rightX; cam.z = cam.z + rightZ end
    if love.keyboard.isDown("space") then cam.y = cam.y + speed end
    if love.keyboard.isDown("lshift") then cam.y = cam.y - speed end

    RLengine.update(dt)
end

function love.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(2) then
        local cam = RLengine.cam
        cam.yaw = cam.yaw + dx * 0.004
        cam.pitch = math.max(-1.5, math.min(1.5, cam.pitch - dy * 0.004))
    end
end

function love.keypressed(key)
    if key == "up" then
        RLengine.setParticleCount(RLengine.count + 250000)
    elseif key == "down" then
        RLengine.setParticleCount(RLengine.count - 250000)
    elseif key == "1" then RLengine.forceMode = 1
    elseif key == "2" then RLengine.forceMode = 2
    elseif key == "3" then RLengine.forceMode = 3
    elseif key == "4" then RLengine.forceMode = 4
    elseif key == "f1" then RLengine.paletteMode = 1
    elseif key == "f2" then RLengine.paletteMode = 2
    elseif key == "f3" then RLengine.paletteMode = 3
    elseif key == "f4" then RLengine.paletteMode = 4
    end
end

function love.draw()
    RLengine.draw()
end