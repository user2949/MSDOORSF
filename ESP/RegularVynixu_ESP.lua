-- 		 			          - CREATED BY RegularVynixu -
-- 	     ---- ORIGINAL: https://github.com/RegularVynixu/Utilities/blob/main/ESP/Better_ESP/Source.lua ----
-- 		   This is just a modified version for MSHUB that added some bug fixes and more features

if Vynixu_ESPModule then return Vynixu_ESPModule end -- silly goose

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

-- Variables
local localPlayer = Players.LocalPlayer
local localChar = localPlayer.Character or localPlayer.CharacterAdded:Wait()
local localRoot = localChar:WaitForChild("HumanoidRootPart")
local localCamera = workspace.CurrentCamera

local vec2new = Vector2.new
local col3new = Color3.new
local col3hsv = Color3.fromHSV
local drawnew = Drawing.new
local instnew = Instance.new
local waitForChild = game.WaitForChild
local findFirstIsA = game.FindFirstChildWhichIsA
local descendantOf = game.IsDescendantOf
local getPlayers = Players.GetPlayers
local math_max = math.max
local math_round = math.round
local math_clamp = math.clamp
local insert = table.insert
local sub = string.sub
local lower = string.lower

local getPivot = localChar.GetPivot
local wtvp = localCamera.WorldToViewportPoint

local module = {
    Containers = {},
    Connections = {},
    Config = {
        Rainbow = false,
        TextSize = 16,
        DarkerOutlineColor = true,
        Distance = {
            Enabled = true,
            Max = math.huge
        },
        Health = {
            Enabled = true,
            Type = "Percentage" -- "Fraction"
        },
        Tracer = {
            Enabled = true,
            Thickness = 1,
            Color = col3new(1, 1, 1),
            From = "Bottom" -- Bottom, Center, Top, Mouse
        },
        Highlight = {
            Enabled = true,
            AlwaysOnTop = true,
            Color = {
                Fill = col3new(1, 1, 1),
                Outline = col3hsv(0.00588235, 0.00588235, 0.00588235),
            },
            Transparency = {
                Fill = 0.65,
                Outline = 0
            }
        },
        Adornment = { -- :Add({ Adornment = true })
            AlwaysOnTop = true,
            Transparency = 0.65,
            Type = "Cylinder", -- Sphere, Box
            Color = {
                Main = col3new(1, 1, 1),
                Text = col3hsv(0.00588235, 0.00588235, 0.00588235),
            },
        }
    }
}

-- Functions
local function changeColorBrightness(color)
    if module.Config.DarkerOutlineColor == false then return color end -- also checks here for the rainbow outline color
	if typeof(color) ~= "Color3" then return color end

	local h, s, v = color:ToHSV()
	return col3hsv(h, s, v + (v / 2))
end

local function onCharacterAdded(char)
    localChar, localRoot = char, waitForChild(char, "HumanoidRootPart")
    
    getPivot = localChar.GetPivot
end

local function onDestroyingCamera(_, parent)
    if parent then return end

    if module.Connections.CameraDeleted ~= nil and typeof(module.Connections.CameraDeleted) == "RBXScriptConnection" then module.Connections.CameraDeleted:Disconnect() end
    repeat task.wait() until workspace.CurrentCamera

    localCamera = workspace.CurrentCamera
    wtvp = localCamera.WorldToViewportPoint
    module.Connections.CameraDeleted = localCamera.AncestryChanged:Connect(onDestroyingCamera)
end

local function isAlive(container)
    local rootPart = container.Root
    local humanoid = container.Humanoid
    if not rootPart or not rootPart.Parent then
        return false
    elseif humanoid and humanoid.Health <= 0 then
        return false
    end
    return true
end

local function checkCallback(container, key)
    local callback = container.Callbacks[key]
    if not callback then
       -- warn("Failed to find callback: " .. key)
        return false
    end
    return true, {callback()}
end

function module:Add(rootPart, options, callbacks)
    if typeof(rootPart) == "Instance" and rootPart.ClassName == "Model" then
        rootPart = rootPart.PrimaryPart or findFirstIsA(rootPart, "BasePart")
    end
    if not rootPart then
        --warn("Failed to find root part.")
        return
    end

    -- Setup callbacks (nullable)
    callbacks = (typeof(callbacks) == "table") and callbacks or {}

    -- Get player from rootPart (nullable)
    local applyPlayerStuff = rootPart:IsA("Player");
    local player;
    if applyPlayerStuff then
        player = rootPart
        rootPart = (player.Character or player.CharacterAdded:Wait()):WaitForChild("HumanoidRootPart", math.huge)
    else
        for _, plr in getPlayers(Players) do
            if plr.Character and descendantOf(plr.Character, rootPart) then
                player = plr
                break
            end
        end
    end

    -- Get player team color (nullable)
    local teamColor;
    if player then
        teamColor = player.TeamColor.Color

        if applyPlayerStuff then
            options.Name = player.Name

            if not callbacks["Health"] then
                callbacks.Health = function()
                    if not player.Character then return 0, 0 end

                    local humanoid = player.Character:FindFirstChild("Humanoid")
                    if not humanoid then return 0, 0 end

                    return humanoid.Health, humanoid.MaxHealth
                end
            end
        end
    end
	
	if self.Containers[applyPlayerStuff and player or rootPart] then
        self:Remove(applyPlayerStuff and player or rootPart)
    end
	
    -- Construct container
    local config = {
        Name = options.Name or rootPart.Name,
        Color = options.Color,
        HighlightFocus = options.HighlightFocus or rootPart,
        AdornmentEnabled = options.Adornment or false,
        Hidden = false
    }
    local connections = {}
    local drawing = {}
    local container = {
        Root = rootPart,
	    Player = player,
        Connections = connections,
        Drawing = drawing,
        Callbacks = callbacks,
        Config = config
    }

    -- Functions
    function container:Remove()
        module:Remove(container.Player or container.Root)
    end

    -- DarkerOutlineColor setting
    if module.Config.DarkerOutlineColor and typeof(config.Color) == "table" then
        config.Color.Outline = changeColorBrightness(config.Color.Outline)
    end

    -- Connections
    connections.AncestryChanged = rootPart.AncestryChanged:Connect(function(_, parent)
        if not parent then
            container:Remove()
        end
    end)

    -- Drawing
    local name = drawnew("Text")
    name.Center = true
    name.Outline = true
    name.Size = self.Config.TextSize
    --name.Color = config.Color
    name.Text = config.Name

    local distance = drawnew("Text")
    distance.Center = true
    distance.Outline = true
    distance.Color = col3new(1, 1, 1)
    distance.Size = self.Config.TextSize

    local health = drawnew("Text")
    health.Center = true
    health.Outline = true
    health.Color = col3new(1, 1, 1)
    health.Size = self.Config.TextSize

    local tracer = drawnew("Line")
    --tracer.From = self.Config.Tracer.From
    tracer.Thickness = self.Config.Tracer.Thickness
    --tracer.Color = config.Color

    local highlight, adornment;
    if config.AdornmentEnabled == true then
        if self.Config.Adornment.Type == "Box" then
			adornment = Instance.new("BoxHandleAdornment", config.HighlightFocus)
			adornment.Size = rootPart.Size 
		elseif self.Config.Adornment.Type == "Sphere" then
			adornment = Instance.new("SphereHandleAdornment", config.HighlightFocus)
			adornment.Radius = rootPart.Size.X * 1.085
			adornment.CFrame = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0)
        else
            adornment = Instance.new("CylinderHandleAdornment", config.HighlightFocus)
			adornment.Height = rootPart.Size.Y * 2
			adornment.Radius = rootPart.Size.X * 1.085
			adornment.CFrame = CFrame.new() * CFrame.Angles(math.rad(90), 0, 0)
		end

        adornment.AlwaysOnTop = options.AlwaysOnTop or self.Config.Adornment.AlwaysOnTop
        adornment.ZIndex = 10
    else
        highlight = instnew("Highlight")
        highlight.Enabled = false
        highlight.FillTransparency = self.Config.Highlight.Transparency.Fill
        highlight.OutlineTransparency = self.Config.Highlight.Transparency.Outline
        highlight.FillColor = self.Config.Highlight.Color.Fill
        highlight.OutlineColor = self.Config.Highlight.Color.Outline
        highlight.Parent = config.HighlightFocus
    end

    -- Drawing objects functions
    function container:Rename(newName)
        name.Text = tostring(newName)
    end
	
    -- Indexing
    insert(drawing, { Obj = name, Name = "Name", Type = "Text" })
    insert(drawing, { Obj = distance, Name = "Distance", Type = "Text" })
    insert(drawing, { Obj = health, Name = "Health", Type = "Text" })
    insert(drawing, { Obj = tracer, Name = "Tracer", Type = "Line" })
    if highlight then insert(drawing, { Obj = highlight, Name = "Highlight", Type = "Highlight" }) end
    if adornment then insert(drawing, { Obj = adornment, Name = "Adornment", Type = "Adornment" }) end

    self.Containers[applyPlayerStuff and player or rootPart] = container
    return container
end

function module:Remove(rootPart)
    local container = self.Containers[rootPart]
    if container then
        self.Containers[rootPart] = nil
        for i, connection in container.Connections do
            connection:Disconnect()
            container.Connections[i] = nil
        end
        for i, draw in container.Drawing do
            draw.Obj:Destroy()
            container.Drawing[i] = nil
        end
        for i, _ in container do
            container[i] = nil
        end
    end
end

function module:Clear()
    for _, container in self.Containers do
        container:Remove()
    end
end

function module:Unload()
    for i, connection in self.Connections do
        connection:Disconnect()
        self.Connections[i] = nil
    end
    self:Clear()
    for i, _ in self do
        self[i] = nil
    end
end

-- Main
local connections = module.Connections
connections.CharacterAdded = localPlayer.CharacterAdded:Connect(onCharacterAdded)
connections.CameraDeleted = localCamera.AncestryChanged:Connect(onDestroyingCamera)
connections.Update = RunService.Stepped:Connect(function()
    local eConfig = module.Config
    local eDistance = eConfig.Distance
    local eHealth = eConfig.Health
    local eTracer = eConfig.Tracer
    local eHighlight = eConfig.Highlight
    local eAdornment = eConfig.Adornment
    local textSize = eConfig.TextSize

    -- Update containers
    for _, container in module.Containers do
        -- Check if alive
        if not isAlive(container) then
            container:Remove()
            continue
        end
        
        local config = container.Config
        local callbacks = container.Callbacks

        -- Get on-screen position
        local root = container.Root
        local pos, onScreen = wtvp(localCamera, root.Position)
        --[[if pos.Z < 0 then
            local objectSpacePos = localCamera.CFrame:pointToObjectSpace(root.Position)
            objectSpacePos = CFrame.Angles(0, 0, math.atan2(objectSpacePos.Y, objectSpacePos.X) + math.pi):vectorToWorldSpace((CFrame.Angles(0, math.rad(89.9), 0):vectorToWorldSpace(Vector3.new(0, 0, -1))))
            pos = wtvp(localCamera, localCamera.CFrame:pointToWorldSpace(objectSpacePos))
        end--]]
        if not onScreen then
            -- Hide container
            if not config.Hidden then
                config.Hidden = true -- This prevents unnecessary updates
                for _, draw in container.Drawing do
                    if draw.Type == "Highlight" then
                        draw.Obj.Enabled = false
                    elseif draw.Type == "Adornment" then
                        draw.Obj.Adornee = nil
                    else
                        draw.Obj.Visible = false
                    end
                end
            end
            continue
        end
        
        -- Check distance
        local mag = (root.Position - localRoot.Position).Magnitude
        if mag > eDistance.Max then continue end

        -- Update container content
        local vec2 = vec2new(pos.X, pos.Y)
        local rainbowColor = col3hsv(tick() % 5 / 5, 1, 1)
        local color;
        local outlineColor;

        local rows = 0
        for _, draw in container.Drawing do
            if draw.Type == "Text" and draw.Obj.Text ~= "" then
                rows += 1
            end
        end
        
        -- Update visuals
        for i = 1, #container.Drawing, 1 do
            local draw = container.Drawing[i]
            local obj = draw.Obj
            local name = draw.Name
            local ttype = draw.Type
            
            if ttype == "Highlight" then
                if typeof(config.Color) == "table" then
                    color = eConfig.Rainbow and rainbowColor or config.Color.Fill
                    outlineColor = eHighlight.Transparency.Outline == 1 and color or (eConfig.Rainbow and changeColorBrightness(rainbowColor) or config.Color.Outline)
                else
                    color = eConfig.Rainbow and rainbowColor or config.Color
                    outlineColor = eHighlight.Transparency.Outline == 1 and color or (eConfig.Rainbow and changeColorBrightness(rainbowColor) or config.Color)
                end

                obj.Enabled = eHighlight.Enabled
                if eHighlight.Enabled then
                    obj.FillColor = color
                    obj.OutlineColor = outlineColor
                    obj.FillTransparency = eHighlight.Transparency.Fill
                    obj.OutlineTransparency = eHighlight.Transparency.Outline
                    obj.DepthMode = (eHighlight.AlwaysOnTop and "AlwaysOnTop" or "Occluded")
                end
            elseif ttype == "Adornment" then
                color = typeof(config.Color) == "table" and (eConfig.Rainbow and rainbowColor or config.Color.Fill) or (eConfig.Rainbow and rainbowColor or config.Color)

                if config.AdornmentEnabled then
                    obj.Color3 = color
                    obj.Transparency = eAdornment.Transparency
                    obj.Adornee = config.HighlightFocus
                end
            else
                color = typeof(config.Color) == "table" and (eConfig.Rainbow and rainbowColor or config.Color.Fill) or (eConfig.Rainbow and rainbowColor or config.Color)

                obj.Color = color
                obj.Visible = (ttype ~= "Line" or (ttype == "Line" and eTracer.Enabled))
                
                if ttype == "Text" then
                    obj.Size = textSize
                    obj.Position = vec2 - vec2new(0, (rows - i) * textSize)
    
                    if name == "Name" then
                        obj.Text = config.Name
                    
                    elseif name == "Distance" and eDistance.Enabled then
                        obj.Text = `[{math_round(mag)} studs]`

                    elseif name == "Health" and eHealth.Enabled then
                        local bool, args = checkCallback(container, "Health") -- args: health, maxHealth
                        if bool then
                            local hType = lower(eHealth.Type)
                            if hType == "percentage" then
                                obj.Text = `[{math_clamp(math_round(100 / args[2] * args[1] * 10) / 10, 0, 100)}%]`
                            elseif hType == "fraction" then
                                obj.Text = `[{math_round(math_max(args[1], 0))}/{math_round(args[2])}]`
                            end
                        end
                    end
                elseif ttype == "Line" then
                    obj.Visible = eTracer.Enabled
                    if eTracer.Enabled then
						if tostring(eTracer.From):lower() == "mouse" then
							obj.From = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y)
						elseif tostring(eTracer.From):lower() == "top" then
							obj.From = vec2new(localCamera.ViewportSize.X / 2, 0)
						elseif tostring(eTracer.From):lower() == "center" then
							obj.From = vec2new(localCamera.ViewportSize.X / 2, localCamera.ViewportSize.Y / 2)
						else
							obj.From = vec2new(localCamera.ViewportSize.X / 2, localCamera.ViewportSize.Y)
						end
							
                        obj.To = vec2 + vec2new(0, math_max(rows * textSize / 2, textSize)) -- dynamic text rows offset
                        obj.Thickness = eTracer.Thickness
                    end
                end
            end
        end

        -- Update container hidden
        config.Hidden = false
    end
end)

getgenv().Vynixu_ESPModule = module
return module
