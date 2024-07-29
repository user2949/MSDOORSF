game:GetService("ReplicatedStorage"):WaitForChild("RemotesFolder"):WaitForChild("CreateElevator"):FireServer({
  	["FriendsOnly"] = false,
  	["Destination"] = "Hotel",
  	["Mods"] = {
  	    "RetroMode"
  	},
  	["MaxPlayers"] = "1"
})
