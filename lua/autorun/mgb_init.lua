----------------- Metrostroi Global Bans -----------------
-- Автор: Alexell
-- Лицензия: MIT
-- Сайт: https://alexell.ru/
-- Steam: https://steamcommunity.com/id/alexell
-- Repo: https://github.com/Alexell/metrostroi_global_bans
----------------------------------------------------------
if game.SinglePlayer() then return end
if not Metrostroi or not Metrostroi.Version then MsgC(Color(255,0,0),"Metrostroi not found.\nMetrostroi Global Bans can not be loaded.\n") return end

MGB = MGB or {}
if SERVER then
	AddCSLuaFile("mgb/cl_mgb.lua")
	include("mgb/sv_mgb.lua")
else
	include("mgb/cl_mgb.lua")
end
