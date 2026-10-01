-- =====================================================
--  AkrivHub v5.1 | Universal Parser (by akriv1s)
--  Парсит ВСЕ loadstring из scripts.txt без зависимости от формата
-- =====================================================

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local HttpService  = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local LP           = Players.LocalPlayer

local SCRIPTS_URL = "https://raw.githubusercontent.com/akriv1s/scripts/refs/heads/main/scripts.txt"

local scripts = {}  -- плоский список: { {game="", name="", url="", loadstring=""} }
local isLoaded = false

-- ==================== УНИВЕРСАЛЬНЫЙ ПАРСЕР ====================
local function parseAll(content)
    local result = {}
    local lines = {}
    for line in content:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    for i, line in ipairs(lines) do
        -- Ищем loadstring строку
        if line:find("loadstring") and line:find("HttpGet") then
            -- Извлекаем URL
            local url = line:match('HttpGet%("([^"]+)"') 
                     or line:match("HttpGet%('([^']+)'")
                     or line:match('"([^"]+)"')

            -- Ищем название выше (до 4 строк)
            local gameName, hubName = nil, nil
            for j = i - 1, math.max(1, i - 4), -1 do
                local prev = lines[j]
                -- Пропускаем пустые, категории, комментарии
                if not prev:match("^%s*$")
                   and not prev:find("loadstring")
                   and not prev:match("^%s*#")
                   and not prev:match("^%s*[-=]+%s*$") then

                    -- Формат: "Игра — Название" или "Игра - Название" или "Игра: Название"
                    local g, h = prev:match("^(.+)%s+[—%-–:]%s+(.+)$")
                    if g and h then
                        gameName = g:gsub("%s+$", ""):gsub("^%s+", "")
                        hubName = h:gsub("%s+$", ""):gsub("^%s+", "")
                        break
                    end

                    -- Если тире нет — берём всю строку как название
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

-- ==================== ЗАГРУЗКА ====================
local function loadScripts()
    local ok, res = pcall(function()
        return game:HttpGet(SCRIPTS_URL, true)
    end)

    if not ok or not res or #res < 50 then
        warn("[AkrivHub] Не удалось загрузить scripts.txt: " .. tostring(res))
        return false
    end

    scripts = parseAll(res)
    isLoaded = true
    print("[AkrivHub] Загружено скриптов: " .. #scripts)
    return true
end

-- ==================== ЗАПУСК ====================
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

-- ==================== ПАРТИКЛЫ ====================
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

-- ==================== ЭКРАН ЗАГРУЗКИ ====================
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
    sub.Text = "Beta v5.1 | Universal Parser"
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

-- ==================== ГЛАВНЫЙ GUI ====================
function showMainGui()
    local sg = Instance.new("ScreenGui")
    sg.Name = "AkrivHub"
    sg.ResetOnSpawn = false
    sg.IgnoreGuiInset = true
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    sg.Parent = LP:WaitForChild("PlayerGui")

    local win = Instance.new("Frame")
    win.Size = UDim2.new(0, 640, 0, 500)
    win.Position = UDim2.new(0.5, -320, 0.5, -250)
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
        Size = UDim2.new(0, 640, 0, 500),
        Position = UDim2.new(0.5, -320, 0.5, -250)
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
    title.Text = "AkrivHub | Beta v5.1"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(0, 220, 1, 0)
    subtitle.Position = UDim2.new(0, 170, 0, 0)
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
    scroll.Size = UDim2.new(1, -30, 1, -140)
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

    -- Футер
    local footer = Instance.new("TextLabel")
    footer.Size = UDim2.new(1, -30, 0, 22)
    footer.Position = UDim2.new(0, 15, 1, -28)
    footer.BackgroundTransparency = 1
    footer.Text = "by akriv1s  •  Right Shift — свернуть"
    footer.TextColor3 = Color3.fromRGB(80, 80, 110)
    footer.Font = Enum.Font.Gotham
    footer.TextSize = 10
    footer.Parent = win

    -- Логика отображения
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

    -- Поиск
    local function applyFilter(query)
        if query == "" then
            renderCards(scripts)
            return
        end
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

    -- Первичный рендер (когда скрипты уже загружены)
    task.spawn(function()
        while not isLoaded do task.wait(0.2) end
        subtitle.Text = "| " .. tostring(#scripts) .. " scripts"
        renderCards(scripts)
    end)

    -- Сворачивание
    local isCollapsed = false
    local fullSize = UDim2.new(0, 640, 0, 500)
    local fullPos = UDim2.new(0.5, -320, 0.5, -250)

    local function setCollapsed(col)
        isCollapsed = col
        if col then
            TweenService:Create(win, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 180, 0, 50), Position = UDim2.new(0, 20, 0, 20)
            }):Play()
            collapseBtn.Text = "+"
            searchFrame.Visible = false
            scroll.Visible = false
            footer.Visible = false
            subtitle.Text = "• свёрнуто"
        else
            TweenService:Create(win, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = fullSize, Position = fullPos
            }):Play()
            collapseBtn.Text = "−"
            searchFrame.Visible = true
            scroll.Visible = true
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

-- ==================== СТАРТ ====================
task.wait(0.5)
showLoading()
task.spawn(function()
    loadScripts()
end)

print("[AkrivHub v5.1] Загружен. RightShift — свернуть/развернуть.")
