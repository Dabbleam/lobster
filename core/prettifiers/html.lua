local process = require "process"
local htmlPrettifier = {}

function htmlPrettifier.prettify( data )
    local proc = assert( process.exec( "node", { "core/prettifiers/node/prettify-html.mjs" } ) )
    proc:stdin( data )
    local stdin = proc:fds()
    process.close( stdin )

    local pid = proc:pid()
    -- This completely hangs on long inputs. (?????)
    -- local status, err = process.waitpid( pid )

    local fullOutput = {}
    local data, again

    repeat
        data, err, again = proc:stdout()
        table.insert( fullOutput, data )
    until not data and not again

    return table.concat( fullOutput )
end

return htmlPrettifier