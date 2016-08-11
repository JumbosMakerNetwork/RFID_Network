/*
 * rfid_gpio.h
 *
 *		 by Will Dolan, June 2016
 */

#ifndef RFIDGPIO_H_
#define RFIDGPIO_H_

void   beginUse(char *resp);
void   rejectUse();
void   endUse();
void   noUserHandler();

#endif /* RFIDGPIO */
