game:GetService("ReplicatedStorage"):WaitForChild("RemotesFolder"):WaitForChild("CreateElevator"):FireServer({
	["FriendsOnly"] = false,
	["Destination"] = "Hotel",
	["Mods"] = {
	    "SuperHardMode"
	},
	["MaxPlayers"] = "1"
})
