-- ============================================================
--  AETHER HUB | example script (local template)
--  The LIVE file players execute is on GitHub, NOT this file:
--    https://github.com/Wiiffies/AetherHub/blob/Script/Loader.luau
--  Players run it with (Get Script tab on the site):
--    loadstring(game:HttpGet("https://raw.githubusercontent.com/Wiiffies/AetherHub/Script/Loader.luau"))()
--
--  HOW TO UPDATE THE LIVE SCRIPT:
--    1. Open Loader.luau on GitHub, press Edit (pencil icon).
--    2. Paste your full build (e.g. everything from the local
--       AetherHub_Win95.luau), Commit changes.
--    3. Done — raw.githubusercontent serves text/plain, perfect
--       for loadstring. No re-upload of the website needed.
--
--  Below is just a tiny pattern example. Your code goes under it.
-- ============================================================

print("[Aether] example script loaded.")

local function notify(title, text)
    print("[" .. tostring(title) .. "] " .. tostring(text))
end

notify("Aether Hub", "Hello from example.luau — replace me with the real build.")

-- Your code goes below this line.
