--------------------------------------------------------------------------------
--[[						MrStump's Blackjack Table					   ]]--
--------------------------------------------------------------------------------
-- Heavy automation and modification by my_hat_stinks
--[[Table of Contents:
	1. Configuration
	2. Powerup Detection
	3. Powerup effects
	4. Card Zone Counting/display
	5. Deck Finding/Tracking
	6. Card Dealing
	7. Functions to find data
	8. Button click Functions
	9. Button creation
]]
function onload()
	--[[The powerupEffectTable allows you to attach an effect to figurines as well as
		limit who they can be used on. Combine these factors to make custom powerups.
		The name field is the name of your powerup. Powerups can only be figurines
		On custom models, that means you need to have it set. right click > custom > figurine
	Available Options:
		WHO - the 'who' field must have one of the below entries
			"Anyone" = usuable on anyone
			"Any Player" = usable on any play, but not the dealer
			"Other Player" = only usuable on other players, not dealer or self
			"Self Only" = only usuable on your own hand zone
			"Dealer Only" = only usable on the dealer hand zone
			"Colorname" = only usable on that color space, by anyone (ex: "Yellow")
		EFFECT - the 'effect' field must have one of the below entries
			"Clear" - Removes any cards or powerups in the target zone
			"Alt. Clear" - Removes any cards or powerups in the target zone, respawns powerup played
			"Redraw" - Removes cards and deals 2 new cards
			"Redraw All" - Removes cards and deals 2 new cards to every betting player
			"Swap" - Exchanges cards in one zone with those in another
			"Clone" - Replaces player's own cards with those from another, leaving the origionals
			"Destroy" - Destroys the last dealt card (any player), can only be played mid-round
			"Reveal" - Flips over any face-down card
			"Stand" - Reveals second card and hides the following cards
			"Draw 1" - Forces individual powerup is played on to draw a card. Only works with 1
			"Powerup Draw" - Draws 1 random powerup from the powerupTable
			"Rupee Pull" - Pulls 1 random rupee from the rupeeWallet
			"Reset Timer" - Reduces the bonus round timer to 3 seconds
	]]--
	powerupEffectTable = {
		["Force the dealer to reveal their facedown card"] = {who="Dealer Only", effect="Reveal"},
		["Force the dealer to stand on two cards"] = {who="Dealer Only", effect="Stand"},
		["Force the dealer to draw an additional card"] = {who="Dealer Only", effect="Draw 1"},
		["Copy another player's hand"] = {who="Other Player", effect="Clone"},
		["Exit from the round"] = {who="Self Only", effect="Clear"},
		["Help another player exit from the round"] = {who="Other Player", effect="Clear"},
		["Discard your hand and stand on 19"] = {who="Self Only", effect="Alt. Clear"},
		["Swap hands with another player"] = {who="Other Player", effect="Swap"},
		["Swap hands with the dealer"] = {who="Dealer Only", effect="Swap"},
		["Random powerup draw"] = {who="Self Only", effect="Powerup Draw"},
		["Random rupee pull"] = {who="Self Only", effect="Rupee Pull"},
		["Reward token"] = {who="Self Only", effect="Reward Token"},
		["Royal token"] = {who="Self Only", effect="Royal Token"},
		["Prestige token"] = {who="Self Only", effect="Prestige Token"},
		
		-- Card numbers only
		["+1 to anyone's hand"] = {who="Anyone", effect="Card Mod"},    ["+1 to any player's hand"] = {who="Any Player", effect="Card Mod"},
		["-1 from anyone's hand"] = {who="Anyone", effect="Card Mod"},
		["+3 to anyone's hand"] = {who="Anyone", effect="Card Mod"},    ["+3 to any player's hand"] = {who="Any Player", effect="Card Mod"},
		["-3 from anyone's hand"] = {who="Anyone", effect="Card Mod"},
		["+10 to your own hand"] = {who="Self Only", effect="Card Mod"},
		
		["Force the dealer to bust"] = {who="Dealer Only", effect="Card Mod"},
		
		-- Internal - Do not use
		["Fifth Card"] = {who="", effect="FifthCard"},
	}
	
	powerupTable = {}
	for _,id in pairs({ "2c564b", "432519", "cd6cd1", "a4883c", "7b7031", "4a8de2", "fcaebe", "48ae1d", "3bf915", "b5851f", "81121a", "60a985", "c663e1", "f0150d", "84928d" }) do
		local obj = getObjectFromGUID(id)
		if obj then
			table.insert(powerupTable, {id, obj.getName()})
		end
	end
	
	prestigeTable = {}
	
	rewards = {
		Help = getObjectFromGUID("ef72b4"),
		GiveJokers = getObjectFromGUID("4dbf75"),
		StealJokers = getObjectFromGUID("395ece"),
		CopyJokers = getObjectFromGUID("aad1be"),
		
		FiveCardWin = getObjectFromGUID("890842"),
		FiveCardTwentyOne = getObjectFromGUID("37085e"),
		SixCardWin = getObjectFromGUID("68a101"),
		SixCardTwentyOne = getObjectFromGUID("fe17c6"),
		
		Blackjack = getObjectFromGUID("7c99c4"),
		DoubleJoker = getObjectFromGUID("887ef8"),
		TripleSeven = getObjectFromGUID("fa1dc7"),
		Unused = getObjectFromGUID("9b7f31"),
	}
	
	--The names (in quotes) should all match the names on your cards.
	--The values should match the value of those cards.
	--If you have powerup modifies (ex: +1 to score), it could be added here (again, figurine required)
	--0 is reserved for Aces.
	cardNameTable = {
		["Two"]=2, ["Three"]=3, ["Four"]=4, ["Five"]=5,
		["Six"]=6, ["Seven"]=7, ["Eight"]=8, ["Nine"]=9, ["Ten"]=10,
		["Jack"]=10, ["Queen"]=10, ["King"]=10, ["Ace"]="Ace", ["Joker"]="Joker",
		
		["+1 to anyone's hand"]=1, ["+1 to any player's hand"]=1, ["-1 from anyone's hand"]=-1,
		["+3 to anyone's hand"]=3, ["+3 to any player's hand"]=3, ["-3 from anyone's hand"]=-3,
		["+10 to your own hand"]=10, ["Discard your hand and stand on 19"]=19,
		["Force the dealer to bust"]=-69
	}

	--This is what ties a scripting zone to a player/dealer
	--color is the player's color, z is the player's scripting zone
	--Dealer comes first!
	objectSets = {
		{color="Dealer", zone=getObjectFromGUID("275a5d"), value=0, count=0, container=getObjectFromGUID("df8d40"), prestige=getObjectFromGUID("885bf4"), btnHandler=getObjectFromGUID("355712"), tbl=getObjectFromGUID("758fe9")},
		{color="Pink", zone=getObjectFromGUID("44f05e"), value=0, count=0, container=getObjectFromGUID("7c4eb9"), prestige=getObjectFromGUID("0b4a58"), btnHandler=getObjectFromGUID("4503f9"), tbl=getObjectFromGUID("bb54b1")},
		{color="Purple", zone=getObjectFromGUID("63ef4e"), value=0, count=0, container=getObjectFromGUID("54d217"), prestige=getObjectFromGUID("17ddfd"), btnHandler=getObjectFromGUID("2a52f9"), tbl=getObjectFromGUID("b2ab0b")},
		{color="Blue", zone=getObjectFromGUID("423ae1"), value=0, count=0, container=getObjectFromGUID("f2e64b"), prestige=getObjectFromGUID("f87e7b"), btnHandler=getObjectFromGUID("5d5e85"), tbl=getObjectFromGUID("7a414f")},
		{color="Teal", zone=getObjectFromGUID("5c2692"), value=0, count=0, container=getObjectFromGUID("54cc65"), prestige=getObjectFromGUID("3484cc"), btnHandler=getObjectFromGUID("925380"), tbl=getObjectFromGUID("d21b66")},
		{color="Green", zone=getObjectFromGUID("595fa9"), value=0, count=0, container=getObjectFromGUID("579f2e"), prestige=getObjectFromGUID("a7bb1b"), btnHandler=getObjectFromGUID("031d13"), tbl=getObjectFromGUID("2612ed")},
		{color="Yellow", zone=getObjectFromGUID("5b82fd"), value=0, count=0, container=getObjectFromGUID("486212"), prestige=getObjectFromGUID("944b87"), btnHandler=getObjectFromGUID("ab82ca"), tbl=getObjectFromGUID("a7596f")},
		{color="Orange", zone=getObjectFromGUID("38b2d7"), value=0, count=0, container=getObjectFromGUID("b179e0"), prestige=getObjectFromGUID("844d3d"), btnHandler=getObjectFromGUID("ef0906"), tbl=getObjectFromGUID("efae07")},
		{color="Red", zone=getObjectFromGUID("8b37f7"), value=0, count=0, container=getObjectFromGUID("82aca4"), prestige=getObjectFromGUID("d8cd49"), btnHandler=getObjectFromGUID("9fd676"), tbl=getObjectFromGUID("b54e19")},
		{color="Brown", zone=getObjectFromGUID("1c13af"), value=0, count=0, container=getObjectFromGUID("cee112"), prestige=getObjectFromGUID("6c29ce"), btnHandler=getObjectFromGUID("5b2fc0"), tbl=getObjectFromGUID("688678")},
		{color="White", zone=getObjectFromGUID("a751f4"), value=0, count=0, container=getObjectFromGUID("8144bb"), prestige=getObjectFromGUID("88482c"), btnHandler=getObjectFromGUID("0a3126"), tbl=getObjectFromGUID("33b903")},
		
		-- Split zones - Code cycles through this table backwards, so zone 1 is last
		{color="Split6", zone=getObjectFromGUID("43d808"), value=0, count=0, container=getObjectFromGUID("b5effd"), prestige=getObjectFromGUID("43d808"), btnHandler=getObjectFromGUID("1f100d"), tbl=getObjectFromGUID("43d808")},
		{color="Split5", zone=getObjectFromGUID("39f2dd"), value=0, count=0, container=getObjectFromGUID("0232e3"), prestige=getObjectFromGUID("39f2dd"), btnHandler=getObjectFromGUID("9a5313"), tbl=getObjectFromGUID("39f2dd")},
		{color="Split4", zone=getObjectFromGUID("df3fa1"), value=0, count=0, container=getObjectFromGUID("1c1194"), prestige=getObjectFromGUID("df3fa1"), btnHandler=getObjectFromGUID("0f078a"), tbl=getObjectFromGUID("df3fa1")},
		{color="Split3", zone=getObjectFromGUID("391dea"), value=0, count=0, container=getObjectFromGUID("5f8f1e"), prestige=getObjectFromGUID("391dea"), btnHandler=getObjectFromGUID("a356c5"), tbl=getObjectFromGUID("391dea")},
		{color="Split2", zone=getObjectFromGUID("e527cb"), value=0, count=0, container=getObjectFromGUID("3e331e"), prestige=getObjectFromGUID("e527cb"), btnHandler=getObjectFromGUID("c84a39"), tbl=getObjectFromGUID("e527cb")},
		{color="Split1", zone=getObjectFromGUID("f673d7"), value=0, count=0, container=getObjectFromGUID("b2bf24"), prestige=getObjectFromGUID("f673d7"), btnHandler=getObjectFromGUID("35ea56"), tbl=getObjectFromGUID("f673d7")},
	}

	--Object on which buttons are placed for things like "deal cards"
	cardHandler = getObjectFromGUID("77a0c3")
	bonusTimer = getObjectFromGUID("3cce5b")
	
	betBags = getObjectFromGUID("697122")
	
	deckBag = getObjectFromGUID("eaa77b")
	minigameBag = getObjectFromGUID("5b38f8")
	bonusBag = getObjectFromGUID("91fe78")
	
	bonusObjects = {}
	
	--A zone where the deck is placed. Also used in tagging the deck for identification
	deckZone = getObjectFromGUID("885bf4")
	bonusZone = getObjectFromGUID("3c31e1")

	--A list of objects that we want to disable interaction for
	objectLockdown = {
		getObjectFromGUID("16f87e"), getObjectFromGUID("8e0429"), -- Dealer area
		
		-- Player tables
		getObjectFromGUID("9871fe"), getObjectFromGUID("8eafbb"), -- Pink
		getObjectFromGUID("d5d7c5"), getObjectFromGUID("32da09"), -- Purple
		getObjectFromGUID("b92ec5"), getObjectFromGUID("51086b"), getObjectFromGUID("981767"), -- Blue
		getObjectFromGUID("51aacb"), getObjectFromGUID("60b260"), getObjectFromGUID("5a0955"), -- Teal
		getObjectFromGUID("b01343"), getObjectFromGUID("704082"), getObjectFromGUID("653add"), -- Green
		getObjectFromGUID("2cc362"), getObjectFromGUID("51690f"), getObjectFromGUID("63c8aa"), -- Yellow
		getObjectFromGUID("fddcfc"), getObjectFromGUID("8ea777"), getObjectFromGUID("54895c"), -- Orange
		getObjectFromGUID("f12fe3"), getObjectFromGUID("9f466e"), getObjectFromGUID("a3c6db"), -- Red
		getObjectFromGUID("ac9b82"), getObjectFromGUID("b2883b"), -- Brown
		getObjectFromGUID("a82b72"), getObjectFromGUID("4211a7"), -- White
		
		getObjectFromGUID("9ac0b7"),
		
		-- Button handlers
		getObjectFromGUID("4503f9"), -- Pink
		getObjectFromGUID("2a52f9"), -- Purple
		getObjectFromGUID("5d5e85"), -- Blue
		getObjectFromGUID("925380"), -- Teal
		getObjectFromGUID("031d13"), -- Green
		getObjectFromGUID("ab82ca"), -- Yellow
		getObjectFromGUID("ef0906"), -- Orange
		getObjectFromGUID("9fd676"), -- Red
		getObjectFromGUID("5b2fc0"), -- Brown
		getObjectFromGUID("0a3126"), -- White
		
		-- Rupee trophies
		getObjectFromGUID("1feed0"), -- Green
		getObjectFromGUID("533f81"), -- Blue
		getObjectFromGUID("b8bf89"), -- Yellow
		getObjectFromGUID("038e19"), -- Red
		getObjectFromGUID("02eb77"), -- Purple
		getObjectFromGUID("5e2f09"), -- Orange
		getObjectFromGUID("df5ce7"), -- Silver
		getObjectFromGUID("dc1fe2"), -- Rupoor
		getObjectFromGUID("0b6e51"), -- Gold
	}
	
	-- Chips list
	chipConverter = getObjectFromGUID("ad770c")
	chipList = chipConverter and chipConverter.getTable("chipList") or {}
	chipListIndex = {}
	for i=1,#chipList do
		chipListIndex[chipList[i].name or ""] = i
	end
	
	-- Round timer
	roundStateTable = {"1fe5da","bf6cbd","fd2298","aefae6"} -- Bets, Play, Powerups, Paused
	for _,id in ipairs(roundStateTable) do
		roundState = getObjectFromGUID(id)
		if roundState then break end
	end
	if roundState and roundState.getGUID()~=roundStateTable[1] then roundState = roundState.setState(1) end
	
	roundTimer = getObjectFromGUID("8f93ac")
	if roundTimer then
		roundTimer.setValue( 180 )
		roundTimer.Clock.paused = false
		
		roundStateID = 1
	end
	
	-- Other vars
	dealersTurn = false
	dealingDealersCards = false
	lockout = false
	timerTick = 0

	lockObjects()
	createButtons()
	checkForDeck()
	findCardsToCount()
	clearBonus()
end

function lockObjects()
	for i, list in ipairs(objectLockdown) do
		list.interactable = false
	end
end

function GetSetting( var, default )
	if type(var)=="table" then -- Set up var (request from other object)
		default = var.default
		if default==nil then default = var[2] end
		
		var = var.index or var.id or var.setting or var[1]
	end
	if not (var and type(var)=="string") then return default end -- No var, return default
	
	if (not BlackjackSettingsObject) or (BlackjackSettingsObject==nil) then
		for _,obj in pairs(getAllObjects()) do
			if obj.getLock() and obj.getName()=="Blackjack Settings" and obj.getVar("getSetting") and not (obj==nil) then
				BlackjackSettingsObject = obj
				break
			end
		end
		
		if (not BlackjackSettingsObject) or (BlackjackSettingsObject==nil) then
			return default -- No settings object, return default
		end
	end
	
	local value = BlackjackSettingsObject.Call("getSetting", {index=var})
	if value==nil then return default end -- Unset, return default
	
	return value -- Return value
end

objectHasLeftContainer = {}
objectForceDropped = {}
function onObjectLeaveContainer(bag, obj)
	if obj.getPosition()[3] < -16 then
		objectHasLeftContainer[obj] = bag
		Wait.frames(function()
			objectHasLeftContainer[obj] = nil
		end, 2)
	end
end
function onObjectPickedUp(color, object)
	if color ~= "Black" and not (Player[color].admin) then
		if object.getPosition()[3] < -16 then
			object.translate({0,0.15,0})
			print(color .. ' picked up a ' .. object.tag .. ' titled "' .. object.getName() .. '" from the hidden zone!')
			
			if objectHasLeftContainer[object] then
				if objectHasLeftContainer[object].tag=="Infinite" then
					destroyObject(object)
				else
					objectHasLeftContainer[object].putObject(object)
				end
			else
				objectForceDropped[object] = true
				Wait.frames(function()
					objectForceDropped[object] = nil
				end, 2)
			end
		end
		for i, set in ipairs(objectSets) do
			local objectsInZone = set.zone.getObjects()
			for i, found in ipairs(objectsInZone) do
				if found.tag == "Deck" or found.tag == "Card" then
					if found == object then
						object.translate({0,0.15,0})
					end
				end
			end
		end
	end
end

function giveRewardCallback(obj, data)
	if not (obj and data and data.set) then return end
	
	if obj.tag=="Bag" then
		obj.reset()
		
		obj.setName("Player save: " .. Player[data.set.color].steam_name)
		obj.setDescription(Player[data.set.color].steam_id)
	end
	
	local p = {data.pos.x, data.pos.y+0.5, data.pos.z}
	obj.setPosition( p )
end
function giveReward( id, zone )
	if not rewards[id] then return end
	
	local set = findObjectSetFromZone(zone)
	if set.UserColor then
		set = findObjectSetFromColor(set.UserColor) or set
		zone = set.zone
	end
	if not Player[set.color].seated then return end
	
	local params = {}
	-- params.position = zone.getPosition()
	params.position = zone.positionToWorld({0.5,0,-0.5})
	params.callback = "giveRewardCallback"
	params.callback_owner = Global
	params.params = {set=set}
	
	for _,item in pairs( rewards[id].getObjects()) do
		params.position.y = params.position.y+0.1
		params.params.pos = params.position
		
		local obj
		if item.tag=="Infinite" then
			obj = item.takeObject(params)
		elseif obj.tag=="Bag" then
			obj = item.clone(params)
			obj.reset()
			
			obj.setName("Player save: " .. Player[set.color].steam_name)
			obj.setDescription(Player[set.color].steam_id)
		else
			obj = item.clone(params)
			
			obj.setDescription( ("%s - %s\n\n%s"):format(Player[set.color].steam_id, Player[set.color].steam_name or "No Name", obj.getDescription()) )
		end
		
		if obj then
			obj.interactable = true
			obj.setLock( false )
		end
	end
end





--POWERUP DETECTION SECTION





--When an object is dropped by a player, we check if its name is on a powerup list
function onObjectDropped(colorOfDropper, droppedObject)
	-- Dealer zone protections
	if objectForceDropped[droppedObject] then
		return
	elseif droppedObject.getPosition()[3] < -16 and colorOfDropper~="Black" and not Player[colorOfDropper].admin then
		local trash = getObjectFromGUID("df8d40")
		if trash and not (trash==nil) then
			trash.putObject(droppedObject)
			if colorOfDropper then
				printToColor( "You dropped an item in the dealer zone; it has ben placed in Trash.", colorOfDropper, {0.75,0.45,0.35} )
			end
		end
		
		return
	end
	
	-- Powerup use
	local power = powerupEffectTable[droppedObject.getName()]
	if power and bonusCanUsePowerup(droppedObject) then
		return checkPowerupDropZone(colorOfDropper, droppedObject, power.who, power.effect)
	end
	
	-- Chip protections
	if droppedObject.tag=="Chip" and droppedObject.getDescription():find(Player[colorOfDropper].steam_id, 0, true) then
		local inOwnZone = false
		for i=2,#objectSets do
			for _,v in pairs({"zone","tbl","prestige"}) do
				for _,obj in pairs(objectSets[i][v].getObjects()) do
					if obj==droppedObject then
						local setCol = objectSets[i].color
						if setCol==colorOfDropper then  -- If there's an overlap, we prioritise our own zone
							inOwnZone = true
							obj.setDescription( Player[colorOfDropper].steam_id .." - ".. Player[colorOfDropper].steam_name )
							break
						end
						
						if setCol:sub(1,5):lower()~="split" and Player[setCol] and Player[setCol].seated then
							if GetSetting("Chips.AllowTrading", false) then
								obj.setDescription( Player[setCol].steam_id .." - ".. Player[setCol].steam_name )
							elseif not Player[colorOfDropper].admin then
								local ownSet = findObjectSetFromColor(colorOfDropper)
								if ownSet then
									obj.setPosition(ownSet.tbl.getPosition())
								end
								broadcastToColor("You may not trade chips. Chips have been returned to your table.", colorOfDropper, {1,0,0})
								
								return
							end
						end
					end
				end
				if inOwnZone then break end
			end
		end
	end
	
	
end

local preventEnterContainer = {}
function onObjectPickUp(col, obj)
	if col~="Black" and obj.getPosition()[3] >= -16 then
		local desc = obj.getDescription()
		if desc=="" and obj.tag=="Chip" then --obj.getDescription():find("^%$([%d,])+ ?%s*$")
			obj.setDescription( ("%s - %s"):format(Player[col].steam_id, Player[col].steam_name) )
		elseif desc:find(Player[col].steam_id, 0, true) then
			local id, oldDesc = desc:match("^(%d+) %- [^\n]*\n\n(.*)")
			if oldDesc then
				obj.setDescription( ("%s - %s\n\n%s"):format(Player[col].steam_id, Player[col].steam_name, oldDesc) )
			else
				obj.setDescription( ("%s - %s"):format(Player[col].steam_id, Player[col].steam_name) )
			end
		elseif (not Player[col].admin) and desc:find("^(%d+) %- .*") then
			local guid = obj.getGUID()
			preventEnterContainer[obj.getGUID()] = obj.reload()
			Wait.frames(function()
				preventEnterContainer[obj.getGUID()] = nil
			end, 1)
			
			for k,adminCol in pairs(getSeatedPlayers()) do
				if Player[adminCol].admin then
					broadcastToColor( tostring(Player[col].steam_name).." attempted to lift another player's \""..tostring(obj.getName()).."\".", adminCol, {1,0,0} )
				end
			end
		end
	end
end
function onObjectEnterContainer(bag, obj)
	if preventEnterContainer[obj.getGUID()] and preventEnterContainer[obj.getGUID()]==obj then
		destroyObject(obj)
	end
end

--Triggered by above function, this determines if the powerup was dropped in a card zone (objectSets z fields)
function checkPowerupDropZone(colorOfDropper, droppedObject, who, effect)
	for i, set in ipairs(objectSets) do
		local objectsInZone = set.zone.getObjects()
		for j, zoneObject in ipairs(objectsInZone) do
			if zoneObject == droppedObject then
				checkPowerupEffect(colorOfDropper, droppedObject, who, effect, set)
				break
			end
		end
	end
end

--Checks the logic of who should be able to utilize a powerup and its effect
--This function is what enforces the "who" field, so powerups only trigger in the correct zones
function checkPowerupEffect(colorOfDropper, droppedObject, who, effect, setTarget)
	local setUser = findObjectSetFromColor(colorOfDropper)
	if not setUser then return end
	
	if inMinigame then
		if minigame and (not (minigame==nil)) and minigame.getVar("blackjackCanUsePowerup") and minigame.Call("blackjackCanUsePowerup", {setUser=setUser, setTarget=setTarget, object=droppedObject, who=who, effect=effect}) then
		else
			printToColor( "You can't use this powerup during this minigame. Try again later.", colorOfDropper, {1,0.25,0.25} )
			return
		end
	end
	
	if (setTarget == objectSets[1]) and dealingDealersCards then
		broadcastToColor("You can't use a powerup on the dealer while their cards are being dealt.", setUser.color, {1,0.5,0.5})
		
		return
	end
	
	if who == "Anyone" then
		activatePowerupEffect(effect, setTarget, droppedObject, setUser)
	elseif who == "Any Player" and setTarget ~= objectSets[1] then
		activatePowerupEffect(effect, setTarget, droppedObject, setUser)
	elseif who == "Other Player" and colorOfDropper ~= setTarget.color and setTarget ~= objectSets[1] and setTarget.UserColor~=colorOfDropper then
		activatePowerupEffect(effect, setTarget, droppedObject, setUser)
	elseif who == "Self Only" and (colorOfDropper == setTarget.color or setTarget.UserColor==colorOfDropper) then
		activatePowerupEffect(effect, setTarget, droppedObject, setUser)
	elseif who == "Dealer Only" and setTarget == objectSets[1] then
		activatePowerupEffect(effect, setTarget, droppedObject, setUser)
	elseif who == setTarget.color or (setTarget.UserColor and who == setTarget.UserColor) then
		activatePowerupEffect(effect, setTarget, droppedObject, setUser)
	else -- No valid target
		activatePowerupFailedCallback( {obj=droppedObject, user=setUser, target=setTarget} )
	end
end

function unlockPrestigeDestructionBag(data)
	if data and data.bag and not (data.bag and data.bag==nil) then
		data.bag.unlock()
		
		if data and data.container and not (data.container and data.container==nil) then
			data.container.putObject( data.bag )
		elseif data and data.setContainer and not (data.setContainer and data.setContainer==nil) then
			data.setContainer.putObject( data.bag )
		end
	end
end

function doPrestigeDestruction(set)
	local destroyChips = GetSetting("Prestige.ClearChips", true)
	local destroyPowerups = GetSetting("Prestige.ClearPowerups", true)
	
	return doChipDestruction( set, destroyChips, destroyPowerups, true )
end
function doBankruptDestruction(set)
	local destroyChips = GetSetting("Bankruptcy.ClearChips", true)
	local destroyPowerups = GetSetting("Bankruptcy.ClearPowerups", true)
	local destroyPrestige = GetSetting("Bankruptcy.ClearPrestige", false)
	
	return doChipDestruction( set, destroyChips, destroyPowerups, destroyPrestige )
end
function doChipDestruction( set, destroyChips, destroyPowerups, destroyPrestige )
	if not (destroyChips or destroyPowerups or destroyPrestige) then return end
	
	local zoneObjects = set.zone.getObjects()
	local tableObjects = set.tbl.getObjects()
	local prestigeObjects = set.prestige.getObjects()
	
	local ownedContainers = {}
	for _,zone in pairs({zoneObjects, tableObjects, prestigeObjects}) do
		for _, obj in ipairs(zone) do
			local name = obj.getVar("__trader_ObjectName") or obj.getName()
			if obj.getVar("onBlackjackDestroyItems") then
				obj.Call("onBlackjackDestroyItems", {destroyChips=destroyChips, destroyPowerups=destroyPowerups, destroyPrestige=destroyPrestige} )
			elseif destroyChips and obj.tag == "Chip" then
				if destroyPowerups or (not powerupEffectTable[obj.getName()]) then
					destroyObject(obj)
				end
			elseif destroyPowerups and powerupEffectTable[obj.getName()] then
				destroyObject(obj)
			elseif destroyPrestige and (obj.getVar("PrestigeLevel") or ((string.match(name, "New player") or string.match(name, "Prestige %d+")) and not string.find(name, "Trophy"))) then
				destroyObject(obj)
			elseif obj.tag=="Bag" then
				ownedContainers[obj] = true
			end
		end
	end
	
	local plyID = Player[set.color].seated and Player[set.color].steam_id
	for _,obj in pairs(getAllObjects()) do
		if obj.tag=="Bag" then
			beginRecursiveBagCleanup( obj, plyID, destroyChips, destroyPowerups, destroyPrestige, ownedContainers[obj] )
		else
			if obj.getVar("onBlackjackDestroyItems") then
				if obj.getDescription():match("^(%d+) %- .*")==plyID then
					obj.Call("onBlackjackDestroyItems", {destroyChips=destroyChips, destroyPowerups=destroyPowerups, destroyPrestige=destroyPrestige} )
				end
			elseif destroyChips and obj.tag=="Chip" then
				if destroyPowerups or (not powerupEffectTable[obj.getName()]) then
					if obj.getDescription():match("^(%d+) %- .*")==plyID then
						destroyObject(obj)
					end
				end
			elseif destroyPowerups and powerupEffectTable[obj.getName()] then
				if obj.getDescription():match("^(%d+) %- .*")==plyID then
					destroyObject(obj)
				end
			elseif destroyPrestige then
				local name = obj.getVar("__trader_ObjectName") or obj.getName()
				if (obj.getVar("PrestigeLevel") or ((string.match(name, "New player") or string.match(name, "Prestige %d+")) and not string.find(name, "Trophy"))) then
					if obj.getDescription():match("^(%d+) %- .*")==plyID then
						destroyObject(obj)
					end
				end
			end
		end
	end
end

function beginRecursiveBagCleanup( bag, id, destroyChips, destroyPowerups, destroyPrestige, skipIDChecks )
	if bag.getName()=="Save storage" and bag.getLock() then -- Save storage bag
		if bag.getVar("doPrestige") then
			bag.Call("doPrestige", {id=id, destroyChips=destroyChips, destroyPowerups=destroyPowerups, destroyPrestige=destroyPrestige})
		end
		
		return bag
	end
	if bag.getQuantity()<=0 then return bag end -- Empty, skip
	
	-- Yes, this is horrible
	-- It's the only way to get the proper data, and with json we can cleanly remove items
	-- Definitely causes lag, though
	local bagData = JSON.decode(bag.getJSON() or "")
	if not bagData then return bag end
	
	local shouldRespawn = doRecursiveBagCleanup( bagData, id, destroyChips, destroyPowerups, destroyPrestige, skipIDChecks ) -- Do cleanup
	if shouldRespawn then
		local newBag = spawnObjectJSON( {json=JSON.encode(bagData), sound=false} ) -- Respawn with removed data
		
		for i=1,#objectSets do -- Fix objects table
			if objectSets[i].container==bag then
				objectSets[i].container = newBag
			end
		end
		
		bag.destruct() -- Remove old container
		
		return newBag
	end
	
	return bag
end
function doRecursiveBagCleanup( tbl, id, destroyChips, destroyPowerups, destroyPrestige, skipIDChecks )
	if not (tbl and tbl.ContainedObjects) then return false end
	
	local shouldRespawn = false
	for i=#tbl.ContainedObjects,1,-1 do
		local item = tbl.ContainedObjects[i]
		
		-- local objID = item.Description:match("^(%d+) %- .*")
		if item.Name=="Custom_Model_Bag" or item.Name=="Bag" then -- Bag or other container
			shouldRespawn = doRecursiveBagCleanup( item, id, destroyChips, destroyPowerups, destroyPrestige, skipIDChecks ) or shouldRespawn
		elseif powerupEffectTable[item.Nickname] then -- Powerup
			if destroyPowerups and (skipIDChecks or item.Description:match("^(%d+) %- .*")==id) then
				table.remove( tbl.ContainedObjects, i )
				shouldRespawn = true
			end
		elseif item.Name=="Custom_Model" or item.Name=="Custom_Model_Stack" then
			if item.CustomMesh.TypeIndex==5 then -- Custom chip
				if destroyChips and (skipIDChecks or item.Description:match("^(%d+) %- .*")==id) then
					table.remove( tbl.ContainedObjects, i )
					shouldRespawn = true
				end
			elseif destroyPrestige then
				if ((string.match(item.Nickname, "New player") or string.match(item.Nickname, "Prestige %d+")) and not string.find(item.Nickname, "Trophy")) or -- Prestige (name)
				  item.LuaScript:match("[^%d%a]PrestigeLevel%s*=%s*%d+") or item.LuaScript:match("%\[nt]PrestigeLevel%s*=%s*(%d+%.?%d*)") then -- Prestige (script)
					
					if skipIDChecks or item.Description:match("^(%d+) %- .*")==id then
						table.remove( tbl.ContainedObjects, i )
						shouldRespawn = true
					end
				end
			end
		end
	end
	
	if #tbl.ContainedObjects==0 then
		tbl.ContainedObjects = nil
	end
	
	return shouldRespawn
end

-- Activates a given effect. setTarget is the objectSets entry for where it was dropped. setUser is the set of the dropper
powerupEffectFunctions = { -- So much cleaner and more efficient than the huge elseif chain
	Clear = function( setTarget, powerup, setUser )
		if roundStateID~=2 and roundStateID~=3 then return end
		
		local cardsInZone = findCardsInZone(setTarget.zone)
		local decksInZone = findDecksInZone(setTarget.zone)
		local dlr = objectSets[1].value
		if (#cardsInZone>0 or #decksInZone>0) and (setTarget.value<=21 and setTarget.value<dlr and (dlr<=21 or dlr==69)) then
			if setTarget.color~=setUser.color and setTarget.UserColor~=setUser.color then
				giveReward( "Help", setUser.zone )
			end
			
			destroyObject(powerup)
			clearCards(setTarget.zone)
			
			-- Unlock Chips
			local zoneObjectList = setTarget.zone.getObjects()
			for j, bet in ipairs(zoneObjectList) do
				if (bet.tag == "Chip" and not powerupEffectTable[bet.getName()]) or (bet.tag == "Bag" and bet.getName():sub(1,11)~="Player save") then
					bet.interactable = true
					bet.setLock(false)
				end
			end
			
			if currentPlayerTurn==setTarget.color then
				clearPlayerActions(setTarget.zone)
				passPlayerActions(setTarget.zone)
			end
			
			return true
		else
			broadcastToColor("Must use powerup on a zone with cards in it, also the targeted player must be losing and not busted.", setUser.color, {1,0.5,0.5})
		end
	end,
	["Alt. Clear"] = function( setTarget, powerup, setUser )
		if roundStateID~=2 and roundStateID~=3 then return end
		
		local cardsInZone = findCardsInZone(setTarget.zone)
		local decksInZone = findDecksInZone(setTarget.zone)
		if (#cardsInZone>0 or #decksInZone>0) and (setTarget.value <= 21 or (setTarget.value>=68 and setTarget.value<=72)) then
			if setTarget.color~=setUser.color and setTarget.UserColor~=setUser.color then
				local dealerValue = objectSets[1].value
				local targetValue = setTarget.value
				local v = cardNameTable[powerup.getName()] or 0
				if v=="Ace" then v = 11 end
				
				if v~="Joker" and (setTarget.value>dealerValue and v<=dealerValue) or (setTarget.value==dealerValue and v<dealerValue) then
					if setUser.value<targetValue and not GetSetting("Powerups.AllowHostile", true) then
						broadcastToColor("This powerup cannot be used to make another player lose.", setUser.color, {1,0.5,0.5})
						
						return false
					end
				elseif (dealerValue<=21 or dealerValue<=68) and (v=="Joker" or (v>=dealerValue and (v<=21 or (v>=68 and v<=72)))) then
					if (targetValue<dealerValue) or (targetValue==dealerValue and v>dealerValue) then
						giveReward( "Help", setUser.zone )
					end
				end
			end
			
			clearCards(setTarget.zone)
			if currentPlayerTurn==setTarget.color then playerStand(setTarget.btnHandler,"Black") end
			
			return true
		else
			broadcastToColor("Must use powerup on a zone with cards in it, cannot be played on a busted player.", setUser.color, {1,0.5,0.5})
		end
	end,
	Redraw = function( setTarget, powerup, setUser )
		if roundStateID~=2 and roundStateID~=3 then return end
		
		local cardsInZone = findCardsInZone(setTarget.zone)
		local decksInZone = findDecksInZone(setTarget.zone)
		if (#cardsInZone>0 or #decksInZone>0) and (setTarget.value<=21 or (setTarget.value>=68 and setTarget.value<=72)) then
			destroyObject(powerup)
			clearCards(setTarget.zone)
			if setTarget == objectSets[1] then
				dealDealer({1,2})
			else
				dealPlayer(setTarget.color, {1,2})
			end
			
			if setTarget.color=="Dealer" and dealersTurn then
				startLuaCoroutine( Global, "DoDealersCards" )
			end
			
			return true
		else
			broadcastToColor("Must use powerup on a zone with cards in it, cannot be played on a busted player.", setUser.color, {1,0.5,0.5})
		end
	end,
	["Redraw All"] = function( setTarget, powerup, setUser )
		if roundStateID~=2 and roundStateID~=3 then return end
		
		local cardsInZone = findCardsInZone(setUser.zone)
		local decksInZone = findDecksInZone(setTarget.zone)
		if (#cardsInZone>0 or #decksInZone>0) then
			for hand, set in ipairs(objectSets) do
				local cardsInZone = findCardsInZone(set.zone)
				local decksInZone = findDecksInZone(set.zone)
				if (#cardsInZone>0 or #decksInZone>0) then
					destroyObject(powerup)
					clearCards(set.zone)
					if set == objectSets[1] then
						dealDealer({1,2})
					else
						dealPlayer(set.color, {1,2})
					end
				end
			end
			
			if dealersTurn then
				startLuaCoroutine( Global, "DoDealersCards" )
			end
			
			return true
		else
			broadcastToColor("Must use powerup on a zone with cards in it.", setUser.color, {1,0.5,0.5})
		end
	end,
	Swap = function( setTarget, powerup, setUser )
		if roundStateID~=2 and roundStateID~=3 then return end
		
		local tableZ1 = findCardsInZone(setTarget.zone)
		local tableZ2 = findCardsInZone(setUser.zone)
		
		local decksZ1 = findDecksInZone(setTarget.zone) for i=1,#decksZ1 do table.insert(tableZ1, decksZ1[i]) end
		local decksZ2 = findDecksInZone(setUser.zone) for i=1,#decksZ2 do table.insert(tableZ2, decksZ2[i]) end
		if #tableZ1 ~= 0 and #tableZ2 ~= 0 and (setUser.value<=21 or (setUser.value==68) or (setUser.value==69 and setUser.count==2) or (setUser.value==71 and setUser.count==2) or (setUser.value==70 and setUser.count==3)) then
			if setTarget.color~="Dealer" and setTarget.color~=setUser.color and setTarget.UserColor~=setUser.color then
				if (setTarget.value==71 and setTarget.count==2) or (setTarget.value==70 and setTarget.count==3) then -- Triple seven/Double joker stolen
					giveReward( "StealJokers", setUser.zone )
				elseif (setUser.value==71 and setUser.count==2) or (setUser.value==70 and setUser.count==3) then -- Triple seven/Double joker given away
					giveReward( "GiveJokers", setUser.zone )
				elseif setUser.value>setTarget.value then
					local dealerValue = objectSets[1].value
					if dealerValue>0 and dealerValue<=21 and (setUser.value>dealerValue and setTarget.value<=dealerValue) or (setUser.value==dealerValue and setTarget.value<dealerValue) then
						giveReward( "Help", setUser.zone )
					end
				elseif setUser.value<setTarget.value and not GetSetting("Powerups.AllowHostile", true) then
					broadcastToColor("This powerup cannot be used to make another player lose.", setUser.color, {1,0.5,0.5})
					
					return false
				end
			end
			
			swapHandZones(setTarget.zone, setUser.zone, tableZ1, tableZ2)
			destroyObject(powerup)
			
			if setTarget.color=="Dealer" and dealersTurn then
				startLuaCoroutine( Global, "DoDealersCards" )
			end
			
			return true
		else
			broadcastToColor("Must use powerup on a zone with cards in it while you also have cards, cannot be played while busted.", setUser.color, {1,0.5,0.5})
		end
	end,
	Clone = function( setTarget, powerup, setUser )
		if roundStateID~=2 and roundStateID~=3 then return end
		
		local tableZ1 = findCardsInZone(setTarget.zone)
		local tableZ2 = findCardsInZone(setUser.zone)
		
		local decksZ1 = findDecksInZone(setTarget.zone) for i=1,#decksZ1 do table.insert(tableZ1, decksZ1[i]) end
		local decksZ2 = findDecksInZone(setUser.zone) for i=1,#decksZ2 do table.insert(tableZ2, decksZ2[i]) end
		if #tableZ1 ~= 0 and #tableZ2 ~= 0 and (setUser.value <= 21 or (setUser.value>=68 and setUser.value<=72)) then
			if setTarget.color~="Dealer" then
				if (setTarget.value==71 and setTarget.count==2) or (setTarget.value==70 and setTarget.count==3) then -- Triple seven/Double joker cloned
					giveReward( "CopyJokers", setUser.zone )
				end
			end
			
			clearCardsOnly(setUser.zone)
			cloneHandZone(setTarget.zone, setUser.zone)
			destroyObject(powerup)
			return true
		else
			broadcastToColor("Must use powerup on a zone with cards in it while you also have cards, cannot be played while busted.", setUser.color, {1,0.5,0.5})
		end
	end,
	Destroy = function( setTarget, powerup, setUser )
		local cards = findCardsInZone(setTarget.zone)
		
		table.sort( cards, function(a,b)
			local aStarter = a.getTable("blackjack_playerSet")
			local bStarter = b.getTable("blackjack_playerSet")
			
			if aStarter and not bStarter then
				return true
			elseif bStarter and not aStarter then
				return false
			end
			
			local aPos = a.getPosition()
			local bPos = b.getPosition()
			
			if math.abs(aPos.z-bPos.z)<0.25 then -- Allow for a small variance in position, if we're too strict cards might re-order
				if math.abs(aPos.x-bPos.x)<0.25 then
					return aPos.y<bPos.y
				end
				return aPos.x>bPos.x
			end
			
			return aPos.z<bPos.z
		end)
		
		if cards[#cards] and not (cards[#cards]==nil) then
			cards[#cards].destruct()
			destroyObject(powerup)
			
			if dealersTurn and setTarget.color=="Dealer" then
				startLuaCoroutine( Global, "DoDealersCards" )
			end
			
			return true
		end
	end,
	Reveal = function( setTarget, powerup, setUser )
		if roundStateID~=2 and roundStateID~=3 then return end
		
		local cardsInZone = findCardsInZone(setTarget.zone)
		if #cardsInZone == 2 then
			if setTarget.color=="Dealer" and GetSetting("Powerups.RevealIsHelp", true) then
				giveReward( "Help", setUser.zone )
			end
			
			revealHandZone(setTarget.zone)
			destroyObject(powerup)
			return true
		end
	end,
	Stand = function( setTarget, powerup, setUser )
		if roundStateID~=2 and roundStateID~=3 then return end
		
		local cardsInZone = findCardsInZone(setTarget.zone)
		if #cardsInZone < 2 then
			broadcastToColor("This powerup can only be used on a hand with more than two cards.", setUser.color, {1,0.5,0.5})
			return
		end
		
		local newValue = 0
		for i, card in ipairs(findCardsInZone(setTarget.zone) or {}) do
			x = card.getPosition().x
			if x < 3 then
				card.destruct()
			else
				local cardValue = tonumber((card.getName()=="Ace" and 1) or cardNameTable[card.getName()]) or 0
				
				newValue = newValue + cardValue
			end
		end
		
		if setTarget.color=="Dealer" and (setTarget.value<=21 or (setTarget.value>=68 and setTarget.value<=72)) then
			for i=2,#objectSets do
				local s = objectSets[i]
				if s~=setUser and s.UserColor~=setUser.color and (s.value>0 or s.count>0) and s.value<=21 and ((s.value<setTarget.value and s.value>=newValue) or (s.value==setTarget.value and s.value>newValue)) then -- Helped someone
					giveReward( "Help", setUser.zone )
					
					if not GetSetting("Powerups.MultiHelp", true) then break end
				end
			end
		end
		
		destroyObject(powerup)
		return true
	end,
	["Draw 1"] = function( setTarget, powerup, setUser )
		if roundStateID~=2 and roundStateID~=3 then return end
		
		local cardsInZone = findCardsInZone(setTarget.zone)
		local decksInZone = findCardsInZone(setTarget.zone)
		if #cardsInZone>0 or #decksInZone>0 then
			local nextCard = (mainDeck.getObjects()[1] or {}).nickname or ""
			local nextCardValue = tonumber((nextCard=="Ace" and 1) or cardNameTable[nextCard]) or 0
			
			if setTarget.color=="Dealer" then
				if (setTarget.value<=21 and setTarget.value+nextCardValue>21) or (setTarget.value>=68 and setTarget.value<=72) then
					for i=2,#objectSets do
						local s = objectSets[i]
						if s~=setUser and s.UserColor~=setUser.color and (s.value>0 or s.count>0) and s.value<=21 and s.value<=setTarget.value then -- Helped someone
							giveReward( "Help", setUser.zone )
							
							if not GetSetting("Powerups.MultiHelp", true) then break end
						end
					end
				end
				
				forcedCardDraw(setTarget.zone)
				
				while lastCard.getName() == "Joker" do
					lastCard.destruct()
					forcedCardDraw(setTarget.zone, "Black")
					resetTimer(3)
				end
			else
				local dealerValue = objectSets[1].value
				if dealerValue<=21 and dealerValue<setTarget.value and (setTarget.value<=21 or setTarget.value>=67 and setTarget.value<=72) then
					if not GetSetting("Powerups.AllowHostile", true) then
						broadcastToColor("This powerup cannot be used on a winning player.", setUser.color, {1,0.5,0.5})
						
						return false
					end
				end
				
				local newValue = setTarget.value+nextCardValue
				
				if nextCard=="Joker" or (newValue<=21 and ((setTarget.value<dealerValue and newValue>=dealerValue) or (setTarget.value==dealerValue and newValue>dealerValue))) then
					giveReward( "Help", setUser.zone )
				end
				
				forcedCardDraw(setTarget.zone)
			end
			
			destroyObject(powerup)
			return true
		end
	end,
	["Powerup Draw"] = function( setTarget, powerup, setUser )
		if spawnRandomPowerup(setUser.zone) then
			destroyObject(powerup)
		else
			print( "WARNING: Failed to draw powerup for "..setUser.color.."! Are there powerups available on this table?" )
			broadcastToColor("Error: Failed to draw powerup. Are there powerups available on this table?", setUser.color, {1,0.25,0.25})
		end
	end,
	["Rupee Pull"] = function( setTarget, powerup, setUser )
		local betsInZone = findBetsInZone(setTarget.zone)
		local cardsInZone = findCardsInZone(setTarget.zone)
		local decksInZone = findCardsInZone(setTarget.zone)
		if #betsInZone ~= 0 and #cardsInZone == 0 and #decksInZone == 0 then
			if rupeePull(setTarget.zone) then
				destroyObject(powerup)
			end
		else
			broadcastToColor("To use: between rounds, place a bet and then drop into your own zone.", setUser.color, {1,0.5,0.5})
		end
	end,
	["Reward Token"] = function( setTarget, powerup, setUser )
		if powerup.getQuantity() == 2 then
			takeObjectFromContainer(setUser.zone, "737b2a")
			destroyObject(powerup)
		elseif powerup.getQuantity() == 5 then
			takeObjectFromContainer(setUser.zone, "ea79f0")
			destroyObject(powerup)
		else
			broadcastToColor("To use: group together the exact amount based on chosen reward and then drop into your own zone.", setUser.color, {1,0.5,0.5})
		end
	end,
	["Royal Token"] = function( setTarget, powerup, setUser )
		if powerup.getQuantity() == -1 then
			takeObjectFromContainer(setUser.zone, "737b2a")
			destroyObject(powerup)
		elseif powerup.getQuantity() == 2 then
			takeObjectFromContainer(setUser.zone, "ea79f0")
			destroyObject(powerup)
		else
			broadcastToColor("To use: group together the exact amount based on chosen reward and then drop into your own zone.", setUser.color, {1,0.5,0.5})
		end
	end,
	["Prestige Token"] = function( setTarget, powerup, setUser )
		local prestigeObj
		local set = findObjectSetFromZone(setUser.zone)
		local zoneObjects = set.prestige.getObjects()
		
		local level = 0
		for i, object in ipairs(zoneObjects) do
			local findLevel = object.getVar("PrestigeLevel")
			if findLevel then
				if findLevel>=level then
					level = findLevel
					prestigeObj = object
				end
			else
				local findMatch = string.match(object.getVar("__trader_ObjectName") or object.getName(), "Prestige (%d+)")
				if findMatch and tonumber(findMatch)>=level and not string.find(object.getName(), "Trophy") then
					level = tonumber(findMatch) or 0
					prestigeObj = object
				elseif level<=0 and string.find(object.getName(), "New player") and not string.find(object.getName(), "Trophy") then
					level = 0
					prestigeObj = object
				end
			end
		end
		
		if prestigeObj and level then
			if doPrestige(set, level+1) then
				destroyObject(powerup)
			else
				broadcastToColor("Error: Prestige failed.", setUser.color, {1,0.5,0.5})
			end
		else
			broadcastToColor("To use: place your current prestige rupee above your hand then drop into your own zone.", setUser.color, {1,0.5,0.5})
		end
	end,
	["Reset Timer"] = function( setTarget, powerup, setUser )
		resetTimer(3)
		destroyObject(powerup)
		
		return true
	end,
	["Card Mod"] = function( setTarget, powerup, setUser )
		if roundStateID~=2 and roundStateID~=3 then return end
		
		if (#findCardsInZone(setTarget.zone)>0 or #findDecksInZone(setTarget.zone)>0 or #findFigurinesInZone(setTarget.zone)>1) then
			local powerupValue = (powerup.getVar("getCardValue") and powerup.Call("getCardValue")) or cardNameTable[powerup.getName()]
			if powerupValue=="Ace" then powerupValue = (setTarget.value<=10 and 11 or 1) end
			powerupValue = tonumber(powerupValue) or 0
			
			updateHandCounter( setTarget )
			
			if setTarget.color=="Dealer" then
				if setTarget.count==4 and setTarget.value<=21 and setTarget.value>0 then -- This makes 5 card bust
					for i=2,#objectSets do
						local s = objectSets[i]
						if (s~=setUser and s.SplitUser~=setUser) and (s.value>0 or s.count>0) and s.value<=setTarget.value then
							giveReward( "Help", setUser.zone )
							if not GetSetting("Powerups.MultiHelp", true) then break end
						end
					end
				elseif setTarget.count<4 and setTarget.value<=21 and setTarget.value>0 then -- Not bust before this powerup
					local newValue = setTarget.value+powerupValue
					
					if newValue>21 or newValue<=0 then -- Bust after this powerup
						for i=2,#objectSets do
							local s = objectSets[i]
							if (s~=setUser and s.SplitUser~=setUser) and (s.value>0 or s.count>0) and s.value<=setTarget.value then
								giveReward( "Help", setUser.zone )
								if not GetSetting("Powerups.MultiHelp", true) then break end
							end
						end
					else
						for i=2,#objectSets do
							local s = objectSets[i]
							if (s~=setUser and s.SplitUser~=setUser) and (s.value>0 or s.count>0) and s.value<=21 and ((s.value<setTarget.value and s.value>=newValue) or (s.value==setTarget.value and s.value>newValue)) then -- Helped someone
								giveReward( "Help", setUser.zone )
								if not GetSetting("Powerups.MultiHelp", true) then break end
							end
						end
					end
				elseif setTarget.value==69 then -- Dealer blackjack
					local newValue = 11+powerupValue
					
					for i=2,#objectSets do
						local s = objectSets[i]
						if (s~=setUser and s.SplitUser~=setUser) and (s.value>0 or s.count>0) and s.value<=21 and s.value>=newValue then -- Helped someone
							giveReward( "Help", setUser.zone )
							if not GetSetting("Powerups.MultiHelp", true) then break end
						end
					end
				end
			else
				local dealer = objectSets[1]
				local newValue = setTarget.value + powerupValue
				if newValue>21 and setTarget.value<=21 and string.find(powerup.getDescription(), "[Cc]an%'?n?o?t be used to bust ?a?n?o?t?h?e?r? player") then
					broadcastToColor("This powerup cannot be used to bust another player.", setUser.color, {1,0.5,0.5})
					return false
				end
				if setTarget.color~=setUser.color and setTarget.UserColor~=setUser.color then
					if not GetSetting("Powerups.AllowHostile", true) then
						if setTarget.value>=dealer.value and setTarget.value<=21 and newValue<dealer.value then
							broadcastToColor("This powerup cannot be used to make another player lose.", setUser.color, {1,0.5,0.5})
							
							return false
						elseif newValue>21 and setTarget.value<=21 and setTarget.value>=dealer.value and dealer.value<=21 and dealer.value>0 then
							broadcastToColor("This powerup cannot be used to make another player lose.", setUser.color, {1,0.5,0.5})
							
							return false
						end
					end
					
					if newValue<=21 and (dealer.value>21 or newValue>=dealer.value or dealer.count>=5) then
						if (setTarget.value<dealer.value and newValue>=dealer.value and dealer.count<5) or -- Was less than dealer (dealer not bust) OR
						  (setTarget.value==dealer.value and newValue>dealer.value and dealer.count<5) or (setTarget.value>21) then -- Was equal to dealer, now over (dealer not bust) OR Was bust
							giveReward( "Help", setUser.zone )
						end
					elseif setTarget.value>21 and newValue>21 and setTarget.count==4 then -- From bust to 5-card push
						giveReward( "Help", setUser.zone )
					end
				end
			end
			
			if setTarget.color=="Dealer" and dealersTurn then
				startLuaCoroutine( Global, "DoDealersCards" )
			end
			
			return true
		else
			broadcastToColor("Must use powerup on a zone with cards in it.", setUser.color, {1,0.5,0.5})
		end
	end,
}
function activatePowerupFailedCallback(data)
	if not (data.obj and data.obj==nil) then -- No specific null check I know of, but this check seems to work
		if data.obj.getName():lower()=="royal token" or data.obj.getName():lower()=="reward token" then return end
		
		if GetSetting("Powerups.FifthCard", true) then
			if data.target.count~=4 then return end
			if (data.target.value<=21 and data.target.value>=objectSets[1].value) or (data.target.value>=68 and data.target.value<=72) then return end -- No effect
			if data.user.color~=data.target.color and data.user.color~=data.target.UserColor then
				giveReward( "Help", data.user.zone )
			end
			
			local target = data.target.color
			if data.target.color == data.user.color then target = "themself" elseif data.target.color == "Dealer" then target = "the dealer" end
			
			if data.target.UserColor then
				if data.target.UserColor == data.user.color then
					target = target.." (themself)"
				elseif data.target.color == "Dealer" then
					target = target.." (the dealer)"
				else
					target = target.." ("..data.target.UserColor..")"
				end
			end
			
			printToAll("Powerup event: " ..data.user.color.. " used " ..data.obj.getName().. " as a fifth card for " ..target.. ".", {0.5,0.5,1})
			
			data.obj.setPosition( findPowerupPlacement(data.target.zone, #findFigurinesInZone(data.target.zone)+1) )
			data.obj.setRotation( {0,0,0} )
			data.obj.setName("Fifth Card")
			data.obj.setDescription("This powerup has been used as a fifth card to give this hand bust immunity.")
			data.obj.lock()
			cardNameTable["Fifth Card"] = nil
			
			data.target.count = data.target.count + 1 -- Immediately add one to count (prevents double fifth-card)
			data.obj.setColorTint( stringColorToRGB(data.user.color) or {1,1,1} )
			
			if roundStateID==3 and roundTimer and roundTimer.getValue()<10 then
				roundTimer.setValue( 10 )
				roundTimer.Clock.paused = false
			end
		end
	end
end
function activatePowerupEffect(effect, setTarget, powerup, setUser)
	findCardsToCount() -- Make sure our hand value is up to date
	Wait.frames(function() findCardsToCount() end, 2) -- Recount after delay, so we're up to date afterwards too
	
	if powerupEffectFunctions[effect] then
		if not powerupEffectFunctions[effect](setTarget, powerup, setUser) then
			Wait.frames(function()
				activatePowerupFailedCallback( {obj=powerup, user=setUser, target=setTarget} )
			end, 1)
			
			return
		end
	elseif powerup.getVar("powerupUsed") then
		if not powerup.call("powerupUsed", {setTarget=setTarget, powerup=powerup, setUser=setUser}) then
			Wait.frames(function()
				activatePowerupFailedCallback( {obj=powerup, user=setUser, target=setTarget} )
			end, 1)
			return
		end
	else
			Wait.frames(function()
				activatePowerupFailedCallback( {obj=powerup, user=setUser, target=setTarget} )
			end, 1)
		return
	end
	
	local target = setTarget.color
	if setTarget.color == setUser.color then target = "themself" elseif setTarget.color == "Dealer" then target = "the dealer" end
	
	if setTarget.UserColor then
		if setTarget.UserColor == setUser.color then
			target = target.." (themself)"
		elseif setTarget.color == "Dealer" then
			target = target.." (the dealer)"
		else
			target = target.." ("..setTarget.UserColor..")"
		end
	end
	
	printToAll("Powerup event: " ..setUser.color.. " used " ..powerup.getName().. " on " ..target.. ".", {0.5,0.5,1})
	
	powerup.setPosition( findPowerupPlacement(setTarget.zone, #findFigurinesInZone(setTarget.zone)+1) )
	powerup.setRotation( {0,0,0} )
	powerup.lock()
	
	powerup.setColorTint( stringColorToRGB(setUser.color) or {1,1,1} )
	
	if roundStateID==3 and roundTimer and roundTimer.getValue()<10 then
		preventRoundEnd = os.time() + 1
		roundTimer.setValue( 10 )
		roundTimer.Clock.paused = false
	end
end

function AddPowerup(data) -- If TTS devs ever get over their weird phobia of using functions as variables (How Lua was DESIGNED) this function will be more useful. For now, on the object use `Global.call("AddPowerup", dataTable)` and have a global `powerupUsed` function.
	if not (data.obj and data.who) then return end
	
	local name = data.obj.getName()
	if (not name) or name=="" or powerupEffectTable[name] then return end 
	
	local effectName = data.effectName or name -- Failsafe
	
	powerupEffectTable[name] = {who=data.who, effect=data.effectName}
	powerupEffectFunctions[effectName] = powerupEffectFunctions[effectName] or data.func -- If we already have a function here, use that instead
	table.insert(powerupTable, {data.obj.getGUID(), name})
end





--POWERUP EFFECTS SECTION





--Triggerd by powerup, this switches the cards in 2 zones (zone1 and zone2)
function swapHandZones(zone1, zone2, tableZ1, tableZ2)
	for i, card in ipairs(tableZ1) do
		local pos = findCardPlacement(zone2, i)
		card.setPosition(pos)
		
		Wait.frames(function()
			if (not card) or card==nil then return end
			cardPlacedCallback(card, {targetPos=pos, set=findObjectSetFromZone(zone2), isStarter=card.getTable("blackjack_playerSet"), flip=true})
		end, 1)
	end
	for i, card in ipairs(tableZ2) do
		local pos = findCardPlacement(zone1, i)
		card.setPosition(pos)
		
		Wait.frames(function()
			if (not card) or card==nil then return end
			cardPlacedCallback(card, {targetPos=pos, set=findObjectSetFromZone(zone1), isStarter=card.getTable("blackjack_playerSet"), flip=true})
		end, 1)
	end
end

--Clones (copies and pastes) cards from targetZone to the zone of colorUser
function cloneHandZone(targetZone, userZone)
	local targetCardList = findCardsInZone(targetZone)
	local targetDeckList = findDecksInZone(targetZone) for i=1,#targetDeckList do table.insert(targetCardList, targetDeckList[i]) end
	if #targetCardList ~= 0 then
		for i, card in ipairs(targetCardList) do
			local pos = findCardPlacement(userZone, i)
			local clone = card.clone({position=pos}) -- Why is there no callback for this function?
			clone.setPosition(pos)
			
			cardPlacedCallback(clone, {targetPos=pos, set=findObjectSetFromZone(userZone), isStarter=card.getTable("blackjack_playerSet"), flip=true})
		end
	else
		printToAll("ERROR: You cannot copy and empty hand. Copy Canceled.", {1,0.1,0.1})
	end
end

--Reveals any face-down cards
function DoDealersCards()
	if dealingDealersCards or (not dealersTurn) then return 1 end
	dealingDealersCards = true -- Make sure this coroutine doesn't start while it's already running
	
	local set = objectSets[1]
	
	waitTime(0.5)
	local targetCardList = findCardsInZone(set.zone)
	if #targetCardList ~= 0 then
		for i, card in ipairs(targetCardList) do
			if not dealingDealersCards then return end
			
			local z = card.getRotation().z
			if z > 15 and z < 345 then
				local pos = card.getPosition()
				card.setRotation({0,0,0})
				card.setPosition(pos)
				
				waitTime(0.5)
			end
		end
	end
	
	-- findCardsToCount()
	updateHandCounter( set[1] )
	waitTime(0.05)
	
	local standValue = GetSetting("Hands.DealerStandValue", 17)
	
	while (set.value<standValue and set.value<=21 and set.value>0 and set.count<5) do
		if not dealingDealersCards then return end
		updateHandCounter( set[1] )
		
		if set.value>=0 then
			hitCard(set.btnHandler, "Black")
			
			while lastCard.getName() == "Joker" do
				lastCard.destruct()
				hitCard(set.btnHandler, "Black")
				resetTimer(3)
			end
		end
		
		waitTime(0.5)
		-- findCardsToCount()
		updateHandCounter( set[1] )
		updateAllDisplays()
		waitTime(0.05)
	end
	if not dealingDealersCards then return end
	
	if set.count>=5 then
		printToAll("Dealer: 5-card bust.", {0.1,0.1,0.1})
	elseif set.value>=67 or set.value<0 then -- Out of standard range - Special values
		printToAll("Dealer: Stand.", {0.1,0.1,0.1})
	elseif set.value>21 then
		printToAll("Dealer: Bust.", {0.1,0.1,0.1})
	else
		printToAll("Dealer: Stand on ".. tostring(set.value) ..".", {0.1,0.1,0.1})
	end
	updateAllDisplays()
	
	dealingDealersCards = false
	
	setRoundState( 3, GetSetting("Rounds.PowerupsTime", 20) )
	
	return 1
end
function revealHandZone(targetZone)
	local targetCardList = findCardsInZone(targetZone)
	if #targetCardList ~= 0 then
		for i, card in ipairs(targetCardList) do
			local z = card.getRotation().z
			if z > 15 and z < 345 then
				-- card.flip()
				
				card.setRotation({0,0,0})
				
				local pos = card.getPosition()
				pos.y = pos.y + 0.2
				card.setPosition(pos)
			end
		end
		
		if targetZone==objectSets[1].zone then -- Dealer
			startLuaCoroutine( Global, "DoDealersCards" )
		end
		
		updateHandCounter( findObjectSetFromZone(targetZone) )
	else
		printToAll("ERROR: No cards to reveal. Powerup devoured anyway.", {1,0.1,0.1})
	end
end

--Draws a card, forced by powerup
function forcedCardDraw(targetZone)
	local targetCardList = findCardsInZone(targetZone)
	local cardToDraw = #targetCardList + 1
	local pos = findCardPlacement(targetZone, cardToDraw)
	placeCard(pos, true, findObjectSetFromZone(targetZone), false)
end

local spawnPowerupPosModifier = {}
function spawnRandomPowerup(targetZone)
	if #powerupTable==0 then return false end
	
	local chosenIndex = math.random(1, #powerupTable)
	local chosenPowerup = powerupTable[chosenIndex]
	local chosenObject = getObjectFromGUID(chosenPowerup[1])
	if not chosenObject then
		table.remove(powerupTable, chosenIndex)
		
		local found = false
		for _,obj in pairs(getAllObjects()) do
			if obj.getLock() and obj.getName()==chosenPowerup[2] then
				found = true
				
				table.insert(powerupTable, {obj.getGUID(), chosenPowerup[2]})
				
				break
			end
		end
		
		return spawnRandomPowerup(targetZone)
	end
	
	
	local params = {}
	params.position = targetZone.positionToWorld({0.5,0 + (spawnPowerupPosModifier[targetZone] or 0),-0.5})
	local clone = chosenObject.clone(params)
	clone.unlock()
	
	spawnPowerupPosModifier[targetZone] = (spawnPowerupPosModifier[targetZone] or 0) + 0.04
	Wait.frames(function()
		spawnPowerupPosModifier[targetZone] = nil
	end, 2)
	
	local plyCol = (findObjectSetFromZone(targetZone) or {}).color
	if plyCol=="Dealer" or plyCol:sub(1,5)=="Split" then plyCol = nil end
	if plyCol and Player[plyCol].seated then
		clone.setDescription( ("%s - %s\n\n%s"):format( Player[plyCol].steam_id, Player[plyCol].steam_name, clone.getDescription() ) )
	end
	
	return true
end

function takeRandomObjectFromContainer(targetZone, takeFrom)
	local params = {}
	-- params.position = targetZone.getPosition()
	params.position = targetZone.positionToWorld({0.5,0 + (spawnPowerupPosModifier[targetZone] or 0),-0.5})
	container = getObjectFromGUID(takeFrom).takeObject(params)
	container.shuffle()
	takenObject = container.takeObject(params)
	container.destruct()
	
	
	spawnPowerupPosModifier[targetZone] = (spawnPowerupPosModifier[targetZone] or 0) + 0.04
	Wait.frames(function()
		spawnPowerupPosModifier[targetZone] = nil
	end, 2)
end

function takeObjectFromContainer(targetZone, takeFrom, posOverride)
	local params = {}
	-- params.position = targetZone.getPosition()
	params.position = targetZone.positionToWorld(posOverride or {0.5,0 + (spawnPowerupPosModifier[targetZone] or 0),-0.5})
	takenObject = getObjectFromGUID(takeFrom).takeObject(params)
	
	
	spawnPowerupPosModifier[targetZone] = (spawnPowerupPosModifier[targetZone] or 0) + 0.04
	Wait.frames(function()
		spawnPowerupPosModifier[targetZone] = nil
	end, 2)
	
	return takenObject
end

local function withinChipLimit( zone, limit )
	local zoneObjects = zone.getObjects()
	
	local toFind = limit
	for j, bet in ipairs(zoneObjects) do
		if (bet.tag == "Chip" and not powerupEffectTable[bet.getName()]) then
			local num = bet.getQuantity()
			if num==-1 then num=1 end
			
			if num<=toFind then
				toFind = toFind - num
			elseif num==toFind then
				toFind = 0
			elseif num>toFind then
				return false
			end
		elseif (bet.tag == "Bag" and bet.getName():sub(1,11)~="Player save") then
			return false
		end
	end
	
	return true
end
function rupeePull(targetZone)
	local set = findObjectSetFromZone(targetZone)
	
	local rupeeLimit = GetSetting("Rupee.MaxChips", 0)
	if rupeeLimit>0 and not withinChipLimit(targetZone, rupeeLimit) then
		broadcastToColor("Error: Could not pull rupee. Chip limit is "..tostring(rupeeLimit).." and bet bags cannot be used.", set.color, {1,0.25,0.25})
		
		return false
	end
	
	takeRandomObjectFromContainer(set.zone, "2e08d6")
	local name = takenObject.getName()
	local description = takenObject.getDescription()
	destroyObject(takenObject)
	if string.find(name, "prestige") then
		takeObjectFromContainer(set.zone, "a65636")
	elseif string.find(name, "bust") then
		clearBets(set.zone)
	end
	takeObjectFromContainer(set.zone, string.sub(description, 1, 6))
	printToAll("Rupee event: " .. set.color .. " pulled a " .. name .. ".", {0.5,1,0.5})
	processPayout(set.zone, tonumber(string.sub(description, 8)) or 0)
	
	return true
end

function resetTimer(time)
	bonusTimer.setValue(time)
	bonusTimer.Clock.pauseStart()
end





--CARD ZONE COUNTING SECTION





local displayCol = {
	["Safe"] =  {r=1,   g=1,   b=0.75},
	["Win"] =   {r=0.75,g=1,   b=0.75},
	["Lose"] =  {r=1,   g=0.75,b=0.75},
	
	["Bust"] =  {r=0.75, g=0.5,b=0.5},
	
	["Clear"] = {r=1,   g=1,   b=1},
}
--Looks for any cards in the scripting zones and sends them on to obtainCardValue
--Looks for any decks in the scripting zones and sends them on to obtainDeckValue
--Triggers next step, addValues(), after that
local nextAutoCardCount = 0
function findCardsToCount()
	nextAutoCardCount = os.time() + 5 -- Push back auto count
	
	if minigame and not (minigame==nil) and minigame.getVar("blackjackCountCards") and minigame.Call("blackjackCountCards") then -- Minigame override
		-- Should something happen here?
	else
		for hand, set in ipairs(objectSets) do
			updateHandCounter( set )
		end
	end
	timerStart()
end
function updateHandCounter( set )
	if type(set)=="string" then
		set = findObjectSetFromColor(set)
	end
	if not set then return end
	
	local cardList = findCardsInZone(set.zone)
	local deckList = findDecksInZone(set.zone)
	local figurineList = findFigurinesInZone(set.zone)
	if #cardList ~= 0 or #deckList ~= 0 or #figurineList ~= 0 then
		obtainCardNames(set, cardList, deckList, figurineList)
		return
	end
	
	set.value = 0
	set.count = 0
	
	local override = false
	if minigame and not (minigame==nil) and minigame.getVar("blackjackDisplayResult") then -- Override
		local str, col = minigame.Call("blackjackDisplayResult", {set=set, value=value, soft=soft})
		if str then
			set.btnHandler.editButton({
				index=0, label=str, color = (col and {r=col.r,g=col.g,b=col.b} or displayCol.Clear) -- Can't use the colour directly, causes errors
			})
			
			override = true
		end
	end
	
	if not override then
		set.btnHandler.editButton({index=0, label="0", color=displayCol.Clear})
	end
end

--Gets a list of names from the card if they are face up
function obtainCardNames(set, cardList, deckList, figurineList)
	local validCards = {}
	local facedownCount = 0
	local facedownCard = nil
	for i, card in ipairs(cardList) do
		local z = card.getRotation().z
		if z > 270 or z < 90 then
			if set.color=="Dealer" and card.getName()=="Joker" then
				resetTimer(3)
				card.destruct()
			end
			table.insert(validCards, card.getName())
		elseif set.color=="Dealer" then
			facedownCount = facedownCount + 1
			facedownCard = card
		end
	end
	for i, deck in ipairs(deckList) do
		local z = deck.getRotation().z
		if z > 270 or z < 90 then
			for j, card in ipairs(deck.getObjects()) do
				table.insert(cardNames, card.nickname)
			end
		end
	end
	for i, figurine in ipairs(figurineList) do
		table.insert(validCards, figurine)
	end
	set.count = #validCards
	addCardValues(set, validCards, facedownCount, facedownCard)
end

--Adds card values from their names
function addCardValues(set, cardList, facedownCount, facedownCard)
	local value = 0
	local aceCount = 0
	local sevenCount = 0
	local tenCount = 0
	local jokerCount = 0
	local dealerBust = 0
	local stopCount = false
	for i, card in ipairs(cardList) do
		local v = type(card)~="string" and (card.getVar("getCardValue") and card.Call("getCardValue") or cardNameTable[card.getName()]) or cardNameTable[card]
		if v then
			if v == "Ace" then
				aceCount = aceCount + 1
			elseif v == 7 then
				sevenCount = sevenCount + 1
			elseif v == 10 then
				tenCount = tenCount + 1
			elseif v == 69 then
				aceCount = aceCount + 1
				tenCount = tenCount + 1
				v = 10
			elseif (v=="Joker" or v==68) then
				jokerCount = jokerCount + 1
			elseif (v==71) then
				jokerCount = jokerCount + 2
			elseif (v==70) then
				if set.count==1 then
					sevenCount = sevenCount + 3
				end
				v = 21
			elseif v == -69 then
				dealerBust = dealerBust + 1
			end
			
			if set.color=="Dealer" then
				if set.count > 4 or dealerBust > 0 then
					stopCount = true
					value = -69
				end
			else
				if jokerCount > 0 then
					if jokerCount == 2 and set.count <= 2 then
						value = 71
					else
						value = 68
					end
					stopCount = true
				elseif sevenCount == 3 and set.count <= 3 then
					value = 70
					stopCount = true
				end
			end
			if not stopCount then
				value = value + (tonumber(v) or 0)
			end
		end
	end
	
	local soft = false
	if aceCount > 0 and not stopCount then
		for i=1, aceCount do
			if i==aceCount and value <= 10 then
				if aceCount == 1 and tenCount==1 and set.count<=2 then
					value = 69
					stopCount = true
				elseif set.color=="Dealer" and facedownCount<1 and GetSetting("Hands.DealerAceIsOne", true) then
					value = value + 1
				else
					value = value + 11
					soft = true
				end
			else
				value = value + 1
			end
		end
	end
	if value>50 and not (stopCount or  set.count==1) then value=100 end
	
	displayResult(set, value, soft)
	--Checks for blackjack
	if set.color=="Dealer" then
		if #cardList == 1 and facedownCount == 1 then
			checkForBlackjack(value, facedownCard)
		end
	end
end

--Sends the card count results to the displays
--If you wanted special symbols to show up on 21, 21+ etc, you would add it here
local SoftHandDisplay = {
	[1] = "①", [2] = "②", [3] = "③", [4] = "④", [5] = "⑤", [6] = "⑥", [7] = "⑦", [8] = "⑧", [9] = "⑨", [10] = "⑩",
	[11] = "⑪", [12] = "⑫", [13] = "⑬", [14] = "⑭", [15] = "⑮", [16] = "⑯", [17] = "⑰", [18] = "⑱", [19] = "⑲", [20] = "⑳",
	[21] = "㉑",
}
local specialHandDisplay = {
	[-69] = "\u{2620}", [100] = "\u{2620}", -- Bust
	[68] = "\u{2661}", -- Joker
	[69] = "\u{2664}", -- Blackjack
	[70] = "\u{277C}", -- Triple Seven
	[71] = "\u{2665}", -- Double Joker
}
function displayResult(set, value, soft)
	set.value = value
	set.soft = soft
	
	updateHandDisplay( set )
end

function updateAllDisplays()
	for i=1,#objectSets do
		updateHandDisplay( objectSets[i] )
	end
end
function updateHandDisplay( set )
	if minigame and not (minigame==nil) and minigame.getVar("blackjackDisplayResult") then -- Override
		local str, col = minigame.Call("blackjackDisplayResult", {set=set, value=set.value, soft=set.soft})
		if str then
			set.btnHandler.editButton({
				index=0, label=str, color = (col and {r=col.r,g=col.g,b=col.b} or displayCol.Clear)
			})
			return
		end
	end
	
	if specialHandDisplay[set.value] then
		valueLabel = specialHandDisplay[set.value]
	else
		valueLabel = set.value
	end
	if set.soft then valueLabel=SoftHandDisplay[valueLabel] or valueLabel end
	
	set.btnHandler.editButton({
		index=0, label=valueLabel,
		color = getHandDisplayColor(set),
	})
end

function getHandDisplayColor(set)
	local val = set.value
	if set.color=="Dealer" or val==0 then return displayCol.Clear end -- Dealer or not in play
	
	if val==68 or val==71 then return displayCol.Win end -- Joker always wins
	if val>21 and (val<68 or val>72) then -- Bust
		return (set.count>=5 and displayCol.Safe) or displayCol.Bust
	end
	
	local dealerValue = objectSets[1].value
	if dealerValue==69 then -- Dealer blackjack
		return ((val==69 or set.count>=5) and displayCol.Safe) or displayCol.Lose
	end
	
	if dealerValue<=21 then -- Dealer not bust
		if dealerValue==val then -- Push
			return displayCol.Safe
		elseif dealerValue>val then -- Lose
			return (set.count>=5 and displayCol.Safe) or displayCol.Lose
		end
	end
	
	return displayCol.Win
end

--Guess what THIS does.
function checkForBlackjack(value, facedownCard)
	local facedownValue = nil
	for name, v in pairs(cardNameTable) do
		if name == facedownCard.getName() then
			facedownValue = v
		end
	end
	if (facedownValue=="Ace" and value==10) or (facedownValue==10 and value==11) then
		facedownCard.setRotation({0,0,0})
		
		local pos = facedownCard.getPosition()
		pos.y = pos.y + 0.2
		facedownCard.setPosition(pos)
		
		broadcastToAll("Dealer has Blackjack!", {0.9,0.2,0.2})
		
		Wait.frames(function()
			updateHandCounter( objectSets[1] )
			updateAllDisplays()
		end, 2)
	end
end

--Restarts loop back up at countCards
function timerStart()
	Timer.destroy('blackjack_timer')
	Timer.create({identifier='blackjack_timer', function_name='timerStart', delay=0.5})
	if bonusTimer.getValue() < 1 then
		resetTimer(1200)
		bonusRound()
	end
	
	if os.time()>=nextAutoCardCount then -- Recount cards. This updates displays if a card was manually locked in place.
		findCardsToCount()
	end
	
	if roundTimer and roundStateID then
		if roundTimer.getValue()<=0 and ((not preventRoundEnd) or os.time()>preventRoundEnd) then
			preventRoundEnd = nil
			if roundStateID==1 then
				dealButtonPressed( nil, "Lua" )
			elseif roundStateID==3 then
				payButtonPressed( nil, "Lua" )
			elseif roundStateID==2 and (not (inMinigame or dealersTurn)) and GetSetting("Rounds.TurnTimeLimit", 0)>0 and not turnActive then
				turnActive = true -- Failsafe
				if currentPlayerTurn then
					local set = findObjectSetFromColor(currentPlayerTurn)
					
					if set then
						clearPlayerActions(set.zone)
						passPlayerActions(set.zone)
					end
				end
			end
		end
		
		if roundTimer.Clock.paused and (roundStateID==1 or roundStateID==3) then
			setRoundStateObject( 4 ) -- Paused state
		else
			local objID = getRoundStateID()
			if objID~=(-1) and objID~=roundStateID then
				setRoundStateObject(roundStateID)
			end
		end
		
		if roundStateID==2 and inMinigame and ((not minigame) or minigame==nil) then
			printToAll("Minigame controller dissapeared! Resuming normal play...", {1,0,0})
			setRoundState( 1, GetSetting("Rounds.BetTime", 30) )
			
			for i, set in pairs(objectSets) do
				-- Unlock Chips
				local zoneObjects = set.zone.getObjects()
				local tableObjects = set.tbl.getObjects()
				local prestigeObjects = set.prestige.getObjects()
				
				for _,zone in pairs({zoneObjects, tableObjects, prestigeObjects}) do
					for j, bet in ipairs(zone) do
						if (bet.tag == "Chip" and not powerupEffectTable[bet.getName()]) or (bet.tag == "Bag" and bet.getName():sub(1,11)~="Player save") and not bet.interactable then
							bet.interactable = true
							bet.setLock(false)
						end
					end
				end
			end
		end
	end
end
function getRoundStateID()
	if roundState then return roundState.getStateId() end
	
	for _,id in ipairs(roundStateTable) do
		roundState = getObjectFromGUID(id)
		if roundState then return roundState.getStateId() end
	end
	
	return -1
end
function setRoundStateObject( stateID )
	for _,id in ipairs(roundStateTable) do
		roundState = getObjectFromGUID(id)
		if roundState then break end
	end
	if roundState and roundState.getStateId()~=(-1) and roundState.getStateId()~=stateID then roundState = roundState.setState(stateID) end
end
function setRoundState( stateID, roundTime )
	if not roundTimer then return end
	roundStateID = stateID
	
	setRoundStateObject( stateID )
	
	roundTimer.setValue( roundTime or 0 )
	roundTimer.Clock.paused = (roundTimer.getValue()==0)
	
	if stateID==1 then inMinigame = false end
end

function onObjectDestroy( obj )
	if obj==roundTimer then
		roundTimer = nil
	elseif obj==roundState then
		roundState = nil
	end
end





-- BONUS




function addBonus( pos )
	if not pos then
		pos = bonusZone.getPosition()
		pos.y = pos.y - 1.7
	end
	
	local params = {}
	params.position = pos
	
	local autoBonuses = bonusBag.takeObject(params)
	autoBonuses.shuffle()
	
	params.callback_function = activateBonus
	
	local chosenBonus
	repeat
		chosenBonus = autoBonuses.takeObject( params )
		chosenBonus.setColorTint({r=0.25,g=0.25,b=0.25})
		
		for i=1,#bonusObjects do
			if bonusObjects[i].getName()==chosenBonus.getName() then
				destroyObject( chosenBonus )
				chosenBonus = nil
				break
			end
		end
	until (chosenBonus~=nil) or (#autoBonuses.getObjects()==0)
	
	if chosenBonus then
		table.insert( bonusObjects, chosenBonus )
	end
	
	autoBonuses.destruct()
end
function bonusRound()
	local playerList = getSeatedPlayers()
	for i, player in ipairs(playerList) do
		local set = findObjectSetFromColor(player)
		if set then
			spawnRandomPowerup(set.zone)
		end
	end
	if not isBonusActive() then
		clearBonus()
		addBonus()
	end
end

function activateBonus( obj )
	local inTable = false
	for i=1,#bonusObjects do
		if bonusObjects[i]==obj then
			inTable = true
			break
		end
	end
	if not inTable then
		table.insert( bonusObjects, obj )
	end
	
	obj.lock()
	
	if obj.getVar("onDeploy") then
		obj.call("onDeploy")
	else
		obj.setColorTint({r=1,g=1,b=1})
	end
end

function clearBonus()
	if #bonusObjects == 0 then
		local objectList = bonusZone.getObjects()
		for i, object in ipairs(objectList) do
			if object.tag == "Figurine" and object.getLock() then
				object.destruct()
			end
		end
	else
		for i=#bonusObjects,1,-1 do
			bonusObjects[i].destruct()
			bonusObjects[i] = nil
		end
	end
end

local function RunBonusFunc( funcName, data, returnFunc )
	local ret = {}
	
	for i=#bonusObjects,1,-1 do
		local obj = bonusObjects[i]
		if obj and obj~=nil then
			if obj.getVar(funcName) then
				local newValue = obj.call(funcName, data)
				
				if newValue~=nil then
					table.insert( ret, newValue )
				end
				
				if obj==nil then -- Does this check work on the same frame as removal?
					table.remove(bonusObjects, i)
				end
			end
		else
			table.remove(bonusObjects, i)
		end
	end
	
	if returnFunc then
		return returnFunc(ret) -- Let the call decide which it value wants
	else
		return ret[#ret] -- Last entry in table is from the oldest bonus
	end
end

-- Active
function isBonusActive()
	return RunBonusFunc( "isActive")
end

-- Bool Checks
function bonusShouldDealerReveal()
	return RunBonusFunc( "shouldDealerReveal" )==true
end
function bonusCanUsePowerup( powerup )
	return RunBonusFunc( "canUsePowerup", {powerup=powerup} )~=false
end
function bonusCanFlip( )
	return RunBonusFunc( "canFlip" )==true
end
function bonusShouldBust( set )
	return RunBonusFunc( "shouldBust", {set=set} )~=false
end

-- Numbers
function bonusGetPayoutMultiplier( set, mult )
	return RunBonusFunc( "payoutMultiplier", {set=set, betMultiplier=mult}, function(data)
		-- This function ensures we always return the largest multiplier
		-- Useful when there's multiple bonuses
		local value
		
		for i=1,#data do
			if (not value) or data[i]>value then
				value = data[i]
			end
		end
		
		return value
	end)
end

-- Bonus Round Hooks
function bonusPreRound() return RunBonusFunc( "preRoundStart" ) end
function bonusOnRoundStart() return RunBonusFunc( "onRoundStart" ) end
function bonusOnRoundEnd() return RunBonusFunc( "onRoundEnd" ) end


function beginMiniGame()
	local autoMinigames =  minigameBag.takeObject(params)
	autoMinigames.shuffle()
	
	minigame = autoMinigames.takeObject(params)
	inMinigame = true
	
	autoMinigames.destruct()
end

function deployRupees(o, color)
	local playerList = getSeatedPlayers()
	for i, player in ipairs(playerList) do
		local set = findObjectSetFromColor(player)
		if set then
			local bet = #findBetsInZone(set.zone)
			if bet ~= 0 then
				rupeePull(set.zone)
			end
		end
	end
end





--DECK FINDING/TRACKING SECTION





--checks for current deck when the tool loads, triggered by onload
function checkForDeck()
	local objectsInZone = deckZone.getObjects()
	for i, deck in ipairs(objectsInZone) do
		if deck.tag == "Deck" then
			if mainDeck~=nil and mainDeck~=deck then
				destroyObject(mainDeck)
			end
			
			mainDeck = deck
			break
		end
	end
end

--marks a deck in tool's logic as "mainDeck", which is the deck dealt from
function onObjectEnterScriptingZone(zone, object)
	if zone == deckZone and object.tag == "Deck" then
		if mainDeck~=nil and mainDeck~=object then
			destroyObject(mainDeck)
		end
		
		mainDeck = object
	end
	
	-- Prevent people messing with rewards
	for _,rewardZone in pairs(rewards) do
		if zone==rewardZone then
			local col = object.held_by_color
			
			if (not col) then
				object.setPosition( {0,10,0} )
			elseif (col~="Black" and not Player[col].admin) then -- Someone adding to the zone that shouldn't be
				object.destruct()
			end
			
			return
		end
	end
end

--Activated by click function, pulls out a deck from a set of possible bags
function obtainDeck()
	local deckPos = deckZone.getPosition()
	local params = {}
	params.position = {deckPos.x, deckPos.y, deckPos.z}
	local decks = deckBag.takeObject(params)
	decks.shuffle()
	
	params.rotation = {0,0,180}
	params.callback = "shuffleNewDeck"
	params.callback_owner = Global
	
	local taken = decks.takeObject(params)
	taken.shuffle()
	taken.setPosition(params.position)
	taken.setRotation(params.rotation)
	mainDeck = taken
	
	decks.destruct()
end

function shuffleNewDeck()
	mainDeck.shuffle()
	mainDeck.lock()
	mainDeck.interactable = false
end





--CARD DEALING SECTION





--Used to clear all cards and figurines out of a zone
function clearCards(zoneToClear)
	local override = RunBonusFunc( "clearCards", {zone=zoneToClear} )
	if override==true then return end
	
	local objectsInZone = zoneToClear.getObjects()
	for i, object in ipairs(objectsInZone) do
		local tag = object.tag
		if tag == "Card" or tag == "Deck" or (tag == "Figurine" and object.getLock()) or (object.tag == "Chip" and powerupEffectTable[object.getName()] and object.getLock()) then
			destroyObject(object)
		end
	end
	
	displayResult( findObjectSetFromZone(zoneToClear), 0, false )
end

function clearCardsOnly(zoneToClear)
	local override = RunBonusFunc( "clearCardsOnly", {zone=zoneToClear} )
	if override==true then return end
	
	local objectsInZone = zoneToClear.getObjects()
	for i, object in ipairs(objectsInZone) do
		local tag = object.tag
		if tag == "Card" or tag == "Deck" then
			destroyObject(object)
		end
	end
end

--Used to clear all chips out of a zone
function clearBets(zoneToClear, lockedOnly)
	local override = RunBonusFunc( "clearBets", {zone=zoneToClear, lockedOnly=lockedOnly} )
	if override==true then return end
	
	local objectsInZone = zoneToClear.getObjects()
	
	local badBagObjects = 0
	local set = findObjectSetFromZone(zoneToClear)
	
	for i, object in ipairs(objectsInZone) do
		if ((object.tag == "Chip" and not powerupEffectTable[object.getName()]) or (object.tag == "Bag" and object.getName():sub(1,11)~="Player save")) and not (lockedOnly and object.interactable) then
			if object.tag == "Bag" then -- Remove anything that shouldn't be here
				local goodIDs = object.getTable("Blackjack_BetBagContents") or {}
				local contents = object.getObjects()
				
				-----
				local params = {}
				params.position = set.container.getPosition()
				params.position.y = params.position.y + 0.25
				
				for i=1,#contents do
					if lockedOnly and (not goodIDs[contents[i].guid]) or goodIDs[contents[i].guid]<=0 then
						local taken = object.takeObject(params)
						set.container.putObject(taken)
						
						badBagObjects = badBagObjects + 1
					else
						local taken = object.takeObject(params)
						destroyObject(taken)
						
						goodIDs[contents[i].guid] = (goodIDs[contents[i].guid] or 0) - 1
					end
					params.position.y = math.min(params.position.y + 0.5, 20)
				end
				-----
			else
				destroyObject(object)
			end
		end
	end
	
	if badBagObjects>0 then
		broadcastToColor( string.format("Refunded %i bad objects in bet bag(s). Did you attempt to alter your bet?", badBagObjects), set.color, {1,0.25,0.25})
		
		for k,adminCol in pairs(getSeatedPlayers()) do
			if Player[adminCol].admin then
				printToColor( string.format("Refunded %i bad object(s) in bet bag of player %s (%s).", badBagObjects, set.color, Player[set.color].steam_name), adminCol, {1,0,0} )
			end
		end
	end
end

--Deals cards to the player. whichCard is a table with which # cards to deal
function dealDealer(whichCard)
	local override = RunBonusFunc( "dealDealer", {whichCard=whichCard or {}} )
	if override==true then return end
	
	for i, v in ipairs(whichCard or {}) do
		local pos = findCardPlacement(objectSets[1].zone, v)
		if v ~= 2 or (bonusShouldDealerReveal()) then
			placeCard(pos, true, objectSets[1], v<=2, true)
		else
			placeCard(pos, false, objectSets[1], v<=2, true)
		end
	end
end

--Deals to player using same method as dealDealer
function dealPlayer(color, whichCard)
	local override = RunBonusFunc( "dealPlayer", {color=color or "Black", whichCard=whichCard or {}} )
	if override==true then return end
	
	for i, v in ipairs(whichCard or {}) do
		local set = findObjectSetFromColor(color)
		if set then
			local pos = findCardPlacement(set.zone, v)
			placeCard(pos, true, set, true)
		end
	end
end


function updateCardPositions( set )
	local zone = set.zone
	local cards = findCardsInZone(zone)
	
	table.sort( cards, function(a,b)
		local aStarter = a.getTable("blackjack_playerSet")
		local bStarter = b.getTable("blackjack_playerSet")
		
		if aStarter and not bStarter then
			return true
		elseif bStarter and not aStarter then
			return false
		end
		
		local aPos = a.getPosition()
		local bPos = b.getPosition()
		
		if math.abs(aPos.z-bPos.z)<0.25 then -- Allow for a small variance in position, if we're too strict cards might re-order
			if math.abs(aPos.x-bPos.x)<0.25 then
				return aPos.y<bPos.y
			end
			return aPos.x>bPos.x
		end
		
		return aPos.z<bPos.z
	end)
	
	local zoneRot = zone.getRotation()
	for i=1,#cards do
		cards[i].setPosition( findCardPlacement(zone, i) )
		
		local rot = cards[i].getRotation()
		rot.x = zoneRot.x
		rot.y = zoneRot.y + 180
		rot.z = (rot.z>15 and rot.z<275) and 180 or 0
		cards[i].setRotation(rot)
	end
end

--Called by other functions to actually take the card needed
function btnFlipCard(card, col)
	local canFlip = RunBonusFunc( "onCardFlip", {card=card, col=col} )
	if canFlip==false then return end
	
	local set = card.getTable("blackjack_playerSet")
	if set and col~=set.color and col~=set.UserColor and not Player[col].admin then
		broadcastToColor( "This does not belong to you!", col, {1,0.2,0.2} )
		return
	end
	
	local rot = card.getRotation()
	rot.z = rot.z + 180
	card.setRotation(rot)
	
	if set then
		local targetRot = {0,0,0}
		for _,obj in pairs(findCardsInZone(set.zone)) do
			if obj~=card then
				obj.setRotation(targetRot)
			end
		end
		
		updateHandCounter( set )
	end
end
function cardPlacedCallback(obj, data)
	if (not obj) or obj==nil then return end -- card gone
	
	obj.setLock(true)
	obj.interactable = false
	obj.clearButtons()
	
	obj.setPosition(data.targetPos)
	
	local flippable = true
	
	if dealersTurn then
		for _,dlrCard in pairs(findCardsInZone(objectSets[1].zone)) do
			if dlrCard==obj then
				flippable = false
				break
			end
		end
	end
	
	if flippable then
		local rot = obj.getRotation()
		rot.z = data.flip and 0 or 180
		obj.setRotation(rot)
	end
	
	if data.isStarter and bonusCanFlip() then
		obj.setTable("blackjack_playerSet", data.set)
		
		if data.set.color~="Dealer" then
			obj.createButton({
				label="Flip", click_function="btnFlipCard", function_owner=nil,
				position={-0.4, 1.1, -0.95}, rotation={0,0,0}, width=300, height=350, font_size=130
			})
			obj.createButton({
				label="Flip", click_function="btnFlipCard", function_owner=nil,
				position={0.4, -1.1, -0.95}, rotation={0,0,180}, width=300, height=350, font_size=130
			})
		end
	else
		obj.setTable("blackjack_playerSet", nil)
	end
	
	if data.set then
		updateCardPositions( data.set )
		updateHandCounter( data.set )
	else
		findCardsToCount()
	end
	
	if obj.held_by_color then
		local new = obj.reload()
		new.interactable = false
	end
end
function placeCard(pos, flipBool, set, isStarter, fastDraw)
	if (not mainDeck) or (mainDeck==nil) or mainDeck.getQuantity()<40 then
		newDeck()
	end
	
	-- Small adjustment should fix clientside issues with position/rotation
	local targetPos = pos
	if pos.y then
		targetPos = {x=pos.x, y=pos.y, z=pos.z}
		pos.y = pos.y+0.1
	elseif pos[2] then
		targetPos = {pos[1], pos[2], pos[3]}
		pos[2] = pos[2]+0.1
	end
	
	lastCard = mainDeck.takeObject({position=pos, flip=flipBool, callback_function=function(o)
		cardPlacedCallback(o, {targetPos=targetPos, flip=flipBool, set=set, isStarter=isStarter})
	end, smooth = (not fastDraw)})
	lastCard.interactable = false
	
	if fastDraw then
		lastCard.setLock(true)
		lastCard.setPosition(targetPos)
		
		local rot = lastCard.getRotation()
		rot.z = flipBool and 0 or 180
		lastCard.setRotation(rot)
	end
end




--FIND FUNCTION SECTION




--Returns the objectSets entry for a given color
function findObjectSetFromColor(color)
	for i, set in ipairs(objectSets) do
		if color == set.color then
			return set
		end
	end
end

function findObjectSetFromKey(obj, key)
	if (not obj) or obj==nil then return end
	
	for i, set in ipairs(objectSets) do
		if obj == set[key] then
			return set
		end
	end
end
function findObjectSetFromZone(zone)
	for i, set in ipairs(objectSets) do
		if zone == set.zone then
			return set
		end
	end
end
function findObjectSetFromButtons(btnHandler)
	for i, set in ipairs(objectSets) do
		if btnHandler == set.btnHandler then
			return set
		end
	end
end

--Returns any cards found in a scripting zone (zone)
function findCardsInZone(zone)
	local zoneObjectList = zone.getObjects()
	local foundCards = {}
	for i, object in ipairs(zoneObjectList) do
		if object.tag == "Card" and object.getLock() then
			table.insert(foundCards, object)
		end
	end
	return foundCards
end

--Returns any decks in a scripting zone (zone)
function findDecksInZone(zone)
	local zoneObjectList = zone.getObjects()
	local foundDecks = {}
	for i, object in ipairs(zoneObjectList) do
		if object.tag == "Deck" and object.getLock() then
			table.insert(foundDecks, object)
		end
	end
	return foundDecks
end

--Returns any powerups in a scripting zone (zone)
function findFigurinesInZone(zone)
	local zoneObjectList = zone.getObjects()
	local foundFigurines = {}
	for i, object in ipairs(zoneObjectList) do
		if (object.tag == "Figurine" and object.getLock()) or (object.tag == "Chip" and powerupEffectTable[object.getName()] and object.getLock()) then
			table.insert(foundFigurines, object)
		end
	end
	return foundFigurines
end

--Returns any bettable objects in a scripting zone (zone)
function findBetsInZone(zone)
	local zoneObjectList = zone.getObjects()
	local foundChips = {}
	for i, object in ipairs(zoneObjectList) do
		if (object.tag == "Chip" and not powerupEffectTable[object.getName()]) or (object.tag == "Bag" and object.getName():sub(1,11)~="Player save") then
			table.insert(foundChips, object)
		end
	end
	return foundChips
end

--Used to find card dealing positions, based on zone and which position the card should be in
function findCardPlacement(zone, spot)
	local override = RunBonusFunc( "findCardPlacement", {zone=zone, spot=spot} )
	if type(override)=="table" then return override end
	
	if zone == objectSets[1].zone then
		return {6.5 - 2.6 * (spot-1), 1.8, -4.84}
	else
		local pos = zone.getPosition()
		local scale = zone.getScale()
		if spot <= 3 then
			return {pos.x+1-(1*(spot-1)), pos.y-(scale.y/2)+0.1+(0.1*(spot-1)), pos.z-0.5}
		else
			return {pos.x+1-(1*(math.min(spot, 6)-4)), pos.y-(scale.y/2)+0.4+(0.1*(math.min(spot, 20)-4)), pos.z+0.5}
		end
	end
end
function findPowerupPlacement(zone, spot)
	local override = RunBonusFunc( "findPowerupPlacement", {zone=zone, spot=spot} )
	if type(override)=="table" then return override end
	
	if zone == objectSets[1].zone then -- Dealer
		return {-8, 1.8, -8 + (1.5 * math.min(spot,3))}
	else
		local column = math.min( math.floor((spot-1)/5)+1, 18 ) / 20
		local row = ((spot-1)%5)/5
		return zone.positionToWorld({0.5, column-0.45, -0.5 + row*1.1})
	end
end




--MISC FUNCTION SECTION





function lockoutTimer(time)
	lockout = true
	Timer.destroy('lockout_timer')
	Timer.create({identifier='lockout_timer', function_name='concludeLockout', delay=time})
end

function concludeLockout()
	lockout = false
end

function delayedCallback(func, table, time)
	local params = table
	params.id = 'timer_' ..timerTick
	Timer.create({identifier=params.id, function_name=func, parameters=params, delay=time})
	timerTick = timerTick + 1
end

function reverseTable(table)
	local length = #table
	local reverse = {}
	for i, v in ipairs(table) do
		reverse[length + 1 - i] = v
	end
	return reverse
end

function waitTime(tm)
	local endTime = os.clock() + tm -- Using os.clock in this way seems... Dirty. Better than locking speed to FPS, though.
	while os.clock() < endTime do
		coroutine.yield(0)
	end
end




--BUTTON CLICK FUNCTION SECTION





function hitCard(handler, color)
	local set = findObjectSetFromButtons(handler)
	local zone = set.zone
	
	if zone and (color == "Black" or Player[color].promoted or Player[color].host) then
		local override = RunBonusFunc( "onHit", {zone=zone} )
		if override==true then return end
		
		local cardsInZone = #findCardsInZone(zone)
		local decksInZone = #findDecksInZone(zone)
		local pos = findCardPlacement(zone, cardsInZone + decksInZone + 1)
		placeCard(pos, true, set, cardsInZone<2 and decksInZone==0, set.color=="Dealer")
	end
end

local bankruptData = {}
function playerBankrupt(handler, color)
	local set = findObjectSetFromKey(handler, "tbl")
	
	if set and color == set.color then
		local count = 0
		
		local zoneObjects = set.zone.getObjects()
		local tableObjects = set.tbl.getObjects()
		local prestigeObjects = set.prestige.getObjects()
		
		for _,zone in pairs({zoneObjects, tableObjects, prestigeObjects}) do
			for _, obj in ipairs(zone) do
				if obj.tag == "Chip" and obj.getName()=="Bankruptcy token" then
					count = count + (obj.getQuantity()==-1 and 1 or obj.getQuantity())
				end
			end
		end
		
		if count>=12 then
			doChipDestruction(set, true, false)
			
			local destroyPrestige = GetSetting("Bankruptcy.ClearPrestige", false)
			
			local starter = takeObjectFromContainer( set.tbl, "f3ea0f" )
			local starterObjects = starter.getObjects()
			local params = {position = set.tbl.getPosition()}
			for i, object in ipairs(starterObjects) do
				params.position.y = params.position.y + 1.5
				local newObj = starter.takeObject(params)
				
				local oldDesc = newObj.getDescription()
				newObj.setDescription( ("%s - %s\n\n%s"):format(Player[color].steam_id, Player[color].steam_name, oldDesc) )
				
				if not destroyPrestige then -- Keeping our old prestige, ignore any in the bag
					local name = newObj.getVar("__trader_ObjectName") or newObj.getName()
					if newObj.getVar("PrestigeLevel") or (string.match(name, "New player") or string.match(name, "Prestige %d+")) and not string.find(name, "Trophy") then
						params.position.y = params.position.y - 1.5
						destroyObject(newObj)
					end
				end
			end
			starter.destruct()
			
			printToAll("Bankruptcy: " ..set.color.. " has returned to the game!", {0.25,1,0.25})
			
			return
		elseif count>0 then
			broadcastToColor( "Bankruptcy: Collect 12 Bankruptcy tokens to continue.", color, {0.75,0.5,0.5})
			
			return
		end
		
		
		local curTime = os.time()
		if bankruptData[color] and (bankruptData[color].cooldown or 0)>curTime then
			broadcastToColor( "Bankruptcy: Busy, please wait...", color, {1,0.25,0.25})
			return
		end
		
		if (not bankruptData[color]) or bankruptData[color].id~=Player[color].steam_id or (bankruptData[color].time + 10 <= curTime) then -- First press
			broadcastToColor( "Bankruptcy: Are you sure you want to do this? You may lose your current items! Press again to confirm.", color, {1,0.25,0.25})
			
			bankruptData[color] = {id=Player[color].steam_id, time=curTime}
			return
		end
		
		if not (bankruptData[color].lastDeclared and bankruptData[color].lastDeclared+20>curTime) then
			bankruptData[color].cooldown = curTime+5
			
			doBankruptDestruction(set)
			
			local newObj = takeObjectFromContainer( set.tbl, "15a03a", {0,0.5,-0.45} )
			if newObj then
				local oldDesc = newObj.getDescription()
				newObj.setDescription( ("%s - %s\n\n%s"):format(Player[color].steam_id, Player[color].steam_name, oldDesc) )
			end
			
			bankruptData[color].lastDeclared = curTime
			
			if not (bankruptData[color].lastAnnouncement and bankruptData[color].lastAnnouncement+300>curTime) then
				printToAll("Bankruptcy: " ..set.color.. " has declared bankruptcy!", {1,0.25,0.25})
				broadcastToColor( "Bankruptcy: Collect 12 Bankruptcy tokens then press this button again to return to the game.", color, {0.75,0.5,0.5})
				
				bankruptData[color].lastAnnouncement = curTime
			end
		end
	end
end

-- Prestige
-----------
local prestigeData = {}
function playerPrestige(handler, color)
	local set = findObjectSetFromKey(handler, "tbl")
	
	if set and color == set.color then
		local chips = {}
		local prestigeObject
		local prestigeLevel
		
		local zoneObjects = set.zone.getObjects()
		local tableObjects = set.tbl.getObjects()
		local prestigeObjects = set.prestige.getObjects()
		
		local plyID = Player[set.color].steam_id
		
		for _,zone in pairs({zoneObjects, tableObjects, prestigeObjects}) do
			for _, obj in ipairs(zone) do
				local objID = obj.getDescription():match("^(%d+) %- .*") 
				if (not objID) or objID==plyID then
					if obj.tag=="Chip" and chipListIndex[obj.getName()] then
						table.insert(chips, obj.getName())
					else
						local level = obj.getVar("PrestigeLevel") or tonumber((not string.find(obj.getName(), "Trophy")) and string.match(obj.getVar("__trader_ObjectName") or obj.getName(), "Prestige (%d+)") or "")
						if level then
							if (not prestigeObject) or level>prestigeLevel then
								prestigeObject = obj
								prestigeLevel = level
							end
							prestigeObject = obj
						elseif string.match(obj.getName(), "New player") then
							if not prestigeObject then
								prestigeObject = obj
								prestigeLevel = 0
							end
						end
					end
				end
			end
		end
		
		local hasRequired = false
		local requiredChip
		if prestigeLevel then
			if not prestigeTable[prestigeLevel+1] then
				local found = false
				for _,obj in pairs(getAllObjects()) do
					if obj.getLock() and obj.getVar("PrestigeLevel")==(prestigeLevel+1) then
						found = true
						
						table.insert(powerupTable, {obj.getGUID(), chosenPowerup[2]})
						
						break
					end
				end
				
				if not found then
					broadcastToColor( "Prestige: You have reached the maximum prestige level.", color, {0.25,1,0.25})
					
					return
				end
			end
			
			local targetObject = prestigeTable[prestigeLevel+1]
			requiredChip = targetObject.getVar("PrestigeChip")
			
			if chipListIndex[requiredChip] then
				local target = chipListIndex[requiredChip]
				
				for i=1,#chips do
					if chipListIndex[chips[i]] and chipListIndex[chips[i]]>=target then
						hasRequired = true
						break
					end
				end
			else
				for i=1,#chips do
					if chips[i]==requiredChip then
						hasRequired = true
						break
					end
				end
			end
		end
		
		if not hasRequired then
			if prestigeLevel and requiredChip then
				broadcastToColor( "Prestige: Prestige failed. You need at least "..tostring(requiredChip).." to reach Prestige "..tostring(prestigeLevel + 1)..".", color, {0.25,1,0.25})
			else
				broadcastToColor( "Prestige: Prestige failed. Ensure you have the appopriate chip and prestige gem on your table.", color, {0.25,1,0.25})
			end
			
			return
		end
		
		local curTime = os.time()
		if prestigeData[color] and (prestigeData[color].cooldown or 0)>curTime then
			broadcastToColor( "Prestige: Busy, please wait...", color, {1,0.25,0.25})
		elseif (not prestigeData[color]) or prestigeData[color].id~=Player[color].steam_id or (prestigeData[color].time + 10 <= curTime) then -- First press
			broadcastToColor( "Prestige: Do you want to advance to Prestige "..tostring(prestigeLevel+1).."? You may lose your current items! Press again to confirm.", color, {1,0.25,0.25})
			
			prestigeData[color] = {id=Player[color].steam_id, time=curTime}
		elseif not (prestigeData[color].lastDeclared and prestigeData[color].lastDeclared+20>curTime) then
			prestigeData[color].cooldown = curTime+5
			doPrestige(set, prestigeLevel+1)
		end
	end
end

function doPrestige(set, targetLevel)
	if not (set and targetLevel) then return end
	
	local targetObj = prestigeTable[targetLevel]
	if not targetObj then return false end
	
	if targetObj.Call("doPrestige", {set=set} ) then
		doPrestigeDestruction( set )
		
		takeObjectFromContainer( set.tbl, "996d26", {0,0.5,0.45} )
		
		return true
	end
	
	return false
end

function AddPrestige(data)
	if not (data.obj) then return end
	
	local name = data.obj.getName()
	if (not name) or name=="" then return end 
	
	local level = data.obj.getVar("PrestigeLevel")
	if (not level) or type(level)~="number" or level<1 then return end -- Not a valid prestige
	level = math.floor(level)
	
	prestigeTable[level] = data.obj
end
-----------

function dealButtonPressed(o, color)
	if (color == "Lua" or color == "Black" or Player[color].promoted or Player[color].host) then
		setRoundState( 2 )
		
		local override = bonusPreRound()
		if override then return end
		
		inMinigame = false
		if minigame and not (minigame==nil) then
			destroyObject(minigame)
		end
		
		if color == "Lua" or (not lockout) then
			dealersTurn = false
			dealingDealersCards = false
			
			for _,splitSet in ipairs(objectSets) do
				if splitSet.color:sub(1,5)=="Split" then
					if splitSet.container.getQuantity()>0 then -- Someone forgot to claim their stuff
						local targetSet = nil
						for i=2,#objectSets do
							if splitSet.UserColor==objectSets[i].color then
								targetSet = objectSets[i]
								break
							end
						end
						if targetSet and targetSet.container then
							local params = {}
							params.position = targetSet.container.getPosition()
							params.position.y = params.position.y+0.15
							
							for i=1,splitSet.container.getQuantity() do
								splitSet.container.takeObject(params)
							end
						end
					end
					
					splitSet.SplitUser = nil
					splitSet.UserColor = nil
					splitSet.prestige = splitSet.zone
					splitSet.tbl = splitSet.zone
					
					splitSet.container.setColorTint({0.25,0.25,0.25})
				end
			end
			
			lockoutTimer(10)
			if mainDeck == nil or mainDeck.getQuantity() < 80 then
				newDeck()
				deckBool = true
			end
			for i, set in pairs(objectSets) do
				clearPlayerActions(set.zone)
				clearCardsOnly(set.zone)
			end
			
			bonusOnRoundStart()
			
			local playerList = getSeatedPlayers()
			dealOrder = {}
			for i, player in ipairs(playerList) do
				local set = findObjectSetFromColor(player)
				if set then
					local zoneObjectList = set.zone.getObjects()
					for j, bet in ipairs(zoneObjectList) do
						if (bet.tag == "Chip" and not powerupEffectTable[bet.getName()]) or (bet.tag == "Bag" and bet.getName():sub(1,11)~="Player save" and bet.getQuantity()>0) then
							table.insert(dealOrder, player)
							break
						end
					end
				end
			end
			startLuaCoroutine(Global, "dealInOrder")
		else
			broadcastToColor("Error: Button delay is active.\nWait a moment then try again.", color, {1,0.25,0.25})
		end
	end
end

function newDeck()
	if mainDeck ~= nil then
		destroyObject(mainDeck)
	end
	obtainDeck()
end

function dealInOrder()
	-- Setup Hand
	local firstToGo = nil
	if deckBool then
		waitTime( 1 )
		deckBool = false
	end
	findCardsToCount()
	
	-- Lock Chips
	for i=#dealOrder,1,-1 do
		local set = findObjectSetFromColor(dealOrder[i])
		if set then
			local zoneObjectList = set.zone.getObjects()
			
			local foundBets = false
			for j, bet in ipairs(zoneObjectList) do
				if ((bet.tag == "Chip" and not powerupEffectTable[bet.getName()]) or (bet.tag == "Bag" and bet.getName():sub(1,11)~="Player save")) and bet.held_by_color==nil then
					foundBets = true
					bet.interactable = false
					bet.setLock(true)
					
					if bet.tag == "Bag" then -- Additional bag protections
						local fullContents = bet.getObjects()
						local guids = {}
						
						for i=1,#fullContents do
							guids[fullContents[i].guid] = (guids[fullContents[i].guid] or 0) + 1 -- Account for multiple instances of a single guid
						end
						
						bet.setTable("Blackjack_BetBagContents", guids)
					end
				end
			end
			
			if not foundBets then table.remove(dealOrder, i) end
		end
	end
	
	-- Begin Dealing
	for i=1, 2 do
		for o, set in ipairs(reverseTable(objectSets)) do
			if set.color == "Dealer" then
				dealDealer({i})
				while lastCard.getName() == "Joker" do
					lastCard.destruct()
					dealDealer({i})
					resetTimer(3)
				end
				waitTime(0.1)
			else
				for j, player in ipairs(dealOrder) do
					if set.color == player then
						if firstToGo == nil then firstToGo = set end
						dealPlayer(player, {i})
						waitTime(0.1)
						break
					end
				end
			end
		end
	end
	if firstToGo ~= nil then
		delayedCallback('whoGoesFirst', {set=firstToGo}, 1)
	else
		concludeLockout()
		
		waitTime(0.6)
		
		dealersTurn = true
		revealHandZone( objectSets[1].zone, true )
	end
	return 1
end

function whoGoesFirst(table)
	for i=#objectSets,1,-1 do
		if objectSets[i].color==table.set.color then -- For some reason timers create a copy of the table, not referencing the table itself. Does TTS do ANYTHING right?
			if objectSets[i].value>21 then
				passPlayerActions(table.set.zone)
			else
				currentPlayerTurn = table.set.color
				createPlayerActions(table.set.btnHandler)
				
				beginTurnTimer(objectSets[i])
			end
		end
	end
	Timer.destroy(table.id)
	concludeLockout()
end

function beginTurnTimer(set, supressMessage)
	if GetSetting("Rounds.TurnTimeLimit", 0)>0 then
		turnActive = false
		
		local turnTime = GetSetting("Rounds.TurnTimeLimit", 30)
		
		setRoundState( 2, turnTime )
		
		if Player[set.UserColor or set.color].seated and not supressMessage then
			broadcastToColor( ("It's your turn. You have %i seconds to take an action or you will be forced to stand."):format(turnTime), set.UserColor or set.color, {0.25,1,0.25})
		end
	end
end
function endTurnTimer(set, force)
	if force or GetSetting("Rounds.TurnTimeLimitEnds", false) then
		turnActive = true
		
		if roundTimer and roundTimer.getValue()>0 then
			setRoundState( 2, 0 )
		end
	else
		beginTurnTimer(set, true)
	end
end

-- Player actions --

function validateBetBag(data)
	if not (data.bag and data.bag==nil) then -- null check
		local fullContents = data.bag.getObjects()
		local guids = {}
		
		for i=1,#fullContents do
			guids[fullContents[i].guid] = (guids[fullContents[i].guid] or 0) + 1 -- Account for multiple instances of a single guid
		end
		
		data.bag.setTable("Blackjack_BetBagContents", guids)
	end
end
local function repeatBet( color, set, setTarget, addHeight )
	setTarget = setTarget or set
	
	local zoneObjects = set.zone.getObjects()
	local currentBet = {}
	
	local container
	local badBagObjects = 0
	
	local refundParams = {}
	refundParams.position = set.container.getPosition()
	refundParams.position.y = refundParams.position.y + 0.25
	for j, bet in ipairs(zoneObjects) do
		if not bet.interactable then
			if (bet.tag == "Chip" and not powerupEffectTable[bet.getName()]) then
				local count = bet.getQuantity()
				if count==-1 then count = 1 end -- Just... Why?
				
				currentBet[bet.getName()] = (currentBet[bet.getName()] or 0) + count
			elseif (bet.tag == "Bag" and bet.getName():sub(1,11)~="Player save") then
				container = bet
				local contents = bet.getObjects()
				
				bet.setRotation({0,0,0})
				local pos = bet.getPosition()
				pos.y = pos.y + 10
				
				local objs = {}
				local goodIDs = bet.getTable("Blackjack_BetBagContents")
				
				for i=1,#contents do
					if goodIDs[contents[i].guid] and goodIDs[contents[i].guid]>0 then
						local obj = bet.takeObject( {position=pos, rotation={0,0,0}} )
						
						pos.y = pos.y + 8
						
						if ((obj.tag == "Chip" or obj.tag == "Generic") and not powerupEffectTable[obj.getName()]) then
							local count = obj.getQuantity()
							if count==-1 then count = 1 end
							
							currentBet[obj.getName()] = (currentBet[obj.getName()] or 0) + count
						end
						
						table.insert(objs, obj)
					else
						local taken = bet.takeObject(refundParams)
						
						refundParams.position.y = math.min(refundParams.position.y + 0.5, 20)
						set.container.putObject(taken)
						
						badBagObjects = badBagObjects + 1
					end
					
					goodIDs[contents[i].guid] = (goodIDs[contents[i].guid] or 0) - 1
				end
				
				for i=1,#objs do
					bet.putObject(objs[i])
					destroyObject(objs[i])
				end
				delayedCallback('validateBetBag', {bag=bet}, 0.1)
			end
		end
	end
	
	if badBagObjects>0 then
		broadcastToColor( string.format("Refunded %i bad object(s) in bet bag. Did you attempt to alter your bet?", badBagObjects), set.color, {1,0.25,0.25})
		
		for k,adminCol in pairs(getSeatedPlayers()) do
			if Player[adminCol].admin then
				printToColor( string.format("Refunded %i bad object(s) in bet bag of player %s (%s).", badBagObjects, set.color, Player[set.color].steam_name), adminCol, {1,0,0} )
			end
		end
	end
	
	local tableObjects = set.tbl.getObjects()
	local foundStacks = {}
	for j, chip in ipairs(tableObjects) do
		if chip.tag == "Chip" then
			local name = chip.getName()
			if currentBet[name] and currentBet[name]>0 then
				local count = chip.getQuantity()
				if count==-1 then count = 1 end
				
				if count>currentBet[name] then
					table.insert(foundStacks, {chip, currentBet[name]})
					
					currentBet[name] = nil
				elseif count==currentBet[name] then
					table.insert(foundStacks, {chip})
					
					currentBet[name] = nil
				else
					table.insert(foundStacks, {chip})
					
					currentBet[name] = (currentBet[name] or 0) - count
				end
			end
		end
	end
	
	for _,v in pairs(currentBet) do -- Should only run if there's values left
		broadcastToColor( "Error: You don't have enough matching chips on your table.", color, {1,0.25,0.25} )
		return false
	end
	
	local zonePos = setTarget.zone.getPosition()
	
	if container and set==setTarget then
		zonePos = container.getPosition()
		zonePos.y = zonePos.y + 2
	else
		if addHeight then zonePos.y = zonePos.y + addHeight end
		
		zonePos.z = zonePos.z + 3.1
		zonePos.y = zonePos.y - 2
	end
	
	
	local placedBag = nil
	local chipIDs = {}
	if betBags and #foundStacks>1 then
		placedBag = betBags.takeObject( {position=zonePos, rotation={0,0,0}} )
		zonePos.y = zonePos.y+3
		
		placedBag.interactable = false
		placedBag.setLock(true)
	end
	
	for i=1,#foundStacks do
		local tbl = foundStacks[i]
		
		if tbl[2] then
			for i=1,tbl[2] do
				local taken = tbl[1].takeObject( {position=zonePos, rotation={0,0,0}} )
				zonePos.y = zonePos.y + 0.1
				
				if placedBag then
					placedBag.putObject( taken )
				else
					taken.interactable = false
					taken.setLock(true)
				end
			end
			zonePos.y = zonePos.y+0.6
		else
			tbl[1].setPositionSmooth( zonePos )
			tbl[1].setRotation( {0,0,0} )
			
			zonePos.y = zonePos.y + (math.max(tbl[1].getQuantity(), 1)*0.6)
			
			if placedBag then
				placedBag.putObject( tbl[1] )
			else
				tbl[1].interactable = false
				tbl[1].setLock(true)
			end
		end
	end
	
	if placedBag then
		delayedCallback('validateBetBag', {bag=placedBag}, 0.1)
	end
	
	return true
end

function createPlayerActions(btnHandler, simpleOnly)
	btnHandler.createButton({
		label="Stand", click_function="playerStand", function_owner=nil,
		position={-1, 0.25, 0}, rotation={0,0,0}, width=400, height=350, font_size=130
	})
	btnHandler.createButton({
		label="Hit", click_function="playerHit", function_owner=nil,
		position={1, 0.25, 0}, rotation={0,0,0}, width=400, height=350, font_size=130
	})
	
	if simpleOnly then return end
	
	local set = findObjectSetFromButtons( btnHandler )
	local cards = findCardsInZone(set.zone)
	if #cards==2 and cardNameTable[cards[1].getName()]==cardNameTable[cards[2].getName()] then
		if cards[1].getName()==cards[2].getName() or GetSetting("Hands.SplitOnValue", false) then
			btnHandler.createButton({
				label="Split", click_function="playerSplit", function_owner=nil,
				position={-1, 0.25, -0.65}, rotation={0,0,0}, width=400, height=250, font_size=100
			})
		end
	end
	
	if #cards==2 then
		btnHandler.createButton({
			label="Double", click_function="playerDouble", function_owner=nil,
			position={1, 0.25, -0.65}, rotation={0,0,0}, width=400, height=250, font_size=100
		})
	end
end
function delayedCreatePlayerActions(tbl)
	local set = tbl.set
	
	local betsInZone = #findBetsInZone(set.zone)
	local cardsInZone = #findCardsInZone(set.zone)
	local decksInZone = #findDecksInZone(set.zone)
	if betsInZone ~= 0 and (cardsInZone ~= 0 or decksInZone ~= 0) and set.value <= 21 then
		currentPlayerTurn = set.color
		return createPlayerActions(set.btnHandler)
	end
	
	return passPlayerActions(set.zone)
end

function clearPlayerActions(zone, ExtraOnly)
	local set = findObjectSetFromZone(zone)
	local handler = set.btnHandler
	
	handler.clearButtons()
	handler.createButton({
		label="0", click_function="hitCard", function_owner=nil, color={r=1,g=1,b=1},
		position={0, 0.25, 0}, rotation={0,0,0}, width=450, height=450, font_size=300
	}, true)
	createPlayerMetaActions(set)
	
	if ExtraOnly then
		createPlayerActions(handler, true)
	end
	
	-- findCardsToCount()
	updateHandCounter( set )
end
function createPlayerMetaActions(set)
	if set.tbl and set.tbl~=set.zone and set.color~="Dealer" then
		set.tbl.clearButtons()
		
		local scaleTable = set.tbl.getScale()
		
		set.tbl.createButton({
			click_function='playerPrestige', label='Prestige', function_owner=nil,
			position={ -0.13, -0.435, -0.48 }, rotation={0,180,0}, scale = {2/scaleTable.x, 2/scaleTable.y, 2/scaleTable.z},
			width=650, height=190, font_size=110, color = {r=0.5,g=0.5,b=0.5}
		})
		set.tbl.createButton({
			click_function='playerBankrupt', label='Bankrupt', function_owner=nil,
			position={ 0.13, -0.435, -0.48 }, rotation={0,180,0}, scale = {2/scaleTable.x, 2/scaleTable.y, 2/scaleTable.z},
			width=650, height=190, font_size=110, color = {r=0.5,g=0.5,b=0.5}
		})
	end
end

function passPlayerActions(zone)
	local nextInLine = nil
	for i, set in ipairs(reverseTable(objectSets)) do
		if set.color == "Dealer" then
			dealersTurn = true
			currentPlayerTurn = "None"
			revealHandZone(set.zone, true)
			
			if GetSetting("Rounds.TurnTimeLimit", 0)>0 and roundTimer then
				roundTimer.setValue(0)
				roundTimer.Clock.paused = false
			end
			break
		elseif set.zone == zone then
			if set.color:sub(1,5)=="Split" and set.SplitUser then
				local originalSet = set.SplitUser
				
				local betsInZone = #findBetsInZone(originalSet.zone)
				local cardsInZone = #findCardsInZone(originalSet.zone)
				local decksInZone = #findDecksInZone(originalSet.zone)
				if betsInZone ~= 0 and (cardsInZone ~= 0 or decksInZone ~= 0) and originalSet.value <= 21 then
					currentPlayerTurn = originalSet.color
					createPlayerActions(originalSet.btnHandler)
					break
				end
				
				return passPlayerActions(originalSet.zone)
			end
			
			nextInLine = i + 1
		elseif i == nextInLine then
			local betsInZone = #findBetsInZone(set.zone)
			local cardsInZone = #findCardsInZone(set.zone)
			local decksInZone = #findDecksInZone(set.zone)
			if betsInZone ~= 0 and (cardsInZone ~= 0 or decksInZone ~= 0) and set.value <= 21 then
				currentPlayerTurn = set.color
				createPlayerActions(set.btnHandler)
				
				beginTurnTimer(set)
				
				break
			end
			nextInLine = nextInLine + 1
		end
	end
end
function delayedPassPlayerActions(data)
	if currentPlayerTurn==data.color then
		passPlayerActions(data.zone)
	end
end

function playerHit(btnHandler, color)
	local set = findObjectSetFromButtons(btnHandler)
	if color==set.color or color=="Black" or Player[color].promoted or Player[color].host or (set.color:sub(1,5)=="Split" and set.UserColor==color) then
		if set.color~=currentPlayerTurn then
			clearPlayerActions(set.zone)
			
			return broadcastToColor("Error: It's not your turn.", color, {1,0.25,0.25})
		end
		if not lockout then
			local override = RunBonusFunc( "onPlayerHit", {set=set, color=color} )
			if override==true then return end
			
			endTurnTimer(set)
			clearPlayerActions(set.zone, true)
			lockoutTimer(1)
			if set.value > 21 then
				clearPlayerActions(set.zone)
				passPlayerActions(set.zone)
			else
				checkForBust(set, (mainDeck and (not (mainDeck==nil)) and mainDeck.getObjects()[1] or {}).nickname or "")
				forcedCardDraw(set.zone)
			end
		else
			broadcastToColor("Error: Button delay is active.\nWait a moment then try again.", color, {1,0.25,0.25})
		end
	end
end
function playerDouble(btnHandler, color)
	local set = findObjectSetFromButtons(btnHandler)
	
	if color == set.color or color == "Black" or Player[color].promoted or Player[color].host or (set.color:sub(1,5)=="Split" and set.UserColor==color) then
		if set.color~=currentPlayerTurn then
			clearPlayerActions(set.zone)
			
			return broadcastToColor("Error: It's not your turn.", color, {1,0.25,0.25})
		end
		
		if set.value > 21 then
			clearPlayerActions(set.zone)
			passPlayerActions(set.zone)
			return
		end
		
		local cards = findCardsInZone(set.zone)
		if #cards~=2 then clearPlayerActions(set.zone, true) return end
		
		if not lockout then
			local override = RunBonusFunc( "prePlayerDouble", {set=set, color=color} )
			if override==true then return end
			
			endTurnTimer(set)
			if not repeatBet(color,set,splitSet) then return end
			
			local override = RunBonusFunc( "onPlayerDouble", {set=set, color=color} )
			if override==true then return end
			
			lockoutTimer(1.5)
			forcedCardDraw(set.zone)
			clearPlayerActions(set.zone)
			passPlayerActions(set.zone)
		else
			broadcastToColor("Error: Button delay is active.\nWait a moment then try again.", color, {1,0.25,0.25})
		end
	end
end

function checkForBust(set, addCard)
	if set.value > 21 then
		clearPlayerActions(set.zone)
		lockoutTimer(0.75)
		
		delayedCallback('delayedPassPlayerActions', {zone=set.zone, color=set.color}, 0.5)
	elseif addCard and cardNameTable[addCard] then
		local val = cardNameTable[addCard]
		if val=="Ace" then val=1 end
		
		if cardNameTable[addCard]=="Joker" or ( set.value+(tonumber(val) or 0) > (set.soft and 31 or 21) ) then
			clearPlayerActions(set.zone)
			lockoutTimer(0.75)
			
			delayedCallback('delayedPassPlayerActions', {zone=set.zone, color=set.color}, 0.5)
		end
	end
end

function playerStand(btnHandler, color)
	local set = findObjectSetFromButtons(btnHandler)
	if color == set.color or color == "Black" or Player[color].promoted or Player[color].host or (set.color:sub(1,5)=="Split" and set.UserColor==color) then
		if set.color~=currentPlayerTurn then
			clearPlayerActions(set.zone)
			
			return broadcastToColor("Error: It's not your turn.", color, {1,0.25,0.25})
		end
		
		if color=="Black" or not lockout then
			endTurnTimer(set, true)
			clearPlayerActions(set.zone)
			lockoutTimer(0.5)
			
			delayedCallback('delayedPassPlayerActions', {zone=set.zone, color=set.color}, 0.25)
			
			RunBonusFunc( "onPlayerStand", {set=set, color=color} )
		else
			broadcastToColor("Error: Button delay is active.\nWait a moment then try again.", color, {1,0.25,0.25})
		end
	end
end

function playerSplit(btnHandler, color)
	local set = findObjectSetFromButtons(btnHandler)
	if color == set.color or color == "Black" or Player[color].promoted or Player[color].host or (set.color:sub(1,5)=="Split" and set.UserColor==color) then
		if set.color~=currentPlayerTurn then
			clearPlayerActions(set.zone)
			
			return broadcastToColor("Error: It's not your turn.", color, {1,0.25,0.25})
		end
		
		local cards = findCardsInZone(set.zone)
		if #cards~=2 or cardNameTable[cards[1].getName()]~=cardNameTable[cards[2].getName()] then return end
		if (not GetSetting("Hands.SplitOnValue", false)) and cards[1].getName()~=cards[2].getName() then return end
		
		if not lockout then
			endTurnTimer(set)
			for _,splitSet in ipairs(reverseTable(objectSets)) do
				if splitSet.color:sub(1,5)=="Split" and not splitSet.SplitUser then
					local override = RunBonusFunc( "prePlayerSplit", {set=set, color=color} )
					if override==true then return end
					
					if not repeatBet(color,set,splitSet) then return end -- Could not get chips for split
					
					local override = RunBonusFunc( "onPlayerSplit", {set=set, color=color} )
					if override==true then return end
					
					lockoutTimer(2)
					
					splitSet.SplitUser = set
					splitSet.UserColor = set.UserColor or set.color
					splitSet.prestige = set.prestige
					splitSet.tbl = set.tbl
					splitSet.container.setColorTint( stringColorToRGB(set.UserColor or set.color) or {1,1,1} )
					
					cards[1].setPosition( findCardPlacement(splitSet.zone,1) )
					cards[1].setTable("blackjack_playerSet", splitSet) -- Sets zone to split zone, for flipping
					
					cards[2].setPosition( findCardPlacement(set.zone,1) )
					
					placeCard(findCardPlacement(set.zone,2), true, set, true)
					placeCard(findCardPlacement(splitSet.zone,2), true, splitSet, true)
					
					clearPlayerActions(set.zone)
					currentPlayerTurn = splitSet.color
					
					delayedCallback('delayedCreatePlayerActions', {set=splitSet}, 1.5)
					
					return
				end
			end
			
			broadcastToColor("Error: No free Split zones!", color, {1,0.25,0.25})
		else
			broadcastToColor("Error: Button delay is active.\nWait a moment then try again.", color, {1,0.25,0.25})
		end
	end
end

function payButtonPressed(o, color)
	if (color == "Lua" or color == "Black" or Player[color].promoted or Player[color].host) then
		if minigame and not (minigame==nil) and minigame.getVar("blackjackEndRound") and minigame.Call("blackjackEndRound", {color=color}) then -- Override
			return
		end
		
		setRoundState( 1, GetSetting("Rounds.BetTime", 30) )
		
		if minigame and not (minigame==nil) then
			destroyObject(minigame)
		end
		
		if color == "Lua" or (not lockout) then
			dealersTurn = false
			dealingDealersCards = false
			
			findCardsToCount() -- Update values
			
			lockoutTimer(10)
			local dealerValue = objectSets[1].value
			local dealerCount = objectSets[1].count
			for i, set in pairs(objectSets) do
				local value = set.value
				local count = set.count
				if i ~= 1 and value ~= 0 and count ~= 0 then
					if value<=21 and (value>dealerValue or dealerValue>21 and dealerValue~=69) or (value>=69 and value<=72 and dealerValue~=69) or (value==68 or value==71) then
						local betsInZone = #findBetsInZone(set.zone)
						if betsInZone ~= 0 then processPayout(set.zone, calculatePayout(set.zone), true) end
					elseif ((dealerValue<=21 or dealerValue==69) and value == dealerValue) or count >= 5 or (value>=68 and value<=72) then
						-- Unlock Chips
						local zoneObjectList = set.zone.getObjects()
						for j, bet in ipairs(zoneObjectList) do
							if (bet.tag == "Chip" and not powerupEffectTable[bet.getName()]) or (bet.tag == "Bag" and bet.getName():sub(1,11)~="Player save") then
								bet.interactable = true
								bet.setLock(false)
								
								if set.UserColor then
									local targetSet = findObjectSetFromColor(set.UserColor) or set.SplitUser
									if targetSet and targetSet.container then
										targetSet.container.putObject(bet)
									end
								end
							end
						end
					else
						if value > 21 and not bonusShouldBust(set) then
							-- Unlock Chips
							local zoneObjectList = set.zone.getObjects()
							for j, bet in ipairs(zoneObjectList) do
								if (bet.tag == "Chip" and not powerupEffectTable[bet.getName()]) or (bet.tag == "Bag" and bet.getName():sub(1,11)~="Player save") then
									bet.interactable = true
									bet.setLock(false)
									
									if set.UserColor then
										local targetSet = findObjectSetFromColor(set.UserColor) or set.SplitUser
										if targetSet and targetSet.container then
											targetSet.container.putObject(bet)
										end
									end
								end
							end
						else
							clearBets(set.zone, true)
						end
					end
				end
				clearPlayerActions(set.zone)
				clearCards(set.zone)
				
				-- Unlock Chips
				local zoneObjects = set.zone.getObjects()
				local tableObjects = set.tbl.getObjects()
				local prestigeObjects = set.prestige.getObjects()
				
				for zid,zone in pairs({zoneObjects, tableObjects, prestigeObjects}) do
					for j, bet in ipairs(zone) do
						if (bet.tag == "Chip" and not powerupEffectTable[bet.getName()]) or (bet.tag == "Bag" and bet.getName():sub(1,11)~="Player save") and not bet.interactable then
							bet.interactable = true
							bet.setLock(false)
							
							if zid==1 and set.UserColor then -- Only affects bet zone
								local cont = (findObjectSetFromColor(set.UserColor) or set.SplitUser or {}).container
								if cont then
									Wait.frames(function()
										if bet and cont and not (bet==nil or cont==nil) then
											cont.putObject(bet)
										end
									end, 1)
								end
							end
						end
					end
				end
			end
			concludeLockout()
			
			if not inMinigame then
				bonusOnRoundEnd()
			end
			
			inMinigame = false
		else
			broadcastToColor("Error: Button delay is active.\nWait a moment then try again.", color, {1,0.25,0.25})
		end
	end
end

 --  --

function calculatePayout(zone)
	local set = findObjectSetFromZone(zone)
	local value = set.value
	local count = set.count
	local betMultiplier = 1
	if value == 71 and count == 2 then
		--double joker
		giveReward( "DoubleJoker", zone )
		betMultiplier = 14
	elseif value == 70 and count == 3 then
		--triple sevens
		giveReward( "TripleSeven", zone )
		betMultiplier = 7
	elseif (value <= 21 or value == 68) and count >= 5 then
		if (value == 21 or value == 68) and count >= 6 then
			--six card 21
			giveReward( "SixCardTwentyOne", zone )
			betMultiplier = 5
		elseif count >= 6 then
			--six card win
			giveReward( "SixCardWin", zone )
			betMultiplier = 4
		elseif (value == 21 or value == 68) and count == 5 then
			--five card 21
			giveReward( "FiveCardTwentyOne", zone )
			betMultiplier = 4
		elseif count == 5 then
			--five card win
			giveReward( "FiveCardWin", zone )
			betMultiplier = 3
		end
	elseif value == 69 then
		--natural blackjack
		giveReward( "Blackjack", zone )
		betMultiplier = 3
	elseif value == 68 or value == 21 then
		--joker or 21
		if value == 68 then
			betMultiplier = (getPrestige(zone) + 2)
		else
			betMultiplier = 2
		end
	end
	
	local globalMultiplier = math.max(GetSetting("Bet.Multiplier", 1), 1)
	betMultiplier = (bonusGetPayoutMultiplier( set, betMultiplier ) or betMultiplier) * globalMultiplier
	
	return betMultiplier
end

function getPrestige(zone)
	local set = findObjectSetFromZone(zone)
	local zoneObjects = set.prestige.getObjects()
	for i, object in ipairs(zoneObjects) do
		local level = object.getVar("PrestigeLevel")
		if level then return level end
		
		local findStart, findEnd, findNumber = string.find(object.getVar("__trader_ObjectName") or object.getName(), "Prestige (%d+)")
		if findStart and not string.find(object.getName(), "Trophy") then
			return (tonumber(findNumber) or 0)
		end
	end
	return 0
end

local selfDestructScript = [[
function onLoad()
	expireTime = os.time() + %i
end
function onUpdate()
	if expireTime and os.time()>expireTime then destroyObject(self) end
end]]
function processPayout(zone, iterations, lockedOnly)
	local set = findObjectSetFromZone(zone)
	local zoneObjects = zone.getObjects()
	local badBagObjects = 0
	
	local plyID = Player[set.UserColor or set.color].seated and Player[set.UserColor or set.color].steam_id
	
	for j, bet in ipairs(zoneObjects) do
		local wasLocked = {}
		if ((bet.tag == "Chip" and not powerupEffectTable[bet.getName()]) or (bet.tag == "Bag" and bet.getName():sub(1,11)~="Player save")) then
			if (not lockedOnly) or (not bet.interactable) or wasLocked[bet.getGUID()] then
				if (lockedOnly and bet.tag == "Bag") then -- Remove anything that shouldn't be here
					local goodIDs = bet.getTable("Blackjack_BetBagContents")
					local contents = bet.getObjects()
					
					-----
					local params = {}
					params.position = set.container.getPosition()
					params.position.y = params.position.y + 0.25
					
					for n=1,#contents do
						if (not goodIDs[contents[n].guid]) or goodIDs[contents[n].guid]<=0 then
							local taken = bet.takeObject(params)
							
							params.position.y = math.min(params.position.y + 0.5, 20)
							set.container.putObject(taken)
							
							badBagObjects = badBagObjects + 1
						end
						goodIDs[contents[n].guid] = (goodIDs[contents[n].guid] or 0) - 1
					end
					-----
				end
				
				wasLocked[bet.getGUID()] = true
				bet.interactable = true
				bet.setLock(false)
				
				
				local params = {}
				params.position = bet.getPosition()
				params.position.y = params.position.y - 10
				
				local clone = bet.clone(params)
				clone.setLock(true)
				clone.setPosition(params.position)
				
				clone.setLuaScript( selfDestructScript:format(((iterations/10)+2)*1.25) )
				
				
				local betID = bet.getDescription():match("^(%d+) %- .*")
				if betID and betID~=plyID then
					local foundPly = false
					local playerList = getSeatedPlayers()
					for _, col in ipairs(playerList) do
						local targetSet = findObjectSetFromColor(col)
						if Player[col].seated and Player[col].steam_id==betID and targetSet then
							foundPly = true
							for i=1, iterations do
								delayedCallback('payBet', {set=targetSet, bet=clone, final=(i==iterations)}, (i/10))
							end
							
							local setPos = targetSet.zone.getPosition()
							bet.setPosition( setPos )
							
							break
						end
					end
					
					if not foundPly then
						-- TODO: Push objects to autosave
						destroyObject(bet)
						destroyObject(clone)
					end
				else
					for i=1, iterations do
						delayedCallback('payBet', {set=set, bet=clone, final=(i==iterations)}, (i/10))
					end
					
					if set.UserColor and bet.tag=="Bag" then
						local targetSet = findObjectSetFromColor(set.UserColor)
						if targetSet then
							targetSet.container.putObject(bet)
						end
					end
				end
			end
		end
	end
	
	if badBagObjects>0 then
		broadcastToColor( string.format("Refunded %i bad object(s) in bet bag. Did you attempt to alter your bet?", badBagObjects), set.color, {1,0.25,0.25})
		
		for k,adminCol in pairs(getSeatedPlayers()) do
			if Player[adminCol].admin then
				printToColor( string.format("Refunded %i bad object(s) in bet bag of player %s (%s).", badBagObjects, set.color, Player[set.color].steam_name), adminCol, {1,0,0} )
			end
		end
	end
end

function validatePayoutObject(obj, data)
	if obj.tag~="Chip" or powerupEffectTable[obj.getName()] then return obj.destruct() end
	
	obj.unlock()
	
	if data.container then
		data.container.putObject( obj )
	end
end
function payBet(table)
	local params = {}
	params.position = table.set.container.getPosition()
	params.position.y = params.position.y + 0.25
	
	params.params = {container=table.set.container}
	params.callback = "validatePayoutObject"
	params.callback_owner = Global
	
	if table.bet.tag == "Chip" and not powerupEffectTable[table.bet.getName()] then
		local payout = table.bet.clone(params)
		payout.setPosition(params.position)
		
		payout.interactable = true
		payout.setLock(false)
		payout.setLuaScript( "" )
		
		table.set.container.putObject( payout )
		
		payout.destruct()
	elseif table.bet.tag == "Bag" and table.bet.getName():sub(1,11)~="Player save" then
		local payout = table.bet.clone(params)
		
		for l=1, table.bet.getQuantity() do
			local taken = payout.takeObject(params)
			taken.setPosition(params.position)
			
			taken.lock()
			params.position.y = math.min(params.position.y + 0.5, 20) -- Exact position doesn't matter too much, as long as it doesn't get sucked into another bag before we can validate.
		end
		payout.destruct()
	end
	Timer.destroy(table.id)
	if table.final then
		table.bet.destruct()
	end
end





--BUTTON CREATION SECTION




--Button creation, trigger is in onload()
function createButtons()
	--Card count displays, get created first so they have index of 0 on their zones
	for i, v in ipairs(objectSets) do
		v.btnHandler.createButton({
			label="0", click_function="hitCard", function_owner=nil,
			position={0, 0.25, 0}, rotation={0,0,0}, width=450, height=450, font_size=300
		}, true)
		
		createPlayerMetaActions(v)
	end
	
	cardHandler.createButton({
		label="Deal\ncards", click_function="dealButtonPressed", function_owner=nil,
		position={-0.46,0.19,-0.19}, rotation={0,0,0}, width=450, height=450, font_size=150
	})
	cardHandler.createButton({
		label="End\nround", click_function="payButtonPressed", function_owner=nil,
		position={0.46,0.19,-0.19}, rotation={0,0,0}, width=450, height=450, font_size=150
	})
end


-- Forward functions from third parties
function forwardFunction(params)
	if _G[params.function_name or ""] then -- Normally I'd use boolean logic instead of an if statement here, but we may have more than one return value
		return _G[params.function_name or ""]( unpack(params.data or {}) )
	end
end

function onChat(str, ply)
	if ply.admin and str:lower():sub(1,7)=="!debug " then
		printToColor( ("Debug: %s = %s"):format(str:sub(8,-1), tostring(_G[str:sub(8,-1)])), ply.color, {1,1,1})
		
		if type(_G[str:sub(8,-1)])=="table" then
			for k,v in pairs(_G[str:sub(8,-1)]) do
				printToColor( ("  -  %s = %s"):format(k, v), ply.color, {1,1,1})
			end
		end
		
		return false
	end
end
