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
lget_pressed(lua_State *L) {
	DWORD cNumRead, fdwSaveOldMode, fdwMode, i;
	INPUT_RECORD irInBuf[128];

	// Get the standard input handle.
	HANDLE hStdin = GetStdHandle(STD_INPUT_HANDLE);
	if (hStdin == INVALID_HANDLE_VALUE)
		return luaL_error(L, "GetStdHandle failed");

	// Save the current input mode, to be restored on exit.
	if (! GetConsoleMode(hStdin, &fdwSaveOldMode) )
        		return luaL_error(L, "GetConsoleMode failed");

    	// Enable the window input events.
	fdwMode = ENABLE_WINDOW_INPUT;
    	if (! SetConsoleMode(hStdin, fdwMode) )
        		return luaL_error(L, "SetConsoleMode failed");

	if (! ReadConsoleInput(
                	hStdin,      // input buffer handle
                	irInBuf,     // buffer to read into
                	128,         // size of read buffer
                	&cNumRead) ) // number of records read
            		return luaL_error(L, "ReadConsoleInput failed");

	char buffer[128];
	memset(buffer, 0, sizeof(buffer));
	int count = 0;

        	for (i = 0; i < cNumRead; i++)
        	{
            		switch(irInBuf[i].EventType)
            		{
                	case KEY_EVENT: // keyboard input
			if (!irInBuf[i].Event.KeyEvent.bKeyDown) {
				WORD vCode = irInBuf[i].Event.KeyEvent.wVirtualKeyCode;
				if (vCode == VK_ESCAPE) {
					buffer[count++] = 'e';
				} else if (vCode == VK_SPACE) {
					buffer[count++] = 'p';
				} else {
					char c = irInBuf[i].Event.KeyEvent.uChar.AsciiChar;
					if (c != ' ' && c != 'e') {
						buffer[count++] = c;
					}
				}
			}
                    		break;

                	case WINDOW_BUFFER_SIZE_EVENT: // disregard buf. resizing
                    		break;

                	case FOCUS_EVENT:  // disregard focus events
			break;

                	case MENU_EVENT:   // disregard menu events
                    		break;

                	default:
                    		return luaL_error(L, "Unknown event type");
                    		break;
            		}
        	}

	lua_pushlstring(L, buffer, count);
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
		{ "get_pressed", lget_pressed },
		{ "sleep", lsleep },
		{ NULL, NULL },
	};
	luaL_newlib(L, l);
	return 1;
}