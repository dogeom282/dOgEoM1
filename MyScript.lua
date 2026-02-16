-- FTAP (Fling Things and People) 올인원 스크립트 (최종 안정화 버전)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

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
-- [ 동그란 TP 버튼 추가 ]
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

    button.MouseButton1Click:Connect(function()
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
            
            button.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            task.wait(0.2)
            button.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
        end
    end)

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

local plr = Players.LocalPlayer
local rs = ReplicatedStorage

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
-- [ 초고속 안티그랩 ]
-- =============================================
local antiGrabConn = nil
local isAntiGrabEnabled = false

local function AntiGrabF(enable)
    if antiGrabConn then antiGrabConn:Disconnect() end
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
            local grabParts = Workspace:FindFirstChild("GrabParts")
            if grabParts then
                for _, part in ipairs(grabParts:GetChildren()) do
                    if part.Name == "GrabPart" then
                        local weld = part:FindFirstChildOfClass("WeldConstraint")
                        if weld and weld.Part1 and weld.Part1:IsDescendantOf(char) then
                            if DestroyGrabLine then pcall(function() DestroyGrabLine:FireServer(weld.Part1) end) end
                            if hrp and SetNetworkOwner then pcall(function() SetNetworkOwner:FireServer(hrp) end) end
                            break
                        end
                    end
                end
            end
        end
    end)
end

-- =============================================
-- [ 즉시 해제 ]
-- =============================================
local function ManualRelease()
    local char = plr.Character
    if not char then Rayfield:Notify({Title = "오류", Content = "캐릭터 없음", Duration = 2}) return end
    
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
-- [ 안티 스티키 아우라 ]
-- =============================================
local AntiStickyAuraT = false
local AntiStickyAuraThread = nil

local function AntiStickyAuraF()
    if AntiStickyAuraThread then task.cancel(AntiStickyAuraThread) end
    if not AntiStickyAuraT then return end

    local targetNames = {"NinjaKunai", "NinjaShuriken", "NinjaKatana", "ToolCleaver", "ToolDiggingForkRusty", "ToolPencil", "ToolPickaxe"}

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
    if AntiBurnThread then task.cancel(AntiBurnThread) end
    if not AntiBurnV then return end

    AntiBurnThread = task.spawn(function()
        local EP = nil
        for _, child in ipairs(Workspace:GetDescendants()) do
            if child.Name == "ExtinguishPart" and child:IsA("BasePart") then
                EP = child
                break
            end
        end
        if not EP then return end

        while AntiBurnV do
            local char = plr.Character
            if char then
                local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
                if head then
                    EP.Transparency = 1
                    EP.Size = Vector3.new(0, 0, 0)
                    EP.CFrame = head.CFrame * CFrame.new(0, 10, 0)
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
    if AntiExplosionC then AntiExplosionC:Disconnect() end
    if not AntiExplosionT then return end

    local char = plr.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    AntiExplosionC = Workspace.ChildAdded:Connect(function(model)
        if not AntiExplosionT then return end
        if model:IsA("BasePart") and (model.Position - hrp.Position).Magnitude <= 25 then
            hrp.Anchored = true
            task.wait(0.05)
            hrp.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
            hrp.Anchored = false
        end
    end)
end

-- =============================================
-- [ 안티 페인트 ]
-- =============================================
local AntiPaintT = false
local AntiPaintThread = nil

local function AntiPaintF()
    if AntiPaintThread then task.cancel(AntiPaintThread) end
    if not AntiPaintT then return end

    local paintParts = {"PaintDrop", "PaintSplat", "PaintBall", "PaintBucket", "PaintProjectile", "PaintSplash"}

    AntiPaintThread = task.spawn(function()
        while AntiPaintT do
            local char = plr.Character
            if char then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") then
                        local isPaint = false
                        for _, name in ipairs(paintParts) do
                            if obj.Name:find(name) then isPaint = true break end
                        end
                        if isPaint and char:FindFirstChild("HumanoidRootPart") then
                            local hrp = char.HumanoidRootPart
                            if (obj.Position - hrp.Position).Magnitude < 20 then
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
-- [ 루프그랩 ]
-- =============================================
local LoopGrabT = false
local LoopGrabThread = nil

local function LoopGrabF()
    if LoopGrabThread then task.cancel(LoopGrabThread) end
    if not LoopGrabT then return end

    LoopGrabThread = task.spawn(function()
        while LoopGrabT do
            local grabParts = workspace:FindFirstChild("GrabParts")
            if grabParts then
                for _, part in ipairs(grabParts:GetChildren()) do
                    if part.Name == "GrabPart" then
                        local weld = part:FindFirstChildOfClass("WeldConstraint")
                        if weld and weld.Part1 then
                            for _, player in ipairs(Players:GetPlayers()) do
                                if player ~= plr and player.Character and weld.Part1:IsDescendantOf(player.Character) then
                                    local targetHRP = player.Character:FindFirstChild("HumanoidRootPart")
                                    local myHRP = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                                    if targetHRP and myHRP and SetNetworkOwner then
                                        pcall(function() SetNetworkOwner:FireServer(targetHRP, CFrame.lookAt(myHRP.Position, targetHRP.Position)) end)
                                    end
                                    break
                                end
                            end
                        end
                    end
                end
            end
            task.wait(0.1)
        end
    end)
end

-- =============================================
-- [ 킥그랩 ]
-- =============================================
local KickGrabTarget = nil
local KickGrabLooping = false
local KickGrabThread = nil

local function ExecuteKickGrabLoop()
    while KickGrabLooping do
        local myChar = plr.Character
        local targetChar = KickGrabTarget and KickGrabTarget.Character
        local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
        local targetHrp = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
        local cam = Workspace.CurrentCamera

        if myHrp and targetHrp and cam then
            local rOwner = SetNetworkOwner
            local rDestroy = DestroyGrabLine
            
            if not rOwner or not rDestroy then
                task.wait(0.1)
                goto continue
            end
            
            local distance = (myHrp.Position - targetHrp.Position).Magnitude

            if distance > 30 then
                local ping = plr:GetNetworkPing()
                local offset = targetHrp.Position + (targetHrp.Velocity * (ping + 0.15))
                myHrp.CFrame = CFrame.new(offset) * targetHrp.CFrame.Rotation
                task.wait(0.1)
            end

            local detentionPos = cam.CFrame * CFrame.new(0, 0, -19)
            
            pcall(function() rOwner:FireServer(targetHrp, detentionPos) end)
            targetHrp.CFrame = detentionPos
            pcall(function() rDestroy:FireServer(targetHrp) end)
        end
        ::continue::
        RunService.Heartbeat:Wait()
    end
end

-- =============================================
-- [ 팔다리 제거 ]
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
-- [ 가장 가까운 플레이어 ]
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
-- [ 수동 킬 ]
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
                if SetNetworkOwner then pcall(function() SetNetworkOwner:FireServer(torso, torso.CFrame) end) end
                if mode == "kill" then
                    local FallenY = Workspace.FallenPartsDestroyHeight
                    local targetY = (FallenY <= -50000 and -49999) or -100
                    torso.CFrame = CFrame.new(99999, targetY, 99999)
                else
                    torso.CFrame = CFrame.new(99999, 99999, 99999)
                end
                count = count + 1
            end
        end
        task.wait(0.1)
    end
    
    Rayfield:Notify({Title = mode == "kill" and "Kill" or "Kick", Content = count .. "명 처리", Duration = 2})
end

-- =============================================
-- [ Rayfield UI ]
-- =============================================
local Window = Rayfield:CreateWindow({
    Name = "FTAP 올인원 (최종)",
    LoadingTitle = "킥그랩 + 안티불 + 안티폭발 + 안티스티키 + 안티킥 + 블롭TP + 시선TP + 안티페인트",
    ConfigurationSaving = { Enabled = false }
})

-- 탭 생성
local MainTab = Window:CreateTab("메인", 4483362458)
local AuraTab = Window:CreateTab("아우라", 4483362458)
local SecurityTab = Window:CreateTab("보안", 4483362458)
local TargetTab = Window:CreateTab("대상", 4483362458)
local GrabTab = Window:CreateTab("그랩", 4483362458)

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
            StatusLabel:Set("상태: 🟠 오너쉽 있음")
        else
            StatusLabel:Set("상태: 🟢 안전")
        end
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
-- [ 보안 탭 ]
-- =============================================
SecurityTab:CreateSection("🔰 방어 설정")

local AntiBurnToggle = SecurityTab:CreateToggle({
    Name = "🔥 Anti-Burn",
    CurrentValue = false,
    Callback = function(Value)
        AntiBurnV = Value
        AntiBurn()
        Rayfield:Notify({Title = "안티 불", Content = Value and "활성화" or "비활성화", Duration = 2})
    end
})

local AntiExplodeToggle = SecurityTab:CreateToggle({
    Name = "💥 Anti-Explosion",
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
    Name = "🎨 Anti-Paint",
    CurrentValue = false,
    Callback = function(Value)
        AntiPaintT = Value
        AntiPaintF()
        Rayfield:Notify({Title = "안티 페인트", Content = Value and "활성화" or "비활성화", Duration = 2})
    end
})

-- =============================================
-- [ 대상 탭 ]
-- =============================================
TargetTab:CreateSection("🎯 대상 선택")

local TargetDropdown = TargetTab:CreateDropdown({
    Name = "대상 목록",
    Options = targetList,
    CurrentOption = {"OPEN"},
    MultipleOptions = true,
    Callback = function(Options)
        targetList = Options
    end
})

TargetTab:CreateInput({
    Name = "추가 (자동완성)",
    PlaceholderText = "닉네임 입력",
    RemoveTextAfterFocusLost = true,
    Callback = function(Value)
        if Value == "" then return end
        local target = findPlayerByPartialName(Value)
        if target then
            for _, name in ipairs(targetList) do
                if name == target.Name then return end
            end
            table.insert(targetList, target.Name)
            TargetDropdown:Refresh(targetList, true)
            Rayfield:Notify({Title = "추가됨", Content = target.Name, Duration = 1})
        end
    end
})

TargetTab:CreateInput({
    Name = "제거",
    PlaceholderText = "닉네임 입력",
    RemoveTextAfterFocusLost = true,
    Callback = function(Value)
        if Value == "" then return end
        for i, name in ipairs(targetList) do
            if name:lower() == Value:lower() then
                table.remove(targetList, i)
                TargetDropdown:Refresh(targetList, true)
                Rayfield:Notify({Title = "제거됨", Content = name, Duration = 1})
                return
            end
        end
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

-- 팔다리 제거
local DeletePartDropdown = TargetTab:CreateDropdown({
    Name = "🦴 제거 부위",
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
        for _, name in ipairs(targetList) do
            local target = Players:FindFirstChild(name)
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
    Name = "🎯 현재 그랩한 대상 제거",
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
-- [ 그랩 탭 ]
-- =============================================
GrabTab:CreateSection("🔄 그랩 공격")

local LoopGrabToggle = GrabTab:CreateToggle({
    Name = "Loop Grab",
    CurrentValue = false,
    Callback = function(Value)
        LoopGrabT = Value
        LoopGrabF()
        Rayfield:Notify({Title = "Loop Grab", Content = Value and "활성화" or "비활성화", Duration = 2})
    end
})

-- 킥그랩 대상 선택
local KickGrabTargetList = {}
for _, player in ipairs(Players:GetPlayers()) do
    if player ~= plr then table.insert(KickGrabTargetList, player.Name) end
end

local KickGrabTargetDropdown = GrabTab:CreateDropdown({
    Name = "킥그랩 대상",
    Options = KickGrabTargetList,
    CurrentOption = {"선택하세요"},
    MultipleOptions = false,
    Callback = function(Options)
        local name = Options[1]
        if name and name ~= "선택하세요" then
            KickGrabTarget = Players:FindFirstChild(name)
            Rayfield:Notify({Title = "킥그랩", Content = "대상: " .. name, Duration = 2})
        end
    end
})

local KickGrabToggle = GrabTab:CreateToggle({
    Name = "👢 Kick Grab",
    CurrentValue = false,
    Callback = function(Value)
        if Value and not KickGrabTarget then
            Rayfield:Notify({Title = "오류", Content = "대상을 선택하세요", Duration = 2})
            KickGrabToggle:Set(false)
            return
        end
        KickGrabLooping = Value
        if Value then
            if KickGrabThread then task.cancel(KickGrabThread) end
            KickGrabThread = task.spawn(ExecuteKickGrabLoop)
            Rayfield:Notify({Title = "킥그랩", Content = "활성화", Duration = 2})
        else
            if KickGrabThread then task.cancel(KickGrabThread) end
            Rayfield:Notify({Title = "킥그랩", Content = "비활성화", Duration = 2})
        end
    end
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

bringRayfieldToFront()

Rayfield:Notify({
    Title = "🚀 로드 완료",
    Content = "모든 기능 포함 | TP 버튼 화면 하단",
    Duration = 5
})
