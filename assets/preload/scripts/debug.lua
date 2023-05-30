--this bad bitch is made by kevin kuntz and edited by raltyro huge props to them
--(justamz edited it a bit to make it compatible with denpa, that includes removing the scroll speed and cam movement features :skull:)

--uncomment this if you want it to print on the command prompt instead or not wanting psych to crash LMAO
--local function debugPrint(...) print(...) end

luaDebugMode = true;

function onUpdate(elapsed)
    setTextString('botplayTxt', "");
end

function math.clamp(x,min,max)return math.max(min,math.min(x,max))end

function math.truncate(x, precision, round)
	if (precision == 0) then return math.floor(x) end
	
	precision = type(precision) == "number" and precision or 2
	
	x = x * math.pow(10, precision);
	return (round and math.floor(x + .5) or math.floor(x)) / math.pow(10, precision)
end

function cgProperty(i, v)
	return setProperty(i, getProperty(i) + v)
end

function cgPropertyFromGroup(o, id, i, v)
	return setPropertyFromGroup(o, id, i, getPropertyFromGroup(o, id, i) + v)
end

function cgPropertyFromClass(c, i, v)
	return setPropertyFromClass(c, i, getPropertyFromClass(c, i) + v)
end

local function getJustPressedKey(str)
	local b = getPropertyFromClass("flixel.FlxG", "keys.justPressed." .. str)
	return type(b) == "boolean" and b or false
end

local function getPressedKey(str)
	local b = getPropertyFromClass("flixel.FlxG", "keys.pressed." .. str)
	return type(b) == "boolean" and b or false
end

local travelHealth, travelBotplay = 100, -1
local function travel(ms)
	local prev = getPropertyFromClass("Conductor", "songPosition")
	
	local pos = math.clamp(
		prev + (type(ms) == "number" and ms or 0),
		1,
		getPropertyFromClass("flixel.FlxG", "sound.music.length") - 1
	)
	
	setPropertyFromClass("Conductor", "songPosition", pos)
	
	if (type(getPropertyFromClass("flixel.FlxG", "sound.music._channel.position")) == "number" and ms > 0) then
		setPropertyFromClass("flixel.FlxG", "sound.music._channel.position", pos)
	else
		setPropertyFromClass("flixel.FlxG", "sound.music.time", pos)
	end
	if (type(getProperty("vocals._channel.position")) == "number" and ms > 0) then
		setProperty("vocals._channel.position", pos)
	else
		setProperty("vocals.time", pos)
	end
	
	if (not getProperty('cpuControlled')) then
		travelHealth = getProperty("health")
		travelBotplay = 8
		setProperty('cpuControlled', true)
	end
	
	debugPrint("Travelled from " .. tostring(math.truncate(prev)) .. " to " .. tostring(math.truncate(pos)))
	
	return pos
end

local function toggleBotplay(b)
	local curBotplay = getProperty('cpuControlled')
	if (type(b) ~= "boolean") then b = not curBotplay end
	
	if (b == curBotplay) then return end
	setProperty('cpuControlled', b)
	setProperty('botplayTxt.visible', b)
	
	debugPrint("Auto mode " .. (b and "On" or "Off"))
end

local function togglePractice(b)
	local curPractice = getProperty('practiceMode')
	if (type(b) ~= "boolean") then b = not curPractice end
	
	if (b == curBotplay) then return end
	setProperty('practiceMode', b)
	
	debugPrint("Practice mode " .. (b and "On" or "Off"))
end

local ccc = false
function onUpdatePost(elapsed)
	if (not getProperty("paused")) then
		setPropertyFromClass("PlayState", "chartingMode", ccc)
	end
	
	travelBotplay = travelBotplay - 1
	if (travelBotplay >= 0) then
		setProperty("health", travelHealth)
	end
	if (travelBotplay == 0) then
		setProperty('cpuControlled', false)
		travelBotplay = -1
		
		local songPos = getSongPosition() + 3
		for i = 0, getProperty("notes.length") do
			if (getPropertyFromGroup("notes", i, "strumTime") > songPos) then
				break
			end
			setPropertyFromGroup("notes", i, "ignoreNote", true)
		end
	end
	
	if (not getProperty('startingSong')) then
		if (getJustPressedKey("F1")) then -- endSong
			endSong()
		end
	end

	if (getJustPressedKey("F2")) then -- Restart Song
		restartSong(true)
	end
	
	local shift = getPressedKey("SHIFT")
	local ctrl = getPressedKey("CONTROL")
	if (getJustPressedKey("F5")) then -- Go back 10 seconds
		travel(-(shift and 10000 or ctrl and 1000 or 5000))
	elseif (getJustPressedKey("F6")) then -- Go forward 10 seconds
		travel(shift and 10000 or ctrl and 1000 or 5000)
	end
	
	if (getJustPressedKey("F7")) then --  Zoom Out
		cgProperty('defaultCamZoom', -.1)
		debugPrint("Zoomed out " .. tostring(getProperty("defaultCamZoom")))
	elseif (getJustPressedKey("F8")) then -- Zoom In
		cgProperty('defaultCamZoom', .1)
		debugPrint("Zoomed in " .. tostring(getProperty("defaultCamZoom")))
	end
	

	if (getJustPressedKey("F9")) then -- toggle practice
		togglePractice()
	end

	if (travelBotplay <= -1 and getJustPressedKey("F10")) then -- toggle botplay
		toggleBotplay()
	end

	if getPropertyFromClass('flixel.FlxG', 'keys.justPressed.F11') then
        if not getPropertyFromClass("openfl.Lib", "application.window.fullscreen") then
            setPropertyFromClass("openfl.Lib", "application.window.fullscreen", true)
        else
            setPropertyFromClass("openfl.Lib", "application.window.fullscreen", false)
        end
    end
end

function onCreatePost()
	ccc = getPropertyFromClass("PlayState", "chartingMode")
	debugPrint(getProperty('unspawnNotes.length'))
end

function onPause()
	setPropertyFromClass("PlayState", "chartingMode", true)
	
	return Function_Continue
end

function onDestroy()
	setPropertyFromClass("PlayState", "chartingMode", ccc)
end

onResume = onDestroy

onGameOver = onDestroy

onEndSong = onDestroy
