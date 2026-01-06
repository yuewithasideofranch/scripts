-- Use this on the MAIN to autofarm!
-- made with <3 by yue

local lp = game:GetService("Players").LocalPlayer
local backpack = lp:WaitForChild("Backpack")
local savedPos = nil
local farming = false

local function teleport(pos)
    if lp.Character and lp.Character.PrimaryPart then
        lp.Character:SetPrimaryPartCFrame(CFrame.new(pos))
    end
end

local function safeFire(args)
    pcall(function()
        if lp.Character and lp.Character:FindFirstChild("Communicate") then
            lp.Character.Communicate:FireServer(unpack(args))
        end
    end)
end

local function useTool(toolName)
    local tool = backpack:FindFirstChild(toolName)
    if not tool then
        return false
    end

    safeFire({
        [1] = {
            ["Goal"] = "Console Move",
            ["Tool"] = tool
        }
    })

    return true
end

local function isDeadBodyNearby(radius)
    return true
end

local function farmLoop()
    while true do
        if not farming or not savedPos then
            task.wait(0.1)
            continue
        end

        if not (lp.Character and lp.Character.PrimaryPart) then
            task.wait(0.1)
            continue
        end
        task.wait(0.1)
        teleport(savedPos)

        safeFire({
            [1] = {
                ["Goal"] = "KeyPress",
                ["Key"] = Enum.KeyCode.G
            }
        })

        if isDeadBodyNearby(20) then
            if not backpack:FindFirstChild("Jet Dive") then
                local ok1 = useTool("Thunder Kick")
                local ok2 = useTool("Flamewave Cannon")

                if not (ok1 and ok2 and ok3) then
                    task.wait(5)
                    continue
                end
            else
                local needed = {
                    "Jet Dive",
                    "Blitz Shot",
                    "Ignition Burst",
                    "Machine Gun Blows"
                }

                for _, toolName in ipairs(needed) do
                    if not useTool(toolName) then
                        task.wait(5)
                    end
                end
            end
        else
            task.wait(1)
        end
    end
end

spawn(farmLoop)

for _,player in ipairs(game.Players:GetPlayers()) do
    player.Chatted:Connect(function(msg)
        msg = msg:lower()
        if player == lp then
            if msg == ".sp" then
                if player.Character and player.Character.PrimaryPart then
                    savedPos = player.Character.PrimaryPart.Position
                    print("[.setpos] Saved position of " .. player.Name .. ":", savedPos)
                end
            end
            if msg == ".fa" then
                if savedPos then
					wait(5)
                    farming = true
                    print("[.farm] Started farming loop.")
                else
                    print("[.farm] No position saved.")
                end
            end
            if msg == ".st" then
                farming = false
                print("[.stop] Stopped farming.")
            end   
        end
    end)
end
