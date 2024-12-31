-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Proxy = module("vrp","lib/Proxy")
local Tunnel = module("lib/Tunnel")
vRP = Proxy.getInterface("vRP")
vRPclient = Tunnel.getInterface("vRP")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
cRP = {}
Tunnel.bindInterface("helicrash",cRP)
vCLIENT = Tunnel.getInterface("helicrash")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Boxes = 0
local Cooldown = os.time()

local timerStarted = false
local timerDuration = TimerOpen
local timerEndTime = 0
local activeOpen = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- GLOBALSTATE
-----------------------------------------------------------------------------------------------------------------------------------------
GlobalState["Helicrash"] = false
GlobalState["HelicrashCooldown"] = os.time()
GlobalState["Firework"] = false
-----------------------------------------------------------------------------------------------------------------------------------------
-- WEBHOOK
-----------------------------------------------------------------------------------------------------------------------------------------
local webhookhelicrash = webhook

function SendWebhookMessage(webhook,message)
	if webhook ~= nil and webhook ~= "" then
		PerformHttpRequest(webhook, function(err, text, headers) end, 'POST', json.encode({content = message}), { ['Content-Type'] = 'application/json' })
	end
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- SYSTEM
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do 
		if Timers[os.date("%H:%M")] and os.time() >= Cooldown then
			Boxes = 0
			local Selected = math.random(#Components)
			-- for Number,v in pairs(Components[Selected]) do
			-- 	if Number ~= "1" then
			-- 		Boxes = Boxes + 1

			-- 		local Loot = math.random(#Loots)
			-- 		vRP.remSrvdata("stackChest:Helicrash-"..Number,false)
			-- 		vRP.setSrvdata("stackChest:Helicrash-"..Number,Loots[Loot],false)
			-- 	end
			-- end

			TriggerEvent("zone_control:DeleteZoneAirDrops")
			TriggerEvent("zone_control:CreateZoneAirDropSelected", Components[Selected]["3"])
			StartHelicrashTimer(timerDuration)
			TriggerClientEvent("Notify",-1,"important","<b>Helicóptero Caindo!</b><br>Aviso de emergência, estamos em queda livre.",60000)
			TriggerClientEvent("Notify",-1,"aviso","O suprimento que estava dentro do helicóptero poderá ser aberto em <b>5 minutos</b>.",60000)
			GlobalState["Helicrash"] = Selected
			GlobalState["HelicrashCooldown"] = os.time() + 600
			Cooldown = os.time() + 3000
		end

		if Backup[os.date("%M")] and os.time() >= Cooldown then
			TriggerEvent("SaveServer",false)
			Cooldown = os.time() + 60
		end

		Wait(1000)
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- BOX
-----------------------------------------------------------------------------------------------------------------------------------------
exports("Box",function()
	if GlobalState["Helicrash"] then
		Boxes = Boxes - 1
		if Boxes <= 0 then
			GlobalState["Helicrash"] = false
			Boxes = 0
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HELICRASH
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterCommand("helicrash",function(source,Message)
	local getUserId = vRP.getUserId(source)
	if getUserId then
		if vRP.hasGroup(getUserId,"Admin") then
			Timers[os.date("%H:%M")] = true
		end
	end
end)

RegisterServerEvent("helicrash:coletar")
AddEventHandler("helicrash:coletar",function(resource)
	local source = source
	local user_id = vRP.getUserId(source)
	local nearestPlayers = vRPclient.nearestPlayer(source, 4)

	if not nearestPlayers then
		local identity = vRP.userIdentity(user_id)
		if identity then
			local collected = vCLIENT.CollectHelicrash(source,TimerCollect)
			if collected then
				receveidItens(source)
				TriggerClientEvent("Notify",-1,"normal","<b>"..identity["name"].." "..identity["name2"].."</b> Coletou o helicrash com sucesso.",30000)
				if GlobalState["Helicrash"] then
					GlobalState["Helicrash"] = false
				end
				Wait(2000)
				TriggerEvent("zone_control:DeleteZoneAirDrops")
			end
		end
	else
		TriggerClientEvent("Notify",source,"aviso","<b>Negado!</b><br>Existem outros jogadores por perto.",3000)
	end
end)

function receveidItens(source)
	local user_id = vRP.getUserId(source)
	local itensWebhook = {}
	local notspacebag = false
	if user_id then
		for _, item in pairs(Loots) do

			local itemRandomMath = 0

			if item.item == "ticket_blindado_24" then
				local chanceitem = math.random(0, 100)
				if chanceitem <= ChanceBlindado then
					itemRandomMath = 1
				else
					itemRandomMath = 0
				end
			else
				itemRandomMath = math.random(0, item.amountMax)
			end

			if vRP.giveInventoryItem(user_id, item.item, itemRandomMath, true) then
				table.insert(itensWebhook, item.item.." x"..itemRandomMath)
			else
				if itemRandomMath ~= 0 then
					notspacebag = true
				end
			end
		end
		if notspacebag then
			TriggerClientEvent("Notify", source,"negado", "Sem espaço na mochila para receber todos os itens!", 6000)
		end
		SendWebhookMessage(webhookhelicrash,"```prolog\n[ID]: "..user_id.." \n[RESGATOU]: "..table.concat(itensWebhook, ", ").."\n"..os.date("\n[Data]: %d/%m/%Y [Hora]: %H:%M:%S").." \r```")
		itensWebhook = {}
	end
end

function StartHelicrashTimer(duration)
    timerEndTime = GetGameTimer() + (duration * 1000)
    timerStarted = true
    activeOpen = false
end

function UpdateHelicrashTimer()
    if timerStarted then
        local currentTime = GetGameTimer()
        if currentTime >= timerEndTime then
            timerStarted = false
            activeOpen = true
        end
    end
end

cRP.getActiveOpen = function()
	if activeOpen then
		return true
	else
		local timerOpen = math.floor((timerEndTime - GetGameTimer()) / 60000)
		if timerOpen <= 0 then
			timerOpen = math.floor((timerEndTime - GetGameTimer()) / 1000)
			if timerOpen <= 0 then
				timerOpen = 0
			end
			TriggerClientEvent("Notify", source, "negado", "Ainda está muito quente.<br><small>Aguarde <b>"..timerOpen.." segundos</b> para o resfriamento do helicrash.</small>",5000)
			return false
		end
		TriggerClientEvent("Notify", source, "negado", "Ainda está muito quente.<br><small>Aguarde <b>"..(timerOpen + 1).." minuto(s)</b> para o resfriamento do helicrash.</small>",5000)
		return false
	end
end

cRP.setActiveOpen = function(status)
	activeOpen = status
end

CreateThread(function()
    while true do
        UpdateHelicrashTimer()
        Wait(1000)
    end
end)



RegisterCommand("fogos",function(source,Message)
	local user_id = vRP.getUserId(source)
	if not vRP.hasGroup(user_id,"Admin") then
		TriggerClientEvent("Notify",source,"negado","Você não tem permissão para usar este comando.",5000)
		return
	end

	if not Message[1] then
		TriggerClientEvent("Notify",source,"negado","Você precisa especificar o <b>ID</b> do jogador.",5000)
	else
		local otherPlayer = vRP.userSource(Message[1])
		if otherPlayer ~= nil then
			local ped = GetPlayerPed(otherPlayer)
			local coords = GetEntityCoords(ped)
			TriggerClientEvent("firework:Battery",-1,coords)
			TriggerClientEvent("Notify",source,"check","Fogos soltados no player <b>"..Message[1].."</b> com sucesso.",5000)
		else
			TriggerClientEvent("Notify",source,"negado","Player não encontrado.",5000)
		end
	end
end)