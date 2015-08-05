#include <SPI.h>
#include <MFRC522.h>
#include <SoftwareSerial.h>
#include <SparkFunESP8266WiFi.h>

// WARNING, WARNING ... DANGER, WILL ROBINSON, DANGER!!!
// The station ID is unique to each terminal and must be manually entered.
// Double and triple check this value is what you intend it to be.
#define SID 2  // Station ID number  - needs to correlate with database setting

//// Wireless network information ////
/////////////////////////////////////
const char SSID[] = "tuftswireless";
// Empty string since network is not password protected. This particular network is 
// mac address registry based. We are not registering the mac addresses of these so
// they are limited to accessing internal IPs or websites hosted by Tufts. 
const char PSK[] = ""; 
// Static IP of the directory location
const char DBIP[] = "130.64.17.0";

#define RST_PIN   5   // 
#define SS_PIN    10  // 

////  RFID Inits ////////////
/////////////////////////////
int successRead = 0;
// RFID_UID will be stored and sent as a hex string
String RFID_UID;
MFRC522 RFID(SS_PIN, RST_PIN);  // Create mfrc522 instance
MFRC522::MIFARE_Key key;

//// Hardware assignments /////
///////////////////////////////
SoftwareSerial LCD(3,2);        // D2 -> LCD TX, D3 -> LCD RX (unused)
int redLED = 6;
int greenLED = 7;


void setup() {
  pinMode(redLED, OUTPUT);
  pinMode(greenLED, OUTPUT);

  // Initialize Serial Communications
  Serial.begin(9600);   // with the PC for debugging displays
  LCD.begin(9600);      // With the LCD for external displays

  // Check and set up the wifi connection
  initializeESP8266();

  ///// !!! The following could probably be thrown into a single function in case
  ///// !!! signal is lost at some point. FOr now it's fine here thgouh. 
  Serial.println(F("connecting now "));
  display("Connecting to", "     Wifi...");

  int retVal =0;
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
  delay(500);
  display("  Waiting for", "     RFID..");

  SPI.begin();      // Init SPI bus
  RFID.PCD_Init();    // Init MFRC522
  Serial.println(F("/n And it begins..."));
  

  ////// !!! I uncommented the following and it seemed to eliminate the issue.
  ////// !!! It was in all the example codes so maybe it needs the 

  // Prepare the key (used both as key A and as key B)
  // using FFFFFFFFFFFFh which is the default at chip delivery from the factory
  for (byte i = 0; i < 6; i++) {
    key.keyByte[i] = 0xFF;
  }
  // Serial.println(F("Scan a MIFARE Classic PICC to demonstrate read and write."));
  // Serial.print(F("Using key (for A and B):"));
  GetRFID(key.keyByte, MFRC522::MF_KEY_SIZE);
  
}


void loop() {

  do {
    successRead = getPICC();  // sets successRead to 1 when we get read from reader otherwise 0
  } while (!successRead);
  
  Serial.println(F("An RFID has been detected")); 

  display("","");
  display("    Welcome!", " RFID Detected!");
  digitalWrite(greenLED, HIGH);
  delay(1000); 
  digitalWrite(greenLED, LOW); 

  // Serial.print(F("debug 2:"));
  Serial.print(F("Card UID:"));
  RFID_UID = GetRFID(RFID.uid.uidByte, RFID.uid.size);
  
  RFID.PICC_HaltA();       // Halt PICC
  RFID.PCD_StopCrypto1();  // Stop encryption on PCD

  // Serial.println(String(RFID_UID));

  String req = "3"; // Req type is consistently 3 for Sign IN/OUT stations.
                    // **** string bc of arguments ReqJMN takes.

  String info = "SignIn"; // Info constant for Sign IN/OUT stations.
  // // ping the database
  String resp = ReqJMN(String(RFID_UID), req, info);
  Serial.println("resp = ");
  Serial.println(resp);

  
  /*****************************************************************************
  ******************************************************************************
  ******** The following is code to handle the server responses, 
  ******** which currently does not function (board doesn't parse server resp)
  ******************************************************************************

  String fname = resp.substring(2);
  // Need to parse through 'resp' here to grab the permission and the first 
  // name to display. 

  // **** changed to [] notation from 'charat(0)', which i've never seen before
  if (resp[0]== 'T')
  {
    // Turn on the green light for a second
    // Display a welcome message using 'fname'
    digitalWrite(greenLED, HIGH);
    delay(1000); 
    digitalWrite(greenLED, LOW);  
  }
  else if (resp[0] == 'F')
  {

    // Blink the red light for a few seconds and give a 
    // warning message, maybe say get approved at maker.tufts.edu

    display("Insufficient","credentials");
    for(int i = 0; i<4; i++){
      digitalWrite(redLED, HIGH);  
      delay(1000); 
      digitalWrite(redLED, LOW);
      delay(1000);   
    }

  }
  else if (resp[0] == 'E')
  {
    // Blink the red light and give an error message.
    // Display a warning to get a staff member. 
    display("Error","Get staff");
    while(1){
      digitalWrite(redLED, HIGH);  
      delay(1000); 
      digitalWrite(redLED, LOW);
      delay(1000);
    }
  }
  **************************************************************************/

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

//// !!! I eliminated the hex string to long int function call since that seemed to
//// !!! cause some junk. Maybe that filled the memory and caused the repeatability
//// !!! problems. After eliminating that and adding the initilizing key call back into
//// !!! the setup, I was able to get it running for a half hour randomly running various
//// !!! RFID tags about 2 dozen times. 
String GetRFID(byte *buffer, byte bufferSize) {
  Serial.println("Get RFID called.");
  Serial.println("buffer size: " + String(bufferSize));
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
  // It returns either true or false -- indicating whether
  // communication was successul or not.
  int test = esp8266.begin();
  if (test != true)
  {
    Serial.println(F("Error talking to ESP8266."));
    while(1){
        display("Error connecting","to Wifi Shield");
        delay(1500);
        display("Hard-reset","device"); 
        delay(1500);
        void(* resetFunc) (void) = 0;
        resetFunc();
    }

  }
  
  Serial.println(F("ESP8266 Shield Present"));
  // The ESP8266 can be set to one of three modes:
  //  1 - ESP8266_MODE_STA - Station only
  //  2 - ESP8266_MODE_AP - Access point only
  //  3 - ESP8266_MODE_STAAP - Station/AP combo
  // Use esp8266.getMode() to check which mode it's in:
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

  return true;
}

String ReqJMN(String RFID1, String req, String info)
{
  // This should get a return value. I changed it to void and things worked fine. 
  Serial.println(F("Contacting JMN Database."));
  ESP8266Client JMN; // Create a client object
  delay(200);
  int retVal = JMN.connect(DBIP, 80); // Connect to sparkfun (HTTP port)
  if (retVal <= 0) {
    Serial.println(F("Could not connect"));
    display("Could not","connect.");
    delay(1000);
    return "Error";
  }

  Serial.println(F("Successfully connected!"));

  // Use the RFID.php page. I'd rather everything go through one page and I 
  // updated the syntax to pass a hex string to the database. 
  // 
  String cmd = "GET /RFID.php?sid="; 
  cmd += SID;
  cmd += "&rfid=";
  cmd += RFID1;
  cmd += "&req=";
  cmd += req;
  cmd += "&info=";
  cmd += info;
  cmd += " HTTP/1.1\n"
          "Host: " + String(DBIP) + "\n"
          "Connection: close\n\n";

  Serial.println(cmd);
  JMN.print(cmd);

  String response = "";
  delay(50); //VERY short delay to allow for buffering
  int counter = 0;
  while (JMN.available()) // While there's data available
  {
    Serial.write(JMN.read()); // read() gets the FIFO char
    char inChar = (char)JMN.read(); // Reads input as a char
    Serial.println("inChar " + String(counter));
    counter++;
    Serial.println(inChar);
    response += inChar; // Adds input to a large string
    Serial.println(response);
  }

  // Need to parse through the response for permission and for user name
  if (response != "") {
    Serial.println("Printing response...");
    Serial.println(String(response));
    display("     Signin", "     logged!");
    delay(500);
  }
  
  if (JMN.connected()){
    JMN.stop();
  }

  return response;

}


////////////////////////////////////////////////////////////////////////
////////////////// MISC UTILITIES ///////////////////////////////////
//////////////////////////////////////////////////////

// Function to display a system error and instructions
void SystemError(String error1, String error2)
{
  String Ecmd1 = " ";
  String Ecmd2 = " ";
 
  Ecmd1 = "PLEASE CONTACT";
  Ecmd2 = " A STAFF MEMBER";
  display(error1, error2);
  delay(500);
}

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
  successRead = 0;
  RFID_UID="";
  // initializeESP8266();
  display("  Waiting for", "     RFID..");

}




