local maxPlayers = 4;

for _, elevator in pairs(workspace.Lobby.LobbyElevators:GetChildren()) do
    if elevator.Name:match("LobbyElevator") and elevator:GetAttribute("Max") == maxPlayers then
        game:GetService("ReplicatedStorage").RemotesFolder.ElevatorJoin:FireServer(elevator)
    end
end
