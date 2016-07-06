#include <time.h>

int takePicture()
{
	time_t now = time(NULL);
	int now_int = (int)now;
	return now_int;
}