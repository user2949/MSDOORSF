return function(_, CanEntityKill)
    require(game.ReplicatedStorage.ClientModules.EntityModules.Shade).stuff(require(game.Players.LocalPlayer.PlayerGui.MainUI.Initiator.Main_Game), workspace.CurrentRooms[tostring(game.ReplicatedStorage.GameData.LatestRoom.Value)])    
    if CanEntityKill then
        local con
        con=game:GetService("ReplicatedStorage").ClientModules.EntityModules.Shade.SoundHurt.Played:Connect(function(sId)
            game.Players.LocalPlayer.Character.Humanoid.Health-=60
            game:GetService("ReplicatedStorage").GameStats["Player_" .. game.Players.LocalPlayer.Name].Total.DeathCause.Value = "Halt"
            debug.setupvalue(getconnections(game.ReplicatedStorage.EntityInfo.DeathHint.OnClientEvent)[1].Function, 1, {
                "You died to Halt again...",
                "As you run, it may appear in front of you at any time.",
                "When it does, turn around and keep running!",
                "This process will repeat multiple times."
            })
        end)
        local con2;con2=workspace.CurrentCamera.ChildRemoved:Connect(function(c)
            if c.Name=="Shade" then
                con:Disconnect()
                        con2:Disconnect()
            end
        end)
    end
    return workspace.CurrentCamera:WaitForChild("Shade")
end
