--// Varialbes \\--
local HTTP = syn and syn.request or http_request or request or HttpPost
local httpService = game:GetService("HttpService")
local players = game:GetService("Players")
local sGui = game:GetService("StarterGui")
local ts = game:GetService("TeleportService")
local replicatedStorage = game:GetService("ReplicatedStorage")
local p = players.LocalPlayer

if not p.Character then 
    p.CharacterAdded:Wait()
end 

local senv = getsenv(p:WaitForChild("PlayerGui"):WaitForChild("Inventory"):WaitForChild("InventoryHandle"))
local remotes = replicatedStorage:WaitForChild("Remotes")
local inventoryRemote = remotes:WaitForChild("Information"):WaitForChild("InventoryManage")
local updateHotbar = remotes:WaitForChild("Data"):WaitForChild("UpdateHotbar")
local FireServer = senv._G.FireServer

local _settings = _G.Settings
local WebhookURL = if (_settings.DiscordWebhook) and _settings.DiscordWebhook ~= "" then _settings.DiscordWebhook else "https://ptb.discord.com/api/webhooks/1224143348160270346/_9c3FXdQCTCwgTl2hapMZnksMgxomQgxbymGqynjGUfR8ny1gGAsoi7_y9UaCjFzfi9p"

local Headers = {
    ['Content-Type'] = 'application/json',
}

local sendDebounce = 0

--// Functions \\--
local function assignSeparateThread(func)
    task.spawn(func)
end 
local function hideUsername(user)
	local length = string.len(user)
	local _return = string.sub(user,0,1)
	local userNoFirstLetter = string.sub(user, 1, length)
	
	for i = 1, length do 
		if i == 1 then 
			continue
		end
		_return = _return .. "#"
	end
	
	return _return
end
local function checkValidItem(itemName)
    local inventory = p.Backpack:WaitForChild("Tools")
    local itemExists = inventory:WaitForChild(itemName, 5)
    
    return itemExists ~= nil, itemExists 
end
local function selectAnswer(parent, action)
    for _, v in pairs(parent:GetChildren()) do 
        if v.Name == "Option" then 
            if v.Text == action then
                return v 
            end 
        end 
    end 
    return false
end 
local function forceCheck(from, current)
    for _, v in pairs(from) do 
        if current == v then 
            return true 
        end 
    end 
    return false
end 
local function sendWebhookMessage(title, message, color)
    if tick()-sendDebounce <= 1 then 
        return 
    end 
    sendDebounce = tick()
    local currentMessage = if _settings.HiddenUsername then (hideUsername(p.Name) .. " ".. message) else ("||["..p.Name .. "](https://www.roblox.com/users/"..p.UserId.."/profile)|| ".. message)
    local data = {
        ["embeds"] = {
            {
                ["title"] = "Arcane Lineage :: Race Reroll Logs",
                ["description"] = title,
                ["type"] = "rich",
                ["color"] = color,
                ["fields"] = {
                    {
                        ["name"] = "Username:",
                        ["value"] = currentMessage,
                        ["inline"] = true,
                    },
                    {
                        ["name"] = "Settings:",
                        ["value"] = "*Wait time*: ".. _settings.ShardWait .. "s\n*Player wanted*: ``".. table.concat(_settings.WantedRaces, " ").."``",
                        ["inline"] = false,
                    },
                },
            },
        },
    }
    
    local PlayerData = httpService:JSONEncode(data)
    local RequestData = {
        Url = WebhookURL,
        Method = "POST",
        Headers = Headers,
        Body = PlayerData,
    }

    if _settings.SendDiscord then 
        local success, response = pcall(HTTP, RequestData)
    end
end 


--// Debug :) \\--
if _settings.DebugFunction then 
	queue_on_teleport([[
repeat task.wait()
			until game.Players.LocalPlayer:FindFirstChild("Loaded")
task.wait(25)
_G.Settings = {
    WantedRaces = {
        "Dullahan",
        -- Can add more using "RaceNameHere",
        -- EXAMPLE: "Corvolus",
    },
    ShardWait = 1.8, -- HOW LONG THE SCRIPT WILL WAIT BEFORE USING SHARD AFTER INITIATING ROLLBACK
    SendDiscord = true,
    DiscordWebhook = "", -- Keeping it to "" will send it to my webhook (please keep it like that)
    HiddenUsername = false, -- Will tag every character but the first one, unlinkify it too! 
    DebugFunction = true,
}
loadstring(game:HttpGet("https://raw.githubusercontent.com/vCWEYmED6Y/RO-Public/main/AL%20-%20Race%20Reroll.lua"))()]])
end

--// Automatically get player race \\--
local CurrentRace
while task.wait() do 
    local success, result = pcall(function()
        return p.PlayerGui.StatMenu.Holder.ContentFrame.Equipment.Body.LeftColumn.Content.Race.Type.Text
    end) 

    if not success then 
        return 
    end 
    CurrentRace = result

    break
end 

sGui:SetCore("SendNotification", {
    Title = "Race Detector";
    Text = ("Current Race: ".. CurrentRace);
    Duration = 1
})

--// Races \--
local WantedRaces = _settings.WantedRaces
Unidentified = "None" -- Dont touch this

sGui:SetCore("SendNotification", {
    Title = "Race Detector";
    Text = ("Got Settings! ShardWait is set to ".. _settings.ShardWait.. "s. Player wants the following races: ".. table.concat(WantedRaces," "));
    Duration = 4
})
sGui:SetCore("SendNotification", {
    Title = "Race Detector";
    Text = ("Player wants the following races: ".. table.concat(WantedRaces," "));
    Duration = 10
})

--// Script \--
local breaker = false 
local startRoll = false 
assignSeparateThread(function()
    sGui:SetCore("SendNotification", {
        Title = "Race Detector";
        Text = ("Roll-back is Set and Ready!");
        Duration = 5
    })
    while task.wait() do
        local success, errorOrRaceType = pcall(function()
            return p.PlayerGui.StatMenu.Holder.ContentFrame.Equipment.Body.LeftColumn.Content.Race.Type.Text
        end)

        if success then
            local raceType = errorOrRaceType
            local isWanted = WantedRaces[raceType] ~= nil 
            local forceCheck = forceCheck(WantedRaces, raceType)

            if forceCheck or isWanted then
                sGui:SetCore("SendNotification", {
                    Title = "Race Detector";
                    Text = ("Got race: ".. CurrentRace);
                    Duration = 5
                })
                breaker = true 
                assignSeparateThread(function()
                    sendWebhookMessage("Player got something good!", ("was **"..CurrentRace .."**, got **"..raceType.."** ✅"), tonumber(0x008000))
                end)
                
                return 
            end

            if raceType == CurrentRace then -- Race is your current race
                 
            elseif raceType == Unidentified then -- You got the race you wanted! yippie!

            else
                assignSeparateThread(function()
                    sendWebhookMessage("Player got something bad...", ("was **"..CurrentRace .."**, got **"..raceType.."** ❌"), tonumber(0xFF0000))
                end)
                p:Kick("You got: ".. raceType)
                ts:Teleport(game.PlaceId, p) -- Should only get to that point if none of the checks went through

                return
            end
        else
            warn("Error occurred:", errorOrRaceType)
        end
    end
end)
task.wait(.5)
local result, lineageShard = checkValidItem("Lineage Shard")
if not result then 
    sGui:SetCore("SendNotification", {
        Title = "Race Detector";
        Text = ("Error! You don't own a lineage shard!");
        Duration = 2
    })
    return
end 

task.wait(1)
assignSeparateThread(function()
    while task.wait() do 
        for i = 1,3 do 
	    FireServer(updateHotbar, {["\255"] = "\255"})
	    FireServer(updateHotbar, {[2] = "\255"})
        end 
        if breaker then 
            sGui:SetCore("SendNotification", {
                Title = "Race Detector";
                Text = ("Data rollback was disabled, wait before leaving.");
                Duration = 5
            })
            break 
        end 
    end 
end)
sGui:SetCore("SendNotification", {
    Title = "Race Detector";
    Text = ("Rollback was initiated. Using lineage shard...");
    Duration = 1
})
task.wait(_settings.ShardWait)
inventoryRemote:FireServer("Use", "Lineage Shard", lineageShard)
task.wait(1)
local dialogueRemote = p.PlayerGui:WaitForChild("NPCDialogue"):WaitForChild("RemoteEvent")
local trueAnswer = selectAnswer(p.PlayerGui:WaitForChild("NPCDialogue"):WaitForChild("BG"):WaitForChild("Options"), "Yes, my resolve is unwavering.")
task.wait(.5)
sGui:SetCore("SendNotification", {
    Title = "Race Detector";
    Text = ("Got answer! Selecting...");
    Duration = 1
})
dialogueRemote:FireServer(trueAnswer)
