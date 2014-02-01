--[[
LUA_PATH = "..\\common\\?.lua;..\\utils\\?.lua"
require('3disAsm')
c = new['3dModel']() fin = assert(io.open('..\\utils\\OBJ3D.RES/0940.0F','rb')) s = fin:read("*a") fin:close()
c:Init(s)
]]

assert(loadlib('../bin/lbitlib.dll','luaopen_bit'))()
LUA_PATH = "../common/?.lua"
require('classes')
require('stdlib')

class('3dModel',{
	VERTEX = { n=0; };
	POLY = { n=0; };
	faceCount = 0;

	-- disassemble model data stream and create faces and vertices from it

	-- ctor
	['3dModel'] = function(this, chunk)
		if chunk then
			this:Init(chunk)
		end
		return this
	end;

	Init = function(this, chunk)
		print(this, chunk)
		if not chunk then return 0 end
		local i = 9
		faceCount = sreadint(string.sub(chunk,7),2)
		print(string.len(chunk))
		while i <= string.len(chunk) do
			local op = sreadint(string.sub(chunk,i),2)
			print("-->",i,op)
			if decode[op] then
				setfenv(decode[op],this)
				local r = decode[op](string.sub(chunk,i+2))
				if not r or r < 1 then error("FOAM IN MY BRAIN") end
				i = i + r
				--print("Thingy.")
			else
				error("Unknown opcode "..op)
				--print("Unknown opcode.")
			end
		end
		return 3
	end;


	-- master disassembler table
	decode = {
		[00] = function(fin)	-- END OF SUB-HULL
			printf("0000\tEND FACE\n")
			return 2
		end;
		[01] = function(fin)	-- DEFINE FACE
			local n = sreadint(fin,2)
			local x,y,z
			printf("0001\tDEFINE FACE (%u bytes)\n",n)
			x,y,z
			= sreadint(fin, 4,4,4)
			printf("    : normal (%u, %u, %u)\n", x,y,z)
			x,y,z
			= sreadint(fin, 4,4,4)
			printf("    : refpt  (%u, %u, %u)\n", x,y,z)
			return 28
		end;
		[03] = function(fin)	-- DEFINE MULTIPLE VERTICES
			local n = sreadint(fin,2)
			local x,y,z
			printf("0003\tDEFINE %u VERTICES\n", n)
			for i=1,n,1 do
				x,y,z
				= sreadint(fin, 4,4,4)
				printf("    : (%u, %u, %u)\n", x,y,z)
				VERTEX[VERTEX.n] = { x=x,y=y,z=z }
				VERTEX.n = VERTEX.n +1
			end
			return 4+12*n
		end;
		[04] = function(fin)	-- DRAW FLAT-SHADED POLY
			local n = sreadint(fin,2)
			local p = {}
			printf("0004\tDRAW FLAT-SHADED POLYGON: %u vertices\n    : ",n)
			for i=1,n,1 do
				local v = sreadint(string.sub(fin,1+i*2), 2)
				printf("%u ", v)
				table.insert(p,VERTEX[v])
			end
			table.insert(POLY,p)
			print()
			return 4+2*n
		end;
		[05] = function(fin)	-- SET FLAT-SHADED POLY COLOR
			local c = sreadint(fin,2)
			printf("0005\tSET SHADE COLOR: %u\n",c)
			return 4
		end;
		[10] = function(fin)	-- DEFINE VERTEX WITH X REFERENT
			local i,r,x
			 = sreadint(fin,2,2,4)
			printf("000A\tDEFINE VERTEX #%u WITH X REFERENT\n", i)
			printf("    : #%u + (%u, 0, 0)\n", r, x)
			VERTEX[i] = {
				x=x+	VERTEX[r].x,
				y=		VERTEX[r].y,
				z=		VERTEX[r].z
			}
			return 10
		end;
		[11] = function(fin)	-- DEFINE VERTEX WITH Y REFERENT
			local i,r,y
			 = sreadint(fin,2,2,4)
			printf("000A\tDEFINE VERTEX #%u WITH Y REFERENT\n", i)
			printf("    : #%u + (0, %u, 0)\n", r, y)
			VERTEX[i] = {
				x=		VERTEX[r].x,
				y=y+	VERTEX[r].y,
				z=		VERTEX[r].z
			}
			return 10
		end;
		[12] = function(fin)	-- DEFINE VERTEX WITH Z REFERENT
			local i,r,z
			 = sreadint(fin,2,2,4)
			printf("000A\tDEFINE VERTEX #%u WITH Z REFERENT\n", i)
			printf("    : #%u + (0, 0, %u)\n", r, z)
			VERTEX[i] = {
				x=		VERTEX[r].x,
				y=		VERTEX[r].y,
				z=z+	VERTEX[r].z
			}
			return 10
		end;
		[13] = function(fin)	-- DEFINE VERTEX WITH X,Y REFERENTS
			local i,r,x,y
			 = sreadint(fin,2,2,4,4)
			printf("000A\tDEFINE VERTEX #%u WITH X,Y REFERENTS\n", i)
			printf("    : #%u + (%u, %u, 0)\n", r, x, y)
			VERTEX[i] = {
				x=x+	VERTEX[r].x,
				y=y+	VERTEX[r].y,
				z=		VERTEX[r].z
			}
			return 14
		end;
		[14] = function(fin)	-- DEFINE VERTEX WITH X,Z REFERENTS
			local i,r,x,z
			 = sreadint(fin,2,2,4,4)
			printf("000A\tDEFINE VERTEX #%u WITH X,Z REFERENTS\n", i)
			printf("    : #%u + (%u, 0, %u)\n", r, x, z)
			VERTEX[i] = {
				x=x+	VERTEX[r].x,
				y=		VERTEX[r].y,
				z=z+	VERTEX[r].z
			}
			return 14
		end;
		[15] = function(fin)	-- DEFINE VERTEX WITH Y,Z REFERENTS
			local i,r,y,z
			 = sreadint(fin,2,2,4,4)
			printf("000A\tDEFINE VERTEX #%u WITH Y,Z REFERENTS\n", i)
			printf("    : #%u + (0, %u, %u)\n", r, y, z)
			VERTEX[i] = {
				x=		VERTEX[r].x,
				y=y+	VERTEX[r].y,
				z=z+	VERTEX[r].z
			}
			return 14
		end;
		[28] = function(fin)	-- SET COLOR/SHADE
			local c,s = sreadint(fin,2,2)
			printf("0001C\tSET COLOR AND SHADE: %u, %u\n",c,s)
			return 6
		end;
	};
})

