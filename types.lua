

-- How the bytestream is described on comments:
-- <t> a - means 'a' encoded as type 't'
-- <t> a[n] - means 'a' repeated n times encoded as type 'a'

-- The stream is read as a stream of "any" or a "vartuple":
-- on root level, each value is preceded by it's type.
-- Some types receive args before his value.
--
-- After the whole stream is read, the value of the last of these "any" 
-- must be already parsed.

types = {
-- basic types - fixed width
	[0] = 'typetag',
	[1] = 'varsint', -- zigzag encoded (%2 is negative bit for != 0)
 	[2] = 'varuint',
	[3] = 'int8',
	[4] = 'int16',
	[5] = 'int32',
	[6] = 'uint8',
	[7] = 'uint16',
	[8] = 'uint32',
	[10] = 'float',
	[11] = 'double',
-- basic types - variable size precedes value
	[12] = 'string', -- args: varint size
-- basic containers
	[20] = 'array', -- args: <typetag> type
	-- value: <varint> size, <type> data[size]
	[21] = 'tuple', -- args: <varint> size, <typetag> struct[size]
	-- value: <struct[1]> v1, <struct[2]> v2, ..., <struct[size]> vn
	[22] = 'vartuple', -- generic tuple: each value is preceded by it's type
		-- note: same structure as the stream itself outside other types
-- templates
	[40] = 'templateDef',
	-- args: <varint> nArgs, <typetag> TArgs[nArgs], <varint> size, <typetag> struct[size]
 		-- - TArgs tells the types of in-place args, read after typetag templateRef, 
		-- preceding value. The values of these types are read similarly as arguments 
		-- of pre-defined types. Typetag here has the same meaning as "type" on C++ templates.
		-- - struct tells the structure of the contained value. May use special typetag T_
		-- to refer to types to be defined with args to templateRef.
	-- value: '' (0 bytes) 
	[41] = 'templateRef',
	-- args: <varint> templateIndex,
	-- 	<TArgs[1]> T_1, <TArgs[2]> T_2, ..., <TArgs[nArgs] T_nArgs,
	-- value: <struct[1]> v1, <struct[2]> v2, ..., <struct[size]> vn
	-- 	note: when struct[i] == (T_, j), it is read as TArgs[j]
	[49] = 'T_', -- Reserved for use inside template defitions. Forbidden elsewhere
	-- args: <varint> argIdx -- must be < nArgs
}


