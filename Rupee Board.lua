
local powerupsTable = {
	{"[1CE055]Green rupee[-] [Trophy]", "[EEFF00]Yellow rupee[-] [Trophy]", "[1965E8]Blue rupee[-] [Trophy]"},
	{"[E81931]Red rupee[-] [Trophy]", "[AD51C2]Purple rupee[-] [Trophy]", "[F06800]Orange rupee[-] [Trophy]"},
	{"[BEBEBE]Silver rupee[-] [Trophy]", "[DEB444]Gold rupee[-] [Trophy]", "[514464]Rupoor[-] [Trophy]"},
}
local numPowerups = {}
for i=1,#powerupsTable do
	for n=1,#powerupsTable[i] do
		numPowerups[powerupsTable[i][n]] = 0
		_G["doDeploy_"..tostring(powerupsTable[i][n])] = function(_,c)
			deployQueue(tostring(powerupsTable[i][n]), c)
		end
	end
end

PendingDesc = nil
buttons = {}

-- Initialization
function onLoad(state)
	nextUpdate = os.time() + 2
	
	buttons = {}
	
	if state and state~="" then
		local decode = JSON.decode(state)
		
		for k in pairs(numPowerups) do
			if decode[k] then
				numPowerups[k] = decode[k]
			end
		end
	end
end
function onSave()
	return JSON.encode(numPowerups)
end
function forceSave()
	self.script_state = JSON.encode(numPowerups)
end
function onDestroy()
	Timer.destroy("PowerupBoardRefresh_"..tostring(self.guid))
end

local function ProcessQueue()
	if os.time()<nextUpdate then return end
	
	if PendingDesc then
		self.setDescription( PendingDesc )
		PendingDesc = nil
	end
	
	while #deployQueueData>0 do
		nextUpdate = nextUpdate+0.1
		if deployPowerup(deployQueueData[1]) then
			table.remove(deployQueueData, 1)
			break
		else
			table.remove(deployQueueData, 1)
		end
	end
end
function onUpdate()
	if os.time()<nextUpdate then return end
	
	buttons = {}
	makeButtons()
	
	Timer.create({ identifier = "PowerupBoardRefresh_"..tostring(self.guid), function_name = "countPowerups", delay = 2, repetitions = 0 })
	
	deployQueueData = {}
	onUpdate = ProcessQueue
end

function onObjectEnterContainer(bag,o)
	if bag==self then
		countPowerups()
		return
	end
	if o~=self then return end
	
	Timer.destroy("PowerupBoardRefresh_"..tostring(self.guid))
end

function GetZoneID( searchID )
	local ownerID = string.match(self.getDescription(), "^(%d+) %- .*")
	local otherID = string.match(searchID, "^(%d+) %- .*")
	
	if not otherID then return false end
	
	local seated = getSeatedPlayers()
	for i=1,#seated do
		seated[ seated[i] ] = true
		seated[i] = nil
	end
	
	local objectSets = Global.getTable("objectSets")
	if not objectSets then return false end
	
	local foundID = false
	for i=1,#objectSets do
		local set = objectSets[i]
		if set and seated[set.color] then
			for _,v in pairs({"zone","tbl","prestige"}) do
				for _,obj in pairs(set[v].getObjects()) do
					if obj==self then
						if Player[set.color].steam_id==ownerID then  -- If there's an overlap, we prioritise our own zone
							return false
						end
						
						if Player[set.color].steam_id==otherID then
							foundID = true
							break
						end
					end
				end
			end
		end
	end
	
	return foundID
end

-- Buttons
function countPowerups()
	local objects = self.getObjects()
	
	for i=1,#objects do
		local drawn = self.takeObject({position=pos})
		local name = drawn.getName()
		if numPowerups[name] then
			local meshData = drawn.getCustomObject()
			
			local stackSize = (drawn.getQuantity()==(-1) and 1) or drawn.getQuantity()
			
			numPowerups[name] = numPowerups[name] + stackSize
			
			drawn.destruct()
		else
			if drawn.getName()==self.getName() then
				local pwups = JSON.decode(drawn.script_state or "") -- It's too early for obj.getTable(), script hasn't loaded
				if pwups then
					for k,v in pairs(pwups) do
						if numPowerups[k] then
							numPowerups[k] = numPowerups[k] + math.max( v or 0, 0 )
						end
					end
				end
				
				local drawnDesc = drawn.getDescription()
				if drawnDesc~=self.getDescription() then
					if (self.held_by_color and self.held_by_color~="Black") or GetZoneID(drawnDesc) then
						self.setDescription(drawnDesc)
						self.translate({0,0.1,0})
					end
				end
				
				destroyObject(drawn)
			else
				drawn.setPosition(getDeployPosition(drawn))
				drawn.setLock(false)
				drawn.interactable = true
				
				Wait.frames(function()
					if drawn and not (drawn==nil) then
						drawn.setPosition(getDeployPosition(drawn))
					end
				end, 0)
			end
		end
	end
	
	updateButtons()
	forceSave()
end
function makeButtons()
	self.clearButtons()
	
	buttons = {}
	local buttonIndex = 0
	for row = 1,#powerupsTable do
		local numColumns = #powerupsTable[row]
		local startPos = (numColumns - 1) * (-1)
		local rowPos = (row*2.91)-6.4
		
		buttons[row] = {}
		
		for column = 1,#powerupsTable[row] do
			local count = numPowerups[powerupsTable[row][column]] or 0
			self.createButton({
				label="", click_function="doDeploy_"..tostring(powerupsTable[row][column]), function_owner=self,
				position={startPos+ (column-1)*2,0.1,rowPos}, rotation={0,0,0}, width=960, height=1400, font_size=150,
				color = count==0 and {r=0,g=0,b=0, a=0.85} or {r=0.5,g=0.75,b=0.5, a=0}, tooltip=tostring(powerupsTable[row][column])
			})
			
			-- Drop-shadow counter text. There's no way to draw text directly, this will hit performance.
			local str = "[b]"..tostring(count).."[-]"
			local btnPos = {x=startPos+ (column-1)*2 +0.65, y=0.1, z=rowPos+0.95}
			self.createButton({
				label=str, click_function="null", function_owner=self,
				position={btnPos.x+0.02,0.1,btnPos.z+0.02}, rotation={0,0,0}, width=0, height=0, font_size=250,
				font_color = {r=0,g=0,b=0},
			})
			self.createButton({
				label=str, click_function="null", function_owner=self,
				position=btnPos, rotation={0,0,0}, width=0, height=0, font_size=250,
				font_color = {r=1,g=1,b=1},
			})
			
			buttons[row][column] = {btn=buttonIndex, txt=buttonIndex+2, shadow=buttonIndex+1, count=count, btnPos=btnPos}
			buttonIndex = buttonIndex + 3
		end
	end
end
function updateButtons()
	for row = 1,#buttons do
		for column = 1,#buttons[row] do
			local newCount = numPowerups[powerupsTable[row][column]] or 0
			local btnData = buttons[row][column]
			if newCount~=btnData.count then
				local str = "[b]"..tostring(newCount).."[-]"
				self.editButton({index=btnData.btn, color = (newCount==0 and {r=0,g=0,b=0, a=0.85} or {r=0.5,g=0.75,b=0.5, a=0})})
				
				self.editButton({index=btnData.shadow, label = str})
				self.editButton({index=btnData.txt, label = str})
				
				btnData.count = newCount
			end
		end
	end
	
end

-- Deploy Powerup
function null() end
function deployPowerup(name)
	if (not numPowerups[name]) then return end
	
	if (numPowerups[name] or 0)>=1 then
		numPowerups[name] = numPowerups[name]-1
		local data = numPowerups[name]
		local pos = getDeployPosition()
		
		local chosenObject
		local powerupTable = Global.getTable("powerupTable")
		if (powerupTable) and #powerupTable>0 then
			for i=1,#powerupTable do
				local chosenPowerup = powerupTable[i]
				local obj = getObjectFromGUID(chosenPowerup[1])
				
				if obj and obj.getName()==name then
					chosenObject = obj
				end
			end
		end
		if not chosenObject then
			for _,obj in pairs(getAllObjects()) do
				if obj.getLock() and obj.getName()==name then
					chosenObject = obj
					
					break
				end
			end
		end
		if not chosenObject then
			return false
		end
		
		local params = {}
		params.position = getDeployPosition()
		local clone = chosenObject.clone(params)
		clone.unlock()
		clone.interactable = true
		clone.setPosition(params.position)
		clone.setRotation(self.getRotation())
		
		countPowerups()
		
		return true
	else -- Check contents
		local objects = self.getObjects()
		
		for _,obj in pairs(objects) do
			if obj.name==name then
				local pos = getDeployPosition()
				
				self.takeObject({position = pos, guid = obj.guid})
				countPowerups()
				
				return true
			end
		end
	end
	
	return false
end
function deployQueue(name, col)
	if not name then return end
	if col and not Player[col].admin then
		local id = string.match(self.getDescription(), "^(%d+) %- .*")
		
		if id and Player[col].steam_id~=id then
			Player[col].print("This isn't yours!", {r=1,g=0,b=0})
			return
		end
	end
	
	if (not numPowerups[name]) then return end
	
	table.insert(deployQueueData, name)
end

function getDeployPosition(obj)
	if obj then
		local objBounds = obj.getBoundsNormalized()
		local objScale = obj.getScale()
		local zMod = math.max(objBounds.size.z, 1) * objScale.z
		
		local scale = self.getScale()
		return self.positionToWorld({ 0, 8+scale.y, ((-1)/scale.z)-5 -(1.5*zMod) })
	else
		local scale = self.getScale()
		return self.positionToWorld({ 0, 8+scale.y,  ((-1)/scale.z)-5 })
	end
end

function onPickUp( col )
	if col~="Black" and self.getDescription()=="" and not PendingDesc then
		PendingDesc = Player[col].steam_id  .." - ".. Player[col].steam_name
	end
	
	local plyID = Player[col].steam_id
	local boardID = self.getDescription():match("^(%d+) %- .*")
	
	if boardID and boardID~=plyID then return end -- Only manage our own boards
	
	local holding = Player[col].getHoldingObjects()
	for i=1,#holding do
		if holding[i]~=self and holding[i].getLuaScript()==self.getLuaScript() then
			destroyObject(self)
			return
		end
	end
end


function onBlackjackDestroyItems(data)
	if data.destroyPowerups then
		local pwupTable = Global.getTable("powerupEffectTable")
		for name,v in pairs(numPowerups) do
			if pwupTable[name] then -- It's a powerup
				numPowerups[name] = 0
			end
		end
		forceSave()
	end
end
