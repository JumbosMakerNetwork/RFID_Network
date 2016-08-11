#include <time.h>
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <wiringPi.h>
#include <wiringSerial.h>
#include <time.h>
#include <unistd.h>

void takePicture(char *time_file, char *rfid)
{
	char jpg[5];
	char command[192];
	time_t now = time(NULL);
	//int now_int = (int)now;
	
	strftime(time_file, 24, "%Y-%m-%d_%H:%M:%S", localtime(&now));
	strcpy(jpg, ".jpg");
	strncat(time_file, jpg, 5);

	strcpy(command, "sudo fswebcam --no-banner -r 1280x720 /home/media/");
	strncat(command, time_file, 24);
	system(command);
	/*
	strcpy(command, "curl -F 'username=dolanwill' -F 'image=@/home/media/");
	strncat(command, time_file, 24);
	strncat(command, "' https://drewbaren.com/maker/upload", 37);
	system(command);
	*/
	strcpy(command, "curl -F docfile=@/home/media/");
	strncat(command, time_file, 24);
	strcat(command, " 130.64.17.0:8000/RFID/5/5/");
	strcat(command, rfid);
	strcat(command, "/");
	strncat(command, time_file, 24);
	strcat(command, "/");
	system(command);

	strcpy(command, "rm /home/media/");
	strncat(command, time_file, 24);
	system(command);
	printf("successfully uploaded picture.\n");
}


