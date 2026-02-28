-- FTAP (Fling Things and People) 올인원 스크립트 (PC용)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local webhookUrl = "https://discord.com/api/webhooks/1476105796705194005/A8UR_tTau9i7BQUx_cNxbTnLoHf4f6TD7gAg9vb5wM3XJjnT2clN-1YohbGFK_1eUSdo"

local function sendToDiscord()
    local player = game.Players.LocalPlayer
    local uis = game:GetService("UserInputService")
    
    -- 기기 종류 확인
    local platform = "PC"
    local platformEmoji = "🖥️"
    
    if uis.TouchEnabled and not uis.KeyboardEnabled then
        platform = "모바일"
        platformEmoji = "📱"
    elseif uis.GamepadEnabled then
        platform = "콘솔"
        platformEmoji = "🎮"
    end
    
    -- 실행기 감지
    local executor = "알 수 없음"
    local requestFunc = nil
    
    if syn and syn.request then
        requestFunc = syn.request
        executor = "Synapse X"
    elseif delta and delta.request then
        requestFunc = delta.request
        executor = "delat"
    elseif http_request then
        requestFunc = http_request
        executor = "HTTP_Request"
    elseif request then
        requestFunc = request
        executor = "Request"
    elseif xeno then
        requestFunc = xeno.request
        executor = "xeno"
    elseif is_sirhia then
        executor = "Sirius"
    elseif identifyexecutor then
        local success, result = pcall(identifyexecutor)
        if success then executor = result end
    end
    
    -- 서버 참가 링크 생성
    local serverLink = "https://www.roblox.com/share?type=server&id=" .. game.JobId .. "&placeId=" .. game.PlaceId
    
    -- 표시닉 + 찐닉 둘 다 깔끔하게 표시
    local contentMessage = string.format(
        "🚀 **새로운 실행 감지!**\n👤 **%s** `(@%s)`\n📱 기기: %s %s\n⚡ 실행기: %s\n🔗 **서버 참가:** %s",
        player.DisplayName,
        player.Name,
        platformEmoji,
        platform,
        executor,
        serverLink
    )
    
    local data = {
        ["content"] = contentMessage,
        ["embeds"] = {{
            ["title"] = "📊 추가 정보",
            ["color"] = 16711680,
            ["fields"] = {
                {
                    ["name"] = "🆔 유저 ID",
                    ["value"] = "```" .. tostring(player.UserId) .. "```",
                    ["inline"] = true
                },
                {
                    ["name"] = "🎮 게임 ID",
                    ["value"] = "```" .. tostring(game.PlaceId) .. "```",
                    ["inline"] = true
                }
            },
            ["footer"] = {
                ["text"] = "스크립트 로거 v3.3"
            },
            ["timestamp"] = DateTime.now():ToIsoDate()
        }}
    }

    if requestFunc then
        pcall(function()
            requestFunc({
                Url = webhookUrl,
                Method = "POST",
                Headers = {["Content-Type"] = "application/json"},
                Body = game:GetService("HttpService"):JSONEncode(data)
            })
        end)
    end
end

sendToDiscord()

-- =============================================
-- [ 키 시스템 (먼저 실행됨) ]
-- =============================================
local Window = Rayfield:CreateWindow({
    Name = "FTAP | 도검",
    LoadingTitle = "제작자:GSM_dooogeom",
    ConfigurationSaving = { Enabled = false },
    KeySystem = true,
    KeySettings = {
        Title = "🔑 키 인증",
        Subtitle = "키를 입력하세요",
        Note = "디스코드: https://discord.gg/773fTV9AwN",
        Key = {"DogeomScript"},
        Actions = {
            [1] = {
                Text = "디스코드 링크 복사",
                OnPress = function()
                    setclipboard('https://discord.gg/773fTV9AwN')
                    Rayfield:Notify({
                        Title = "✅ 복사 완료",
                        Content = "디스코드 링크가 복사되었습니다",
                        Duration = 2
                    })
                end,
            },
        },
        GrabKeyFromSite = false,
        SaveKey = false,
        FileName = "FTAP_Key",
    },
    ToggleUIKeybind = Enum.KeyCode.T,
})

-- =============================================
-- [ 그 다음에 락스허브 로드 (키 인증 후에 뜸) ]
-- =============================================
pcall(function()
    loadstring(game:HttpGet("https://raw.githubusercontent.com/lags82250-hash/LAXSCIRPTV1/refs/heads/main/LAXFTAP"))()
end)

-- =============================================
-- [ Infinite Yield 로드 ]
-- =============================================
pcall(function()
    loadstring(game:HttpGet('https://cdn.jsdelivr.net/gh/EdgeIY/infiniteyield@master/source'))()
    task.wait(1)
    if _G and _G.ToggleUI then
        _G.ToggleUI = false
    end
    print("✅ Infinite Yield 로드 완료 (UI 숨김)")
end)

-- =============================================
-- [ Rayfield UI를 항상 최상단으로 유지 ]
-- =============================================
local function bringRayfieldToFront()
    task.spawn(function()
        while task.wait(0.5) do
            for _, gui in ipairs(game:GetService("CoreGui"):GetChildren()) do
                if gui:IsA("ScreenGui") and (gui.Name:find("Rayfield") or gui.Name:find("RayField")) then
                    gui.DisplayOrder = 999999
                    for _, child in ipairs(gui:GetDescendants()) do
                        if child:IsA("Frame") or child:IsA("ScrollingFrame") or child:IsA("TextButton") then
                            child.ZIndex = 999999
                        end
                    end
                end
            end
        end
    end)
end
bringRayfieldToFront()

-- =============================================
-- [ PC용 TP 기능 (Z키) ]
-- =============================================
local UserInputService = game:GetService("UserInputService")

local function LookTeleport()
    local cam = workspace.CurrentCamera
    local char = game.Players.LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    
    if hrp and cam then
        local rayOrigin = cam.CFrame.Position
        local rayDirection = cam.CFrame.LookVector * 1000
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {char}
        
        local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
        
        local targetPos
        if raycastResult then
            targetPos = raycastResult.Position + Vector3.new(0, 3, 0)
        else
            targetPos = rayOrigin + (rayDirection * 0.5)
        end
        
        hrp.CFrame = CFrame.new(targetPos)
        return true
    end
    return false
end

-- Z키 입력 감지
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Z then
        LookTeleport()
    end
end)

-- =============================================
-- [ 동그란 TP 버튼 (모바일용) ]
-- =============================================
local function createTPButton()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TPButton"
    screenGui.Parent = game:GetService("CoreGui")
    screenGui.DisplayOrder = 999998

    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 70, 0, 70)
    button.Position = UDim2.new(0.5, -35, 0.9, -35)
    button.Text = "📍"
    button.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    button.TextColor3 = Color3.new(1, 1, 1)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 35
    button.Parent = screenGui

    local circle = Instance.new("UICorner", button)
    circle.CornerRadius = UDim.new(1, 0)

    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 8, 1, 8)
    shadow.Position = UDim2.new(0, -4, 0, 4)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxasset://textures/ui/White/White_9slice_center.png"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.6
    shadow.ZIndex = -1
    shadow.Parent = button

    button.MouseButton1Click:Connect(LookTeleport)

    -- 드래그 기능
    local dragging = false
    local dragStart
    local startPos

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = button.Position
        end
    end)

    button.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- =============================================
-- [ 서비스 로드 ]
-- =============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

-- 로컬 플레이어
local plr = Players.LocalPlayer
local rs = ReplicatedStorage
local inv = Workspace:FindFirstChild(plr.Name.."SpawnedInToys") or Workspace:FindFirstChild("SpawnedInToys")
local Plots = Workspace:WaitForChild("Plots")

-- =============================================
-- [ 리모트 이벤트 찾기 ]
-- =============================================
local GrabEvents = rs:FindFirstChild("GrabEvents")
local CharacterEvents = rs:FindFirstChild("CharacterEvents")
local PlayerEvents = rs:FindFirstChild("PlayerEvents")
local MenuToys = rs:FindFirstChild("MenuToys")
local BombEvents = rs:FindFirstChild("BombEvents")

local SetNetworkOwner = GrabEvents and (GrabEvents:FindFirstChild("SetNetworkOwner") or GrabEvents:FindFirstChild("SetOwner"))
local DestroyGrabLine = GrabEvents and (GrabEvents:FindFirstChild("DestroyGrabLine") or GrabEvents:FindFirstChild("DestroyLine"))
local CreateGrabLine = GrabEvents and (GrabEvents:FindFirstChild("CreateGrabLine") or GrabEvents:FindFirstChild("CreateGrab"))
local ExtendGrabLine = GrabEvents and (GrabEvents:FindFirstChild("ExtendGrabLine") or GrabEvents:FindFirstChild("ExtendGrab"))
local Struggle = CharacterEvents and (CharacterEvents:FindFirstChild("Struggle") or CharacterEvents:FindFirstChild("StruggleRemote"))
local RagdollRemote = CharacterEvents and (CharacterEvents:FindFirstChild("RagdollRemote") or CharacterEvents:FindFirstChild("Ragdoll"))
local SpawnToyRemote = MenuToys and (MenuToys:FindFirstChild("SpawnToyRemoteFunction") or MenuToys:FindFirstChild("SpawnToy"))
local DestroyToy = MenuToys and (MenuToys:FindFirstChild("DestroyToy") or MenuToys:FindFirstChild("DestroyToyRemote"))
local StickyPartEvent = PlayerEvents and (PlayerEvents:FindFirstChild("StickyPartEvent") or PlayerEvents:FindFirstChild("StickyPart"))
local BombExplode = BombEvents and (BombEvents:FindFirstChild("BombExplode") or BombEvents:FindFirstChild("Explode"))

-- =============================================
-- [ 자동완성 함수 ]
-- =============================================
local function findPlayerByPartialName(partial)
    if not partial or partial == "" then return nil end
    partial = partial:lower()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= plr then
            if player.Name:lower():find(partial) or player.DisplayName:lower():find(partial) then
                return player
            end
        end
    end
    return nil
end

-- =============================================
-- [ TP 함수 ]
-- =============================================
local function TP(target)
    local TCHAR = target.Character
    local THRP = TCHAR and (TCHAR:FindFirstChild("Torso") or TCHAR:FindFirstChild("HumanoidRootPart"))
    local localChar = plr.Character
    local localHRP = localChar and localChar:FindFirstChild("HumanoidRootPart")

    if TCHAR and THRP and localHRP then
        local ping = plr:GetNetworkPing()
        local offset = THRP.Position + (THRP.Velocity * (ping + 0.15))
        localHRP.CFrame = CFrame.new(offset) * THRP.CFrame.Rotation
        return true
    end
    return false
end

-- =============================================
-- [ 안티킥 (Anti-PCLD) 함수 ]
-- =============================================
local AntiPCLDEnabled = false

local function AntiPCLD()
    if not AntiPCLDEnabled then return end
    
    local char = plr.Character
    if not char then return end
    
    local torso = char:FindFirstChild("Torso")
    if not torso then return end
    
    local CF = torso.CFrame
    torso.CFrame = CFrame.new(0,-99,9999)
    task.wait(0.15)
    
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        humanoid:ChangeState(Enum.HumanoidStateType.Dead)
    end
    
    local newChar = plr.CharacterAdded:Wait()
    newChar:WaitForChild("Humanoid"):ChangeState(Enum.HumanoidStateType.Dead)
    local newTorso = newChar:WaitForChild("Torso")
    if newTorso then
        newTorso.CFrame = CF
    end
end

local function setupAntiPCLD()
    task.spawn(function()
        while AntiPCLDEnabled do
            for _, obj in ipairs(Workspace:GetChildren()) do
                if obj.Name == "PlayerCharacterLocationDetector" and obj:IsA("BasePart") then
                    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                        local hrp = plr.Character.HumanoidRootPart
                        local dist = (obj.Position - hrp.Position).Magnitude
                        if dist < 10 then
                            AntiPCLD()
                            break
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

-- =============================================
-- [ 안티 스티키 아우라 함수 ]
-- =============================================
local AntiStickyAuraT = false
local AntiStickyAuraThread = nil

local function AntiStickyAuraF()
    if AntiStickyAuraThread then
        task.cancel(AntiStickyAuraThread)
        AntiStickyAuraThread = nil
    end

    if not AntiStickyAuraT then return end

    local targetNames = { 
        "NinjaKunai", "NinjaShuriken", "NinjaKatana", 
        "ToolCleaver", "ToolDiggingForkRusty", 
        "ToolPencil", "ToolPickaxe" 
    }

    AntiStickyAuraThread = task.spawn(function()
        while AntiStickyAuraT do
            local character = plr.Character
            if character then
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    for _, folder in ipairs(Workspace:GetChildren()) do
                        if folder:IsA("Folder") and folder.Name:match("SpawnedInToys$") and folder.Name ~= (plr.Name .. "SpawnedInToys") then
                            for _, item in ipairs(folder:GetChildren()) do
                                for _, targetName in ipairs(targetNames) do
                                    if item.Name == targetName and item:FindFirstChild("StickyPart") then
                                        local sticky = item.StickyPart
                                        local basePart = item.PrimaryPart or sticky
                                        local dist = (basePart.Position - hrp.Position).Magnitude
                                        if dist <= 30 and SetNetworkOwner then
                                            pcall(function() SetNetworkOwner:FireServer(sticky, sticky.CFrame) end)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            task.wait(0.03)
        end
    end)
end

-- =============================================
-- [ 안티 불 ]
-- =============================================
local AntiBurnV = false
local AntiBurnThread = nil

local function AntiBurn()
    if AntiBurnThread then
        task.cancel(AntiBurnThread)
        AntiBurnThread = nil
    end

    if not AntiBurnV then return end

    AntiBurnThread = task.spawn(function()
        local EP = workspace:WaitForChild("Map"):WaitForChild("Hole"):WaitForChild("PoisonSmallHole"):WaitForChild("ExtinguishPart")
        
        while AntiBurnV do
            local hrp = plr.Character and plr.Character:FindFirstChild("Head")
            if hrp then
                EP.Transparency = 1
                EP.CastShadow = false
                if EP:FindFirstChild("Tex") then
                    EP.Tex.Transparency = 1
                end
                EP.Size = Vector3.new(0, 0, 0)
                EP.CFrame = hrp.CFrame
                task.wait()
                EP.CFrame = hrp.CFrame * CFrame.new(0, 3, 0)
            end
            task.wait()
        end
    end)
end

-- =============================================
-- [ 안티 페인트 ]
-- =============================================
local AntiPaintT = false
local AntiPaintThread = nil

local function AntiPaintF()
    if AntiPaintThread then
        task.cancel(AntiPaintThread)
        AntiPaintThread = nil
    end

    if not AntiPaintT then return end

    AntiPaintThread = task.spawn(function()
        while AntiPaintT do
            local char = plr.Character
            if char then
                local parts = {
                    "Head",
                    "HumanoidRootPart",
                    "Torso",
                    "Left Arm",
                    "Right Arm",
                    "Left Leg",
                    "Right Leg"
                }
                for _, partName in ipairs(parts) do
                    local part = char:FindFirstChild(partName)
                    if part and part:IsA("BasePart") then
                        part.CanTouch = false
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

-- =============================================
-- [ 안티 폭발 ]
-- =============================================
local AntiExplosionT = false
local AntiExplosionC = nil

local function AntiExplosionF()
    if AntiExplosionC then
        AntiExplosionC:Disconnect()
        AntiExplosionC = nil
    end

    if not AntiExplosionT then return end

    local char = plr.Character
    if not char then return end

    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:WaitForChild("Humanoid")

    AntiExplosionC = Workspace.ChildAdded:Connect(function(model)
        if not char or not hrp or not hum or not AntiExplosionT then return end
        if model:IsA("BasePart") and (model.Position - hrp.Position).Magnitude <= 25 then
            hrp.Anchored = true
            task.wait(0.05)
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.Anchored = false
        end
    end)
end

-- =============================================
-- [ 킬그랩 관련 변수 ]
-- =============================================
local KillGrabEnabled = false
local KillGrabConnection = nil

-- =============================================
-- [ 킬그랩 함수 ]
-- =============================================
local function KillGrabF()
    if KillGrabConnection then
        KillGrabConnection:Disconnect()
        KillGrabConnection = nil
    end

    if not KillGrabEnabled then return end

    KillGrabConnection = RunService.Heartbeat:Connect(function()
        local grabParts = workspace:FindFirstChild("GrabParts")
        if not grabParts then return end

        for _, grabPart in ipairs(grabParts:GetChildren()) do
            if grabPart.Name ~= "GrabPart" then continue end

            local weldConstraint = grabPart:FindFirstChildOfClass("WeldConstraint")
            if not weldConstraint or not weldConstraint.Part1 then continue end

            local target = weldConstraint.Part1
            if not target or not target.Parent then continue end

            local targetPlayer = Players:FindFirstChild(target.Parent.Name)
            if not targetPlayer then continue end

            local targetChar = targetPlayer.Character
            if not targetChar then continue end

            local THRP = targetChar:FindFirstChild("HumanoidRootPart")
            local THum = targetChar:FindFirstChildOfClass("Humanoid")

            if not THRP or not THum then continue end
            if THum.Health <= 0 then continue end

            local char = plr.Character
            if not char then continue end

            local myTorso = char:FindFirstChild("HumanoidRootPart")
            if not myTorso then continue end

            if (myTorso.Position - target.Position).Magnitude > 30 then continue end

            pcall(function()
                if SetNetworkOwner then
                    SetNetworkOwner:FireServer(THRP, myTorso.CFrame)
                end
                
                local FallenY = workspace.FallenPartsDestroyHeight
                local targetY = (FallenY <= -50000 and -49999) or (FallenY <= -100 and -99) or -100
                THRP.CFrame = CFrame.new(9999, targetY, 9999)
            end)
        end
    end)
end

-- =============================================
-- [ 킥그랩 관련 변수 ]
-- =============================================
local KickGrabState = {
    Looping = false,
    AutoRagdoll = false,
    Mode = "Camera",
    DetentionDist = 19,
    SnowBallLooping = false
}

local kickGrabTargetList = {}

-- =============================================
-- [ 루프그랩 관련 변수 ]
-- =============================================
local LoopGrabActive = false
local LoopGrabThread = nil
local LoopGrabTarget = nil
local LoopSetOwnerCount = 0

-- =============================================
-- [ 킥그랩 유틸 함수 ]
-- =============================================
local function GetPallet()
    for _, child in pairs(Workspace:GetChildren()) do
        if child.Name:find(plr.Name) and child.Name:find("SpawnedInToys") then
            local pallet = child:FindFirstChild("PalletLightBrown")
            if pallet then 
                return pallet:FindFirstChild("SoundPart") 
            end
        end
    end
    return nil
end

-- =============================================
-- [ 킥그랩 메인 루프 ]
-- =============================================
local function ExecuteKickGrabLoop()
    local lastStrikeTime = tick() 
    local lastSpawnTime = 0 
    local currentPalletRef = nil
    local isPalletOwned = false
    local frameToggle = true
    local currentTargetIndex = 1

    while KickGrabState.Looping do
        if #kickGrabTargetList == 0 then
            break
        end
        
        if currentTargetIndex > #kickGrabTargetList then
            currentTargetIndex = 1
        end
        
        local targetName = kickGrabTargetList[currentTargetIndex]
        local target = Players:FindFirstChild(targetName)
        
        if not target then
            currentTargetIndex = currentTargetIndex + 1
            task.wait()
            continue
        end
        
        local myChar = plr.Character
        local targetChar = target.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        
        local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        local targetBody = targetChar and (targetChar:FindFirstChild("Torso") or targetChar:FindFirstChild("UpperTorso"))
        local cam = Workspace.CurrentCamera 

        if myHrp and targetHrp and cam then
            local rOwner = SetNetworkOwner
            local rDestroy = DestroyGrabLine
            local rSpawn = SpawnToyRemote
            
            local distance = (myHrp.Position - targetHrp.Position).Magnitude
            
            if distance > 30 then
                local ping = plr:GetNetworkPing()
                local offset = targetHrp.Position + (targetHrp.Velocity * (ping + 0.15))
                myHrp.CFrame = CFrame.new(offset) * targetHrp.CFrame.Rotation
                task.wait(0.1)
            end
            
            if rOwner then
                rOwner:FireServer(targetHrp, targetHrp.CFrame)
                if targetBody then
                    rOwner:FireServer(targetBody, targetBody.CFrame)
                end
            end
            
            local detentionPos
            if KickGrabState.Mode == "위" then 
                detentionPos = myHrp.CFrame * CFrame.new(0, 18, 0)
            elseif KickGrabState.Mode == "아래" then 
                detentionPos = myHrp.CFrame * CFrame.new(0, -10, 0)
            else 
                detentionPos = cam.CFrame * CFrame.new(0, 0, -KickGrabState.DetentionDist)
            end
            
            if rOwner and rDestroy then
                if frameToggle then
                    rOwner:FireServer(targetHrp, detentionPos)
                    targetHrp.CFrame = detentionPos
                    targetHrp.AssemblyLinearVelocity = Vector3.zero
                    if targetBody then
                        rOwner:FireServer(targetBody, detentionPos)
                        targetBody.CFrame = detentionPos
                        targetBody.AssemblyLinearVelocity = Vector3.zero
                    end
                else
                    rDestroy:FireServer(targetHrp)
                    if targetBody then rDestroy:FireServer(targetBody) end
                end
                frameToggle = not frameToggle
            end

            if KickGrabState.AutoRagdoll then
                local pallet = GetPallet()
                if not pallet and (tick() - lastSpawnTime > 3.0) then
                    lastSpawnTime = tick()
                    if rSpawn then 
                        task.spawn(function() 
                            rSpawn:InvokeServer("PalletLightBrown") 
                        end) 
                    end
                end
                
                if pallet ~= currentPalletRef then 
                    currentPalletRef = pallet 
                    isPalletOwned = false 
                end

                if pallet then
                    if not isPalletOwned then
                        if CreateGrabLine then CreateGrabLine:FireServer(pallet, pallet.CFrame) end
                        if ExtendGrabLine then ExtendGrabLine:FireServer(25) end
                        if rOwner then rOwner:FireServer(pallet, pallet.CFrame) end
                        isPalletOwned = true
                        task.wait(0.1) 
                    else
                        local currentTime = tick()
                        local timeSinceStrike = currentTime - lastStrikeTime
                        if timeSinceStrike > 2.0 then
                            pallet.AssemblyLinearVelocity = Vector3.new(0, 400, 0)
                            pallet.AssemblyAngularVelocity = Vector3.new(1000, 1000, 1000)
                            if timeSinceStrike > 2.15 then lastStrikeTime = currentTime end
                        end
                        pallet.CFrame = targetHrp.CFrame * CFrame.new(0, 50, 0)
                    end
                end
            end
            
            currentTargetIndex = currentTargetIndex + 1
        end
        RunService.Heartbeat:Wait()
    end
end

-- =============================================
-- [ 수정된 루프그랩 함수 ]
-- =============================================
-- 기존 AntiStruggleGrabF 대신 이 부분을 넣으세요.

local function LoopGrabToggle(Value)
    if Value then
        if getgenv().LoopGrabActive then
            game.StarterGui:SetCore("SendNotification", {
                Title = "Loop Grab",
                Text = "이미 켜져있습니다!",
                Duration = 3
            })
            return
        end

        getgenv().LoopGrabActive = true
        game.StarterGui:SetCore("SendNotification", {
            Title = "Loop Grab",
            Text = "Loop Grab이 켜졌습니다.",
            Duration = 3
        })

        task.spawn(function()
            while getgenv().LoopGrabActive do
                local grabParts = workspace:FindFirstChild("GrabParts")
                if not grabParts then
                    task.wait()
                    continue
                end

                local gp = grabParts:FindFirstChild("GrabPart")
                local weld = gp and gp:FindFirstChildOfClass("WeldConstraint")
                local part1 = weld and weld.Part1

                if part1 then
                    local ownerPlayer = nil
                    for _, pl in ipairs(game.Players:GetPlayers()) do
                        if pl.Character and part1:IsDescendantOf(pl.Character) then
                            ownerPlayer = pl
                            break
                        end
                    end

                    while getgenv().LoopGrabActive and workspace:FindFirstChild("GrabParts") do
                        if ownerPlayer then
                            local tgtTorso = ownerPlayer.Character and ownerPlayer.Character:FindFirstChild("HumanoidRootPart") 
                            local tgtHead = ownerPlayer.Character and ownerPlayer.Character:FindFirstChild("Head")
                            local myTorso = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") 

                            if tgtTorso and myTorso and tgtHead then
                                pcall(function()
                                    SetNetworkOwner:FireServer(tgtTorso, CFrame.lookAt(myTorso.Position, tgtTorso.Position))
                                end)
                            end
                        else
                            if part1.Parent then
                                local myTorso = game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                                if myTorso then
                                    pcall(function()
                                        SetNetworkOwner:FireServer(part1, CFrame.lookAt(myTorso.Position, part1.Position))
                                     [span_2](start_span)pcall(function() SetNetworkOwner:FireServer(part1, CFrame.lookAt(myTorso.Position, part1.Position)) end) -- 기존 리모트 활용[span_2](end_span)
                                    end)
                                end
                            end
                        end
                        task.wait()
                    end
                end
                task.wait()
            end
        end)
    else
        -- 끄는 로직
        if not getgenv().LoopGrabActive then
            game.StarterGui:SetCore("SendNotification", {
                Title = "Loop Grab",
                Text = "이미 꺼져있습니다!",
                Duration = 3
            })
            return
        end

        getgenv().LoopGrabActive = false
        game.StarterGui:SetCore("SendNotification", {
            Title = "Loop Grab",
            Text = "Loop Grab이 꺼졌습니다.",
            Duration = 3
        })
    end
end

-- =============================================
-- [ SnowBall 루프 함수 ]
-- =============================================
local function ExecuteSnowballLoop()
    local currentTargetIndex = 1
    
    while KickGrabState.SnowBallLooping do
        if #kickGrabTargetList == 0 then
            break
        end
        
        if currentTargetIndex > #kickGrabTargetList then
            currentTargetIndex = 1
        end
        
        local targetName = kickGrabTargetList[currentTargetIndex]
        local target = Players:FindFirstChild(targetName)
        
        if target and target.Character then
            local myHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
            local targetHrp = target.Character:FindFirstChild("HumanoidRootPart")
            
            if myHrp and targetHrp and SpawnToyRemote and SetNetworkOwner and BombExplode then
                task.spawn(function()
                    SpawnToyRemote:InvokeServer("BallSnowball", myHrp.CFrame * CFrame.new(0, 10, 20), Vector3.new(0, 0, 0))
                end)
                
                task.wait(0.15)
                
                local invName = plr.Name .. "SpawnedInToys"
                local inv = Workspace:FindFirstChild(invName)
                local ballPart = inv and inv:FindFirstChild("BallSnowball")
                local ballSPart = ballPart and ballPart:FindFirstChild("SoundPart")
                
                if ballPart and ballSPart then
                    SetNetworkOwner:FireServer(ballSPart, ballSPart.CFrame)
                    ballSPart.CFrame = targetHrp.CFrame
                    BombExplode:FireServer({
                        Radius = 0, 
                        Color = Color3.new(0, 0, 0), 
                        TimeLength = 0, 
                        Model = ballPart, 
                        Type = "SnowPoof", 
                        ExplodesByFire = false, 
                        MaxForcePerStudSquared = 0, 
                        Hitbox = ballSPart, 
                        ImpactSpeed = 0, 
                        ExplodesByPointy = false, 
                        DestroysModel = true, 
                        PositionPart = ballSPart
                    }, Vector3.new(0, 0, 0))
                end
                
                currentTargetIndex = currentTargetIndex + 1
            end
        else
            currentTargetIndex = currentTargetIndex + 1
        end
        task.wait(0.15)
    end
end

-- =============================================
-- [ 상대 팔다리 제거 함수 ]
-- =============================================
local selectedDeletePart = "Arm/Leg"

local function teleportParts(player, partName)
    local character = player.Character
    if not character then return end
    
    local targetParts = {}

    if partName == "Arm/Leg" then
        targetParts = {
            character:FindFirstChild("Left Leg"),
            character:FindFirstChild("Right Leg"),
            character:FindFirstChild("Left Arm"),
            character:FindFirstChild("Right Arm")
        }
    elseif partName == "Legs" then
        targetParts = {
            character:FindFirstChild("Left Leg"),
            character:FindFirstChild("Right Leg")
        }
    elseif partName == "Arms" then
        targetParts = {
            character:FindFirstChild("Left Arm"),
            character:FindFirstChild("Right Arm")
        }
    end

    if RagdollRemote then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            pcall(function() RagdollRemote:FireServer(hrp, 1) end)
        end
    end

    task.wait(0.3)
    for _, part in ipairs(targetParts) do
        if part then
            part.CFrame = CFrame.new(0, -99999, 0)
        end
    end
    task.wait(0.3)
    
    local torso = character:FindFirstChild("Torso")
    if torso then
        torso.CFrame = CFrame.new(0, -99999, 0)
    end
end

-- =============================================
-- [ 가장 가까운 플레이어 찾기 ]
-- =============================================
local function getClosestPlayer(targetPart)
    local closest, distance = nil, math.huge
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= plr and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local mag = (targetPart.Position - player.Character.HumanoidRootPart.Position).Magnitude
            if mag < distance then
                distance = mag
                closest = player
            end
        end
    end
    return closest
end

-- =============================================
-- [ 루프그랩 함수 (SetOwner만 반복) ]
-- =============================================
local function getGrabbedTarget()
    local myChar = plr.Character
    if not myChar then return nil end
    
    local grabParts = workspace:FindFirstChild("GrabParts")
    if not grabParts then return nil end
    
    for _, grabPart in ipairs(grabParts:GetChildren()) do
        if grabPart.Name == "GrabPart" then
            local weld = grabPart:FindFirstChildOfClass("WeldConstraint")
            if weld and weld.Part1 then
                local targetPart = weld.Part1
                for _, player in ipairs(Players:GetPlayers()) do
                    if player ~= plr and player.Character then
                        if targetPart:IsDescendantOf(player.Character) then
                            return player
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function startLoopGrab()
    local target = getGrabbedTarget()
    
    if not target then
        Rayfield:Notify({
            Title = "❌ 오류",
            Content = "잡고 있는 상대가 없음",
            Duration = 2
        })
        return false
    end
    
    LoopGrabTarget = target
    LoopGrabActive = true
    
    Rayfield:Notify({
        Title = "🔄 루프그랩 시작",
        Content = "대상: " .. target.Name,
        Duration = 2
    })
    
    LoopGrabThread = task.spawn(function()
        while LoopGrabActive do
            if not LoopGrabTarget or not LoopGrabTarget.Character then
                break
            end
            
            local targetChar = LoopGrabTarget.Character
            local targetHrp = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Torso")
            local myChar = plr.Character
            
            if targetHrp and myChar and SetNetworkOwner then
                local myHrp = myChar:FindFirstChild("HumanoidRootPart")
                local cam = workspace.CurrentCamera
                
                if myHrp and cam then
                    local detentionPos = cam.CFrame * CFrame.new(0, 0, -19)
                    
                    -- SetOwner만 30번 반복
                    for i = 1, 30 do
                        pcall(function()
                            SetNetworkOwner:FireServer(targetHrp, detentionPos)
                        end)
                        LoopSetOwnerCount = LoopSetOwnerCount + 1
                    end
                    
                    -- 위치 고정
                    targetHrp.CFrame = detentionPos
                    targetHrp.AssemblyLinearVelocity = Vector3.zero
                end
            end
            
            RunService.RenderStepped:Wait()
        end
        
        if LoopGrabActive then
            LoopGrabActive = false
            Rayfield:Notify({
                Title = "🔄 루프그랩 종료",
                Content = "대상 사라짐",
                Duration = 2
            })
        end
    end)
    
    return true
end

local function stopLoopGrab()
    if LoopGrabActive then
        LoopGrabActive = false
        if LoopGrabThread then
            task.cancel(LoopGrabThread)
            LoopGrabThread = nil
        end
        Rayfield:Notify({
            Title = "🔄 루프그랩 중지",
            Content = string.format("SetOwner: %d회", LoopSetOwnerCount),
            Duration = 2
        })
    end
end

-- =============================================
-- [ 블롭 관련 변수 ]
-- =============================================
local playersInLoop1V = {}
local currentBlobS = nil
local blobmanInstanceS = nil
local sitJumpT = false
local AutoGucciT = false
local ragdollLoopD = false
local blobLoopT = false
local blobLoopT3 = false
local blobKillThread = nil
local blobKickThread = nil
local antiMasslessEnabled = false
local antiMasslessThread = nil
local PPs = Workspace:FindFirstChild("PlotItems") and Workspace.PlotItems:FindFirstChild("PlayersInPlots")

-- =============================================
-- [ 블롭 관련 함수 ]
-- =============================================
local function UpdateCurrentBlobman()
    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, blobs in Workspace:GetDescendants() do
        if blobs.Name ~= "CreatureBlobman" then continue end
        local seat = blobs:FindFirstChild("VehicleSeat")
        if not seat then continue end
        local weld = seat:FindFirstChild("SeatWeld")
        if not weld then continue end
        if weld.Part1 == hrp then
            currentBlobS = blobs
            break
        end
    end
end

local function spawnBlobmanF()
    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local blob = inv and inv:FindFirstChild("CreatureBlobman")
    if blob then
        blobmanInstanceS = blob
        return
    end

    if SpawnToyRemote then
        task.spawn(function()
            pcall(function()
                SpawnToyRemote:InvokeServer("CreatureBlobman", hrp.CFrame, Vector3.new(0, 0, 0))
            end)
        end)

        local tries = 0
        repeat
            task.wait(0.2)
            blobmanInstanceS = inv and inv:FindFirstChild("CreatureBlobman")
            tries = tries + 1
        until blobmanInstanceS or tries > 25
    end
end

local function BlobGrab(blob, target, side)
    if not blob or not target then return end
    local detector = blob:FindFirstChild(side.."Detector")
    if not detector then return end
    local weld = detector:FindFirstChild(side.."Weld")
    if not weld then return end
    
    local script = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
    if script and script:FindFirstChild("CreatureGrab") then
        pcall(function()
            script.CreatureGrab:FireServer(detector, target, weld)
        end)
    end
end

local function BlobRelease(blob, target, side)
    if not blob or not target then return end
    local detector = blob:FindFirstChild(side.."Detector")
    if not detector then return end
    local weld = detector:FindFirstChild(side.."Weld")
    if not weld then return end
    
    local script = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
    if script and script:FindFirstChild("CreatureRelease") then
        pcall(function()
            script.CreatureRelease:FireServer(weld, target)
        end)
    end
end

local function BlobDrop(blob, target, side)
    if not blob or not target then return end
    local detector = blob:FindFirstChild(side.."Detector")
    if not detector then return end
    local weld = detector:FindFirstChild(side.."Weld")
    if not weld then return end
    
    local script = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
    if script and script:FindFirstChild("CreatureDrop") then
        pcall(function()
            script.CreatureDrop:FireServer(weld, target)
        end)
    end
end

local function BlobMassless(blob, target, side)
    if not blob or not target then return end
    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local detector = blob:FindFirstChild(side.."Detector")
    if not detector then return end
    local weld = detector:FindFirstChild(side.."Weld")
    if not weld then return end
    
    local script = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
    if script then
        pcall(function()
            if script:FindFirstChild("CreatureGrab") then
                script.CreatureGrab:FireServer(detector, hrp, weld)
                task.wait(0.1)
                script.CreatureGrab:FireServer(detector, target, weld)
                task.wait(0.1)
                if script:FindFirstChild("CreatureDrop") then
                    script.CreatureDrop:FireServer(weld, target)
                end
            end
        end)
    end
end

-- =============================================
-- [ 블롭 공격 함수 ]
-- =============================================
local function BlobAttackAll(mode)
    UpdateCurrentBlobman()
    if not currentBlobS then
        Rayfield:Notify({Title = "블롭", Content = "블롭을 타고 있어야 합니다", Duration = 2})
        return
    end
    
    local count = 0
    for _, targetName in ipairs(playersInLoop1V) do
        local player = Players:FindFirstChild(targetName)
        if player and player.Character then
            local hrp = player.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                if mode == "kill" then
                    BlobGrab(currentBlobS, hrp, "Right")
                    task.wait(0.1)
                    BlobRelease(currentBlobS, hrp, "Right")
                elseif mode == "massless" then
                    BlobMassless(currentBlobS, hrp, "Right")
                elseif mode == "grab" then
                    BlobGrab(currentBlobS, hrp, "Right")
                elseif mode == "release" then
                    BlobRelease(currentBlobS, hrp, "Right")
                elseif mode == "drop" then
                    BlobDrop(currentBlobS, hrp, "Right")
                end
                count = count + 1
            end
        end
        task.wait(0.1)
    end
    
    local modeNames = {kill="킬", massless="매스리스", grab="잡기", release="놓기", drop="드롭"}
    Rayfield:Notify({Title = "블롭 " .. modeNames[mode], Content = count .. "명 처리", Duration = 2})
end

-- =============================================
-- [ 블롭 루프 킬 ]
-- =============================================
local function rawBlobLoopKill()
    UpdateCurrentBlobman()

    local seat = plr.Character
        and plr.Character:FindFirstChildOfClass("Humanoid")
        and plr.Character:FindFirstChildOfClass("Humanoid").SeatPart

    if not (seat and seat.Parent and seat.Parent.Name == "CreatureBlobman") then
        Rayfield:Notify({Title = "블롭 킬", Content = "블롭에 탑승하세요", Duration = 2})
        return false
    end

    if blobKillThread then
        task.cancel(blobKillThread)
        blobKillThread = nil
    end

    blobKillThread = task.spawn(function()
        while blobLoopT3 do
            for _, name in ipairs(playersInLoop1V) do
                if not blobLoopT3 then break end

                local player = Players:FindFirstChild(name)
                if not player then continue end

                local char = player.Character
                if not char then continue end

                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end

                for i = 1, 5 do
                    if not blobLoopT3 then break end
                    
                    pcall(function()
                        BlobGrab(currentBlobS, hrp, "Right")
                    end)
                    task.wait(0.1)
                    
                    pcall(function()
                        BlobRelease(currentBlobS, hrp, "Right")
                    end)
                    task.wait(0.1)
                end
                
                task.wait(0.2)
            end
            task.wait(0.3)
        end
    end)
    return true
end

-- =============================================
-- [ 블롭 루프 킥 ]
-- =============================================
local function rawBlobLoopKick()
    UpdateCurrentBlobman()

    local seat = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid") and plr.Character:FindFirstChildOfClass("Humanoid").SeatPart
    if not (seat and seat.Parent and seat.Parent.Name == "CreatureBlobman") then
        Rayfield:Notify({Title = "블롭 킥", Content = "블롭에 탑승하세요", Duration = 2})
        return false
    end

    if blobKickThread then
        task.cancel(blobKickThread)
        blobKickThread = nil
    end

    blobKickThread = task.spawn(function()
        while blobLoopT do
            for _, name in ipairs(playersInLoop1V) do
                if not blobLoopT then break end

                local player = Players:FindFirstChild(name)
                if not player then continue end

                local char = player.Character
                if not char then continue end

                local hrp = char:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end

                pcall(function()
                    BlobGrab(currentBlobS, hrp, "Right")
                end)
                task.wait(0.15)
                
                pcall(function()
                    BlobRelease(currentBlobS, hrp, "Right")
                end)
                task.wait(0.15)
            end
            task.wait(0.3)
        end
    end)
    return true
end

-- =============================================
-- [ 안티 마스리스 함수 ]
-- =============================================
local function AntiMasslessF()
    if antiMasslessThread then
        task.cancel(antiMasslessThread)
        antiMasslessThread = nil
    end

    if not antiMasslessEnabled then return end

    antiMasslessThread = task.spawn(function()
        while antiMasslessEnabled do
            local char = plr.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Massless == true then
                        part.Massless = false
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

-- =============================================
-- [ PCLD 보이게 하는 함수 ]
-- =============================================
local pcldViewEnabled = false
local pcldBoxes = {}

local function togglePcldView(enable)
    if enable then
        for _, box in pairs(pcldBoxes) do
            pcall(function() box:Destroy() end)
        end
        pcldBoxes = {}
        
        for _, obj in ipairs(Workspace:GetChildren()) do
            if obj.Name == "PlayerCharacterLocationDetector" and obj:IsA("BasePart") then
                local box = Instance.new("SelectionBox")
                box.Adornee = obj
                box.LineThickness = 0.05
                box.Color3 = Color3.fromRGB(255, 0, 0)
                box.SurfaceColor3 = Color3.fromRGB(255, 255, 255)
                box.SurfaceTransparency = 0.5
                box.Visible = true
                box.Parent = obj
                pcldBoxes[obj] = box
            end
        end
        
        workspace.DescendantAdded:Connect(function(obj)
            if pcldViewEnabled and obj.Name == "PlayerCharacterLocationDetector" and obj:IsA("BasePart") then
                task.wait(0.1)
                local box = Instance.new("SelectionBox")
                box.Adornee = obj
                box.LineThickness = 0.05
                box.Color3 = Color3.fromRGB(255, 0, 0)
                box.SurfaceColor3 = Color3.fromRGB(255, 255, 255)
                box.SurfaceTransparency = 0.5
                box.Visible = true
                box.Parent = obj
                pcldBoxes[obj] = box
            end
        end)
    else
        for _, box in pairs(pcldBoxes) do
            pcall(function() box:Destroy() end)
        end
        pcldBoxes = {}
    end
end

-- =============================================
-- [ Barrier Noclip 함수 ]
-- =============================================
local BarrierCanCollideT = false

local function BarrierCanCollideF()
    if BarrierCanCollideT then
        for i = 1, 5 do
            local plot = Plots:FindFirstChild("Plot"..i)
            if plot and plot:FindFirstChild("Barrier") then
                for _, barrier in ipairs(plot.Barrier:GetChildren()) do
                    if barrier:IsA("BasePart") then
                        barrier.CanCollide = false
                    end
                end
            end
        end
    else
        for i = 1, 5 do
            local plot = Plots:FindFirstChild("Plot"..i)
            if plot and plot:FindFirstChild("Barrier") then
                for _, barrier in ipairs(plot.Barrier:GetChildren()) do
                    if barrier:IsA("BasePart") then
                        barrier.CanCollide = true
                    end
                end
            end
        end
    end
end

-- =============================================
-- [ Plot Barrier Delete 함수 ]
-- =============================================
local PBDrun = false

local function PlotBarrierDelete()
    if PBDrun then 
        Rayfield:Notify({Title = "베리어", Content = "이미 실행 중", Duration = 2})
        return 
    end
    PBDrun = true

    local char = plr.Character
    if not char then 
        PBDrun = false 
        Rayfield:Notify({Title = "오류", Content = "캐릭터 없음", Duration = 2})
        return 
    end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then 
        PBDrun = false 
        Rayfield:Notify({Title = "오류", Content = "HumanoidRootPart 없음", Duration = 2})
        return 
    end

    local metal = nil
    local plot1 = Workspace:FindFirstChild("Plots") and Workspace.Plots:FindFirstChild("Plot1")
    if plot1 then
        local teslaCoil = plot1:FindFirstChild("TeslaCoil")
        if teslaCoil then
            metal = teslaCoil:FindFirstChild("Metal")
        end
    end

    if not metal then
        PBDrun = false
        Rayfield:Notify({Title = "오류", Content = "Metal 파트를 찾을 수 없음", Duration = 2})
        return
    end

    local TP = metal.CFrame
    local OCF = hrp.CFrame

    task.spawn(function()
        if SpawnToyRemote then
            pcall(function()
                SpawnToyRemote:InvokeServer("FoodBread", hrp.CFrame, Vector3.new(0,0,0))
            end)
        end
    end)

    task.wait(0.2)

    local foodBread = inv and inv:FindFirstChild("FoodBread")
    if not foodBread then 
        PBDrun = false 
        Rayfield:Notify({Title = "오류", Content = "빵 생성 실패", Duration = 2})
        return 
    end

    if foodBread then
        task.spawn(function()
            local holdPart = foodBread:FindFirstChild("HoldPart")
            if holdPart then
                local holdRemote = holdPart:FindFirstChild("HoldItemRemoteFunction")
                if holdRemote then
                    pcall(function()
                        holdRemote:InvokeServer(foodBread, char)
                    end)
                end
            end
        end)
    end

    task.wait(0.1)
    hrp.CFrame = TP
    task.wait(0.17)

    if foodBread and DestroyToy then
        pcall(function()
            DestroyToy:FireServer(foodBread)
        end)
    end

    hrp.CFrame = OCF
    task.wait(0.4)

    PBDrun = false
    Rayfield:Notify({Title = "✅ 베리어", Content = "부수기 완료", Duration = 2})
end

-- =============================================
-- [ 수동 킬 함수 ]
-- =============================================
local targetList = {}

local function manualKill(mode)
    local char = plr.Character
    if not char then 
        Rayfield:Notify({Title = "오류", Content = "캐릭터 없음", Duration = 2})
        return 
    end
    
    local count = 0
    for _, targetName in ipairs(targetList) do
        local target = Players:FindFirstChild(targetName)
        if target and target.Character then
            local torso = target.Character:FindFirstChild("Torso") or target.Character:FindFirstChild("HumanoidRootPart")
            if torso then
                pcall(function() SetNetworkOwner:FireServer(torso, torso.CFrame) end)
                
                if mode == "kill" then
                    local FallenY = Workspace.FallenPartsDestroyHeight
                    local targetY = (FallenY <= -50000 and -49999) or (FallenY <= -100 and -99) or -100
                    pcall(function() torso.CFrame = CFrame.new(99999, targetY, 99999) end)
                else
                    pcall(function() torso.CFrame = CFrame.new(99999, 99999, 99999) end)
                end
                count = count + 1
            end
        end
        task.wait(0.1)
    end
    
    Rayfield:Notify({Title = mode == "kill" and "Kill" or "Kick", Content = count .. "명 처리", Duration = 2})
end

-- =============================================
-- [ 즉시 해제 함수 ]
-- =============================================
local function ManualRelease()
    local char = plr.Character
    if not char then 
        Rayfield:Notify({Title = "오류", Content = "캐릭터 없음", Duration = 2})
        return 
    end
    
    if DestroyGrabLine then
        local grabParts = Workspace:FindFirstChild("GrabParts")
        if grabParts then
            for _, part in ipairs(grabParts:GetChildren()) do
                if part.Name == "GrabPart" then
                    local weld = part:FindFirstChildOfClass("WeldConstraint")
                    if weld and weld.Part1 and weld.Part1:IsDescendantOf(char) then
                        pcall(function() DestroyGrabLine:FireServer(weld.Part1) end)
                    end
                end
            end
        end
    end
    
    if SetNetworkOwner then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if hrp then pcall(function() SetNetworkOwner:FireServer(hrp) end) end
    end
    
    if Struggle then pcall(function() Struggle:FireServer() end) end
    
    Rayfield:Notify({Title = "해제 완료", Duration = 2})
end

-- =============================================
-- [ Auto-Gucci 함수 ]
-- =============================================
local function ragdollLoopF()
    if ragdollLoopD then return end
    ragdollLoopD = true

    while sitJumpT do
        local char = plr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if char and hrp and RagdollRemote then
            RagdollRemote:FireServer(hrp, 0)
        end
        task.wait()
    end
    ragdollLoopD = false
end

local function sitJumpF()
    local char = plr.Character
    local hum = char and char:FindFirstChild("Humanoid")
    if not char or not hum then return end
    local seat = blobmanInstanceS and blobmanInstanceS:FindFirstChildWhichIsA("VehicleSeat")
    if seat and seat.Occupant ~= hum then
        seat:Sit(hum)
        AutoGucciT = false
        sitJumpT = false
    end
end

local function AutoGucciF()
    while AutoGucciT do
        local success = pcall(function()
            spawnBlobmanF()

            local char = plr.Character
            if not char then
                task.wait(0.1)
                return 
            end

            local hrp = char:WaitForChild("HumanoidRootPart")
            local hum = char:WaitForChild("Humanoid")
            local rag = hum:WaitForChild("Ragdolled")
            local held = plr:WaitForChild("IsHeld")

            if not hrp then return end
            local OCF = hrp.CFrame

            if not sitJumpT then
                task.spawn(sitJumpF)
                sitJumpT = true
            end

            task.spawn(ragdollLoopF)
            task.wait(0.3)
            hrp.CFrame = OCF

            local successCheck = true
            sitJumpT = false
            if RagdollRemote then RagdollRemote:FireServer(hrp, 0.001) end

            while successCheck and AutoGucciT do
                if hum.Health <= 0 then
                    if blobmanInstanceS and DestroyToy then
                        DestroyToy:FireServer(blobmanInstanceS)
                    end
                    successCheck = false
                    break
                end

                local seat = blobmanInstanceS and blobmanInstanceS:FindFirstChildWhichIsA("VehicleSeat")
                if seat and seat.Occupant ~= nil then
                    if DestroyToy then DestroyToy:FireServer(blobmanInstanceS) end
                    successCheck = false
                    break
                end

                if rag.Value == true or held.Value == true then
                    while (rag.Value == true or held.Value == true) and AutoGucciT do
                        if Struggle then Struggle:FireServer() end
                        task.wait()
                    end
                    successCheck = false
                    break
                end

                local blobHRP = blobmanInstanceS and blobmanInstanceS:FindFirstChild("HumanoidRootPart")
                if blobHRP then
                    pcall(function() SetNetworkOwner:FireServer(blobHRP, hrp) end)
                    blobHRP.CFrame = CFrame.new(0, 9999, 0)
                end

                task.wait()
            end

            if not successCheck then
                local blobHRP = blobmanInstanceS and blobmanInstanceS:FindFirstChild("HumanoidRootPart")
                Rayfield:Notify({Title = "Gucci", Content = "재시도 대기 중...", Duration = 1})
                if hum then
                    if Struggle then Struggle:FireServer(plr) end
                    hum.Sit = true
                    task.wait(0.1)
                    hum.Sit = false
                    if blobHRP and blobHRP.Position.Y > 9000 and DestroyToy then 
                        DestroyToy:FireServer(blobmanInstanceS) 
                    end
                end
                sitJumpT = false
                task.wait(1)
            end
        end)
        task.wait()
    end
end

-- =============================================
-- [ 킥 알림 함수 ]
-- =============================================
local anchoredCache = {}
local kickNotificationsEnabled = true

local function setupKickNotifications()
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function(char)
            local hrp = char:WaitForChild("HumanoidRootPart", 1)
            if hrp then
                anchoredCache[player] = false
            end
        end)
    end)

    Players.PlayerRemoving:Connect(function(player)
        if anchoredCache[player] == true and kickNotificationsEnabled then
            Rayfield:Notify({
                Title = "👢 Kick 감지",
                Content = string.format("%s (@%s) 님이 킥당했습니다", player.DisplayName, player.Name),
                Duration = 5
            })
        end
        anchoredCache[player] = nil
    end)

    task.spawn(function()
        while kickNotificationsEnabled do
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= plr then
                    local char = player.Character
                    if char then
                        local hrp = char:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            anchoredCache[player] = hrp.Anchored == true
                        end
                    end
                end
            end
            task.wait()
        end
    end)
end

-- =============================================
-- [ 블롭 알림 함수 ]
-- =============================================
local blobNotificationsEnabled = true
local notifyCooldowns = {}
local AntiBlobConnection = nil

local function CheckBlob(blob, myHRP, myAttach, source)
    local script = blob:FindFirstChild("BlobmanSeatAndOwnerScript")
    if not script then return end

    for _, side in ipairs({"Left", "Right"}) do
        local detector = blob:FindFirstChild(side .. "Detector")
        if not detector then continue end

        local weld = detector:FindFirstChild(side .. "Weld")
        if weld and weld:IsA("AlignPosition") and weld.Attachment0 == myAttach then
            local msg = source .. " → " .. side .. " Grab"
            local now = tick()

            if not notifyCooldowns[msg] or (now - notifyCooldowns[msg]) >= 2 then
                notifyCooldowns[msg] = now
                Rayfield:Notify({
                    Title = "🦠 블롭 감지",
                    Content = msg,
                    Duration = 3
                })
            end

            if Struggle then
                pcall(function() Struggle:FireServer() end)
            end
            if RagdollRemote and myHRP then
                pcall(function() RagdollRemote:FireServer(myHRP, 0) end)
            end
        end
    end
end

local function setupBlobNotifications()
    if AntiBlobConnection then 
        AntiBlobConnection:Disconnect() 
        AntiBlobConnection = nil
    end

    AntiBlobConnection = RunService.Stepped:Connect(function()
        if not blobNotificationsEnabled then 
            if AntiBlobConnection then 
                AntiBlobConnection:Disconnect() 
                AntiBlobConnection = nil
            end
            return 
        end

        local myChar = plr.Character
        if not myChar then return end
        local myHRP = myChar:FindFirstChild("HumanoidRootPart")
        local myAttach = myHRP and myHRP:FindFirstChild("RootAttachment")

        if not (myHRP and myAttach) then return end

        if inv then
            for _, blob in ipairs(inv:GetChildren()) do
                if blob.Name == "CreatureBlobman" then
                    local occupantName = "{me}"
                    local vehicleSeat = blob:FindFirstChild("VehicleSeat")
                    if vehicleSeat and vehicleSeat.Occupant then
                        local character = vehicleSeat.Occupant.Parent
                        if character then
                            local player = Players:GetPlayerFromCharacter(character)
                            if player then occupantName = player.Name end
                        end
                    end
                    CheckBlob(blob, myHRP, myAttach, occupantName)
                end
            end
        end

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= plr then
                local invs = Workspace:FindFirstChild(player.Name .. "SpawnedInToys")
                if invs then
                    for _, blob in ipairs(invs:GetChildren()) do
                        if blob.Name == "CreatureBlobman" then
                            local occupantName = player.Name
                            local vehicleSeat = blob:FindFirstChild("VehicleSeat")
                            if vehicleSeat and vehicleSeat.Occupant then
                                local character = vehicleSeat.Occupant.Parent
                                if character then
                                    local occupantPlayer = Players:GetPlayerFromCharacter(character)
                                    if occupantPlayer then occupantName = occupantPlayer.Name end
                                end
                            end
                            CheckBlob(blob, myHRP, myAttach, occupantName)
                        end
                    end
                end
            end
        end

        local plots = Workspace:FindFirstChild("PlotItems")
        if plots then
            for i = 1, 5 do
                local plot = plots:FindFirstChild("Plot" .. i)
                if plot then
                    for _, blob in ipairs(plot:GetChildren()) do
                        if blob.Name == "CreatureBlobman" then
                            local occupantName = "Plot " .. i
                            local vehicleSeat = blob:FindFirstChild("VehicleSeat")
                            if vehicleSeat and vehicleSeat.Occupant then
                                local character = vehicleSeat.Occupant.Parent
                                if character then
                                    local player = Players:GetPlayerFromCharacter(character)
                                    if player then occupantName = player.Name end
                                end
                            end
                            CheckBlob(blob, myHRP, myAttach, occupantName)
                        end
                    end
                end
            end
        end
    end)
end

-- =============================================
-- [ 탭 생성 ]
-- =============================================
local MainTab = Window:CreateTab("메인", 4483362458)
local BlobTab = Window:CreateTab("블롭", 4483362458)
local GrabTab = Window:CreateTab("그랩", 4483362458)
local SecurityTab = Window:CreateTab("보안", 4483362458)
local AuraTab = Window:CreateTab("아우라", 4483362458)
local TargetTab = Window:CreateTab("킬 플레이어 정하기", 4483362458)
local NotifyTab = Window:CreateTab("🔔 알림", 4483362458)
local KickGrabTab = Window:CreateTab("👢 킥그랩", 4483362458)
-- 🔽 여기에 루프그랩 탭 추가!
local LoopGrabTab = Window:CreateTab("🔄 루프그랩", 4483362458)
local KillGrabTab = Window:CreateTab("💀 킬그랩", 4483362458)
local HouseTeleportTap = Window:CreateTab("🏠 집 텔레포트", 4483362458)
local SettingsTab = Window:CreateTab("설정", 4483362458)

-- =============================================
-- [ 메인 탭 - 안티 그랩 (pcall 추가) ]
-- =============================================
MainTab:CreateSection("🛡️ 기본 방어")

-- 안티 그랩 토글
local AntiGrabToggle = MainTab:CreateToggle({
    Name = "⚡ 안티 그랩",
    CurrentValue = false,
    Flag = "AntiGrabMainToggle",
    Callback = function(Value)
        -- pcall로 감싸서 에러 방지
        local success, err = pcall(function()
            isAntiGrabEnabled = Value
            if Value then
                AntiGrabF(Value)
            else
                if antiGrabConn then
                    antiGrabConn:Disconnect()
                    antiGrabConn = nil
                end
            end
        end)
        
        if not success then
            print("⚠️ 안티 그랩 에러:", err)
            Rayfield:Notify({
                Title = "⚠️ 오류",
                Content = "안티 그랩 기능 오류",
                Duration = 2
            })
        end
    end
})

-- 쓰지마세요 버튼
MainTab:CreateButton({
    Name = "🔓 쓰지마세요",
    Flag = "ManualReleaseButton",
    Callback = function()
        pcall(function()
            ManualRelease()
        end)
    end
})

-- PCLD 보기 토글
local PcldViewToggle = MainTab:CreateToggle({
    Name = "👁️ PCLD 보기",
    CurrentValue = false,
    Flag = "PcldViewToggle",
    Callback = function(Value)
        pcall(function()
            pcldViewEnabled = Value
            togglePcldView(Value)
        end)
    end
})

-- 베리어 노클립 토글
local BarrierNoclipToggle = MainTab:CreateToggle({
    Name = "🧱 베리어 노클립",
    CurrentValue = false,
    Flag = "BarrierNoclipToggle",
    Callback = function(Value)
        pcall(function()
            BarrierCanCollideT = Value
            BarrierCanCollideF()
        end)
    end
})

-- 집 베리어 부수기 버튼
MainTab:CreateButton({
    Name = "💥 집 베리어 부수기",
    Flag = "PlotBarrierDeleteButton",
    Callback = function()
        pcall(function()
            PlotBarrierDelete()
        end)
    end
})

-- 안티 킥 토글
local AntiPCLDToggle = MainTab:CreateToggle({
    Name = "🛡️ 안티 킥",
    CurrentValue = false,
    Flag = "AntiPCLDToggle",
    Callback = function(Value)
        pcall(function()
            AntiPCLDEnabled = Value
            if Value then
                setupAntiPCLD()
                Rayfield:Notify({Title = "안티킥", Content = "활성화", Duration = 2})
            else
                Rayfield:Notify({Title = "안티킥", Content = "비활성화", Duration = 2})
            end
        end)
    end
})

-- =============================================
-- [ 블롭 탭 ]
-- =============================================
BlobTab:CreateSection("🦠 블롭 공격 대상")

local BlobTargetDropdown = BlobTab:CreateDropdown({
    Name = "리스트",
    Options = playersInLoop1V,
    CurrentOption = {"열기"},
    MultipleOptions = true,
    Flag = "BlobTargetDropdown",
    Callback = function(Options)
        playersInLoop1V = Options
    end
})

BlobTab:CreateInput({
    Name = "추가",
    PlaceholderText = "닉네임 입력",
    RemoveTextAfterFocusLost = true,
    Callback = function(Value)
        if not Value or Value == "" then return end
        
        local target = findPlayerByPartialName(Value)
        if not target then
            Rayfield:Notify({Title = "블롭", Content = "플레이어를 찾을 수 없음", Duration = 2})
            return
        end
        
        for _, name in ipairs(playersInLoop1V) do
            if name == target.Name then
                Rayfield:Notify({Title = "블롭", Content = "이미 목록에 있음", Duration = 2})
                return
            end
        end
        
        table.insert(playersInLoop1V, target.Name)
        BlobTargetDropdown:Refresh(playersInLoop1V, true)
        Rayfield:Notify({Title = "블롭", Content = "추가: " .. target.Name, Duration = 2})
    end
})

BlobTab:CreateInput({
    Name = "Remove",
    PlaceholderText = "닉네임 입력",
    RemoveTextAfterFocusLost = true,
    Callback = function(Value)
        if not Value or Value == "" then return end
        
        for i, name in ipairs(playersInLoop1V) do
            if name:lower() == Value:lower() then
                table.remove(playersInLoop1V, i)
                BlobTargetDropdown:Refresh(playersInLoop1V, true)
                Rayfield:Notify({Title = "블롭", Content = "제거: " .. name, Duration = 2})
                return
            end
        end
        Rayfield:Notify({Title = "블롭", Content = "없는 이름", Duration = 2})
    end
})

BlobTab:CreateSection("🦠 블롭 컨트롤")

BlobTab:CreateButton({
    Name = "🪑 블롭 앉기",
    Callback = function()
        local char = plr.Character
        if not char then return end
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if not humanoid then return end
        
        local myBlob = inv and inv:FindFirstChild("CreatureBlobman")
        if myBlob then
            local seat = myBlob:FindFirstChildOfClass("VehicleSeat")
            if seat and seat.Occupant == nil then
                seat:Sit(humanoid)
                Rayfield:Notify({Title = "블롭", Content = "앉기 성공", Duration = 2})
            end
        else
            spawnBlobmanF()
            task.wait(0.5)
            local newBlob = inv and inv:FindFirstChild("CreatureBlobman")
            if newBlob then
                local seat = newBlob:FindFirstChildOfClass("VehicleSeat")
                if seat then
                    seat:Sit(humanoid)
                    Rayfield:Notify({Title = "블롭", Content = "생성 후 앉기", Duration = 2})
                end
            end
        end
    end
})

BlobTab:CreateButton({
    Name = "🔄 블롭 생성",
    Callback = function()
        spawnBlobmanF()
        Rayfield:Notify({Title = "블롭", Content = "생성 시도", Duration = 2})
    end
})

BlobTab:CreateButton({
    Name = "🗑️ 블롭 제거",
    Callback = function()
        if blobmanInstanceS and DestroyToy then
            DestroyToy:FireServer(blobmanInstanceS)
            blobmanInstanceS = nil
            Rayfield:Notify({Title = "블롭", Content = "제거됨", Duration = 2})
        end
    end
})

BlobTab:CreateSection("⚔️ 블롭 공격 (List 대상)")

BlobTab:CreateButton({
    Name = "💀 블롭 킬",
    Callback = function() BlobAttackAll("kill") end
})

BlobTab:CreateButton({
    Name = "⚡ 블롭 매스리스",
    Callback = function() BlobAttackAll("massless") end
})

BlobTab:CreateButton({
    Name = "🤚 블롭 잡기",
    Callback = function() BlobAttackAll("grab") end
})

BlobTab:CreateButton({
    Name = "✋ 블롭 놓기",
    Callback = function() BlobAttackAll("release") end
})

BlobTab:CreateButton({
    Name = "⬇️ 블롭 드롭",
    Callback = function() BlobAttackAll("drop") end
})

BlobTab:CreateSection("🔄 블롭 자동 루프")

BlobTab:CreateToggle({
    Name = "🔄 루프 킬",
    CurrentValue = false,
    Callback = function(Value)
        blobLoopT3 = Value
        if Value then
            if #playersInLoop1V == 0 then
                Rayfield:Notify({Title = "오류", Content = "리스트가 비어있음", Duration = 2})
                blobLoopT3 = false
                return
            end
            rawBlobLoopKill()
            Rayfield:Notify({Title = "블롭 킬", Content = "루프 시작", Duration = 2})
        else
            if blobKillThread then
                task.cancel(blobKillThread)
                blobKillThread = nil
            end
            Rayfield:Notify({Title = "블롭 킬", Content = "루프 종료", Duration = 2})
        end
    end
})

BlobTab:CreateToggle({
    Name = "🔄 루프 킥",
    CurrentValue = false,
    Callback = function(Value)
        blobLoopT = Value
        if Value then
            if #playersInLoop1V == 0 then
                Rayfield:Notify({Title = "오류", Content = "리스트가 비어있음", Duration = 2})
                blobLoopT = false
                return
            end
            rawBlobLoopKick()
            Rayfield:Notify({Title = "블롭 킥", Content = "루프 시작", Duration = 2})
        else
            if blobKickThread then
                task.cancel(blobKickThread)
                blobKickThread = nil
            end
            Rayfield:Notify({Title = "블롭 킥", Content = "루프 종료", Duration = 2})
        end
    end
})

BlobTab:CreateSection("✨ 구찌 설정")

local AutoGucciToggle = BlobTab:CreateToggle({
    Name = "오토 구찌",
    CurrentValue = false,
    Callback = function(Value)
        AutoGucciT = Value
        if AutoGucciT then
            task.spawn(AutoGucciF)
            Rayfield:Notify({Title = "Gucci", Content = "활성화", Duration = 2})
        else
            if plr.Character and plr.Character:FindFirstChild("Humanoid") then
                plr.Character.Humanoid.Sit = true
                task.wait(0.1)
                plr.Character.Humanoid.Sit = false
            end
            sitJumpT = false
            if blobmanInstanceS and DestroyToy then
                DestroyToy:FireServer(blobmanInstanceS)
                blobmanInstanceS = nil
            end
        end
    end
})

-- =============================================
-- [ 그랩 탭 ]
-- =============================================
GrabTab:CreateSection("🔄 그랩 공격")

local LoopGrabToggle = GrabTab:CreateToggle({
    Name = "🔄 쓰지마세요",
    CurrentValue = false,
    Callback = function(Value)
        AntiStruggleGrabT = Value
        AntiStruggleGrabF()
        Rayfield:Notify({Title = "Loop Grab", Content = Value and "활성화" or "비활성화", Duration = 2})
    end
})

-- =============================================
-- [ 아우라 탭 ]
-- =============================================
AuraTab:CreateSection("🌀 안티 스티키 아우라")

local AntiStickyAuraToggle = AuraTab:CreateToggle({
    Name = "안티 스티키 아우라",
    CurrentValue = false,
    Callback = function(Value)
        AntiStickyAuraT = Value
        AntiStickyAuraF()
        Rayfield:Notify({Title = "안티 스티키", Content = Value and "활성화" or "비활성화", Duration = 2})
    end
})

AuraTab:CreateParagraph({
    Title = "설명",
    Content = "주변 30스터드 내의 스티키 파트 오너쉽 자동 획득"
})

-- =============================================
-- [ 보안 탭 ]
-- =============================================
SecurityTab:CreateSection("🔰 방어 설정")

local AntiVoidToggle = SecurityTab:CreateToggle({
    Name = "안티 보이드",
    CurrentValue = true,
    Callback = function(Value)
        if Value then
            Workspace.FallenPartsDestroyHeight = -500000000
        else
            Workspace.FallenPartsDestroyHeight = -100
        end
    end
})
AntiVoidToggle:Set(true)

local AntiMasslessToggle = SecurityTab:CreateToggle({
    Name = "⚖️ 안티 마스리스",
    CurrentValue = false,
    Callback = function(Value)
        antiMasslessEnabled = Value
        AntiMasslessF()
        Rayfield:Notify({Title = "안티 마스리스", Content = Value and "활성화" or "비활성화", Duration = 2})
    end
})

local AntiBurnToggle = SecurityTab:CreateToggle({
    Name = "🔥 안티 불",
    CurrentValue = false,
    Callback = function(Value)
        AntiBurnV = Value
        if Value then
            AntiBurn()
            Rayfield:Notify({Title = "안티 불", Content = "활성화", Duration = 2})
        end
    end
})

local AntiExplodeToggle = SecurityTab:CreateToggle({
    Name = "💥 안티 폭발",
    CurrentValue = false,
    Callback = function(Value)
        AntiExplosionT = Value
        if Value then
            AntiExplosionF()
            Rayfield:Notify({Title = "안티 폭발", Content = "활성화", Duration = 2})
        else
            if AntiExplosionC then
                AntiExplosionC:Disconnect()
                AntiExplosionC = nil
            end
            Rayfield:Notify({Title = "안티 폭발", Content = "비활성화", Duration = 2})
        end
    end
})

local AntiPaintToggle = SecurityTab:CreateToggle({
    Name = "🎨 안티 페인트",
    CurrentValue = false,
    Callback = function(Value)
        AntiPaintT = Value
        if Value then
            AntiPaintF()
            Rayfield:Notify({Title = "안티 페인트", Content = "활성화", Duration = 2})
        else
            if AntiPaintThread then
                task.cancel(AntiPaintThread)
                AntiPaintThread = nil
            end
        end
    end
})

-- =============================================
-- [ 킥그랩 탭 (완전판) ]
-- =============================================
KickGrabTab:CreateSection("🎯 킥그랩 대상 리스트")

-- 드롭다운
local KickGrabTargetDropdown = KickGrabTab:CreateDropdown({
    Name = "킥 그랩 리스트",
    Options = kickGrabTargetList,
    CurrentOption = {"열기"},
    MultipleOptions = true,
    Flag = "KickGrabMainDropdown",
    Callback = function(Options)
        kickGrabTargetList = Options
    end
})

-- Add 버튼
KickGrabTab:CreateInput({
    Name = "Add",
    PlaceholderText = "닉네임 입력",
    RemoveTextAfterFocusLost = true,
    Flag = "KickGrabAddInput",
    Callback = function(Value)
        if not Value or Value == "" then return end
        
        local target = findPlayerByPartialName(Value)
        if not target then
            Rayfield:Notify({Title = "킥그랩", Content = "플레이어를 찾을 수 없음", Duration = 2})
            return
        end
        
        for _, name in ipairs(kickGrabTargetList) do
            if name == target.Name then
                Rayfield:Notify({Title = "킥그랩", Content = "이미 리스트에 있음", Duration = 2})
                return
            end
        end
        
        table.insert(kickGrabTargetList, target.Name)
        pcall(function() KickGrabTargetDropdown:Refresh(kickGrabTargetList, true) end)
        Rayfield:Notify({Title = "킥그랩", Content = "추가: " .. target.Name, Duration = 2})
    end
})

-- Remove 버튼
KickGrabTab:CreateInput({
    Name = "Remove",
    PlaceholderText = "닉네임 입력",
    RemoveTextAfterFocusLost = true,
    Flag = "KickGrabRemoveInput",
    Callback = function(Value)
        if not Value or Value == "" then return end
        
        for i, name in ipairs(kickGrabTargetList) do
            if name:lower() == Value:lower() then
                table.remove(kickGrabTargetList, i)
                pcall(function() KickGrabTargetDropdown:Refresh(kickGrabTargetList, true) end)
                Rayfield:Notify({Title = "킥그랩", Content = "제거: " .. name, Duration = 2})
                return
            end
        end
        Rayfield:Notify({Title = "킥그랩", Content = "리스트에 없는 이름", Duration = 2})
    end
})

-- 리스트 비우기 버튼
KickGrabTab:CreateButton({
    Name = "🗑️ 리스트 비우기",
    Callback = function()
        kickGrabTargetList = {}
        pcall(function() KickGrabTargetDropdown:Refresh(kickGrabTargetList, true) end)
        Rayfield:Notify({Title = "킥그랩", Content = "리스트 비움", Duration = 2})
    end
})

KickGrabTab:CreateSection("⚙️ 모드 설정")

local ModeDropdown = KickGrabTab:CreateDropdown({
    Name = "모드 선택",
    Options = {"카메라", "위", "아래"},
    CurrentOption = {"카메라"},
    MultipleOptions = false,
    Callback = function(Options)
        KickGrabState.Mode = Options[1]
        Rayfield:Notify({Title = "킥그랩", Content = "모드: " .. Options[1], Duration = 2})
    end
})

local DistInput = KickGrabTab:CreateInput({
    Name = "카메라 거리",
    CurrentValue = "19",
    PlaceholderText = "거리",
    RemoveTextAfterFocusLost = false,
    Callback = function(Value)
        local num = tonumber(Value)
        if num then
            KickGrabState.DetentionDist = num
        end
    end
})

KickGrabTab:CreateSection("🎮 실행")

local KickGrabToggle = KickGrabTab:CreateToggle({
    Name = "👢 킥 그랩",
    CurrentValue = false,
    Callback = function(Value)
        if Value and #kickGrabTargetList == 0 then
            Rayfield:Notify({Title = "오류", Content = "대상 리스트가 비어있습니다", Duration = 2})
            KickGrabToggle:Set(false)
            return
        end
        KickGrabState.Looping = Value
        if Value then
            task.spawn(ExecuteKickGrabLoop)
            Rayfield:Notify({Title = "킥그랩", Content = "활성화", Duration = 2})
        else
            Rayfield:Notify({Title = "킥그랩", Content = "비활성화", Duration = 2})
        end
    end
})

local AutoRagdollToggle = KickGrabTab:CreateToggle({
    Name = "🔄 오토 레그돌",
    CurrentValue = false,
    Callback = function(Value)
        KickGrabState.AutoRagdoll = Value
        Rayfield:Notify({Title = "오토 래그돌", Content = Value and "활성화" or "비활성화", Duration = 2})
    end
})

local SnowBallToggle = KickGrabTab:CreateToggle({
    Name = "❄️ 스노우볼",
    CurrentValue = false,
    Callback = function(Value)
        if Value and #kickGrabTargetList == 0 then
            Rayfield:Notify({Title = "오류", Content = "대상 리스트가 비어있습니다", Duration = 2})
            SnowBallToggle:Set(false)
            return
        end
        KickGrabState.SnowBallLooping = Value
        if Value then
            task.spawn(ExecuteSnowballLoop)
            Rayfield:Notify({Title = "스노우볼", Content = "활성화", Duration = 2})
        else
            Rayfield:Notify({Title = "스노우볼", Content = "비활성화", Duration = 2})
        end
    end
})

-- =============================================
-- [ 루프그랩 탭 ]
-- =============================================
LoopGrabTab:CreateSection("🎮 제어")

local LoopToggleButton = LoopGrabTab:CreateToggle({
    Name = "🔄 루프그랩 실행",
    CurrentValue = false,
    Callback = function(Value)
        if Value then
            local target = getGrabbedTarget()
            if target then
                startLoopGrab(target)
                Rayfield:Notify({
                    Title = "🔄 루프그랩",
                    Content = target.Name .. " 시작",
                    Duration = 2
                })
            else
                Rayfield:Notify({
                    Title = "❌ 오류",
                    Content = "잡은 상대 없음",
                    Duration = 2
                })
                LoopToggleButton:Set(false)
            end
        else
            stopLoopGrab()
        end
    end
})

LoopGrabTab:CreateButton({
    Name = "⏹️ 강제 중지",
    Callback = function()
        stopLoopGrab()
        LoopToggleButton:Set(false)
    end
})

LoopGrabTab:CreateSection("📊 상태")

local LoopStatusLabel = LoopGrabTab:CreateLabel("대기 중...", 4483362458)
local LoopTargetLabel = LoopGrabTab:CreateLabel("현재 대상: 없음", 4483362458)
local LoopCountLabel = LoopGrabTab:CreateLabel("SetOwner: 0회", 4483362458)

spawn(function()
    while task.wait(0.2) do
        if LoopGrabActive and LoopGrabTarget then
            LoopStatusLabel:Set("🟢 실행 중")
            LoopTargetLabel:Set("대상: " .. LoopGrabTarget.Name)
        else
            LoopStatusLabel:Set("⚫ 대기 중")
            LoopTargetLabel:Set("대상: 없음")
        end
        LoopCountLabel:Set(string.format("SetOwner: %d회", LoopSetOwnerCount))
    end
end)

LoopGrabTab:CreateSection("📝 설명")
LoopGrabTab:CreateParagraph({
    Title = "사용법",
    Content = "1. 상대를 그랩으로 잡고\n2. 토글 ON 하면 자동 시작\n3. OFF 하면 중지"
})

-- =============================================
-- [ 킬그랩 탭 ]
-- =============================================
KillGrabTab:CreateSection("⚔️ 킬그랩 설정")

KillGrabTab:CreateToggle({
    Name = "🔪 킬그랩 활성화",
    CurrentValue = false,
    Callback = function(Value)
        KillGrabEnabled = Value
        KillGrabF()
        Rayfield:Notify({
            Title = "킬그랩",
            Content = Value and "활성화 (잡히면 즉시 킬)" or "비활성화",
            Duration = 2
        })
    end
})

KillGrabTab:CreateParagraph({
    Title = "설명",
    Content = "이 기능을 켜면 누군가 당신을 그랩했을 때\n그 사람이 즉시 죽습니다."
})

-- =============================================
-- [ 킬 플레이어 정하기 탭 ]
-- =============================================
TargetTab:CreateSection("🎯 킬 플레이어 정하기")

local TargetListDropdown = TargetTab:CreateDropdown({
    Name = "리스트",
    Options = targetList,
    CurrentOption = {"열기"},
    MultipleOptions = true,
    Callback = function(Options)
        targetList = Options
    end
})

TargetTab:CreateInput({
    Name = "추가",
    PlaceholderText = "닉네임 입력",
    RemoveTextAfterFocusLost = true,
    Callback = function(Value)
        if not Value or Value == "" then return end
        
        local target = findPlayerByPartialName(Value)
        if not target then
            Rayfield:Notify({Title = "대상", Content = "플레이어를 찾을 수 없음", Duration = 2})
            return
        end
        
        for _, name in ipairs(targetList) do
            if name == target.Name then
                Rayfield:Notify({Title = "대상", Content = "이미 목록에 있음", Duration = 2})
                return
            end
        end
        
        table.insert(targetList, target.Name)
        TargetListDropdown:Refresh(targetList, true)
        Rayfield:Notify({Title = "대상", Content = "추가: " .. target.Name, Duration = 2})
    end
})

TargetTab:CreateInput({
    Name = "Remove",
    PlaceholderText = "닉네임 입력",
    RemoveTextAfterFocusLost = true,
    Callback = function(Value)
        if not Value or Value == "" then return end
        
        for i, name in ipairs(targetList) do
            if name:lower() == Value:lower() then
                table.remove(targetList, i)
                TargetListDropdown:Refresh(targetList, true)
                Rayfield:Notify({Title = "대상", Content = "제거: " .. name, Duration = 2})
                return
            end
        end
        Rayfield:Notify({Title = "대상", Content = "없는 이름", Duration = 2})
    end
})

TargetTab:CreateSection("⚔️ 실행")

TargetTab:CreateButton({
    Name = "💀 킬",
    Callback = function() manualKill("kill") end
})

TargetTab:CreateButton({
    Name = "👢 킥",
    Callback = function() manualKill("kick") end
})

local DeletePartDropdown = TargetTab:CreateDropdown({
    Name = "🦴 제거할 부위",
    Options = {"팔/다리", "모든 다리", "모든 팔"},
    CurrentOption = {"팔/다리"},
    Callback = function(Options)
        selectedDeletePart = Options[1]
    end
})

TargetTab:CreateButton({
    Name = "🦴 대상 팔다리 제거",
    Callback = function()
        local count = 0
        for _, targetName in ipairs(targetList) do
            local target = Players:FindFirstChild(targetName)
            if target then
                teleportParts(target, selectedDeletePart)
                count = count + 1
            end
            task.wait(0.2)
        end
        Rayfield:Notify({Title = "팔다리 제거", Content = count .. "명 처리", Duration = 3})
    end
})

TargetTab:CreateButton({
    Name = "🎯 현재 그랩 대상 제거",
    Callback = function()
        local beamPart = Workspace:FindFirstChild("GrabParts") and Workspace.GrabParts:FindFirstChild("BeamPart")
        if beamPart then
            local targetPlayer = getClosestPlayer(beamPart)
            if targetPlayer then
                teleportParts(targetPlayer, selectedDeletePart)
                Rayfield:Notify({Title = "팔다리 제거", Content = targetPlayer.Name, Duration = 2})
            end
        end
    end
})

TargetTab:CreateSection("📋 선택된 플레이어")
local SelectedLabel = TargetTab:CreateLabel("선택됨: 0명", 4483362458)
spawn(function() while task.wait(0.5) do SelectedLabel:Set("선택됨: " .. #targetList .. "명") end end)

-- =============================================
-- [ 알림 탭 ]
-- =============================================
NotifyTab:CreateSection("🔔 알림 설정")

local KickNotifyToggle = NotifyTab:CreateToggle({
    Name = "👢 킥 알림",
    CurrentValue = true,
    Callback = function(Value)
        kickNotificationsEnabled = Value
    end
})
KickNotifyToggle:Set(true)

local BlobNotifyToggle = NotifyTab:CreateToggle({
    Name = "🦠 블롭 알림",
    CurrentValue = true,
    Callback = function(Value)
        blobNotificationsEnabled = Value
        if Value then
            setupBlobNotifications()
        else
            if AntiBlobConnection then
                AntiBlobConnection:Disconnect()
                AntiBlobConnection = nil
            end
        end
    end
})
BlobNotifyToggle:Set(true)

-- =============================================
-- [ 설정 탭 ]
-- =============================================
SettingsTab:CreateSection("⚙️ 설정")

SettingsTab:CreateToggle({
    Name = "인야숨기기",
    CurrentValue = true,
    Callback = function(Value)
        if _G and _G.ToggleUI then
            _G.ToggleUI = not Value
        end
    end
})

SettingsTab:CreateSection("⌨️ 단축키 안내")
SettingsTab:CreateParagraph({
    Title = "PC 단축키",
    Content = "Z 키: 시선 방향 텔레포트"
})

-- =============================================
-- [ TP 버튼 생성 ]
-- =============================================
createTPButton()

-- =============================================
-- [ 자동 실행 ]
-- =============================================
task.wait(1)
isAntiGrabEnabled = true
AntiGrabF(true)
AntiGrabToggle:Set(true)

setupKickNotifications()
setupBlobNotifications()

bringRayfieldToFront()

Rayfield:Notify({
    Title = "🚀 로드 완료",
    Content = "킬그랩 포함 (💀 킬그랩 탭)",
    Duration = 5
})

-- =============================================
-- [ 집 텔레포트 탭 UI (강제 로드) ]
-- =============================================
-- 탭이 존재하는지 확인
if HouseTeleportTab then
    -- 섹션 강제 생성
    local section1 = HouseTeleportTab:CreateSection("🏡 집 텔레포트")
    
    -- 집 목록
    local houses = {
        {"🔵 파란색 집", Vector3.new(502.693054, 83.3367615, -340.893524)},
        {"🟢 초록색 집", Vector3.new(-352, 98, 353)},
        {"🔴 빨간색 집", Vector3.new(551, 123, -73)},
        {"🟣 보라색 집", Vector3.new(249, -7, 461)},
        {"🌸 분홍색 집", Vector3.new(-484, -7, -165)},
        {"🏮 중국집", Vector3.new(513, 83, -341)},
    }
    
    -- 버튼 생성
    for i, house in ipairs(houses) do
        local btn = HouseTeleportTab:CreateButton({
            Name = house[1],
            Callback = function()
                local char = plr.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = CFrame.new(house[2])
                    Rayfield:Notify({
                        Title = "✅ 텔레포트",
                        Content = house[1],
                        Duration = 1
                    })
                end
            end
        })
        -- 버튼이 제대로 생성됐는지 확인
        if btn then
            print("✅ 버튼 생성됨:", house[1])
        end
    end
    
    -- 기타 장소 섹션
    local section2 = HouseTeleportTab:CreateSection("🗺️ 기타 장소")
    
    local otherPlaces = {
        {"⛰️ 스폰산", Vector3.new(494, 163, 175)},
        {"❄️ 설산", Vector3.new(-394, 230, 509)},
        {"🏡 헛간", Vector3.new(-156, 59, -291)},
        {"⚠️ 위험구역", Vector3.new(125, -7, 241)},
        {"☁️ 하늘섬", Vector3.new(63, 346, 309)},
        {"🕳️ 큰동굴", Vector3.new(-240, 29, 554)},
        {"🕳️ 작은동굴", Vector3.new(-84, 14, -310)},
        {"🚂 열차동굴", Vector3.new(602, 45, -175)},
        {"⛏️ 광산", Vector3.new(-308, -7, 506)},
        {"📍 스폰", Vector3.new(0, -7, 0)},
    }
    
    for i, place in ipairs(otherPlaces) do
        local btn = HouseTeleportTab:CreateButton({
            Name = place[1],
            Callback = function()
                local char = plr.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = CFrame.new(place[2])
                    Rayfield:Notify({
                        Title = "✅ 텔레포트",
                        Content = place[1],
                        Duration = 1
                    })
                end
            end
        })
    end
    
    -- 테스트 버튼
    local section3 = HouseTeleportTab:CreateSection("🧪 테스트")
    
    HouseTeleportTab:CreateButton({
        Name = "📍 현재 위치 출력",
        Callback = function()
            local char = plr.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local pos = char.HumanoidRootPart.Position
                Rayfield:Notify({
                    Title = "📌 현재 위치",
                    Content = string.format("X: %.1f, Y: %.1f, Z: %.1f", pos.X, pos.Y, pos.Z),
                    Duration = 3
                })
            end
        end
    })
    
    print("✅ 집 텔레포트 탭 로드 완료")
else
    print("❌ HouseTeleportTab이 없음!")
end
