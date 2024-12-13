local QBCore = exports['qb-core']:GetCoreObject()
local attachedVehicle = nil
local trailerAttached = nil

-- Maximum distance between the player's vehicle and the trailer
local MAX_TRAILER_DISTANCE = 10.0 -- Adjust for how far the trailer can be detected

-- Command to open the tow menu
RegisterCommand("towmenu", function()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)

    if vehicle ~= 0 then
        -- Find the nearest trailer to the player's vehicle
        local trailerFound, trailer = FindNearestTrailer(vehicle)

        if trailerFound then
            local trailerCoords = GetEntityCoords(trailer)
            local vehicleCoords = GetEntityCoords(vehicle)
            local distance = #(trailerCoords - vehicleCoords)

            -- Check if the player's vehicle is within range of the trailer
            if distance <= MAX_TRAILER_DISTANCE then
                local trailerModel = GetEntityModel(trailer)
                print("[TowMenu] Detected Trailer Model: " .. trailerModel)
                QBCore.Functions.Notify("Detected Trailer Model: " .. trailerModel, "success")

                if IsTrailerAllowed(trailer) then
                    TriggerEvent('qb-menu:client:openMenu', {
                        {
                            header = "Tow Menu",
                            txt = "Attach or Detach your vehicle",
                            isMenuHeader = true
                        },
                        {
                            header = "Attach Vehicle",
                            txt = "Attach your vehicle to the trailer",
                            params = {
                                event = "towmenu:attachPlayerVehicle",
                                args = {
                                    trailer = trailer,
                                    vehicle = vehicle
                                }
                            }
                        },
                        {
                            header = "Detach Vehicle",
                            txt = "Detach your vehicle from the trailer",
                            params = {
                                event = "towmenu:detachVehicle",
                                args = {}
                            }
                        }
                    })
                else
                    QBCore.Functions.Notify("This trailer is not allowed!", "error")
                    print("[TowMenu] Trailer not allowed. Model: " .. trailerModel)
                end
            else
                QBCore.Functions.Notify("Your vehicle is too far from the trailer!", "error")
                print("[TowMenu] Player's vehicle is too far from the trailer. Distance: " .. distance)
            end
        else
            QBCore.Functions.Notify("No trailer detected near your vehicle!", "error")
            print("[TowMenu] No trailer detected near the player's vehicle.")
        end
    else
        QBCore.Functions.Notify("You need to be inside a vehicle to use this command!", "error")
        print("[TowMenu] Player is not inside a vehicle.")
    end
end)

-- Function to find the nearest trailer to the player's vehicle
function FindNearestTrailer(vehicle)
    local vehicleCoords = GetEntityCoords(vehicle)
    local closestTrailer = nil
    local closestDistance = MAX_TRAILER_DISTANCE

    for trailer in EnumerateVehicles() do
        if IsEntityAVehicle(trailer) and IsTrailerAllowed(trailer) then
            local trailerCoords = GetEntityCoords(trailer)
            local distance = #(vehicleCoords - trailerCoords)

            if distance < closestDistance then
                closestTrailer = trailer
                closestDistance = distance
            end
        end
    end

    return closestTrailer ~= nil, closestTrailer
end

-- Function to check if the trailer model is allowed
function IsTrailerAllowed(trailer)
    local trailerModel = GetEntityModel(trailer)
    for _, allowedModel in pairs(Config.AllowedTrailers) do
        if trailerModel == allowedModel then
            return true
        end
    end
    print("[TowMenu] Trailer model not in the allowed list: " .. trailerModel)
    return false
end

-- Event to attach the player's vehicle to the trailer
RegisterNetEvent('towmenu:attachPlayerVehicle', function(data)
    local trailer = data.trailer
    local vehicle = data.vehicle

    if not DoesEntityExist(vehicle) then
        QBCore.Functions.Notify("Your vehicle does not exist!", "error")
        print("[TowMenu] Player's vehicle does not exist.")
        return
    end

    if not DoesEntityExist(trailer) then
        QBCore.Functions.Notify("Trailer does not exist!", "error")
        print("[TowMenu] Trailer does not exist.")
        return
    end

    -- Ensure the entities are networked
    if not NetworkGetEntityIsNetworked(vehicle) then
        NetworkRegisterEntityAsNetworked(vehicle)
    end

    if not NetworkGetEntityIsNetworked(trailer) then
        NetworkRegisterEntityAsNetworked(trailer)
    end

    -- Disable collisions and physics for stability
    SetEntityCollision(vehicle, false, true)
    FreezeEntityPosition(vehicle, true)

    -- Attach the player's vehicle to the trailer
    attachedVehicle = vehicle
    trailerAttached = trailer

    AttachEntityToEntity(vehicle, trailer, 20, 0.0, -3.5, 1.0, 0.0, 0.0, 0.0, false, false, true, false, 20, true)

    QBCore.Functions.Notify("Your vehicle has been securely attached to the trailer!", "success")
    print("[TowMenu] Player's vehicle securely attached to the trailer.")
end)

-- Event to detach the attached vehicle from the trailer
RegisterNetEvent('towmenu:detachVehicle', function()
    if attachedVehicle ~= nil then
        -- Detach the attached vehicle and restore collisions
        DetachEntity(attachedVehicle, true, true)
        SetEntityCollision(attachedVehicle, true, true)
        FreezeEntityPosition(attachedVehicle, false)

        attachedVehicle = nil
        trailerAttached = nil

        QBCore.Functions.Notify("Your vehicle has been detached from the trailer!", "success")
        print("[TowMenu] Player's vehicle detached from the trailer.")
    else
        QBCore.Functions.Notify("No vehicle is currently attached to the trailer!", "error")
        print("[TowMenu] No vehicle is currently attached to the trailer.")
    end
end)

-- Vehicle enumerator to find nearby vehicles
function EnumerateVehicles()
    return coroutine.wrap(function()
        local handle, vehicle = FindFirstVehicle()
        local success
        repeat
            coroutine.yield(vehicle)
            success, vehicle = FindNextVehicle(handle)
        until not success
        EndFindVehicle(handle)
    end)
end
