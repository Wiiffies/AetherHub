













local BASE = "https://raw.githubusercontent.com/Wiiffies/AetherHub/Script/"
local HIT_URL = "https://YOUR-COUNTER-URL/hit"

local GAMES = {
    [107778070777162] = "StealAnEgg.luau",
}

local function notify(title, text, dur)
    print("[Aether] " .. tostring(title) .. ": " .. tostring(text))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = tostring(title),
            Text = tostring(text),
            Duration = tonumber(dur) or 6,
        })
    end)
end


local placeId = game.PlaceId
local file = GAMES[placeId]

if not file then
    notify("Aether Hub",
        "This game is not supported yet. (PlaceId: " .. tostring(placeId) .. ")", 8)
    return
end


local ok, src = pcall(function()
    return game:HttpGet(BASE .. file)
end)
if not ok or type(src) ~= "string" or #src < 100 then
    notify("Aether Hub", "Download failed — check your executor connection.", 6)
    return
end


local fn, err = loadstring(src, "Aether-" .. file)
if not fn then
    notify("Aether Hub", "Load error: " .. tostring(err), 6)
    return
end
local okRun, errRun
task.spawn(function()
    pcall(function()
        game:HttpGet(HIT_URL)
    end)
end)
task.spawn(function()
    pcall(function()
        game:HttpGet("https://abacus.jasoncameron.dev/hit/aetherhub/executions")
    end)
end)
okRun, errRun = pcall(fn)
if not okRun then
    notify("Aether Hub", "Runtime error: " .. tostring(errRun), 6)
end
