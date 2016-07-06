/*
 * rfid.h
 *
 *  Created on: 06.09.2013
 *      Author: alexs
 *		edited by Will Dolan, June 2016
 */

#ifndef RFID_H_
#define RFID_H_

#include "rc522.h"
#include <stdint.h>

tag_stat find_tag(uint16_t *);
tag_stat select_tag_sn(uint8_t * sn, uint8_t * len);
tag_stat read_tag_str(uint8_t addr, char * str);
uint8_t HW_init(uint32_t spi_speed, uint8_t gpio);
int look_for_RFID();
int get_RFID(char *sn_str);
int RFID_comparison(char *RFID_UID);
void RFID_refresh();
void init_RFID();
void RFID_end();

#endif /* RFID_H_ */
