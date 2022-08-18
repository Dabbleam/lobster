local state = {}

-- Special variable used to blank out state items
-- Probably a better way to do this
NULL = {}

local STATE_DEBUG = false

local state_hooks = {}

function state:on( key, func, ... )
    state_hooks[ key ] = state_hooks[ key ] or {}
    table.insert( state_hooks[ key ], { func = func, args = { ... } } )
end

local wrap_table_with_hook_calls

-- This might be too much recursion, look into exempting some objects?

wrap_table_with_hook_calls = function( table, isNew, key )
    local wrapped = {}

    if isNew then
        for k, v in pairs( table ) do
            local childKey = key and ( key .. "." .. k ) or k
            if v == NULL then v = nil end

            if STATE_DEBUG then
                print( "state: calling hooks for new object subkey: " .. childKey )
            end

            if type( v ) == "table" and k:sub( 1, 1 ) ~= "_" then
                wrapped[ k ] = wrap_table_with_hook_calls( v, true, childKey )
            else
                wrapped[ k ] = v
            end

            if state_hooks[ childKey ] then
                for _, hook in ipairs( state_hooks[ childKey ] ) do
                    hook.func( v, unpack( hook.args ) )
                end
            end
        end
    end

    setmetatable( wrapped, {
        __newindex = function( _, k, v )
            local childKey = key and ( key .. "." .. k ) or k
            if v == NULL then v = nil end
            if type( v ) == "table" then
                v = wrap_table_with_hook_calls( v, v ~= table[ k ], childKey )
            end

            table[ k ] = v

            if STATE_DEBUG then
                print( "state: calling hooks for modified subkey: " .. childKey )
            end

            if state_hooks[ childKey ] then
                for _, hook in ipairs( state_hooks[ childKey ] ) do
                    hook.func( v, unpack( hook.args ) )
                end
            end
        end,

        __index = function( _, k )
            return table[ k ]
        end
    })

    return wrapped
end

return wrap_table_with_hook_calls( state )