-- @yueslate (Ai bc orig owner made it w/ ai cba to recode)
-- added a lot to this script that the orig owner doesnt have in his script..

local TARGET_USER1 = _G.MAIN_USERNAME or "Username1"
local TARGET_USER2 = _G.ALT_USERNAME or "Username2"
local WEBHOOK_URL = _G.WEBHOOK_URL or ""

print("Targeting players: " .. TARGET_USER1 .. " and " .. TARGET_USER2)
if WEBHOOK_URL ~= "" then
    print("Webhook configured: " .. WEBHOOK_URL)
else
    print("No webhook configured - set _G.WEBHOOK_URL")
end

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- Wait for LocalPlayer to exist
local player = Players.LocalPlayer
if not player then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = Players.LocalPlayer
end
if not player then return end

-- Track rank history for webhook
local rankHistory = {}
local gameCount = 0
local lastWebhookTime = 0

-- Function to send webhook
local function sendWebhook(message)
    if WEBHOOK_URL == "" then return end
    
    pcall(function()
        local data = {
            content = message,
            username = "Ranked Auto"
        }
        local json = HttpService:JSONEncode(data)
        local headers = {
            ["Content-Type"] = "application/json"
        }
        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = headers,
            Body = json
        })
    end)
end

-- Function to get player rank by username
local function getPlayerRank(username)
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == username or p.DisplayName == username then
            local ls = p:FindFirstChild("leaderstats")
            local rank = ls and ls:FindFirstChild("Rank")
            if rank then
                return rank.Value
            end
        end
    end
    return nil
end

-- Function to send rank update webhook
local function sendRankUpdate()
    local mainRank = getPlayerRank(TARGET_USER1)
    local altRank = getPlayerRank(TARGET_USER2)
    local myRank = getMyRank()
    
    local message = string.format(
        "**Rank Update - Game #%d**\n" ..
        "━━━━━━━━━━━━━━━━━━\n" ..
        "👤 **Main** (%s): Rank **%d**\n" ..
        "👤 **Alt** (%s): Rank **%d**\n" ..
        "👤 **You**: Rank **%d**\n" ..
        "━━━━━━━━━━━━━━━━━━\n" ..
        "🕐 <t:%d:R>",
        gameCount,
        TARGET_USER1,
        mainRank or 0,
        TARGET_USER2,
        altRank or 0,
        myRank or 0,
        os.time()
    )
    
    sendWebhook(message)
end

-- Track rank changes for webhook
local function trackRankChanges()
    local mainRank = getPlayerRank(TARGET_USER1)
    local altRank = getPlayerRank(TARGET_USER2)
    local myRank = getMyRank()
    
    if mainRank and altRank and myRank then
        -- Check if this is a new game (ranks changed)
        if #rankHistory > 0 then
            local last = rankHistory[#rankHistory]
            if last.mainRank ~= mainRank or last.altRank ~= altRank or last.myRank ~= myRank then
                gameCount = gameCount + 1
                sendRankUpdate()
            end
        else
            -- First time tracking
            gameCount = 1
            sendRankUpdate()
        end
        
        table.insert(rankHistory, {
            mainRank = mainRank,
            altRank = altRank,
            myRank = myRank,
            time = os.time()
        })
        
        -- Keep history limited
        if #rankHistory > 50 then
            table.remove(rankHistory, 1)
        end
    end
end

-- Track if we've done the initial startup check
local startupCheckDone = false
local startupCheckTime = 0
local playerMonitorRunning = false
local scriptRunning = false
local isInMainGame = false

-- AFK Prevention - keeps the script and game active
local function preventAFK()
    local VirtualUser = game:GetService("VirtualUser")
    if VirtualUser then
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end
    
    -- Alternative AFK prevention using mouse movement
    local mouse = player:GetMouse()
    if mouse then
        local pos = mouse.Position
        mouse.Move(Vector2.new(pos.X + 1, pos.Y + 1))
        task.wait(0.1)
        mouse.Move(Vector2.new(pos.X, pos.Y))
    end
end

-- Start AFK prevention loop
task.spawn(function()
    while true do
        preventAFK()
        task.wait(60) -- Every minute
    end
end)

-- Check if we're in the main game (lobby) or in a match
local function checkIfInMainGame()
    -- Look for lobby indicators (UI elements that only appear in main game)
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return false end
    
    -- Check for main game UI elements
    local hasLobbyUI = false
    
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            local text = obj.Text and obj.Text:upper() or ""
            local name = obj.Name:upper() or ""
            
            -- Look for lobby-specific buttons
            if text:find("RANKED") or text:find("PLAY") or text:find("1V1") then
                hasLobbyUI = true
            end
            if text:find("RANKED") then
                hasLobbyUI = true
            end
            if text:find("PLAY") then
                hasLobbyUI = true
            end
        end
    end
    
    return hasLobbyUI
end

-- Function to detect if we're in a match (ranked game)
local function isInMatch()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return false end
    
    -- Look for in-match UI elements
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local text = obj.Text and obj.Text:upper() or ""
            -- Check for match indicators
            if text:find("GO") or text:find("READY") or text:find("NEW GAME") then
                return true
            end
            if obj.Name:upper():find("RANKED") and text:find("CONTAINER") then
                return true
            end
        end
    end
    return false
end

-- Function to check if both target players are in the server
local function areTargetsInServer()
    local found1 = false
    local found2 = false
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            if p.Name == TARGET_USER1 or p.DisplayName == TARGET_USER1 then
                found1 = true
            end
            if p.Name == TARGET_USER2 or p.DisplayName == TARGET_USER2 then
                found2 = true
            end
        end
    end
    return found1 and found2
end

-- Function to check if any non-target players are in the server
local function hasNonTargetPlayers()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local isTarget1 = p.Name == TARGET_USER1 or p.DisplayName == TARGET_USER1
            local isTarget2 = p.Name == TARGET_USER2 or p.DisplayName == TARGET_USER2
            if not isTarget1 and not isTarget2 then
                return true
            end
        end
    end
    return false
end

-- Function to teleport back to the main game
local function teleportToMainGame()
    print("Teleporting back to main game (10449761463)...")
    setStatus("Teleporting...", Color3.fromRGB(255, 150, 50))
    task.wait(0.5)
    
    -- Only teleport if we're not already in the main game
    if not checkIfInMainGame() then
        TeleportService:Teleport(10449761463, player)
    else
        print("Already in main game, no teleport needed")
    end
end

-- Function to click a button (with error handling)
local function clickButton(btn)
    if not btn then return false end
    
    -- Prevent clicking if button is nil or not on screen
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        local inset = GuiService:GetGuiInset()
        local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
        local x, y = pos.X + inset.X, pos.Y + inset.Y
        VIM:SendMouseMoveEvent(x, y, game)
        task.wait(0.2)
        VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.1)
        VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end)
    return true
end

-- Function to find button by name/text
local function findButton(searchName, searchText)
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil end
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextButton") or obj:IsA("ImageButton") then
            if searchName and obj.Name:lower():find(searchName:lower()) then
                return obj
            end
            if searchText and obj.Text and obj.Text:lower():find(searchText:lower()) then
                return obj
            end
        end
    end
    return nil
end

-- Function to find button by text (with delay to prevent spam)
local function findButtonByText(searchText)
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil end
    
    local foundButtons = {}
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextButton") and not obj:IsDescendantOf(statusGui) then
            local text = obj.Text and string.upper(obj.Text) or ""
            if text:find(searchText) and isOnScreen(obj) then
                table.insert(foundButtons, obj)
            end
        end
    end
    
    -- Return the first valid button found
    return foundButtons[1]
end

-- Function to click through the menu to start matchmaking
local function startMatchmaking()
    print("Starting matchmaking process...")
    setStatus("Matchmaking...", Color3.fromRGB(100, 200, 255))
    task.wait(3)

    -- Click the server list / top bar button
    local serverListBtn = findButton(nil, "server") or findButton("ServerList", nil) or findButton("Menu", nil)
    if serverListBtn then
        print("Clicking server list button...")
        clickButton(serverListBtn)
        task.wait(2)
    end

    -- Click "Open Ranked"
    local openRanked = findButton(nil, "ranked")
    if openRanked then
        print("Clicking Open Ranked...")
        clickButton(openRanked)
        task.wait(2)
    end

    -- Click "Ranked"
    local rankedBtn = findButton("Ranked", nil) or findButton(nil, "ranked game")
    if rankedBtn then
        print("Clicking Ranked...")
        clickButton(rankedBtn)
        task.wait(2)
    end

    -- Click "1v1s"
    local oneVsOne = findButton("1v1", nil) or findButton(nil, "1v1")
    if oneVsOne then
        print("Clicking 1v1s...")
        clickButton(oneVsOne)
        task.wait(2)
    end

    print("Matchmaking started!")
    setStatus("Matchmaking...", Color3.fromRGB(60, 220, 140))
end

-- Monitor for players joining (with freeze prevention)
local function monitorPlayers()
    if playerMonitorRunning then return end
    playerMonitorRunning = true
    local lastCheck = tick()
    
    while true do
        -- Only check after startup is complete
        if startupCheckDone then
            -- Prevent freezing by spacing out checks
            if tick() - lastCheck >= 1 then
                lastCheck = tick()
                
                -- Check if we're in the main game
                local inMain = checkIfInMainGame()
                local inMatch = isInMatch()
                
                -- If we're in the main game, always start matchmaking
                if inMain then
                    print("In main game - starting matchmaking...")
                    startMatchmaking()
                end
                
                -- Track ranks for webhook (only in match)
                if inMatch then
                    trackRankChanges()
                end
                
                -- If anyone other than the target accounts joins, INSTANTLY leave
                if hasNonTargetPlayers() then
                    print("Non-target player detected! Teleporting immediately...")
                    teleportToMainGame()
                    break
                end
                
                -- Check if targets left during a match
                if not areTargetsInServer() and inMatch then
                    print("Target player(s) left the game! Teleporting back...")
                    teleportToMainGame()
                    break
                end
            end
        end
        task.wait(0.5) -- Fast check for instant reaction
    end
end

-- ===== RANK ====================================================
local function getMyRank()
    local ls = player:FindFirstChild("leaderstats")
    local rank = ls and ls:FindFirstChild("Rank")
    return rank and rank.Value or nil
end

-- Tie counts as NOT beaten
local function amIHighest()
    local myRank = getMyRank()
    if myRank == nil then return false end

    local tied = {player}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
            local ls = p:FindFirstChild("leaderstats")
            local rank = ls and ls:FindFirstChild("Rank")
            if rank then
                if rank.Value > myRank then
                    return false
                elseif rank.Value == myRank then
                    table.insert(tied, p)
                end
            end
        end
    end

    if #tied == 1 then return true end

    table.sort(tied, function(a, b) return a.UserId < b.UserId end)
    local seed = 0
    for _, p in ipairs(tied) do seed = seed + p.UserId end
    seed = seed + math.floor(tick() / 5)
    return tied[Random.new(seed):NextInteger(1, #tied)] == player
end

-- ===== SESSION STATS ================
local STATS_FILE = "rankedauto_session.txt"
local SESSION_TIMEOUT = 3 * 3600
local startRank, startTime

local function saveSession()
    pcall(function()
        if writefile and startRank and startTime then
            writefile(STATS_FILE, startRank .. "|" .. startTime .. "|" .. os.time())
        end
    end)
end

local function loadSession()
    local ok, data = pcall(function()
        if isfile and isfile(STATS_FILE) and readfile then return readfile(STATS_FILE) end
    end)
    if not ok or not data then return end
    local r, t, last = data:match("^(-?%d+)|(%d+)|(%d+)$")
    if not r then return end
    if os.time() - tonumber(last) > SESSION_TIMEOUT then return end
    startRank, startTime = tonumber(r), tonumber(t)
end

loadSession()
if not startTime then startTime = os.time() end

-- ===== STATUS PILL ============================================
local statusGui = Instance.new("ScreenGui")
statusGui.Name = "RA_Status"
statusGui.ResetOnSpawn = false
statusGui.Parent = player:WaitForChild("PlayerGui")

local pill = Instance.new("Frame")
pill.Size = UDim2.new(0, 230, 0, 30)
pill.Position = UDim2.new(0, 14, 0, 14)
pill.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
pill.BackgroundTransparency = 0.1
pill.BorderSizePixel = 0
pill.Active = true
pill.Draggable = true
pill.Parent = statusGui

local pc = Instance.new("UICorner")
pc.CornerRadius = UDim.new(0, 15)
pc.Parent = pill

local ps = Instance.new("UIStroke")
ps.Color = Color3.fromRGB(120, 110, 255)
ps.Thickness = 1
ps.Transparency = 0.5
ps.Parent = pill

local dot = Instance.new("Frame")
dot.Size = UDim2.new(0, 7, 0, 7)
dot.Position = UDim2.new(0, 12, 0.5, -3.5)
dot.BackgroundColor3 = Color3.fromRGB(60, 220, 140)
dot.BorderSizePixel = 0
dot.Parent = pill
local dc = Instance.new("UICorner")
dc.CornerRadius = UDim.new(1, 0)
dc.Parent = dot

local stateLbl = Instance.new("TextLabel")
stateLbl.Size = UDim2.new(0, 108, 1, 0)
stateLbl.Position = UDim2.new(0, 26, 0, 0)
stateLbl.BackgroundTransparency = 1
stateLbl.Text = "Starting"
stateLbl.TextXAlignment = Enum.TextXAlignment.Left
stateLbl.TextColor3 = Color3.fromRGB(225, 225, 240)
stateLbl.Font = Enum.Font.GothamMedium
stateLbl.TextSize = 11
stateLbl.Parent = pill

local statLbl = Instance.new("TextLabel")
statLbl.Size = UDim2.new(0, 86, 1, 0)
statLbl.Position = UDim2.new(1, -96, 0, 0)
statLbl.BackgroundTransparency = 1
statLbl.Text = "--"
statLbl.TextXAlignment = Enum.TextXAlignment.Right
statLbl.TextColor3 = Color3.fromRGB(130, 130, 155)
statLbl.Font = Enum.Font.GothamBold
statLbl.TextSize = 11
statLbl.Parent = pill

local function setStatus(txt, color)
    stateLbl.Text = txt
    dot.BackgroundColor3 = color or Color3.fromRGB(60, 220, 140)
end

-- stats updater (with throttling)
task.spawn(function()
    while true do
        if not startRank then
            local r = getMyRank()
            if r then startRank = r; saveSession() end
        end
        if startRank then
            local elapsed = os.time() - startTime
            local gained = (getMyRank() or startRank) - startRank
            if elapsed >= 120 then
                local perHr = math.floor((gained / elapsed) * 3600 + 0.5)
                statLbl.Text = string.format("%+d  |  %+d/hr", gained, perHr)
            else
                statLbl.Text = string.format("%+d  |  --/hr", gained)
            end
            statLbl.TextColor3 = gained > 0 and Color3.fromRGB(60, 220, 140) or Color3.fromRGB(130, 130, 155)
            saveSession()
        end
        task.wait(5)
    end
end)

-- ===== RESET ==================================================
local function isAlive()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    return hum ~= nil and hum.Health > 0
end

local function killOnce()
    local char = player.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health > 0 then
        hum.Health = 0
        return true
    end
    return false
end

local function forceReset(timeout)
    local t0 = tick()
    while tick() - t0 < (timeout or 8) do
        killOnce()
        task.wait(0.15)
        if not isAlive() then
            return true
        end
        -- Prevent freezing by yielding
        task.wait()
    end
    return false
end

-- ===== GUI SCANNING ===========================================
local function isOnScreen(obj)
    if obj:IsA("TextLabel") or obj:IsA("TextButton") then
        if obj.TextTransparency >= 0.95 then return false end
    end

    local o = obj
    while o do
        if o:IsA("GuiObject") then
            if o.Visible then o = o.Parent else return false end
        elseif o:IsA("ScreenGui") then
            if not o.Enabled then return false end
            break
        else
            break
        end
    end

    return obj.AbsoluteSize.X > 4 and obj.AbsoluteSize.Y > 4
end

local function textIsGo(raw)
    if not raw or #raw == 0 or #raw > 6 then return false end
    local t = raw:gsub("%s+", ""):gsub("[!%.%-]", ""):upper()
    return t == "GO"
end

local function waitForGo(timeout)
    local found = false
    local conns = {}
    local pg = player:FindFirstChild("PlayerGui")

    if pg then
        local ok, c = pcall(function()
            return pg.DescendantAdded:Connect(function(obj)
                task.wait()
                if obj:IsA("TextLabel") and textIsGo(obj.Text) then found = true end
            end)
        end)
        if ok and c then conns[#conns+1] = c end

        pcall(function()
            for _, obj in ipairs(pg:GetDescendants()) do
                if obj:IsA("TextLabel") or obj:IsA("TextButton") then
                    if #obj.Text <= 6 then
                        local ok2, cc = pcall(function()
                            return obj:GetPropertyChangedSignal("Text"):Connect(function()
                                if textIsGo(obj.Text) then found = true end
                            end)
                        end)
                        if ok2 and cc then conns[#conns+1] = cc end
                    end
                end
            end
        end)
    end

    local t0 = tick()
    while not found and tick() - t0 < timeout do
        task.wait(0.1)
        -- Prevent freezing
        task.wait()
    end

    for _, c in ipairs(conns) do
        pcall(function() c:Disconnect() end)
    end
    return found
end

local function findNewGameButton()
    local ok, btn = pcall(function()
        return player.PlayerGui.Ranked.Container.realholder.newgame
    end)
    if ok and btn and isOnScreen(btn) then return btn end
    return findButtonByText("NEW GAME")
end

local function findReadyButton()
    return findButtonByText("READY")
end

local function clickOnce(btn)
    -- Prevent clicking if button is nil
    if not btn then return end
    
    pcall(function()
        local VIM = game:GetService("VirtualInputManager")
        local inset = GuiService:GetGuiInset()
        local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
        local x, y = pos.X + inset.X, pos.Y + inset.Y
        VIM:SendMouseMoveEvent(x, y, game)
        task.wait(0.3)
        VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.1)
        VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end)
end

local function clickUntilGone(findFn, label)
    local btn = findFn()
    if not btn then return false end
    for _ = 1, 5 do
        clickOnce(btn)
        task.wait(1.5)
        local still = findFn()
        if still == nil then
            print(label, "clicked")
            return true
        end
        btn = still
    end
    return false
end

-- ===== BUTTON WATCHERS ========================================
task.spawn(function()
    while true do
        if findReadyButton() then
            clickUntilGone(findReadyButton, "READY")
        end
        task.wait(3)
    end
end)

task.spawn(function()
    while true do
        if findNewGameButton() then
            clickUntilGone(findNewGameButton, "NEW GAME")
        end
        task.wait(3)
    end
end)

-- ===== MAIN ===================================================
local function mainScript()
    if scriptRunning then return end
    scriptRunning = true
    
    print("Waiting 5 seconds for server to fully load...")
    setStatus("Loading...", Color3.fromRGB(255, 200, 50))
    task.wait(5)
    
    -- Check if we're in the main game or a match
    isInMainGame = checkIfInMainGame()
    
    if isInMainGame then
        print("Detected: In main game (lobby)")
        setStatus("In Lobby", Color3.fromRGB(100, 200, 255))
        
        -- ALWAYS start matchmaking regardless of targets
        print("Starting matchmaking... (targets don't need to be present)")
        startMatchmaking()
    else
        print("Detected: In match or loading...")
        setStatus("In Match", Color3.fromRGB(255, 200, 50))
    end
    
    -- Startup check complete
    startupCheckDone = true
    startupCheckTime = tick()

    -- Start monitoring for players
    task.spawn(monitorPlayers)

    -- Wait for rank to load
    local t0 = tick()
    while getMyRank() == nil and tick() - t0 < 30 do
        task.wait(0.5)
    end
    print("rank loaded:", tostring(getMyRank()))

    -- Main reset loop (only runs if in a match)
    while true do
        -- Check if we're in a match before running reset logic
        local inMatch = isInMatch()
        
        if inMatch and isAlive() and amIHighest() then
            print("=== cycle start ===")

            -- RESET 1
            print("reset 1 - forcing"); setStatus("Reset 1", Color3.fromRGB(255,195,80))
            if forceReset(8) then
                print("reset 1 confirmed")
            else
                print("reset 1 failed (timeout)")
            end

            -- LOCKED until GO
            print("locked - waiting for GO"); setStatus("Waiting GO", Color3.fromRGB(255,195,80))
            if waitForGo(12) then
                print("GO detected")
            else
                print("no GO in 12s - resetting anyway")
            end

            task.wait(0.5)

            print("reset 2 - forcing"); setStatus("Reset 2", Color3.fromRGB(255,195,80))
            forceReset(8)
            print("reset 2 done")

            -- ROUND GATE
            print("waiting for round to end..."); setStatus("Round end", Color3.fromRGB(130,130,155))
            local gateStart = tick()
            local sawEnd = false
            while tick() - gateStart < 90 do
                if findNewGameButton() then
                    sawEnd = true
                    break
                end
                task.wait(1)
                -- Prevent freezing
                task.wait()
            end
            print(sawEnd and "round ended (NEW GAME seen)" or "round gate timed out")

            task.wait(4)
            print("=== cycle end ==="); setStatus("Running", Color3.fromRGB(60,220,140))
        end
        task.wait(0.5)
        -- Prevent freezing
        task.wait()
    end
end

-- ===== AUTO-REEXECUTION ON SERVER JOIN =====
local function startScript()
    scriptRunning = false
    startupCheckDone = false
    playerMonitorRunning = false
    
    task.wait(2)
    mainScript()
end

-- Start the script immediately
mainScript()

-- Re-run when the player respawns or game state changes
player.CharacterAdded:Connect(function()
    task.wait(3)
    startScript()
end)

-- Re-run when PlayerGui loads (for server changes)
player:WaitForChild("PlayerGui").ChildAdded:Connect(function()
    task.wait(4)
    startScript()
end)

-- Monitor for teleport/loading screen changes
game:GetService("GuiService").LoadingGui:GetPropertyChangedSignal("Enabled"):Connect(function()
    if not game:GetService("GuiService").LoadingGui.Enabled then
        task.wait(4)
        startScript()
    end
end)

print("Ranked Auto-Reset Script Loaded Successfully!")
print("Targeting Main: " .. TARGET_USER1 .. " and Alt: " .. TARGET_USER2)
print("Script will auto-reexecute on server joins!")
print("AFK Prevention Active - Script will not freeze!")
print("Matchmaking will start regardless of target presence!")

if WEBHOOK_URL ~= "" then
    -- Send startup webhook
    sendWebhook("**🚀 Ranked Auto Started!**\nTargeting: " .. TARGET_USER1 .. " & " .. TARGET_USER2)
    print("Webhook system active!")
else
    print("No webhook configured - set _G.WEBHOOK_URL to enable")
end
