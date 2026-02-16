-- FTAP 올인원 스크립트 (PC/모바일 호환) - 방어 기능 통합

-- =============================================
-- [ Rayfield UI 로드 (안정적인 버전) ]
-- =============================================
local RayfieldLoaded = false
local Rayfield

pcall(function()
    Rayfield = loadstring(game:HttpGet('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/main/source'))()
    if Rayfield then
        RayfieldLoaded = true
    end
end)

if not RayfieldLoaded then
    -- 백업 링크
    pcall(function()
        Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
        if Rayfield then
            RayfieldLoaded = true
        end
    end)
end

if not RayfieldLoaded then
    -- Rayfield 로드 실패 시 기본 알림
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "오류",
        Text = "Rayfield를 로드할 수 없습니다. 인터넷 연결을 확인하세요.",
        Duration = 5
    })
    return
end

-- =============================================
-- [ 서비스 로드 ]
-- =============================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local VirtualUser = game:GetService("VirtualUser")

-- 로컬 플레이어
local plr = Players.LocalPlayer
local rs = ReplicatedStorage

-- 인벤토리 찾기 (여러 경우의 수 처리)
local function getInv()
    local inv = Workspace:FindFirstChild(plr.Name.."SpawnedInToys")
    if not inv then
        inv = Workspace:FindFirstChild("SpawnedInToys")
    end
    return inv
end
local inv = getInv()

-- Plots 찾기
local Plots = Workspace:FindFirstChild("Plots")
if not Plots then
    Plots = Workspace:WaitForChild("Plots", 5)
end

-- PlotItems/PlayersInPlots 찾기
local PPs = nil
local plotItems = Workspace:FindFirstChild("PlotItems")
if plotItems then
    PPs = plotItems:FindFirstChild("PlayersInPlots")
end

-- =============================================
-- [ 리모트 이벤트 안전하게 찾기 ]
-- =============================================
local GrabEvents = rs:FindFirstChild("GrabEvents")
local CharacterEvents = rs:FindFirstChild("CharacterEvents")
local PlayerEvents = rs:FindFirstChild("PlayerEvents")
local MenuToys = rs:FindFirstChild("MenuToys")
local BombEvents = rs:FindFirstChild("BombEvents")

-- 각 리모트를 nil 체크와 함께 찾기
local SetNetworkOwner
local DestroyGrabLine
local CreateGrabLine
local ExtendGrabLine
local Struggle
local RagdollRemote
local SpawnToyRemote
local DestroyToy
local StickyPartEvent
local BombExplode

if GrabEvents then
    SetNetworkOwner = GrabEvents:FindFirstChild("SetNetworkOwner") or GrabEvents:FindFirstChild("SetOwner")
    DestroyGrabLine = GrabEvents:FindFirstChild("DestroyGrabLine") or GrabEvents:FindFirstChild("DestroyLine")
    CreateGrabLine = GrabEvents:FindFirstChild("CreateGrabLine") or GrabEvents:FindFirstChild("CreateGrab")
    ExtendGrabLine = GrabEvents:FindFirstChild("ExtendGrabLine") or GrabEvents:FindFirstChild("ExtendGrab")
end

if CharacterEvents then
    Struggle = CharacterEvents:FindFirstChild("Struggle") or CharacterEvents:FindFirstChild("StruggleRemote")
    RagdollRemote = CharacterEvents:FindFirstChild("RagdollRemote") or CharacterEvents:FindFirstChild("Ragdoll")
end

if MenuToys then
    SpawnToyRemote = MenuToys:FindFirstChild("SpawnToyRemoteFunction") or MenuToys:FindFirstChild("SpawnToy")
    DestroyToy = MenuToys:FindFirstChild("DestroyToy") or MenuToys:FindFirstChild("DestroyToyRemote")
end

if PlayerEvents then
    StickyPartEvent = PlayerEvents:FindFirstChild("StickyPartEvent") or PlayerEvents:FindFirstChild("StickyPart")
end

if BombEvents then
    BombExplode = BombEvents:FindFirstChild("BombExplode") or BombEvents:FindFirstChild("Explode")
end

-- =============================================
-- [ PC용 TP 기능 (Z키) ]
-- =============================================
local function LookTeleport()
    local cam = workspace.CurrentCamera
    local char = plr.Character
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

-- Z키 입력 감지 (안전하게)
pcall(function()
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if input.KeyCode == Enum.KeyCode.Z then
            LookTeleport()
        end
    end)
end)

-- =============================================
-- [ 동그란 TP 버튼 (모바일용) ]
-- =============================================
local function createTPButton()
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "TPButton"
    screenGui.Parent = CoreGui
    screenGui.DisplayOrder = 999998
    screenGui.ResetOnSpawn = false

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
-- [ 안티보이드 함수 ]
-- =============================================
local AntiVoidT = true

local function AntiVoidF(enable)
    if enable then
        workspace.FallenPartsDestroyHeight = -50000
        print("✅ 안티보이드 활성화 (높이 -50000)")
    else
        workspace.FallenPartsDestroyHeight = -100
        print("🔴 안티보이드 비활성화")
    end
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
            for _, obj in ipairs(workspace:GetChildren()) do
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
                    for _, folder in ipairs(workspace:GetChildren()) do
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
-- [ 안티 불 함수 (raw(2).txt에서 가져옴) ]
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
        -- ExtinguishPart 찾기 (여러 경로 시도)
        local EP = nil
        
        -- Map/Hole/PoisonSmallHole 경로 시도
        local map = workspace:FindFirstChild("Map")
        if map then
            local hole = map:FindFirstChild("Hole")
            if hole then
                local poisonHole = hole:FindFirstChild("PoisonSmallHole")
                if poisonHole then
                    EP = poisonHole:FindFirstChild("ExtinguishPart")
                end
            end
        end
        
        -- 없으면 전체 검색
        if not EP then
            for _, child in ipairs(workspace:GetDescendants()) do
                if child.Name == "ExtinguishPart" and child:IsA("BasePart") then
                    EP = child
                    break
                end
            end
        end
        
        if not EP then 
            Rayfield:Notify({Title = "안티불", Content = "ExtinguishPart를 찾을 수 없음", Duration = 2})
            return 
        end
        
        -- 원래 값 저장
        local originalSize = EP.Size
        local originalCFrame = EP.CFrame
        local originalTransparency = EP.Transparency
        local originalCastShadow = EP.CastShadow
        
        while AntiBurnV do
            local char = plr.Character
            if char then
                local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                if head then
                    EP.Transparency = 1
                    EP.CastShadow = false
                    EP.Size = Vector3.new(0, 0, 0)
                    EP.CFrame = head.CFrame * CFrame.new(0, 100, 0)
                end
            end
            task.wait(0.1)
        end
        
        -- 복원
        EP.Size = originalSize
        EP.CFrame = originalCFrame
        EP.Transparency = originalTransparency
        EP.CastShadow = originalCastShadow
    end)
end

-- =============================================
-- [ 안티 폭발 함수 (raw(2).txt에서 가져옴) ]
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

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    AntiExplosionC = workspace.ChildAdded:Connect(function(model)
        if not char or not hrp or not hum or not AntiExplosionT then return end
        
        if model:IsA("BasePart") and (model.Position - hrp.Position).Magnitude <= 25 then
            if hum.SeatPart ~= nil then
                hrp.Anchored = true
                task.wait(0.03)
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                hrp.Anchored = false
            else
                hrp.Anchored = true
                task.wait(0.05)
                hum:ChangeState(Enum.HumanoidStateType.Running)
                hrp.Anchored = false
                hum.AutoRotate = true
            end
        end
    end)
end

-- =============================================
-- [ 안티 페인트 함수 (raw(2).txt에서 가져옴) ]
-- =============================================
local AntiPaintT = false
local AntiPaintThread = nil

local function antiPaintF(state)
    if AntiPaintThread then
        task.cancel(AntiPaintThread)
        AntiPaintThread = nil
    end

    if state then
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
end

-- =============================================
-- [ 킥그랩 관련 변수 ]
-- =============================================
local KickGrabState = {
    Target = nil,
    Looping = false,
    AutoRagdoll = false,
    Mode = "Camera",
    DetentionDist = 19,
    SnowBallLooping = false
}

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
-- [ 원본 루프그랩 함수 ]
-- =============================================
local AntiStruggleGrabT = false
local antiStruggleThread = nil

local function AntiStruggleGrabF()
    if antiStruggleThread then
        task.cancel(antiStruggleThread)
        antiStruggleThread = nil
    end

    if not AntiStruggleGrabT then return end

    antiStruggleThread = task.spawn(function()
        while AntiStruggleGrabT do
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
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl.Character and part1:IsDescendantOf(pl.Character) then
                        ownerPlayer = pl
                        break
                    end
                end

                while AntiStruggleGrabT and workspace:FindFirstChild("GrabParts") do
                    if ownerPlayer then
                        local tgtTorso = ownerPlayer.Character and ownerPlayer.Character:FindFirstChild("HumanoidRootPart")
                        local myTorso = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")

                        if tgtTorso and myTorso and SetNetworkOwner then
                            pcall(function()
                                SetNetworkOwner:FireServer(tgtTorso, CFrame.lookAt(myTorso.Position, tgtTorso.Position))
                            end)
                        end
                    else
                        if part1 and part1.Parent and SetNetworkOwner then
                            local myTorso = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                            if myTorso then
                                pcall(function()
                                    SetNetworkOwner:FireServer(part1, CFrame.lookAt(myTorso.Position, part1.Position))
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
end

-- =============================================
-- [ 초고속 안티그랩 함수 ]
-- =============================================
local antiGrabConn = nil
local isAntiGrabEnabled = false

local function AntiGrabF(enable)
    if antiGrabConn then
        antiGrabConn:Disconnect()
        antiGrabConn = nil
    end

    if not enable then return end

    antiGrabConn = RunService.RenderStepped:Connect(function()
        local char = plr.Character
        if not char then return end

        local isHeld = plr:FindFirstChild("IsHeld")
        if not isHeld then return end

        local head = char:FindFirstChild("Head")
        local POR = head and head:FindFirstChild("PartOwner")
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if isHeld.Value == true or (POR and POR.Value ~= "") then
            if Struggle then pcall(function() Struggle:FireServer() end) end
            
            local grabParts = workspace:FindFirstChild("GrabParts")
            if grabParts then
                for _, part in ipairs(grabParts:GetChildren()) do
                    if part.Name == "GrabPart" then
                        local weld = part:FindFirstChildOfClass("WeldConstraint")
                        if weld and weld.Part1 and weld.Part1:IsDescendantOf(char) and DestroyGrabLine then
                            pcall(function() DestroyGrabLine:FireServer(weld.Part1) end)
                            if hrp and SetNetworkOwner then 
                                pcall(function() SetNetworkOwner:FireServer(hrp) end) 
                            end
                            break
                        end
                    end
                end
            end
        end
    end)
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
        local grabParts = workspace:FindFirstChild("GrabParts")
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
-- [ 블롭 관련 변수 ]
-- =============================================
local playersInLoop1V = {}
local currentBlobS = nil
local blobmanInstanceS = nil
local sitJumpT = false
local AutoGucciT = false
local ragdollLoopD = false
local blobLoopT = false
local blobLoopThread = nil

-- =============================================
-- [ 블롭 관련 함수 ]
-- =============================================
local function UpdateCurrentBlobman()
    local char = plr.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, blobs in workspace:GetDescendants() do
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

    inv = getInv()
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
            inv = getInv()
            blobmanInstanceS = inv and inv:FindFirstChild("CreatureBlobman")
            tries = tries + 1
        until blobmanInstanceS or tries > 25
    end
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
        
        for _, obj in ipairs(workspace:GetChildren()) do
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
    if not Plots then return end
    
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

    if not Plots then
        PBDrun = false
        Rayfield:Notify({Title = "오류", Content = "Plots를 찾을 수 없음", Duration = 2})
        return
    end

    local metal = nil
    local plot1 = Plots:FindFirstChild("Plot1")
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

    if SpawnToyRemote then
        task.spawn(function()
            pcall(function()
                SpawnToyRemote:InvokeServer("FoodBread", hrp.CFrame, Vector3.new(0,0,0))
            end)
        end)
    end

    task.wait(0.2)

    inv = getInv()
    local foodBread = inv and inv:FindFirstChild("FoodBread")
    if not foodBread then 
        PBDrun = false 
        Rayfield:Notify({Title = "오류", Content = "FoodBread 생성 실패", Duration = 2})
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
        if target and target.Character and SetNetworkOwner then
            local torso = target.Character:FindFirstChild("Torso") or target.Character:FindFirstChild("HumanoidRootPart")
            if torso then
                pcall(function() SetNetworkOwner:FireServer(torso, torso.CFrame) end)
                
                if mode == "kill" then
                    local FallenY = workspace.FallenPartsDestroyHeight
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
-- [ 플레이어 재접속 시 방어 기능 재설정 ]
-- =============================================
plr.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid", 5)
    char:WaitForChild("HumanoidRootPart", 5)
    task.wait(1)
    
    inv = getInv()
    
    if AntiExplosionT then
        AntiExplosionF()
    end
    
    if AntiPaintT then
        antiPaintF(true)
    end
    
    if AntiBurnV then
        AntiBurn()
    end
end)

-- =============================================
-- [ 안티 AFK ]
-- =============================================
plr.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- =============================================
-- [ TP 버튼 생성 ]
-- =============================================
pcall(createTPButton)

-- =============================================
-- [ Rayfield UI 설정 ]
-- =============================================
local Window = Rayfield:CreateWindow({
    Name = "FTAP 올인원 (방어 기능 통합)",
    LoadingTitle = "킥그랩 + 안티불 + 안티폭발 + 안티페인트 + 안티보이드",
    ConfigurationSaving = { Enabled = false },
    Discord = {
        Enabled = false,
        Invite = "",
        RememberJoins = true
    },
    KeySystem = false
})

-- 탭 생성
local MainTab = Window:CreateTab("메인", 4483362458)
local GrabTab = Window:CreateTab("그랩", 4483362458)
local DefenseTab = Window:CreateTab("🛡️ 방어", 4483362458)
local AuraTab = Window:CreateTab("아우라", 4483362458)
local TargetTab = Window:CreateTab("킬 플레이어 정하기", 4483362458)
local SettingsTab = Window:CreateTab("설정", 4483362458)

-- =============================================
-- [ 메인 탭 ]
-- =============================================
MainTab:CreateSection("🛡️ 기본 방어")

local AntiGrabToggle = MainTab:CreateToggle({
    Name = "⚡ 초고속 Anti-Grab",
    CurrentValue = false,
    Callback = function(Value)
        isAntiGrabEnabled = Value
        AntiGrabF(Value)
    end
})

MainTab:CreateButton({
    Name = "🔓 즉시 해제",
    Callback = ManualRelease
})

local PcldViewToggle = MainTab:CreateToggle({
    Name = "👁️ PCLD 보이게",
    CurrentValue = false,
    Callback = function(Value)
        pcldViewEnabled = Value
        togglePcldView(Value)
    end
})

local BarrierNoclipToggle = MainTab:CreateToggle({
    Name = "🧱 Barrier Noclip",
    CurrentValue = false,
    Callback = function(Value)
        BarrierCanCollideT = Value
        BarrierCanCollideF()
    end
})

MainTab:CreateButton({
    Name = "💥 집 베리어 부수기",
    Callback = PlotBarrierDelete
})

local AntiPCLDToggle = MainTab:CreateToggle({
    Name = "🛡️ Anti-Kick (PCLD 방어)",
    CurrentValue = false,
    Callback = function(Value)
        AntiPCLDEnabled = Value
        if Value then
            setupAntiPCLD()
            Rayfield:Notify({Title = "안티킥", Content = "활성화 - PCLD 감지 시 자동 방어", Duration = 2})
        else
            Rayfield:Notify({Title = "안티킥", Content = "비활성화", Duration = 2})
        end
    end
})

MainTab:CreateSection("📊 상태")

local StatusLabel = MainTab:CreateLabel("상태: 확인 중...", 4483362458)

task.spawn(function()
    while task.wait(0.5) do
        local char = plr.Character
        local isHeld = plr:FindFirstChild("IsHeld")
        local head = char and char:FindFirstChild("Head")
        local por = head and head:FindFirstChild("PartOwner")
        
        if isHeld and isHeld.Value then
            StatusLabel:Set("상태: 🟡 잡힘")
        elseif por and por.Value ~= "" then
            StatusLabel:Set("상태: 🟠 오너쉽 있음 (" .. por.Value .. ")")
        else
            StatusLabel:Set("상태: 🟢 안전")
        end
    end
end)

-- =============================================
-- [ 그랩 탭 ]
-- =============================================
GrabTab:CreateSection("🔄 그랩 공격")

local LoopGrabToggle = GrabTab:CreateToggle({
    Name = "🔄 Loop Grab",
    CurrentValue = false,
    Callback = function(Value)
        AntiStruggleGrabT = Value
        AntiStruggleGrabF()
        Rayfield:Notify({Title = "Loop Grab", Content = Value and "활성화" or "비활성화", Duration = 2})
    end
})

-- =============================================
-- [ 방어 탭 (raw에서 가져온 3개 기능 포함) ]
-- =============================================
DefenseTab:CreateSection("🌌 보이드 방어")

local AntiVoidToggle = DefenseTab:CreateToggle({
    Name = "🌌 Anti-Void (보이드 방지)",
    CurrentValue = true,
    Callback = function(Value)
        AntiVoidT = Value
        AntiVoidF(Value)
        Rayfield:Notify({Title = "안티보이드", Content = Value and "활성화 (높이 -50000)" or "비활성화", Duration = 2})
    end
})
AntiVoidToggle:Set(true)

DefenseTab:CreateSection("🔥 화염 방어 (raw(2) 소스)")

local AntiBurnToggle = DefenseTab:CreateToggle({
    Name = "🔥 Anti-Burn (불 방어)",
    CurrentValue = false,
    Callback = function(Value)
        AntiBurnV = Value
        if Value then
            AntiBurn()
            Rayfield:Notify({Title = "안티불", Content = "활성화", Duration = 2})
        else
            if AntiBurnThread then
                task.cancel(AntiBurnThread)
                AntiBurnThread = nil
            end
            Rayfield:Notify({Title = "안티불", Content = "비활성화", Duration = 2})
        end
    end
})

DefenseTab:CreateSection("💥 폭발 방어 (raw(2) 소스)")

local AntiExplodeToggle = DefenseTab:CreateToggle({
    Name = "💥 Anti-Explosion (폭발 방어)",
    CurrentValue = false,
    Callback = function(Value)
        AntiExplosionT = Value
        if Value then
            AntiExplosionF()
            Rayfield:Notify({Title = "안티폭발", Content = "활성화", Duration = 2})
        else
            if AntiExplosionC then 
                AntiExplosionC:Disconnect() 
                AntiExplosionC = nil
            end
            Rayfield:Notify({Title = "안티폭발", Content = "비활성화", Duration = 2})
        end
    end
})

DefenseTab:CreateSection("🎨 페인트 방어 (raw(2) 소스)")

local AntiPaintToggle = DefenseTab:CreateToggle({
    Name = "🎨 Anti-Paint (페인트 방어)",
    CurrentValue = false,
    Callback = function(Value)
        AntiPaintT = Value
        antiPaintF(Value)
        Rayfield:Notify({Title = "안티페인트", Content = Value and "활성화" or "비활성화", Duration = 2})
    end
})

DefenseTab:CreateSection("🛡️ 방어 상태")

local StatusVoid = DefenseTab:CreateLabel("🌌 보이드 방어: 켜짐", 4483362458)
local StatusBurn = DefenseTab:CreateLabel("🔥 불 방어: 꺼짐", 4483362458)
local StatusExplode = DefenseTab:CreateLabel("💥 폭발 방어: 꺼짐", 4483362458)
local StatusPaint = DefenseTab:CreateLabel("🎨 페인트 방어: 꺼짐", 4483362458)

task.spawn(function()
    while task.wait(0.5) do
        StatusVoid:Set("🌌 보이드 방어: " .. (AntiVoidT and "켜짐" or "꺼짐"))
        StatusBurn:Set("🔥 불 방어: " .. (AntiBurnV and "켜짐" or "꺼짐"))
        StatusExplode:Set("💥 폭발 방어: " .. (AntiExplosionT and "켜짐" or "꺼짐"))
        StatusPaint:Set("🎨 페인트 방어: " .. (AntiPaintT and "켜짐" or "꺼짐"))
    end
end)

-- =============================================
-- [ 아우라 탭 ]
-- =============================================
AuraTab:CreateSection("🌀 안티 스티키 아우라")

local AntiStickyAuraToggle = AuraTab:CreateToggle({
    Name = "Anti-Sticky Aura",
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
-- [ 킬 플레이어 정하기 탭 ]
-- =============================================
TargetTab:CreateSection("🎯 킬 플레이어 정하기")

local TargetListDropdown = TargetTab:CreateDropdown({
    Name = "Target List",
    Options = targetList,
    CurrentOption = {"OPEN"},
    MultipleOptions = true,
    Callback = function(Options)
        targetList = Options
    end
})

TargetTab:CreateInput({
    Name = "Add (자동완성)",
    PlaceholderText = "닉네임 일부 입력",
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
    Name = "💀 Kill",
    Callback = function() manualKill("kill") end
})

TargetTab:CreateButton({
    Name = "👢 Kick",
    Callback = function() manualKill("kick") end
})

-- 팔다리 제거 드롭다운
local DeletePartDropdown = TargetTab:CreateDropdown({
    Name = "🦴 제거할 부위 선택",
    Options = {"Arm/Leg", "Legs", "Arms"},
    CurrentOption = {"Arm/Leg"},
    Callback = function(Options)
        selectedDeletePart = Options[1]
    end
})

TargetTab:CreateButton({
    Name = "🦴 선택된 대상 팔다리 제거",
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
    Name = "🎯 현재 그랩한 대상 팔다리 제거",
    Callback = function()
        local beamPart = workspace:FindFirstChild("GrabParts") and workspace.GrabParts:FindFirstChild("BeamPart")
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
task.spawn(function() while task.wait(0.5) do SelectedLabel:Set("선택됨: " .. #targetList .. "명") end end)

-- =============================================
-- [ 설정 탭 ]
-- =============================================
SettingsTab:CreateSection("⌨️ 단축키 안내")
SettingsTab:CreateParagraph({
    Title = "PC 단축키",
    Content = "Z 키: 시선 방향 텔레포트"
})

SettingsTab:CreateSection("📱 모바일")
SettingsTab:CreateParagraph({
    Title = "모바일",
    Content = "화면 우측 하단의 📍 버튼을 눌러 텔레포트"
})

-- =============================================
-- [ 자동 실행 ]
-- =============================================
task.wait(1)
isAntiGrabEnabled = true
AntiGrabF(true)
AntiGrabToggle:Set(true)

AntiVoidF(true)  -- 안티보이드 자동 실행

Rayfield:Notify({
    Title = "🚀 로드 완료",
    Content = "방어 탭에 안티불/안티폭발/안티페인트 추가됨 | Z키 TP",
    Duration = 5
})
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
-- [ TP 함수 (raw 기반) ]
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
-- [ 안티보이드 함수 (추가됨) ]
-- =============================================
local AntiVoidT = true

local function AntiVoidF(enable)
    if enable then
        Workspace.FallenPartsDestroyHeight = -50000
        print("✅ 안티보이드 활성화 (높이 -50000)")
    else
        Workspace.FallenPartsDestroyHeight = -100
        print("🔴 안티보이드 비활성화")
    end
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
-- [ 안티 불 함수 (raw(2).txt에서 가져옴) ]
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
        local EP = workspace:FindFirstChild("Map"):FindFirstChild("Hole"):FindFirstChild("PoisonSmallHole"):FindFirstChild("ExtinguishPart")
        
        while AntiBurnV do
            local hrp = plr.Character and plr.Character:FindFirstChild("Head") -- HumanoidRootPart
            if hrp then
                EP.Transparency = 1
                EP.CastShadow = false
                if EP:FindFirstChild("Tex") then
                    EP.Tex.Transparency = 1
                end
                EP.Size = Vector3.new(0, 0, 0)
                EP.CFrame = hrp.CFrame
                task.wait()
                EP.CFrame = hrp.CFrame * CFrame.new(0,3,0)
            end
            task.wait()
        end
        
        -- 복원
        EP.Size = Vector3.new(103.90400695800781, 7.5, 95.14202880859375)
        EP.CFrame = CFrame.new(157.075317, -58.8218384, 287.346954, -1.1920929e-07, 0, -1.00000012, 0, 1, 0, 1.00000012, 0, -1.1920929e-07)
        EP.Transparency = 0.5
        EP.CastShadow = true
        if EP:FindFirstChild("Tex") then
            EP.Tex.Transparency = 0
        end
    end)
end

-- =============================================
-- [ 안티 폭발 함수 (raw(2).txt에서 가져옴) ]
-- =============================================
local AntiExplosionT = false
local AntiExplosionC = nil
local AntiExplosionH = nil

local function AntiExplosionF()
    if AntiExplosionC then
        AntiExplosionC:Disconnect()
        AntiExplosionC = nil
    end
    if AntiExplosionH then
        AntiExplosionH:Disconnect()
        AntiExplosionH = nil
    end

    if not AntiExplosionT then return end

    local char = plr.Character
    if not char then return end

    local hrp = char:WaitForChild("HumanoidRootPart")
    local hum = char:WaitForChild("Humanoid")

    AntiExplosionC = workspace.ChildAdded:Connect(function(model)
        if not char or not hrp or not hum then return end
        
        if model:IsA("BasePart") and (model.Position - hrp.Position).Magnitude <= 20 then
            if hum.SeatPart ~= nil then
                hrp.Anchored = true
                task.wait(0.03)
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                hrp.Anchored = false
            else
                if model:IsA("BasePart") and (model.Position - hrp.Position).Magnitude <= 20 then
                    hrp.Anchored = true
                    task.wait()
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                    hrp.Anchored = false
                    hum.AutoRotate = true

                    for _, limb in ipairs(char:GetDescendants()) do
                        if limb:IsA("BasePart") and limb.Name == "RagdollLimbPart" then
                            limb.CanCollide = false
                        end
                    end
                end
            end
        end
    end)
end

-- =============================================
-- [ 안티 페인트 함수 (raw(2).txt에서 가져옴) ]
-- =============================================
local AntiPaintT = false

local function antiPaintF(state)
    local function setParts(canTouch)
        local char = plr.Character
        if not char then return end
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
                part.CanTouch = canTouch
            end
        end
    end

    if state == true then
        task.spawn(function()
            while AntiPaintT do
                setParts(false)
                task.wait(0.1)
            end
        end)
    else
        setParts(true)
    end
end

-- =============================================
-- [ 킥그랩 관련 변수 ]
-- =============================================
local KickGrabState = {
    Target = nil,
    Looping = false,
    AutoRagdoll = false,
    Mode = "Camera",
    DetentionDist = 19,
    SnowBallLooping = false
}

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
    local hasClaimed = false
    local isBlinking = false
    local frameToggle = true

    while KickGrabState.Looping do
        local myChar = plr.Character
        local targetChar = KickGrabState.Target and KickGrabState.Target.Character
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
                distance = (myHrp.Position - targetHrp.Position).Magnitude
            end
            
            if distance > 20 and not hasClaimed and rOwner then
                isBlinking = true
                local originalCFrame = myHrp.CFrame
                myHrp.CFrame = targetHrp.CFrame 
                
                local claimStart = tick()
                while (tick() - claimStart < 0.5) do 
                    if not KickGrabState.Looping then break end
                    myHrp.CFrame = targetHrp.CFrame
                    rOwner:FireServer(targetHrp, targetHrp.CFrame) 
                    if targetBody then rOwner:FireServer(targetBody, targetBody.CFrame) end
                    RunService.Heartbeat:Wait()
                end
                
                targetHrp.CFrame = originalCFrame
                targetHrp.AssemblyLinearVelocity = Vector3.zero 
                
                myHrp.CFrame = originalCFrame
                rOwner:FireServer(targetHrp, originalCFrame)
                
                hasClaimed = true
                isBlinking = false 
            
            elseif distance <= 20 and not hasClaimed and rOwner then
                local instantClaimStart = tick()
                while (tick() - instantClaimStart < 0.3) do
                    if not KickGrabState.Looping then break end
                    rOwner:FireServer(targetHrp, targetHrp.CFrame)
                    if targetBody then rOwner:FireServer(targetBody, targetBody.CFrame) end
                    RunService.Heartbeat:Wait()
                end
                hasClaimed = true 
            end
            
            if not isBlinking and rOwner and rDestroy then
                local detentionPos
                if KickGrabState.Mode == "Up" then 
                    detentionPos = myHrp.CFrame * CFrame.new(0, 18, 0)
                elseif KickGrabState.Mode == "Down" then 
                    detentionPos = myHrp.CFrame * CFrame.new(0, -10, 0)
                else 
                    detentionPos = cam.CFrame * CFrame.new(0, 0, -KickGrabState.DetentionDist)
                end
                
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
                        local rCreate = CreateGrabLine
                        local rExtend = ExtendGrabLine
                        pallet.CFrame = targetHrp.CFrame * CFrame.new(0, 2, 0) 
                        if rCreate then rCreate:FireServer(pallet, pallet.CFrame) end
                        if rExtend then rExtend:FireServer(25) end
                        if rOwner then rOwner:FireServer(pallet, pallet.CFrame) end
                        isPalletOwned = true
                        task.wait(0.1) 
                    else
                        local currentTime = tick()
                        local timeSinceStrike = currentTime - lastStrikeTime
                        local targetPos
                        if timeSinceStrike > 2.0 then
                            targetPos = targetHrp.CFrame 
                            pallet.AssemblyLinearVelocity = Vector3.new(0, 400, 0)
                            pallet.AssemblyAngularVelocity = Vector3.new(1000, 1000, 1000)
                            if timeSinceStrike > 2.15 then lastStrikeTime = currentTime end
                        else
                            local angle = currentTime * 15
                            targetPos = targetHrp.CFrame * CFrame.new(math.cos(angle)*100, 50, math.sin(angle)*100)
                            pallet.AssemblyLinearVelocity = Vector3.zero
                            pallet.AssemblyAngularVelocity = Vector3.new(100, 100, 100)
                        end
                        pallet.CFrame = targetPos
                    end
                end
            end
        end
        RunService.Heartbeat:Wait()
    end
end

-- =============================================
-- [ SnowBall 루프 함수 ]
-- =============================================
local function ExecuteSnowballLoop()
    while KickGrabState.SnowBallLooping do
        local myHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        local targetChar = KickGrabState.Target and KickGrabState.Target.Character
        local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        
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
-- [ 원본 루프그랩 함수 ]
-- =============================================
local AntiStruggleGrabT = false
local antiStruggleThread = nil

local function AntiStruggleGrabF()
    if antiStruggleThread then
        task.cancel(antiStruggleThread)
        antiStruggleThread = nil
    end

    if not AntiStruggleGrabT then return end

    antiStruggleThread = task.spawn(function()
        while AntiStruggleGrabT do
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
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl.Character and part1:IsDescendantOf(pl.Character) then
                        ownerPlayer = pl
                        break
                    end
                end

                while AntiStruggleGrabT and workspace:FindFirstChild("GrabParts") do
                    if ownerPlayer then
                        local tgtTorso = ownerPlayer.Character and ownerPlayer.Character:FindFirstChild("HumanoidRootPart")
                        local myTorso = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")

                        if tgtTorso and myTorso then
                            pcall(function()
                                SetNetworkOwner:FireServer(tgtTorso, CFrame.lookAt(myTorso.Position, tgtTorso.Position))
                            end)
                        end
                    else
                        if part1 and part1.Parent then
                            local myTorso = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                            if myTorso then
                                pcall(function()
                                    SetNetworkOwner:FireServer(part1, CFrame.lookAt(myTorso.Position, part1.Position))
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
end

-- =============================================
-- [ 초고속 안티그랩 함수 ]
-- =============================================
local antiGrabConn = nil
local isAntiGrabEnabled = false

local function AntiGrabF(enable)
    if antiGrabConn then
        antiGrabConn:Disconnect()
        antiGrabConn = nil
    end

    if not enable then return end

    antiGrabConn = RunService.RenderStepped:Connect(function()
        local char = plr.Character
        if not char then return end

        local isHeld = plr:FindFirstChild("IsHeld")
        if not isHeld then return end

        local head = char:FindFirstChild("Head")
        local POR = head and head:FindFirstChild("PartOwner")
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if isHeld.Value == true or (POR and POR.Value ~= "") then
            pcall(function() Struggle:FireServer() end)
            
            local grabParts = Workspace:FindFirstChild("GrabParts")
            if grabParts then
                for _, part in ipairs(grabParts:GetChildren()) do
                    if part.Name == "GrabPart" then
                        local weld = part:FindFirstChildOfClass("WeldConstraint")
                        if weld and weld.Part1 and weld.Part1:IsDescendantOf(char) then
                            pcall(function() DestroyGrabLine:FireServer(weld.Part1) end)
                            if hrp then pcall(function() SetNetworkOwner:FireServer(hrp) end) end
                            break
                        end
                    end
                end
            end
        end
    end)
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
local blobLoopThread = nil
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
-- [ 수정된 블롭 공격 함수 (원거리 TP 추가) ]
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
                local myChar = plr.Character
                local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                
                if myHrp then
                    local distance = (myHrp.Position - hrp.Position).Magnitude
                    if distance > 30 then
                        TP(player)
                        task.wait(0.1)
                    end
                end
                
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
-- [ 수정된 블롭 자동 킥 함수 (원거리 TP 추가) ]
-- =============================================
local function BlobLoopKick()
    UpdateCurrentBlobman()
    if not currentBlobS then
        Rayfield:Notify({Title = "블롭", Content = "블롭을 타고 있어야 합니다", Duration = 2})
        return
    end
    
    if blobLoopThread then
        task.cancel(blobLoopThread)
        blobLoopThread = nil
    end
    
    blobLoopThread = task.spawn(function()
        while blobLoopT do
            for _, targetName in ipairs(playersInLoop1V) do
                if not blobLoopT then break end
                
                local player = Players:FindFirstChild(targetName)
                if not player then continue end
                
                if PPs and PPs:FindFirstChild(targetName) then continue end
                if inv and inv:FindFirstChild(targetName) then continue end
                
                local character = player.Character
                if not character then continue end
                
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end
                
                if hrp.Massless == true then continue end
                
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local myChar = plr.Character
                    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    
                    if myHrp then
                        local distance = (myHrp.Position - hrp.Position).Magnitude
                        if distance > 30 then
                            TP(player)
                            task.wait(0.1)
                        end
                    end
                    
                    local head = character:FindFirstChild("Head")
                    if head then
                        local tpRunning = true
                        local myChar = plr.Character
                        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        local originCF = myHrp and myHrp.CFrame
                        
                        local tpThread = task.spawn(function()
                            while tpRunning do
                                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and myHrp then
                                    local targetHRP = player.Character.HumanoidRootPart
                                    local ping = plr:GetNetworkPing()
                                    local offset = targetHRP.Position + (targetHRP.Velocity * (ping + 0.15))
                                    myHrp.CFrame = CFrame.new(offset) * targetHRP.CFrame.Rotation
                                end
                                task.wait()
                            end
                        end)
                        
                        for _ = 1, 30 do
                            if not blobLoopT then break end
                            pcall(function()
                                SetNetworkOwner:FireServer(head, head.CFrame)
                            end)
                            local ownerTag = head:FindFirstChild("PartOwner")
                            if ownerTag and ownerTag:IsA("StringValue") and ownerTag.Value == plr.Name then
                                break
                            end
                            task.wait(0.1)
                        end
                        
                        tpRunning = false
                        task.cancel(tpThread)
                        
                        pcall(function()
                            DestroyGrabLine:FireServer(head, head.CFrame)
                        end)
                        
                        if myHrp then
                            hrp.CFrame = CFrame.new(myHrp.CFrame.X, myHrp.CFrame.Y + 50, myHrp.CFrame.Z)
                            myHrp.CFrame = hrp.CFrame
                        end
                        
                        BlobMassless(currentBlobS, hrp, "Right")
                        
                        if originCF and myHrp then
                            myHrp.CFrame = originCF
                        end
                    end
                end
                task.wait(0.1)
            end
            task.wait(0.3)
        end
    end)
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
        Rayfield:Notify({Title = "오류", Content = "FoodBread 생성 실패", Duration = 2})
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
-- [ 플레이어 재접속 시 방어 기능 재설정 ]
-- =============================================
plr.CharacterAdded:Connect(function(char)
    char:WaitForChild("Humanoid")
    char:WaitForChild("HumanoidRootPart")
    task.wait(1)
    
    if AntiExplosionT then
        AntiExplosionF()
    end
    
    if AntiPaintT then
        antiPaintF(true)
    end
    
    if AntiBurnV then
        AntiBurn()
    end
end)

-- =============================================
-- [ Rayfield UI 설정 ]
-- =============================================
local Window = Rayfield:CreateWindow({
    Name = "FTAP 올인원 (방어 기능 통합)",
    LoadingTitle = "킥그랩 + 안티불 + 안티폭발 + 안티페인트 + 안티보이드",
    ConfigurationSaving = { Enabled = false }
})

-- 탭 생성
local MainTab = Window:CreateTab("메인", 4483362458)
local BlobTab = Window:CreateTab("블롭", 4483362458)
local GrabTab = Window:CreateTab("그랩", 4483362458)
local DefenseTab = Window:CreateTab("🛡️ 방어", 4483362458)
local AuraTab = Window:CreateTab("아우라", 4483362458)
local TargetTab = Window:CreateTab("킬 플레이어 정하기", 4483362458)
local NotifyTab = Window:CreateTab("🔔 알림", 4483362458)
local KickGrabTab = Window:CreateTab("👢 킥그랩", 4483362458)
local SettingsTab = Window:CreateTab("설정", 4483362458)

-- =============================================
-- [ 메인 탭 ]
-- =============================================
MainTab:CreateSection("🛡️ 기본 방어")

local AntiGrabToggle = MainTab:CreateToggle({
    Name = "⚡ 초고속 Anti-Grab",
    CurrentValue = false,
    Callback = function(Value)
        isAntiGrabEnabled = Value
        AntiGrabF(Value)
    end
})

MainTab:CreateButton({
    Name = "🔓 즉시 해제",
    Callback = ManualRelease
})

local PcldViewToggle = MainTab:CreateToggle({
    Name = "👁️ PCLD 보이게",
    CurrentValue = false,
    Callback = function(Value)
        pcldViewEnabled = Value
        togglePcldView(Value)
    end
})

local BarrierNoclipToggle = MainTab:CreateToggle({
    Name = "🧱 Barrier Noclip",
    CurrentValue = false,
    Callback = function(Value)
        BarrierCanCollideT = Value
        BarrierCanCollideF()
    end
})

MainTab:CreateButton({
    Name = "💥 집 베리어 부수기",
    Callback = PlotBarrierDelete
})

local AntiPCLDToggle = MainTab:CreateToggle({
    Name = "🛡️ Anti-Kick (PCLD 방어)",
    CurrentValue = false,
    Callback = function(Value)
        AntiPCLDEnabled = Value
        if Value then
            setupAntiPCLD()
            Rayfield:Notify({Title = "안티킥", Content = "활성화 - PCLD 감지 시 자동 방어", Duration = 2})
        else
            Rayfield:Notify({Title = "안티킥", Content = "비활성화", Duration = 2})
        end
    end
})

MainTab:CreateSection("📊 상태")

local StatusLabel = MainTab:CreateLabel("상태: 확인 중...", 4483362458)

spawn(function()
    while task.wait(0.5) do
        local char = plr.Character
        local isHeld = plr:FindFirstChild("IsHeld")
        local head = char and char:FindFirstChild("Head")
        local por = head and head:FindFirstChild("PartOwner")
        
        if isHeld and isHeld.Value then
            StatusLabel:Set("상태: 🟡 잡힘")
        elseif por and por.Value ~= "" then
            StatusLabel:Set("상태: 🟠 오너쉽 있음 (" .. por.Value .. ")")
        else
            StatusLabel:Set("상태: 🟢 안전")
        end
    end
end)

-- =============================================
-- [ 블롭 탭 ]
-- =============================================
BlobTab:CreateSection("🦠 블롭 공격 대상")

local BlobTargetDropdown = BlobTab:CreateDropdown({
    Name = "List",
    Options = playersInLoop1V,
    CurrentOption = {"OPEN"},
    MultipleOptions = true,
    Flag = "BlobTargetDropdown",
    Callback = function(Options)
        playersInLoop1V = Options
    end
})

BlobTab:CreateInput({
    Name = "Add (자동완성)",
    PlaceholderText = "닉네임 일부 입력",
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
    Name = "💀 블롭 킬 (Grab+Release) [TP 자동]",
    Callback = function() BlobAttackAll("kill") end
})

BlobTab:CreateButton({
    Name = "⚡ 블롭 매스리스 [TP 자동]",
    Callback = function() BlobAttackAll("massless") end
})

BlobTab:CreateButton({
    Name = "🤚 블롭 잡기 (Grab) [TP 자동]",
    Callback = function() BlobAttackAll("grab") end
})

BlobTab:CreateButton({
    Name = "✋ 블롭 놓기 (Release) [TP 자동]",
    Callback = function() BlobAttackAll("release") end
})

BlobTab:CreateButton({
    Name = "⬇️ 블롭 드롭 (Drop) [TP 자동]",
    Callback = function() BlobAttackAll("drop") end
})

BlobTab:CreateSection("🔄 블롭 자동 킥")

local BlobLoopKickToggle = BlobTab:CreateToggle({
    Name = "🔄 블롭 자동 킥 (루프) [TP 자동]",
    CurrentValue = false,
    Callback = function(Value)
        blobLoopT = Value
        if blobLoopT then
            BlobLoopKick()
            Rayfield:Notify({Title = "블롭 킥", Content = "자동 루프 시작 (원거리 TP)", Duration = 2})
        else
            if blobLoopThread then
                task.cancel(blobLoopThread)
                blobLoopThread = nil
            end
            Rayfield:Notify({Title = "블롭 킥", Content = "자동 루프 종료", Duration = 2})
        end
    end
})

BlobTab:CreateSection("✨ 구찌 설정")

local AutoGucciToggle = BlobTab:CreateToggle({
    Name = "Auto-Gucci (y=9999)",
    CurrentValue = false,
    Callback = function(Value)
        AutoGucciT = Value
        if AutoGucciT then
            task.spawn(AutoGucciF)
            Rayfield:Notify({Title = "Gucci", Content = "활성화 (y=9999)", Duration = 2})
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
    Name = "🔄 Loop Grab (raw 기반)",
    CurrentValue = false,
    Callback = function(Value)
        AntiStruggleGrabT = Value
        AntiStruggleGrabF()
        Rayfield:Notify({Title = "Loop Grab", Content = Value and "활성화" or "비활성화", Duration = 2})
    end
})

-- =============================================
-- [ 방어 탭 (raw에서 가져온 3개 기능 포함) ]
-- =============================================
DefenseTab:CreateSection("🌌 보이드 방어")

local AntiVoidToggle = DefenseTab:CreateToggle({
    Name = "🌌 Anti-Void (보이드 방지)",
    CurrentValue = true,
    Callback = function(Value)
        AntiVoidT = Value
        AntiVoidF(Value)
        Rayfield:Notify({Title = "안티보이드", Content = Value and "활성화 (높이 -50000)" or "비활성화", Duration = 2})
    end
})
AntiVoidToggle:Set(true)

DefenseTab:CreateSection("🔥 화염 방어 (raw(2) 소스)")

local AntiBurnToggle = DefenseTab:CreateToggle({
    Name = "🔥 Anti-Burn (불 방어)",
    CurrentValue = false,
    Callback = function(Value)
        AntiBurnV = Value
        AntiBurn()
        Rayfield:Notify({Title = "안티불", Content = Value and "활성화 (ExtinguishPart 제어)" or "비활성화", Duration = 2})
    end
})

DefenseTab:CreateSection("💥 폭발 방어 (raw(2) 소스)")

local AntiExplodeToggle = DefenseTab:CreateToggle({
    Name = "💥 Anti-Explosion (폭발 방어)",
    CurrentValue = false,
    Callback = function(Value)
        AntiExplosionT = Value
        if Value then
            AntiExplosionF()
            Rayfield:Notify({Title = "안티폭발", Content = "활성화", Duration = 2})
        else
            if AntiExplosionC then AntiExplosionC:Disconnect() end
            if AntiExplosionH then AntiExplosionH:Disconnect() end
            Rayfield:Notify({Title = "안티폭발", Content = "비활성화", Duration = 2})
        end
    end
})

DefenseTab:CreateSection("🎨 페인트 방어 (raw(2) 소스)")

local AntiPaintToggle = DefenseTab:CreateToggle({
    Name = "🎨 Anti-Paint (페인트 방어)",
    CurrentValue = false,
    Callback = function(Value)
        AntiPaintT = Value
        antiPaintF(Value)
        Rayfield:Notify({Title = "안티페인트", Content = Value and "활성화 (CanTouch=False)" or "비활성화", Duration = 2})
    end
})

DefenseTab:CreateSection("🛡️ 방어 상태")

local StatusVoid = DefenseTab:CreateLabel("🌌 보이드 방어: 켜짐", 4483362458)
local StatusBurn = DefenseTab:CreateLabel("🔥 불 방어: 꺼짐", 4483362458)
local StatusExplode = DefenseTab:CreateLabel("💥 폭발 방어: 꺼짐", 4483362458)
local StatusPaint = DefenseTab:CreateLabel("🎨 페인트 방어: 꺼짐", 4483362458)

spawn(function()
    while task.wait(0.5) do
        StatusVoid:Set("🌌 보이드 방어: " .. (AntiVoidT and "켜짐" or "꺼짐"))
        StatusBurn:Set("🔥 불 방어: " .. (AntiBurnV and "켜짐" or "꺼짐"))
        StatusExplode:Set("💥 폭발 방어: " .. (AntiExplosionT and "켜짐" or "꺼짐"))
        StatusPaint:Set("🎨 페인트 방어: " .. (AntiPaintT and "켜짐" or "꺼짐"))
    end
end)

-- =============================================
-- [ 아우라 탭 ]
-- =============================================
AuraTab:CreateSection("🌀 안티 스티키 아우라")

local AntiStickyAuraToggle = AuraTab:CreateToggle({
    Name = "Anti-Sticky Aura",
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
-- [ 킥그랩 탭 ]
-- =============================================
KickGrabTab:CreateSection("🎯 대상 선택")

local TargetList = {}
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= plr then
        table.insert(TargetList, player.Name)
    end
end

local TargetDropdown = KickGrabTab:CreateDropdown({
    Name = "대상 선택",
    Options = TargetList,
    CurrentOption = {"선택하세요"},
    MultipleOptions = false,
    Callback = function(Options)
        local targetName = Options[1]
        if targetName and targetName ~= "선택하세요" then
            KickGrabState.Target = Players:FindFirstChild(targetName)
            Rayfield:Notify({Title = "킥그랩", Content = "대상: " .. targetName, Duration = 2})
        end
    end
})

KickGrabTab:CreateInput({
    Name = "대상 입력 (자동완성)",
    PlaceholderText = "닉네임 일부 입력",
    RemoveTextAfterFocusLost = true,
    Callback = function(Value)
        if not Value or Value == "" then return end
        local target = findPlayerByPartialName(Value)
        if target then
            KickGrabState.Target = target
            Rayfield:Notify({Title = "킥그랩", Content = "대상: " .. target.Name, Duration = 2})
        else
            Rayfield:Notify({Title = "오류", Content = "플레이어를 찾을 수 없음", Duration = 2})
        end
    end
})

KickGrabTab:CreateSection("⚙️ 모드 설정")

local ModeDropdown = KickGrabTab:CreateDropdown({
    Name = "모드 선택",
    Options = {"Camera", "Up", "Down"},
    CurrentOption = {"Camera"},
    MultipleOptions = false,
    Callback = function(Options)
        KickGrabState.Mode = Options[1]
        Rayfield:Notify({Title = "킥그랩", Content = "모드: " .. Options[1], Duration = 2})
    end
})

local DistInput = KickGrabTab:CreateInput({
    Name = "Camera 거리",
    CurrentValue = "19",
    PlaceholderText = "거리 (기본 19)",
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
    Name = "👢 Kick Grab",
    CurrentValue = false,
    Callback = function(Value)
        if Value and not KickGrabState.Target then
            Rayfield:Notify({Title = "오류", Content = "대상을 먼저 선택하세요", Duration = 2})
            KickGrabToggle:Set(false)
            return
        end
        KickGrabState.Looping = Value
        if Value then
            task.spawn(ExecuteKickGrabLoop)
            Rayfield:Notify({Title = "킥그랩", Content = "활성화 (원거리 TP)", Duration = 2})
        else
            Rayfield:Notify({Title = "킥그랩", Content = "비활성화", Duration = 2})
        end
    end
})

local AutoRagdollToggle = KickGrabTab:CreateToggle({
    Name = "🔄 Auto Ragdoll",
    CurrentValue = false,
    Callback = function(Value)
        KickGrabState.AutoRagdoll = Value
        Rayfield:Notify({Title = "오토 래그돌", Content = Value and "활성화" or "비활성화", Duration = 2})
    end
})

local SnowBallToggle = KickGrabTab:CreateToggle({
    Name = "❄️ SnowBall Ragdoll",
    CurrentValue = false,
    Callback = function(Value)
        if Value and not KickGrabState.Target then
            Rayfield:Notify({Title = "오류", Content = "대상을 먼저 선택하세요", Duration = 2})
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
-- [ 킬 플레이어 정하기 탭 ]
-- =============================================
TargetTab:CreateSection("🎯 킬 플레이어 정하기")

local TargetListDropdown = TargetTab:CreateDropdown({
    Name = "Target List",
    Options = targetList,
    CurrentOption = {"OPEN"},
    MultipleOptions = true,
    Callback = function(Options)
        targetList = Options
    end
})

TargetTab:CreateInput({
    Name = "Add (자동완성)",
    PlaceholderText = "닉네임 일부 입력",
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
    Name = "💀 Kill",
    Callback = function() manualKill("kill") end
})

TargetTab:CreateButton({
    Name = "👢 Kick",
    Callback = function() manualKill("kick") end
})

-- 팔다리 제거 드롭다운
local DeletePartDropdown = TargetTab:CreateDropdown({
    Name = "🦴 제거할 부위 선택",
    Options = {"Arm/Leg", "Legs", "Arms"},
    CurrentOption = {"Arm/Leg"},
    Callback = function(Options)
        selectedDeletePart = Options[1]
    end
})

TargetTab:CreateButton({
    Name = "🦴 선택된 대상 팔다리 제거",
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
    Name = "🎯 현재 그랩한 대상 팔다리 제거",
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
    Name = "IY UI 숨기기",
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
AntiVoidF(true)  -- 안티보이드 자동 실행

bringRayfieldToFront()

Rayfield:Notify({
    Title = "🚀 로드 완료",
    Content = "방어 탭에 안티불/안티폭발/안티페인트 추가됨 | Z키 TP",
    Duration = 5
})
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
-- [ TP 함수 (raw 기반) ]
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
-- [ 안티보이드 함수 (추가됨) ]
-- =============================================
local AntiVoidT = true

local function AntiVoidF(enable)
    if enable then
        Workspace.FallenPartsDestroyHeight = -50000
        print("✅ 안티보이드 활성화 (높이 -50000)")
    else
        Workspace.FallenPartsDestroyHeight = -100
        print("🔴 안티보이드 비활성화")
    end
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
-- [ 수정된 안티 불 함수 (시야 방해 제거) ]
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
        local EP = nil
        for _, child in ipairs(Workspace:GetDescendants()) do
            if child.Name == "ExtinguishPart" and child:IsA("BasePart") then
                EP = child
                break
            end
        end
        if not EP then 
            Rayfield:Notify({Title = "안티 불", Content = "ExtinguishPart를 찾을 수 없음", Duration = 2})
            return 
        end

        while AntiBurnV do
            local char = plr.Character
            if char then
                local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                if head then
                    EP.Transparency = 1
                    EP.Size = Vector3.new(0, 0, 0)
                    EP.CFrame = head.CFrame * CFrame.new(0, 100, 0)
                end
            end
            task.wait(0.1)
        end
    end)
end

-- =============================================
-- [ 안티 폭발 함수 (개선된 버전) ]
-- =============================================
local AntiExplosionT = false
local AntiExplosionC = nil
local AntiExplosionH = nil

local function AntiExplosionF()
    if AntiExplosionC then
        AntiExplosionC:Disconnect()
        AntiExplosionC = nil
    end
    if AntiExplosionH then
        AntiExplosionH:Disconnect()
        AntiExplosionH = nil
    end

    if not AntiExplosionT then return end

    local char = plr.Character
    if not char then return end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    -- ChildAdded 감지 (폭발 추가될 때)
    AntiExplosionC = Workspace.ChildAdded:Connect(function(model)
        if not char or not hrp or not hum or not AntiExplosionT then return end
        if model:IsA("BasePart") and (model.Position - hrp.Position).Magnitude <= 25 then
            if hum.SeatPart ~= nil then
                hrp.Anchored = true
                task.wait(0.05)
                hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
                hrp.Anchored = false
            else
                hrp.Anchored = true
                task.wait(0.05)
                hum:ChangeState(Enum.HumanoidStateType.Running)
                hrp.Anchored = false
                hum.AutoRotate = true
            end
        end
    end)

    -- DescendantAdded 감지 (추가 안전장치)
    AntiExplosionH = Workspace.DescendantAdded:Connect(function(model)
        if not char or not hrp or not hum or not AntiExplosionT then return end
        if model:IsA("BasePart") and (model.Position - hrp.Position).Magnitude <= 25 then
            hrp.Anchored = true
            task.wait(0.05)
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            hrp.Anchored = false
        end
    end)
end

-- =============================================
-- [ 안티 페인트 함수 ]
-- =============================================
local AntiPaintT = false
local AntiPaintThread = nil

local function AntiPaintF()
    if AntiPaintThread then
        task.cancel(AntiPaintThread)
        AntiPaintThread = nil
    end

    if not AntiPaintT then return end

    local paintParts = {
        "PaintDrop", "PaintSplat", "PaintBall", 
        "PaintBucket", "PaintProjectile", "PaintSplash"
    }

    AntiPaintThread = task.spawn(function()
        while AntiPaintT do
            local char = plr.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local hrp = char.HumanoidRootPart
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        local isPaint = false
                        for _, name in ipairs(paintParts) do
                            if obj.Name:find(name) then
                                isPaint = true
                                break
                            end
                        end
                        if isPaint then
                            local dist = (obj.Position - hrp.Position).Magnitude
                            if dist < 30 then
                                obj:Destroy()
                            end
                        end
                    end
                end
            end
            task.wait(0.5)
        end
    end)
end

-- =============================================
-- [ 킥그랩 관련 변수 ]
-- =============================================
local KickGrabState = {
    Target = nil,
    Looping = false,
    AutoRagdoll = false,
    Mode = "Camera",
    DetentionDist = 19,
    SnowBallLooping = false
}

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
    local hasClaimed = false
    local isBlinking = false
    local frameToggle = true

    while KickGrabState.Looping do
        local myChar = plr.Character
        local targetChar = KickGrabState.Target and KickGrabState.Target.Character
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
                distance = (myHrp.Position - targetHrp.Position).Magnitude
            end
            
            if distance > 20 and not hasClaimed and rOwner then
                isBlinking = true
                local originalCFrame = myHrp.CFrame
                myHrp.CFrame = targetHrp.CFrame 
                
                local claimStart = tick()
                while (tick() - claimStart < 0.5) do 
                    if not KickGrabState.Looping then break end
                    myHrp.CFrame = targetHrp.CFrame
                    rOwner:FireServer(targetHrp, targetHrp.CFrame) 
                    if targetBody then rOwner:FireServer(targetBody, targetBody.CFrame) end
                    RunService.Heartbeat:Wait()
                end
                
                targetHrp.CFrame = originalCFrame
                targetHrp.AssemblyLinearVelocity = Vector3.zero 
                
                myHrp.CFrame = originalCFrame
                rOwner:FireServer(targetHrp, originalCFrame)
                
                hasClaimed = true
                isBlinking = false 
            
            elseif distance <= 20 and not hasClaimed and rOwner then
                local instantClaimStart = tick()
                while (tick() - instantClaimStart < 0.3) do
                    if not KickGrabState.Looping then break end
                    rOwner:FireServer(targetHrp, targetHrp.CFrame)
                    if targetBody then rOwner:FireServer(targetBody, targetBody.CFrame) end
                    RunService.Heartbeat:Wait()
                end
                hasClaimed = true 
            end
            
            if not isBlinking and rOwner and rDestroy then
                local detentionPos
                if KickGrabState.Mode == "Up" then 
                    detentionPos = myHrp.CFrame * CFrame.new(0, 18, 0)
                elseif KickGrabState.Mode == "Down" then 
                    detentionPos = myHrp.CFrame * CFrame.new(0, -10, 0)
                else 
                    detentionPos = cam.CFrame * CFrame.new(0, 0, -KickGrabState.DetentionDist)
                end
                
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
                        local rCreate = CreateGrabLine
                        local rExtend = ExtendGrabLine
                        pallet.CFrame = targetHrp.CFrame * CFrame.new(0, 2, 0) 
                        if rCreate then rCreate:FireServer(pallet, pallet.CFrame) end
                        if rExtend then rExtend:FireServer(25) end
                        if rOwner then rOwner:FireServer(pallet, pallet.CFrame) end
                        isPalletOwned = true
                        task.wait(0.1) 
                    else
                        local currentTime = tick()
                        local timeSinceStrike = currentTime - lastStrikeTime
                        local targetPos
                        if timeSinceStrike > 2.0 then
                            targetPos = targetHrp.CFrame 
                            pallet.AssemblyLinearVelocity = Vector3.new(0, 400, 0)
                            pallet.AssemblyAngularVelocity = Vector3.new(1000, 1000, 1000)
                            if timeSinceStrike > 2.15 then lastStrikeTime = currentTime end
                        else
                            local angle = currentTime * 15
                            targetPos = targetHrp.CFrame * CFrame.new(math.cos(angle)*100, 50, math.sin(angle)*100)
                            pallet.AssemblyLinearVelocity = Vector3.zero
                            pallet.AssemblyAngularVelocity = Vector3.new(100, 100, 100)
                        end
                        pallet.CFrame = targetPos
                    end
                end
            end
        end
        RunService.Heartbeat:Wait()
    end
end

-- =============================================
-- [ SnowBall 루프 함수 ]
-- =============================================
local function ExecuteSnowballLoop()
    while KickGrabState.SnowBallLooping do
        local myHrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
        local targetChar = KickGrabState.Target and KickGrabState.Target.Character
        local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        
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
-- [ 원본 루프그랩 함수 ]
-- =============================================
local AntiStruggleGrabT = false
local antiStruggleThread = nil

local function AntiStruggleGrabF()
    if antiStruggleThread then
        task.cancel(antiStruggleThread)
        antiStruggleThread = nil
    end

    if not AntiStruggleGrabT then return end

    antiStruggleThread = task.spawn(function()
        while AntiStruggleGrabT do
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
                for _, pl in ipairs(Players:GetPlayers()) do
                    if pl.Character and part1:IsDescendantOf(pl.Character) then
                        ownerPlayer = pl
                        break
                    end
                end

                while AntiStruggleGrabT and workspace:FindFirstChild("GrabParts") do
                    if ownerPlayer then
                        local tgtTorso = ownerPlayer.Character and ownerPlayer.Character:FindFirstChild("HumanoidRootPart")
                        local myTorso = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")

                        if tgtTorso and myTorso then
                            pcall(function()
                                SetNetworkOwner:FireServer(tgtTorso, CFrame.lookAt(myTorso.Position, tgtTorso.Position))
                            end)
                        end
                    else
                        if part1 and part1.Parent then
                            local myTorso = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                            if myTorso then
                                pcall(function()
                                    SetNetworkOwner:FireServer(part1, CFrame.lookAt(myTorso.Position, part1.Position))
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
end

-- =============================================
-- [ 초고속 안티그랩 함수 ]
-- =============================================
local antiGrabConn = nil
local isAntiGrabEnabled = false

local function AntiGrabF(enable)
    if antiGrabConn then
        antiGrabConn:Disconnect()
        antiGrabConn = nil
    end

    if not enable then return end

    antiGrabConn = RunService.RenderStepped:Connect(function()
        local char = plr.Character
        if not char then return end

        local isHeld = plr:FindFirstChild("IsHeld")
        if not isHeld then return end

        local head = char:FindFirstChild("Head")
        local POR = head and head:FindFirstChild("PartOwner")
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if isHeld.Value == true or (POR and POR.Value ~= "") then
            pcall(function() Struggle:FireServer() end)
            
            local grabParts = Workspace:FindFirstChild("GrabParts")
            if grabParts then
                for _, part in ipairs(grabParts:GetChildren()) do
                    if part.Name == "GrabPart" then
                        local weld = part:FindFirstChildOfClass("WeldConstraint")
                        if weld and weld.Part1 and weld.Part1:IsDescendantOf(char) then
                            pcall(function() DestroyGrabLine:FireServer(weld.Part1) end)
                            if hrp then pcall(function() SetNetworkOwner:FireServer(hrp) end) end
                            break
                        end
                    end
                end
            end
        end
    end)
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
local blobLoopThread = nil
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
-- [ 수정된 블롭 공격 함수 (원거리 TP 추가) ]
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
                local myChar = plr.Character
                local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                
                if myHrp then
                    local distance = (myHrp.Position - hrp.Position).Magnitude
                    if distance > 30 then
                        TP(player)
                        task.wait(0.1)
                    end
                end
                
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
-- [ 수정된 블롭 자동 킥 함수 (원거리 TP 추가) ]
-- =============================================
local function BlobLoopKick()
    UpdateCurrentBlobman()
    if not currentBlobS then
        Rayfield:Notify({Title = "블롭", Content = "블롭을 타고 있어야 합니다", Duration = 2})
        return
    end
    
    if blobLoopThread then
        task.cancel(blobLoopThread)
        blobLoopThread = nil
    end
    
    blobLoopThread = task.spawn(function()
        while blobLoopT do
            for _, targetName in ipairs(playersInLoop1V) do
                if not blobLoopT then break end
                
                local player = Players:FindFirstChild(targetName)
                if not player then continue end
                
                if PPs and PPs:FindFirstChild(targetName) then continue end
                if inv and inv:FindFirstChild(targetName) then continue end
                
                local character = player.Character
                if not character then continue end
                
                local hrp = character:FindFirstChild("HumanoidRootPart")
                if not hrp then continue end
                
                if hrp.Massless == true then continue end
                
                local humanoid = character:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local myChar = plr.Character
                    local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                    
                    if myHrp then
                        local distance = (myHrp.Position - hrp.Position).Magnitude
                        if distance > 30 then
                            TP(player)
                            task.wait(0.1)
                        end
                    end
                    
                    local head = character:FindFirstChild("Head")
                    if head then
                        local tpRunning = true
                        local myChar = plr.Character
                        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
                        local originCF = myHrp and myHrp.CFrame
                        
                        local tpThread = task.spawn(function()
                            while tpRunning do
                                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and myHrp then
                                    local targetHRP = player.Character.HumanoidRootPart
                                    local ping = plr:GetNetworkPing()
                                    local offset = targetHRP.Position + (targetHRP.Velocity * (ping + 0.15))
                                    myHrp.CFrame = CFrame.new(offset) * targetHRP.CFrame.Rotation
                                end
                                task.wait()
                            end
                        end)
                        
                        for _ = 1, 30 do
                            if not blobLoopT then break end
                            pcall(function()
                                SetNetworkOwner:FireServer(head, head.CFrame)
                            end)
                            local ownerTag = head:FindFirstChild("PartOwner")
                            if ownerTag and ownerTag:IsA("StringValue") and ownerTag.Value == plr.Name then
                                break
                            end
                            task.wait(0.1)
                        end
                        
                        tpRunning = false
                        task.cancel(tpThread)
                        
                        pcall(function()
                            DestroyGrabLine:FireServer(head, head.CFrame)
                        end)
                        
                        if myHrp then
                            hrp.CFrame = CFrame.new(myHrp.CFrame.X, myHrp.CFrame.Y + 50, myHrp.CFrame.Z)
                            myHrp.CFrame = hrp.CFrame
                        end
                        
                        BlobMassless(currentBlobS, hrp, "Right")
                        
                        if originCF and myHrp then
                            myHrp.CFrame = originCF
                        end
                    end
                end
                task.wait(0.1)
            end
            task.wait(0.3)
        end
    end)
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
        Rayfield:Notify({Title = "오류", Content = "FoodBread 생성 실패", Duration = 2})
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
-- [ Rayfield UI 설정 ]
-- =============================================
local Window = Rayfield:CreateWindow({
    Name = "FTAP 올인원 (방어 기능 통합)",
    LoadingTitle = "킥그랩 + 안티불 + 안티폭발 + 안티페인트 + 안티보이드",
    ConfigurationSaving = { Enabled = false }
})

-- 탭 생성
local MainTab = Window:CreateTab("메인", 4483362458)
local BlobTab = Window:CreateTab("블롭", 4483362458)
local GrabTab = Window:CreateTab("그랩", 4483362458)
local DefenseTab = Window:CreateTab("🛡️ 방어", 4483362458)
local AuraTab = Window:CreateTab("아우라", 4483362458)
local TargetTab = Window:CreateTab("킬 플레이어 정하기", 4483362458)
local NotifyTab = Window:CreateTab("🔔 알림", 4483362458)
local KickGrabTab = Window:CreateTab("👢 킥그랩", 4483362458)
local SettingsTab = Window:CreateTab("설정", 4483362458)

-- =============================================
-- [ 메인 탭 ]
-- =============================================
MainTab:CreateSection("🛡️ 기본 방어")

local AntiGrabToggle = MainTab:CreateToggle({
    Name = "⚡ 초고속 Anti-Grab",
    CurrentValue = false,
    Callback = function(Value)
        isAntiGrabEnabled = Value
        AntiGrabF(Value)
    end
})

MainTab:CreateButton({
    Name = "🔓 즉시 해제",
    Callback = ManualRelease
})

local PcldViewToggle = MainTab:CreateToggle({
    Name = "👁️ PCLD 보이게",
    CurrentValue = false,
    Callback = function(Value)
        pcldViewEnabled = Value
        togglePcldView(Value)
    end
})

local BarrierNoclipToggle = MainTab:CreateToggle({
    Name = "🧱 Barrier Noclip",
    CurrentValue = false,
    Callback = function(Value)
        BarrierCanCollideT = Value
        BarrierCanCollideF()
    end
})

MainTab:CreateButton({
    Name = "💥 집 베리어 부수기",
    Callback = PlotBarrierDelete
})

local AntiPCLDToggle = MainTab:CreateToggle({
    Name = "🛡️ Anti-Kick (PCLD 방어)",
    CurrentValue = false,
    Callback = function(Value)
        AntiPCLDEnabled = Value
        if Value then
            setupAntiPCLD()
            Rayfield:Notify({Title = "안티킥", Content = "활성화 - PCLD 감지 시 자동 방어", Duration = 2})
        else
            Rayfield:Notify({Title = "안티킥", Content = "비활성화", Duration = 2})
        end
    end
})

MainTab:CreateSection("📊 상태")

local StatusLabel = MainTab:CreateLabel("상태: 확인 중...", 4483362458)

spawn(function()
    while task.wait(0.5) do
        local char = plr.Character
        local isHeld = plr:FindFirstChild("IsHeld")
        local head = char and char:FindFirstChild("Head")
        local por = head and head:FindFirstChild("PartOwner")
        
        if isHeld and isHeld.Value then
            StatusLabel:Set("상태: 🟡 잡힘")
        elseif por and por.Value ~= "" then
            StatusLabel:Set("상태: 🟠 오너쉽 있음 (" .. por.Value .. ")")
        else
            StatusLabel:Set("상태: 🟢 안전")
        end
    end
end)

-- =============================================
-- [ 블롭 탭 ]
-- =============================================
BlobTab:CreateSection("🦠 블롭 공격 대상")

local BlobTargetDropdown = BlobTab:CreateDropdown({
    Name = "List",
    Options = playersInLoop1V,
    CurrentOption = {"OPEN"},
    MultipleOptions = true,
    Flag = "BlobTargetDropdown",
    Callback = function(Options)
        playersInLoop1V = Options
    end
})

BlobTab:CreateInput({
    Name = "Add (자동완성)",
    PlaceholderText = "닉네임 일부 입력",
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
    Name = "💀 블롭 킬 (Grab+Release) [TP 자동]",
    Callback = function() BlobAttackAll("kill") end
})

BlobTab:CreateButton({
    Name = "⚡ 블롭 매스리스 [TP 자동]",
    Callback = function() BlobAttackAll("massless") end
})

BlobTab:CreateButton({
    Name = "🤚 블롭 잡기 (Grab) [TP 자동]",
    Callback = function() BlobAttackAll("grab") end
})

BlobTab:CreateButton({
    Name = "✋ 블롭 놓기 (Release) [TP 자동]",
    Callback = function() BlobAttackAll("release") end
})

BlobTab:CreateButton({
    Name = "⬇️ 블롭 드롭 (Drop) [TP 자동]",
    Callback = function() BlobAttackAll("drop") end
})

BlobTab:CreateSection("🔄 블롭 자동 킥")

local BlobLoopKickToggle = BlobTab:CreateToggle({
    Name = "🔄 블롭 자동 킥 (루프) [TP 자동]",
    CurrentValue = false,
    Callback = function(Value)
        blobLoopT = Value
        if blobLoopT then
            BlobLoopKick()
            Rayfield:Notify({Title = "블롭 킥", Content = "자동 루프 시작 (원거리 TP)", Duration = 2})
        else
            if blobLoopThread then
                task.cancel(blobLoopThread)
                blobLoopThread = nil
            end
            Rayfield:Notify({Title = "블롭 킥", Content = "자동 루프 종료", Duration = 2})
        end
    end
})

BlobTab:CreateSection("✨ 구찌 설정")

local AutoGucciToggle = BlobTab:CreateToggle({
    Name = "Auto-Gucci (y=9999)",
    CurrentValue = false,
    Callback = function(Value)
        AutoGucciT = Value
        if AutoGucciT then
            task.spawn(AutoGucciF)
            Rayfield:Notify({Title = "Gucci", Content = "활성화 (y=9999)", Duration = 2})
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
    Name = "🔄 Loop Grab (raw 기반)",
    CurrentValue = false,
    Callback = function(Value)
        AntiStruggleGrabT = Value
        AntiStruggleGrabF()
        Rayfield:Notify({Title = "Loop Grab", Content = Value and "활성화" or "비활성화", Duration = 2})
    end
})

-- =============================================
-- [ 방어 탭 (안티보이드 추가) ]
-- =============================================
DefenseTab:CreateSection("🌌 보이드 방어")

local AntiVoidToggle = DefenseTab:CreateToggle({
    Name = "🌌 Anti-Void (보이드 방지)",
    CurrentValue = true,
    Callback = function(Value)
        AntiVoidT = Value
        AntiVoidF(Value)
        Rayfield:Notify({Title = "안티보이드", Content = Value and "활성화 (높이 -50000)" or "비활성화", Duration = 2})
    end
})
AntiVoidToggle:Set(true)

DefenseTab:CreateSection("🔥 화염 방어")

local AntiBurnToggle = DefenseTab:CreateToggle({
    Name = "🔥 Anti-Burn (불 방어)",
    CurrentValue = false,
    Callback = function(Value)
        AntiBurnV = Value
        AntiBurn()
        Rayfield:Notify({Title = "안티불", Content = Value and "활성화 (시야개선)" or "비활성화", Duration = 2})
    end
})

DefenseTab:CreateSection("💥 폭발 방어")

local AntiExplodeToggle = DefenseTab:CreateToggle({
    Name = "💥 Anti-Explosion (폭발 방어)",
    CurrentValue = false,
    Callback = function(Value)
        AntiExplosionT = Value
        if Value then
            AntiExplosionF()
            Rayfield:Notify({Title = "안티폭발", Content = "활성화", Duration = 2})
        else
            if AntiExplosionC then AntiExplosionC:Disconnect() end
            if AntiExplosionH then AntiExplosionH:Disconnect() end
            Rayfield:Notify({Title = "안티폭발", Content = "비활성화", Duration = 2})
        end
    end
})

DefenseTab:CreateSection("🎨 페인트 방어")

local AntiPaintToggle = DefenseTab:CreateToggle({
    Name = "🎨 Anti-Paint (페인트 방어)",
    CurrentValue = false,
    Callback = function(Value)
        AntiPaintT = Value
        AntiPaintF()
        Rayfield:Notify({Title = "안티페인트", Content = Value and "활성화" or "비활성화", Duration = 2})
    end
})

DefenseTab:CreateSection("📋 방어 상태")

local VoidStatus = DefenseTab:CreateLabel("🌌 보이드 방어: 켜짐", 4483362458)
local BurnStatus = DefenseTab:CreateLabel("🔥 불 방어: 꺼짐", 4483362458)
local ExplodeStatus = DefenseTab:CreateLabel("💥 폭발 방어: 꺼짐", 4483362458)
local PaintStatus = DefenseTab:CreateLabel("🎨 페인트 방어: 꺼짐", 4483362458)

spawn(function()
    while task.wait(0.5) do
        VoidStatus:Set("🌌 보이드 방어: " .. (AntiVoidT and "켜짐" or "꺼짐"))
        BurnStatus:Set("🔥 불 방어: " .. (AntiBurnV and "켜짐" or "꺼짐"))
        ExplodeStatus:Set("💥 폭발 방어: " .. (AntiExplosionT and "켜짐" or "꺼짐"))
        PaintStatus:Set("🎨 페인트 방어: " .. (AntiPaintT and "켜짐" or "꺼짐"))
    end
end)

-- =============================================
-- [ 아우라 탭 ]
-- =============================================
AuraTab:CreateSection("🌀 안티 스티키 아우라")

local AntiStickyAuraToggle = AuraTab:CreateToggle({
    Name = "Anti-Sticky Aura",
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
-- [ 킥그랩 탭 ]
-- =============================================
KickGrabTab:CreateSection("🎯 대상 선택")

local TargetList = {}
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= plr then
        table.insert(TargetList, player.Name)
    end
end

local TargetDropdown = KickGrabTab:CreateDropdown({
    Name = "대상 선택",
    Options = TargetList,
    CurrentOption = {"선택하세요"},
    MultipleOptions = false,
    Callback = function(Options)
        local targetName = Options[1]
        if targetName and targetName ~= "선택하세요" then
            KickGrabState.Target = Players:FindFirstChild(targetName)
            Rayfield:Notify({Title = "킥그랩", Content = "대상: " .. targetName, Duration = 2})
        end
    end
})

KickGrabTab:CreateInput({
    Name = "대상 입력 (자동완성)",
    PlaceholderText = "닉네임 일부 입력",
    RemoveTextAfterFocusLost = true,
    Callback = function(Value)
        if not Value or Value == "" then return end
        local target = findPlayerByPartialName(Value)
        if target then
            KickGrabState.Target = target
            Rayfield:Notify({Title = "킥그랩", Content = "대상: " .. target.Name, Duration = 2})
        else
            Rayfield:Notify({Title = "오류", Content = "플레이어를 찾을 수 없음", Duration = 2})
        end
    end
})

KickGrabTab:CreateSection("⚙️ 모드 설정")

local ModeDropdown = KickGrabTab:CreateDropdown({
    Name = "모드 선택",
    Options = {"Camera", "Up", "Down"},
    CurrentOption = {"Camera"},
    MultipleOptions = false,
    Callback = function(Options)
        KickGrabState.Mode = Options[1]
        Rayfield:Notify({Title = "킥그랩", Content = "모드: " .. Options[1], Duration = 2})
    end
})

local DistInput = KickGrabTab:CreateInput({
    Name = "Camera 거리",
    CurrentValue = "19",
    PlaceholderText = "거리 (기본 19)",
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
    Name = "👢 Kick Grab",
    CurrentValue = false,
    Callback = function(Value)
        if Value and not KickGrabState.Target then
            Rayfield:Notify({Title = "오류", Content = "대상을 먼저 선택하세요", Duration = 2})
            KickGrabToggle:Set(false)
            return
        end
        KickGrabState.Looping = Value
        if Value then
            task.spawn(ExecuteKickGrabLoop)
            Rayfield:Notify({Title = "킥그랩", Content = "활성화 (원거리 TP)", Duration = 2})
        else
            Rayfield:Notify({Title = "킥그랩", Content = "비활성화", Duration = 2})
        end
    end
})

local AutoRagdollToggle = KickGrabTab:CreateToggle({
    Name = "🔄 Auto Ragdoll",
    CurrentValue = false,
    Callback = function(Value)
        KickGrabState.AutoRagdoll = Value
        Rayfield:Notify({Title = "오토 래그돌", Content = Value and "활성화" or "비활성화", Duration = 2})
    end
})

local SnowBallToggle = KickGrabTab:CreateToggle({
    Name = "❄️ SnowBall Ragdoll",
    CurrentValue = false,
    Callback = function(Value)
        if Value and not KickGrabState.Target then
            Rayfield:Notify({Title = "오류", Content = "대상을 먼저 선택하세요", Duration = 2})
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
-- [ 킬 플레이어 정하기 탭 ]
-- =============================================
TargetTab:CreateSection("🎯 킬 플레이어 정하기")

local TargetListDropdown = TargetTab:CreateDropdown({
    Name = "Target List",
    Options = targetList,
    CurrentOption = {"OPEN"},
    MultipleOptions = true,
    Callback = function(Options)
        targetList = Options
    end
})

TargetTab:CreateInput({
    Name = "Add (자동완성)",
    PlaceholderText = "닉네임 일부 입력",
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
    Name = "💀 Kill",
    Callback = function() manualKill("kill") end
})

TargetTab:CreateButton({
    Name = "👢 Kick",
    Callback = function() manualKill("kick") end
})

-- 팔다리 제거 드롭다운
local DeletePartDropdown = TargetTab:CreateDropdown({
    Name = "🦴 제거할 부위 선택",
    Options = {"Arm/Leg", "Legs", "Arms"},
    CurrentOption = {"Arm/Leg"},
    Callback = function(Options)
        selectedDeletePart = Options[1]
    end
})

TargetTab:CreateButton({
    Name = "🦴 선택된 대상 팔다리 제거",
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
    Name = "🎯 현재 그랩한 대상 팔다리 제거",
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
    Name = "IY UI 숨기기",
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
AntiVoidF(true)  -- 안티보이드 자동 실행

bringRayfieldToFront()

Rayfield:Notify({
    Title = "🚀 로드 완료",
    Content = "방어 탭에 안티보이드 추가됨 | Z키 TP",
    Duration = 5
})
