--[[ BSD 3-Clause License

Copyright (c) 2022, Marian Arlt
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. ]]

_addon.name = 'WarnMe'
_addon.author = 'Deridjian'
_addon.version = '1.0'
_addon.command = 'wm'

config = require('config')
texts = require('texts')
res = require('resources')
require('logger')

local defaults = {}
defaults.screen = windower.get_windower_settings().ui_x_res
defaults.timeout = 4
defaults.fontem = 0.9

defaults.ability = {}
defaults.ability.pos = {}
defaults.ability.pos.x = defaults.screen / 2
defaults.ability.pos.y = windower.get_windower_settings().ui_y_res / 2
defaults.ability.flags = {}
defaults.ability.flags.bold = true
defaults.ability.text = {}
defaults.ability.text.size = 38
defaults.ability.text.font = 'Lucida Console'
defaults.ability.text.stroke = {}
defaults.ability.text.stroke.width = 2
defaults.ability.text.stroke.alpha = 210
defaults.ability.bg = {}
defaults.ability.bg.visible = false
defaults.ability.show = {}
defaults.ability.show.spells = true
defaults.ability.show.others = false

defaults.details = {}
defaults.details.pos = {}
defaults.details.pos.x = defaults.ability.pos.x
defaults.details.pos.y = defaults.ability.pos.y + defaults.ability.text.size * 1.75
defaults.details.flags = {}
defaults.details.flags.bold = true
defaults.details.text = {}
defaults.details.text.size = defaults.ability.text.size / 2.5
defaults.details.text.font = defaults.ability.text.font
defaults.details.text.stroke = {}
defaults.details.text.stroke.width = 1
defaults.details.bg = {}
defaults.details.bg.visible = false
defaults.details.show = {}
defaults.details.show.actor = true
defaults.details.show.target = true

settings = config.load(defaults)

local ability = texts.new('', settings.ability, settings)
local details = texts.new('', settings.details, settings)
local forced

function display_action(action, category)
    local language = windower.ffxi.get_info().language == "English" and 'en' or 'ja'
    local ability_id = action.targets[1].actions[1].param
    local categories = {[6]="job_abilities", [7]="monster_abilities", [8]="spells"}
    local action_name = res[categories[category]][ability_id][language]

    ability:text(action_name)
    align_center(ability, 'ability', action_name)
    ability:show()
end

function display_details(action)
    local actor = windower.ffxi.get_mob_by_id(action.actor_id)
    local actor_target = windower.ffxi.get_mob_by_id(action.targets[1].id)
    local details_string

    if settings.details.show.actor and settings.details.show.target then
        details_string = actor.name.." > "..actor_target.name
    elseif settings.details.show.actor and not settings.details.show.target then
        details_string = actor.name
    else
        details_string = "on "..actor_target.name
    end

    details:text(details_string)
    align_center(details, 'details', details_string)
    details:show()
end

function align_center(element, key, string)
    local pos_x = settings.screen / 2 - (#string * settings[key].text.size * settings.fontem / 2)
    element:pos(pos_x, settings[key].pos.y)
end

function hide_and_clear()
    ability:hide(); details:hide(); ability:clear(); details:clear()
end

windower.register_event('action', function(action)
    -- fail as soon as possible: only if something is targeted and the action came from that target
    if windower.ffxi.get_mob_by_target('t') and windower.ffxi.get_mob_by_target('t').id == action.actor_id then
        local target = windower.ffxi.get_mob_by_target('t')

        if
            target.spawn_type == 16 and -- target is a monster
            (settings.ability.show.others or windower.ffxi.get_mob_by_id(target.claim_id).in_alliance) and
            (action.category == 6 or action.category == 7 or (action.category == 8 and settings.ability.show.spells))
        then
            display_action(action, action.category)
            if settings.details.show.actor or settings.details.show.target then
                display_details(action)
            end

            if not forced then
                coroutine.schedule(hide_and_clear, settings.timeout)
            end
        end
    end
end)

windower.register_event('addon command', function(command, ...)
    cmd = command and command:lower()
    local arg = {...}

    -- choose what's being shown and what's not
    if cmd == 'toggle' then
        if arg[1] == 'actor' then
            if settings.details.show.actor then
                notice("Actor will now be hidden.")
            else
                notice("Actor will now be shown.")
            end
            settings.details.show.actor = not settings.details.show.actor
            settings:save()
        elseif arg[1] == 'target' then
            if settings.details.show.target then
                notice("Target will now be hidden.")
            else
                notice("Target will now be shown.")
            end
            settings.details.show.target = not settings.details.show.target
            settings:save()
        elseif arg[1] == 'spells' then
            if settings.ability.show.spells then
                notice("Spells will now be hidden.")
            else
                notice("Spells will now be shown.")
            end
            settings.ability.show.spells = not settings.ability.show.spells
            settings:save()
        else
            error("Argument for //wm toggle must be 'target', 'actor' or 'spells'.")
        end

    -- set how many seconds the information will be shown on screen
    elseif cmd == 'timeout' then
        if not tonumber(arg[1]) then
            error("Argument for //wm timeout must be a number.")
        else
            settings.timeout = tonumber(arg[1])
            settings:save()
            notice("Information will now be shown for "..arg[1].." seconds.")
        end

    -- change font size
    elseif cmd == 'size' then
        if not tonumber(arg[2]) then
            error("Second argument for //wm size must be a number.")
        elseif arg[1] == 'ability' or arg[1] == 'details' then
            if arg[1] == 'ability' then
                settings.ability.text.size = tonumber(arg[2])
                settings.details.pos.y = settings.ability.pos.y + tonumber(arg[2]) * 1.75
                notice("Ability is now set to "..arg[2].." points.")
            elseif arg[1] == 'details' then
                settings.details.text.size = tonumber(arg[2])
                notice("Details are now set to "..arg[2].." points.")
            end
            settings:save()
            config.reload(settings)
        else
            error("First argument for //wm size must be 'ability' or 'details'.")
        end

    -- choose whether to allow mobs claimed by others
    elseif cmd == 'mode' then
        if settings.ability.show.others then
            notice("Mode is now set to allow only mobs claimed by yourself and your party/alliance.")
        else
            notice("Mode is now set to also allow unclaimed mobs and mobs claimed by others.")
        end
        settings.ability.show.others = not settings.ability.show.others
        settings:save()

    elseif cmd == 'tune' then
        if tonumber(arg[1]) >= 0.5 and tonumber(arg[1]) <= 1.5 then
            settings.fontem = tonumber(arg[1])
            settings:save()
            config.reload(settings)
            notice("Alignment was adjusted to be "..arg[1].."em.")
        else
            error("Takes a decimal value between 0.5 and 1.5.")
        end

    -- force visibility to allow easy mouse move and y-axis changes
    elseif cmd == 'sticky' then
        if forced then
            forced = nil
            hide_and_clear()
        else
            forced = true
            ability:text("Infinite Trouble")
            align_center(ability, 'ability', "Infinite Trouble")
            ability:show()
            if settings.details.show.actor or settings.details.show.target then
                local details_string
                if settings.details.show.actor and settings.details.show.target then
                    details_string = "Debuglix > "..windower.ffxi.get_player().name
                elseif settings.details.show.actor and not settings.details.show.target then
                    details_string = "Debuglix"
                else
                    details_string = "on "..windower.ffxi.get_player().name
                end
                details:text(details_string)
                align_center(details, 'details', details_string)
                details:show()
            end
        end

    -- print help text to log
    else
        windower.add_to_chat(200, " ")
        windower.add_to_chat(200, "WarnMe was built to help you prominently notice enemy moves")
        windower.add_to_chat(200, "Toggle off '/names' for maximum legibility")
        windower.add_to_chat(200, " ")
        windower.add_to_chat(207, "//wm toggle [actor/target/spells] : Toggles display of the passed argument")
        windower.add_to_chat(207, "//wm timeout [seconds] : Sets the duration for which the action will be displayed")
        windower.add_to_chat(207, "//wm size [ability/details] [size] : Changes the font size of either one")
        windower.add_to_chat(207, "//wm tune [0.5-1.5] : Tune alignment; lower to push right, raise to push left")
        windower.add_to_chat(207, "//wm mode : Toogles between allowing own claims or any, even by others")
        windower.add_to_chat(207, "//wm sticky : Toggles forced visibility for manual positioning on y-axis")
    end
end)