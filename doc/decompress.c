#include <lua.h>
#include <lauxlib.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

void do_unpack(
	const uint8_t * pack,
	uint8_t * unpack,
	unsigned long packsize,
	unsigned long unpacksize
) {
	const uint8_t * byteptr;
	uint8_t * exptr;
	unsigned long word;
	int nbits;
	int val;

	int ntokens = 0;
	static int offs_token [16384];
	static int len_token  [16384];
	static int org_token  [16384];

	int i;

	for (i = 0; i < 16384; ++i)
	{
		len_token [i] = 1;
		org_token [i] = -1;
	}
	memset (unpack, 0, unpacksize);

	byteptr = pack;
	exptr   = unpack;
	nbits = 0;

	while (exptr - unpack < unpacksize)
	{
		while (nbits < 14)
		{
			word = (word << 8) + *byteptr++;
			nbits += 8;
		}

		nbits -= 14;
		val = (word >> nbits) & 0x3FFF;
		if (val == 0x3FFF)
			break;

		if (val == 0x3FFE)
		{
			for (i = 0; i < 16384; ++i)
			{
				len_token [i] = 1;
				org_token [i] = -1;
			}
			ntokens = 0;
			continue;
		}

		if (ntokens < 16384)
		{
			offs_token [ntokens] = exptr - unpack;
			if (val >= 0x100)
			{
				org_token [ntokens] = val - 0x100;
			}
			++ntokens;
		}

		if (val < 0x100)
		{
			*exptr++ = val;
		} else {
			val -= 0x100;

			if (len_token [val] == 1)
			{
				if (org_token [val] != -1)
				{
					len_token [val] += len_token [org_token [val]];
				} else {
					len_token [val] += 1;
				}
			}
			for (i = 0; i < len_token [val]; ++i)
			{
				*exptr++ = unpack [i + offs_token [val]];
			}
		}
	}
}

int res_decompress(lua_State * L)
{
	uint32_t packsize, unpacksize;
	const uint8_t * pack;
	uint8_t * unpack;

	pack = (const uint8_t *)luaL_checklstring(L, 1, &packsize);
	unpacksize = luaL_checkinteger(L, 2);
	unpack = malloc(unpacksize);
	
	do_unpack(pack, unpack, packsize, unpacksize);
	
	lua_pushlstring(L, (const char *)unpack, unpacksize);
	return 1;
}

int luaopen_res_decompress(lua_State * L)
{
	lua_pushcfunction(L, res_decompress);
	return 1;
}
