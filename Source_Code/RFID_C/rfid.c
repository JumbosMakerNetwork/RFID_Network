/*
 * rfid.c
 *
 *  Created on: 06.09.2013
 *      Author: alexs
 *		Edited by Will Dolan, June 2016
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <syslog.h>
#include <sys/wait.h>
#include <signal.h>
#include <bcm2835.h>
#include "rc522.h"
#include "rfid.h"

uint8_t buff[MAXRLEN];

void init_RFID()
{
	uint8_t gpio=255;
	uint32_t spi_speed=10000000L;
	if (HW_init(spi_speed,gpio)) fprintf(stderr, "HW init failure\n"); // Если не удалось инициализировать RC522 выходим.
	InitRc522();
}

void RFID_end()
{
	bcm2835_spi_end();
	bcm2835_close();
}

int look_for_RFID()
{
	uint16_t CType=0;
	char status = find_tag(&CType);
	if(status != TAG_OK) {
		return 0;
	}
	return 1;
}

int get_RFID(char *sn_str)
{
	uint8_t SN_len=0;
	int tmp;
	char *p;
	uint8_t SN[10];
	p=sn_str;	
	if(select_tag_sn(SN,&SN_len)!=TAG_OK) fprintf(stderr, "card read error.\n");

	//edited this for loop to print in little endian order
	for (tmp=SN_len-1;tmp>=0;tmp--) {
		sprintf(p,"%02x",SN[tmp]);
		p+=2;
	}
	*p=0;
	return 1;
}

void RFID_refresh()
{
	PcdHalt();
}

int RFID_comparison(char *RFID_UID)
{
	if(!look_for_RFID()){
		printf("no RFID found when comparing.\n");
		return 0;
	}
	char *new_RFID = (char *)calloc(10,1);
	get_RFID(new_RFID);
	printf("reading card: %s\n", new_RFID);
	int cmp = strcmp(RFID_UID, new_RFID);
	free(new_RFID);
	return cmp;
}

uint8_t HW_init(uint32_t spi_speed, uint8_t gpio) {
	uint16_t sp;

	sp=(uint16_t)(250000L/spi_speed);
	if (!bcm2835_init()) {
		fprintf(stderr, "Can't init bcm2835!\n");
		return 1;
	}
	if (gpio<28) {
		bcm2835_gpio_fsel(gpio, BCM2835_GPIO_FSEL_OUTP);
		bcm2835_gpio_write(gpio, LOW);
	}

	bcm2835_spi_begin();
	bcm2835_spi_setBitOrder(BCM2835_SPI_BIT_ORDER_MSBFIRST);      // The default
	bcm2835_spi_setDataMode(BCM2835_SPI_MODE0);                   // The default
	bcm2835_spi_setClockDivider(sp); // The default
	bcm2835_spi_chipSelect(BCM2835_SPI_CS0);                      // The default
	bcm2835_spi_setChipSelectPolarity(BCM2835_SPI_CS0, LOW);      // the default
	return 0;
}

tag_stat find_tag(uint16_t * card_type) {
	tag_stat tmp;
	if ((tmp=PcdRequest(PICC_REQIDL,buff))==TAG_OK) {
		*card_type=(int)(buff[0]<<8|buff[1]);
	}
	return tmp;
}

tag_stat select_tag_sn(uint8_t * sn, uint8_t * len){

	if (PcdAnticoll(PICC_ANTICOLL1,buff)!=TAG_OK) {return TAG_ERR;}
	if (PcdSelect(PICC_ANTICOLL1,buff)!=TAG_OK) {return TAG_ERR;}
	if (buff[0]==0x88) {
		memcpy(sn,&buff[1],3);
		if (PcdAnticoll(PICC_ANTICOLL2,buff)!=TAG_OK) {
			return TAG_ERR;}
		if (PcdSelect(PICC_ANTICOLL2,buff)!=TAG_OK) {return TAG_ERR;}
		if (buff[0]==0x88) {
			memcpy(sn+3,&buff[1],3);
			if (PcdAnticoll(PICC_ANTICOLL3,buff)!=TAG_OK) {
				return TAG_ERR;}
			if (PcdSelect(PICC_ANTICOLL3,buff)!=TAG_OK) {return TAG_ERR;}
			memcpy(sn+6,buff,4);
			*len=10;
		}else{
			memcpy(sn+3,buff,4);
			*len=7;
		}
	}else{
		memcpy(sn,&buff[0],4);
		*len=4;
	}
	return TAG_OK;
}

tag_stat read_tag_str(uint8_t addr, char * str) {
	tag_stat tmp;
	char *p;
	uint8_t buff[MAXRLEN];
	int i = 16;

	tmp=PcdRead(addr,buff);
	p=str;
	if (tmp==TAG_OK) {
		for (i=16;i>=0;i--) {
			sprintf(p,"%02x",(char)buff[i]);
			p+=2;
		}
	}else if (tmp==TAG_ERRCRC){
		sprintf(p,"CRC Error");
	}else{
		sprintf(p,"Unknown error");
	}
	return tmp;
}


