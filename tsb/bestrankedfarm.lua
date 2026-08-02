-- cracked with love by yue - FYI, this code is hella ai because i fixed up his shit and it was ass and had hella issues, this versions js better & free <33

local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- ===== MAIN SCRIPT =====
local function runMainScript()
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer

    local function getMyRank()
        return player:WaitForChild("leaderstats"):WaitForChild("Rank").Value
    end

    local function amIHighest()
        local myRank = getMyRank()
        for i, p in ipairs(Players:GetPlayers()) do
            if p ~= player then
                local ls = p:FindFirstChild("leaderstats")
                local rank = ls and ls:FindFirstChild("Rank")
                if rank and rank.Value >= myRank then
                    return false
                end
            end
        end
        return true
    end

    local function resetCharacter()
        local char = player.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.Health = 0
            end
        end
    end

    local function waitForRespawn(timeout)
        local startChar = player.Character
        local start = tick()
        while tick() - start < timeout do
            local char = player.Character
            if char and char ~= startChar and char:FindFirstChildOfClass("Humanoid") then
                return true
            end
            task.wait(0.2)
        end
        return false
    end

    local function isOnScreen(btn)
        local obj = btn
        while obj do
            if obj:IsA("GuiObject") then
                if obj.Visible then
                    obj = obj.Parent
                else
                    return false
                end
            else
                break
            end
        end
        if btn.AbsoluteSize.X > 0 then
            return true
        else
            return false
        end
    end

    local function findButtonByText(searchText)
        local gui = player:WaitForChild("PlayerGui")
        for i, obj in ipairs(gui:GetDescendants()) do
            if obj:IsA("TextButton") and string.upper(obj.Text):find(searchText) and isOnScreen(obj) then
                return obj
            end
        end
        return nil
    end

    local function findNewGameButton()
        local ok, btn = pcall(function()
            return player.PlayerGui.Ranked.Container.realholder.newgame
        end)
        if ok and btn and isOnScreen(btn) then
            return btn
        end
        return findButtonByText("NEW GAME")
    end

    local function findReadyButton()
        return findButtonByText("READY")
    end

    local function waitForNewGameButton(timeout)
        local start = tick()
        while tick() - start < timeout do
            local btn = findNewGameButton()
            if btn then
                return btn
            end
            task.wait(0.5)
        end
        return nil
    end

    local function clickOnce(btn)
        local VIM = game:GetService("VirtualInputManager")
        local inset = game:GetService("GuiService"):GetGuiInset()
        local pos = btn.AbsolutePosition + btn.AbsoluteSize / 2
        local x = pos.X + inset.X
        local y = pos.Y + inset.Y
        VIM:SendMouseMoveEvent(x, y, game)
        task.wait(0.3)
        VIM:SendMouseButtonEvent(x, y, 0, true, game, 1)
        task.wait(0.1)
        VIM:SendMouseButtonEvent(x, y, 0, false, game, 1)
    end

    local function clickUntilGone(findFn, label)
        local btn = findFn()
        if not btn then
            return false
        end
        for attempt = 1, 5 do
            print(label, "click attempt", attempt)
            clickOnce(btn)
            task.wait(1.5)
            local stillThere = findFn()
            if stillThere == nil then
                print(label, "gone - click worked")
                return true
            end
            btn = stillThere
        end
        print(label, "still visible after 5 attempts")
        return false
    end

    -- watcher: clicks READY anytime it shows up
    task.spawn(function()
        while true do
            local btn = findReadyButton()
            if btn then
                print("watcher: READY appeared - clicking")
                clickUntilGone(findReadyButton, "READY")
            end
            task.wait(1)
        end
    end)

    -- watcher: clicks NEW GAME anytime it shows up, regardless of rank
    task.spawn(function()
        while true do
            local btn = findNewGameButton()
            if btn then
                print("watcher: NEW GAME appeared - clicking")
                clickUntilGone(findNewGameButton, "NEW GAME")
            end
            task.wait(1)
        end
    end)

    task.wait(11) -- let the game finish loading before we start the reset logic

    while true do
        if amIHighest() then
            print("Highest rank - reset 1")
            resetCharacter()

            local respawned = waitForRespawn(6)
            if respawned then
                print("respawned after reset 1")
            else
                print("no respawn detected after reset 1 (timeout)")
            end

            task.wait(0.5)

            print("Reset 2")
            resetCharacter()

            print("Waiting for NEW GAME button...")
            local btn = waitForNewGameButton(30)
            if btn then
                task.wait(2)
                clickUntilGone(findNewGameButton, "NEW GAME")
            else
                print("NEW GAME button never appeared")
            end
        end
        task.wait(5)
    end
end

-- ===== AUTO-EXECUTE ON SERVER JOIN =====
-- This will run the script automatically when you join any server
-- and re-run it if the script stops or the game reloads

local function startScript()
    -- Check if we're already running to prevent duplicates
    if not getgenv().AutoResetRunning then
        getgenv().AutoResetRunning = true
        print("Auto-Reset Script Started!")
        task.spawn(runMainScript)
    end
end

-- Start immediately
startScript()

-- Also start when the player respawns or game state changes
player.CharacterAdded:Connect(function()
    -- Small delay to let everything load
    task.wait(1)
    startScript()
end)

-- Re-run if the player's PlayerGui loads (for server changes)
player:WaitForChild("PlayerGui").ChildAdded:Connect(function()
    task.wait(2)
    startScript()
end)

-- For re-execution on game reload (some executors support this)
if syn and syn.reload then
    syn.reload(function()
        getgenv().AutoResetRunning = false
        startScript()
    end)
end

print("Auto-Reset Script Loaded - Will auto-execute on every server join!")
