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

------------------------------------------- ARKA PLAN -------------------------------------------

-- // [Kainatbozan] DERİN BOSS BULUCU FONKSİYONU
local function derindenBossBul()
    for _, v in ipairs(workspace:GetDescendants()) do
        if v:IsA("Model") and (v.Name:lower():match("demon") or v.Name:lower():match("king")) then
            local hum = v:FindFirstChildOfClass("Humanoid")
            local bHrp = v:FindFirstChild("HumanoidRootPart")
            if hum and bHrp and hum.Health > 0 then
                return v, bHrp, hum
            end
        end
    end
    return nil, nil, nil
end


-- // %100 MANUEL VURUŞ İÇİN POZİSYONLAMA VE OTO-KILIÇ MOTORU
task.spawn(function()
    while true do
        task.wait(0.02) -- Boss hareket ettikçe anlık olarak ona yapışmak için çok seri döngü
        
        if _G.AutoBoss then
            local karakter = plr.Character
            local benimHrp = karakter and karakter:FindFirstChild("HumanoidRootPart")
            local benimHuman = karakter and karakter:FindFirstChildOfClass("Humanoid")
            
            if karakter and benimHrp and benimHuman and benimHuman.Health > 0 then
                pcall(function()
                    local bossModel, bossHRP, bossHumanoid = derindenBossBul()
                    
                    if bossModel and bossHRP and bossHumanoid then
                        -- 1. OTO-KILIÇ KUŞANMA (Tıklarken elinde kılıç olsun diye çantadan otomatik çeker)
                        local tool = karakter:FindFirstChildOfClass("Tool")
                        if not tool then
                            local sirtindakiKilic = plr.Backpack:FindFirstChildOfClass("Tool")
                            if sirtindakiKilic then
                                sirtindakiKilic.Parent = karakter
                            end
                        end
                        
                        -- 2. %100 VURUŞ POZİSYONU (Tam menzil, boss'a dönük ve çakılı)
                        benimHrp.Anchored = false -- Pozisyon ayarlanırken glitch olmasın diye anlık çözüyoruz
                        
                        -- Boss'un 3 birim önünde, 1 birim yukarısında konumlan ve yüzünü direkt boss'un kalbine çevir
                        local hedefKonum = bossHRP.Position + (bossHRP.CFrame.LookVector * 3) + Vector3.new(0, 1, 0)
                        benimHrp.CFrame = CFrame.lookAt(hedefKonum, bossHRP.Position)
                        
                        benimHrp.Velocity = Vector3.new(0, 0, 0) -- Fiziksel savrulmaları ve bugları sıfırla
                        benimHrp.Anchored = true -- Karakteri havada çivi gibi çak (Boss seni fırlatamaz)
                    else
                        -- Boss haritada yoksa veya öldüyse karakteri serbest bırak
                        if benimHrp.Anchored then 
                            benimHrp.Anchored = false 
                        end
                    end
                end)
            end
        else
            -- Menüden buton kapatılırsa veya karakter ölürse donmayı anında kaldır
            local karakter = plr.Character
            local benimHrp = karakter and karakter:FindFirstChild("HumanoidRootPart")
            if benimHrp and benimHrp.Anchored then
                benimHrp.Anchored = false
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
