local bot_active = false
local show_gui = false
local give_item_gui_open = false
local bot_functions = {
    mine = true,
    place_drills = true,
    build_base = true,
    place_turrets = true,
    mine_any_resource = false
}

local resource_types = {"iron-ore", "copper-ore", "coal", "stone", "uranium-ore"}
local selected_resource = "iron-ore"
local resource_limit = 100
local waypoints = {}

local function table_find(tbl, value)
    for index, val in ipairs(tbl) do
        if val == value then
            return index
        end
    end
    return nil
end

local function mine_nearest_resource(player)
    local surface = player.surface
    local position = player.position
    local resources = surface.find_entities_filtered{type = "resource", name = selected_resource}
    local nearest_resource = nil
    local nearest_distance = math.huge
    local mined_amount = player.get_item_count(selected_resource)

    if mined_amount >= resource_limit then
        player.print("Resource limit reached: " .. resource_limit)
        bot_active = false
        create_bot_gui(player)
        return
    end

    for _, resource in pairs(resources) do
        local distance = ((resource.position.x - position.x)^2 + (resource.position.y - position.y)^2)^0.5
        if distance < nearest_distance then
            nearest_resource = resource
            nearest_distance = distance
        end
    end

    if nearest_resource then
        local resource_position = nearest_resource.position
        local dx = resource_position.x - position.x
        local dy = resource_position.y - position.y

        local direction_x, direction_y = nil, nil

        if math.abs(dx) > 0.5 then
            if dx > 0 then
                direction_x = defines.direction.east
            else
                direction_x = defines.direction.west
            end
        end

        if math.abs(dy) > 0.5 then
            if dy > 0 then
                direction_y = defines.direction.south
            end
        end

        if direction_x then
            player.walking_state = {walking = true, direction = direction_x}
        elseif direction_y then
            player.walking_state = {walking = true, direction = direction_y}
        else
            player.walking_state = {walking = false}
            player.mine_entity(nearest_resource)
        end
    else
        player.walking_state = {walking = false}
    end
end

local function mine_any_resource(player)
    local surface = player.surface
    local position = player.position
    local resources = surface.find_entities_filtered{type = "resource"}
    local nearest_resource = nil
    local nearest_distance = math.huge

    for _, resource in pairs(resources) do
        local distance = ((resource.position.x - position.x)^2 + (resource.position.y - position.y)^2)^0.5
        if distance < nearest_distance then
            nearest_resource = resource
            nearest_distance = distance
        end
    end

    if nearest_resource then
        local resource_position = nearest_resource.position
        local dx = resource_position.x - position.x
        local dy = resource_position.y - position.y

        local direction_x, direction_y = nil, nil

        if math.abs(dx) > 0.5 then
            if dx > 0 then
                direction_x = defines.direction.east
            else
                direction_x = defines.direction.west
            end
        end

        if math.abs(dy) > 0.5 then
            if dy > 0 then
                direction_y = defines.direction.south
            end
        end

        if direction_x then
            player.walking_state = {walking = true, direction = direction_x}
        elseif direction_y then
            player.walking_state = {walking = true, direction = direction_y}
        else
            player.walking_state = {walking = false}
            player.mine_entity(nearest_resource)
        end
    else
        player.walking_state = {walking = false}
    end
end

local function place_mining_drills(player)
    local surface = player.surface
    local position = player.position
    local miner_name = "electric-mining-drill"
    local miner_position = {x = position.x + 5, y = position.y}

    if surface.can_place_entity{name = miner_name, position = miner_position} then
        surface.create_entity{name = miner_name, position = miner_position, force = player.force}
    end
end

local function build_base(player)
    local surface = player.surface
    local position = player.position
    local entities_to_place = {
        {name = "assembling-machine-1", position = {x = position.x + 10, y = position.y}},
        {name = "assembling-machine-1", position = {x = position.x + 12, y = position.y}},
        {name = "small-electric-pole", position = {x = position.x + 11, y = position.y - 1}},
        {name = "small-electric-pole", position = {x = position.x + 11, y = position.y + 1}},
    }

    for _, entity in pairs(entities_to_place) do
        if surface.can_place_entity{name = entity.name, position = entity.position} then
            surface.create_entity{name = entity.name, position = entity.position, force = player.force}
        end
    end
end

local function place_turrets(player)
    local surface = player.surface
    local position = player.position
    local turret_name = "gun-turret"
    local turret_position = {x = position.x + 5, y = position.y}

    if surface.can_place_entity{name = turret_name, position = turret_position} then
        surface.create_entity{name = turret_name, position = turret_position, force = player.force}
    end
end

local function create_bot_gui(player)
    if player.gui.left.bot_gui then
        player.gui.left.bot_gui.destroy()
    end

    if show_gui then
        local frame = player.gui.left.add{type = "frame", name = "bot_gui", caption = "Bot Control", direction = "vertical"}

        local start_stop_button = frame.add{
            type = "button",
            name = "start_stop_button",
            caption = bot_active and "Stop Bot" or "Start Bot",
            style = bot_active and "green_button" or "red_button"
        }

        frame.add{type = "checkbox", name = "mine_checkbox", caption = "Auto-mine resources", state = bot_functions.mine}
        frame.add{type = "checkbox", name = "place_drills_checkbox", caption = "Place mining drills", state = bot_functions.place_drills}
        frame.add{type = "checkbox", name = "build_base_checkbox", caption = "Build base", state = bot_functions.build_base}
        frame.add{type = "checkbox", name = "place_turrets_checkbox", caption = "Place turrets", state = bot_functions.place_turrets}
        frame.add{type = "checkbox", name = "mine_any_resource_checkbox", caption = "Mine any resource", state = bot_functions.mine_any_resource}

        frame.add{type = "label", name = "resource_label", caption = "Select resource to mine:"}
        local resource_dropdown = frame.add{type = "drop-down", name = "resource_dropdown", items = resource_types, selected_index = table_find(resource_types, selected_resource) or 1}
        frame.add{type = "label", name = "limit_label", caption = "Resource limit:"}
        local limit_textfield = frame.add{type = "textfield", name = "resource_limit_textfield", text = tostring(resource_limit)}

        local waypoint_frame = frame.add{type = "frame", name = "waypoint_frame", caption = "Waypoints", direction = "vertical"}
        waypoint_frame.add{type = "button", name = "add_waypoint_button", caption = "Add Waypoint"}
        for index, waypoint in ipairs(waypoints) do
            local flow = waypoint_frame.add{type = "flow", name = "waypoint_" .. index, direction = "horizontal"}
            flow.add{type = "textfield", name = "waypoint_textfield_" .. index, text = waypoint.name}
            flow.add{type = "button", name = "delete_waypoint_" .. index, caption = "Delete"}
            flow.add{type = "button", name = "go_to_waypoint_" .. index, caption = "Go To"}
        end
    end
end

local function toggle_bot_gui(player)
    show_gui = not show_gui
    create_bot_gui(player)
end

local function create_give_item_gui(player)
    if player.gui.left.give_item_frame then
        player.gui.left.give_item_frame.destroy()
    end

    local frame = player.gui.left.add{type = "frame", name = "give_item_frame", caption = "Give Item"}
    frame.add{type = "textfield", name = "item_name_textfield", text = ""}
    frame.add{type = "textfield", name = "item_count_textfield", text = "1"}
    frame.add{type = "button", name = "give_item_button", caption = "Give Item"}
end

local function toggle_give_item_gui(player)
    give_item_gui_open = not give_item_gui_open

    if give_item_gui_open then
        create_give_item_gui(player)
    else
        if player.gui.left.give_item_frame then
            player.gui.left.give_item_frame.destroy()
        end
    end
end

local function on_gui_click(event)
    local element = event.element
    local player = game.players[event.player_index]

    if element.name == "start_stop_button" then
        bot_active = not bot_active
        create_bot_gui(player)
    elseif element.name == "mine_checkbox" then
        bot_functions.mine = element.state
    elseif element.name == "place_drills_checkbox" then
        bot_functions.place_drills = element.state
    elseif element.name == "build_base_checkbox" then
        bot_functions.build_base = element.state
    elseif element.name == "place_turrets_checkbox" then
        bot_functions.place_turrets = element.state
    elseif element.name == "mine_any_resource_checkbox" then
        bot_functions.mine_any_resource = element.state
    elseif element.name == "add_waypoint_button" then
        local waypoint = {name = "Waypoint " .. (#waypoints + 1), position = player.position}
        table.insert(waypoints, waypoint)
        create_bot_gui(player)
    elseif string.find(element.name, "delete_waypoint_") then
        local index = tonumber(string.match(element.name, "%d+"))
        table.remove(waypoints, index)
        create_bot_gui(player)
    elseif string.find(element.name, "go_to_waypoint_") then
        local index = tonumber(string.match(element.name, "%d+"))
        local waypoint = waypoints[index]
        player.teleport(waypoint.position)
    elseif element.name == "give_item_button" then
        local item_name = player.gui.left.give_item_frame.item_name_textfield.text
        local item_count = tonumber(player.gui.left.give_item_frame.item_count_textfield.text) or 1

        if game.item_prototypes[item_name] then
            player.insert{name = item_name, count = item_count}
            player.print("Gave " .. item_count .. " x " .. item_name)
        else
            player.print("Invalid item name: " .. item_name)
        end
    end
end

local function on_gui_text_changed(event)
    local element = event.element

    if string.find(element.name, "waypoint_textfield_") then
        local index = tonumber(string.match(element.name, "%d+"))
        waypoints[index].name = element.text
    elseif element.name == "resource_limit_textfield" then
        resource_limit = tonumber(element.text) or resource_limit
    end
end

local function on_gui_checked_state_changed(event)
    local element = event.element
    if element.name == "resource_dropdown" then
        selected_resource = resource_types[element.selected_index]
    end
end

script.on_event("toggle-bot-gui", function(event)
    local player = game.players[event.player_index]
    toggle_bot_gui(player)
end)

script.on_event("toggle-give-item-gui", function(event)
    local player = game.players[event.player_index]
    toggle_give_item_gui(player)
end)

script.on_event(defines.events.on_gui_click, on_gui_click)
script.on_event(defines.events.on_gui_text_changed, on_gui_text_changed)
script.on_event(defines.events.on_gui_checked_state_changed, on_gui_checked_state_changed)

script.on_event(defines.events.on_tick, function(event)
    if bot_active then
        for _, player in pairs(game.connected_players) do
            if bot_functions.mine then
                mine_nearest_resource(player)
            end

            if bot_functions.mine_any_resource then
                mine_any_resource(player)
            end

            if bot_functions.place_drills then
                place_mining_drills(player)
            end

            if bot_functions.build_base then
                build_base(player)
            end

            if bot_functions.place_turrets then
                place_turrets(player)
            end
        end
    end
end)

script.on_event(defines.events.on_player_joined_game, function(event)
    local player = game.players[event.player_index]
    create_bot_gui(player)
end)
