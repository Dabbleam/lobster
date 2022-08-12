local state = {}

local state_internal = {}
local state_hooks = {}

function state:on( key, func, ... )
    state_hooks[ key ] = state_hooks[ key ] or {}
    table.insert( state_hooks[ key ], { func = func, args = { ... } } )
end

setmetatable( state, {
    __newindex = function( _, key, value )
        state_internal[ key ] = value

        if state_hooks[ key ] then
            for _, hook in ipairs( state_hooks[ key ] ) do
                hook.func( value, unpack( hook.args ) )
            end
        end
    end,

    __index = function( _, key )
        return state_internal[ key ]
    end
} )

return state