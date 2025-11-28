local currentPlaceId = game.PlaceId
queue_on_teleport('loadstring(game:HttpGet("https://raw.githubusercontent.com/TomtomFH/Pressure/refs/heads/main/loader.lua",true))()')
local validPlaceIds = {
    12552538292,
    17355897213,
    124505452456262,
    121188829551651
}

if currentPlaceId == 12411473842 then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/TomtomFH/Pressure/refs/heads/main/mainLobby.lua",true))()
else
    for _, id in ipairs(validPlaceIds) do
        if currentPlaceId == id then
            loadstring(game:HttpGet("https://raw.githubusercontent.com/TomtomFH/Pressure/refs/heads/main/main.lua",true))()
            break
        end
    end
end
