
#include <stdio.h>
#include <windows.h>

CHAR szCommName [] = "\\\\.\\COM7";
BYTE Buff [16];

HANDLE hComm = INVALID_HANDLE_VALUE;
BOOL usend (int n);
BOOL urecv (int n);

int __cdecl main ()
{
	COMMCONFIG ComCfg;
	COMMPROP CommProp;
	DCB Dcb;
	COMMTIMEOUTS CommTimeouts;
	DWORD dwSize, dw;
	BOOL bRes;
	int i, j;
	FILE *f_rom;
	size_t n;
__try {
	hComm = CreateFile (szCommName, GENERIC_READ | GENERIC_WRITE, 0, NULL, OPEN_EXISTING,
		0, NULL);
	if (hComm == INVALID_HANDLE_VALUE) {
		puts ("COM: open error.");
		return 1;
	}
	puts ("COM: open OK.");
	urecv (1);
	if (Buff [0] == 0x55)
		puts ("Start byte OK.");
	else {
		printf ("Start byte error (%02x).\n", Buff [0]);
		return 1;
	}
	urecv (2);
	printf ("SPL = %02x  SPH = %02x\n", Buff [0], Buff [1]);
	Buff [0] = 0x0C; Buff [1] = 0x01;
	usend (2);
	urecv (2);
	Buff [0] = 0x0F; Buff [1] = 0x01;
	usend (2);
	urecv (2);
	Sleep (1000);
	Buff [0] = 0x0F; Buff [1] = 0x00;
	usend (2);
	urecv (2);
	Sleep (1000);
	Buff [0] = 0x01; Buff [1] = 0xD3;
	usend (2);
	urecv (2);
	printf ("echo %02x %02x\n", Buff [0], Buff [1]);
	for (i = 0; i < 100; i++) {
		printf ("i = %2d\n", i);
		Buff [0] = (rand() & 8-1)+1;
		Buff [1] = rand() & 0xff;
		usend (2);
		urecv (2);
	}
	for (j = 0; j < 4; j++) {
		for (i = 0; i < 16; i++) {
			printf ("i = %2d\n", i);
			Buff [0] = 0x0A;
			Buff [1] = i;
			usend (2);
			urecv (2);
		}
		for (i = 15; i >= 0; i--) {
			printf ("i = %2d\n", i);
			Buff [0] = 0x0A;
			Buff [1] = i;
			usend (2);
			urecv (2);
		}
	}
} __finally {
	if (hComm != INVALID_HANDLE_VALUE) CloseHandle (hComm);
}
	return 0;
}

BOOL usend (int n)
{
	DWORD dw;
	BOOL bRes;
	bRes = WriteFile (hComm, Buff, n, &dw, NULL);
	if (!bRes)
		printf ("COM: send error (%d bytes).\n", n);
	return bRes;
}

BOOL urecv (int n)
{
	DWORD dw;
	BOOL bRes;
	bRes = ReadFile (hComm, Buff, n, &dw, NULL);
	if (!bRes)
		printf ("COM: receive error (%d bytes).\n", n);
	return bRes;
}
