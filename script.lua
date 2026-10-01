-- =====================================================
--  AkrivHub v1.1 Beta | Dynamic Loader
--  Автоматически загружает скрипты из scripts.txt
--  by akriv1s
-- =====================================================

local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local LP           = Players.LocalPlayer

-- =====================================================
--  ИСТОЧНИК СПИСКА СКРИПТОВ
-- =====================================================
local SCRIPTS_URL = "https://raw.githubusercontent.com/akriv1s/scripts/refs/heads/main/scripts.txt"

-- =====================================================
--  СОСТОЯНИЕ
-- =====================================================
local state = {
    scripts       = {},       -- { { name, game, url, desc } }
    isLoaded      = false,
    loadProgress  = 0,
    mainGui       = nil,
    loadingGui    = nil,
}

-- =====================================================
--  ПАРСЕР scripts.txt
-- =====================================================
local function parseScripts(content)
    local result = {}
    local currentGame = "Разное"
    local lines = {}

    -- Разбиваем на строки, убираем \r
    for line in content:gmatch("[^\r\n]+") do
        line = line:gsub("\r", "")
        table.insert(lines, line)
    end

    local i = 1
    while i <= #lines do
        local line = lines[i]

        -- Категория (## Название)
        local catMatch = line:match("^%s*##%s+(.+)$")
        if catMatch then
            currentGame = catMatch:gsub("%s+$", ""):gsub("^%s+", "")
            i = i + 1

            -- Пропускаем пустые строки
            while i <= #lines and lines[i]:match("^%s*$") do i = i + 1 end

            -- Читаем скрипты до следующей категории
            while i <= #lines and not lines[i]:match("^%s*##") do
                local entry = lines[i]
                if not entry:match("^%s*$") then
                    -- Пытаемся распарсить: "Название (описание)" или просто "Название"
                    local name, desc = entry:match("^(.+)%s+%((.+)%)%s*$")
                    if not name then
                        name = entry
                        desc = ""
                    end

                    -- Ищем URL в следующей строке
                    local url = nil
                    local j = i + 1
                    while j <= #lines and lines[j]:match("^%s*$") do j = j + 1 end
                    if j <= #lines then
                        url = lines[j]:match("^%s*(https?://.+)$")
                    end

                    if url then
                        table.insert(result, {
                            name = name,
                            game = currentGame,
                            desc = desc,
                            url  = url,
                        })
                        i = j + 1
                    else
                        -- URL не найден, пропускаем строку
                        i = i + 1
                    end
                else
                    i = i + 1
                end
            end
        else
            i = i + 1
        end
    end

    return result
end

-- =====================================================
--  ЗАГРУЗКА СПИСКА
-- =====================================================
local function loadScripts()
    print("[AkrivHub] Загружаю scripts.txt...")
    state.loadProgress = 0.3

    local ok, res = pcall(function()
        return game:HttpGet(SCRIPTS_URL, true)
    end)

    if not ok or not res or #res < 100 then
        warn("[AkrivHub] Не удалось загрузить scripts.txt: " .. tostring(res))
        state.loadProgress = 1
        return false
    end

    state.loadProgress = 0.7
    state.scripts = parseScripts(res)
    state.isLoaded = true
    state.loadProgress = 1

    print("[AkrivHub] Загружено скриптов: " .. #state.scripts)
    return true
end

-- =====================================================
--  ЗАПУСК СКРИПТА
-- =====================================================
local function runScript(scriptData)
    if not scriptData or not scriptData.url then
        warn("[AkrivHub] Пустой URL")
        return false
    end

    print("[AkrivHub] Запускаю: " .. scriptData.name)
    local ok, err = pcall(function()
        local source = game:HttpGet(scriptData.url)
        if not source or #source < 10 then
            error("Пустой ответ от сервера")
        end
        local chunk = loadstring(source)
        if not chunk then
            error("loadstring вернул nil")
        end
        chunk()
    end)

    if not ok then
        warn("[AkrivHub] Ошибка «" .. scriptData.name .. "»: " .. tostring(err))
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
                    math.random(15, 35) / 10,
                    Enum.EasingStyle.Sine,
                    Enum.EasingDirection.InOut
                ), {
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
    state.loadingGui = sg

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
    sub.Text = "v1.1 Beta | Dynamic Loader"
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

    -- Прогресс-бар обновляется в фоне
    task.spawn(function()
        while sg and sg.Parent do
            TweenService:Create(bar, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
                Size = UDim2.new(state.loadProgress, 0, 1, 0)
            }):Play()
            task.wait(0.3)
        end
    end)

    task.delay(3, function()
        if sg and sg.Parent then
            local fadeOut = TweenService:Create(bg, TweenInfo.new(0.5), { BackgroundTransparency = 1 })
            fadeOut:Play()
            fadeOut.Completed:Connect(function()
                sg:Destroy()
                state.loadingGui = nil
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
    state.mainGui = sg

    -- Главное окно
    local win = Instance.new("Frame")
    win.Size = UDim2.new(0, 640, 0, 520)
    win.Position = UDim2.new(0.5, -320, 0.5, -260)
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

    -- Анимация появления
    win.Size = UDim2.new(0, 0, 0, 0)
    win.Position = UDim2.new(0.5, 0, 0.5, 0)
    TweenService:Create(win, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 640, 0, 520),
        Position = UDim2.new(0.5, -320, 0.5, -260)
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
    title.Text = "AkrivHub | v1.1 Beta"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header

    local subtitle = Instance.new("TextLabel")
    subtitle.Size = UDim2.new(0, 220, 1, 0)
    subtitle.Position = UDim2.new(0, 160, 0, 0)
    subtitle.BackgroundTransparency = 1
    subtitle.Text = "| Loading..."
    subtitle.TextColor3 = Color3.fromRGB(100, 100, 140)
    subtitle.Font = Enum.Font.Gotham
    subtitle.TextSize = 11
    subtitle.TextXAlignment = Enum.TextXAlignment.Left
    subtitle.Parent = header

    -- Кнопка сворачивания
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

    local collapseCorner = Instance.new("UICorner")
    collapseCorner.CornerRadius = UDim.new(0, 8)
    collapseCorner.Parent = collapseBtn

    -- Кнопка закрытия
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

    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 8)
    closeCorner.Parent = closeBtn

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

    local searchCorner = Instance.new("UICorner")
    searchCorner.CornerRadius = UDim.new(0, 10)
    searchCorner.Parent = searchFrame

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

    -- Список скриптов
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, -30, 1, -160)
    scroll.Position = UDim2.new(0, 15, 0, 106)
    scroll.BackgroundColor3 = Color3.fromRGB(18, 18, 26)
    scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.ScrollBarThickness = 4
    scroll.ScrollBarImageColor3 = Color3.fromRGB(60, 60, 90)
    scroll.Parent = win

    local scrollCorner = Instance.new("UICorner")
    scrollCorner.CornerRadius = UDim.new(0, 10)
    scrollCorner.Parent = scroll

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
            if c:IsA("Frame") or c:IsA("TextLabel") then
                c:Destroy()
            end
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

            local cardCorner = Instance.new("UICorner")
            cardCorner.CornerRadius = UDim.new(0, 10)
            cardCorner.Parent = card

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

            local runCorner = Instance.new("UICorner")
            runCorner.CornerRadius = UDim.new(0, 8)
            runCorner.Parent = runBtn

            runBtn.MouseButton1Click:Connect(function()
                runBtn.Text = "..."
                runBtn.BackgroundColor3 = Color3.fromRGB(180, 150, 60)
                task.spawn(function()
                    local ok = runScript(script)
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

    -- Фильтрация
    local function applyFilter(query)
        if query == "" then
            renderCards(state.scripts)
            return
        end
        local q = query:lower()
        local filtered = {}
        for _, s in ipairs(state.scripts) do
            if s.name:lower():find(q, 1, true) or s.game:lower():find(q, 1, true) then
                table.insert(filtered, s)
            end
        end
        renderCards(filtered)
    end

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        applyFilter(searchBox.Text)
    end)

    -- Первичный рендер (когда загрузка завершена)
    task.spawn(function()
        while not state.isLoaded do task.wait(0.2) end
        subtitle.Text = "| " .. tostring(#state.scripts) .. " scripts"
        renderCards(state.scripts)
    end)

    -- Сворачивание
    local isCollapsed = false
    local fullSize = UDim2.new(0, 640, 0, 520)
    local fullPos = UDim2.new(0.5, -320, 0.5, -260)

    local function setCollapsed(col)
        isCollapsed = col
        if col then
            TweenService:Create(win, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, 180, 0, 50),
                Position = UDim2.new(0, 20, 0, 20)
            }):Play()
            collapseBtn.Text = "+"
            searchFrame.Visible = false
            scroll.Visible = false
            footer.Visible = false
            subtitle.Text = "• свёрнуто"
        else
            TweenService:Create(win, TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
                Size = fullSize,
                Position = fullPos
            }):Play()
            collapseBtn.Text = "−"
            searchFrame.Visible = true
            scroll.Visible = true
            footer.Visible = true
            subtitle.Text = "| " .. tostring(#state.scripts) .. " scripts"
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

-- Показываем экран загрузки
showLoading()

-- Загружаем скрипты в фоне
task.spawn(function()
    loadScripts()
end)

print("[AkrivHub v1.1 Beta] Загружен. Скрипты подтягиваются из GitHub.")
