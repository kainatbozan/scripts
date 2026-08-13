local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Jujutsu Shenanigans - Auto Target Engine",
   LoadingTitle = "JJK Smart Script",
   LoadingSubtitle = "Random Target & Auto Switch System",
   ConfigurationSaving = { Enabled = false }
})

local MainTab = Window:CreateTab("Auto Combat", 4483362458)
local SafetyTab = Window:CreateTab("Güvenlik & Blok", 4483362458)

local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Ayarlar
local targetPlayerName = ""
local useRandomTarget = true -- Varsayılan Rastgele Hedef
local behindDistance = 2.5
local m1Count = 4
local comboDelay = 0.25
local m1Delay = 0.12

local autoAttackLoop = false
local autoBlockToggle = false
local healthSafetyToggle = false
local autoGuardBreakToggle = true

local isEscapeActive = false
local currentTargetPlayer = nil

-- CANLI VE GEÇERLİ OYUN CU KONTROLÜ
local function isPlayerAlive(player)
   if player and player.Parent and player.Character then
      local hum = player.Character:FindFirstChildOfClass("Humanoid")
      local root = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
      if hum and root and hum.Health > 0 then
         return true
      end
   end
   return false
end

-- DİNAMİK HEDEF SEÇİCİ (İSİM VEYA RASTGELE)
local function updateAndGetTarget()
   -- Eğer mevcut hedef hala canlıysa ve oyundaysa onu koru
   if isPlayerAlive(currentTargetPlayer) then
      return currentTargetPlayer
   end

   currentTargetPlayer = nil

   -- 1. Özel İsim Yazıldıysa Ona Bak
   if not useRandomTarget and targetPlayerName ~= "" then
      for _, player in ipairs(Players:GetPlayers()) do
         if player ~= LocalPlayer and isPlayerAlive(player) then
            if string.sub(string.lower(player.Name), 1, #targetPlayerName) == string.lower(targetPlayerName) or
               string.sub(string.lower(player.DisplayName), 1, #targetPlayerName) == string.lower(targetPlayerName) then
               currentTargetPlayer = player
               return currentTargetPlayer
            end
         end
      end
   end

   -- 2. Rastgele veya İsim Bulunamadıysa En Yakındaki Canlı Oyuncuyu Seç
   local closestPlayer = nil
   local shortestDistance = math.huge
   local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

   for _, player in ipairs(Players:GetPlayers()) do
      if player ~= LocalPlayer and isPlayerAlive(player) then
         if myRoot then
            local dist = (player.Character.HumanoidRootPart.Position - myRoot.Position).Magnitude
            if dist < shortestDistance then
               shortestDistance = dist
               closestPlayer = player
            end
         else
            closestPlayer = player
            break
         end
      end
   end

   currentTargetPlayer = closestPlayer
   if currentTargetPlayer then
      Rayfield:Notify({Title = "Yeni Hedef Kilitlendi!", Content = "Hedef: " .. currentTargetPlayer.Name, Duration = 2})
   end
   return currentTargetPlayer
end

-- Target Torso Bulma
local function getTargetTorso()
   local target = updateAndGetTarget()
   if target and target.Character then
      return target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("Torso")
   end
   return nil
end

-- Rakip Blok Yapıyor mu Kontrolü
local function isTargetBlocking()
   local target = updateAndGetTarget()
   if target and target.Character then
      local char = target.Character
      if char:FindFirstChild("Blocking") or char:FindFirstChild("Block") or char:FindFirstChild("Guard") then
         return true
      end
      local hum = char:FindFirstChildOfClass("Humanoid")
      if hum then
         for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
            local animName = string.lower(track.Name)
            if string.find(animName, "block") or string.find(animName, "guard") then
               return true
            end
         end
      end
   end
   return false
end

-- Havada Sabitleme
local function freezeInAir(root)
   if not root then return end
   local bv = root:FindFirstChild("JJKSpaceBV")
   if not bv then
      bv = Instance.new("BodyVelocity")
      bv.Name = "JJKSpaceBV"
      bv.MaxForce = Vector3.new(1e9, 1e9, 1e9)
      bv.Velocity = Vector3.new(0, 0, 0)
      bv.Parent = root
   end
end

local function unfreezeInAir(root)
   if root then
      local bv = root:FindFirstChild("JJKSpaceBV")
      if bv then bv:Destroy() end
   end
end

-- DİNAMİK ARKA İŞINLANMA (VELOCITY PREDICTION)
local function tpBehindTarget()
   if isEscapeActive then return false end
   
   local targetTorso = getTargetTorso()
   local character = LocalPlayer.Character
   local myRoot = character and character:FindFirstChild("HumanoidRootPart")

   if targetTorso and myRoot then
      local velocity = targetTorso.AssemblyLinearVelocity or targetTorso.Velocity
      local predictPos = targetTorso.Position + (velocity * 0.03)
      local behindPosition = predictPos - (targetTorso.CFrame.LookVector * behindDistance)
      myRoot.CFrame = CFrame.lookAt(behindPosition, targetTorso.Position)
      return true
   end
   return false
end

-- Tuş Girdileri
local function pressKey(keyCode, holdTime)
   VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
   task.wait(holdTime or 0.05)
   VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
end

local function clickM1()
   VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
   task.wait(0.03)
   VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
end

local function clickM2()
   VirtualInputManager:SendMouseButtonEvent(0, 0, 1, true, game, 0)
   task.wait(0.05)
   VirtualInputManager:SendMouseButtonEvent(0, 0, 1, false, game, 0)
end

-- %15 CAN UZAYA KAÇMA & %30 CANDA DÖNME MOTORU
task.spawn(function()
   while true do
      if healthSafetyToggle then
         local character = LocalPlayer.Character
         local hum = character and character:FindFirstChildOfClass("Humanoid")
         local myRoot = character and character:FindFirstChild("HumanoidRootPart")

         if hum and myRoot and hum.Health > 0 then
            local healthPercent = (hum.Health / hum.MaxHealth) * 100

            if healthPercent <= 15 and not isEscapeActive then
               isEscapeActive = true
               myRoot.CFrame = myRoot.CFrame + Vector3.new(0, 150, 0)
               freezeInAir(myRoot)
               Rayfield:Notify({Title = "TEHLİKE!", Content = "Can %15 altı! Göğe kaçıldı...", Duration = 3})
            elseif healthPercent >= 30 and isEscapeActive then
               isEscapeActive = false
               unfreezeInAir(myRoot)
               Rayfield:Notify({Title = "SAVAŞA DÖNÜLDÜ", Content = "Can %30! Savaşa devam ediliyor.", Duration = 3})
            end
         end
      end
      task.wait(0.2)
   end
end)

-- AUTO BLOCK (F BASMA)
task.spawn(function()
   while true do
      if autoBlockToggle and not isEscapeActive then
         VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
      else
         VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
      end
      task.wait(0.1)
   end
end)

-- OTOMATİK SÜREKLİ OTOMATİK SALDIRI DÖNGÜSÜ (ÖLENE / ÇIKANA KADAR YAPITAŞI)
task.spawn(function()
   while true do
      if autoAttackLoop and not isEscapeActive then
         local targetTorso = getTargetTorso()

         if targetTorso then
            tpBehindTarget()

            -- 1. Blok Kontrolü ve Guard Break
            if autoGuardBreakToggle and isTargetBlocking() then
               VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
               clickM2()
               task.wait(0.1)
            end

            -- 2. Yetenek Sırası (1-2-3-4)
            local keys = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four}
            for _, key in ipairs(keys) do
               if not autoAttackLoop or isEscapeActive or not isPlayerAlive(currentTargetPlayer) then break end
               tpBehindTarget()
               
               if autoGuardBreakToggle and isTargetBlocking() then
                  clickM2()
               end

               VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
               pressKey(key, 0.08)
               task.wait(comboDelay)
            end

            -- 3. M1 Vuruş Serisi
            for i = 1, m1Count do
               if not autoAttackLoop or isEscapeActive or not isPlayerAlive(currentTargetPlayer) then break end
               tpBehindTarget()
               
               if autoGuardBreakToggle and isTargetBlocking() then
                  clickM2()
               else
                  clickM1()
               end
               task.wait(m1Delay)
            end
         else
            task.wait(0.5) -- Canlı oyuncu yoksa bekle
         end
      end
      task.wait(0.02)
   end
end)

-- UI ELEMANLARI (TAB 1)

MainTab:CreateInput({
   Name = "Hedef Oyuncu Adı (Boşsa Rastgele)",
   PlaceholderText = "İsim yaz veya boş bırak...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      targetPlayerName = Text
      if Text == "" then
         useRandomTarget = true
         currentTargetPlayer = nil
         Rayfield:Notify({Title = "Mod Değişti", Content = "Rastgele oyuncu moduna geçildi.", Duration = 2})
      else
         useRandomTarget = false
         currentTargetPlayer = nil
         updateAndGetTarget()
      end
   end,
})

MainTab:CreateToggle({
   Name = "Sürekli Otomatik Saldır (Ölene/Çıkana Kadar)",
   CurrentValue = false,
   Flag = "AutoAttackLoopFlag",
   Callback = function(Value)
      autoAttackLoop = Value
      if Value then
         currentTargetPlayer = nil
         updateAndGetTarget()
      end
   end,
})

-- UI ELEMANLARI (TAB 2: GÜVENLİK VE AYARLAR)

SafetyTab:CreateToggle({
   Name = "Otomatik Blok Kırma (Auto Guard Break - M2)",
   CurrentValue = true,
   Flag = "AutoGuardBreakFlag",
   Callback = function(Value)
      autoGuardBreakToggle = Value
   end,
})

SafetyTab:CreateToggle({
   Name = "Uzay Koruması (%15 Kaç / %30 Dön)",
   CurrentValue = false,
   Flag = "SpaceSafetyFlag",
   Callback = function(Value)
      healthSafetyToggle = Value
      if not Value and isEscapeActive then
         isEscapeActive = false
         local character = LocalPlayer.Character
         if character and character:FindFirstChild("HumanoidRootPart") then
            unfreezeInAir(character.HumanoidRootPart)
         end
      end
   end,
})

SafetyTab:CreateToggle({
   Name = "Auto Block (Sürekli F Bas/Tut)",
   CurrentValue = false,
   Flag = "AutoBlockFlag",
   Callback = function(Value)
      autoBlockToggle = Value
      if not Value then
         VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
      end
   end,
})

SafetyTab:CreateSection("Ayar & Gecikmeler")

SafetyTab:CreateSlider({
   Name = "Arka Mesafe (Studs)",
   Range = {1, 10},
   Increment = 0.5,
   Suffix = " Stud",
   CurrentValue = 2.5,
   Flag = "DistanceSlider",
   Callback = function(Value)
      behindDistance = Value
   end,
})

SafetyTab:CreateSlider({
   Name = "M1 Vuruş Hızı (Sn)",
   Range = {0.05, 0.5},
   Increment = 0.01,
   Suffix = " sn",
   CurrentValue = 0.12,
   Flag = "M1DelaySlider",
   Callback = function(Value)
      m1Delay = Value
   end,
})

SafetyTab:CreateSlider({
   Name = "Yetenek Gecikmesi (Sn)",
   Range = {0.1, 1},
   Increment = 0.05,
   Suffix = " sn",
   CurrentValue = 0.25,
   Flag = "DelaySlider",
   Callback = function(Value)
      comboDelay = Value
   end,
})
