-- How the bytestream is described on comments:
-- <t> a - means 'a' encoded as type 't'
-- <t> a[n] - means 'a' is an array of 'n' values encoded as type 'a'

-- The stream is read as a stream of "any" or a "vartuple":
-- on root level, each value is preceded by its type.
-- Some types receive args before his value.
--
-- After the whole stream is read, the value of the last of these "any"
-- must be already parsed.

types = {
-- basic types - fixed width
	[0x0] = 'typetag', -- indicates how to calculate the size of a value
		-- A value of type typetag starts with a byte containing one
		-- of the values on this table.
		-- If the most significant bit of this byte is set, this
		-- typetag has size >1. This size depends on the number and
		-- size of arguments of this tag.

	[0x1] = 'varsint', -- zigzag encoded (%2 is negative bit for != 0)
	[0x2] = 'varuint',
	[0x3] = 'int8',
	[0x4] = 'int16',
	[0x5] = 'int32',
	[0x6] = 'uint8',
	[0x7] = 'uint16',
	[0x8] = 'uint32',
	[0x10] = 'double',
	[0x11] = 'float',
-- basic types - variable size precedes value
	[0x12] = 'string', -- value: varint size
-- basic containers
	[0x80] = 'array', -- args: <typetag> type
	-- value: <varint> size, <type> data[size]
	[0x81] = 'tuple', -- args: <varint> size, <typetag> struct[size]
	-- value: <struct[1]> v1, <struct[2]> v2, ..., <struct[size]> vn
	[0x82] = 'vartuple', -- generic tuple: each value is preceded by it's type
		-- note: same structure as the stream itself outside other types
-- templates
	[0xa0] = 'templateDef',
	-- Tuple-like supporting compact definition of many "any"s that will share the same typetag
	-- args: <varint> nArgs, <typetag> TArgs[nArgs], <varint> size, <typetag> struct[size]
		-- - TArgs tells the types of in-place args, read after typetag templateRef,
		-- preceding value. The values of these types are read similarly as arguments
		-- of pre-defined types. Typetag here has the same meaning as "type" on C++ templates.
		-- - struct tells the structure of the contained value. May use special typetag T_
		-- to refer to types to be defined with args to templateRef.
	-- value: '' (0 bytes)
	[0xa1] = 'templateRef',
	-- args: <varint> templateIndex,
	-- 	<typetag> TArgs[nArgs] T_V,
	-- value: <struct[1]> v1, <struct[2]> v2, ..., <struct[size]> vn
	-- 	note: when struct[i] == (T_, j), it is read as TArgs[j]
	[0xaa] = 'T_', -- Reserved for use inside template defitions. Forbidden elsewhere
	-- args: <varint> argIdx -- must be < nArgs
}

--[[
Exemplos:

Tipo aluno(matricula, nome, turmas[])
como aluno(111111, 'Joao',[turma('33F', 'INF1010'), ...])

<typetag> t = tuple,
--tuple args(
	<varint> size = 3,
	<typetag> struct[0] = uint32,
	<typetag> struct[1] = string,
	<typetag> struct[2] = array,
	--array args(
		<typetag> t = tuple,
		--tuple args(
			<varint> size = 2,
			<typetag> struct[0] = string,
			<typetag> struct[1] = string,
		--)
	--)
--) tuple value(
	<uint32> value = 111111 ,
	<string> value = 'Joao',
	--array value(
	<varint> size = 3,
		--tuple value(
		<string> value = '33F', <string> value = 'INF1010',
		--) tuple value(
		<string> value = '33D', <string> value = 'FIS1041',
		--) tuple value(
		<string> value = '3A0', <string> value = 'MAT1025',
		--)
	--)
--)


Tipo aluno(matricula, nome, turmas[]) definido com um template com T_ no lugar de strings

<typetag> t = template -- Declara um template para aluno
--template args(
	<varint> nArgs = 1,    -- tamanho de TArgs
	<varint> size = 3,     -- tamanho de struct
	<typetag> struct[0] = uint32,
	<typetag> struct[1] = T_
	--T_ args(
		<varint> 1 -- T_1
	--)
	<typetag> struct[2] = array,
	--array args(
		<typetag> t = tuple,
		--tuple args(
			<varint> size = 2,
			<typetag> struct[0] = T_
			--T_ args(
				<varint> 1 -- T_1
			--)
			<typetag> struct[1] = T_
			--T_ args(
				<varint> 1 -- T_1
			--)
		--)
	--)
--)

<typetag> t = templateRef -- Usa o template de aluno com wstring
--templateRef args(
	<varint> idx = 1 -- Índice do template de aluno
	<typetag> T_1 = wstring
--templateRef value(
	<uint32> value = 111111,
	<wstring> value = 'Joao',
	--array value(
	<varint> size = 3,
		--tuple value(
		<wstring> value = '33F', <wstring> value = 'INF1010',
		--) tuple value(
		<wstring> value = '33D', <wstring> value = 'FIS1041',
		--) tuple value(
		<wstring> value = '3A0', <wstring> value = 'MAT1025',
		--)
	--)
--)

]]--


