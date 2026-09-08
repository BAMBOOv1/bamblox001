local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local LogService = game:GetService("LogService")
local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local CONFIG = {
	GuiName = "HelloWorldUI",
	Version = "0.0.6",
	Button = {
		Size = UDim2.fromOffset(46, 46),
		Position = UDim2.fromOffset(100, 100),
		Text = "B",
		TextSize = 42,
		TextColor = Color3.fromRGB(82, 196, 72),
		BackgroundColor = Color3.fromRGB(20, 35, 20),
		CornerRadius = 6,
	},
	Modal = {
		Size = UDim2.fromOffset(920, 680),
		BackgroundColor = Color3.fromRGB(40, 40, 40),
		HeaderHeight = 48,
		SidebarWidth = 180,
		HeaderColor = Color3.fromRGB(28, 28, 28),
		SidebarColor = Color3.fromRGB(34, 34, 34),
		ContentColor = Color3.fromRGB(45, 45, 45),
		MenuColor = Color3.fromRGB(48, 48, 48),
		MenuActiveColor = Color3.fromRGB(82, 196, 72),
		LogTextColor = Color3.fromRGB(220, 220, 220),
		LogWarningColor = Color3.fromRGB(235, 190, 80),
		LogErrorColor = Color3.fromRGB(235, 95, 95),
		MaxLogs = 200,
	},
	WindowButton = {
		Size = UDim2.fromOffset(36, 30),
		TextSize = 20,
		MinimizeColor = Color3.fromRGB(70, 70, 70),
		CloseColor = Color3.fromRGB(190, 55, 55),
		HoverColor = Color3.fromRGB(220, 70, 70),
		CornerRadius = 5,
	},
	DragThreshold = 5,
}
local State = {
	ModalOpen = false,
	Pressed = false,
	Dragging = false,
	HeaderPressed = false,
	HeaderDragging = false,
	DragStartPosition = nil,
	ButtonStartPosition = nil,
	ModalStartPosition = nil,
}
local function createScreenGui()
	local existing = playerGui:FindFirstChild(CONFIG.GuiName)
	if existing then
		existing:Destroy()
	end
	local gui = Instance.new("ScreenGui")
	gui.Name = CONFIG.GuiName
	gui.ResetOnSpawn = false
	gui.Parent = playerGui
	return gui
end
local function createToggleButton(gui)
	local button = Instance.new("TextButton")
	button.Name = "ToggleButton"
	button.Size = CONFIG.Button.Size
	button.Position = CONFIG.Button.Position
	button.Text = CONFIG.Button.Text
	button.TextSize = CONFIG.Button.TextSize
	button.Font = Enum.Font.Arcade
	button.TextColor3 = CONFIG.Button.TextColor
	button.BackgroundColor3 = CONFIG.Button.BackgroundColor
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, CONFIG.Button.CornerRadius)
	corner.Parent = button
	return button
end
local function createPlayerESP()
	local esp = {
		Enabled = false,
		Connections = {},
		CharacterConnections = {},
	}
	local function removePlayer(player)
		local connection = esp.CharacterConnections[player]
		if connection then
			connection:Disconnect()
			esp.CharacterConnections[player] = nil
		end
		if player.Character then
			local head = player.Character:FindFirstChild("Head")
			local tag = head and head:FindFirstChild("MARK01_PlayerName")
			if tag then
				tag:Destroy()
			end
		end
	end
	local function addPlayer(player)
		if player == Players.LocalPlayer or not esp.Enabled then
			return
		end
		local function attach(character)
			local head = character:WaitForChild("Head", 5)
			if not head or not esp.Enabled or not head.Parent then
				return
			end
			removePlayer(player)
			local tag = Instance.new("BillboardGui")
			tag.Name = "MARK01_PlayerName"
			tag.Adornee = head
			tag.Size = UDim2.fromOffset(180, 32)
			tag.StudsOffset = Vector3.new(0, 2.5, 0)
			tag.AlwaysOnTop = true
			tag.MaxDistance = 250
			tag.Parent = head
			local label = Instance.new("TextLabel")
			label.Size = UDim2.fromScale(1, 1)
			label.BackgroundTransparency = 1
			label.Text = player.DisplayName .. " (" .. player.Name .. ")"
			label.Font = Enum.Font.GothamBold
			label.TextColor3 = Color3.fromRGB(255, 255, 255)
			label.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
			label.TextStrokeTransparency = 0.35
			label.TextSize = 14
			label.Parent = tag
		end
		if player.Character then
			task.spawn(attach, player.Character)
		end
		esp.CharacterConnections[player] = player.CharacterAdded:Connect(attach)
	end
	function esp:SetEnabled(enabled)
		self.Enabled = enabled
		if enabled then
			for _, target in ipairs(Players:GetPlayers()) do
				addPlayer(target)
			end
		else
			for _, target in ipairs(Players:GetPlayers()) do
				removePlayer(target)
			end
		end
	end
	function esp:Toggle()
		self:SetEnabled(not self.Enabled)
		return self.Enabled
	end
	function esp:Destroy()
		self:SetEnabled(false)
		for _, connection in ipairs(self.Connections) do
			connection:Disconnect()
		end
	end
	table.insert(esp.Connections, Players.PlayerAdded:Connect(addPlayer))
	table.insert(esp.Connections, Players.PlayerRemoving:Connect(function(player)
		removePlayer(player)
		esp.CharacterConnections[player] = nil
	end))
	return esp
end
local function createModal(gui, playerESP)
	local modal = Instance.new("Frame")
	modal.Name = "Modal"
	modal.Size = CONFIG.Modal.Size
	modal.Position = UDim2.new(0.5, -460, 0.5, -340)
	modal.BackgroundColor3 = CONFIG.Modal.BackgroundColor
	modal.BorderSizePixel = 0
	modal.Visible = false
	modal.Parent = gui
	local header = Instance.new("Frame")
	header.Name = "Header"
	header.Size = UDim2.new(1, 0, 0, CONFIG.Modal.HeaderHeight)
	header.BackgroundColor3 = CONFIG.Modal.HeaderColor
	header.BorderSizePixel = 0
	header.Parent = modal
	local logo = Instance.new("TextLabel")
	logo.Name = "Logo"
	logo.Size = UDim2.fromOffset(160, CONFIG.Modal.HeaderHeight)
	logo.Position = UDim2.fromOffset(16, 0)
	logo.BackgroundTransparency = 1
	logo.Text = "MARK 01"
	logo.Font = Enum.Font.GothamBold
	logo.TextColor3 = Color3.fromRGB(255, 255, 255)
	logo.TextSize = 20
	logo.TextXAlignment = Enum.TextXAlignment.Left
	logo.Parent = header
	local headerStatus = Instance.new("TextLabel")
	headerStatus.Name = "HeaderStatus"
	headerStatus.Size = UDim2.fromOffset(360, CONFIG.Modal.HeaderHeight)
	headerStatus.Position = UDim2.new(0.5, -180, 0, 0)
	headerStatus.BackgroundTransparency = 1
	headerStatus.Text = "FPS: --  |  Ping: --  |  Ver: " .. CONFIG.Version
	headerStatus.Font = Enum.Font.Code
	headerStatus.TextColor3 = Color3.fromRGB(170, 170, 170)
	headerStatus.TextSize = 14
	headerStatus.TextXAlignment = Enum.TextXAlignment.Center
	headerStatus.Parent = header
	local frames = 0
	local elapsed = 0
	RunService.RenderStepped:Connect(function(deltaTime)
		frames += 1
		elapsed += deltaTime
		if elapsed < 0.5 then
			return
		end
		local fps = math.floor(frames / elapsed + 0.5)
		local ping = "--"
		local success, pingValue = pcall(function()
			return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
		end)
		if success then
			ping = pingValue
		end
		headerStatus.Text = string.format("FPS: %d  |  Ping: %s  |  Ver: %s", fps, ping, CONFIG.Version)
		frames = 0
		elapsed = 0
	end)
	local sidebar = Instance.new("Frame")
	sidebar.Name = "Sidebar"
	sidebar.Size = UDim2.new(0, CONFIG.Modal.SidebarWidth, 1, -CONFIG.Modal.HeaderHeight)
	sidebar.Position = UDim2.fromOffset(0, CONFIG.Modal.HeaderHeight)
	sidebar.BackgroundColor3 = CONFIG.Modal.SidebarColor
	sidebar.BorderSizePixel = 0
	sidebar.Parent = modal
	local menuTitle = Instance.new("TextLabel")
	menuTitle.Name = "MenuTitle"
	menuTitle.Size = UDim2.new(1, -24, 0, 32)
	menuTitle.Position = UDim2.fromOffset(12, 16)
	menuTitle.BackgroundTransparency = 1
	menuTitle.Text = "MENU"
	menuTitle.Font = Enum.Font.GothamBold
	menuTitle.TextColor3 = Color3.fromRGB(145, 145, 145)
	menuTitle.TextSize = 12
	menuTitle.TextXAlignment = Enum.TextXAlignment.Left
	menuTitle.Parent = sidebar
	local content = Instance.new("Frame")
	content.Name = "Content"
	content.Size = UDim2.new(1, -CONFIG.Modal.SidebarWidth, 1, -CONFIG.Modal.HeaderHeight)
	content.Position = UDim2.new(0, CONFIG.Modal.SidebarWidth, 0, CONFIG.Modal.HeaderHeight)
	content.BackgroundColor3 = CONFIG.Modal.ContentColor
	content.BorderSizePixel = 0
	content.Parent = modal
	local contentTitle = Instance.new("TextLabel")
	contentTitle.Name = "ContentTitle"
	contentTitle.Size = UDim2.new(1, -48, 0, 42)
	contentTitle.Position = UDim2.fromOffset(24, 24)
	contentTitle.BackgroundTransparency = 1
	contentTitle.Text = "Home"
	contentTitle.Font = Enum.Font.GothamBold
	contentTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
	contentTitle.TextSize = 28
	contentTitle.TextXAlignment = Enum.TextXAlignment.Left
	contentTitle.Parent = content
	local contentBody = Instance.new("TextLabel")
	contentBody.Name = "ContentBody"
	contentBody.Size = UDim2.new(1, -48, 0, 32)
	contentBody.Position = UDim2.fromOffset(24, 72)
	contentBody.BackgroundTransparency = 1
	contentBody.Text = "Welcome to MARK 01"
	contentBody.Font = Enum.Font.Gotham
	contentBody.TextColor3 = Color3.fromRGB(190, 190, 190)
	contentBody.TextSize = 16
	contentBody.TextXAlignment = Enum.TextXAlignment.Left
	contentBody.Parent = content
	local logsList = Instance.new("ScrollingFrame")
	logsList.Name = "LogsList"
	logsList.Size = UDim2.new(1, -48, 1, -120)
	logsList.Position = UDim2.fromOffset(24, 104)
	logsList.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
	logsList.BorderSizePixel = 0
	logsList.ScrollBarThickness = 6
	logsList.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	logsList.CanvasSize = UDim2.fromOffset(0, 0)
	logsList.Visible = false
	logsList.Parent = content
	local logsPadding = Instance.new("UIPadding")
	logsPadding.PaddingTop = UDim.new(0, 8)
	logsPadding.PaddingBottom = UDim.new(0, 8)
	logsPadding.PaddingLeft = UDim.new(0, 8)
	logsPadding.PaddingRight = UDim.new(0, 8)
	logsPadding.Parent = logsList
	local logsLayout = Instance.new("UIListLayout")
	logsLayout.Padding = UDim.new(0, 4)
	logsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	logsLayout.Parent = logsList
	local logLabels = {}
	local layoutUpdateId = 0
	local function getLogColor(messageType)
		if messageType == Enum.MessageType.MessageWarning then
			return CONFIG.Modal.LogWarningColor
		end
		if messageType == Enum.MessageType.MessageError then
			return CONFIG.Modal.LogErrorColor
		end
		return CONFIG.Modal.LogTextColor
	end
	local function addLog(message, messageType)
		layoutUpdateId += 1
		local currentUpdateId = layoutUpdateId
		local currentCanvasPosition = logsList.CanvasPosition
		local anchorLabel = nil
		local anchorPosition = nil
		for _, label in ipairs(logLabels) do
			local labelTop = label.AbsolutePosition.Y
			local listTop = logsList.AbsolutePosition.Y
			if labelTop + label.AbsoluteSize.Y >= listTop then
				anchorLabel = label
				anchorPosition = labelTop
				break
			end
		end
		local logLabel = Instance.new("TextLabel")
		logLabel.Name = "LogEntry"
		logLabel.Size = UDim2.new(1, -16, 0, 24)
		logLabel.AutomaticSize = Enum.AutomaticSize.Y
		logLabel.BackgroundTransparency = 1
		logLabel.Text = message
		logLabel.Font = Enum.Font.Code
		logLabel.TextColor3 = getLogColor(messageType)
		logLabel.TextSize = 14
		logLabel.TextWrapped = true
		logLabel.TextXAlignment = Enum.TextXAlignment.Left
		logLabel.TextYAlignment = Enum.TextYAlignment.Top
		logLabel.LayoutOrder = #logLabels + 1
		logLabel.Parent = logsList
		table.insert(logLabels, logLabel)
		while #logLabels > CONFIG.Modal.MaxLogs do
			local oldestLog = table.remove(logLabels, 1)
			oldestLog:Destroy()
		end
		logsList.CanvasSize = UDim2.fromOffset(0, logsLayout.AbsoluteContentSize.Y + 16)
		task.spawn(function()
			RunService.RenderStepped:Wait()
			RunService.RenderStepped:Wait()
			if not logsList.Parent or currentUpdateId ~= layoutUpdateId then
				return
			end
			if anchorLabel and anchorLabel.Parent then
				local positionDelta = anchorLabel.AbsolutePosition.Y - anchorPosition
				logsList.CanvasPosition = Vector2.new(
					currentCanvasPosition.X,
					math.max(0, currentCanvasPosition.Y + positionDelta)
				)
			else
				logsList.CanvasPosition = currentCanvasPosition
			end
		end)
	end
	for _, logMessage in ipairs(LogService:GetLogHistory()) do
		addLog(logMessage.message or logMessage.Message, logMessage.messageType or logMessage.MessageType)
	end
	LogService.MessageOut:Connect(function(message, messageType)
		addLog(message, messageType)
	end)
	local playerToggle = Instance.new("TextButton")
	playerToggle.Name = "PlayerNamesToggle"
	playerToggle.Size = UDim2.fromOffset(180, 38)
	playerToggle.Position = UDim2.fromOffset(24, 120)
	playerToggle.Text = "ESP: OFF"
	playerToggle.Font = Enum.Font.GothamBold
	playerToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
	playerToggle.TextSize = 14
	playerToggle.BackgroundColor3 = CONFIG.Modal.MenuColor
	playerToggle.BorderSizePixel = 0
	playerToggle.AutoButtonColor = true
	playerToggle.Visible = false
	playerToggle.Parent = content
	local pingStatus = Instance.new("TextLabel")
	pingStatus.Name = "MiscPingStatus"
	pingStatus.Size = UDim2.new(1, -48, 0, 24)
	pingStatus.Position = UDim2.fromOffset(24, 96)
	pingStatus.BackgroundTransparency = 1
	pingStatus.Text = "Client Ping: --"
	pingStatus.Font = Enum.Font.Code
	pingStatus.TextColor3 = Color3.fromRGB(190, 190, 190)
	pingStatus.TextSize = 14
	pingStatus.TextXAlignment = Enum.TextXAlignment.Left
	pingStatus.Visible = false
	pingStatus.Parent = content
	local playerList = Instance.new("ScrollingFrame")
	playerList.Name = "PlayerList"
	playerList.Size = UDim2.new(1, -48, 1, -210)
	playerList.Position = UDim2.fromOffset(24, 174)
	playerList.BackgroundColor3 = Color3.fromRGB(32, 32, 32)
	playerList.BorderSizePixel = 0
	playerList.ScrollBarThickness = 6
	playerList.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
	playerList.CanvasSize = UDim2.fromOffset(0, 0)
	playerList.Visible = false
	playerList.Parent = content
	local playerListPadding = Instance.new("UIPadding")
	playerListPadding.PaddingTop = UDim.new(0, 8)
	playerListPadding.PaddingBottom = UDim.new(0, 8)
	playerListPadding.PaddingLeft = UDim.new(0, 8)
	playerListPadding.PaddingRight = UDim.new(0, 8)
	playerListPadding.Parent = playerList
	local playerListLayout = Instance.new("UIListLayout")
	playerListLayout.Padding = UDim.new(0, 4)
	playerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	playerListLayout.Parent = playerList
	local pingRemote = ReplicatedStorage:FindFirstChild("MARK01_GetPlayerPings")
	local playerPings = {}
	local function refreshPlayerList()
		pingRemote = pingRemote or ReplicatedStorage:FindFirstChild("MARK01_GetPlayerPings")
		if pingRemote then
			local success, result = pcall(function()
				return pingRemote:InvokeServer()
			end)
			if success and type(result) == "table" then
				playerPings = result
			end
		end
		for _, child in ipairs(playerList:GetChildren()) do
			if child:IsA("TextLabel") then
				child:Destroy()
			end
		end
		for index, target in ipairs(Players:GetPlayers()) do
			local label = Instance.new("TextLabel")
			label.Name = "PlayerEntry"
			label.Size = UDim2.new(1, -16, 0, 28)
			label.BackgroundTransparency = 1
			local ping = playerPings[target.UserId]
			local youLabel = target == Players.LocalPlayer and " [YOU]" or ""
			label.Text = target.DisplayName .. " (" .. target.Name .. ")" .. youLabel .. " ----- " .. (ping and (ping .. " ms") or "--")
			label.Font = Enum.Font.Gotham
			label.TextColor3 = target == Players.LocalPlayer and CONFIG.Button.TextColor or Color3.fromRGB(235, 235, 235)
			label.TextSize = 14
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.LayoutOrder = index
			label.Parent = playerList
		end
		playerList.CanvasSize = UDim2.fromOffset(0, playerListLayout.AbsoluteContentSize.Y + 16)
	end
	Players.PlayerAdded:Connect(refreshPlayerList)
	Players.PlayerRemoving:Connect(refreshPlayerList)
	refreshPlayerList()
	RunService.RenderStepped:Connect(function()
		if not pingStatus.Visible then
			return
		end
		local success, ping = pcall(function()
			return Stats.Network.ServerStatsItem["Data Ping"]:GetValueString()
		end)
		pingStatus.Text = "Client Ping: " .. (success and ping or "--")
	end)
	task.spawn(function()
		while playerList.Parent do
			if playerList.Visible then
				refreshPlayerList()
			end
			task.wait(1)
		end
	end)
	local playerToggleCorner = Instance.new("UICorner")
	playerToggleCorner.CornerRadius = UDim.new(0, 5)
	playerToggleCorner.Parent = playerToggle
	playerToggle.MouseButton1Click:Connect(function()
		local enabled = playerESP:Toggle()
		playerToggle.Text = enabled and "ESP: ON" or "ESP: OFF"
		playerToggle.BackgroundColor3 = enabled and CONFIG.Modal.MenuActiveColor or CONFIG.Modal.MenuColor
	end)
	local menuButtons = {}
	local menuItems = {
		{Name = "Home", Description = "Welcome to MARK 01"},
		{Name = "Settings", Description = "Configure your preferences"},
		{Name = "Logs", Description = "Client output logs"},
		{Name = "Misc", Description = "Extra map testing tools"},
	}
	for index, item in ipairs(menuItems) do
		local menuButton = Instance.new("TextButton")
		menuButton.Name = item.Name .. "MenuButton"
		menuButton.Size = UDim2.new(1, -24, 0, 42)
		menuButton.Position = UDim2.fromOffset(12, 52 + ((index - 1) * 48))
		menuButton.Text = item.Name
		menuButton.Font = Enum.Font.GothamMedium
		menuButton.TextColor3 = Color3.fromRGB(235, 235, 235)
		menuButton.TextSize = 15
		menuButton.TextXAlignment = Enum.TextXAlignment.Left
		menuButton.BackgroundColor3 = index == 1 and CONFIG.Modal.MenuActiveColor or CONFIG.Modal.MenuColor
		menuButton.BorderSizePixel = 0
		menuButton.AutoButtonColor = false
		menuButton.Parent = sidebar
		local menuPadding = Instance.new("UIPadding")
		menuPadding.PaddingLeft = UDim.new(0, 14)
		menuPadding.Parent = menuButton
		local menuCorner = Instance.new("UICorner")
		menuCorner.CornerRadius = UDim.new(0, 5)
		menuCorner.Parent = menuButton
		menuButtons[index] = menuButton
		menuButton.MouseButton1Click:Connect(function()
			for _, button in ipairs(menuButtons) do
				button.BackgroundColor3 = CONFIG.Modal.MenuColor
			end
			menuButton.BackgroundColor3 = CONFIG.Modal.MenuActiveColor
			contentTitle.Text = item.Name
			contentBody.Text = item.Description
			logsList.Visible = item.Name == "Logs"
			contentBody.Visible = item.Name ~= "Logs"
			playerToggle.Visible = item.Name == "Misc"
			pingStatus.Visible = item.Name == "Misc"
			playerList.Visible = item.Name == "Misc"
			if item.Name == "Misc" then
				refreshPlayerList()
			end
		end)
	end
	local minimizeButton = Instance.new("TextButton")
	minimizeButton.Name = "MinimizeButton"
	minimizeButton.Size = CONFIG.WindowButton.Size
	minimizeButton.Position = UDim2.new(1, -84, 0.5, -15)
	minimizeButton.Text = "-"
	minimizeButton.Font = Enum.Font.GothamBold
	minimizeButton.TextSize = CONFIG.WindowButton.TextSize
	minimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	minimizeButton.BackgroundColor3 = CONFIG.WindowButton.MinimizeColor
	minimizeButton.BorderSizePixel = 0
	minimizeButton.AutoButtonColor = true
	minimizeButton.Parent = header
	local minimizeCorner = Instance.new("UICorner")
	minimizeCorner.CornerRadius = UDim.new(0, CONFIG.WindowButton.CornerRadius)
	minimizeCorner.Parent = minimizeButton
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = CONFIG.WindowButton.Size
	closeButton.Position = UDim2.new(1, -44, 0.5, -15)
	closeButton.Text = "X"
	closeButton.Font = Enum.Font.GothamBold
	closeButton.TextSize = CONFIG.WindowButton.TextSize
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.BackgroundColor3 = CONFIG.WindowButton.CloseColor
	closeButton.BorderSizePixel = 0
	closeButton.AutoButtonColor = false
	closeButton.Parent = header
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, CONFIG.WindowButton.CornerRadius)
	closeCorner.Parent = closeButton
	closeButton.MouseEnter:Connect(function()
		closeButton.BackgroundColor3 = CONFIG.WindowButton.HoverColor
	end)
	closeButton.MouseLeave:Connect(function()
		closeButton.BackgroundColor3 = CONFIG.WindowButton.CloseColor
	end)
	return modal, header, minimizeButton, closeButton
end
local function setModalState(modal, open)
	State.ModalOpen = open
	modal.Visible = open
end
local function setupDragAndClick(button, modal)
	button.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		State.Pressed = true
		State.Dragging = false
		State.DragStartPosition = input.Position
		State.ButtonStartPosition = button.Position
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not State.Pressed then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		local delta = input.Position - State.DragStartPosition
		if not State.Dragging then
			if math.abs(delta.X) > CONFIG.DragThreshold
				or math.abs(delta.Y) > CONFIG.DragThreshold then
				State.Dragging = true
			end
		end
		if State.Dragging then
			button.Position = UDim2.new(
				State.ButtonStartPosition.X.Scale,
				State.ButtonStartPosition.X.Offset + delta.X,
				State.ButtonStartPosition.Y.Scale,
				State.ButtonStartPosition.Y.Offset + delta.Y
			)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if not State.Pressed then
			return
		end
		if not State.Dragging then
			setModalState(modal, not State.ModalOpen)
		end
		State.Pressed = false
		State.Dragging = false
		State.DragStartPosition = nil
		State.ButtonStartPosition = nil
	end)
end
local function setupHeaderDrag(header, modal)
	header.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		State.HeaderPressed = true
		State.HeaderDragging = false
		State.DragStartPosition = input.Position
		State.ModalStartPosition = modal.Position
	end)
	UserInputService.InputChanged:Connect(function(input)
		if not State.HeaderPressed then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		local delta = input.Position - State.DragStartPosition
		if not State.HeaderDragging then
			if math.abs(delta.X) > CONFIG.DragThreshold
				or math.abs(delta.Y) > CONFIG.DragThreshold then
				State.HeaderDragging = true
			end
		end
		if State.HeaderDragging then
			modal.Position = UDim2.new(
				State.ModalStartPosition.X.Scale,
				State.ModalStartPosition.X.Offset + delta.X,
				State.ModalStartPosition.Y.Scale,
				State.ModalStartPosition.Y.Offset + delta.Y
			)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		State.HeaderPressed = false
		State.HeaderDragging = false
		State.DragStartPosition = nil
		State.ModalStartPosition = nil
	end)
end
local function createUI()
	local gui = createScreenGui()
	local toggleButton = createToggleButton(gui)
	local playerESP = createPlayerESP()
	local modal, header, minimizeButton, closeButton = createModal(gui, playerESP)
	setupDragAndClick(toggleButton, modal)
	setupHeaderDrag(header, modal)
	minimizeButton.MouseButton1Click:Connect(function()
		setModalState(modal, false)
	end)
	closeButton.MouseButton1Click:Connect(function()
		playerESP:Destroy()
		gui:Destroy()
	end)
end
createUI()
