-- Services
local PlayerService = game:GetService("Players")

-- Modules
local ReplicaService = require(script.Parent.ReplicaService)
local ProfileService = require(script.Parent.ProfileService)

-- Player data template
local PROFILE_TEMPLATE = {
	Level = 0,
	Coins = 0,
}

local PlayerProfileClassToken = ReplicaService.NewClassToken("PlayerProfile")

local GameProfileStore = ProfileService.GetProfileStore("PlayerData", PROFILE_TEMPLATE)

local DataStoreService = {}

function DataStoreService:OnPlayerAdded(player: Player)
	local profile = GameProfileStore:LoadProfileAsync("Player_" .. player.UserId, "ForceLoad")
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()
		profile:ListenToRelease(function()
			self._playerProfiles[player].Replica:Destroy()
			self._playerProfiles[player] = nil
			player:Kick()
		end)
		if player:IsDescendantOf(PlayerService) == true then
			local playerProfile = {
				Profile = profile,
				Replica = ReplicaService.NewReplica({
					ClassToken = PlayerProfileClassToken,
					Tags = { Player = player },
					Data = profile.Data,
					Replication = "All",
				}),
				_player = player,
			}
			self._playerProfiles[player] = playerProfile
		else
			profile:Release()
		end
	else
		player:Kick()
	end
end

function DataStoreService:Init()
	print(`{script.Name} Init!`)

	self._playerProfiles = {}

	-- Set up profile for all players currently in the server
	for _, player: Player in ipairs(PlayerService:GetPlayers()) do
		task.spawn(function()
			self:OnPlayerAdded(player)
		end)
	end

	-- Set up profile when a player joins
	PlayerService.PlayerAdded:Connect(function(player: Player)
		self:OnPlayerAdded(player)
	end)

	-- Release profile when a player leaves
	PlayerService.PlayerRemoving:Connect(function(player)
		local playerProfile = self._playerProfiles[player]
		if playerProfile ~= nil then
			playerProfile.Profile:Release()
		end
	end)
end

return DataStoreService
