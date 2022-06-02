#define LUA_LIB

#include "lua.h"
#include "lauxlib.h"
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <ws2tcpip.h>

#define CACHE_SIZE 0x1000	

static int
lconnect(lua_State *L) {
	const char * addr = luaL_checkstring(L, 1);
	const char * port = luaL_checkstring(L, 2);

	WSADATA wsaData;
	int ret = WSAStartup(MAKEWORD(2,2), &wsaData);
	if (0 != ret)
	{
		return luaL_error(L, "Startup %s %d failed", addr, port);
	}

	struct addrinfo *result = NULL;
	struct addrinfo hints;

	ZeroMemory(&hints, sizeof(hints));
	hints.ai_family = AF_INET;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_protocol = IPPROTO_TCP;

	ret = getaddrinfo(addr, port, &hints, &result);
	if (0 != ret)
	{
		return luaL_error(L, "Getaddr %s %d failed", addr, port);
	}

	SOCKET sock = socket(result->ai_family, result->ai_socktype, result->ai_protocol);
	if (INVALID_SOCKET == sock)
	{
		freeaddrinfo(result);
		return luaL_error(L, "Socket %s %d failed", addr, port);
	}

	ret = connect(sock, result->ai_addr, (int)result->ai_addrlen);
	if (SOCKET_ERROR == ret)
	{
		freeaddrinfo(result);
		closesocket(sock);
		return luaL_error(L, "Connect %s %s failed", addr, port);
	}

	freeaddrinfo(result);

	unsigned long ul = 1;
	ret=ioctlsocket(sock, FIONBIO, (unsigned long *)&ul);
	if(SOCKET_ERROR == ret)  
	{  
		closesocket(sock);
		return luaL_error(L, "Set non-blocking %s %d failed", addr, port);
	}

	lua_pushinteger(L, (int)sock);

	return 1;
}

static int
lclose(lua_State *L) {
	SOCKET sock = (SOCKET)luaL_checkinteger(L, 1);
	closesocket(sock);

	return 0;
}

static void
block_send(lua_State *L, unsigned int sock, const char * buffer, int sz) {
	while(sz > 0) {
		int ret = send(sock, buffer, sz, 0);
		if (SOCKET_ERROR == ret) {
			int err = WSAGetLastError();
			if (err == WSAEWOULDBLOCK || errno == WSAEINTR)
				continue;
			luaL_error(L, "send error: %s", strerror(err));

		}
		buffer += ret;
		sz -= ret;
	}
}

/*
	integer fd
	string message
 */
static int
lsend(lua_State *L) {
	size_t sz = 0;
	SOCKET sock = (SOCKET)luaL_checkinteger(L,1);
	const char * msg = luaL_checklstring(L, 2, &sz);

	block_send(L, sock, msg, (int)sz);

	return 0;
}

/*
	intger fd
	string last
	table result

	return 
		boolean (true: data, false: block, nil: close)
		string last
 */

struct socket_buffer {
	void * buffer;
	int sz;
};

static int
lrecv(lua_State *L) {
	SOCKET sock = (SOCKET)luaL_checkinteger(L,1);

	char buffer[CACHE_SIZE];
	int ret = recv(sock, buffer, CACHE_SIZE, 0);
	if (0 == ret) {
		lua_pushliteral(L, "");
		// close
		return 1;
	}
	if (ret < 0) {
		int err = WSAGetLastError();
		if (err == WSAEWOULDBLOCK || err == WSAEINTR) {
			return 0;
		}
		luaL_error(L, "recv error: %s", strerror(err));
	}
	lua_pushlstring(L, buffer, ret);
	return 1;
}

LUAMOD_API int
luaopen_lsocket(lua_State *L) {
	luaL_checkversion(L);
	luaL_Reg l[] = {
		{ "connect", lconnect },
		{ "recv", lrecv },
		{ "send", lsend },
		{ "close", lclose },
		{ NULL, NULL },
	};
	luaL_newlib(L, l);
	return 1;
}
