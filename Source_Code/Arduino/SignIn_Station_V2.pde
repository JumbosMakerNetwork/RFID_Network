#include <SPI.h>
#include <MFRC522.h>
#include <SoftwareSerial.h>
#include <SparkFunESP8266WiFi.h>

// WARNING, WARNING ... DANGER, WILL ROBINSON, DANGER!!!
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
char JMNR[] = "$$$$$$";

#define RST_PIN   5   // 
#define SS_PIN    10  // 

////  RFID Inits ////////////
/////////////////////////////
// RFID_UID will be stored and sent as a hex string
String RFID_UID ="";
String prevRFID_UID ="";
MFRC522 RFID(SS_PIN, RST_PIN);  // Create mfrc522 instance
MFRC522::MIFARE_Key key;

//// Hardware assignments /////
///////////////////////////////
SoftwareSerial LCD(3,2);        // D2 -> LCD TX, D3 -> LCD RX (unused)
const int greenLED = 7;
const int redLED = 6;

const int OVRD = A0;  // writing key override to pin 4
// if the network is down, or there is some other fatal error,turn the key, which will run current to 4, make keyState != LOW and trigger override().
// We could also feasibly make an "override" RFID code so that override() is triggered whenever it's placed
int keyState = 0;
int initKeyState = 0;

// For the timer
unsigned long t0 = 0;
unsigned long t1 = 0;
String timer = "";

void setup() {
  pinMode(redLED, OUTPUT);
  pinMode(greenLED, OUTPUT);

  pinMode(OVRD, INPUT);
  initKeyState = digitalRead(OVRD);
  keyState = initKeyState;


  // Initialize Serial Communications
  Serial.begin(9600);   // with the PC for debugging displays
  LCD.begin(9600);      // With the LCD for external displays

  // Check and set up the wifi connection
  initializeESP8266();

  delay(500);
  display("  Waiting for", "     RFID..");

  SPI.begin();      
  RFID.PCD_Init();     

  // Prepare the key (used both as key A and as key B)
  // using FFFFFFFFFFFFh which is the default at chip delivery from the factory
  for (byte i = 0; i < 6; i++) {
    key.keyByte[i] = 0xFF;
  }
  
  GetRFID(key.keyByte, MFRC522::MF_KEY_SIZE);
}


void loop() {

  do {
  } while ( !getPICC() && (digitalRead(OVRD) == initKeyState) );

  if(digitalRead(OVRD) != initKeyState){   //if the keyState != what it was originally set to, i.e. the key has been turned
    override();
  }
  
  Serial.println(F("An RFID has been detected"));
  RFID_UID = GetRFID(RFID.uid.uidByte, RFID.uid.size);
  String info = "";

  if (RFID_UID == prevRFID_UID){
      //handler for signing out
      display("    Goodbye!", "  Signed out!");

      t1 = millis();
      t1 = t1-t0;
      t1 = t1/1000; //this gives us seconds since signin
      digitalWrite(greenLED, HIGH);
      prevRFID_UID = "";

      info = String(t1); // send seconds spent at station to server
      Serial.println(F("seconds elapsed: "));
      Serial.println(info);
  }

  else{
      t0 = millis();
      prevRFID_UID = RFID_UID;

      display("    Welcome!", " RFID Detected!");
      digitalWrite(greenLED, HIGH);

      info = "SignIn"; // Info constant for Sign IN/OUT stations.
  }

  RFID.PICC_HaltA();       // Halt PICC
  RFID.PCD_StopCrypto1();  // Stop encryption on PCD

  ReqJMN( RFID_UID, "3", info);
  digitalWrite(greenLED, LOW);  

  Serial.println(F("JMNR: "));
  Serial.println(JMNR);



  //String fname = resp.substring(2);
  // Need to parse through 'resp' here to grab the permission and the first 
  // name to display. 

  if (JMNR[0]== 'T')
  {
    // Turn on the green light for a second
    // Display a welcome message using 'fname'
    display("Permission Granted!","");
    digitalWrite(greenLED, HIGH);
    delay(1000); 
    digitalWrite(greenLED, LOW);  
  }
  else if (JMNR[0] == 'F')
  {
    // Blink the red light for a few seconds and give a 
    // warning message, say get approved at maker.tufts.edu

    display("Insufficient","credentials");
    for(int i = 0; i<4; i++){
      digitalWrite(redLED, HIGH);  
      delay(1000); 
      digitalWrite(redLED, LOW);
      delay(1000);   
    }

  }
  else if (JMNR[0] == 'E')
  {
    // Blink the red light and give an error message.
    // Display a warning to get a staff member. 
    display("Error","Get staff");
      digitalWrite(redLED, HIGH);  
      delay(1000); 
      digitalWrite(redLED, LOW);
      delay(1000);
      void(* resetFunc) (void) = 0;
      resetFunc();
    
  }

  reinitialize();  
}



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
  Serial.println("Get RFID called.");
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
boolean initializeESP8266()
{
  // esp8266.begin() verifies that the ESP8266 is operational 
  // and sets it up for the rest of the sketch.

  int test = esp8266.begin();
  if (test != true)
  {
    display("Error connecting","to Wifi Shield");
    void(* resetFunc) (void) = 0;
    resetFunc();
  }
  
  Serial.println(F("ESP8266 Shield Present"));
  
  int retVal = esp8266.getMode();
  if (retVal != ESP8266_MODE_STA) 
  { 
    retVal = esp8266.setMode(ESP8266_MODE_STA);
    if (retVal < 0)
    {
      Serial.println(F("Error setting mode."));
      display("Error setting","mode");
      return false;
    }
  }

  Serial.println(F("Mode set to station"));

  //blink leds once
  digitalWrite(greenLED, HIGH);
  digitalWrite(redLED, HIGH);
  delay(500); 
  digitalWrite(greenLED, LOW);  
  digitalWrite(redLED, LOW); 

  display("Connecting to", "     Wifi...");

  retVal =0;
  Serial.println(F("init retval"));

  retVal = esp8266.connect(SSID, PSK);
  if (retVal < 0)
    {
      Serial.println(F("Error connecting: "));
      display("Error connecting","to Wifi");
      delay(1000);
      display("Resetting","");
      delay(300);
      void(* resetFunc) (void) = 0;
      resetFunc();

    }
  else
  { 
    Serial.println(F("retval successful"));
    display("Successfully", "Connected!");
  }

  return true;
}

void ReqJMN(String RFID1, String req, String info)
{
  Serial.println(F("in reqjmn"));
  // To use the ESP8266 as a TCP client, use the 
  // ESP8266Client class. First, create an object:
  ESP8266Client client;

  // ESP8266Client connect([server], [port]) is used to 
  // connect to a server (const char * or IPAddress) on
  // a specified port.
  // Returns: 1 on success, 2 on already connected,
  // negative on fail (-1=TIMEOUT, -3=FAIL).
  int retVal = client.connect(DBIP, 80);
  if (retVal <= 0)
  {
    display("Failed to connect.", "reset device.");
    return;
  }


  else{
    // I'm putting the string declaration in this else statement to take advantage of local variable scoping.
    // Since memory seems to be such an issue, the memory it takes to generate this string should be 'recycled'
    // after this 'else' conditional.
    // URL path is a string, and to avoid the += operator, we explicitly redefine appropriate parts

    String httpRequest = "GET /RFID.php?sid=2&rfid=zzzzzzzz&req=z&info=zzzzzz HTTP/1.1\n"
                           "Host: 130.64.17.0\n"
                           "Connection: close\n\n";

    //populate with RFID
    for(int i = 0; i <8; i++){
      httpRequest[26+i] = RFID1[i];
    }
    //populate with req and info
    httpRequest[38] = req[0];

    size_t j;
    for(j=0; info[j]!='\0'; ++j);   //have to hand count length of info because its a String not a const char*
    size_t len = j % 6;                //using modulus to make sure it fits in the url param
    for(int i = 0; i < len; i++){
      httpRequest[45+i] = info[i];
    }
    client.print(httpRequest);
    delay(1000); //time it takes to buffer
  }

  // Currently, the response I get from the .php is only the first 63 characters of the response headers. It doesn't get to the body.
  // I don't know why, and this is a pretty crucial bug. It's not a buffering issue, and I don't think it's a memory issue, either.

  if( client.available())
  {   
      Serial.println(F("serial available: "));
      Serial.println(client.available());
      
      if( client.find("Da") ){            /// currently this is seeking the 'date' parameter in the header, for testing.
        Serial.println(F("I found 'Date'."));  /// we're going to want to make the argument of find() "JMNR:" once we get the body
        for(int i = 0; i < 6; i++){
          JMNR[i] = (char)client.read();
          delay(2);
        }
      }
      else if( !client.find("Da") ){
        Serial.println(F("I can't find 'Date' "));
        }
  }
  
  // connected() is a boolean return value - 1 if the 
  // connection is active, 0 if it's closed.
  if (client.connected()){
    client.stop(); // stop() closes a TCP connection.
    client.flush();
  }

}



////////////////////////////////////////////////////////////////////////
////////////////// MISC UTILITIES ///////////////////////////////////
//////////////////////////////////////////////////////

// Function for sending strings to the display
void display(String Line1, String Line2)
{
  // Clear the display
  LCD.write(254); LCD.write(128);
  LCD.write("                "); // clear display (16 characters each line)
  LCD.write("                ");

    // Concate the strings
  char L1[ ] = "                "; // 16 Characters
  char L2[ ] = "                "; // 16 Characters
  Line1.toCharArray(L1, 17);
  Line2.toCharArray(L2, 17);
  
  LCD.write(254); LCD.write(128); // First line
  LCD.write(L1);

  LCD.write(254); LCD.write(192); // Second line
  LCD.write(L2);

  delay(25);
}

void reinitialize(){
  RFID_UID="";
  display("  Waiting for", "     RFID..");
  for(int i = 0; i < 6; i++){
    JMNR[i] = '$';
  }

}

void override(){
  display("OVERRIDE","");
  digitalWrite(redLED, HIGH);
  digitalWrite(greenLED, HIGH);
  // ~this is where we would put code to supply power to the relays and bypass the permissions checks
  while(1){
  }

}




