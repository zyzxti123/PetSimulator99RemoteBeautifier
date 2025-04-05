local functions = {
    ["getsenv"] = getsenv,
    ["hookfunction"] = hookfunction,
    ["getupvalue"] = debug.getupvalue or getupvalue,
}

for key: string, value: (...any) -> (...any) in pairs(functions) do
    if not value then
        return game.Players.LocalPlayer:Kick(`[Z-Ware]: Unsupported Exploit: {key}`)
    end
end

local network = getsenv(game.ReplicatedStorage.Library.Client.Network)

local remoteReversedNamesHashedStorage = {{}, {}, {}}
local remoteHashedNamesStorage  = debug.getupvalue(network._getName, 1)
for remoteType, remoteStorage in next, remoteHashedNamesStorage do
    for remoteName: string, remoteHashedName: string in next, remoteStorage do
        remoteReversedNamesHashedStorage[remoteType][remoteHashedName] = remoteName
		remoteHashedNamesStorage[remoteType][remoteName] = remoteName
		remoteHashedNamesStorage[remoteType][remoteHashedName] = nil
    end
end

local remotesInstanceStorage = debug.getupvalue(network._remote, 1)
for remoteType: number, remoteStorage: {[number]: {[string]: RemoteFunction | RemoteEvent | UnreliableRemoteEvent}} in next, remotesInstanceStorage do
    for remoteHashedName: string, remoteInstance: RemoteFunction | RemoteEvent in next, remoteStorage do
		local remoteName = remoteReversedNamesHashedStorage[remoteType][remoteHashedName]
		if remoteName then
			remotesInstanceStorage[remoteType][remoteHashedName].Name = remoteName
			remotesInstanceStorage[remoteType][remoteName] = remotesInstanceStorage[remoteType][remoteHashedName]
			remotesInstanceStorage[remoteType][remoteHashedName] = nil
            
			warn(`[Z-Ware]: Dehashed: {remoteHashedName} → {remoteName}`)
		else
			 warn(`[Z-Ware]: Failed To Dehash: {remoteHashedName}!`)
		end
    end
end

local _orginalGetName; _orginalGetName = hookfunction(network._getName, function(remoteType: number, remoteName: string): string
    return remoteName
end)

local _orginalRemote; _orginalRemote = hookfunction(network._remote, function(remoteType: number, remoteName: string): (RemoteFunction | RemoteEvent | UnreliableRemoteEvent)
	local remoteHashedName = _orginalGetName(remoteType, remoteName)
	local remoteInstanceStorage = remotesInstanceStorage[remoteType]
	local remoteInstance = remoteInstanceStorage[remoteHashedName] or remoteInstanceStorage[remoteName]
	
    if not remoteInstance then
        remoteInstance = game.ReplicatedStorage:FindFirstChild(remoteHashedName)

        if not remoteInstance then
            return nil
        end

        remoteInstance.Name = remoteName
        remoteInstanceStorage[remoteName] = remoteInstance
        debug.getupvalue(_orginalRemote, 3)(remoteName, remoteInstance) --// remote handler or smthing

        warn(`[Z-Ware]: Dehashed In Real-Time: {remoteHashedName} → {remoteName}`)
    elseif remoteInstance.Name ~= remoteName then
        remoteInstance.Name = remoteName
        remoteInstanceStorage[remoteName] = remoteInstance

        warn(`[Z-Ware]: Dehashed In Real-Time: {remoteHashedName} → {remoteName}`)
    end

    return remoteInstance
end)
