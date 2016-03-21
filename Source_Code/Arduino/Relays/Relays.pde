#include <SPI.h>
#include <MFRC522.h>
#include <SoftwareSerial.h>

// The station ID is unique to each terminal and must be manually entered.
// Double and triple check this value is what you intend it to be.
//#define SID 2  // Station ID number  - needs to correlate with database setting

//// Wireless network information ////
/////////////////////////////////////
const char SSID[] = "tuftswireless";
// // Empty string since network is not password protected. This particular network is 
// // mac address registry based. We are not registering the mac addresses of these so
// // they are limited to accessing internal IPs or websites hosted by Tufts. 
const char PSK[] = ""; 
// // Static IP of the directory location
const char DBIP[] = "130.64.17.0";
#define STID 5                  // Station ID number (soldering)

#define RST_PIN   5   // 
#define SS_PIN    10  // 

////  RFID Inits ////////////
/////////////////////////////
// RFID_UID will be stored and sent as a hex string
String RFID_UID ="";
String prevRFID_UID ="";
MFRC522 RFID(SS_PIN, RST_PIN);  // Create mfrc522 instance
MFRC522::MIFARE_Key key;

String req = "";
String info = "";

//// Hardware assignments /////
///////////////////////////////
SoftwareSerial ESP8266(8, 9); // D8 -> ESP8266 RX, D9 -> ESP8266 TX
SoftwareSerial LCD(2,3);        // D2 -> LCD TX, D3 -> LCD RX (unused)
const int greenLED = 7;
const int redLED = 6;
const int relayPin = 4;

const int OVRD = A0;  // writing key override to pin 0
// if the network is down, or there is some other fatal error,turn the key, which will run current to 0, make keyState != LOW and trigger override().
int keyState = 0;
int initKeyState = 0;

// For the timer
unsigned long t0 = 0;
unsigned long t1 = 0;
String timer = "";

void setup() {
  pinMode(redLED, OUTPUT);
  pinMode(greenLED, OUTPUT);
  pinMode(relayPin, OUTPUT);

  pinMode(OVRD, INPUT);
  initKeyState = digitalRead(OVRD);
  keyState = initKeyState;


  // Initialize Serial Communications
  Serial.begin(9600);   // with the PC for debugging displays
  LCD.begin(9600);      // With the LCD for external displays
  LCD.write(0x12); // Makes sure the display is running at 9600 Baud
  LCD_init();      // With the LCD for external displays
  ESP8266.begin(9600);

  display("Welcome", "");

  Serial.println(F("checking esp8266!"));
  while(!ESP8266_Check()){}
  Serial.println(F("esp8266 checked!"));
  while( !ESP8266_Mode(3) ){}
  Serial.println(F("esp8266 set to mode 3!"));
  while( !connectWiFi() ){}
  Serial.println(F("esp8266 successfully connected to wifi!"));

  SPI.begin();      
  RFID.PCD_Init(); 

  delay(500);
  display("Waiting for", "RFID..");    

  // Prepare the key (used both as key A and as key B)
  // using FFFFFFFFFFFFh which is the default at chip delivery from the factory
  for (byte i = 0; i < 6; i++) {
      key.keyByte[i] = 0xFF;
  }
  GetRFID(key.keyByte, MFRC522::MF_KEY_SIZE);
}


void loop() {
    delay(1000);
    unsigned long counter = 0;
    unsigned int period = 32768;  

    do {
        //for debugging: wait for serial commands while looping
        while(ESP8266.available()) Serial.write(ESP8266.read());
        while(Serial.available()) ESP8266.write(Serial.read());

        /*delay a tenth of a second, then increment counter, and check wifi periodically
          this makes use of bitwise operations instead of modulo and greater than 4 bil
          comparisons which significantly improves performance 
          The first checks whether counter is a multiple of the period, the second 
          checks whether the counter is greater than 2^31 (2bill) so it can reset. */

        delay(100); 
        counter++;
        if(counter & period) {
           if (counter & (1<<31)) { 
                  counter = 0;
           }

           if( !connectWiFi() ) {
                  display("Wifi", "Disconnected");
                  while(!connectWiFi()) {}
                  display("Wifi", "Connected");
                  delay(200);
                  //ReqJMN( "0", "3", "Wifi disconnect");
                  //delay(200);
                  display("Waiting for", "RFID..");
           }
        }

    } while ( !getPICC()  && (digitalRead(OVRD) == initKeyState) );
    //if the keyState != what it was originally set to, i.e. the key has been turned
    if(digitalRead(OVRD) != initKeyState) {   
                  override();
    }
  
    Serial.println(F("An RFID has been detected"));
    RFID_UID = GetRFID(RFID.uid.uidByte, RFID.uid.size);
    info = "begin";
    req = "1";     //req is 1, we're querying DB, looking for info back
    display("Welcome!", "RFID Detected!");

    // RFID.PICC_HaltA();       // Halt PICC
    // RFID.PCD_StopCrypto1();  // Stop encryption on PCD

    String resp = ReqJMN( RFID_UID, req, info);
    Serial.println(resp);

    // If this is a signin or a server query
    if(req == "1" || req == "3") {   
        if (resp[0]== 'T')
        {
          digitalWrite(greenLED, HIGH);
          String name = getName(resp);

          display("Welcome", name);
          delay(1000);
          display("Permission","Granted!");
          delay(1000);
          digitalWrite(greenLED, LOW);
          prevRFID_UID = RFID_UID;

          beginUse();
        }
        else if (resp[0] == 'F')
        {
          digitalWrite(redLED, HIGH);  
          display("Insufficient","credentials");
          delay(1000);
          display("Get approved at","maker.tufts.edu");
          delay(1000);
          digitalWrite(redLED, LOW);
          digitalWrite(relayPin, LOW);

        }
        else if (resp[0] == 'E')
        {
          // Blink the red light and give an error message.
          // Display a warning to get a staff member. 
            display("No ID found","in Database");
            digitalWrite(relayPin, LOW);
            digitalWrite(redLED, HIGH);  
            delay(1000);
            display("Get approved at","maker.tufts.edu"); 
            digitalWrite(redLED, LOW);
            delay(1000);
        }
    }
    display("Waiting for", "RFID..");
}

void beginUse() 
{
  t0 = millis();
  digitalWrite(greenLED, HIGH);
  digitalWrite(relayPin, HIGH);
  display("Commence","Use...");
  
  Serial.println(F("before while loop"));
  Serial.println ( RFID.PICC_IsNewCardPresent() );
  Serial.println ( RFID.PICC_ReadCardSerial() );

  //while the RFID engaged is the same as before
  while( getPICC() ) { 
        Serial.println(F("in while loop"));
        Serial.println(RFID_UID);
        Serial.println( GetRFID(RFID.uid.uidByte, RFID.uid.size) );
        Serial.println( RFID.PICC_IsNewCardPresent() );
        Serial.println( RFID.PICC_ReadCardSerial() );
        //give access for 10 seconds...
        display("Commence","Use..");
        delay(2000);  //give access for 2 secs
        display("Commence","Use...");
        delay(2000);  //give access for 2 secs
        display("Commence","Use....");
        delay(2000);  //give access for 2 secs
        display("Commence","Use.....");
        delay(2000);  //give access for 2 secs
        display("Commence","Use......");
        delay(2000);  //give access for 2 secs
  }
  endUse();
}

void endUse()
{
    display("Goodbye!", "Signed out!");
    t1 = millis();
    t1 = t1-t0;
    t1 = t1/1000; //this gives us seconds since signin

    digitalWrite(greenLED, LOW);
    prevRFID_UID = "";
    digitalWrite(relayPin, LOW);

    req = "2";      //Req is 2, we are just logging the time spent to the server
    info = String(t1); // send seconds spent at station to server
    Serial.println(F("seconds elapsed: "));
    Serial.println(info);
    ReqJMN( RFID_UID, req, info);
    delay(1000);
}


//////////////////////////////////////////////////////////////////
//////////////////////RFID UTILITY FUNCTIONS//////////////////////
//////////////////////////////////////////////////////////////////

// Grab the hex values from a byte array, returns decimal equivalent
int getPICC() {
  // Getting ready for Reading PICCs
  if ( ! RFID.PICC_IsNewCardPresent()) { //If a new PICC placed to RFID reader continue
    return 0;
  }
  if ( ! RFID.PICC_ReadCardSerial()) {   //Since a PICC is placed, get Serial and continue
    return 0;
  }

  return 1;
}

String GetRFID(byte *buffer, byte bufferSize) {
  Serial.println(F("Get RFID called."));
  String tmp = "";
  String tmp2;
  for (byte i = 0; i < bufferSize; i++) {
    tmp2 = "";
    tmp2 += String(buffer[i] < 0x10 ? "0" : "");
    tmp2 += String(buffer[i], HEX);
    tmp = tmp2 + tmp;
  }
  tmp.toUpperCase();
  return tmp;
}


////////////////////////////////////////////////////////////////////////
/////////////////////// WIFI / DATABASE UTILITIES //////////////////////
////////////////////////////////////////////////////////////////////////
boolean ESP8266_Check()
{
  ESP8266.println("AT");
  delay(500);

  if(ESP8266.find("OK")) {
    Serial.println(F("RECEIVED: OK"));
    return true;
  }
  else if(ESP8266.find("ERROR")) {
    Serial.println(F("RECEIVED: Error"));
    return false;
  }
  else {
    Serial.println(F("RECEIVED: No Response"));
    delay(1000);
    void(* resetFunc) (void) = 0;
    resetFunc();
    return false;
  }
  delay(100);
}

boolean ESP8266_Mode(int mode)
{
  ESP8266.println(F("AT+CWMODE?"));
  if(ESP8266.find(mode)) {
    Serial.print(F("Mode already set"));
    return true;
  }

  ESP8266.print(F("AT+CWMODE="));
  ESP8266.println(mode);

  if(ESP8266.find("OK")) {
    Serial.println(F("RECEIVED: OK"));
    return true;
  }
  else if(ESP8266.find("ERROR")) {
    Serial.println(F("RECEIVED: Error"));
    return false;
  }
  else {
    Serial.println(F("RECEIVED: No Response"));
    void(* resetFunc) (void) = 0;
    resetFunc();
    return false;
  }
  delay(100);
}


boolean connectWiFi(){
  ESP8266.println("AT+CWJAP?");
  if(ESP8266.find("tuftswireless")) {
      while(ESP8266.available()) Serial.write(ESP8266.read());
      Serial.println(F("Already connected"));
      return true;
  }
  delay(100);
  String cmd="AT+CWJAP=\"";
  cmd+=SSID;
  cmd+="\",\"";
  cmd+=PSK;
  cmd+="\"";
  ESP8266.println(cmd);
  Serial.println(cmd);
  delay(800);
  while (!ESP8266.available()) {
    delay(100);
  }

  if(ESP8266.find("OK")) {
    Serial.println(F("RECEIVED: OK"));
    ESP8266.flush();
    return true;
  }
  else if(ESP8266.find("ERROR")) {
    Serial.println(F("RECEIVED: Error"));
    return false;
  }
  else {
    Serial.println(F("RECEIVED: Couldn't connect to wifi; no response"));
    // void(* resetFunc) (void) = 0;
    // resetFunc();
    return false;
  }
  delay(100);
}


String ReqJMN(String RFID1, String req1, String info1)
{
  String resp="";
  char z;
  Serial.println(F("Starting request..."));

  String httpReq = "GET /RFID.php?stid=";
  httpReq += STID; // Universal constant
  httpReq += "&rfid=";
  httpReq += RFID1; // Local input
  httpReq += "&req=";
  httpReq += req1; // local input
  httpReq += "&info=";
  httpReq += info1; // local input
  httpReq += " HTTP/1.0\r\n\r\n";
  delay(50);
  Serial.println(httpReq);

  //  Send AT command to ESP8266
  // Start connection - 
  Serial.println(F("CIPStart..."));
  Serial.print(F("AT+CIPSTART=\"TCP\",\""));
  Serial.print(DBIP);
  Serial.print(F("\",80\r\n"));

  ESP8266.print("AT+CIPSTART=\"TCP\",\"");
  ESP8266.print(DBIP);
  ESP8266.print("\",80\r\n");
  
  delay(100);
  if(ESP8266.find("OK")) {
    Serial.println(F("CIPSTART: OK"));
  }
  else if(ESP8266.find("ERROR")) {
    Serial.println(F("CIPSTART: Error"));
  }
  else {
    Serial.println(F("CIPSTART: No Response"));
  }

  // Send request - 
  Serial.print(F("AT+CIPSEND=")); 
  Serial.print(httpReq.length());
  Serial.print("\r\n");

  ESP8266.print("AT+CIPSEND="); 
  ESP8266.print(httpReq.length()); // Specifies how much data is being sent
  ESP8266.print("\r\n");
  // while(ESP8266.available()) Serial.write(ESP8266.read());
  delay(500);

  if(ESP8266.find("OK")) {
    Serial.println(F("Sent Request - "));
    Serial.print(httpReq);
    ESP8266.print(httpReq);
  }
  else {
    Serial.println(F("No request sent. Try again."));
  }

  int j = 0;
  Serial.println(F("Attempting now..."));
  while(!ESP8266.find("JMNR:")) {
    j++;
    Serial.print(j);
    if (j>50) {
      Serial.println(F("Error - could not find JMNR"));
      return "Error - could not find JMNR";
    }
  }

  Serial.println(F("Found JMNR:..."));
  for (int i = 0; i<=18; i++) {
    while(!ESP8266.available());
    z = (char)ESP8266.read();
    Serial.write(z);
    resp.concat(z);
  }

  Serial.println(F("<-- END"));
  
  return resp;
}



////////////////////////////////////////////////////////////////////////
////////////////// MISC UTILITIES ///////////////////////////////////
//////////////////////////////////////////////////////

void LCD_init() 
{
      // Initialize the display
      LCD.write(0x0C); // Turn Display on
      delay(10);
      LCD.write(0x7C); // Command Character
      delay(10);
      LCD.write(157); // Full Brightness
      delay(10);
}

// Function for sending strings to the display
void display(String Line1, String Line2)
{
  // Clear the display
  LCD.write(254); LCD.write(128);
  LCD.write("                "); // clear display (16 characters each line)
  LCD.write("                ");

  Line1 = center(Line1);
  Line2 = center(Line2);

    // Concatenate the strings
  char L1[ ] = "                "; // 16 Characters
  char L2[ ] = "                "; // 16 Characters
  Line1.toCharArray(L1, 16);
  Line2.toCharArray(L2, 16);
  
  LCD.write(254); LCD.write(128); // First line
  LCD.write(L1);

  LCD.write(254); LCD.write(192); // Second line
  LCD.write(L2);

  delay(25);
}

void override()
{
  display("OVERRIDE","");
  digitalWrite(redLED, HIGH);
  digitalWrite(greenLED, HIGH);
  digitalWrite(relayPin, HIGH); 

  while(digitalRead(OVRD) != initKeyState) {
    // While the key state is not what it was at the initialization of the program
    // turn the key back to original state to end the override
    delay(20000); 

  }
  digitalWrite(relayPin, LOW);
  digitalWrite(redLED, LOW);
  digitalWrite(greenLED, LOW);

}

String getName(String response)
{
  Serial.println(F("In getname"));
  response.remove(0,2);   //removes 'T' and a whitespace, also, this fxn is
                          //pass by copy, so we're not altering the reponse from before
  Serial.println(response);

  //find whitespace after name
  int k = 0;
  for(k; k < response.length(); k++) {
      if(response[k] == ' ') {
        break;
      }
  }

  int j = (16 - k);
  // now remove everything after index k, up to the last index (index 15)
  response.remove(k, j);

  return response;
}

String center(String toCenter)
{
  // Center the string for the display
  int a = toCenter.length();
  a = a + (a % 2);  //makes divisible by 2
  a = 16 - a;
  a = a/2;
  String center1 = "";
  for (a; a > 0; a--) {    //for loop concatenates whitespaces to beginning of new array
      center1 += ' ';
  }
  center1 += toCenter;
  return center1;
}