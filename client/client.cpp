#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

const int size = 4096;

void send_packed_str(int sock, unsigned char* buf, char *init, const unsigned int len) {
	unsigned char lsb = len & 0xff;
    unsigned char msb = len >> 8;
    buf[0] = msb;
    buf[1] = lsb;
    memcpy(buf+2, reinterpret_cast<unsigned char*>(init), len);
    send(sock, buf, len+2, 0);
	memset(buf, 0, len+2);
}

int main(int argc, char *argv[])
{

	//tcp socket
    int sock = socket(AF_INET, SOCK_STREAM, 0);

    struct sockaddr_in saddr;
    memset(&saddr, 0, sizeof(saddr));
    saddr.sin_family = AF_INET;
    saddr.sin_port = htons(8888);
    saddr.sin_addr.s_addr = inet_addr("127.0.0.1");

    if (connect(sock, (struct sockaddr*)&saddr, sizeof(saddr)) < 0)
    {
        printf("connect fails\n");
        exit(1);
    }

    unsigned char buf[size];
    memset(buf, 0, sizeof(buf));
	unsigned char msg[size];
	memset(msg, 0, sizeof(msg));

    char init[size];
    memset(init, 0, sizeof(init));
    char temp[size];
    printf("Welcome to the game! Please enter V to verify your account or enter C to create a new account: ");
    scanf("%s", temp);
    while (strlen(temp) != 1 || (strncmp(temp, "V", 1) != 0 && strncmp(temp, "C", 1) != 0)) {
        printf("Invalid option, please enter again.\n");
        scanf("%s", temp);
    }
    strcat(init, temp);
    printf("Please enter your id: ");
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
		/*sprintf(buf, "%c%cCkkk\npw", ++count);
		printf("sending: %s", buf);
		send(sock, buf, strlen(buf), 0);
		memset(buf, 0, sizeof(buf));

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

		if (count == 10) {
			sprintf(buf, "exit\n");
			send(sock, buf, strlen(buf), 0);
			break;
		}*/
    }
	close(sock);
    return 0;
}
