/*
 * main.c
 *	
 *  by Will Dolan, June 2016
 */

#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include "rfid.h"
#include "curl_req.h"
#include "led_gpio.h"
 #include "camera.h"

#define stid "5"

/* Main :
 *      First, initialize RFID and GPIO components
 *      Then, enter loop. Wait for RFID, then 
 *      send a request to JMN DB w/ RFID, then take appropriate action
 *      based on response. Look for help button depress throughout.
*/
int main(void)
{       
        char *RFID_UID = (char *)calloc(10,1);
        char *JMN_resp = (char *)calloc(128,1);
        init_RFID();
        init_GPIO();
        int status = 0;
        int use_time = 0;
        int photo_time = 0;
        char use_time_s[16];
        char photo_time_s[16];
        int initHelpState = readHelp(0);
        int initPhotoState = readPhoto(0);
	
	while(1) {
		status = look_for_RFID();

                if(status == 1){
                        get_RFID(RFID_UID);
                        printf("New tag: %s\n", RFID_UID);
        		ReqJMN(JMN_resp, RFID_UID, "1", "begin", stid);

        		if (strchr(JMN_resp,'T') != NULL) {
                                time_t begin_t = beginUse(JMN_resp);
                                while(status == 1){
                                        if(readHelp(initHelpState) == 1){
                                                sendHelp(RFID_UID);
                                                ReqJMN(JMN_resp, RFID_UID, "4", "help_email", stid);
                                        }
                                        if(readPhoto(initPhotoState) == 1){
                                                photo_time = takePicture();
                                                sprintf(photo_time_s, "%d", photo_time);
                                                ReqJMN(JMN_resp, RFID_UID, "5", "123", stid);
                                        }
                                        status = look_for_RFID();
                                        status = look_for_RFID();
                                        //need to call twice! don't touch.****
                                }
                                use_time = endUse(begin_t);
                                sprintf(use_time_s, "%d", use_time);
                                ReqJMN(JMN_resp, RFID_UID, "2", use_time_s, stid);
                        }

                        else if (strchr(JMN_resp,'E') != NULL) {
        			rejectUse();
        		} 
                        else noUserHandler();

                        RFID_refresh();
                }
                
                if(readHelp(initHelpState) == 1) {
                        contact_admin();
                        ReqJMN(JMN_resp, "0", "4", "contact_admin", stid);
                }
	}
        RFID_end();
        free(RFID_UID);
        free(JMN_resp);
        return 0;
}

//char *ReqJMN(char *RFID, char *req, char *info, char* station);

