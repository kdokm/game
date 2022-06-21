#define LUA_LIB

#include "lua.h"
#include "lauxlib.h"
#include <windows.h>
#include <conio.h>

HANDLE hStdout, hOutBuf;

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
	DWORD cNum, cNumRead, fdwSaveOldMode, fdwMode, i;
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

	if (! GetNumberOfConsoleInputEvents(hStdin, &cNum) )
		return luaL_error(L, "GetNumberOfConsoleInputEvents failed");

	char buffer[128];
	memset(buffer, 0, sizeof(buffer));
	int count = 0;

	if (cNum > 0) {
		if (! ReadConsoleInput(
                		hStdin,      // input buffer handle
                		irInBuf,     // buffer to read into
                		128,         // size of read buffer
                		&cNumRead) ) // number of records read
	            		return luaL_error(L, "ReadConsoleInput failed");

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
						if (c != 'e' && c != 'p') {
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
	}

	SetConsoleMode(hStdin, fdwSaveOldMode);

	lua_pushlstring(L, buffer, count);
	return 1;
}

static int
lget_time(lua_State *L) {
	long long time = GetTickCount();
	lua_pushinteger(L, time);
	return 1;
}

static int
lsleep(lua_State *L) {
	long long pre = luaL_checkinteger(L, 1);
	int n = luaL_checkinteger(L, 2);
	long long time = GetTickCount();
	int diff = n-(int)(time-pre);
	if (diff > 0) {
		Sleep(diff);
	}
	lua_pushinteger(L, time+diff);
	return 1;
}

static int
lset_buffer(lua_State *L) {
	hStdout = GetStdHandle(STD_OUTPUT_HANDLE);
	hOutBuf = CreateConsoleScreenBuffer(
        		GENERIC_READ | GENERIC_WRITE, 
        		FILE_SHARE_READ | FILE_SHARE_WRITE, 
        		NULL, 
        		CONSOLE_TEXTMODE_BUFFER, 
        		NULL
    	);
	SetConsoleActiveScreenBuffer(hOutBuf);

	CONSOLE_CURSOR_INFO cci;
    	cci.bVisible=0;
    	cci.dwSize=1;
    	SetConsoleCursorInfo(hOutBuf, &cci);
	return 0;
}

void cls(HANDLE hConsole)
{
    	CONSOLE_SCREEN_BUFFER_INFO csbi;
    	SMALL_RECT scrollRect;
	COORD scrollTarget;
    	CHAR_INFO fill;

	// Get the number of character cells in the current buffer.
    	if (!GetConsoleScreenBufferInfo(hConsole, &csbi))
    	{
        		return;
    	}

	// Scroll the rectangle of the entire buffer.
    	scrollRect.Left = 0;
    	scrollRect.Top = 0;
    	scrollRect.Right = csbi.dwSize.X;
    	scrollRect.Bottom = csbi.dwSize.Y;

    	// Scroll it upwards off the top of the buffer with a magnitude of the entire height.
    	scrollTarget.X = 0;
    	scrollTarget.Y = (SHORT)(0 - csbi.dwSize.Y);

    	// Fill with empty spaces with the buffer's default text attribute.
    	fill.Char.UnicodeChar = TEXT(' ');
    	fill.Attributes = csbi.wAttributes;

	// Do the scroll
    	ScrollConsoleScreenBuffer(hConsole, &scrollRect, NULL, scrollTarget, &fill);
}

static int
lwrite_buffer(lua_State *L) {
	int flag = luaL_checkinteger(L, 1);
	char data[6400];
	COORD coord = { 0, 0 };
	DWORD bytes = 0;
	ReadConsoleOutputCharacterA(hStdout, data, 6400, coord, &bytes);
            	WriteConsoleOutputCharacterA(hOutBuf, data, 6400, coord, &bytes);
	if (flag) {
		cls(hStdout);
	}
	return 0;
}

LUAMOD_API int
luaopen_lcontrol(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "jump", ljump },
		{ "get_pressed", lget_pressed },
		{ "get_time", lget_time },
		{ "sleep", lsleep },
		{ "set_buffer", lset_buffer },
		{ "write_buffer", lwrite_buffer },
		{ NULL, NULL },
	};
	luaL_newlib(L, l);
	return 1;
}