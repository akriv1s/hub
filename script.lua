-- =====================================================
--  AkrivHub v5.3 | Kill Switch Edition
--  by akriv1s
-- =====================================================

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local VIM          = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local LP           = Players.LocalPlayer

local SCRIPTS_URL = "https://raw.githubusercontent.com/akriv1s/scripts/refs/heads/main/scripts.txt"

local scripts = {}
local isLoaded = false

-- =====================================================
--  ANTI-AFK
-- =====================================================
local ANTI_AFK_ENABLED = true
local ANTI_AFK_INTERVAL = 30

local function startAntiAFK()
    task.spawn(function()
        while true do
            task.wait(ANTI_AFK_INTERVAL)
            if ANTI_AFK_ENABLED then
                pcall(function()
                    VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
                    task.wait(0.05)
                    VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
                    local vu = game:GetService("VirtualUser")
                    vu:CaptureController()
                    vu:ClickButton2(Vector2.new())
                end)
            end
        end
    end)
end

-- =====================================================
--  KILL ALL SCRIPTS — ядерная кнопка
-- =====================================================
local function killAllScripts()
    print("[AkrivHub] ⚠ KILL SWITCH: остановка всех скриптов...")

    -- 1. Уничтожаем ВСЕ ScreenGui в PlayerGui
    local pg = LP:FindFirstChild("PlayerGui")
    if pg then
        for _, obj in ipairs(pg:GetChildren()) do
            if obj:IsA("ScreenGui") then
                pcall(function() obj:Destroy() end)
            end
        end
    end

    -- 2. Уничтожаем CoreGui (там часто прячутся читы)
    local cg = game:GetService("CoreGui")
    for _, obj in ipairs(cg:GetChildren()) do
        if obj:IsA("ScreenGui") and obj.Name ~= "RobloxGui" then
            pcall(function() obj:Destroy() end)
        end
    end

    -- 3. Отключаем все Connections (если исполнитель поддерживает)
    if getconnections then
        local connections = getconnections(game:GetService("RunService").Heartbeat)
        for _, conn in ipairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
        connections = getconnections(game:GetService("RunService").RenderStepped)
        for _, conn in ipairs(connections) do
            pcall(function() conn:Disconnect() end)
        end
    end

    -- 4. Останавливаем все Loop-потоки Lua (мягко)
    pcall(function()
        for _, thread in ipairs(debug and debug.getthreads and debug.getthreads() or {}) do
            if coroutine.status(thread) == "suspended" or coroutine.status(thread) == "running" then
                pcall(function() task.cancel(thread) end)
            end
        end
    end)

    -- 5. Возвращаем скорость игрока к норме
    pcall(function()
        local char = LP.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            hum.WalkSpeed = 16
            hum.JumpPower = 50
        end
    end)

    -- 6. Возвращаем Lighting к дефолту
    pcall(function()
        local Light = game:GetService("Lighting")
        Light.Ambient = Color3.fromRGB(70, 70, 70)
        Light.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        Light.Brightness = 2
        Light.FogEnd = 100000
        Light.GlobalShadows = true
    end)

    -- 7. Убираем тело полёта, если есть
    pcall(function()
        local char = LP.Character
        if char then
            for _, obj in ipairs(char:GetDescendants()) do
                if obj:IsA("BodyVelocity") or obj:IsA("BodyPosition") or obj:IsA("BodyGyro") then
                    obj:Destroy()
                end
            end
        end
    end)

    -- 8. Убираем оставшиеся Billboards и Highlights
    pcall(function()
        for _, obj in ipairs(game:GetService("Players"):GetPlayers()) do
            if obj.Character then
                for _, c in ipairs(obj.Character:GetChildren()) do
                    if c:IsA("Highlight") or c:IsA("BillboardGui") or c:IsA("BoxHandleAdornment") then
                        c:Destroy()
                    end
                end
            end
        end
    end)

    print("[AkrivHub] ✓ Все скрипты остановлены.")
end

-- =====================================================
--  ПАРСЕР scripts.txt
-- =====================================================
local function parseAll(content)
    local result = {}
    local lines = {}
    for line in content:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    for i, line in ipairs(lines) do
        if line:find("loadstring") and line:find("HttpGet") then
            local url = line:match('HttpGet%("([^"]+)"')
                     or line:match("HttpGet%('([^']+)'")
                     or line:match('"([^"]+)"')

            local gameName, hubName = nil, nil
            for j = i - 1, math.max(1, i - 4), -1 do
                local prev = lines[j]
                if not prev:match("^%s*$")
                   and not prev:find("loadstring")
                   and not prev:match("^%s*#")
                   and not prev:match("^%s*[-=]+%s*$") then
                    local g, h = prev:match("^(.+)%s+[—%-–:]%s+(.+)$")
                    if g and h then
                        gameName = g:gsub("%s+$", ""):gsub("^%s+", "")
                        hubName = h:gsub("%s+$", ""):gsub("^%s+", "")
                        break
                    end
                    if not hubName then
                        hubName = prev:gsub("%s+$", ""):gsub("^%s+", "")
                        gameName = "—"
                        break
                    end
                end
            end

            if url and hubName then
                table.insert(result, {
                    game = gameName or "—",
                    name = hubName or "Скрипт",
                    url = url,
                    loadstring = line,
                })
            end
        end
    end
    return result
end

local function loadScripts()
    local ok, res = pcall(function()
        return game:HttpGet(SCRIPTS_URL, true)
    end)
    if not ok or not res or #res < 50 then
        warn("[AkrivHub] Не удалось загрузить scripts.txt")
        return false
    end
    scripts = parseAll(res)
    isLoaded = true
    print("[AkrivHub] Загружено скриптов: " .. #scripts)
    return true
end

local function runLoadstring(line, name)
    if not line or line == "" then return false end
    print("[AkrivHub] Запускаю: " .. tostring(name))
    local ok, err = pcall(function()
        local chunk = loadstring(line)
        if not chunk then error("loadstring вернул nil") end
        chunk()
    end)
    if not ok then
        warn("[AkrivHub] Ошибка «" .. tostring(name) .. "»: " .. tostring(err))
        return false
    end
    return true
end

-- =====================================================
--  ПАРТИКЛЫ
-- =====================================================
local function createLoadingParticles(parent)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, 0, 1, 0)
    container.BackgroundTransparency = 1
    container.ZIndex = 2
    container.Parent = parent
    for i = 1, 40 do
        local p = Instance.new("ImageLabel")
        p.Size = UDim2.new(0, math.random(4, 12), 0, math.random(4, 12))
        p.Position = UDim2.new(math.random(), 0, math.random(), 0)
        p.BackgroundTransparency = 1
        p.Image = "rbxasset://textures/particles/sparkles_main.dds"
        p.ImageColor3 = Color3.fromRGB(100, 180, 255)
        p.ImageTransparency = math.random(30, 80) / 100
        p.ZIndex = 2
        p.Parent = container
        task.spawn(function()
            while p.Parent do
                TweenService:Create(p, TweenInfo.new(
                    math.random(15, 35) / 10, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
                    Position = UDim2.new(math.random(), 0, math.random(), 0),
                    ImageTransparency = math.random(40, 90) / 100,
                    Rotation = math.random(-180, 180)
                }):Play()
                task.wait(math.random(15, 35) / 10)
            end
        end)
    end
end

-- =====================================================
--  ЭКРАН ЗАГРУЗКИ
-- =====================================================
local function showLoading()
    local sg = Instance.new("ScreenGui")
    sg.Name = "AkrivHubLoading"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = LP:WaitForChild("PlayerGui")

    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(10, 10, 15)
    bg.BorderSizePixel = 0
    bg.Parent = sg

    local container = Instance.new("Frame")
    container.Size = UDim2.new(0, 400, 0, 200)
    container.Position = UDim2.new(0.5, -200, 0.5, -100)
    container.BackgroundTransparency = 1
    container.ZIndex = 3
    container.Parent = sg

    local logo = Instance.new("TextLabel")
    logo.Size = UDim2.new(1, 0, 0, 60)
    logo.Position = UDim2.new(0, 0, 0, 20)
    logo.BackgroundTransparency = 1
    logo.Text = "AkrivHub"
    logo.TextColor3 = Color3.fromRGB(255, 255, 255)
    logo.Font = Enum.Font.GothamBlack
    logo.TextSize = 36
    logo.ZIndex = 3
    logo.Parent = container

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.new(1, 0, 0, 24)
    sub.Position = UDim2.new(0, 0, 0, 78)
    sub.BackgroundTransparency = 1
    sub.Text = "v5.3 | Kill Switch Edition"
    sub.TextColor3 = Color3.fromRGB(120, 120, 160)
    sub.Font = Enum.Font.Gotham
    sub.TextSize = 14
    sub.ZIndex = 3
    sub.Parent = container

    local barBg = Instance.new("Frame")
    barBg.Size = UDim2.new(0, 300, 0, 6)
    barBg.Position = UDim2.new(0.5, -150, 0, 130)
    barBg.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
    barBg.BorderSizePixel = 0
    barBg.ZIndex = 3
    barBg.Parent = container

    local bar = Instance.new("Frame")
    bar.Size = UDim2.new(0, 0, 1, 0)
    bar.BackgroundColor3 = Color3.fromRGB(100, 180, 255)
    bar.BorderSizePixel = 0
    bar.ZIndex = 3
    bar.Parent = barBg

    local barGrad = Instance.new("UIGradient")
    barGrad.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 180, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(180, 100, 255))
    }
    barGrad.Parent = bar

    createLoadingParticles(sg)

    TweenService:Create(bar, TweenInfo.new(2.5, Enum.EasingStyle.Quart), {
        Size = UDim2.new(1, 0, 1, 0)
    }):Play()

    task.delay(3, function()
        if sg and sg.Parent then
            local fadeOut = TweenService:Create(bg, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
            fadeOut:Play()
            fadeOut.Completed:Connect(function()
                sg:Destroy()
                if showMainGui then showMainGui() end
            end)
        end
    end)
end

-- =====================================================
--  ГЛАВНЫЙ GUI
-- =====================================================
function showMainGui()
    local sg = Instance.new("ScreenGui")
    sg.Name = "AkrivHub"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = LP:WaitForChild("PlayerGui")

    local win = Instance.new("Frame")
    win.Size = UDim2.new(0, 640, 0, 540)
    win.Position = UDim2.new(0.5, -320, 0.5, -270)
    win.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    win.BorderSizePixel = 0
    win.Active = true
    win.Draggable = true
    win.Parent = sg

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = win

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(60, 60, 90)
    stroke.Thickness = 1.5
    stroke.Parent = win

    win.Size = UDim2.new(0, 0, 0, 0)
    win.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(win, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 640, 0, 540),
        Position = UDim2.new(0.5, -320, 0.5, -270)
    }):Play()

    -- Заголовок
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 44)
    header.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    header.BorderSizePixel = 0
    header.Parent = win
    local headerCorner = Instance.new("UICorner")
    headerCorner.CornerRadius = UDim.new(0, 16)
    headerCorner.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -160, 1, 0)
    title.Position = UDim2.new(0, 18, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "AkrivHub | v5.3"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(0, 260, 1, 0)
    subtitle.Position = UDim2.new(0, 160, 0, 0)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "| Loading..."
    subtitle.TextColor3 = Color3.fromRGB(100, 100, 140)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 11
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = header

    -- Свернуть
    local collapseBtn = Instance.new("TextButton")
    collapseBtn.Size = UDim2.new(0, 28, 0, 28)
    collapseBtn.Position = UDim2.new(1, -70, 0, 8)
    collapseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
    collapseBtn.BorderSizePixel = 0
    collapseBtn.Text = "−"
    collapseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    collapseBtn.Font = Enum.Font.GothamBold
    collapseBtn.TextSize = 16
    collapseBtn.Parent = header
    local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 8); cc.Parent = collapseBtn

    -- Закрыть
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 28, 0, 28)
    closeBtn.Position = UDim2.new(1, -36, 0, 8)
    closeBtn.BackgroundColor3 = Color3.fromRGB(160, 50, 60)
    closeBtn.BorderSizePixel = 0
    closeBtn.Text = "×"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 18
    closeBtn.Parent = header
    local cc2 = Instance.new("UICorner"); cc2.CornerRadius = UDim.new(0, 8); cc2.Parent = closeBtn

    closeBtn.MouseButton1Click:Connect(function()
        TweenService:Create(win, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0.5, 0, 0.5, 0),
            BackgroundTransparency = 1
        }):Play()
        task.wait(0.3)
        sg:Destroy()
    end)

    -- Поиск
    local searchFrame = Instance.new("Frame")
    searchFrame.Size = UDim2.new(1, -30, 0, 40)
    searchFrame.Position = UDim2.new(0, 15, 0, 56)
    searchFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    searchFrame.BorderSizePixel = 0
    searchFrame.Parent = win
    local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0, 10); sc.Parent = searchFrame

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -20, 1, 0)
    searchBox.Position = UDim2.new(0, 14, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Text = ""
    searchBox.PlaceholderText = "Поиск по названию или игре..."
    searchBox.PlaceholderColor3 = Color3.fromRGB(100, 100, 130)
    searchBox.TextColor3 = Color3.fromRGB(230, 230, 240)
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 13
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchFrame

    -- Список
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -30, 1, -220)
    scroll.Position = UDim2.new(0, 15, 0, 106)
    scroll.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 90)
    scroll.Parent = win
    local scc = Instance.new("UICorner"); scc.CornerRadius = UDim.new(0, 10); scc.Parent = scroll

    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 6)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Parent = scroll

    -- Кнопки управления (Anti-AFK / Rejoin)
    local toggles = Instance.new("Frame")
    toggles.Size = UDim2.new(1, -30, 0, 32)
    toggles.Position = UDim2.new(0, 15, 1, -106)
    toggles.BackgroundTransparency = 1
    toggles.Parent = win

    local afkBtn = Instance.new("TextButton")
    afkBtn.Size = UDim2.new(0.5, -5, 1, 0)
    afkBtn.Position = UDim2.new(0, 0, 0, 0)
    afkBtn.BackgroundColor3 = Color3.fromRGB(55, 140, 70)
    afkBtn.BorderSizePixel = 0
    afkBtn.Text = "Anti-AFK: ON"
    afkBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    afkBtn.Font = Enum.Font.GothamBold
    afkBtn.TextSize = 11
    afkBtn.Parent = toggles
    local afkCorner = Instance.new("UICorner"); afkCorner.CornerRadius = UDim.new(0, 8); afkCorner.Parent = afkBtn

    afkBtn.MouseButton1Click:Connect(function()
        ANTI_AFK_ENABLED = not ANTI_AFK_ENABLED
        afkBtn.Text = "Anti-AFK: " .. (ANTI_AFK_ENABLED and "ON" or "OFF")
        afkBtn.BackgroundColor3 = ANTI_AFK_ENABLED and Color3.fromRGB(55, 140, 70) or Color3.fromRGB(50, 50, 70)
    end)

    local rejoinBtn = Instance.new("TextButton")
    rejoinBtn.Size = UDim2.new(0.5, -5, 1, 0)
    rejoinBtn.Position = UDim2.new(0.5, 5, 0, 0)
    rejoinBtn.BackgroundColor3 = Color3.fromRGB(60, 90, 160)
    rejoinBtn.BorderSizePixel = 0
    rejoinBtn.Text = "Rejoin"
    rejoinBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    rejoinBtn.Font = Enum.Font.GothamBold
    rejoinBtn.TextSize = 11
    rejoinBtn.Parent = toggles
    local rejoinCorner = Instance.new("UICorner"); rejoinCorner.CornerRadius = UDim.new(0, 8); rejoinCorner.Parent = rejoinBtn

    rejoinBtn.MouseButton1Click:Connect(function()
        pcall(function()
            game:GetService("TeleportService"):Teleport(game.PlaceId, LP)
        end)
    end)

    -- 🚨 KILL ALL SCRIPTS BUTTON
    local killBtn = Instance.new("TextButton")
    killBtn.Size = UDim2.new(1, -30, 0, 40)
    killBtn.Position = UDim2.new(0, 15, 1, -66)
    killBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 50)
    killBtn.BorderSizePixel = 0
    killBtn.Text = "☠ KILL ALL SCRIPTS"
    killBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    killBtn.Font = Enum.Font.GothamBlack
    killBtn.TextSize = 13
    killBtn.Parent = win
    local killCorner = Instance.new("UICorner"); killCorner.CornerRadius = UDim.new(0, 10); killCorner.Parent = killBtn

    killBtn.MouseButton1Click:Connect(function()
        killBtn.Text = "Останавливаю..."
        killBtn.BackgroundColor3 = Color3.fromRGB(120, 30, 40)

        -- Сначала запускаем убийство
        task.spawn(function()
            killAllScripts()

            -- Если хаб каким-то чудом ещё жив — дожимаем через 1 секунду
            task.wait(1)
            pcall(function()
                for _, obj in ipairs(LP:FindFirstChild("PlayerGui"):GetChildren()) do
                    if obj:IsA("ScreenGui") then obj:Destroy() end
                end
            end)
        end)
    end)

    -- Футер
    local footer = Instance.new("TextLabel")
    footer.Size = UDim2.new(1, -30, 0, 18)
    footer.Position = UDim2.new(0, 15, 1, -22)
    footer.BackgroundTransparency = 1
    footer.Text = "by akriv1s  •  Right Shift — свернуть  •  Kill — вырубить всё"
    footer.TextColor3 = Color3.fromRGB(80, 80, 110)
    footer.Font = Enum.Font.Gotham
    footer.TextSize = 10
    footer.Parent = win

    -- Логика
    local function clearList()
        for _, c in ipairs(scroll:GetChildren()) do
            if c:IsA("Frame") or c:IsA("TextLabel") then c:Destroy() end
        end
    end

    local function renderCards(list)
        clearList()
        if #list == 0 then
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, 40)
            lbl.BackgroundTransparency = 1
            lbl.Text = "Ничего не найдено"
            lbl.TextColor3 = Color3.fromRGB(160, 160, 190)
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 12
            lbl.Parent = scroll
            return
        end

        for i, script in ipairs(list) do
            local card = Instance.new("Frame")
            card.Size = UDim2.new(1, 0, 0, 68)
            card.BackgroundColor3 = Color3.fromRGB(28, 28, 40)
            card.BorderSizePixel = 0
            card.LayoutOrder = i
            card.Parent = scroll
            local cardCorner = Instance.new("UICorner"); cardCorner.CornerRadius = UDim.new(0, 10); cardCorner.Parent = card

            local nameL = Instance.new("TextLabel")
            nameL.Size = UDim2.new(1, -110, 0, 20)
            nameL.Position = UDim2.new(0, 14, 0, 8)
            nameL.BackgroundTransparency = 1
            nameL.Text = script.name
            nameL.TextColor3 = Color3.fromRGB(255, 255, 255)
            nameL.Font = Enum.Font.GothamBold
            nameL.TextSize = 13
            nameL.TextXAlignment = Enum.TextXAlignment.Left
            nameL.TextTruncate = Enum.TextTruncate.AtEnd
            nameL.Parent = card

            local gameL = Instance.new("TextLabel")
            gameL.Size = UDim2.new(1, -110, 0, 14)
            gameL.Position = UDim2.new(0, 14, 0, 30)
            gameL.BackgroundTransparency = 1
            gameL.Text = "🎮 " .. script.game
            gameL.TextColor3 = Color3.fromRGB(130, 130, 160)
            gameL.Font = Enum.Font.Gotham
            gameL.TextSize = 10
            gameL.TextXAlignment = Enum.TextXAlignment.Left
            gameL.TextTruncate = Enum.TextTruncate.AtEnd
            gameL.Parent = card

            local runBtn = Instance.new("TextButton")
            runBtn.Size = UDim2.new(0, 90, 0, 30)
            runBtn.Position = UDim2.new(1, -102, 0.5, -15)
            runBtn.BackgroundColor3 = Color3.fromRGB(55, 140, 70)
            runBtn.BorderSizePixel = 0
            runBtn.Text = "▶ Запуск"
            runBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
            runBtn.Font = Enum.Font.GothamBold
            runBtn.TextSize = 11
            runBtn.Parent = card
            local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 8); rc.Parent = runBtn

            runBtn.MouseButton1Click:Connect(function()
                runBtn.Text = "..."
                runBtn.BackgroundColor3 = Color3.fromRGB(180, 150, 60)
                task.spawn(function()
                    local ok = runLoadstring(script.loadstring, script.name)
                    task.wait(0.3)
                    runBtn.Text = ok and "✓ ОК" or "✕ Ошибка"
                    runBtn.BackgroundColor3 = ok and Color3.fromRGB(55, 140, 70) or Color3.fromRGB(180, 60, 60)
                    task.wait(1.5)
                    runBtn.Text = "▶ Запуск"
                    runBtn.BackgroundColor3 = Color3.fromRGB(55, 140, 70)
                end)
            end)
        end
    end

    local function applyFilter(query)
        if query == "" then renderCards(scripts) return end
        local q = query:lower()
        local filtered = {}
        for _, s in ipairs(scripts) do
            if s.name:lower():find(q, 1, true) or s.game:lower():find(q, 1, true) then
                table.insert(filtered, s)
            end
        end
        renderCards(filtered)
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        applyFilter(searchBox.Text)
    end)

    task.spawn(function()
        while not isLoaded do task.wait(0.2) end
        subtitle.Text = "| " .. tostring(#scripts) .. " scripts"
        renderCards(scripts)
    end)

    -- Сворачивание
    local isCollapsed = false
    local fullSize = UDim2.new(0, 640, 0, 540)
    local fullPos = UDim2.new(0.5, -320, 0.5, -270)

    local function setCollapsed(col)
        isCollapsed = col
        if col then
            TweenService:Create(win, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 200, 0, 50), Position = UDim2.new(0, 20, 0, 20)
            }):Play()
            collapseBtn.Text = "+"
            searchFrame.Visible = false
            scroll.Visible = false
            toggles.Visible = false
            killBtn.Visible = false
            footer.Visible = false
            subtitle.Text = "• Anti-AFK + Kill"
        else
            TweenService:Create(win, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = fullSize, Position = fullPos
            }):Play()
            collapseBtn.Text = "−"
            searchFrame.Visible = true
            scroll.Visible = true
            toggles.Visible = true
            killBtn.Visible = true
            footer.Visible = true
            subtitle.Text = "| " .. tostring(#scripts) .. " scripts"
        end
    end

    collapseBtn.MouseButton1Click:Connect(function() setCollapsed(not isCollapsed) end)
    UIS.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.RightShift then
            setCollapsed(not isCollapsed)
        end
    end)
end

-- =====================================================
--  СТАРТ
-- =====================================================
task.wait(0.5)

startAntiAFK()
showLoading()

task.spawn(function()
    loadScripts()
end)

print("[AkrivHub v5.3] Загружен. Anti-AFK + Kill Switch активны.")
