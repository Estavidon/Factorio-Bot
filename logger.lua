-- logger.lua

local Logger = {}

Logger.file_path = "__my_mod__/error_log.txt"

function Logger.log_error(error_message)
    local file = io.open(Logger.file_path, "a")
    if file then
        file:write(os.date("%Y-%m-%d %H:%M:%S") .. " - " .. error_message .. "\n")
        file:close()
    else
        game.print("Failed to open log file for writing.")
    end
end

return Logger
