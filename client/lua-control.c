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
lcheck_pressed(lua_State *L) {
	const int key = luaL_checkinteger(L, 1);
	lua_pushboolean(L, GetAsyncKeyState(key)&1);
	return 1;
}

static int
lsleep(lua_State *L) {
	int n = luaL_checknumber(L, 1);
	Sleep(n);
	return 0;
}

LUAMOD_API int
luaopen_lcontrol(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "jump", ljump },
		{ "check_pressed", lcheck_pressed },
		{ "sleep", lsleep },
		{ NULL, NULL },
	};
	luaL_newlib(L, l);
	return 1;
}