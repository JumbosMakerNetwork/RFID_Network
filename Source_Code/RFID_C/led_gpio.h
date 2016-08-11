/*
 * led_gpio.h
 *
 *		 by Will Dolan, June 2016
 */

#ifndef LEDGPIO_H_
#define LEDGPIO_H_

// General init/mem control
void   init_GPIO();
void   GPIO_end();
void   displayIP(char input[]);
void activate_LCD();

// GPIO input
int    readHelp(int initHelpState);
int    readPhoto(int initPhotoState);

// control flow
time_t beginUse(char *resp);
int    endUse(time_t start_time);
void   rejectUse();
void   noUserHandler();
void   contact_admin();
void   sendHelp();

// LCD utils
void   getName(char *name_buff, char *response);
void   center(char *buff, char *toCenter);
void   display(char *line1, char *line2);

#endif /* LEDGPIO */
