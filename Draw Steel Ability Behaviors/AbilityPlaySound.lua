local mod = dmhub.GetModLoading()

RegisterGameType("ActivatedAbilityPlaySoundBehavior", "ActivatedAbilityBehavior")

ActivatedAbility.RegisterType
{
    id = 'play_sound',
    text = 'Play Sound',
    createBehavior = function()
        return ActivatedAbilityPlaySoundBehavior.new {
        }
    end
}

ActivatedAbilityPlaySoundBehavior.summary = 'Play Sound'
ActivatedAbilityPlaySoundBehavior.mode = "builtin"
ActivatedAbilityPlaySoundBehavior.soundEvent = "none"
ActivatedAbilityPlaySoundBehavior.soundAsset = ""
ActivatedAbilityPlaySoundBehavior.volume = 1
ActivatedAbilityPlaySoundBehavior.delay = 0
ActivatedAbilityPlaySoundBehavior.repeatCount = ""
ActivatedAbilityPlaySoundBehavior.repeatInterval = 0.25

--a runaway formula could otherwise schedule an unbounded number of sounds.
local g_maxRepeats = 10

--returns the number of times to play, or nil if the sound should not play at all.
--ability/casterToken may be nil (e.g. previewing in the editor with no token
--selected on the map). ExecuteGoblinScript doesn't require a real creature to
--evaluate a plain number, so we still attempt it -- only formulas that
--reference creature/ability symbols will fail to resolve without full context.
function ActivatedAbilityPlaySoundBehavior:GetRepeatCount(ability, casterToken, symbols)
    if self.repeatCount == nil or self.repeatCount == "" then
        return 1
    end

    symbols = symbols or {}
    if ability ~= nil then
        symbols.ability = symbols.ability or ability
    end

    local lookupSymbols = symbols
    if casterToken ~= nil then
        lookupSymbols = casterToken.properties:LookupSymbol(symbols)
    end

    local contextMessage = "Sound repeats"
    if ability ~= nil then
        contextMessage = string.format("Sound repeats for %s", ability.name)
    end

    local count = ExecuteGoblinScript(self.repeatCount, lookupSymbols, nil, contextMessage)
    if count == nil then
        return nil
    end

    count = math.floor(count)
    if count < 1 then
        return nil
    end

    return math.min(count, g_maxRepeats)
end

function ActivatedAbilityPlaySoundBehavior:Cast(ability, casterToken, targets, options)
    local repeats = self:GetRepeatCount(ability, casterToken, options.symbols)
    print(string.format("PLAYSOUND_DEBUG Cast t=%.3f self=%s ability=%s asset=%s soundEvent=%s repeatCountField=%s repeats=%s castid=%s",
        dmhub.Time(), tostring(self), ability and ability.name or "?", tostring(self.soundAsset), tostring(self.soundEvent),
        tostring(self.repeatCount), tostring(repeats), options.symbols and options.symbols.castid or "?"))
    if repeats == nil then
        return
    end

    if self.mode == "custom" then
        if self.soundAsset == nil or self.soundAsset == "" then
            return
        end

        local asset = assets.audioTable[self.soundAsset]
        if asset == nil then
            return
        end

        local Play = function(i)
            --PlaySoundEvent keys its shared sync doc by the asset's own id, so a
            --repeat play with byte-identical content just gets silently coalesced
            --away as a no-op value "change" -- including a play from an unrelated
            --concurrent cast of this same asset (e.g. an ability that fires twice
            --per use, like the Akimbo kit). Explicitly stopping the old instance
            --first works, but the abrupt cutoff itself produces an audible click.
            --Nudging pitch by an inaudible, alternating amount instead forces a
            --genuine value change each repeat, so the engine runs its own internal
            --replace (delete-then-recreate) instead of us hard-interrupting it.
            local playOptions = {
                asset = asset,
                volume = self.volume,
            }
            if i > 1 then
                --only nudge repeats -- the first play keeps its exact configured
                --pitch untouched.
                playOptions.pitch = (i % 2 == 0) and 1.001 or 0.999
            end
            print(string.format("PLAYSOUND_DEBUG Play t=%.3f self=%s asset=%s i=%d/%d pitch=%s", dmhub.Time(), tostring(self), tostring(self.soundAsset), i, repeats, tostring(playOptions.pitch)))
            audio.PlaySoundEvent(playOptions)
        end

        for i = 1, repeats do
            local delay = self.delay + (i - 1)*self.repeatInterval
            if delay > 0 then
                dmhub.Schedule(delay, function()
                    if mod.unloaded then return end
                    Play(i)
                end)
            else
                Play(i)
            end
        end
        return
    end

    if self.soundEvent == "none" then
        return
    end

    for i = 1, repeats do
        audio.DispatchSoundEvent(self.soundEvent, {
            volume = self.volume,
            delay = self.delay + (i - 1)*self.repeatInterval,
        })
    end
end

function ActivatedAbilityPlaySoundBehavior:EditorItems(parentPanel)
    local result = {}

    local soundOptions = {
        {
            id = "none",
            text = "None",
        }
    }

    for name, _ in pairs(audio.soundEvents) do
        soundOptions[#soundOptions+1] = {
            id = name,
            text = name,
        }
    end

    local builtinPanel
    local customPanel

    result[#result+1] = gui.Panel {
        classes = { "formPanel" },
        gui.Label {
            classes = { "formLabel" },
            text = "Sound Source:",
        },

        gui.Dropdown {
            idChosen = self.mode,
            options = {
                { id = "builtin", text = "Built-in" },
                { id = "custom", text = "Custom" },
            },
            change = function(element)
                self.mode = element.idChosen
                builtinPanel:SetClass("collapsed", self.mode ~= "builtin")
                customPanel:SetClass("collapsed", self.mode ~= "custom")
            end,
        }
    }

    builtinPanel = gui.Panel {
        classes = { "formPanel", cond(self.mode ~= "builtin", "collapsed") },
        gui.Label {
            classes = { "formLabel" },
            text = "Sound Event:",
        },

        gui.Dropdown {
            idChosen = self.soundEvent,
            hasSearch = true,
            sort = true,
            options = soundOptions,
            change = function(element)
                self.soundEvent = element.idChosen
            end,
        }
    }
    result[#result+1] = builtinPanel

    customPanel = gui.Panel {
        classes = { "formPanel", cond(self.mode ~= "custom", "collapsed") },
        gui.Label {
            classes = { "formLabel" },
            text = "Custom Sound:",
        },

        gui.AudioEditor {
            width = 64,
            height = 64,
            halign = "left",
            value = self.soundAsset ~= "" and self.soundAsset or nil,
            change = function(element)
                self.soundAsset = element.value or ""
            end,
        },
    }
    result[#result+1] = customPanel

    result[#result+1] = gui.Panel {
        classes = { "formPanel" },
        gui.Label {
            classes = { "formLabel" },
            text = "Volume:",
        },
        gui.Slider{
            style = {
                height = 30,
                width = 200,
                fontSize = 14,
            },
            sliderWidth = 140,
            labelWidth = 50,
            value = self.volume,
            halign = "left",
            minValue = 0,
            maxValue = 2,
            formatFunction = function(num)
                return string.format('%d%%', round(num*100))
            end,
            deformatFunction = function(num)
                return num*0.01
            end,
            events = {
                change = function(element)
                    self.volume = element.value
                end,
            },
        },
    }

    result[#result+1] = gui.Panel {
        classes = { "formPanel" },
        gui.Label {
            classes = { "formLabel" },
            text = "Delay (s):",
        },
        gui.Input {
            classes = { "formInput" },
            width = 100,
            text = tostring(self.delay),
            characterLimit = 16,
            change = function(element)
                self.delay = tonumber(element.text) or self.delay
                if self.delay < 0 then
                    self.delay = 0
                end
                element.text = tostring(self.delay)
            end,
        },
    }

    result[#result+1] = gui.Panel {
        classes = { "formPanel" },
        gui.Label {
            classes = { "formLabel" },
            text = "Play Count:",
        },
        gui.GoblinScriptInput {
            classes = { "formInput" },
            value = self.repeatCount,
            change = function(element)
                self.repeatCount = element.value
            end,
            documentation = {
                help = "This GoblinScript determines how many times the sound is played in total. If left blank the sound plays once. If it evaluates to nothing, or to a number less than one, the sound is not played at all.",
                output = "number",
                subject = creature.helpSymbols,
                subjectDescription = "The creature invoking the ability",
                examples = {
                    {
                        script = "3",
                        text = "Play the sound three times.",
                    },
                    {
                        script = "Ability.Number of Targets",
                        text = "Play the sound once for each creature the ability targets.",
                    },
                },
                symbols = {
                    ability = {
                        name = "Ability",
                        type = "ability",
                        desc = "The ability that is playing this sound.",
                    },
                },
            },
        },
    }

    result[#result+1] = gui.Panel {
        classes = { "formPanel" },
        gui.Label {
            classes = { "formLabel" },
            text = "Repeat Interval (s):",
        },
        gui.Input {
            classes = { "formInput" },
            width = 100,
            text = tostring(self.repeatInterval),
            characterLimit = 16,
            change = function(element)
                self.repeatInterval = tonumber(element.text) or self.repeatInterval
                if self.repeatInterval < 0 then
                    self.repeatInterval = 0
                end
                element.text = tostring(self.repeatInterval)
            end,
        },
    }

    result[#result+1] = gui.Button {
        classes = {"sizeM"},
        width = 160,
        text = "Preview Sound",
        click = function(element)
            local ability = parentPanel.data.parentAbility
            local casterToken = dmhub.selectedTokens[1]
            local repeats = self:GetRepeatCount(ability, casterToken, {})
            if repeats == nil then
                return
            end

            if self.mode == "custom" then
                if self.soundAsset == nil or self.soundAsset == "" then
                    return
                end
                local asset = assets.audioTable[self.soundAsset]
                if asset == nil then
                    return
                end

                local Play = function()
                    local instance = asset:Play()
                    if instance ~= nil then
                        instance.volume = self.volume
                    end
                end

                for i = 1, repeats do
                    local delay = self.delay + (i - 1)*self.repeatInterval
                    if delay > 0 then
                        dmhub.Schedule(delay, function()
                            if mod.unloaded then return end
                            Play()
                        end)
                    else
                        Play()
                    end
                end
                return
            end

            if self.soundEvent == "none" then
                return
            end

            for i = 1, repeats do
                audio.FireSoundEvent(self.soundEvent, {
                    volume = self.volume,
                    delay = self.delay + (i - 1)*self.repeatInterval,
                })
            end
        end,
    }

    return result
end
