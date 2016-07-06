/*
 * led_gpio.h
 *
 *		 by Will Dolan, June 2016
 */

#ifndef LEDGPIO_H_
#define LEDGPIO_H_

void   init_GPIO();
int readHelp(int initHelpState);
int readPhoto(int initPhotoState);
time_t beginUse(char *resp) ;
int    endUse(time_t start_time);
void   rejectUse();
void   noUserHandler();
void   contact_admin();
void   sendHelp();
char  *getName(char *response);

#endif /* LEDGPIO */
