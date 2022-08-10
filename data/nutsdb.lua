-- NutsDB parser for Lua

-- Used in this project to migrate history and settings from Probster

local struct = require "struct"
local bit = require "bit"

--- NutsDB format, taken from datafile.go

--  the entry stored format:
--  |----------------------------------------------------------------------------------------------------------------|
--  |  crc  | timestamp | ksz | valueSize | flag  | TTL  |bucketSize| status | ds   | txId |  bucket |  key  | value |
--  |----------------------------------------------------------------------------------------------------------------|
--  | uint32| uint64  |uint32 |  uint32 | uint16  | uint32| uint32 | uint16 | uint16 |uint64 |[]byte|[]byte | []byte |
--  |----------------------------------------------------------------------------------------------------------------|

-- CRC is calculated over the entire entry (timestamp through value)

local nuts = {}
nuts.__index = nuts

local ENTRY_HEADER_SIZE = 42

local ENTRY_FLAG_DELETE = 0
local ENTRY_FLAG_SET = 1

function nuts.open( base )
	if type( f ) == "string" then
		f = assert( io.open( f, "rb" ) )
	end

	local self = { base = base, buckets = {} }
	setmetatable( self, nuts )

	return self
end

function nuts:read_file( f )
	assert( f and type( f ) == "string", "bad argument #1 to 'read_file' (expected string, got " .. type( f ) .. ")" )
	local f = assert( io.open( self.base .. "/" .. f .. ".dat", "rb" ) )
	self.f = f
	self:read_entries()
end

function nuts:read_entries()
	local entry = self:read_entry()
	while entry do
		self.buckets[ entry.bucket ] = self.buckets[ entry.bucket ] or {}
		local b = self.buckets[ entry.bucket ]
		if entry.flag == 0 then
			assert( b[ entry.key ], "missing deleted key " .. entry.key .. " in bucket " .. entry.bucket )
			b[ entry.key ] = nil
		else
			assert( not b[ entry.key ], "duplicate key " .. entry.key .. " in bucket " .. entry.bucket )
			b[ entry.key ] = entry.value
		end
		entry = self:read_entry()
	end

	self.buckets = self.buckets
end

function nuts:read_entry()
	local entryHeader = self.f:read( ENTRY_HEADER_SIZE )
	local crc, timestamp, ksz, vsz, flag, ttl, bucketSz, status, ds, txId =
		struct.unpack( "<ILIIHIIHHL", entryHeader )

	if crc == 0 and timestamp == 0 and ksz == 0 then
		-- Reached end of preallocated file, bail!

		return
	end

	-- TODO: verify CRC!

	local bucket = self.f:read( bucketSz )
	local key = self.f:read( ksz )
	local value = self.f:read( vsz )

	local entry = {
		bucket = bucket,
		timestamp = timestamp,
		key = key,
		value = value,
		flag = flag,
		ttl = ttl,
		status = status
	}

	return entry
end

do return end

local test = nuts.open( "test" )
test:read_file( "0" )
test:read_file( "1" )
test:read_file( "2" )
test:read_file( "3" )

for k, v in pairs( test.buckets ) do
	print( k )
	for i, z in pairs( v ) do
		local printVal = z
		if #printVal > 20 then
			printVal = printVal:sub( 1, 20 ) .. "..."
		end
		print( "        " .. i .. " = " .. printVal )
	end
end
