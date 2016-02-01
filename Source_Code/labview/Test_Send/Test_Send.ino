/*
  Blink
  Turns on an LED on for one second, then off for one second, repeatedly.

  Most Arduinos have an on-board LED you can control. On the Uno and
  Leonardo, it is attached to digital pin 13. If you're unsure what
  pin the on-board LED is connected to on your Arduino model, check
  the documentation at http://www.arduino.cc

  This example code is in the public domain.

  modified 8 May 2014
  by Scott Fitzgerald
 */

String ID0 = "XXXXXXXX";
String ID1 = "420c0e11";
String ID2 = "39Bc6d91";

// the setup function runs once when you press reset or power the board
void setup() {
  // initialize digital pin 13 as an output.
  pinMode(13, OUTPUT);
  Serial.begin (9600);
}

// the loop function runs over and over again forever
void loop() {
  sendID(ID0);
  sendID(ID1);
  sendID(ID0);
  sendID(ID2);

}


void sendID(String ID)
{
  digitalWrite(13, HIGH);
  delay(100);
  digitalWrite(13, LOW);
  for (int i=0; i <= 300; i++)
  {
    Serial.println(ID);
    delay(50);
  }
}

