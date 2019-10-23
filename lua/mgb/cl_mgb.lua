----------------- Metrostroi Global Bans -----------------
-- Автор: Alexell
-- Лицензия: MIT
-- Сайт: https://alexell.ru/
-- Steam: https://steamcommunity.com/id/alexell
-- Repo: https://github.com/Alexell/metrostroi_global_bans
----------------------------------------------------------
local function T(str,...)
	return string.format(Metrostroi.GetPhrase(str),...)
end

local function GetReports(sid,nick)
	net.Start("MGB.Reports")
		net.WriteString(sid)
		net.WriteString(nick)
	net.SendToServer()
end

local function SendReport(sid,nick,report)
	net.Start("MGB.AddReport")
		net.WriteString(sid)
		net.WriteString(nick)
		net.WriteString(report)
	net.SendToServer()
end

local function SendVote(sid,vote)
	net.Start("MGB.AddVote")
		net.WriteString(sid)
		net.WriteString(vote)
	net.SendToServer()
end

local function AddReport(sid,nick)
	local frame = vgui.Create("DFrame")
	frame:SetTitle(T("MGB.GUI.AddReport.Title").." "..nick)
	frame:SetIcon("icon16/error_add.png")
	frame:SetSize(385,185)
	frame:Center()
	frame:MakePopup()

	local rules = vgui.Create("DLabel",frame)
	rules:SetPos(10,30)
	rules:SetText(T("MGB.GUI.AddReport.Rules"))
	rules:SizeToContents()
	
	local report = vgui.Create("DTextEntry",frame)
	report:SetPos(10,100)
	report:SetSize(365,45)
	report:SetMultiline(true)
	report:SetUpdateOnType(true)

	local head = vgui.Create("DLabel",frame)
	local posx,posy = report:GetPos()
	head:SetPos(10,posy-15)
	head:SetText(T("MGB.GUI.AddReport.Headline")..":")
	head:SizeToContents()
	local maxtext = ""
	report.OnValueChange = function(self,str)
		local awail = 150-#(str:gsub('[\128-\191]',''))
		if awail == 0 then
			maxtext = str
			report:SetText(maxtext)
		elseif awail < 0 then
			report:SetText(maxtext)
			return
		end
		head:SetText(T("MGB.GUI.AddReport.Headline")..": "..T("MGB.GUI.AddReport.Textleft").." "..awail.." "..T("MGB.GUI.AddReport.Characters"))
		head:SizeToContents()
	end
	
	local send = vgui.Create("DButton",frame)
	send:SetSize(70,22)
	send:SetPos((frame:GetWide()/2)-(send:GetWide()/2),(frame:GetTall()-send:GetTall()-10))
	send:SetText(T("MGB.GUI.AddReport.Send"))
	
	send.DoClick = function()
		if (report:GetText() == "") then
			Derma_Message(T("MGB.GUI.AddReport.TextEmpty").."!",T("MGB.GUI.AddReport.Title").." "..nick,"OK")
			return
		end
		SendReport(sid,nick,report:GetText())
		frame:Close()
	end
end

local function ShowPeports(reports,nick)
	if reports.result then
		Derma_Message(T(reports.result,GetHostName()),T("MGB.GUI.Reports.Title").." "..nick,"OK")
	else
		local frame = vgui.Create("DFrame")
		frame:SetTitle(T("MGB.GUI.Reports.Title").." "..nick)
		frame:SetIcon("icon16/error.png")
		local w = 400
		local h = 295
		-- перфекционизм
		if #reports == 1 then h = 120 end
		if #reports == 2 then h = 210 end
		if #reports > 3 then w = 415 end -- смещение на скролл-бар
		
		frame:SetSize(w,h)
		frame:Center()
		frame:MakePopup()

		local scroll = vgui.Create("DScrollPanel",frame)
		scroll:Dock(FILL)
		
		for k,v in pairs(reports) do
			local panel = scroll:Add("DPanel")
			panel:SetBackgroundColor(Color(255,255,150))
			panel:Dock(TOP)
			panel:DockMargin(3,3,3,5 )
			panel:SetSize(400,80)
			local label = vgui.Create("DLabel",panel)
			label:SetPos(10,5)
			label:SetText(T("MGB.GUI.Reports.Server")..": "..v.server.." | "..T("MGB.GUI.Reports.Date")..": "..v.date)
			label:SizeToContents()
			label:SetDark(1)
			local note = vgui.Create("DTextEntry",panel)
			note:SetPos(10,25)
			note:SetSize(365,45)
			note:SetText(v.note)
			note:SetMultiline(true)
			note.AllowInput = function() -- блокировка от изменения
				return true
			end
		end
	end
end

local function ShowMainMenu(bads,waits,bans)
	
	-- ФОРМИРОВАНИЕ ИНТЕРФЕЙСА --
	
	-- основной фрейм
	local frame = vgui.Create("DFrame")
	frame:SetSize(600,300)
	frame:Center()
	frame:SetTitle("Metrostroi Global Bans [MGB]")
	frame:SetVisible(true)
	frame:SetIcon("icon16/shield.png")
	frame:MakePopup()
	
	-- вкладки
	local tab = vgui.Create("DPropertySheet",frame)
	tab:SetSize(frame:GetWide(),frame:GetTall())
	tab:Dock(FILL)

	local players = vgui.Create("DPanel",tab)
	players:SetSize(tab:GetWide(),tab:GetTall())
	tab:AddSheet(T("MGB.GUI.Tabs.Online.Title"),players,"icon16/group.png",false,false)

	local bad_players = vgui.Create( "DPanel", tab )
	bad_players:SetSize(tab:GetWide(),tab:GetTall())
	tab:AddSheet(T("MGB.GUI.Tabs.Bad.Title"),bad_players,"icon16/group_error.png",false,false)
	
	local wait_players = vgui.Create( "DPanel", tab )
	wait_players:SetSize(tab:GetWide(),tab:GetTall())
	tab:AddSheet(T("MGB.GUI.Tabs.Wait.Title"),wait_players,"icon16/chart_bar.png",false,false)
	
	local banned_players = vgui.Create( "DPanel", tab )
	banned_players:SetSize(tab:GetWide(),tab:GetTall())
	tab:AddSheet(T("MGB.GUI.Tabs.Ban.Title"),banned_players,"icon16/exclamation.png",false,false)
	
	tab.OnRemove = function()
		MGB.BadList = nil
		MGB.WaitList = nil
		MGB.BanList = nil
	end
	
	-- игроки онлайн
	local player_list = vgui.Create("DListView",players)
	player_list:SetMultiSelect(false)
	player_list:AddColumn(T("MGB.Labels.Nick"))
	player_list:AddColumn(T("MGB.Labels.Group"))
	player_list:AddColumn("SteamID")
	player_list:SetSize(players:GetWide()-26,players:GetTall())
	player_list:SetPos(0,0)
	
		-- меню
		player_list.OnRowRightClick = function( lst, id, row )
			if IsValid(menu) then menu:Remove() end
			row:SetSelected(true)
			local menu = DermaMenu()

			menu:AddOption(T("MGB.Labels.ReportList"), function()
				GetReports(row:GetValue(3),row:GetValue(1))
			end):SetIcon("icon16/error.png")

			menu:AddOption(T("MGB.GUI.Tabs.Online.SendReport"), function()
				AddReport(row:GetValue(3),row:GetValue(1))
			end):SetIcon("icon16/error_add.png")
			
			menu:AddOption(T("MGB.Labels.Copy").." SteamID", function()
				SetClipboardText(row:GetValue(3))
			end):SetIcon("icon16/page_copy.png")
			
			menu.OnRemove = function()
				if IsValid(row) then
					row:SetSelected(false)
				end
			end
			menu:Open()
		end
	
	-- имеющие репорты
	MGB.BadList = vgui.Create("DListView",bad_players)
	MGB.BadList:SetMultiSelect(false)
	MGB.BadList:AddColumn(T("MGB.Labels.Nick"))
	MGB.BadList:AddColumn("SteamID")
	MGB.BadList:AddColumn(T("MGB.Labels.Reports"))
	MGB.BadList:SetSize(bad_players:GetWide()-26,bad_players:GetTall())
	MGB.BadList:SetPos(0,0)
	
		-- меню
		MGB.BadList.OnRowRightClick = function( lst, id, row )
			if IsValid(menu) then menu:Remove() end
			row:SetSelected(true)
			local menu = DermaMenu()

			menu:AddOption(T("MGB.Labels.ReportList"), function()
				GetReports(row:GetValue(2),row:GetValue(1))
			end):SetIcon("icon16/error.png")
			
			menu:AddOption(T("MGB.Labels.Copy").." SteamID", function()
				SetClipboardText(row:GetValue(3))
			end):SetIcon("icon16/page_copy.png")
			
			menu.OnRemove = function()
				if IsValid(row) then
					row:SetSelected(false)
				end
			end
			menu:Open()
		end
	
	-- голосование за бан
	MGB.WaitList = vgui.Create("DListView",wait_players)
	MGB.WaitList:SetMultiSelect(false)
	MGB.WaitList:AddColumn(T("MGB.Labels.Nick"))
	MGB.WaitList:AddColumn("SteamID")
	MGB.WaitList:AddColumn(T("MGB.Labels.Reports"))
	MGB.WaitList:AddColumn(T("MGB.GUI.Tabs.Wait.Yes"))
	MGB.WaitList:AddColumn(T("MGB.GUI.Tabs.Wait.No"))
	MGB.WaitList:SetSize(wait_players:GetWide()-26,wait_players:GetTall())
	MGB.WaitList:SetPos(0,0)
	
		-- меню
		MGB.WaitList.OnRowRightClick = function( lst, id, row )
			if IsValid(menu) then menu:Remove() end
			row:SetSelected(true)
			local menu = DermaMenu()

			menu:AddOption(T("MGB.GUI.Tabs.Wait.VoteYes"), function()
				SendVote(row:GetValue(2),"1")
			end):SetIcon("icon16/tick.png")
			
			menu:AddOption(T("MGB.GUI.Tabs.Wait.VoteNo"), function()
				SendVote(row:GetValue(2),"0")
			end):SetIcon("icon16/cross.png")
			
			menu:AddOption(T("MGB.Labels.Copy").." SteamID", function()
				SetClipboardText(row:GetValue(2))
			end):SetIcon("icon16/page_copy.png")
			
			menu.OnRemove = function()
				if IsValid(row) then
					row:SetSelected(false)
				end
			end
			menu:Open()
		end
	
	-- глобальные баны
	MGB.BanList = vgui.Create("DListView",banned_players)
	MGB.BanList:SetMultiSelect(false)
	MGB.BanList:AddColumn(T("MGB.Labels.Nick"))
	MGB.BanList:AddColumn("SteamID")
	MGB.BanList:AddColumn(T("MGB.GUI.Tabs.Ban.Date"))
	MGB.BanList:SetSize(banned_players:GetWide()-26,banned_players:GetTall())
	MGB.BanList:SetPos(0,0)
	
		-- меню
		MGB.BanList.OnRowRightClick = function( lst, id, row )
			if IsValid(menu) then menu:Remove() end
			row:SetSelected(true)
			local menu = DermaMenu()
			
			menu:AddOption(T("MGB.Labels.ReportList"), function()
				GetReports(row:GetValue(2),row:GetValue(1))
			end):SetIcon("icon16/error.png")
			menu:AddOption(T("MGB.Labels.Copy").." SteamID", function()
				SetClipboardText(row:GetValue(3))
			end):SetIcon("icon16/page_copy.png")
			
			menu.OnRemove = function()
				if IsValid(row) then
					row:SetSelected(false)
				end
			end
			menu:Open()
		end
	
	------------------------
	
	-- ЗАПОЛНЕНИЕ СПИСКОВ --
	
	-- игроки онлайн
	local online = player.GetAll()
	for _,ply in pairs(online) do
		player_list:AddLine(ply:Nick(),ply:GetUserGroup(),ply:SteamID())
	end
	
	-- игроки с репортами
	for k,v in pairs(bads) do
		MGB.BadList:AddLine(v.nick,v.sid,v.reps)
	end
	
	-- игроки на голосовании
	for k,v in pairs(waits) do
		MGB.WaitList:AddLine(v.nick,v.sid,v.reps,v.votesY,v.votesN)
	end
	
	-- забаненные игроки
	for k,v in pairs(bans) do
		MGB.BanList:AddLine(v.nick,v.sid,v.date)
	end
end

net.Receive("MGB.MainMenu",function(ln,ply)
	ShowMainMenu(net.ReadTable(),net.ReadTable(),net.ReadTable())
end)

net.Receive("MGB.Reports",function(ln,ply)
	ShowPeports(net.ReadTable(),net.ReadString())
end)

net.Receive("MGB.AddReport",function(ln,ply)
	local result = net.ReadString()
	Derma_Message(T(result,GetHostName()),T("MGB.GUI.AddReport.Title"),"OK")
end)

net.Receive("MGB.AddVote",function(ln,ply)
	local result = net.ReadString()
	Derma_Message(T(result,GetHostName()),T("MGB.GUI.Tabs.Wait.Vote"),"OK")
end)

net.Receive("MGB.Events",function()
	local tab = net.ReadTable()
	for k,v in pairs(tab) do
		if v.type == "report" then
			chat.AddText(Color(0,148,255),"[MGB] ",Color(255,255,255),T("MGB.Labels.Player").." ",Color(0,255,0),v.nick.." ("..v.sid..") ",Color(255,255,255),T("MGB.Messages.EventReport").." ",Color(0,255,0),v.server)
			chat.AddText(Color(0,148,255),T("MGB.Labels.Report")": ",Color(255,255,255),v.report)
		elseif v.type == "ban" then
			chat.AddText(Color(0,148,255),"[MGB] ",Color(255,255,255),T("MGB.Labels.Player").." ",Color(0,255,0),v.nick.." ("..v.sid..") ",Color(255,255,255),T("MGB.Messages.EventBan")..".")
		end
	end
end)
net.Receive("MGB.Notice",function()
	local message = net.ReadString()
	chat.AddText(Color(0,148,255),"[MGB] ",Color(255,255,255),T(message).."!")
end)
