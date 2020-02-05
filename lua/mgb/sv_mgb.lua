----------------- Metrostroi Global Bans -----------------
-- Автор: Alexell
-- Лицензия: MIT
-- Сайт: https://alexell.ru/
-- Steam: https://steamcommunity.com/id/alexell
-- Repo: https://github.com/Alexell/metrostroi_global_bans
----------------------------------------------------------
-- иконки GMod: http://www.famfamfam.com/lab/icons/silk/previews/index_abc.png

CreateConVar("mgb_events", 1, {FCVAR_ARCHIVE})
gameevent.Listen("player_connect")
util.AddNetworkString("MGB.MainMenu")
util.AddNetworkString("MGB.Reports")
util.AddNetworkString("MGB.AddReport")
util.AddNetworkString("MGB.AddVote")
util.AddNetworkString("MGB.Events")
util.AddNetworkString("MGB.Notice")
MGB.BadPlayers = {}
MGB.WaitPlayers = {}
MGB.BannedPlayers = {}
MGB.NeedBadNotice = false
MGB.NeedWaitNotice = false
MGB.LastEvent = {}

net.Receive("MGB.Reports",function(ln,ply)
	local sid = net.ReadString()
	local nick = net.ReadString()
	local params = {act="getreports",host=GetHostName(),ip=game.GetIPAddress(),sid=sid}
	http.Post("https://api.alexell.ru/metrostroi/mgb/",params,function(body,len,headers,code)
		local tab = {}
		if (code ~= 200 or body == "") then
			print("[MGB] Web request failed! Please try later.")
			tab = {result="MGB.Messages.WebRequestFailed"}
		end
		if body:find("Server blocked") then
			tab = {result="MGB.Messages.Serverblocked"}
		elseif body:find("Not found") then
			tab = {result="MGB.Messages.NoReports"}
		else
			tab = util.JSONToTable(body)
		end
		net.Start("MGB.Reports")
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
			result = "MGB.Messages.WebRequestFailed"
		end
		if body:find("Server blocked") then
			result = "MGB.Messages.Serverblocked"
		elseif body:find("Report added") then
			result = "MGB.Messages.ReportAdded"
		elseif body:find("Report rejected") then
			result = "MGB.Messages.ReportRejected"
		elseif body:find("Repeat report") then
			result = "MGB.Messages.ReportRepeat"
		elseif body:find("Invalid SteamID") then
			result = "MGB.Messages.InvalidSID"
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
			result = "MGB.Messages.WebRequestFailed"
		end
		if body:find("Server blocked") then
			result = "MGB.Messages.Serverblocked"
		elseif body:find("Vote added") then
			result = "MGB.Messages.VoteAdded"
		elseif body:find("Repeat vote") then
			result = "MGB.Messages.VoteRepeat"
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
		if (body == "" or body:find("Not found")) then return end
		if (body == "" or body:find("Not found")) then return end
		MGB.BadPlayers = util.JSONToTable(body) or {}
	end)
end

local function GetWaitPlayers()
	local params = {act="getwait",host=GetHostName(),ip=game.GetIPAddress()}
	http.Post("https://api.alexell.ru/metrostroi/mgb/",params,function(body,len,headers,code)
		if code ~= 200 then
			print("[MGB] Web request failed! Code: "..code)
			return
		end
		if (body == "" or body:find("Not found")) then return end
		MGB.WaitPlayers = util.JSONToTable(body) or {}
	end)
end

local function GetBannedPlayers()
	local params = {act="getban",host=GetHostName(),ip=game.GetIPAddress()}
	http.Post("https://api.alexell.ru/metrostroi/mgb/",params,function(body,len,headers,code)
		if code ~= 200 then
			print("[MGB] Web request failed! Code: "..code)
			return
		end
		if (body == "" or body:find("Not found")) then return end
		MGB.BannedPlayers = util.JSONToTable(body) or {}
	end)
end

local function GetEvents()
	if GetConVarNumber("mgb_events") == 1 then
		local params = {act="getevents",host=GetHostName(),ip=game.GetIPAddress()}
		http.Post("https://api.alexell.ru/metrostroi/mgb/",params,function(body,len,headers,code)
			if code ~= 200 then
				print("[MGB] Web request failed! Code: "..code)
				return
			end
			if (body == "" or body:find("Not found")) then return end
			if body ~= MGB.LastEvent then
				MGB.LastEvent = body
				net.Start("MGB.Events")
					net.WriteTable(util.JSONToTable(body))
				net.Broadcast()
			end
		end)
	end
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

local function PlayerBanned(sid)
	for k,v in pairs(MGB.BannedPlayers) do
		if sid == v.sid then return true end
	end
	return false
end

hook.Add("player_connect","MGB.Ban",function(data)
	if PlayerBanned(data.networkid) then
		game.KickID(data.networkid,"[MGB] You are banned on Metrostroi servers")
		return
	end
end)

timer.Create("MGB.Init",1,1,function() GetAPIData(false) end)
timer.Create("MGB.Updater",300,0,function() GetAPIData(true) GetEvents() end)

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
			net.Start("MGB.Notice")
				net.WriteString("MGB.Messages.NoticeBad")
			net.Send(ply)
			MGB.NeedBadNotice = false
		end
		if MGB.NeedWaitNotice == true then
			net.Start("MGB.Notice")
				net.WriteString("MGB.Messages.NoticeWait")
			net.Send(ply)
			MGB.NeedWaitNotice = false
		end
	end
end)