/*
 * HW_GPIO.c
 *	
 *  by Will Dolan, June 2016
 */

#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <wiringPi.h>
#include <wiringSerial.h>
#include <time.h>
 #include <unistd.h>
#include "led_gpio.h"

 #define greenLED 29
 #define redLED	  28
 #define relayPin 27
 #define LCD_3v3  1
 #define HELP_BUTTON 24
 #define PHOTO_BUTTON 25

int LCD;
char *LCD_buff1;
char *LCD_buff2;

// Returns the device address of the LCD monitor, or -1 if failure
void init_GPIO()
 {
        wiringPiSetup();
	pinMode(greenLED, OUTPUT);     
	pinMode(redLED, OUTPUT);    
        pinMode(relayPin, OUTPUT); 
        pinMode(HELP_BUTTON, INPUT);
        pinMode(LCD_3v3, OUTPUT);
        digitalWrite(LCD_3v3, LOW);  
        printf("Pi initialized, ready for RFID.\n");
 }

 void activate_LCD()
 {
        LCD_buff1 = (char *)calloc(16, 1);
        LCD_buff2 = (char *)calloc(16, 1);
        digitalWrite(LCD_3v3, HIGH); 
        delay(100);
        if ((LCD = serialOpen ("/dev/ttyAMA0", 9600)) < 0) {
                fprintf (stderr, "Unable to open serial device: %s\n", strerror (errno)) ;
                return;
        }
	char clearcmd[2] = { 254, 1 };
        write(LCD, clearcmd, 2);

        display("Welcome,", "Terminal ready.");
        delay(1000);
        display("Waiting for", "RFID...");
 }

 void displayIP(char input[])
 {
        printf("Read from stdin:\n%s\n",input);
        char line1[16];
        char line2[16];
        int i = 0;
        int j = 0;
        int whitespace = 0;

        while((input[i] != '\0') && (input[i] != '\n') && (i<15)) {
            if (input[i] == ' '){
                whitespace = 1;
                break;
            }
            line1[i] = input[i];
            i++;
        }
        line1[i] = '\0';
        
        if(whitespace == 1){
            printf("Found whitespace.\n");
            i++;
            while((input[i] != '\0') && (input[i] != '\n') && (j < 15)){
                line2[j] = input[i];
                i++; j++;
            }
        }
        line2[j] = '\0';

        printf("Line 1:\n%s\n",line1);
        printf("Line 2:\n%s\n",line2);

        display("Current IP", "Address:");
        delay(1500);
        display(line1, line2);
        delay(5000);
        display("Waiting for", "RFID...");
 }

 int readHelp(int initHelpState)
 {
        return (digitalRead(HELP_BUTTON) != initHelpState);
 } 
 
 int readPhoto(int initPhotoState)
 {
        return (digitalRead(PHOTO_BUTTON) != initPhotoState);
 }

 time_t beginUse(char *resp) 
{
        char *name = (char *)calloc(16,1);
        digitalWrite(greenLED, HIGH);
        digitalWrite(relayPin, HIGH);
        getName(name, resp);
        display("Welcome", name);
        free(name);
        delay(2000);
        digitalWrite(greenLED, HIGH);
        digitalWrite(relayPin, HIGH);
        display("Commence","Use...");
        time_t curr_time;
        curr_time = time(NULL);
        return curr_time;
}
void rejectUse()
{
        digitalWrite(redLED, HIGH);  
        display("Insufficient","credentials");
        delay(1000);
        display("Get approved at","maker.tufts.edu");
        delay(1000);
        digitalWrite(redLED, LOW);
        digitalWrite(relayPin, LOW);
        display("Waiting for", "RFID..");
}
void noUserHandler()
{
        display("No ID found","in Database");
        digitalWrite(relayPin, LOW);
        digitalWrite(redLED, HIGH);  
        delay(1000);
        display("Get approved at","maker.tufts.edu"); 
        digitalWrite(redLED, LOW);
        delay(1000);
        display("Waiting for", "RFID..");
}

int endUse(time_t start_time)
{
        display("Goodbye!", "Signed out!");
        time_t curr_time;
        curr_time = time(NULL);        
        int time_diff = (int)difftime(curr_time, start_time);

        digitalWrite(greenLED, LOW);
        digitalWrite(relayPin, LOW);
        delay(1000);
        display("Waiting for", "RFID..");
        return time_diff;
}

void contact_admin()
{
        display("Administrator","Contacted.");
        delay(2500);
        display("Please wait,","help is coming!");
        delay(2500);  
        display("Waiting for", "RFID..");
}
void sendHelp()
{
        display("Help","Requested!");
        delay(1500);                
        display("Check email","for info");
        delay(2000);                
        display("or press again","to call admin.");
        delay(1500);        
        display("Commence","Use...");
}

void display(char *line1, char *line2)
{
        char line1cmd[2] = { 254, 128 };
        char line2cmd[2] = { 254, 192 };

        center(LCD_buff1, line1);
        center(LCD_buff2, line2);

        write(LCD, line1cmd, 2);
        serialPuts(LCD, LCD_buff1);
        write(LCD, line2cmd, 2);
        serialPuts(LCD, LCD_buff2);
}

void getName(char *name_buff, char *response)
{
        char *r;

        //find T after JMNR
        unsigned int k;
        for(k = 0; k < strlen(response); k++) {
              if(response[k] == 'T') {
                    break;
              }
        }
        r = (response + k + 5); // skip 'True' and a whitespace
        k = 0;
        while((r[k] != ' ') && (r[k] != '\0') && (r[k] != '\n')){
            name_buff[k] = r[k];
            k++;
        }
        name_buff[k+1] = '\0';
}

void center(char *buff, char *toCenter)
{
        // Center the string for the display
        int s_len = strlen(toCenter);
        int space_padding = 0;
        if(s_len > 15){
            fprintf(stderr, "Error: message too long");
            return;
        }
        space_padding = s_len + (s_len % 2);  //makes divisible by 2
        space_padding = 16 - space_padding;  // get total amount of space on both sides
        space_padding = space_padding/2;       // space padding on one side

        strcpy(buff, ""); 
        //for loop appends whitespace to buffer
        int i;
        for (i=0; i < space_padding; i++) {
                buff[i] = ' ';
        }
        int j;
        for (j=0; j < s_len; j++) {
                buff[i] = toCenter[j];
                i++;
        }
        for (; i < 15; i++) {
                buff[i] = ' ';
        }
        buff[15] = '\0';
}

void GPIO_end()
{
        serialClose(LCD);
        free(LCD_buff1);
        free(LCD_buff2);
}
