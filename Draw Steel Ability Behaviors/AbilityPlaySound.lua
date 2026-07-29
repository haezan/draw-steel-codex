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
function ActivatedAbilityPlaySoundBehavior:GetRepeatCount(ability, casterToken, options)
    if self.repeatCount == nil or self.repeatCount == "" then
        return 1
    end

    local count = ExecuteGoblinScript(self.repeatCount, casterToken.properties:LookupSymbol(options.symbols), nil, string.format("Sound repeats for %s", ability.name))
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
    local repeats = self:GetRepeatCount(ability, casterToken, options)
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
            audio.PlaySoundEvent {
                asset = asset,
                volume = self.volume,
            }
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
            text = "Repeat:",
        },
        gui.GoblinScriptInput {
            classes = { "formInput" },
            value = self.repeatCount,
            change = function(element)
                self.repeatCount = element.value
            end,
            documentation = {
                help = "This GoblinScript determines how many times the sound is played. If left blank the sound plays once. If it evaluates to nothing, or to a number less than one, the sound is not played at all.",
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
            if self.mode == "custom" then
                if self.soundAsset == nil or self.soundAsset == "" then
                    return
                end
                local asset = assets.audioTable[self.soundAsset]
                if asset == nil then
                    return
                end
                local instance = asset:Play()
                if instance ~= nil then
                    instance.volume = self.volume
                end
                return
            end

            if self.soundEvent == "none" then
                return
            end
            audio.FireSoundEvent(self.soundEvent, {
                volume = self.volume,
                delay = self.delay,
            })
        end,
    }

    return result
end
