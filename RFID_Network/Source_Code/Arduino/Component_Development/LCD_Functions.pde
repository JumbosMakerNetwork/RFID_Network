// Based on SparkFun Serial LCD example 1
// Clear the display and say "Hello World!"

// This sketch is for Arduino versions 1.0 and later
// If you're using an Arduino version older than 1.0, use
// the other example code available on the tutorial page.

// Use the softwareserial library to create a new "soft" serial port
// for the display. This prevents display corruption when uploading code.
#include <SoftwareSerial.h>

// Attach the serial display's RX line to digital pin 2
SoftwareSerial LCD(3,2); // pin 2 = TX, pin 3 = RX (unused)

//char Str1[29];
//char Str2[29];
String Str1 = "testing ... extra characters";
String Str2 = "display ... extra characters";
String Str3 = "Booting";
String Str4 = "  up...";

void setup()
{
  LCD.begin(9600); // set up serial port for 9600 baud
  display(Str3, Str4); 
  delay(5000); // wait for display to boot up
}

void loop()
{
//  Str1 = "testing ... extra characters";
//  Str2 = "display ... extra characters";

  display(Str1, Str2);

  while(1); // wait forever
}

void display(String L1, String L2)
{
  // Clear the display
  LCD.write(254); // move cursor to beginning of first line
  LCD.write(128);

  LCD.write("                "); // clear display (16 characters each line)
  LCD.write("                ");

    // Concate the strings
  char L1[ ] = "                ";
  char L2[ ] = "                ";
  Line1.toCharArray(L1, 17);
  Line2.toCharArray(L2, 17);
  
  LCD.write(254); // move cursor to beginning of first line
  LCD.write(128);

  LCD.write(L1); // Write the first line

  LCD.write(254); // move cursor to beginning of second line
  LCD.write(192);

  LCD.write(L2); // Write the second line

  delay(25);
}








