/*
 * HW_GPIO.c
 *	
 *  by Will Dolan, June 2016
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <wiringPi.h>
#include <time.h>
#include "led_gpio.h"

 #define greenLED 29
 #define redLED	  28
 #define relayPin 27
 #define HELP_BUTTON 24
 #define PHOTO_BUTTON 25

 void init_GPIO()
 {
        wiringPiSetup();
	    pinMode(greenLED, OUTPUT);     
	    pinMode(redLED, OUTPUT);    
	    pinMode(relayPin, OUTPUT); 
	    pinMode(HELP_BUTTON, INPUT);
        printf("Pi initialized, ready for RFID.\n");
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
        digitalWrite(greenLED, HIGH);
        digitalWrite(relayPin, HIGH);
        char *name = getName(resp);
        //display("Welcome", name);
        free(name);
        //delay(1000);
        digitalWrite(greenLED, HIGH);
        digitalWrite(relayPin, HIGH);
        //display("Commence","Use...");
        time_t curr_time;
        curr_time = time(NULL);
        return curr_time;
}
void rejectUse()
{
        digitalWrite(redLED, HIGH);  
        //display("Insufficient","credentials");
        delay(1000);
        //display("Get approved at","maker.tufts.edu");
        delay(1000);
        digitalWrite(redLED, LOW);
        digitalWrite(relayPin, LOW);
}
void noUserHandler()
{
        // Blink the red light and give an error message.
        // //Display a warning to get a staff member. 
        //display("No ID found","in Database");
        digitalWrite(relayPin, LOW);
        digitalWrite(redLED, HIGH);  
        delay(1000);
        //display("Get approved at","maker.tufts.edu"); 
        digitalWrite(redLED, LOW);
        delay(1000);
}

int endUse(time_t start_time)
{
        //display("Goodbye!", "Signed out!");
        time_t curr_time;
        curr_time = time(NULL);        
        int time_diff = (int)difftime(curr_time, start_time);

        digitalWrite(greenLED, LOW);
        digitalWrite(relayPin, LOW);

        return time_diff;
}

void contact_admin()
{
        //display("Administrator","Contacted.");
        // delay(2500);
        // display("Please wait,","help is coming!");
        // delay(2500);  
        // display("Waiting for", "RFID..");
}
void sendHelp()
{
        // display("Help","Requested!");
        // delay(1500);                
        // display("Check your email","for information");
        // delay(2000);                
        // display("or press again","to call admin.");
        // delay(1500);        
}
/*
void display(string line1, string line2)
{
        // Clear the display
        LCD.write(254); LCD.write(128);
        LCD.write("                "); // clear display (16 characters each line)
        LCD.write("                ");

        line1 = center(Line1);
        line2 = center(Line2);

        // Concatenate the strings
        char L1[ ] = "                "; // 16 Characters
        char L2[ ] = "                ";
        line1.toCharArray(L1, 16);
        line2.toCharArray(L2, 16);

        LCD.write(254); LCD.write(128); // First line
        LCD.write(L1);

        LCD.write(254); LCD.write(192); // Second line
        LCD.write(L2);

        delay(25);
}*/

char *getName(char *response)
{
        char *r;
        char *name = (char *)calloc(16,1);

        //find T after JMNR
        unsigned int k;
        for(k = 0; k < strlen(response); k++) {
              if(response[k] == 'T') {
                    break;
              }
        }
        r = (response + k + 2); // skip T and a whitespace
        k = 0;
        while((r[k] != ' ') && (r[k] != '\0') && (r[k] != '\n')){
            name[k] = r[k];
            k++;
        }
        name[k+1] = '\0';
        return name;
}
/*
string center(string toCenter)
{
        // Center the string for the display
        int a = toCenter.length();
        a = a + (a % 2);  //makes divisible by 2
        a = 16 - a;
        a = a/2;
        string center1 = "";
        for (a; a > 0; a--) {    //for loop concatenates whitespaces to beginning of new array
                center1 += ' ';
        }
        center1 += toCenter;
        return center1;
}*/