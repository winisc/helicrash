-----------------------------------------------------------------------------------------------------------------------------------------
-- VRP
-----------------------------------------------------------------------------------------------------------------------------------------
local Tunnel = module("lib/Tunnel")
-----------------------------------------------------------------------------------------------------------------------------------------
-- CONNECTION
-----------------------------------------------------------------------------------------------------------------------------------------
cRP = {}
Tunnel.bindInterface("helicrash",cRP)
vSERVER = Tunnel.getInterface("helicrash")
-----------------------------------------------------------------------------------------------------------------------------------------
-- VARIABLES
-----------------------------------------------------------------------------------------------------------------------------------------
local Blip = nil
local BlipRadius = nil
local Objects = {}
local Active = false
local FxAsset = "scr_indep_fireworks"

-----------------------------------------------------------------------------------------------------------------------------------------
-- SYSTEM
-----------------------------------------------------------------------------------------------------------------------------------------
CreateThread(function()
	while true do
		if Active and Components[Active] then
			local Ped = PlayerPedId()
			local Crashed = Components[Active]
			local Coords = GetEntityCoords(Ped)
			local Distance = #(Coords - Crashed["1"][1])

			if Distance <= 250 then
				for Number,v in pairs(Crashed) do
					if not Objects[Number] and LoadModel(v[3]) then
						Objects[Number] = CreateObjectNoOffset(v[3],v[1],false,false,false)
						PlaceObjectOnGroundProperly(Objects[Number])
						FreezeEntityPosition(Objects[Number],true)
						SetEntityLodDist(Objects[Number],0xFFFF)
						SetEntityHeading(Objects[Number],v[2])

						if Number ~= "1" then
							exports["target"]:AddBoxZone("Helicrash:"..Number,v[1],1.25,2.0,{
								name = "Helicrash:"..Number,
								heading = v[2],
								minZ = v[1]["z"] - 1.00,
								maxZ = v[1]["z"] + 0.25
							},{
								distance = 1.75,
								options = {
									{
										event = "helicrash:coletar",
										label = "Coletar",
										tunnel = "server"
									}
								}
							})
						end
					end
				end
			else
				if Objects["1"] then
					for Number,v in pairs(Objects) do
						DeleteEntity(Objects[Number])
						Objects[Number] = nil
					end
				end
			end
		end

		Wait(1000)
	end
end)

function LoadModel(Hash)
	if IsModelInCdimage(Hash) and IsModelValid(Hash) then
		RequestModel(Hash)
		while not HasModelLoaded(Hash) do
			RequestModel(Hash)
			Wait(1)
		end

		return true
	end

	return false
end
-----------------------------------------------------------------------------------------------------------------------------------------
-- ADDSTATEBAGCHANGEHANDLER
-----------------------------------------------------------------------------------------------------------------------------------------
AddStateBagChangeHandler("Helicrash",nil,function(Name,Key,Value)
	if DoesBlipExist(Blip) and DoesBlipExist(BlipRadius) then
		RemoveBlip(Blip)
		RemoveBlip(BlipRadius)
	end

	Active = Value

	if not Value then
		if Objects["1"] then
			for Number,_ in pairs(Objects) do
				if Number ~= "1" then
					exports["target"]:RemCircleZone("Helicrash:"..Number)

					if DoesEntityExist(Objects[Number]) then
						DeleteEntity(Objects[Number])
					end

					Objects[Number] = nil
				end
			end
		end
	else
		HeliBlip(Active)

		if Objects["1"] then
			for Number,v in pairs(Objects) do
				exports["target"]:RemCircleZone("Helicrash:"..Number)

				if DoesEntityExist(Objects[Number]) then
					DeleteEntity(Objects[Number])
				end

				Objects[Number] = nil
			end
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- GLOBALSTATE
-----------------------------------------------------------------------------------------------------------------------------------------
RegisterNetEvent("onClientResourceStart")
AddEventHandler("onClientResourceStart",function(Resource)
	if (GetCurrentResourceName() ~= Resource) then
		return
	end

	if GlobalState["Helicrash"] then
		Active = GlobalState["Helicrash"]
		HeliBlip(Active)
	end

	if GlobalState["Firework"] then
		for i = 1,#Locations,1 do
			TriggerEvent("firework:"..Locations[i]["Type"],Locations[i]["Coords"])
		end
	end
end)
-----------------------------------------------------------------------------------------------------------------------------------------
-- HELIBLIP
-----------------------------------------------------------------------------------------------------------------------------------------
function HeliBlip(Number)
	if Components[Number] then
		Blip = AddBlipForCoord(Components[Number]["1"][1],Components[Number]["1"][2],Components[Number]["1"][3])
		SetBlipSprite(Blip,64)
		SetBlipDisplay(Blip,4)
		SetBlipAsShortRange(Blip,true)
		SetBlipColour(Blip,2)
		SetBlipScale(Blip,0.8)
		BeginTextCommandSetBlipName("STRING")
		AddTextComponentString("Helicóptero Caído")
		EndTextCommandSetBlipName(Blip)

		BlipRadius = AddBlipForRadius(Components[Number]["1"][1],Components[Number]["1"][2],Components[Number]["1"][3],150.0)
		SetBlipColour(BlipRadius,63)
		SetBlipAlpha(BlipRadius,80)
	end
end

function cRP.CollectHelicrash(timerPull)
	if not vSERVER.getActiveOpen() then
		StartScreenEffect("MP_Celeb_Lose",0,true)
		SetTimeout(5000,function()
			StopScreenEffect("MP_Celeb_Lose")
		end)
				SetEntityHealth(PlayerPedId(),GetEntityHealth(PlayerPedId())-2)
		return false
	end

    LocalPlayer["state"]["NoTarget"] = true
	TriggerEvent('snt/animations/stop')
    TriggerEvent('snt/animations/play', { dict = "amb@prop_human_parking_meter@female@idle_a", anim = "idle_a_female", walk = false, loop = true })
    TriggerEvent('snt/animations/setBlocked', true)
    TriggerEvent('player:disabledInventory', true)
    exports["lb-phone"]:ToggleOpen(false, false)
    exports["lb-phone"]:ToggleDisabled(true)
    FreezeEntityPosition(PlayerPedId(), true)
    LocalPlayer["state"]["Acao"] = true
    TriggerEvent('Progress', timerPull, 'Coletando.')

    local startTime = GetGameTimer()
    local endTime = startTime + (timerPull * 1000)
	local cancelCollect = false
	local Crashed = Components[Active]

    while GetGameTimer() < endTime do
        Citizen.Wait(0)
		DrawText3D(Crashed["2"][1][1],Crashed["2"][1][2],Crashed["2"][1][3] + 0.5, "~w~PRESSIONE~w~ ~g~[F7]~w~ ~w~PARA CANCELAR~w~")
		if IsControlJustPressed(0, 168) then
			cancelCollect = true
		end

        if GetEntityHealth(PlayerPedId()) <= 101 or cancelCollect then
			TriggerEvent("cancelProgress")
            LocalPlayer["state"]["NoTarget"] = false
            LocalPlayer["state"]["Acao"] = false
            FreezeEntityPosition(PlayerPedId(), false)
            TriggerEvent('snt/animations/setBlocked', false)
            TriggerEvent('player:disabledInventory', false)
            exports["lb-phone"]:ToggleDisabled(false)
            TriggerEvent('snt/animations/stop')
			cancelCollect = false
            return false
        end
    end

    LocalPlayer["state"]["NoTarget"] = false
    LocalPlayer["state"]["Acao"] = false
    FreezeEntityPosition(PlayerPedId(), false)
    TriggerEvent('snt/animations/setBlocked', false)
    TriggerEvent('player:disabledInventory', false)
    exports["lb-phone"]:ToggleDisabled(false)
    TriggerEvent('snt/animations/stop')
	vSERVER.setActiveOpen(false)
    return true
end

RegisterNetEvent("firework:Battery")
AddEventHandler("firework:Battery",function(coords)
	local Coords = coords
    RequestNamedPtfxAsset(FxAsset)
    while not HasNamedPtfxAssetLoaded(FxAsset) do
        Wait(1)
	end
	
		UseParticleFxAsset(FxAsset)
		SetParticleFxNonLoopedColour(math.random(),math.random(),math.random())
		StartNetworkedParticleFxNonLoopedAtCoord("scr_indep_firework_trailburst",Coords,0.0,0.0,0.0,math.random() * 0.5 + 1.8,false,false,false,false)
		Wait(1500)
		UseParticleFxAsset(FxAsset)
		SetParticleFxNonLoopedColour(math.random(),math.random(),math.random())
		StartNetworkedParticleFxNonLoopedAtCoord("scr_indep_firework_trailburst",Coords,0.0,0.0,0.0,math.random() * 0.5 + 1.8,false,false,false,false)
		Wait(1500)
		UseParticleFxAsset(FxAsset)
		SetParticleFxNonLoopedColour(math.random(),math.random(),math.random())
		StartNetworkedParticleFxNonLoopedAtCoord("scr_indep_firework_trailburst",Coords,0.0,0.0,0.0,math.random() * 0.5 + 1.8,false,false,false,false)
		Wait(1500)
		UseParticleFxAsset(FxAsset)
		SetParticleFxNonLoopedColour(math.random(),math.random(),math.random())
		StartNetworkedParticleFxNonLoopedAtCoord("scr_indep_firework_trailburst",Coords,0.0,0.0,0.0,math.random() * 0.5 + 1.8,false,false,false,false)
		Wait(1500)
		UseParticleFxAsset(FxAsset)
		SetParticleFxNonLoopedColour(math.random(),math.random(),math.random())
		StartNetworkedParticleFxNonLoopedAtCoord("scr_indep_firework_trailburst",Coords,0.0,0.0,0.0,math.random() * 0.5 + 1.8,false,false,false,false)
		Wait(1500)
		UseParticleFxAsset(FxAsset)
		SetParticleFxNonLoopedColour(math.random(),math.random(),math.random())
		StartNetworkedParticleFxNonLoopedAtCoord("scr_indep_firework_trailburst",Coords,0.0,0.0,0.0,math.random() * 0.5 + 1.8,false,false,false,false)
		Wait(1500)
		UseParticleFxAsset(FxAsset)
		SetParticleFxNonLoopedColour(math.random(),math.random(),math.random())
		StartNetworkedParticleFxNonLoopedAtCoord("scr_indep_firework_trailburst",Coords,0.0,0.0,0.0,math.random() * 0.5 + 1.8,false,false,false,false)
		Wait(1500)
		UseParticleFxAsset(FxAsset)
		SetParticleFxNonLoopedColour(math.random(),math.random(),math.random())
		StartNetworkedParticleFxNonLoopedAtCoord("scr_indep_firework_trailburst",Coords,0.0,0.0,0.0,math.random() * 0.5 + 1.8,false,false,false,false)
		Wait(4000)
		UseParticleFxAsset(FxAsset)
		SetParticleFxNonLoopedColour(math.random(),math.random(),math.random())
		StartNetworkedParticleFxNonLoopedAtCoord("scr_indep_firework_trailburst",Coords,0.0,0.0,0.0,math.random() * 0.5 + 2.8,false,false,false,false)
		Wait(1500)
end)

-----------------------------------------------------------------------------------------------------------------------------------------
--DRAW TEXT
-----------------------------------------------------------------------------------------------------------------------------------------
function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())

    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)

    end
end