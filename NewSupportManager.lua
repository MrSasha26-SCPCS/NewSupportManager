local GameObject = CS.UnityEngine.GameObject
local Time = CS.UnityEngine.Time
local Vector2 = CS.UnityEngine.Vector2
local Vector3 = CS.UnityEngine.Vector3
local SceneManager = CS.UnityEngine.SceneManagement.SceneManager
local Player = CS.Player
local Resources = CS.UnityEngine.Resources
local Random = CS.UnityEngine.Random
local Config = CS.Config
local PlayerUtilities = CS.PlayerUtilities

local function tableLength(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

---@class NewSupportManager:CS.Akequ.Base.Room
NewSupportManager = {}

NewSupportManager.const_plug_update_time = 2

NewSupportManager.called = false
NewSupportManager.spawned = true
NewSupportManager.SH = false
NewSupportManager.mb_SH = false

NewSupportManager.MTF_tickets = 50
NewSupportManager.CI_tickets = 50
NewSupportManager.delta_time = nil
NewSupportManager.sec_float = 0
NewSupportManager.update_time = 0
NewSupportManager.max_SH = nil
NewSupportManager.delta_tickets = nil
NewSupportManager.min = 0
NewSupportManager.sec = 0
NewSupportManager.support_spawn = 1
NewSupportManager.round_started = 0
NewSupportManager.time_to_spawned = nil
NewSupportManager.group = "None"
NewSupportManager.scp_healths = {}

NewSupportManager.timertext_ = nil
NewSupportManager.timertext_text = nil

function NewSupportManager:Init()
    if self.main.netEvent.isServer then
        local f = io.open("Plugins/SerpentsHand.lua", "r")
        if f ~= nil then
            io.close(f)
            self.SH = true
        end
        GameObject.FindObjectOfType(typeof(CS.SupportManager)).enabled = false
        CS.HookManager.Add(self.main.netEvent.gameObject, "onSupportState", function(obj) 
            if obj[0] == false then
                self.support_spawn = 1
                self.main:SendToEveryone("GetSupportInfo", self.sec, self.MTF_tickets, self.CI_tickets, self.support_spawn)
            elseif obj[0] == true then
                self.support_spawn = 0
                self.main:SendToEveryone("GetSupportInfo", self.sec, self.MTF_tickets, self.CI_tickets, self.support_spawn)
            end
        end)
        CS.HookManager.Add(self.main.netEvent.gameObject, "onRoundStart", function(obj) self:RoundStarted() end)
    end
    if self.main.netEvent.isClient then
        self.main:SendToServer("SendSupportInfo")

        local base_ = GameObject.Find("PlayerCanvas")
        self.timertext_ = GameObject("SupportTimerText")
        self.timertext_.transform:SetParent(base_.transform, false)
        self.timertext_.transform.localPosition = Vector3(0, 40, 0)
        local rt = self.timertext_:AddComponent(typeof(CS.UnityEngine.RectTransform))
        rt.anchorMin = Vector2(0.5, 0)
        rt.anchorMax = Vector2(0.5, 0)
        rt.pivot = Vector2(0.5, 0)
        rt.sizeDelta = Vector2(550, 30)
        self.timertext_text = self.timertext_:AddComponent(typeof(CS.UnityEngine.UI.Text))
        self.timertext_text.alignment = CS.UnityEngine.TextAnchor.MiddleCenter
        self.timertext_text.text = "Ожидание получения информации..."
        self.timertext_text.fontSize = 18
        self.timertext_text.font = CS.UnityEngine.Resources.GetBuiltinResource(typeof(CS.UnityEngine.Font), "Arial.ttf")

        local MTF_tickets_obj = GameObject("MTFTicketsText")
        MTF_tickets_obj.transform:SetParent(base_.transform, false)
        MTF_tickets_obj.transform.localPosition = Vector3(-50, 50, 0)
        MTF_rt = MTF_tickets_obj:AddComponent(typeof(CS.UnityEngine.RectTransform))
        MTF_rt.anchorMin = Vector2(0.5, 0)
        MTF_rt.anchorMax = Vector2(0.5, 0)
        MTF_rt.pivot = Vector2(0.5, 0)
        MTF_rt.sizeDelta = Vector2(250, 60)
        local MTF_text_ = MTF_tickets_obj:AddComponent(typeof(CS.UnityEngine.UI.Text))
        MTF_text_.alignment = CS.UnityEngine.TextAnchor.MiddleLeft
        MTF_text_.text = "Тикеты <color=blue>МОГ</color>:\n..."
        MTF_text_.fontSize = 18
        MTF_text_.font = Resources.GetBuiltinResource(typeof(CS.UnityEngine.Font), "Arial.ttf")

        local CI_tickets_obj = GameObject("CITicketsText")
        CI_tickets_obj.transform:SetParent(base_.transform, false)
        CI_tickets_obj.transform.localPosition = Vector3(50, 50, 0)
        local CI_rt = CI_tickets_obj:AddComponent(typeof(CS.UnityEngine.RectTransform))
        CI_rt.anchorMin = Vector2(0.5, 0)
        CI_rt.anchorMax = Vector2(0.5, 0)
        CI_rt.pivot = Vector2(0.5, 0)
        CI_rt.sizeDelta = Vector2(250, 60)
        local CI_text_ = CI_tickets_obj:AddComponent(typeof(CS.UnityEngine.UI.Text))
        CI_text_.alignment = CS.UnityEngine.TextAnchor.MiddleRight
        CI_text_.text = "Тикеты <color=green>ПХ</color>:\n..."
        CI_text_.fontSize = 18
        CI_text_.font = Resources.GetBuiltinResource(typeof(CS.UnityEngine.Font), "Arial.ttf")
    end
end

function NewSupportManager:RoundStarted()        
    self.round_started = 1

    local players = GameObject.FindObjectsOfType(typeof(Player))

    self.delta_time = 100 / players.Length
    if self.delta_time > 20 then
        self.delta_time = 20
    end
    self.delta_tickets = math.floor(players.Length / 2.2)
    self.sec = Random.Range(Config.GetInt("minimum_time_to_spawn", 240) + 30, Config.GetInt("maximum_time_to_spawn", 270) + 30)
    self.max_SH = 0
    
    CS.HookManager.Add(self.main.netEvent.gameObject, "onSupportSpawned", function(obj)
        self.mb_SH = true
        
        GameObject.FindObjectOfType(typeof(CS.SupportManager)).enabled = false

        local players = GameObject.FindObjectsOfType(typeof(Player))
        self.scp_healths = {}
        for i = 0, players.Length-1 do
            local p = players[i]
            if p ~= nil then
                if p.playerClass ~= nil and p.health ~= nil and p.maxHealth ~= nil then
                    if p.playerClass:GetType().Name:find("SCP") and p.playerClass:GetType().Name ~= "SCP0492" then                        
                        self.scp_healths[p] = p.health / p.maxHealth
                    end
                end
            end
        end

        self.sec = Random.Range(Config.GetInt("minimum_time_to_spawn", 240), Config.GetInt("maximum_time_to_spawn", 270))

        if obj[0] == "MTF" then
            self.CI_tickets = self.CI_tickets + self.delta_tickets
            self.MTF_tickets = self.MTF_tickets - self.delta_tickets
        else
            self.MTF_tickets = self.MTF_tickets + self.delta_tickets
            self.CI_tickets = self.CI_tickets - self.delta_tickets
        end
        if self.MTF_tickets < 0 then
            self.MTF_tickets = 0
            self.CI_tickets = 100
        end
        if self.CI_tickets < 0 then
            self.CI_tickets = 0
            self.MTF_tickets = 100
        end

        self.max_SH = players.Length / 2

        self.called = false
        self.spawned = true

        self.main:SendToEveryone("GetSupportInfo", self.sec, self.MTF_tickets, self.CI_tickets, self.support_spawn)
    end)
    CS.HookManager.Add(self.main.netEvent.gameObject, "onClassDEscape", function(obj)
        local ply = obj[0]
        if ply.canPickup then
            self.CI_tickets = self.CI_tickets + 1
            self.MTF_tickets = self.MTF_tickets - 1
        else
            self.MTF_tickets = self.MTF_tickets + 1
            self.CI_tickets = self.CI_tickets - 1
        end
        self.main:SendToEveryone("GetSupportInfo", self.sec, self.MTF_tickets, self.CI_tickets, self.support_spawn)
    end)
    CS.HookManager.Add(self.main.netEvent.gameObject, "onScientistEscape", function(obj)
        local ply = obj[0]
        if ply.canPickup then
            self.MTF_tickets = self.MTF_tickets + 1
            self.CI_tickets = self.CI_tickets - 1
        else
            self.CI_tickets = self.CI_tickets + 1
            self.MTF_tickets = self.MTF_tickets - 1
        end
        self.main:SendToEveryone("GetSupportInfo", self.sec, self.MTF_tickets, self.CI_tickets, self.support_spawn)
    end)
    CS.HookManager.Add(self.main.netEvent.gameObject, "onPlayerDeath", function(obj)
        if obj[0] ~= nil and obj[1] ~= nil then        
            local killer_team = nil
            local deathPly_team = nil
            local deathPly = obj[0]

            if obj[1].killer ~= nil then
                local killer = obj[1].killer
                if killer.playerClass ~= nil and deathPly.playerClass ~= nil then
                    if killer.maxHealth < 200 then
                        killer_team = killer.playerClass:GetTeamID()
                    else
                        killer_team = "SCP"
                    end
                    if deathPly.maxHealth < 200 then
                        deathPly_team = deathPly.playerClass:GetTeamID()
                    else 
                        deathPly_team = "SCP"
                    end
                    if killer_team ~= nil then
                        if killer_team == "SCP" then 
                            self.sec = self.sec + self.delta_time 
                        elseif killer_team == "MTF" then
                            if deathPly_team ~= killer_team then
                                print(deathPly.playerClass:GetName())
                                if deathPly_team == "SCP" and deathPly.playerClass:GetType().Name ~= "SCP0492" and deathPly.playerClass:GetName() ~= "Длань Змея" then
                                    self.MTF_tickets = self.MTF_tickets + 2
                                    self.CI_tickets = self.CI_tickets - 2
                                    self.mb_SH = false
                                else
                                    self.MTF_tickets = self.MTF_tickets + 1
                                    self.CI_tickets = self.CI_tickets - 1
                                end
                            end
                        elseif killer_team == "ClassD" then
                            if deathPly_team ~= killer_team then
                                if deathPly_team == "SCP" and deathPly.playerClass:GetType().Name ~= "SCP0492" and deathPly.playerClass:GetName() ~= "Длань Змея" then
                                    self.MTF_tickets = self.MTF_tickets - 2
                                    self.CI_tickets = self.CI_tickets + 2
                                else
                                    self.MTF_tickets = self.MTF_tickets - 1
                                    self.CI_tickets = self.CI_tickets + 1
                                end
                            end
                        end
                    end
                end                    
            end
        end
        self.main:SendToEveryone("GetSupportInfo", self.sec, self.MTF_tickets, self.CI_tickets, self.support_spawn)
    end)
    CS.HookManager.Add(self.main.netEvent.gameObject, "onPlayerTeleported", function(obj)
        local ply = obj[0]
        if ply ~= nil then                   
            ply_t = ply.transform
            ply_class = ply.playerClass
            if ply_t ~= nil and ply_class ~= nil then
                if ply_t.position.y >= 4000 and ply_class:GetType().Name ~= "Spectator" then
                    self.sec = self.sec + self.delta_time
                    self.main:SendToEveryone("GetSupportInfo", self.sec, self.MTF_tickets, self.CI_tickets, self.support_spawn)
                end
            end
        end
    end)
    CS.HookManager.Add(self.main.netEvent.gameObject, "onPlayerSetClass", function(obj)
        local ply = obj[0]
        local conn = ply.connectionToClient
        if ply.playerClass ~= nil then
            if ply.playerClass:GetType().Name == "Spectator" then
                self.main:SendToClient("Activate", conn)
            else
                self.main:SendToClient("Clear", conn)
            end
        end
    end)
    CS.HookManager.Add(self.main.netEvent.gameObject, "onSupportRequest", function(obj)
        if GameObject.FindObjectOfType(typeof(CS.SupportManager)).enabled == false then
            GameObject.FindObjectOfType(typeof(CS.SupportManager)).enabled = true
            CS.HookManager.Run("onSupportRequest", obj[0])
        else
            if obj[0] == "MTF" then
                self.main:SendToEveryone("MTFSupport")
                self.time_to_spawned = 20
                self.group = "MTF"
            else
                self.main:SendToEveryone("CISupport")
                self.time_to_spawned = 21
                self.group = "CI"
            end
            self.spawned = false
            self.called = true
        end
    end)
    CS.HookManager.Add(self.main.netEvent.gameObject, "onPlayerDisconnected", function(obj)
        local conn = obj[0]
        local ply = PlayerUtilities.GetServerPlayer(conn)
        if self.scp_healths[ply] ~= nil then
            self.scp_healths[ply] = nil
            self.mb_SH = false
        end
    end)
    self.main:SendToEveryone("GetSupportInfo", self.sec, self.MTF_tickets, self.CI_tickets, self.support_spawn)
end

function NewSupportManager:Update()
    if self.main.netEvent.isServer then
        if self.update_time <= 0 then
            self.update_time = self.const_plug_update_time
            self:PluginUpdate()
        else
            self.update_time = self.update_time - Time.deltaTime
        end
    end
    if self.main.netEvent.isClient then
        if self.round_started == 1 then
            if self.support_spawn == 1 then
                self.sec_float = self.sec_float - Time.deltaTime
                if self.sec_float < 0 then
                    self.min = self.min - 1
                    self.sec_float = self.sec_float + 60
                end
                if self.sec_float >= 60 then
                    self.min = self.min + 1
                    self.sec_float = self.sec_float - 60
                end
                if self.min >= 0 then
                    self.sec = math.floor(self.sec_float)
                    self.timertext_text.text = "До отряда " .. string.format("%02d:%02d", self.min, self.sec)
                end
            else
                self.timertext_text.text = "Спавн поддержки <color=red>заблокирован</color>"
            end
        end
    end
end

--SERVER

function NewSupportManager:PluginUpdate()
    if self.main.netEvent.isServer then 
        if self.round_started == 1 then
            if self.support_spawn == 1 then 
                if self.spawned == false then
                    self.time_to_spawned = self.time_to_spawned - self.const_plug_update_time
                    if self.time_to_spawned <= 0 then
                        CS.HookManager.Run("onSupportSpawned", self.group)
                    end
                end
                self.sec = self.sec - self.const_plug_update_time

                if self.sec <= 0 then                           
                    if self.called == false then
                        self.called = true                        
                        local SH_spawn = true
                        local players = GameObject.FindObjectsOfType(typeof(Player))

                        if self.SH and tableLength(self.scp_healths) > 0 and self.mb_SH then
                            for ply, value in pairs(self.scp_healths) do
                                print("VALUE: " .. value)
                                if ply ~= nil then
                                    print("Ply != nil")
                                    if ply.playerClass:GetType().Name:find("SCP") then
                                        if value - (ply.health / ply.maxHealth) >= 0.3 then                                                   
                                            SH_spawn = false
                                            break
                                        end
                                    else
                                        SH_spawn = false
                                        break
                                    end
                                else
                                    SH_spawn = false
                                    break
                                end
                            end                            
                        else
                            SH_spawn = false
                        end
                        if SH_spawn then
                            print("Trying to spawn SH")
                            for i = 0, players.Length-1 do
                                ply = players[i]
                                if ply ~= nil then
                                    if ply.playerClass ~= nil then
                                        if self.max_SH <= 0 then
                                            break
                                        end
                                        if ply.playerClass:GetType().Name == "Spectator" then
                                            self.max_SH = self.max_SH - 1
                                            ply:SetClass("SerpentsHand")
                                        end
                                    end
                                end
                            end
                            self.mb_SH = false
                            self.max_SH = math.floor(players.Length / 2)
                            self.sec = Random.Range(Config.GetInt("minimum_time_to_spawn", 240), Config.GetInt("maximum_time_to_spawn", 270)) / 2
                            self.main:SendToEveryone("GetSupportInfo", self.sec, self.MTF_tickets, self.CI_tickets, self.support_spawn)
                            self.called = false
                        else
                            print("Trying to spawn norm support")
                            
                            GameObject.FindObjectOfType(typeof(CS.SupportManager)).enabled = true

                            if self.MTF_tickets > self.CI_tickets then
                                CS.HookManager.Run("onSupportRequest", "MTF")
                                self.main:SendToEveryone("MTFSupport")
                                self.group = "MTF"
                            elseif self.MTF_tickets == self.CI_tickets then
                                local random = math.random(2)
                                if random == 1 then
                                    CS.HookManager.Run("onSupportRequest", "MTF")
                                    self.group = "MTF"
                                else
                                    CS.HookManager.Run("onSupportRequest", "CI")
                                    self.group = "CI"
                                end
                            else
                                CS.HookManager.Run("onSupportRequest", "CI")
                                self.group = "CI"
                            end
                        end
                    end
                end
            end
        end
    end
end

function NewSupportManager:SendSupportInfo(conn)
    if self.round_started == 1 then    
        self.main:SendToClient("GetSupportInfo", conn, self.sec, self.MTF_tickets, self.CI_tickets, self.support_spawn)
    else 
        self.main:SendToClient("Clear", conn) 
    end
end

--CLIENT

function NewSupportManager:MTFSupport()
    self.min = -1
    self.timertext_text.text = "Прибывает <color=blue>МОГ</color>"
end
function NewSupportManager:CISupport()
    self.min = -1
    self.timertext_text.text = "Прибывают <color=green>ПХ</color>"
end
function NewSupportManager:GetSupportInfo(sec_serv, tickets_MTF, tickets_CI, supportSpawn)
    self.round_started = 1
    self.sec_float = sec_serv
    self.min = 0
    self.CI_tickets = math.floor(tickets_CI)
    self.MTF_tickets = math.floor(tickets_MTF)
    self.support_spawn = supportSpawn

    local MTF_tickets_obj = GameObject.Find("MTFTicketsText")
    local MTF_text = MTF_tickets_obj:GetComponent(typeof(CS.UnityEngine.UI.Text))
    MTF_text.text = "Тикеты <color=blue>МОГ</color>:\n" .. self.MTF_tickets

    local CI_tickets_obj = GameObject.Find("CITicketsText")
    local CI_text = CI_tickets_obj:GetComponent(typeof(CS.UnityEngine.UI.Text))
    CI_text.text = "Тикеты <color=green>ПХ</color>:\n" .. self.CI_tickets
end
function NewSupportManager:Clear()
    local MTF_tickets_obj = GameObject.Find("MTFTicketsText")
    local MTF_text = MTF_tickets_obj:GetComponent(typeof(CS.UnityEngine.UI.Text))
    local CI_tickets_obj = GameObject.Find("CITicketsText")
    local CI_text = CI_tickets_obj:GetComponent(typeof(CS.UnityEngine.UI.Text))
    self.timertext_text.enabled = false
    MTF_text.enabled = false
    CI_text.enabled = false
end
function NewSupportManager:Activate()
    local MTF_tickets_obj = GameObject.Find("MTFTicketsText")
    local MTF_text = MTF_tickets_obj:GetComponent(typeof(CS.UnityEngine.UI.Text))
    local CI_tickets_obj = GameObject.Find("CITicketsText")
    local CI_text = CI_tickets_obj:GetComponent(typeof(CS.UnityEngine.UI.Text))
    self.timertext_text.enabled = true
    MTF_text.enabled = true
    CI_text.enabled = true
end
return NewSupportManager