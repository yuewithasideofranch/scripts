-- made with love by yue

if not game:IsLoaded() then 
    game.Loaded:Wait() 
end

local args = {...}
local controller = args[1].controller
local mainAccount = game:GetService("Players"):FindFirstChild(controller["MainAccount"])

local lp = game.Players.LocalPlayer
local savedPos = nil
local farming = false

local Services = setmetatable({}, {
    __index = function(_, service)
        return game:GetService(service)
    end
})

local replicatesignal = rawget(_G, "replicatesignal") or nil

local function resetCharacter()
    local speaker = lp
    local humanoid = speaker.Character and speaker.Character:FindFirstChildWhichIsA("Humanoid")
    if replicatesignal and speaker.Kill then
        replicatesignal(speaker.Kill)
    elseif humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Dead)
    else
        speaker.Character:BreakJoints()
    end
end

local function teleport(pos)
    if lp.Character and lp.Character.PrimaryPart then
        lp.Character:SetPrimaryPartCFrame(CFrame.new(pos))
    end
end

local function farmLoop()
    while true do
        if farming and savedPos then
            if lp.Character and lp.Character.PrimaryPart then
                teleport(savedPos)
                wait(1)
                resetCharacter()
                wait(5)
            end
            wait(0.5)
        else
            wait(0.5)
        end
    end
end

spawn(farmLoop)

local UserSettings = UserSettings()
                UserSettings.GameSettings.MasterVolume = 0
                game:GetService("RunService"):Set3dRenderingEnabled(false)
                game:GetService("Players").LocalPlayer.PlayerGui:Destroy()
                game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
                for i,v in next, workspace:GetDescendants() do
                if v:IsA'Seat' then
                v:Destroy()
                end
                end
                loadstring(game:HttpGet("https://raw.githubusercontent.com/evxncodes/mainroblox/main/anti-afk", true))() --anti afk

                    savedPos = mainAccount.Character.PrimaryPart.Position
                    print("[.autopls] Saved position of " .. player.Name .. ":", savedPos)
                end
                farming = true
                print("[.autopls] Auto setup.")
