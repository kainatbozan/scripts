local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
   Name = "Jujutsu Shenanigans (Ultra Hızlı)",
   LoadingTitle = "Yükleniyor...",
   LoadingSubtitle = "kainatbozan - Düzenlendi",
   ConfigurationSaving = { Enabled = false }
})

-- GUI SÜRÜKLEMEYİ (HAREKET ETMEYİ) TAMAMEN İPTAL ETME
task.spawn(function()
   task.wait(2)
   local coreGui = game:GetService("CoreGui")
   local rayfieldGui = coreGui:FindFirstChild("Rayfield") or game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Rayfield")
   
   if rayfieldGui then
      for _, desc in ipairs(rayfieldGui:GetDescendants()) do
         if desc:IsA("Frame") or desc:IsA("TextButton") or desc:IsA("ImageButton") or desc:IsA("TextLabel") then
            desc.Active = false
            desc.Draggable = false
         end
      end
   end
end)

local MainTab = Window:CreateTab("Auto Combat", 4483362458)
local TestTab = Window:CreateTab("Test (Dummy)", 4483362458)
local SafetyTab = Window:CreateTab("Güvenlik & Blok", 4483362458)
local WhitelistTab = Window:CreateTab("Whitelist", 4483362458)

local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Genel Ayarlar
local targetPlayerName = ""
local useRandomTarget = true
local behindDistance = 2.5
local twinSpeedValue = 200
local m1Count = 4
local comboDelay = 0.20
local m1Delay = 0.00 -- Işık hızı için varsayılan 0
local gDelay = 2.0

local autoAttackLoop = false
local standaloneAutoM1 = false
local autoBehindLock = false
local autoBlockToggle = false
local autoParryToggle = false -- YENİ: Akıllı Blok
local attackWhileBlocking = false -- YENİ: Block tutarak vur
local healthSafetyToggle = false
local autoGuardBreakToggle = true
local aimbotToggle = false
local twinSpeedToggle = false
local autoGToggle = false
local dummyTargetToggle = false

-- Yuji Auto Combo Ayarları
local yujiComboToggle = false
local yujiSkillDelay = 0.35

-- Hitbox Ayarları
local hitboxToggle = false
local hitboxSize = 15
local hitboxTransparency = 0.7

-- Whitelist Tablosu
local whitelist = {}
local whitelistInputName = ""

local isEscapeActive = false
local currentTargetPlayer = nil
local currentDummyTarget = nil
local isRespawning = false
local isParrying = false

local UIFlags = {}

-- WHITELIST KONTROLÜ
local function isWhitelisted(player)
   if not player then return false end
   for _, name in ipairs(whitelist) do
      if string.lower(player.Name) == string.lower(name) or string.lower(player.DisplayName) == string.lower(name) then
         return true
      end
   end
   return false
end

local function isLocalPlayerAlive()
   if isRespawning then return false end
   local char = LocalPlayer.Character
   if not char or not char:IsDescendantOf(Workspace) then return false end

   local hum = char:FindFirstChildOfClass("Humanoid")
   local root = char:FindFirstChild("HumanoidRootPart")

   if not hum or not root then return false end
   if hum.Health <= 0 then return false end

   if char:FindFirstChild("Knocked") or char:FindFirstChild("Ragdoll") or char:FindFirstChild("Dead") then
      return false
   end

   local state = hum:GetState()
   if state == Enum.HumanoidStateType.Dead or state == Enum.HumanoidStateType.Physics then
      return false
   end

   return true
end

local function isCharacterAlive(char)
   if not char or not char:IsDescendantOf(Workspace) then return false end
   
   local player = Players:GetPlayerFromCharacter(char)
   if player and isWhitelisted(player) then return false end

   local hum = char:FindFirstChildOfClass("Humanoid")
   local root = char:FindFirstChild("HumanoidRootPart")

   if not hum or not root then return false end
   if hum.Health <= 0 then return false end

   if char:FindFirstChild("Knocked") or char:FindFirstChild("Ragdoll") or char:FindFirstChild("Dead") then
      return false
   end

   return true
end

-- DUMMY TARAMA
task.spawn(function()
   while true do
      if dummyTargetToggle and isLocalPlayerAlive() then
         local closest = nil
         local shortestDist = math.huge
         local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

         if myRoot then
            for _, obj in ipairs(Workspace:GetDescendants()) do
               if obj:IsA("Model") and string.find(string.lower(obj.Name), "dummy") then
                  if isCharacterAlive(obj) then
                     local dRoot = obj:FindFirstChild("HumanoidRootPart")
                     if dRoot then
                        local dist = (dRoot.Position - myRoot.Position).Magnitude
                        if dist < shortestDist then
                           shortestDist = dist
                           closest = obj
                        end
                     end
                  end
               end
            end
         end
         currentDummyTarget = closest
      else
         currentDummyTarget = nil
      end
      task.wait(1)
   end
end)

local function updateAndGetTargetPlayer()
   if not isLocalPlayerAlive() then return nil end
   if currentTargetPlayer and isCharacterAlive(currentTargetPlayer.Character) then return currentTargetPlayer end

   currentTargetPlayer = nil

   if not useRandomTarget and targetPlayerName ~= "" then
      for _, player in ipairs(Players:GetPlayers()) do
         if player ~= LocalPlayer and player.Character and isCharacterAlive(player.Character) then
            if string.find(string.lower(player.Name), string.lower(targetPlayerName)) or
               string.find(string.lower(player.DisplayName), string.lower(targetPlayerName)) then
               currentTargetPlayer = player
               return currentTargetPlayer
            end
         end
      end
   end

   local closestPlayer = nil
   local shortestDist = math.huge
   local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")

   for _, player in ipairs(Players:GetPlayers()) do
      if player ~= LocalPlayer and player.Character and isCharacterAlive(player.Character) then
         local tRoot = player.Character:FindFirstChild("HumanoidRootPart")
         if myRoot and tRoot then
            local dist = (tRoot.Position - myRoot.Position).Magnitude
            if dist < shortestDist then
               shortestDist = dist
               closestPlayer = player
            end
         else
            closestPlayer = player
            break
         end
      end
   end

   currentTargetPlayer = closestPlayer
   return currentTargetPlayer
end

local function getActiveTarget()
   if dummyTargetToggle then
      if currentDummyTarget and isCharacterAlive(currentDummyTarget) then return currentDummyTarget end
      return nil
   else
      local p = updateAndGetTargetPlayer()
      if p and p.Character and isCharacterAlive(p.Character) then return p.Character end
      return nil
   end
end

local function isTargetBlocking()
   local targetChar = getActiveTarget()
   if targetChar then
      if targetChar:FindFirstChild("Blocking") or targetChar:FindFirstChild("Block") or targetChar:FindFirstChild("Guard") then return true end
      local hum = targetChar:FindFirstChildOfClass("Humanoid")
      if hum then
         for _, track in ipairs(hum:GetPlayingAnimationTracks()) do
            local animName = string.lower(track.Name)
            if string.find(animName, "block") or string.find(animName, "guard") then return true end
         end
      end
   end
   return false
end

local function tpBehindTarget()
   if isEscapeActive or not isLocalPlayerAlive() then return end

   local targetChar = getActiveTarget()
   local myChar = LocalPlayer.Character
   local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

   if targetChar and myRoot then
      local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
      if tRoot then
         local behindPosition = tRoot.Position - (tRoot.CFrame.LookVector * behindDistance)
         local targetCFrame = CFrame.lookAt(behindPosition, tRoot.Position)
         local dist = (myRoot.Position - targetCFrame.Position).Magnitude

         if dist > 30 then
            myRoot.CFrame = myRoot.CFrame:Lerp(targetCFrame, 0.15)
         else
            myRoot.CFrame = targetCFrame
         end
      end
   end
end

local function pressKey(keyCode, holdTime)
   VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
   task.wait(holdTime or 0.01)
   VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
end

-- IŞIK HIZINDA M1 FONKSİYONU
local function clickM1()
   local vp = Camera.ViewportSize
   VirtualInputManager:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, true, game, 0)
   RunService.RenderStepped:Wait() -- Tek bir frame bekler (Mümkün olan en hızlı tıklama)
   VirtualInputManager:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 0, false, game, 0)
   
   if attackWhileBlocking and not isParrying then
      -- Vururken saniyelik block basıp çeker (Block iptalini önlemek için)
      VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
   end
end

local function clickM2()
   local vp = Camera.ViewportSize
   VirtualInputManager:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 1, true, game, 0)
   RunService.RenderStepped:Wait()
   VirtualInputManager:SendMouseButtonEvent(vp.X / 2, vp.Y / 2, 1, false, game, 0)
end

local function resetHitboxes()
   for _, player in ipairs(Players:GetPlayers()) do
      if player ~= LocalPlayer and player.Character then
         local root = player.Character:FindFirstChild("HumanoidRootPart")
         if root then
            root.Size = Vector3.new(2, 2, 1)
            root.Transparency = 1
         end
      end
   end
end

-- AKILLI BLOK (AUTO PARRY) SİSTEMİ
task.spawn(function()
   while true do
      if autoParryToggle and not isEscapeActive and isLocalPlayerAlive() then
         local targetChar = getActiveTarget()
         if targetChar then
            local myRoot = LocalPlayer.Character.HumanoidRootPart
            local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
            
            -- Hedef 20 studdan yakınsa animasyonlarını tarar
            if myRoot and tRoot and (myRoot.Position - tRoot.Position).Magnitude < 20 then
               local eHum = targetChar:FindFirstChildOfClass("Humanoid")
               if eHum and eHum.Health > 0 then
                  local isAttacking = false
                  for _, anim in ipairs(eHum:GetPlayingAnimationTracks()) do
                     local animName = string.lower(anim.Name)
                     -- Saldırı animasyonu isimleri (çoğu oyunu kapsar)
                     if string.find(animName, "punch") or string.find(animName, "m1") or
                        string.find(animName, "attack") or string.find(animName, "kick") or
                        string.find(animName, "strike") or string.find(animName, "skill") or
                        string.find(animName, "swing") or string.find(animName, "dash") then
                        isAttacking = true
                        break
                     end
                  end

                  if isAttacking and not isParrying then
                     isParrying = true
                     task.spawn(function()
                        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game)
                        task.wait(0.35) -- Blokta kalma süresi
                        if not autoBlockToggle then
                           VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game)
                        end
                        task.wait(0.1) -- Spam önleyici bekleme
                        isParrying = false
                     end)
                  end
               end
            end
         end
      end
      task.wait(0.01) -- Işık hızında tarama
   end
end)


RunService.RenderStepped:Connect(function()
   if hitboxToggle and not dummyTargetToggle then
      for _, player in ipairs(Players:GetPlayers()) do
         if player ~= LocalPlayer and player.Character and not isWhitelisted(player) then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
               root.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
               root.Transparency = hitboxTransparency
               root.BrickColor = BrickColor.new("Really red")
               root.Material = Enum.Material.ForceField
               root.CanCollide = false
            end
         elseif isWhitelisted(player) and player.Character then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            if root and root.Size.X ~= 2 then
               root.Size = Vector3.new(2, 2, 1)
               root.Transparency = 1
            end
         end
      end
   end

   if not isLocalPlayerAlive() then return end
   local myChar = LocalPlayer.Character
   local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
   local hum = myChar and myChar:FindFirstChildOfClass("Humanoid")

   if twinSpeedToggle and hum then hum.WalkSpeed = twinSpeedValue end

   if healthSafetyToggle and hum and myRoot then
      local hpPercent = (hum.Health / hum.MaxHealth) * 100
      if hpPercent <= 15 then
         isEscapeActive = true
         myRoot.CFrame = CFrame.new(myRoot.Position.X, 500, myRoot.Position.Z)
      elseif hpPercent >= 30 and isEscapeActive then
         isEscapeActive = false
      end
   end

   if autoBehindLock and not isEscapeActive and not autoAttackLoop and not yujiComboToggle then
      tpBehindTarget()
   end

   if (aimbotToggle or autoAttackLoop or yujiComboToggle) and not isEscapeActive then
      local targetChar = getActiveTarget()
      if targetChar then
         local head = targetChar:FindFirstChild("Head") or targetChar:FindFirstChild("HumanoidRootPart")
         if head then Camera.CFrame = CFrame.lookAt(Camera.CFrame.Position, head.Position) end
      end
   end
end)

-- SAVAŞ DÖNGÜLERİ
task.spawn(function()
   while true do
      if yujiComboToggle and not isEscapeActive and isLocalPlayerAlive() then
         local targetChar = getActiveTarget()
         if targetChar then
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
            
            if myRoot and tRoot and (myRoot.Position - tRoot.Position).Magnitude > 15 then
               tpBehindTarget()
               task.wait(0.05)
               continue
            end

            tpBehindTarget()
            if autoGuardBreakToggle and isTargetBlocking() then clickM2(); task.wait(0.05) end
            
            for i = 1, 3 do
               if not yujiComboToggle or not isLocalPlayerAlive() or not getActiveTarget() then break end
               tpBehindTarget(); clickM1(); task.wait(m1Delay)
            end
            
            if yujiComboToggle and isLocalPlayerAlive() and getActiveTarget() then tpBehindTarget(); pressKey(Enum.KeyCode.One, 0.01); task.wait(yujiSkillDelay) end
            if yujiComboToggle and isLocalPlayerAlive() and getActiveTarget() then tpBehindTarget(); pressKey(Enum.KeyCode.Two, 0.01); task.wait(yujiSkillDelay) end
            if yujiComboToggle and isLocalPlayerAlive() and getActiveTarget() then tpBehindTarget(); pressKey(Enum.KeyCode.Three, 0.01); task.wait(yujiSkillDelay) end
            if yujiComboToggle and isLocalPlayerAlive() and getActiveTarget() then tpBehindTarget(); pressKey(Enum.KeyCode.Four, 0.01); task.wait(yujiSkillDelay) end
         else task.wait(0.05) end
      else task.wait(0.1) end
   end
end)

task.spawn(function()
   while true do
      if autoGToggle and not isEscapeActive and isLocalPlayerAlive() then pressKey(Enum.KeyCode.G, 0.1) end
      task.wait(gDelay)
   end
end)

task.spawn(function()
   while true do
      -- Sadece AutoBlock açıksa sürekli F basılı tutar. AutoParry açıksa o kendi yönetir.
      if autoBlockToggle and not isEscapeActive and isLocalPlayerAlive() and not autoParryToggle then 
         VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.F, false, game) 
      end
      task.wait(0.1)
   end
end)

task.spawn(function()
   while true do
      if standaloneAutoM1 and not isEscapeActive and isLocalPlayerAlive() then
         local targetChar = getActiveTarget()
         if targetChar then
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local tRoot = targetChar:FindFirstChild("HumanoidRootPart")
            if myRoot and tRoot and (myRoot.Position - tRoot.Position).Magnitude > 15 then
               tpBehindTarget()
               task.wait(0.05)
               continue
            end
            if autoGuardBreakToggle and isTargetBlocking() then clickM2() else clickM1() end
         end
      end
      task.wait(m1Delay)
   end
end)

task.spawn(function()
   while true do
      if autoAttackLoop and not yujiComboToggle and not isEscapeActive and isLocalPlayerAlive() then
         local targetChar = getActiveTarget()
         if targetChar then
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            local tRoot = targetChar:FindFirstChild("HumanoidRootPart")

            if myRoot and tRoot and (myRoot.Position - tRoot.Position).Magnitude > 15 then
               tpBehindTarget()
               task.wait(0.05)
               continue
            end

            tpBehindTarget()
            if autoGuardBreakToggle and isTargetBlocking() then clickM2(); task.wait(0.05) end

            local keys = {Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four}
            for _, key in ipairs(keys) do
               if not autoAttackLoop or isEscapeActive or not isLocalPlayerAlive() or not getActiveTarget() then break end
               tpBehindTarget()
               if autoGuardBreakToggle and isTargetBlocking() then clickM2() end
               pressKey(key, 0.02)
               task.wait(comboDelay)
            end

            for i = 1, m1Count do
               if not autoAttackLoop or isEscapeActive or not isLocalPlayerAlive() or not getActiveTarget() then break end
               tpBehindTarget()
               if autoGuardBreakToggle and isTargetBlocking() then clickM2() else clickM1() end
               task.wait(m1Delay)
            end
         else task.wait(0.05) end
      else task.wait(0.1) end
   end
end)

LocalPlayer.CharacterAdded:Connect(function(char)
   isRespawning = true
   currentTargetPlayer = nil
   currentDummyTarget = nil
   isEscapeActive = false
   char:WaitForChild("HumanoidRootPart", 5)
   char:WaitForChild("Humanoid", 5)
   task.wait(2.5) 
   isRespawning = false
end)

-------------------------------------------------------------------------
-- UI ELEMANLARI
-------------------------------------------------------------------------
MainTab:CreateSection("Savaş & Hedefleme")

MainTab:CreateInput({
   Name = "Hedef Oyuncu Adı (Boşsa En Yakın)",
   PlaceholderText = "İsim yaz veya boş bırak...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text)
      targetPlayerName = Text
      currentTargetPlayer = nil
      useRandomTarget = (Text == "")
      updateAndGetTargetPlayer()
   end,
})

MainTab:CreateToggle({
   Name = "🔥 AUTO FARM (Tüm Savaş Özelliklerini Aç)",
   CurrentValue = false,
   Flag = "AutoFarmToggleMaster",
   Callback = function(Value)
      if UIFlags.AutoG then UIFlags.AutoG:Set(Value) end
      if UIFlags.Aimbot then UIFlags.Aimbot:Set(Value) end
      if UIFlags.AutoBehind then UIFlags.AutoBehind:Set(Value) end
      if UIFlags.GenelAuto then UIFlags.GenelAuto:Set(Value) end
   end,
})

UIFlags.GenelAuto = MainTab:CreateToggle({
   Name = "Genel Auto Combat",
   CurrentValue = false,
   Flag = "AutoAttackLoopFlag",
   Callback = function(Value)
      autoAttackLoop = Value
      if Value then
         if UIFlags.YujiCombo then UIFlags.YujiCombo:Set(false) end
         currentTargetPlayer = nil
         updateAndGetTargetPlayer()
      end
   end,
})

UIFlags.AutoBehind = MainTab:CreateToggle({
   Name = "Hedefin Sırtına Anında Işınlan (Instant TP Lock)",
   CurrentValue = false,
   Flag = "AutoBehindLockFlag",
   Callback = function(Value) autoBehindLock = Value end,
})

UIFlags.Aimbot = MainTab:CreateToggle({
   Name = "Kamera Aimbot (Hedefe Kilitlen)",
   CurrentValue = false,
   Flag = "AimbotToggleFlag",
   Callback = function(Value) aimbotToggle = Value end,
})

UIFlags.AutoG = MainTab:CreateToggle({
   Name = "Otomatik G Bas (Auto Awakening/Ultimate)",
   CurrentValue = false,
   Flag = "AutoGToggleFlag",
   Callback = function(Value) autoGToggle = Value end,
})

MainTab:CreateToggle({
   Name = "Sürekli Auto M1 (Işık Hızında Tıkla)",
   CurrentValue = false,
   Flag = "StandaloneM1Flag",
   Callback = function(Value) standaloneAutoM1 = Value end,
})

MainTab:CreateSection("Hitbox Ayarları")

MainTab:CreateToggle({
   Name = "Hitbox Büyütücü (Hitbox Expander)",
   CurrentValue = false,
   Flag = "HitboxToggleFlag",
   Callback = function(Value)
      hitboxToggle = Value
      if not Value then resetHitboxes() end
   end,
})

-------------------------------------------------------------------------
SafetyTab:CreateSection("Blok & Defans Ayarları")

SafetyTab:CreateToggle({
   Name = "🧠 AKILLI BLOK (Auto Parry / Skill Algılayıcı)",
   CurrentValue = false,
   Flag = "AutoParryFlag",
   Callback = function(Value) autoParryToggle = Value end,
})
SafetyTab:CreateParagraph({Title = "Bilgi", Content = "Düşman M1 veya Skill kullandığında anında algılayarak otomatik blok basar."})

SafetyTab:CreateToggle({
   Name = "🛡️ Blok Tutarken Vur (Kesintisiz Defans+Saldırı)",
   CurrentValue = false,
   Flag = "AttackWhileBlockingFlag",
   Callback = function(Value) attackWhileBlocking = Value end,
})

SafetyTab:CreateToggle({
   Name = "Otomatik Blok Kırma (Auto Guard Break - M2)",
   CurrentValue = true,
   Flag = "AutoGuardBreakFlag",
   Callback = function(Value) autoGuardBreakToggle = Value end,
})

SafetyTab:CreateToggle({
   Name = "Auto Block (Sürekli F Bas/Tut)",
   CurrentValue = false,
   Flag = "AutoBlockFlag",
   Callback = function(Value)
      autoBlockToggle = Value
      if not Value then VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.F, false, game) end
   end,
})

SafetyTab:CreateToggle({
   Name = "Uzay Koruması (%15 Göğe TP / %30 Dön)",
   CurrentValue = false,
   Flag = "SpaceSafetyFlag",
   Callback = function(Value)
      healthSafetyToggle = Value
      if not Value then isEscapeActive = false end
   end,
})

SafetyTab:CreateSection("Gecikme & Hız Ayarları")

SafetyTab:CreateSlider({
   Name = "M1 Vuruş Hızı (Sn) [0 = Işık Hızı]",
   Range = {0.00, 0.50},
   Increment = 0.01,
   Suffix = " sn",
   CurrentValue = 0.00,
   Flag = "M1DelaySlider",
   Callback = function(Value) m1Delay = Value end,
})

SafetyTab:CreateSlider({
   Name = "Yetenek Gecikmesi (Sn)",
   Range = {0.01, 1},
   Increment = 0.01,
   Suffix = " sn",
   CurrentValue = 0.15,
   Flag = "DelaySlider",
   Callback = function(Value) comboDelay = Value end,
})

-------------------------------------------------------------------------
TestTab:CreateSection("Dummy (NPC) Hedefleme Modu")
TestTab:CreateToggle({
   Name = "Sadece Dummy'lere Kilitlen (Oyuncuları Yoksay)",
   CurrentValue = false,
   Flag = "DummyTargetFlag",
   Callback = function(Value) dummyTargetToggle = Value end,
})
-------------------------------------------------------------------------
WhitelistTab:CreateInput({
   Name = "Oyuncu Adı (Username / DisplayName)",
   PlaceholderText = "Eklenecek adı yazın...",
   RemoveTextAfterFocusLost = false,
   Callback = function(Text) whitelistInputName = Text end,
})
WhitelistTab:CreateButton({
   Name = "Whitelist'e Ekle (Dost Ekle)",
   Callback = function()
      if whitelistInputName ~= "" then
         table.insert(whitelist, whitelistInputName)
         currentTargetPlayer = nil
         updateAndGetTargetPlayer()
      end
   end,
})
