#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "sock.h"

const int size = 4096;

void send_packed_str(SOCKET sock, unsigned char* buf, char *init, const unsigned int len) {
	unsigned char lsb = len & 0xff;
    unsigned char msb = len >> 8;
    buf[0] = msb;
    buf[1] = lsb;
    memcpy(buf+2, reinterpret_cast<unsigned char*>(init), len);
    int ret = send(sock, reinterpret_cast<char*>(buf), len+2, 0);
	if (SOCKET_ERROR == ret) {
		printf("send fails: %d", WSAGetLastError());
		closesocket(sock);
		exit(1);
	}
	memset(buf, 0, len+2);
}

int main(int argc, char *argv[])
{

	//tcp socket
    WSADATA wsaData;
	int ret = WSAStartup(MAKEWORD(2,2), &wsaData);
	if (0 != ret)
	{
		printf("init fails\n");
        exit(1);
	}

    struct addrinfo *result = NULL;
	struct addrinfo hints;

	ZeroMemory(&hints, sizeof(hints));
	hints.ai_family = AF_INET;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_protocol = IPPROTO_TCP;

    char ip[100];
    strcpy(ip, "127.0.0.1");
	char port[100];
	strcpy(port, "8888");

	ret = getaddrinfo(ip, port, &hints, &result);
	if (0 != ret)
	{
		printf("getaddr fails\n");
        exit(1);
	}

    SOCKET sock = socket(result->ai_family, result->ai_socktype, result->ai_protocol);
    if (INVALID_SOCKET == sock)
	{
        freeaddrinfo(result);
		printf("socket fails\n");
        exit(1);
	}

    ret = connect(sock, result->ai_addr, (int)result->ai_addrlen);
	if (SOCKET_ERROR == ret)
	{
		freeaddrinfo(result);
		closesocket(sock);
		printf("socket fails\n");
        exit(1);
	}

    freeaddrinfo(result);

    unsigned char buf[size];
    memset(buf, 0, sizeof(buf));
	unsigned char msg[size];
	memset(msg, 0, sizeof(msg));

    char init[size];
    char temp[size];
    system("cls");
    printf("Welcome to the game! Please enter V to verify your account or enter C to create a new account: ");
    scanf("%s", temp);
    while (strlen(temp) != 1 || (strncmp(temp, "V", 1) != 0 && strncmp(temp, "C", 1) != 0)) {
        printf("Invalid option, please enter again.\n");
        scanf("%s", temp);
    }
    strcpy(init, temp);
    printf("\nPlease enter your id: ");
    scanf("%s", temp);
    strcat(init, temp);
    printf("Please enter your password: ");
    scanf("%s", temp);
    strcat(init, "\n");
    strcat(init, temp);
    unsigned int len = strlen(init);
    send_packed_str(sock, buf, init, len);
    while (true)
    {
		/*
		while (true) {
			recv(sock, buf, sizeof(buf), 0);
			strcat(msg, buf);
			if (strchr(buf, '\n') != nullptr)
			{
				break;
			}
			memset(buf, 0, sizeof(buf));
		}
		memset(buf, 0, sizeof(buf));
        printf("received: %s\n", msg);
        memset(msg, 0, sizeof(msg));

		*/
    }
	closesocket(sock);
    return 0;
}
