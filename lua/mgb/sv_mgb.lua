----------------- Metrostroi Global Bans -----------------
-- Автор: Alexell
-- Лицензия: MIT
-- Сайт: https://alexell.ru/
-- Steam: https://steamcommunity.com/id/alexell
-- Repo: https://github.com/Alexell/metrostroi_global_bans
----------------------------------------------------------
-- иконки GMod: http://www.famfamfam.com/lab/icons/silk/previews/index_abc.png

util.AddNetworkString("MGB.MainMenu")
util.AddNetworkString("MGB.Peports")
util.AddNetworkString("MGB.AddReport")
util.AddNetworkString("MGB.AddVote")
MGB.BadPlayers = {}
MGB.WaitPlayers = {}
MGB.BannedPlayers = {}
MGB.NeedBadNotice = false
MGB.NeedWaitNotice = false

net.Receive("MGB.Peports",function(ln,ply)
	local sid = net.ReadString()
	local nick = net.ReadString()
	local params = {act="getreports",host=GetHostName(),ip=game.GetIPAddress(),sid=sid}
	http.Post("https://api.alexell.ru/metrostroi/mgb/",params,function(body,len,headers,code)
		local tab = {}
		if (code ~= 200 or body == "") then
			print("[MGB] Web request failed! Please try later.")
			tab = {result="Ошибка запроса к API! Попробуйте повторить позже."}
		end
		if body == "Server blocked" then
			tab = {result="Доступ к репортам для "..GetHostName().." заблокирован!\nОбратитесь к разработчику аддона."}
		elseif body == "Not found" then
			tab = {result="Репортов не найдено!"}
		else
			tab = util.JSONToTable(body)
		end
		net.Start("MGB.Peports")
			net.WriteTable(tab)
			net.WriteString(nick)
		net.Send(ply)
	end)
end)

net.Receive("MGB.AddReport",function(ln,ply)
	local sid = net.ReadString()
	local nick = net.ReadString()
	local report = net.ReadString()
	local admin = ply:SteamID()
	local params = {act="addreport",host=GetHostName(),ip=game.GetIPAddress(),nick=nick,sid=sid,note=report,admin=admin}
	http.Post("https://api.alexell.ru/metrostroi/mgb/",params,function(body,len,headers,code)
		local result = ""
		if (code ~= 200 or body == "") then
			print("[MGB] Web request failed! Please try later.")
			result = "Ошибка запроса к API! Попробуйте повторить позже."
		end
		if body == "Server blocked" then
			result = "Доступ к репортам для "..GetHostName().." заблокирован!\nОбратитесь к разработчику аддона."
		elseif body == "Report added" then
			result = "Репорт успешно отправлен!"
		elseif body == "Repeat report" then
			result = "С сервера "..GetHostName().." уже отправляли репорт на этого игрока!"
		end
		net.Start("MGB.AddReport")
			net.WriteString(result)
		net.Send(ply)
	end)
end)

net.Receive("MGB.AddVote",function(ln,ply)
	local sid = net.ReadString()
	local vote = net.ReadString()
	local admin = ply:SteamID()
	local params = {act="addvote",host=GetHostName(),ip=game.GetIPAddress(),sid=sid,vote=vote,admin=admin}
	http.Post("https://api.alexell.ru/metrostroi/mgb/",params,function(body,len,headers,code)
		local result = ""
		if (code ~= 200 or body == "") then
			print("[MGB] Web request failed! Please try later.")
			result = "Ошибка запроса к API! Попробуйте повторить позже."
		end
		if body == "Server blocked" then
			result = "Доступ к голосованиям для "..GetHostName().." заблокирован!\nОбратитесь к разработчику аддона."
		elseif body == "Vote added" then
			result = "Ваш голос учтен!"
		elseif body == "Repeat vote" then
			result = "С сервера "..GetHostName().." уже голосовали за этого игрока!"
		end
		net.Start("MGB.AddVote")
			net.WriteString(result)
		net.Send(ply)
	end)
end)

local function GetBadPlayers()
	local params = {act="getbad",host=GetHostName(),ip=game.GetIPAddress()}
	http.Post("https://api.alexell.ru/metrostroi/mgb/",params,function(body,len,headers,code)
		local tab = {}
		if code ~= 200 then
			print("[MGB] Web request failed! Code: "..code)
			return
		end
		if (body == "" or body == "Not found") then return end
		if (body == "" or body == "Not found") then return end
		MGB.BadPlayers = util.JSONToTable(body)
	end)
end

local function GetWaitPlayers()
	local params = {act="getwait",host=GetHostName(),ip=game.GetIPAddress()}
	http.Post("https://api.alexell.ru/metrostroi/mgb/",params,function(body,len,headers,code)
		if code ~= 200 then
			print("[MGB] Web request failed! Code: "..code)
			return
		end
		if (body == "" or body == "Not found") then return end
		MGB.WaitPlayers = util.JSONToTable(body)
	end)
end

local function GetBannedPlayers()
	local params = {act="getban",host=GetHostName(),ip=game.GetIPAddress()}
	http.Post("https://api.alexell.ru/metrostroi/mgb/",params,function(body,len,headers,code)
		if code ~= 200 then
			print("[MGB] Web request failed! Code: "..code)
			return
		end
		if (body == "" or body == "Not found") then return end
		MGB.BannedPlayers = util.JSONToTable(body)
	end)
end

local function GetAPIData(updater)
	-- получаем последние загруженные списки
	local BadPlayers = MGB.BadPlayers
	local WaitPlayers = MGB.WaitPlayers
	local BannedPlayers = MGB.BannedPlayers
	
	-- получаем списки через API
	GetBadPlayers()
	GetWaitPlayers()
	GetBannedPlayers()
	
	if updater then
		-- проверяем необходимость оповестить админов
		timer.Create("MGB.Notifier",3,1,function()
			if MGB.NeedBadNotice == false then
				for k,v in pairs(MGB.BadPlayers) do
					local finded = false
					for k2,v2 in pairs(BadPlayers) do
						if v.sid == v2.sid then finded = true end
					end
					if finded == false then
						MGB.NeedBadNotice = true
						break
					end
				end
			end
			if MGB.NeedWaitNotice == false then
				for k,v in pairs(MGB.WaitPlayers) do
					local finded = false
					for k2,v2 in pairs(WaitPlayers) do
						if v.sid == v2.sid then finded = true end
					end
					if finded == false then
						MGB.NeedWaitNotice = true
						break
					end
				end
			end
		end)
	end
end

timer.Create("MGB.Init",1,1,function() GetAPIData(false) end)
timer.Create("MGB.Updater",300,0,function() GetAPIData(true) end)

hook.Add("PlayerButtonDown","MGB.ShowMenu",function(ply,key)
	if (key == KEY_F6 and ply:IsAdmin()) then
		GetAPIData(true)
		net.Start("MGB.MainMenu")
			net.WriteTable(MGB.BadPlayers)
			net.WriteTable(MGB.WaitPlayers)
			net.WriteTable(MGB.BannedPlayers)
		net.Send(ply)
	end
end)

-- оповещаем админов по двум спискам
hook.Add("PlayerInitialSpawn", "MGB.AdminNotice",function(ply)
	if ply:IsAdmin() then
		if MGB.NeedBadNotice == true then
			ply:ChatPrint("Появились новые игроки с репортами.\nПроверьте Metrostroi Global Bans!")
			MGB.NeedBadNotice = false
		end
		if MGB.NeedWaitNotice == true then
			ply:ChatPrint("Появились новые игроки в голосовании за бан.\nПроверьте Metrostroi Global Bans!")
			MGB.NeedWaitNotice = false
		end
	end
end)