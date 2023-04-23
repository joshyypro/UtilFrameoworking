local player = game:GetService('Players').LocalPlayer--; repeat wait() player = game:GetService('Players').LocalPlayer until player
local runService = game:GetService('RunService')
for i = 1, 10 do
	if player or runService:IsServer() then break end
	wait()
	player = game:GetService('Players').LocalPlayer
end
local userInputService = game:GetService('UserInputService')
local stepped
pcall(function() stepped = runService.RenderStepped end)
pcall(function() if runService:IsServer() then stepped = runService.Heartbeat end end)

local Timing = require(script.Timing)

local util = {}

do
	local debugInstances = true
	local classes = {}
	function util.class(nc, newf)
		nc = nc or {}
		nc.__index = nc
		local classDebugData
		if debugInstances and nc.className then
			classDebugData = {
				name = nc.className,
				class = nc,
				instances = setmetatable({}, {__mode = "v"})
			}
			table.insert(classes, classDebugData)
		end
		function nc:new(o, ...)
			o = o or {}
			if type(o) == "table" and not getmetatable(o) then
				setmetatable(o, nc)
			end
			o = newf and newf(o, ...) or o
			if type(o) == "table" and not getmetatable(o) then
				setmetatable(o, nc)
			end
			if classDebugData then
				table.insert(classDebugData.instances, o)
			end
			if o.initObject then
				o:initObject()
			end
			return o
		end
		return nc
	end
	function util.subclass(super, nc, newf)
		nc = util.class(nc, newf)
		nc.super = super
		function nc.__index(_, key)
			return rawget(nc, key) or super[key]
		end
		return nc
	end
	function util.setupRemoveWatch()
		if not debugInstances then
			return
		end
		for _, class in pairs(classes) do
			do
				local old_Remove = class.class.Remove
				local function new_Remove(obj, ...)
					local instances = class.instances
					for i = #instances, 1, -1 do
						if instances[i] == obj then
							table.remove(instances, i)
						end
					end
					if old_Remove then
						old_Remove(obj, ...)
					end
					if type(obj) == "table" then
						for i in pairs(obj) do
							obj[i] = nil
						end
					end
				end
				class.class.Remove = new_Remove
				class.class.Remove = new_Remove
				if not old_Remove then
					class.lacksRemove = true
				end
			end
		end
	end
	function util.debugClasses(specificClass)
		if not debugInstances then
			print("instance debug disabled")
			return
		end
		if specificClass then
			for _, class in pairs(classes) do
				if class.name == specificClass then
					print(class.name .. ": " .. #class.instances .. (class.lacksRemove and " [?]" or ""))
				end
			end
		else
			table.sort(classes, function(a, b)
				return a.name < b.name
			end)
			for _, class in pairs(classes) do
				print(class.name .. ": " .. #class.instances .. (class.lacksRemove and " [?]" or ""))
			end
		end
	end
end

local gui, fader
if player and not script.Parent:IsA('ServerStorage') then
	local playerGui = player:WaitForChild('PlayerGui')
	util.backGui = Instance.new('ScreenGui', playerGui)
	util.backGui.Name = 'BackGui'
	
	gui = Instance.new('ScreenGui', playerGui)
	gui.Name = 'MainGui'
	util.gui = gui
	fader = Instance.new('Frame', gui)
	fader.Name = 'FadeGui'
	fader.BorderSizePixel = 0
	fader.Size = UDim2.new(1.0, 0, 1.0, 60)
	fader.Position = UDim2.new(0.0, 0, 0.0, -40)
	fader.BackgroundTransparency = 1.0
	util.fadeGui = fader
	
	util.frontGui = Instance.new('ScreenGui', playerGui)
	util.frontGui.Name = 'FrontGui'
	
	util.soundContainer = Instance.new('ScreenGui', playerGui)
	util.soundContainer.Name = 'SoundContainer'
	
	util.simulatedCoreGui = Instance.new('ScreenGui', playerGui)
	util.simulatedCoreGui.Name = 'SimulatedCoreGui'
end

function util:layerGuis()
	local playerGui = player:WaitForChild('PlayerGui')
	util.backGui.Parent, util.gui.Parent, util.frontGui.Parent, util.simulatedCoreGui.Parent = nil, nil, nil, nil
	util.backGui.Parent = playerGui
	util.gui.Parent = playerGui
	util.frontGui.Parent = playerGui
	util.simulatedCoreGui.Parent = playerGui
end

function util.getHumanoid()
	local s, r = pcall(function()
		for _, h in pairs(player.Character:GetChildren()) do
			if h:IsA('Humanoid') then
				return h
			end
		end
	end)
	if s and r then
		return r
	end
end

function util.isTouchDevice()
	local touchEnabled = false
	pcall(function() touchEnabled = userInputService.TouchEnabled end)
	return touchEnabled
end
function util.isPhone()
	if not gui then return false end
	return gui.AbsoluteSize.X <= 640
end

util.lerpCFrame = require(script.CFrameInterpolator)
util.lerpUDim2 = function(a, b)
	local axs, axo, ays, ayo = a.X.Scale, a.X.Offset, a.Y.Scale, a.Y.Offset
	local dxs, dxo, dys, dyo = b.X.Scale-axs, b.X.Offset-axo, b.Y.Scale-ays, b.Y.Offset-ayo
	return function(alpha)
		return UDim2.new(axs+dxs*alpha, axo+dxo*alpha, ays+dys*alpha, ayo+dyo*alpha)
	end
end
util.lerpVector2 = function(a, b)
	local ax, ay = a.X, a.Y
	local dx, dy = b.X-ax, b.Y-ay
	return function(alpha)
		return Vector2.new(ax+dx*alpha, ay+dy*alpha)
	end
end

util.uid = require(script.Ascii85).uid
util.Timing = Timing

do
	local fds = require(script.FontDisplayService)
	function util.Write(...)
		return fds:Write(...)
	end
	fds:Preload('Avenir')
	local fc = require(script.FontDisplayService.FontCreator)
	util.AvenirFont = fc.load('Avenir')
	util.loadFont = fc.load
end

do
	local httpService = game:GetService('HttpService')
	function util.jsonEncode(...)
		return httpService:JSONEncode(...)
	end
	function util.jsonDecode(...)
		return httpService:JSONDecode(...)
	end
end

local tostring = tostring
function util.toId(thing)
	if thing and thing.id then thing = thing.id end
	return (tostring(thing):lower():gsub('[^a-z0-9]+', ''))
end

function util.split(str, sep)
	local arr = {}
	-- [[ NEW IMPLEMENTATION:
	local index = 1
	while true do
		local s, e = str:find(sep, index, true)
		if not s then break end
		table.insert(arr, str:sub(index, s-1))
		index = e+1
	end
	table.insert(arr, str:sub(index))
	--]]
	--[[ OLD IMPLEMENTATION: (badly supported more than 1 character)
	for sub in string.gmatch(str, '[^'..sep..']+') do -- do not pass raw magic characters for seperator
		table.insert(arr, sub)
	end
	--]]
	return arr
end

local function deepcopy(t)
	if type(t) ~= 'table' then return t end
	local mt = getmetatable(t)
	local res = {}
	for k, v in pairs(t) do
		if type(v) == 'table' then
			v = deepcopy(v)
		end
		res[k] = v
	end
	setmetatable(res, mt)
	return res
end
util.deepcopy = deepcopy

function util.shallowcopy(t)
	if type(t) ~= 'table' then return t end
	local c = {}
	for k, v in pairs(t) do
		c[k] = v
	end
	return c
end

function util.trim(str)
	if str:match('^%s+$') then return '' end
	str = str:match('^%s+(%S.*)$') or str -- string.match(str, '^%s+(%S+)') or str
	str = str:match('^(.*%S)%s+$') or str -- string.match(str, '(%S+)%s+$') or str
	return str
end


function util.Create(instanceType)
	return function(data)
		local obj = Instance.new(instanceType)
		for k, v in pairs(data) do
			local s, e = pcall(function()
				if type(k) == 'number' then
					v.Parent = obj
				elseif type(v) == 'function' then
					obj[k]:connect(v)
				else
					obj[k] = v
				end
			end)
			if not s then
				error('Create: could not set property '..k..' of '..instanceType..' ('..e..')', 2)
			end
		end
		return obj
	end
end

function util.GetDescendants(p,ofClass)local d={}local function r(o)for _,c in pairs(o:GetChildren())do if not ofClass or c:IsA(ofClass)then table.insert(d,c)end r(c)end end r(p)return d end



function util.FadeOut(duration, color, fn)
	fader.ZIndex = 10
	fader.BackgroundColor3 = color or Color3.new(0, 0, 0)
	local s = fader.BackgroundTransparency
	local e = 0.0
	util.Tween(duration, nil, function(a)
		fader.BackgroundTransparency = s + (e-s)*a
		if fn then
			fn(a)
		end
	end)
end

function util.FadeIn(duration, fn)
	local s = fader.BackgroundTransparency
	local e = 1.0
	util.Tween(duration, nil, function(a)
		fader.BackgroundTransparency = s + (e-s)*a
		if fn then
			fn(a)
		end
	end)
end

function util.FadeOutWithCircle(duration, keepCircle)
	local create = util.Create
	local container = create 'Frame' {
		BackgroundTransparency = 1.0,
		Size = UDim2.new(1.0, 0, 1.0, 36),
		Position = UDim2.new(0.0, 0, 0.0, -36),
		Parent = util.frontGui,
	}
	local scope = create 'ImageLabel' {
		BackgroundTransparency = 1.0,
		Image = 'rbxassetid://6604522520',
		ZIndex = 9, Parent = container,
	}
	local left   = create 'Frame' { BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 9, Parent = container, }
	local right  = create 'Frame' { BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 9, Parent = container, Position = UDim2.new(1.0, 0, 0.0, 0), }
	local top    = create 'Frame' { BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 9, Parent = container, }
	local bottom = create 'Frame' { BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 9, Parent = container, Position = UDim2.new(0.0, 0, 1.0, 0), }
	util.Tween(duration or .6, nil, function(a)
		local x = container.AbsoluteSize.X * 1.42 * (1-a)
		scope.Size = UDim2.new(0.0, x, 0.0, x)
		scope.Position = UDim2.new(0.5, -x/2, 0.5, -x/2)
		left.Size   = UDim2.new(0.5, -x/2+1, 1.0, 0)
		right.Size  = UDim2.new(-0.5, x/2-1, 1.0, 0)
		top.Size    = UDim2.new(1.0, 0, 0.5, -x/2+1)
		bottom.Size = UDim2.new(1.0, 0, -0.5, x/2-1)
	end)
	if keepCircle then
		return {container, scope, left, right, top, bottom}
	else
		fader.BackgroundColor3 = Color3.new(0, 0, 0)
		fader.BackgroundTransparency = 0.0
		container:Remove()
	end
end

function util.FadeInWithCircle(duration, circle)
	local container, scope, left, right, top, bottom
	if circle then container, scope, left, right, top, bottom = unpack(circle) end
	if not container then
		local create = util.Create
		container = create 'Frame' {
			BackgroundTransparency = 1.0,
			Size = UDim2.new(1.0, 0, 1.0, 36),
			Position = UDim2.new(0.0, 0, 0.0, -36),
			Parent = util.frontGui,
		}
		scope = create 'ImageLabel' {
			BackgroundTransparency = 1.0,
			Image = 'rbxassetid://6604522520',
			ZIndex = 9, Parent = container,
		}
		left   = create 'Frame' { BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 9, Parent = container, }
		right  = create 'Frame' { BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 9, Parent = container, Position = UDim2.new(1.0, 0, 0.0, 0), }
		top    = create 'Frame' { BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 9, Parent = container, }
		bottom = create 'Frame' { BorderSizePixel = 0, BackgroundColor3 = Color3.new(0, 0, 0), ZIndex = 9, Parent = container, Position = UDim2.new(0.0, 0, 1.0, 0), }
		fader.BackgroundTransparency = 1.0
	end
	util.Tween(duration or .6, nil, function(a)
		local x = container.AbsoluteSize.X * 1.42 * a
		scope.Size = UDim2.new(0.0, x, 0.0, x)
		scope.Position = UDim2.new(0.5, -x/2, 0.5, -x/2)
		left.Size   = UDim2.new(0.5, -x/2+1, 1.0, 0)
		right.Size  = UDim2.new(-0.5, x/2-1, 1.0, 0)
		top.Size    = UDim2.new(1.0, 0, 0.5, -x/2+1)
		bottom.Size = UDim2.new(1.0, 0, -0.5, x/2-1)
	end)
	container:Remove()
end


function util.lookBackAtMe(t, leaveCameraScriptable)
	local cam = workspace.CurrentCamera
	local headP = player.Character.Head.Position
	local camGoal = CFrame.new(headP + (cam.CoordinateFrame.p-headP).unit*12.5, headP)
	local _, lerp = util.lerpCFrame(cam.CoordinateFrame, camGoal)
	util.Tween(t or .8, 'easeOutCubic', function(a)
		local cf = lerp(a)
		cam.CFrame = CFrame.new(cf.p, cf.p+cf.lookVector)
	end)
	if not leaveCameraScriptable then
		cam.CameraType = Enum.CameraType.Custom
	end
end

function util.lookAt(p, f, t)
	local cam = workspace.CurrentCamera
	local ocf = cam.CoordinateFrame
	local dynamic = false
	local lerp
	if type(f) == 'function' then
		dynamic = true
	elseif (pcall(function() return p.p end)) and not f then
		lerp = select(2, util.lerpCFrame(ocf, p))
	else
		lerp = select(2, util.lerpCFrame(ocf, CFrame.new(p, f)))
	end
	util.Tween(t or .8, 'easeOutCubic', function(a)
		local cf
		if dynamic then
			cf = select(2, util.lerpCFrame(ocf, CFrame.new(p, f(a))))(a)
		else
			cf = lerp(a)
		end
		cam.CFrame = CFrame.new(cf.p, cf.p+cf.lookVector)
	end)
end


do
	local threads = {}
	function util.Teleport(newCF, torso)
		if not torso then
			while not player.Character do wait() end -- R15 doesn't always load the character immediately; it seems it sometimes waits for the meshes?
			torso = player.Character.HumanoidRootPart
			pcall(function()
				local human = util.getHumanoid()
				if human.RigType == Enum.HumanoidRigType.R15 then
					newCF = newCF + Vector3.new(0, -3 + torso.Size.Y/2 + human.HipHeight, 0)
				end
			end)
		end
		local thisThread = {}
		threads[torso] = thisThread
		torso.Velocity  = Vector3.new()
		torso.CFrame = newCF
		while torso and torso.Parent and (torso.Position-newCF.p).magnitude > 5 and threads[torso] == thisThread do
			torso.CFrame = newCF
			wait()
		end
	end
	
	function util.TeleportToSpawnBox()
		util.Teleport(CFrame.new(3, 70, 389) + Vector3.new(math.random(-20, 20), 0, math.random(-20, 20)))
	end
end


function util.Tween(duration, timing, fn, priority)
	local doesEndZero = timing == 'sineBack'
	if duration == 0 then
		fn(1, 0)
		return true
	end
	if type(timing) == 'string' then
		timing = Timing[timing](duration)
	end
	local st = tick()
	if fn(0, 0) == false then return false end
	if priority then
		local uid = 'Tween_'..util.uid()
		local _end = util.Signal()
		local ended = false
		local runService = game:GetService('RunService')
		runService:BindToRenderStep(uid, priority, function()
			if ended then return end
			local et = tick()-st
			if et >= duration then
				ended = true
				fn(doesEndZero and 0 or 1, duration)
				_end:fire(true)
			end
			local a = et/duration
			if timing then
				a = timing(et)
			end
			if fn(a, et) == false then
				ended = true
				_end:fire(false)
			end
		end)
		local r = _end:wait()
		runService:UnbindFromRenderStep(uid)
		return r
	else
		while true do
			stepped:wait()
			local et = tick()-st
			if et >= duration then
				fn(doesEndZero and 0 or 1, duration)
				return true
			end
			local a = et/duration
			if timing then
				a = timing(et)
			end
			if fn(a, et) == false then
				return false
			end
		end
	end
end
do
	local pTweenThreads = {}
	local lerpFuncs
	do
		local objLerp = function(s, e)
			return function(a)
				return s:Lerp(e, a)
			end
		end
		lerpFuncs = {
			Vector2 = objLerp,
			Vector3 = objLerp,
			UDim2 = objLerp,
			CFrame = objLerp,
			Color3 = objLerp,
			number = function(s, e)
				local d = e - s
				return function(a)
					return s + d * a
				end
			end
		}
	end
	local Tween = util.Tween
	local function pTween(obj, prop, val, dur, timing, changedCallback, successCallback)
		local threadList = pTweenThreads[obj]
		if not threadList then
			threadList = {}
			pTweenThreads[obj] = threadList
		end
		local thisThread = {}
		threadList[prop] = thisThread
		local lerp = lerpFuncs[typeof(val)](obj[prop], val)
		Tween(dur, timing, function(a)
			if threadList[prop] ~= thisThread then
				return false
			end
			obj[prop] = lerp(a)
			if changedCallback then
				return changedCallback()
			end
		end)
		if threadList[prop] == thisThread then
			threadList[prop] = nil
			if not next(threadList) then
				pTweenThreads[obj] = nil
			end
			if successCallback then
				successCallback()
			end
		end
	end
	util.pTween = pTween
	function util.spTween(...)
		util.fastSpawn(pTween, ...)
	end
	function util.pSet(obj, prop, val)
		local threadList = pTweenThreads[obj]
		if threadList then
			threadList[prop] = nil
			if not next(threadList) then
				pTweenThreads[obj] = nil
			end
		end
		obj[prop] = val
	end
end
function util.MoveModel(part, newcf, recursive)
	local function MMRecursive(part, newcf, dm, r)
		local model = dm
		if not model then model = part.Parent end
		for _, p in pairs(model:GetChildren()) do
			if p ~= part and p:IsA('BasePart') and not p:IsA('Terrain') then
				p.CFrame = newcf:toWorldSpace(part.CFrame:toObjectSpace(p.CFrame))
			elseif p:IsA('Model') and r then
				MMRecursive(part, newcf, p, true)
			end
		end
		if not dm then
			part.CFrame = newcf
		end
	end
	MMRecursive(part, newcf, nil, recursive)
end

function util.ScaleModel(rootPart, scale, recursive)
	local c = rootPart.CFrame
	local function scaleSubModel(model)
		for _, part in pairs(model:GetChildren()) do
			if part:IsA('BasePart') then
				local cf = part.CFrame
				local s = part.Size
				part.Size = s * scale
				local S = scale * (s/part.Size)
				local m = part:FindFirstChild('Mesh')

                --[[if part.Size ~= s * scale and not m then
                    m = Instance.new('SpecialMesh')
                    m.MeshType = part:IsA('WedgePart') and Enum.MeshType.Wedge or Enum.MeshType.Brick
                    m.Parent = part
                end--]]

				if m then
					if m:IsA('BlockMesh') or m:IsA('CylinderMesh') or (m:IsA('SpecialMesh') and m.MeshId == '') then
						m.Scale = m.Scale * S--scale
					else
						m.Scale = m.Scale * scale
					end
					m.Offset = m.Offset * scale
				end

				local dif = cf.p - c.p
				dif = dif * scale
				local newpos = c.p + dif
				part.CFrame = cf - (cf.p-newpos)
			elseif recursive and part:IsA('Model') then
				scaleSubModel(part)
			end
		end
	end
	scaleSubModel(rootPart.Parent)
end

-- mutates ignoreList
function util.findPartOnRayWithIgnoreFunction(ray, ignoreList, ignoreFunction)
	if type(ignoreList) == 'function' then
		ignoreFunction = ignoreList
		ignoreList = {}
	end
	local hit, pos, normal, material
	repeat
		hit, pos, normal, material = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
		if hit then
			if ignoreFunction(hit) then
				table.insert(ignoreList, hit)
			else
				return hit, pos, normal, material
			end
		end
	until not hit
	return hit, pos, normal, material
end

function util.Signal(debugOff)
	local sig = {}
	
	local mSignaler = Instance.new('BindableEvent')
	
	local mArgData = nil
	local mArgDataCount = nil
	
	function sig:fire(...)
--		if not debugOff then
--			print('firing signal')
--			print(debug.traceback())
--		end
		mArgData = {...}
		mArgDataCount = select('#', ...)
		mSignaler:Fire()
	end
	
	function sig:connect(f)
		if not f then error('connect(nil)', 2) end
		return mSignaler.Event:connect(function()
			f(unpack(mArgData, 1, mArgDataCount))
		end)
	end
	
	function sig:wait()
		mSignaler.Event:wait()
		assert(mArgData, 'Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.')
		return unpack(mArgData, 1, mArgDataCount)
	end
	
	return sig
end

function util.fastSpawn(fn, ...)
	local sig = util.Signal(true)
	sig:connect(fn)
	sig:fire(...)
end

function util.extents(pos, size)
	local cam = workspace.CurrentCamera
	local cf = CFrame.new(pos, pos + cam.CoordinateFrame.lookVector)
	local p = cam:WorldToScreenPoint(pos)
	local p1 = cam:WorldToScreenPoint((cf*CFrame.new(-size/2, -size/2, 0)).p)
	local p2 = cam:WorldToScreenPoint((cf*CFrame.new( size/2,  size/2, 0)).p)
	return Vector2.new(p.x, p.y), (p1-p2).magnitude / math.sqrt(2), p.z > 0
end

function util.sound(id, volume, playFromTime, RemoveAfter, playFromPart)
	local sound = util.Create 'Sound' {
		SoundId = type(id)=='number' and ('rbxassetid://'..id) or id,
		Volume = volume or .5,
		TimePosition = playFromTime or 0,
		Parent = playFromPart and playFromPart or (util.soundContainer or workspace),
	}
	sound:Play()
	delay(RemoveAfter or 120, function()
		sound:Remove()
	end)
	return sound
end

function util.loopSound(id, volume, loopId)
	if type(id) == 'table' then
		id, loopId = unpack(id)
	end
	if id == 10723773194 then volume = .7 end -- eclipse battle music
	local sound = util.Create 'Sound' {
		SoundId = type(id)=='number' and ('rbxassetid://'..id) or id,
		Volume = volume or .5,
		Looped = loopId==nil,
		Parent = util.soundContainer or workspace,
	}
	local sound2
	local stopped = false
	if loopId then
		sound2 = util.Create 'Sound' {
			SoundId = type(loopId)=='number' and ('rbxassetid://'..loopId) or loopId,
			Volume = volume or .5,
			Looped = true,
			Parent = util.soundContainer or workspace,
		}
		sound.Ended:connect(function()
			if stopped then return end
			sound2.Volume = sound.Volume
			sound2.Name = sound.Name
			local oldSound = sound
			delay(.5, function() -- Jul 28 '16 ROBLOX update bug workaround
				oldSound:Remove()
			end)
			sound = sound2
			sound2 = nil
			sound:Play()
		end)
	end
	sound:Play()
	return setmetatable({
		Stop = function()
			stopped = true
			sound:Stop()
		end,
		Remove = function()
			stopped = true
			sound:Stop()
			delay(.5, function() -- Jul 28 '16 ROBLOX update bug workaround
				sound:Remove()
				if sound2 then sound2:Remove() end
			end)
		end
	}, {
		__index = function(_, key)
			return sound[key]
		end,
		__newindex = function(_, key, value)
			sound[key] = value
		end
	})
end

function util.weightedRandom(objects, getWeight, rand)
	if not objects or #objects == 0 then return nil end
	rand = rand or math.random
	local objectsAndWeights = {}
	local totalWeight = 0
	for _, obj in pairs(objects) do
		local weight = getWeight(obj)
		table.insert(objectsAndWeights, {obj, weight})
		totalWeight = totalWeight + weight
	end
	local r = rand()*totalWeight
	for _, thing in pairs(objectsAndWeights) do
		if thing[2] >= r then
			return thing[1]
		end
		r = r - thing[2]
	end
	warn('! defaulting to last object in wtRdm') -- should never execute this
	return objectsAndWeights[#objectsAndWeights][1]
end

function util.pageItemPairs(pages)
	return coroutine.wrap(function()
		local itemnum = 1
		local pagenum = 1
		while true do
			for _, item in ipairs(pages:GetCurrentPage()) do
				coroutine.yield(pagenum, itemnum, item)
				itemnum = itemnum + 1
			end
			if pages.IsFinished then
				break
			end
			pages:AdvanceToNextPageAsync()
			pagenum = pagenum + 1
		end
	end)
end

function util.hsb( h, s, v ) -- h = 0..360, s = 0..1, v = 0..1
	if s == 0 then
		return Color3.new(v, v, v)
	end
	h = h / 60
	local i = math.floor(h)
	local f = h - i
	local p = v * ( 1 - s )
	local q = v * ( 1 - s * f )
	local t = v * ( 1 - s * ( 1 - f ) )
	if i == 0 then
		return Color3.new(v, t, p)
	elseif i == 1 then
		return Color3.new(q, v, p)
	elseif i == 2 then
		return Color3.new(p, v, t)
	elseif i == 3 then
		return Color3.new(p, q, v)
	elseif i == 4 then
		return Color3.new(t, p, v)
	end
	return Color3.new(v, p, q)
end


function util.comma_value(n)
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

do
	local rc4 = require(script.RC4) 'Rx-7i3zv,6Rg]~t'
	util.rc4 = rc4
	function util.rc4equal(x, y)
		local typeX = type(x)
		if typeX ~= type(y) then return false end
		if typeX == 'table' then return rc4(x) == rc4(y) end
		return x == y
	end
end

function util.exclaim(object)
	local create = util.Create
	local part = create 'Part' {
		Size = Vector3.new(1, 1, 1),
		Anchored = true,
		CanCollide = false,
		Transparency = 1.0,
		CFrame = object.CFrame * CFrame.new(0, 2, 0),
		Parent = workspace,
	}
	local bbg = create 'BillboardGui' {
		Adornee = part,
		Parent = part,
	}
	local exc = create 'Frame' {
		BackgroundTransparency = 1.0,
		Size = UDim2.new(0.0, 0, 0.2, 0),
		Parent = gui,
	}
	util.Write '!' {
		Frame = exc,
		Scaled = true,
	}
	exc.Parent = bbg
	exc.Size = UDim2.new(1.0, 0, 1.0, 0)
	local duration = .35
	util.Tween(duration, util.Timing.cubicBezier(duration, .85, 0, .6, 2), function(a)
		bbg.Size = UDim2.new(1.8, 0, 1.8*a, 0)
	end)
	wait(.25)
	bbg:Remove()
	part:Remove()
end

function util.question(object)
	local create = util.Create
	local part = create 'Part' {
		Size = Vector3.new(1, 1, 1),
		Anchored = true,
		CanCollide = false,
		Transparency = 1.0,
		CFrame = object.CFrame * CFrame.new(0, 2, 0),
		Parent = workspace,
	}
	local bbg = create 'BillboardGui' {
		Adornee = part,
		Parent = part,
	}
	local exc = create 'Frame' {
		BackgroundTransparency = 1.0,
		Size = UDim2.new(0.0, 0, 0.2, 0),
		Parent = gui,
	}
	util.Write '?' {
		Frame = exc,
		Scaled = true,
	}
	exc.Parent = bbg
	exc.Size = UDim2.new(1.0, 0, 1.0, 0)
	local duration = .35
	util.Tween(duration, util.Timing.cubicBezier(duration, .85, 0, .6, 2), function(a)
		bbg.Size = UDim2.new(1.8, 0, 1.8*a, 0)
	end)
	wait(.25)
	bbg:Remove()
	part:Remove()
end

function util.hexToRGB(str)
	str = str:lower()
	if string.sub(str, 1, 1) == "#" then
		str = string.sub(str, 2)
	end
	local m = 16
	local tab = {
		a = 10,
		b = 11,
		c = 12,
		d = 13,
		e = 14,
		f = 15
	}
	local fin = {}
	for i = 1, string.len(str) do
		local char = string.sub(str, i, i)
		local n = tonumber(char) or tab[char] or 0
		if i == 1 or i == 3 or i == 5 then
			fin[i] = n * m
		else
			fin[i] = n
		end
	end
	return fin[1] + fin[2], fin[3] + fin[4], fin[5] + fin [6]
end

function util.rgbToHEX(cr, cg, cb)
	local cr1 = math.floor(cr/16)
	local cr2 = cr - cr1 * 16
	local cg1 = math.floor(cg/16)
	local cg2 = cg - cg1 * 16
	local cb1 = math.floor(cb/16)
	local cb2 = cb - cb1 * 16
	local str = ""
	local tab = {
		[10] = "a",
		[11] = "b",
		[12] = "c",
		[13] = "d",
		[14] = "e",
		[15] = "f"
	}
	local function tonum(n)
		if n >= 10 and n <= 15 then
			return tab[n]
		elseif n > 15 then
			return 0
		end
		return n
	end
	str = (tonum(cr1) .. tonum(cr2) .. tonum(cg1) .. tonum(cg2) .. tonum(cb1) .. tonum(cb2)):upper()
	return "#" .. str
end

function util.uiGradient(gradient)
	gradient = gradient:lower()
	local gradients = {
		['coolsky'] = ColorSequence.new(Color3.fromRGB(util.hexToRGB('#2980B9')), Color3.fromRGB(util.hexToRGB('#6DD5FA'))),
		['gradegrey'] = ColorSequence.new(Color3.fromRGB(util.hexToRGB('#bdc3c7')), Color3.fromRGB(util.hexToRGB('#2c3e50'))),
		['moonlit'] = ColorSequence.new(Color3.fromRGB(util.hexToRGB('#0F2027')), Color3.fromRGB(util.hexToRGB('#2C5364'))),
		['brightpurple'] = ColorSequence.new(Color3.fromRGB(util.hexToRGB('#8E2DE2')), Color3.fromRGB(util.hexToRGB('#4A00E0'))),
		['piggypink'] = ColorSequence.new(Color3.fromRGB(util.hexToRGB('#ee9ca7')), Color3.fromRGB(util.hexToRGB('#ffdde1'))),
		['jshine'] = ColorSequence.new(Color3.fromRGB(util.hexToRGB('#12c2e9')), Color3.fromRGB(util.hexToRGB('#c471ed')), Color3.fromRGB(util.hexToRGB('#f64f59'))),
		['rainbowblue'] = ColorSequence.new(Color3.fromRGB(util.hexToRGB('#00F260')), Color3.fromRGB(util.hexToRGB('#0575E6'))),
		['ultraviolet'] = ColorSequence.new(Color3.fromRGB(util.hexToRGB('#654ea3')), Color3.fromRGB(util.hexToRGB('#eaafc8'))),
		['citruspeel'] = ColorSequence.new(Color3.fromRGB(util.hexToRGB('#fdc830')), Color3.fromRGB(util.hexToRGB('#f37335'))),
		['terminal'] = ColorSequence.new(Color3.fromRGB(util.hexToRGB('#000000')), Color3.fromRGB(util.hexToRGB('#0f9b0f'))),
		['lush'] = ColorSequence.new(Color3.fromRGB(util.hexToRGB('#56ab2f')), Color3.fromRGB(util.hexToRGB('#a8e063'))),
		['orangefun'] = ColorSequence.new(Color3.fromRGB(util.hexToRGB('#fc4a1a')), Color3.fromRGB(util.hexToRGB('#f7b733'))),
		['rainbow'] = ColorSequence.new(Color3.fromRGB(util.hexToRGB('#FF0000')), Color3.fromRGB(util.hexToRGB('#FF7F00')), Color3.fromRGB(util.hexToRGB('#FFFF00')), Color3.fromRGB(util.hexToRGB('#00FF00')), Color3.fromRGB(util.hexToRGB('#0000FF')), Color3.fromRGB(util.hexToRGB('#2E2B5F')), Color3.fromRGB(util.hexToRGB('#8B00FF'))),
		--['xmasv1'] = ColorSequence.new({ColorSequenceKeypoint.new(Color3.fromRGB(util.hexToRGB('#ED213A')),0),ColorSequenceKeypoint.new(Color3.fromRGB(util.hexToRGB('#56ab2f')),.5),ColorSequenceKeypoint.new(Color3.fromRGB(util.hexToRGB('#283c86')),1)}),
		['netflix'] = ColorSequence.new(Color3.fromRGB(util.hexToRGB('#8E0E00')), Color3.fromRGB(util.hexToRGB('#1F1C18'))),
		['darknight'] = ColorSequence.new(Color3.fromRGB(util.hexToRGB('#BA8B02')), Color3.fromRGB(util.hexToRGB('#181818'))),
		['loveandliberty'] = ColorSequence.new(Color3.fromRGB(util.hexToRGB('#200122')), Color3.fromRGB(util.hexToRGB('#6f0000'))),
	}
	local gradientkeywords = {}
	for k, v in pairs(gradients) do
		gradientkeywords[k] = v
	end
	for k, word in pairs(gradientkeywords) do
		local grad = gradients[gradient]
		local keyword = gradient:lower()
		if gradient == keyword then
			return grad
		end
	end
end

function util.shineGradientTween(time, esd, fn, objs)
	local tweenLibrary = {
		EasingStyles = {
			Linear = Enum.EasingStyle.Linear,
			Sine = Enum.EasingStyle.Sine,
			Back = Enum.EasingStyle.Back,
			Quad = Enum.EasingStyle.Quad,
			Quart = Enum.EasingStyle.Quart,
			Quint = Enum.EasingStyle.Quint,
			Bounce = Enum.EasingStyle.Bounce,
			Elastic = Enum.EasingStyle.Elastic,
			Exponential = Enum.EasingStyle.Exponential,
			Circular = Enum.EasingStyle.Circular,
			Cubic = Enum.EasingStyle.Cubic,
		},
		EasingDirections = {
			In = Enum.EasingDirection.In,
			Out = Enum.EasingDirection.Out,
			InOut = Enum.EasingDirection.InOut
		}
	}
	local es = tweenLibrary.EasingStyles
	local ed = tweenLibrary.EasingDirections

	if esd == "easeInLinear" then
		esd = {EasingStyle = es.Linear, EasingDirection = ed.In}
	elseif esd == "easeInSine" then
		esd = {EasingStyle = es.Sine, EasingDirection = ed.In}
	elseif esd == "easeInBack" then
		esd = {EasingStyle = es.Back, EasingDirection = ed.In}
	elseif esd == "easeInQuad" then
		esd = {EasingStyle = es.Quad, EasingDirection = ed.In}
	elseif esd == "easeInQuart" then
		esd = {EasingStyle = es.Quart, EasingDirection = ed.In}
	elseif esd == "easeInQuint" then
		esd = {EasingStyle = es.Quint, EasingDirection = ed.In}
	elseif esd == "easeInBounce" then
		esd = {EasingStyle = es.Bounce, EasingDirection = ed.In}
	elseif esd == "easeInElastic" then
		esd = {EasingStyle = es.Elastic, EasingDirection = ed.In}
	elseif esd == "easeInExponential" then
		esd = {EasingStyle = es.Exponential, EasingDirection = ed.In}
	elseif esd == "easeInCircular" then
		esd = {EasingStyle = es.Circular, EasingDirection = ed.In}
	elseif esd == "easeInCubic" then
		esd = {EasingStyle = es.Cubic, EasingDirection = ed.In}
	elseif esd == "easeOutLinear" then
		esd = {EasingStyle = es.Linear, EasingDirection = ed.Out}
	elseif esd == "easeOutSine" then
		esd = {EasingStyle = es.Sine, EasingDirection = ed.Out}
	elseif esd == "easeOutBack" then
		esd = {EasingStyle = es.Back, EasingDirection = ed.Out}
	elseif esd == "easeOutQuad" then
		esd = {EasingStyle = es.Quad, EasingDirection = ed.Out}
	elseif esd == "easeOutQuart" then
		esd = {EasingStyle = es.Quart, EasingDirection = ed.Out}
	elseif esd == "easeOutQuint" then
		esd = {EasingStyle = es.Quint, EasingDirection = ed.Out}
	elseif esd == "easeOutBounce" then
		esd = {EasingStyle = es.Bounce, EasingDirection = ed.Out}
	elseif esd == "easeOutElastic" then
		esd = {EasingStyle = es.Elastic, EasingDirection = ed.Out}
	elseif esd == "easeOutExponential" then
		esd = {EasingStyle = es.Exponential, EasingDirection = ed.Out}
	elseif esd == "easeOutCircular" then
		esd = {EasingStyle = es.Circular, EasingDirection = ed.Out}
	elseif esd == "easeOutCubic" then
		esd = {EasingStyle = es.Cubic, EasingDirection = ed.Out}
	end

	if type(objs) == 'table' then
		for _, obj in pairs(objs) do
			local tInfo = TweenInfo.new(time, esd.EasingStyle, esd.EasingDirection, 0, false, 0)
			local twn = game:GetService("TweenService"):Create(obj, tInfo, fn)
			twn:Play()
			return twn
		end
	elseif type(objs) == 'userdata' then
		local tInfo = TweenInfo.new(time, esd.EasingStyle, esd.EasingDirection, 0, false, 0)
		local twn = game:GetService("TweenService"):Create(objs, tInfo, fn)
		twn:Play()	
		return twn	
	end
end

function util.shineGradient(grad)
	local c = util.shineGradientTween(0.5, 'easeOutCircular', {Offset = Vector2.new(1.5, 0)}, grad)
	local sp = Vector2.new(-1.5, 0) 
	local a = 2.5
	c.Completed:Wait() 
	--grad.Offset = sp 
	c:Play() 
	c.Completed:Wait()
	local oc = util.shineGradientTween(0.5, 'easeOutCircular', {Offset = sp}, grad)
	oc:Play() 
	oc.Completed:Wait()
	util.shineGradient(grad)
end

function util.aOrAn(str, upper)
	local vowels = {a=true,e=true,i=true,o=true,u=true}
	if vowels[str:sub(1,1):lower()] then
		return upper and 'An '..str or 'an '..str
	end
	return upper and 'A '..str or 'a '..str
end


function util.map(t, fn)
	local newT = {}
	for k, v in pairs(t) do
		newT[k] = fn(v)
	end
	return newT
end

local debugSyncs = false
function util.Sync(fnList) -- returns the first return value of each function as collective tuple
--	print('synchronizing', #fnList, 'functions')
	local nFunctions = 0
	local nReturnedFunctions = 0
	local completionSignal = util.Signal()
	local err
	local returnList = {}
	for i, fn in pairs(fnList) do
		if type(fn) == 'function' then
			nFunctions = nFunctions + 1
			util.fastSpawn(function()
				if debugSyncs then
					local s, r = pcall(fn)
					if s then
						nReturnedFunctions = nReturnedFunctions + 1
						returnList[i] = r
					else
						err = r
					end
				else
					returnList[i] = (fn())
					nReturnedFunctions = nReturnedFunctions + 1
				end
				completionSignal:fire()
			end)
		end
	end
	while nReturnedFunctions < nFunctions do
		if err then
			error('Encountered an error during sync: '..err)
		end
		completionSignal:wait()
	end
	return unpack(returnList)
end


function util.GetNameColor(pName)
	local value = 0
	for index = 1, #pName do
		local cValue = string.byte(string.sub(pName, index, index))
		local reverseIndex = #pName - index + 1
		if #pName%2 == 1 then
			reverseIndex = reverseIndex - 1
		end
		if reverseIndex%4 >= 2 then
			cValue = -cValue
		end
		value = value + cValue
	end
	value = value%8
	local colors = {
		Color3.new(253/255, 41/255, 67/255), -- BrickColor.new("Bright red").Color,
		Color3.new(1/255, 162/255, 255/255), -- BrickColor.new("Bright blue").Color,
		Color3.new(2/255, 184/255, 87/255), -- BrickColor.new("Earth green").Color,
		BrickColor.new("Lavender").Color, -- BrickColor.new("Bright violet").Color,
		BrickColor.new("Bright orange").Color,
		BrickColor.new("Bright yellow").Color,
		BrickColor.new("Light reddish violet").Color,
		BrickColor.new("Brick yellow").Color,
	}
	return colors[value+1]
end


-- https://coronalabs.com/blog/2014/09/02/tutorial-printing-table-contents/
-- maxDepth added
function util.print_r ( t , maxDepth )  
    local print_r_cache={}
    local function sub_print_r(t,indent,mDepth)
		if mDepth == 0 then print(indent..'...') return end
        if (print_r_cache[tostring(t)]) then
            print(indent.."*"..tostring(t))
        else
            print_r_cache[tostring(t)]=true
            if (type(t)=="table") then
                for pos,val in pairs(t) do
                    if (type(val)=="table") then
                        print(indent.."["..pos.."] => "..tostring(val).." {")
                        sub_print_r(val,indent..string.rep(" ",string.len(pos)+8),mDepth and mDepth-1)
                        print(indent..string.rep(" ",string.len(pos)+6).."}")
                    elseif (type(val)=="string") then
                        print(indent.."["..pos..'] => "'..val..'"')
                    else
                        print(indent.."["..pos.."] => "..tostring(val))
                    end
                end
            else
                print(indent..tostring(t))
            end
        end
    end
    if (type(t)=="table") then
        print(tostring(t).." {")
        sub_print_r(t,"  ",maxDepth)
        print("}")
    else
        sub_print_r(t,"  ")
    end
    print()
end




return util
