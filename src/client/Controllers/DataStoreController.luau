-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PlayerService = game:GetService("Players")

-- Modules
local ReplicaController = require(ReplicatedStorage.ReplicaController)

local DataStoreController = {}

function DataStoreController:Init()
	print(`{script.Name} Init!`)

	self._replicas = {}

	ReplicaController.ReplicaOfClassCreated("PlayerProfile", function(Replica)
		self._replicas[Replica.Tags.Player] = Replica
	end)

	ReplicaController.RequestData()

	PlayerService.PlayerRemoving:Connect(function(player: Player)
		if self._replicas[player] then
			self._replicas[player] = nil
		end
	end)
end

return DataStoreController
