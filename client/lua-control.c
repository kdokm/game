#define LUA_LIB

#include "lua.h"
#include "lauxlib.h"
#include <windows.h>
#include <conio.h>

static int
ljump(lua_State *L) {
	const int x = luaL_checkinteger(L, 1);
	const int y = luaL_checkinteger(L, 2);
	COORD pos;
	pos.X = x;
	pos.Y = y;
	HANDLE handle = GetStdHandle(STD_OUTPUT_HANDLE);
	SetConsoleCursorPosition(handle, pos);
	return 0;
}

static int
lget_key_state(lua_State *L) {
	const int key = luaL_checkinteger(L, 1);
	lua_pushinteger(L, GetAsyncKeyState(key));
	return 1;
}

LUAMOD_API int
luaopen_control(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "jump", ljump },
		{ "get_key_state", lget_key_state },
		{ NULL, NULL },
	};
	luaL_newlib(L, l);
	return 1;
}