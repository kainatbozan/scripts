for _, v in pairs(game:GetService("CoreGui"):GetChildren()) do
    if v.Name == "Rayfield" then v:Destroy() end
end

-- // GLOBAL AYARLAR
_G.OrbFarm = false
_G.AutoClick = false
_G.AutoRebirth = false
_G.AutoCrate = false
_G.SelectedCrateType = "skin" -- Varsayılan olarak kostüm seçili
_G.tpspeed = 0.4 

local plr = game.Players.LocalPlayer
local ts = game:GetService("TweenService")
local rs = game:GetService("ReplicatedStorage")
local hrp = plr.Character and plr.Character:WaitForChild("HumanoidRootPart", 10)

local alive = false
local function oncharadded(character)
    hrp = character:WaitForChild("HumanoidRootPart", 10)
    local human = character:WaitForChild("Humanoid", 10)
    if human then
        alive = true
        human.Died:Connect(function() alive = false end)
    end
end
if plr.Character then oncharadded(plr.Character) end
plr.CharacterAdded:Connect(oncharadded)

-- // RAYFIELD KÜTÜPHANESİNİ YÜKLE
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Giant Simulator",
   Icon = 0,
   LoadingTitle = "Script is loading",
   LoadingSubtitle = "by kainatbozan",
   ShowText = "Rayfield",
   Theme = "Default",
   ToggleUIKeybind = "K",
   DisableRayfieldPrompts = true,
   DisableBuildWarnings = true,
   ConfigurationSaving = { Enabled = false },
   Discord = { Enabled = false },
   KeySystem = false
})

-- // SEKMELER
local MainTab = Window:CreateTab("Main", 4483362458)
local CratesTab = Window:CreateTab("Creates", 4483362458)
local EggsTab = Window:CreateTab("Eggs", 4483362458)
local QuestTab = Window:CreateTab("Quest", 4483362458)

-- // 1. SEKME ELEMANLARI (ANA ÖZELLİKLER)
MainTab:CreateToggle({
   Name = "Orb Farm",
   CurrentValue = false,
   Flag = "OrbToggleV12",
   Callback = function(Value) _G.OrbFarm = Value end,
})

MainTab:CreateToggle({
   Name = "AutoClick(no animation)",
   CurrentValue = false,
   Flag = "ClickToggleV12",
   Callback = function(Value) _G.AutoClick = Value end,
 })

MainTab:CreateToggle({
   Name = "AutoRebirth (need 100 level)",
   CurrentValue = false,
   Flag = "RebirthToggleV12",
   Callback = function(Value) _G.AutoRebirth = Value end,
})

-- // 2. SEKME ELEMANLARI (KILIÇ & KOSTÜM LİSTESİ)
-- // 2. SEKME ELEMANLARI (KILIÇ & KOSTÜM LİSTESİ)
CratesTab:CreateDropdown({
   Name = "Select Crate Type",
   Options = {"Legendary Skin (Kostüm)", "Legendary Weapon (Kılıç)"},
   CurrentOption = {"Legendary Skin (Kostüm)"},
   MultipleOptions = false,
   Flag = "CrateTypeDropdownV12",
   Callback = function(Option)
      -- Listeden seçilene göre sunucuya gidecek parametreyi değiştiriyoruz
      -- İsimler artık menüdekiyle birebir aynı!
      if Option[1] == "Legendary Skin (Kostüm)" then
          _G.SelectedCrateType = "skin"
      elseif Option[1] == "Legendary Weapon (Kılıç)" then
          _G.SelectedCrateType = "weapon"
      end
   end,
})

CratesTab:CreateToggle({
   Name = "Open Chest",
   CurrentValue = false,
   Flag = "CrateToggleV12",
   Callback = function(Value) _G.AutoCrate = Value end,
})


local ButunSandiklar = {
    "t1_skin_crate", 
    "t2_skin_crate",
    "t3_skin_crate", 
    "t1_wpn_crate", 
    "t2_wpn_crate",
    "t3_wpn_crate"
}

CratesTab:CreateButton({
   Name = "Sell All Create",
   Callback = function()
      for _, tur in pairs(ButunSandiklar) do
          pcall(function()
              local args = { tur }
              game:GetService("ReplicatedStorage"):WaitForChild("Aero"):WaitForChild("AeroRemoteServices"):WaitForChild("GameService"):WaitForChild("SellAllCratesRequest"):InvokeServer(unpack(args))
          end)
          task.wait(0.1)
      end
   end,
})

EggsTab:CreateToggle({
   Name = "Auto Open Event Eggs",
   CurrentValue = false,
   Flag = "EventEggToggle",
   Callback = function(Value)
      _G.AutoEventEggs = Value
   end,
})

EggsTab:CreateToggle({
   Name = "Auto Open Artifact Create",
   CurrentValue = false,
   Flag = "EventArtifactToogle",
   Callback = function(Value)
      _G.AutoEventArtifact = Value
   end,
})

QuestTab:CreateToggle({
   Name = "Auto Boss Kill (Demon King)",
   CurrentValue = false,
   Flag = "AutoBossToggleV12",
   Callback = function(Value)
      _G.AutoBoss = Value
      -- Eğer hile kapatılırsa karakterin donmasını anında çözelim
      if not Value and hrp then
          hrp.Anchored = false
      end
   end,
})
------------------------------------------- ARKA PLAN -------------------------------------------

-- animasyonsuz vurus
task.spawn(function()
    while true do
        task.wait(0.01)
        if _G.AutoClick and alive then
            pcall(function()
                local AeroRemotes = rs:FindFirstChild("Aero") and rs.Aero:FindFirstChild("AeroRemoteServices")
                local GameService = AeroRemotes and AeroRemotes:FindFirstChild("GameService")
                if GameService then
                    if GameService:FindFirstChild("WeaponAnimComplete") and GameService:FindFirstChild("WeaponAttackStart") then
                        GameService.WeaponAnimComplete:FireServer()
                        GameService.WeaponAttackStart:FireServer()
                    end
                end
                local combatEvent = rs:FindFirstChild("CombatEvent") or (rs:FindFirstChild("Events") and rs.Events:FindFirstChild("CombatEvent"))
                if combatEvent then combatEvent:FireServer("Attack") end
            end)
        end
    end
end)

-- oto rebirth
task.spawn(function()
    while true do
        task.wait(0.5)
        if _G.AutoRebirth and alive then
            pcall(function()
                local AeroRemotes = rs:FindFirstChild("Aero") and rs.Aero:FindFirstChild("AeroRemoteServices")
                local GameService = AeroRemotes and AeroRemotes:FindFirstChild("GameService")
                if GameService and GameService:FindFirstChild("RebirthRequest") then
                    GameService.RebirthRequest:InvokeServer()
                end
            end)
        end
    end
end)

-- oto sandık açma
task.spawn(function()
    while true do
        task.wait(0.3)
        if _G.AutoCrate then
            pcall(function()
                local AeroRemotes = rs:FindFirstChild("Aero") and rs.Aero:FindFirstChild("AeroRemoteServices")
                local GameService = AeroRemotes and AeroRemotes:FindFirstChild("GameService")
                
                if GameService and GameService:FindFirstChild("OpenLegendaryCrate") then
                    GameService.OpenLegendaryCrate:InvokeServer(_G.SelectedCrateType, 1)
                end
            end)
        end
    end
end)

-- event yumurta
task.spawn(function()
    while true do
        task.wait(0.3)
        if _G.AutoEventEggs then
            pcall(function()
                local args = { 6, 1 }
                game:GetService("ReplicatedStorage"):WaitForChild("Aero"):WaitForChild("AeroRemoteServices"):WaitForChild("GameService"):WaitForChild("OpenPetCrate"):InvokeServer(unpack(args))
            end)
        end
    end
end)

-- Demon boss (Gövdeye Işınlanma + Sabitleme + Vuruş Motoru)
-- // GELİŞMİŞ DİNAMİK BOSS BULUCU (Klasör bağımsız)
local function findDemonKingBoss()
    -- 1. İhtimal: Doğrudan Workspace içinde mi?
    if workspace:FindFirstChild("DemonKing") then return workspace.DemonKing end
    if workspace:FindFirstChild("Demon King") then return workspace["Demon King"] end
    
    -- 2. İhtimal: workspace.NPC klasöründe mi?
    local npcFolder = workspace:FindFirstChild("NPC")
    -- 3. İhtimal: workspace.Scene.NPC klasöründe mi? (Orb farmının olduğu yer)
    if not npcFolder and workspace:FindFirstChild("Scene") then
        npcFolder = workspace.Scene:FindFirstChild("NPC")
    end
    
    if npcFolder then
        if npcFolder:FindFirstChild("DemonKing") then return npcFolder.DemonKing end
        if npcFolder:FindFirstChild("Demon King") then return npcFolder["Demon King"] end
    end
    
    -- 4. İhtimal: Haritadaki tüm modelleri tara (Garantili Son Çare)
    for _, child in ipairs(workspace:GetChildren()) do
        if child:IsA("Model") and (child.Name:match("Demon") or child.Name:match("King")) then
            return child
        end
    end
    return nil
end

-- Demon boss (Dinamik Tarama + Güvenli Işınlanma + Vuruş Motoru)
task.spawn(function()
    local lastLogTime = 0
    while true do
        task.wait(0.1) -- Hızlı tepki vermesi için süreyi düşürdük
        
        if _G.AutoBoss then
            if not alive or not hrp then 
                task.wait(0.5)
                continue 
            end
            
            pcall(function()
                local bossModel = findDemonKingBoss()
                
                if bossModel then
                    local bossHRP = bossModel:FindFirstChild("HumanoidRootPart")
                    local bossHumanoid = bossModel:FindFirstChildOfClass("Humanoid")
                    
                    if bossHRP and bossHumanoid and bossHumanoid.Health > 0 then
                        -- 1. GÜVENLİ IŞINLANMA DIZISI
                        hrp.Anchored = false -- Işınlanırken takılmamak için önce donmayı çöz
                        
                        -- Boss'un kafasının 4 birim yukarısına ışınla (Yere düşmeyi veya bugda kalmayı önler)
                        hrp.CFrame = bossHRP.CFrame * CFrame.new(0, 4, 0)
                        hrp.Velocity = Vector3.new(0, 0, 0) -- Hızlanmayı sıfırla
                        
                        hrp.Anchored = true -- Işınlanma bittiği an havada dondur
                        
                        -- 2. OTOMATİK VURUŞ MOTORU
                        local tool = plr.Character:FindFirstChildOfClass("Tool")
                        if tool then
                            tool:Activate() -- Elindeki kılıcı salla
                            
                            local AeroRemotes = rs:FindFirstChild("Aero") and rs.Aero:FindFirstChild("AeroRemoteServices")
                            local gameService = AeroRemotes and AeroRemotes:FindFirstChild("GameService")
                            
                            if gameService then
                                -- Sunucuya hasar remote'larını sırasıyla gönderiyoruz
                                if gameService:FindFirstChild("WeaponAttackStart") then
                                    gameService.WeaponAttackStart:FireServer()
                                end
                                if gameService:FindFirstChild("MeleeHit") then
                                    gameService.MeleeHit:FireServer(bossHRP)
                                end
                                if gameService:FindFirstChild("WeaponAnimComplete") then
                                    gameService.WeaponAnimComplete:FireServer()
                                end
                            end
                        end
                    else
                        -- Boss ölü canlanmasını bekliyor
                        if hrp.Anchored then hrp.Anchored = false end
                        if tick() - lastLogTime > 5 then
                            print("[Kainatbozan] Boss haritada var ama canlı değil. Doğması bekleniyor...")
                            lastLogTime = tick()
                        end
                    end
                else
                    -- Boss haritada tamamen yoksa karakterin donmasını çöz
                    if hrp.Anchored then hrp.Anchored = false end
                    if tick() - lastLogTime > 5 then
                        warn("[Kainatbozan] Demon King haritanın hiçbir yerinde bulunamadı!")
                        lastLogTime = tick()
                    end
                end
            end)
        else
            -- Menüden hile kapatıldıysa karakterin donmasını anında iptal et
            if hrp and hrp.Anchored then
                hrp.Anchored = false
            end
        end
    end
end)

-- event artifact
task.spawn(function()
    while true do
        task.wait(0.3)
        if _G.AutoEventArtifact then
            pcall(function()
                local args = { 4, 1 }
                game:GetService("ReplicatedStorage"):WaitForChild("Aero"):WaitForChild("AeroRemoteServices"):WaitForChild("GameService"):WaitForChild("OpenArtifactCrate"):InvokeServer(unpack(args))
            end)
        end
    end
end)
-- orba gitmek
local function tweenTo(targetCFrame, speed)
    if not hrp or not alive then return end
    local info = TweenInfo.new(speed, Enum.EasingStyle.Linear)
    local tween = ts:Create(hrp, info, {CFrame = targetCFrame})
    tween:Play()
    tween.Completed:Wait()
end

-- orb kontrol
local function getClosestOrb()
    if not hrp or not alive then return nil end
    local closestOrb = nil
    local shortestDistance = math.huge

    local scene = workspace:FindFirstChild("Scene")
    local orbFolder = scene and (scene:FindFirstChild("ResourceNodes1") or scene:FindFirstChild("ResourceNodes"))
    
    if orbFolder then
        for _, v in ipairs(orbFolder:GetChildren()) do
            if (v:IsA("Part") or v:IsA("MeshPart") or v:IsA("BasePart")) and v:FindFirstChild("Prefab") then
                local distance = (hrp.Position - v.Position).Magnitude
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestOrb = v
                end
            end
        end
    end
    return closestOrb
end

-- orb farm
task.spawn(function()
    while true do
        task.wait(0.1)
        if _G.OrbFarm then
            if not alive then repeat task.wait(1) until alive end
            while _G.OrbFarm and alive do
                local targetOrb = getClosestOrb()
                if not targetOrb or not targetOrb.Parent then break end
                
                tweenTo(targetOrb.CFrame, _G.tpspeed)
                if hrp then hrp.Velocity = Vector3.new(0,0,0) end
                
                local timeout = 0
                while targetOrb and targetOrb.Parent and timeout < 0.15 and alive do
                    task.wait(0.02)
                    timeout = timeout + 0.02
                end
            end
        end
    end
end)

Rayfield:Notify({
   Title = "Giant Sim Script Full Loaded",
   Content = "START HACKING.",
   Duration = 5,
   Image = 4483362458,
})
