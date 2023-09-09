local vehiclesCars = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 17, 18, 19, 20}

local cruise = false
local seatbeltEjectSpeed = 45.0
local seatbeltEjectAccel = 100.0
local seatbeltIsOn = false
local currSpeed = 0.0
local prevVelocity = { x = 0.0, y = 0.0, z = 0.0 }

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local player = PlayerPedId()
        if IsPedInAnyVehicle(player, false) then
            local vehicle = GetVehiclePedIsIn(player, false)
            local vehicleSpeedSource = GetEntitySpeed(vehicle)
            local vehicleSpeed = vehicleSpeedSource * 3.6 -- Convertir a kilómetros por hora
            local vehicleClass = GetVehicleClass(vehicle)
            local rpm = GetVehicleCurrentRpm(vehicle)
            local speed = GetEntitySpeed(vehicle)
            local isEngineRunning = GetIsVehicleEngineRunning(vehicle)

            SendNUIMessage({
                type = "vehicleStatus",
                isInsideVehicle = true
            })

            SendNUIMessage({
                type = "rpm",
                value = rpm
            })
            SendNUIMessage({
                type = "speed",
                value = speed
            })
            if isEngineRunning then
                SendNUIMessage({
                    type = "statusengine",
                    value = true
                })
            else
                SendNUIMessage({
                    type = "statusengine",
                    value = false
                })
            end

            -- cinturon
            if has_value(vehiclesCars, vehicleClass) and vehicleClass ~= 8 then
                local prevSpeed = currSpeed
                currSpeed = vehicleSpeedSource

                SetPedConfigFlag(player, 32, true)

                if not seatbeltIsOn then
                    local vehIsMovingFwd = GetEntitySpeedVector(vehicle, true).y > 1.0
                    local vehAcc = (prevSpeed - currSpeed) / GetFrameTime()
                    if vehIsMovingFwd and prevSpeed > (seatbeltEjectSpeed / 2.237) and vehAcc > (seatbeltEjectAccel * 9.81) then
                        local position = GetEntityCoords(player)
                        SetEntityCoords(player, position.x, position.y, position.z - 0.47, true, true, true)
                        SetEntityVelocity(player, prevVelocity.x, prevVelocity.y, prevVelocity.z)
                        SetPedToRagdoll(player, 1000, 1000, 0, 0, 0, 0)
                    else
                        prevVelocity = GetEntityVelocity(vehicle)
                    end
                else
                    DisableControlAction(0, 75)
                end
            end

            if IsPedInAnyVehicle(player, false) and isEngineRunning then
              if IsControlJustReleased(0, 311) and has_value(vehiclesCars, vehicleClass) and vehicleClass ~= 8 then
                  seatbeltIsOn = not seatbeltIsOn
                  SendNUIMessage({
                      type = "seatbelt",
                      value = seatbeltIsOn
                  })
              end
          end

            -- crucero
            if IsControlJustPressed(1, 246) then
                if cruise == false then
                    cruise = true
                    local currentSpeed = GetEntitySpeed(GetVehiclePedIsIn(player, false))
                    SetVehicleMaxSpeed(GetVehiclePedIsIn(player, false), currentSpeed)
                    SendNUIMessage({
                        type = "maxSpeed",
                        value = currentSpeed
                    })
                elseif cruise == true then
                    cruise = false
                    SetVehicleMaxSpeed(GetVehiclePedIsIn(player, false), 0.0)
                    SendNUIMessage({
                        type = "maxSpeed",
                        value = 0.0
                    })
                end
            end

            -- sirenas

            local vehicleSiren

            if IsVehicleSirenOn(vehicle) then
              vehicleSiren = true
              SendNUIMessage({
                type = "vehicleSiren",
                value = true
            })
            else
              vehicleSiren = false
              SendNUIMessage({
                type = "vehicleSiren",
                value = false
            })
            end

            -- transmision

            local vehicleGear = GetVehicleCurrentGear(vehicle)

            if (vehicleSpeed == 0 and vehicleGear == 0) or (vehicleSpeed == 0 and vehicleGear == 1) then
                vehicleGear = 'N'
            elseif vehicleSpeed > 0 and vehicleGear == 0 then
                vehicleGear = 'R'
            end

            SendNUIMessage({
                type = "vehicleGear",
                value = vehicleGear
            })

            -- Luces

            local vehicleVal, vehicleLights, vehicleHighlights = GetVehicleLightsState(vehicle)
            local vehicleIsLightsOn

            if vehicleLights == 1 and vehicleHighlights == 0 then
              vehicleIsLightsOn = 'normal'
            elseif (vehicleLights == 1 and vehicleHighlights == 1) or (vehicleLights == 0 and vehicleHighlights == 1) then
              vehicleIsLightsOn = 'high'
            else
              vehicleIsLightsOn = 'off'
            end
            

            SendNUIMessage({
              type = "light",
              value = vehicleIsLightsOn
            })

            -- gasofa 

            local vehicleFuel
			      vehicleFuel = GetVehicleFuelLevel(vehicle)

            SendNUIMessage({
              type = "fuel",
              value = vehicleFuel
            })

        else
            SendNUIMessage({
                type = "vehicleStatus",
                isInsideVehicle = false
            })
        end
    end
end)

function has_value(tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end
    return false
end
