#include <SPI.h>
#include <MFRC522.h>
#include <SoftwareSerial.h>

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
#define STID 1                  // Station ID number

#define RST_PIN   5   // 
#define SS_PIN    10  // 

////  RFID Inits ////////////
/////////////////////////////
// RFID_UID will be stored and sent as a hex string
String RFID_UID ="";
MFRC522 RFID(SS_PIN, RST_PIN);  // Create mfrc522 instance
MFRC522::MIFARE_Key key;

//// Hardware assignments /////
///////////////////////////////
SoftwareSerial ESP8266(8, 9); // D9 -> ESP8266 RX, D10 -> ESP8266 TX
SoftwareSerial LCD(3,2);        // D2 -> LCD TX, D3 -> LCD RX (unused)
const int greenLED = 7;
const int redLED = 6;

void setup() {
  display("Welcome", "");
  pinMode(redLED, OUTPUT);
  pinMode(greenLED, OUTPUT);

  // Initialize Serial Communications
  Serial.begin(9600);   // with the PC for debugging displays
  LCD.begin(9600);      // With the LCD for external displays
  ESP8266.begin(9600);

  while(!ESP8266_Check()){}
  Serial.println("esp8266 checked!");
  while( !ESP8266_Mode(3) ){}
  Serial.println("esp8266 set to mode 3!");
  while( !connectWiFi() ){}
  Serial.println("esp8266 successfully connected to wifi!");

  display("Waiting for", "RFID..");
  delay(500);

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
  delay(1000);

  do {
    //for debugging: wait for serial commands while looping
    while(ESP8266.available()) Serial.write(ESP8266.read());
    while(Serial.available()) ESP8266.write(Serial.read());
  } while ( !getPICC() );
  
  Serial.println(F("An RFID has been detected"));
  RFID_UID = GetRFID(RFID.uid.uidByte, RFID.uid.size);

  display("Welcome!", "RFID Detected!");
  String info = "SignIn"; // Info constant for Sign IN/OUT stations.

  RFID.PICC_HaltA();       // Halt PICC
  RFID.PCD_StopCrypto1();  // Stop encryption on PCD

  String resp = "";
  resp = ReqJMN( RFID_UID, "3", info);
  Serial.println(resp);

      if (resp[0]== 'T')
      {
        digitalWrite(greenLED, HIGH);
        String name = getName(resp);
        Serial.println(resp);
        Serial.println(name);

        display("Welcome", name);
        delay(1000);
        display("Permission","Granted!");
        delay(1000);
        digitalWrite(greenLED, LOW);  

      }
      else if (resp[0] == 'F')
      {
        digitalWrite(redLED, HIGH);  
        display("Insufficient","credentials");
        delay(2000);
        display("Get approved at","maker.tufts.edu");
        delay(2000);
        digitalWrite(redLED, LOW);  

      }
      else if (resp[0] == 'E')
      {
        // Blink the red light and give an error message.
        // Display a warning to get a staff member. 
        display("No ID found","in Database");
          digitalWrite(redLED, HIGH);  
          delay(1000);
          display("Get approved at","maker.tufts.edu"); 
          digitalWrite(redLED, LOW);
          delay(1000);
      }
  display("Waiting for", "RFID..");
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
boolean ESP8266_Check()
{
  ESP8266.println("AT");
  delay(500);
  if(ESP8266.find("OK"))
  {
    Serial.println(F("RECEIVED: OK"));
    return true;
  }
  else if(ESP8266.find("ERROR"))
  {
    Serial.println(F("RECEIVED: Error"));
    Serial.println(F("Trying again.."));
    return false;
  }
  else
  {
    Serial.println(F("RECEIVED: No Response"));
    Serial.println(F("Trying again.."));
    delay(1000);
    return false;
  }
  delay(100);
}

boolean ESP8266_Mode(int mode)
{
  ESP8266.println(F("AT+CWMODE?"));
  if(ESP8266.find(mode)) // Might have to conver mode from an int to a char
  {
    Serial.print(F("Mode already set"));
    return true;
  }
  ESP8266.print(F("AT+CWMODE="));
  ESP8266.println(mode);
    if(ESP8266.find("OK"))
  {
    Serial.println(F("RECEIVED: OK"));
    return true;
  }
  else if(ESP8266.find("ERROR"))
  {
    Serial.println(F("RECEIVED: Error"));
    Serial.println(F("Trying again.."));
    return false;
  }
  else
  {
    Serial.println(F("RECEIVED: No Response"));
    Serial.println(F("Trying again.."));
    //reset device
    void(* resetFunc) (void) = 0;
    resetFunc();
    return false;
  }
  delay(100);
}


boolean connectWiFi(){
  ESP8266.println("AT+CWJAP?");
  if(ESP8266.find("tuftswireless")) 
  {
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
  while ( !ESP8266.available() ){
    delay(100);
  }

  if(ESP8266.find("OK"))
  {
    Serial.println(F("RECEIVED: OK"));
    ESP8266.flush();
    return true;
  }
  else if(ESP8266.find("ERROR"))
  {
    Serial.println(F("RECEIVED: Error"));
    return false;
  }
  else
  {
    Serial.println(F("RECEIVED: Couldn't connect to wifi; no response"));
    // void(* resetFunc) (void) = 0;
    // resetFunc();
    //had device reset, but could use more robust way of resetting if no network connection
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
  Serial.println("CIPStart...");
  Serial.print("AT+CIPSTART=\"TCP\",\"");
  Serial.print(DBIP);
  Serial.print("\",80\r\n");

  ESP8266.print("AT+CIPSTART=\"TCP\",\"");
  ESP8266.print(DBIP);
  ESP8266.print("\",80\r\n");
  
  delay(100);
  if(ESP8266.find("OK"))
  {
    Serial.println(F("CIPSTART: OK"));
  }
  else if(ESP8266.find("ERROR"))
  {
    Serial.println(F("CIPSTART: Error"));
    return "Error";
  }
  else
  {
    Serial.println(F("CIPSTART: No Response"));
    return "Error";
  }

  // Send request - 
  Serial.println("CIPSEND...");
  Serial.print("AT+CIPSEND="); 
  Serial.print(httpReq.length());
  Serial.print("\r\n");

  ESP8266.print("AT+CIPSEND="); 
  ESP8266.print(httpReq.length()); // Specifies how much data is being sent
  ESP8266.print("\r\n");
  // while(ESP8266.available()) Serial.write(ESP8266.read());
  delay(500);

  if(ESP8266.find("OK")){
    Serial.println("Sent Request - ");
    Serial.print(httpReq);
    ESP8266.print(httpReq);
  }
  else{
    Serial.println("No request sent. Try again.");
  }

  int j = 0;
  while(!ESP8266.find("JMNR:"));
  {
    j++;
    Serial.print(j);
    if (j>50){
      Serial.println("Error - could not find JMNR");
      return "Error - could not find JMNR";
    }
  }

  Serial.println("Found JMNR:...");
  for (int i = 0; i<=18; i++)
  {
    while(!ESP8266.available());
    z = (char)ESP8266.read();
    Serial.write(z);
    resp.concat(z);
  }

  Serial.println("<-- END");
  
  return resp;
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

String getName(String response){
  Serial.println("In getname");
  response.remove(0,2);   //removes 'T' and a whitespace, also, this fxn is
                          //pass by copy, so we're not altering the reponse from before
  Serial.println(response);

  //find whitespace after name
  int k = 0;
  for(k; k < response.length(); k++){
      if(response[k] == ' '){
        break;
      }
  }

  int j = (16 - k);
  // now remove everything after index k, up to the last index (index 15)
  response.remove(k, j);

  return response;
}

String center(String toCenter){
  // Auto center the strings
  int a = toCenter.length();
  a = a + (a % 2);  //makes divisible by 2
  a = 16 - a;
  a = a/2;
  String center1 = "";
  for (a; a > 0; a--){    //for loop concatenates whitespaces to beginning of new array
    center1 += ' ';
  }
  center1 += toCenter;
  return center1;
}

