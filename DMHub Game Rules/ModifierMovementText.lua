local mod = dmhub.GetModLoading()

local g_textTypeDomains = {
    {
        id = "movement",
        text = "Movement",
    },
    {
        id = "initiative",
        text = "Initiative",
    },
    {
        id = "negotiation",
        text = "Negotiation",
    },
    {
        id = "montage",
        text = "Montage",
    },
    {
        id = "respite",
        text = "Respite",
    },
}

--controls text showing up when a player is moving.
CharacterModifier.RegisterType('movementtext', "Reminder Text")

CharacterModifier.TypeInfo.movementtext = {
    init = function(modifier)
        modifier.text = ""
        modifier.color = "white"
    end,

    ReminderText = function(modifier, creature, domain, text)
        if (rawget(modifier, "texttype") or "movement") ~= domain then
            return text
        end

        local s = StringInterpolateGoblinScript(modifier.text, creature)
        if text ~= "" then
            text = text .. "\n\n"
        end
        return string.format("%s<color=%s>%s</color>", text, modifier.color, s)
    end,

    MovementAdvisoryText = function(modifier, creature, path, text)
        if (rawget(modifier, "texttype") or "movement") ~= "movement" then
            return text
        end

        if modifier:try_get("movementType", "all") == "shift" and (not path.shifting) then
            return text
        end

        local s = StringInterpolateGoblinScript(modifier.text, creature:LookupSymbol{
            path = PathMoved.new{path = path},
        })

        if text ~= "" then
            text = text .. "\n\n"
        end
        return string.format("%s<color=%s>%s</color>", text, modifier.color, s)
    end,

    createEditor = function(modifier, element)
        local Refresh
        local firstRefresh = true

        Refresh = function()
            if firstRefresh then
                firstRefresh = false
            else
                element:FireEvent("refreshModifier")
            end

            local domain = modifier:try_get("texttype", "movement")

            local children = {}
			children[#children+1] = modifier:FilterConditionEditor()

            children[#children+1] = gui.Panel{
                classes = {'formPanel'},
                children = {
                    gui.Label{
                        text = 'Domain:',
                        classes = {'formLabel'},
                    },
                    gui.Dropdown{
                        options = g_textTypeDomains,
                        idChosen = domain,
                        change = function(self)
                            modifier.texttype = self.idChosen
                            Refresh()
                        end,
                    },
                },
            }

            children[#children+1] = gui.Panel{
                classes = {'formPanel'},
                children = {
                    gui.Label{
                        text = 'Color:',
                        classes = {'formLabel'},
                    },
                    gui.Dropdown{
                        options = {
                            { id = "white", text = "White"},
                            { id = "red", text = "Red"},
                            { id = "green", text = "Green"},
                        },
                        idChosen = modifier.color,
                        change = function(self)
                            modifier.color = self.idChosen
                            Refresh()
                        end,
                    },
                },
            }

            if domain == "movement" then
                children[#children+1] = gui.Panel{
                    classes = {"formPanel"},
                    gui.Label{
                        classes = {"formLabel"},
                        text = "Movement Type:",
                    },
                    gui.Dropdown{
                        classes = {"formDropdown"},
                        options = {
                            {
                                id = "all",
                                text = "All",
                            },
                            {
                                id = "shift",
                                text = "Shift",
                            },
                        },
                        idChosen = modifier:try_get("movementType", "all"),
                        change = function(element)
                            modifier.movementType = element.idChosen
                            Refresh()
                        end,
                    }
                }
            end

            children[#children+1] = gui.Panel{
                classes = {'formPanel'},
                children = {
                    gui.Label{
                        text = 'Text:',
                        classes = {'formLabel'},
                    },
                    gui.Input{
                        height = "auto",
                        minHeight = 30,
                        maxHeight = 80,
                        width = 400,
                        multiline = true,
                        characterLimit = 2000,
                        text = modifier.text or "",
                        change = function(self)
                            modifier.text = self.text
                            Refresh()
                        end,
                    },
                },
            }

            element.children = children
        end

        Refresh()
    end,
}

CharacterModifier.RegisterType('movementrestriction', "Movement Restriction")

CharacterModifier.TypeInfo.movementrestriction = {
    init = function(modifier)
        modifier.targetFormula = ""
    end,

    GetMovementRestrictionFilter = function(modifier, cre, token)
        local formula = modifier:try_get("targetFormula", "")
        if formula == "" then return nil end

        local targetCreature = ExecuteGoblinScript(
            formula,
            cre:LookupSymbol(modifier:try_get("_tmp_symbols", {})),
            nil,
            "movement restriction target")
        if targetCreature == nil then return nil end

        local targetToken = dmhub.LookupToken(targetCreature)
        if targetToken == nil or not targetToken.valid then return nil end

        local distanceNow = targetToken:Distance(token.loc)

        return function(loc)
            return targetToken:Distance(loc) >= distanceNow
        end
    end,

    createEditor = function(modifier, element)
        local Refresh
        local firstRefresh = true

        Refresh = function()
            if firstRefresh then
                firstRefresh = false
            else
                element:FireEvent("refreshModifier")
            end

            local children = {}
            children[#children+1] = modifier:FilterConditionEditor()

            children[#children+1] = gui.Panel{
                classes = {'formPanel'},
                children = {
                    gui.Label{
                        text = 'Cannot Move Toward:',
                        classes = {'formLabel'},
                    },
                    gui.GoblinScriptInput{
                        classes = {'formInput'},
                        value = modifier:try_get("targetFormula", ""),
                        change = function(self)
                            modifier.targetFormula = self.value
                            Refresh()
                        end,
                        documentation = {
                            output = "creature",
                            help = "The creature that the affected creature cannot willingly move closer to.",
                        },
                    },
                },
            }

            element.children = children
        end

        Refresh()
    end,
}

function creature:GetMovementRestrictionFilter(token)
    local mods = self:GetActiveModifiers()
    local filters = {}
    for _, mod in ipairs(mods) do
        local typeInfo = CharacterModifier.TypeInfo[mod.mod.behavior]
        if typeInfo ~= nil and typeInfo.GetMovementRestrictionFilter ~= nil then
            local f = typeInfo.GetMovementRestrictionFilter(mod.mod, self, token)
            if f ~= nil then
                filters[#filters+1] = f
            end
        end
    end
    if #filters == 0 then return nil end
    return function(loc)
        for _, f in ipairs(filters) do
            if not f(loc) then return false end
        end
        return true
    end
end

function CharacterModifier:MovementAdvisoryText(creature, path, text)
	local typeInfo = CharacterModifier.TypeInfo[self.behavior] or {}
	if typeInfo.MovementAdvisoryText ~= nil then
        text = typeInfo.MovementAdvisoryText(self, creature, path, text)
	end
    return text
end

function CharacterModifier:ReminderText(creature, domain, text)
	local typeInfo = CharacterModifier.TypeInfo[self.behavior] or {}
	if typeInfo.ReminderText ~= nil then
        text = typeInfo.ReminderText(self, creature, domain, text)
	end
    return text
end

function gui.ReminderTextPanel(options)
    local domain = options.domain or "movement"
    options.domain = nil

    local tokens = options.tokens or {}
    options.tokens = nil

    local fontSize = options.fontSize or 14
    options.fontSize = nil

    local params = {
        width = 400,
        height = "auto",
        maxHeight = options.maxHeight or 80,
        vscroll = true,
        bgimage = true,
        flow = "vertical",
        settokens = function(element, tokens)

            local children = {}
            for _,token in ipairs(tokens) do
                local text = ""
                local modifiers = token.properties:GetActiveModifiers()
                for _,mod in ipairs(modifiers) do
                    text = mod.mod:ReminderText(token.properties, domain, text)
                end

                if text ~= "" then
                    children[#children+1] = gui.Panel{
                        flow = "horizontal",
                        width = "100%-8",
                        height = "auto",
                        halign = "left",
                        valign = "top",
                        classes = {"reminderTextPanel"},
                        gui.CreateTokenImage(token, {
                            width = 32,
                            height = 32,
                            valign = "center",
                            lmargin = 4,
                        }),
                        gui.Label{
                            text = text,
                            fontSize = fontSize,
                            color = "white",
                            width = "100%-40",
                            height = "auto",
                            halign = "right",
                            valign = "center",
                        },
                    }
                end
            end
            element.children = children
        end,
    }

    for k,v in pairs(options) do
        params[k] = v
    end

    local resultPanel = gui.Panel(params)
    resultPanel:FireEvent("settokens", tokens)
    return resultPanel
end