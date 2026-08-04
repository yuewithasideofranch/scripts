-- cracked with love by yue (not hard im not flexxing js sayin) 
-- FYI, this code is hella ai due to the orig "creator", not me, this versions js free with some bloated stuff removed <33


























local Players = game:GetService("Players")

-- Wait for LocalPlayer to exist
local player = Players.LocalPlayer
if not player then
    Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
    player = Players.LocalPlayer
end
if not player then return end

-- ===== RANK ====================================================
local function getMyRank()
    local ls = player:FindFirstChild("leaderstats")
    local rank = ls and ls:FindFirstChild("Rank")
    return rank and rank.Value or nil
end

-- Tie counts as NOT beaten (original used >=, so a tie read as a loss and
-- neither account reset). On a tie all tied clients seed the same RNG from
-- sorted UserIds, so they independently pick the SAME winner - one resets.
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

-- ===== SESSION STATS (persist across teleports) ================
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

-- stats updater (every 5s - cheap, no GUI tree walking)
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

-- RightControl resets the session stats
game:GetService("UserInputService").InputBegan:Connect(function(input, typing)
    if typing then return end
    if input.KeyCode == Enum.KeyCode.RightControl then
        startRank = getMyRank()
        startTime = os.time()
        saveSession()
        statLbl.Text = "+0  |  --/hr"
        setStatus("Stats reset", Color3.fromRGB(120, 110, 255))
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

-- Spams the reset until the character actually dies, then confirms.
local function forceReset(timeout)
    local t0 = tick()
    while tick() - t0 < (timeout or 8) do
        killOnce()
        task.wait(0.15)
        if not isAlive() then
            return true
        end
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

local function findButtonByText(searchText)
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil end
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextButton") and not obj:IsDescendantOf(statusGui)
            and string.upper(obj.Text):find(searchText) and isOnScreen(obj) then
            return obj
        end
    end
    return nil
end

local function findGoLabel()
    local pg = player:FindFirstChild("PlayerGui")
    if not pg then return nil end
    for _, obj in ipairs(pg:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local raw = obj.Text
            if raw and #raw > 0 and #raw <= 6 then
                local t = raw:gsub("%s+", ""):gsub("[!%.%-]", ""):upper()
                if t == "GO" and isOnScreen(obj) then
                    return obj
                end
            end
        end
    end
    return nil
end

local function textIsGo(raw)
    if not raw or #raw == 0 or #raw > 6 then return false end
    local t = raw:gsub("%s+", ""):gsub("[!%.%-]", ""):upper()
    return t == "GO"
end

local function objectIsGo(obj)
    if not obj or not obj.Parent then return false end
    local ok, res = pcall(function()
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then
            return textIsGo(obj.Text)
        end
        return false
    end)
    return ok and res == true
end

local function waitForGo(timeout)
    local found = false
    local conns = {}
    local pg = player:FindFirstChild("PlayerGui")

    if pg then
        local ok, c = pcall(function()
            return pg.DescendantAdded:Connect(function(obj)
                task.wait()
                if objectIsGo(obj) then found = true end
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
    local VIM = game:GetService("VirtualInputManager")
    local inset = game:GetService("GuiService"):GetGuiInset()
    local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
    local x, y = pos.X + inset.X, pos.Y + inset.Y
    VIM:SendMouseMoveEvent(x, y, game)
    task.wait(0.3)
    VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
    task.wait(0.1)
    VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
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
        task.wait(2)
    end
end)

task.spawn(function()
    while true do
        if findNewGameButton() then
            clickUntilGone(findNewGameButton, "NEW GAME")
        end
        task.wait(2)
    end
end)

-- ===== MAIN ===================================================
task.spawn(function()
    local t0 = tick()
    while getMyRank() == nil and tick() - t0 < 30 do
        task.wait(0.5)
    end
    print("rank loaded:", tostring(getMyRank()))

    while true do
        if isAlive() and amIHighest() then

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

            -- ROUND GATE: do not start another cycle until this round is clearly over
            print("waiting for round to end..."); setStatus("Round end", Color3.fromRGB(130,130,155))
            local gateStart = tick()
            local sawEnd = false
            while tick() - gateStart < 90 do
                if findNewGameButton() then
                    sawEnd = true
                    break
                end
                task.wait(1)
            end
            print(sawEnd and "round ended (NEW GAME seen)" or "round gate timed out")

            task.wait(4)
            print("=== cycle end ==="); setStatus("Running", Color3.fromRGB(60,220,140))
        end
        task.wait(0.5)
    end
end)

print("Ranked Auto-Reset Script Loaded Successfully!")
