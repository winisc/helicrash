fx_version "bodacious"
author "Wini"
game "gta5"
lua54 "yes"

client_scripts {
	"@vrp/lib/vehicles.lua",
	"@PolyZone/client.lua",
	"@vrp/lib/utils.lua",
	"client-side/*"
}

server_scripts {
	"@vrp/lib/vehicles.lua",
	"@vrp/lib/itemlist.lua",
	"@vrp/lib/utils.lua",
	"server-side/*"
}

shared_scripts {
	"shared-side/*"
}