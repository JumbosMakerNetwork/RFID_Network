#include <SPI.h>
#include <MFRC522.h>
#include <SoftwareSerial.h>

// WARNING, WARNING ... DANGER, WILL ROBINSON, DANGER!!!
// The station ID is unique to each terminal and must be manually entered.
// Double and triple check this value is what you intend it to be.
//#define SID 2  // Station ID number  - needs to correlate with database setting

//////////////////////// Wireless network information //////////////////////////////////

const char SSID[] = "tuftswireless";

// PW = Empty string since network is not password protected. This particular network is 
// mac address registry based. We are not registering the mac addresses of these so
// they are limited to accessing internal IPs or websites hosted by Tufts. 
const char PSK[] = ""; 
// Static IP of the directory location
const char DBIP[] = "130.64.17.0";

#define STID 1                  // Station ID number 
#define RST_PIN   5   
#define SS_PIN    10 

///////////////////////////////// RFID Inits /////////////////////////////////////////

// RFID_UID will be stored and sent as a hex string
String RFID_UID ="";
MFRC522 RFID(SS_PIN, RST_PIN);  // Create mfrc522 instance
MFRC522::MIFARE_Key key;

/////////////////////////////////// Hardware assignments /////////////////////////////

SoftwareSerial ESP8266(8, 9); // D9 -> ESP8266 RX, D10 -> ESP8266 TX
SoftwareSerial LCD(3,2);        // D2 -> LCD TX, D3 -> LCD RX (unused)
#define greenLED 7
#define redLED   6
#define esp8266_rst_pin  A1
#define rst_pin_value 170
#define reset_delay 1000



void setup() {
    pinMode(esp8266_rst_pin, OUTPUT);
    digitalWrite(esp8266_rst_pin, LOW);
    pinMode(redLED, OUTPUT);
    pinMode(greenLED, OUTPUT);

    // Initialize Serial Communications
    Serial.begin(9600);   // with the PC for debugging displays
    LCD.begin(9600);      // With the LCD for external displays
    ESP8266.begin(9600);
    display("Welcome", "");

    while(!ESP8266_Check()){ delay(reset_delay); }
    display("esp8266", "checked!");
    Serial.println(F("esp8266 checked!"));

    while( !ESP8266_Mode(3) ){ delay(reset_delay); }
    Serial.println(F("esp8266 set to mode 3!"));

    display("Connecting", "To Wifi...");
    while( !connectWiFi() ){ delay(reset_delay); }
    Serial.println(F("esp8266 successfully connected to wifi!"));

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

        check_status();
        delay(100);
    } while ( !getPICC() );

    Serial.println(F("An RFID has been detected"));
    RFID_UID = GetRFID(RFID.uid.uidByte, RFID.uid.size);

    display("RFID", "Detected!");
    String info = "SignIn"; // Info constant for Sign IN/OUT stations.

    RFID.PICC_HaltA();       // Halt PICC
    RFID.PCD_StopCrypto1();  // Stop encryption on PCD

    String resp = "";
    resp = ReqJMN( RFID_UID, "3", info);
    Serial.println(resp);

    if (resp[0] == 'T') {
        digitalWrite(greenLED, HIGH);
        String name = getName(resp);
        Serial.println(resp);
        Serial.println(name);

        display("Thank you, ", name);
        delay(3000);
        digitalWrite(greenLED, LOW);  
    }

    else if (resp[0] == 'F') {
        digitalWrite(redLED, HIGH);  
        display("Insufficient","credentials");
        delay(2000);
        display("Get approved at","maker.tufts.edu");
        delay(2000);
        digitalWrite(redLED, LOW);  
    }

    else if (resp[0] == 'E') {
        // Blink the red light and give an error message.
        // Display a warning to get a staff member. 
        display("No ID found","in Database");
        digitalWrite(redLED, HIGH);  
        delay(3000);
        display("Get approved at","maker.tufts.edu"); 
        digitalWrite(redLED, LOW);
        delay(3000);
    }

    display("Waiting for", "RFID..");
}



//////////////////////RFID UTILITY FUNCTIONS//////////////////////
//////////////////////////////////////////////////////////////////

// Grab the hex values from a byte array, returns decimal equivalent
int getPICC() 
{
  // Getting ready for Reading PICCs
  if ( ! RFID.PICC_IsNewCardPresent()) { //If a new PICC placed to RFID reader continue
    return 0;
  }
  if ( ! RFID.PICC_ReadCardSerial()) {   //Since a PICC is placed, get Serial and continue
    return 0;
  }

  return 1;
}

String GetRFID(byte *buffer, byte bufferSize) 
{
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
    ESP8266.println(F("AT"));
    delay(200);
    if(ESP8266.find("OK")) {
      Serial.flush();
      return true;
    }
    
    else if(ESP8266.find("ERROR")) {
      Serial.println(F("RECEIVED: Error"));
      Serial.println(F("Trying again.."));
      return false;
    }
    else {
      Serial.println(F("RECEIVED: No Response"));
      Serial.println(F("Trying again.."));
      return false;
    }
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
      Serial.println(F("Trying again.."));
      return false;
    }
    else {
      Serial.println(F("RECEIVED: No Response"));
      Serial.println(F("Trying again.."));
      //reset device
      void(* resetFunc) (void) = 0;
      resetFunc();
      return false;
    }
    delay(100);
}


boolean connectWiFi()
{
    ESP8266.println(F("AT+CWJAP?"));
    delay(250);
    if(ESP8266.find("tuftswireless")) 
    {
        Serial.flush();
        while(ESP8266.available()) Serial.write(ESP8266.read());
        Serial.print(F("\n"));  
        // Serial.println(F("Already connected"));
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
    delay(500);
    while ( !ESP8266.available() ){
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
        return false;
    }
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

    ESP8266.print(F("AT+CIPSTART=\"TCP\",\""));
    ESP8266.print(DBIP);
    ESP8266.print(F("\",80\r\n"));

    delay(100);
    if(ESP8266.find("OK")) {
      Serial.println(F("CIPSTART: OK"));
    }
    
    else if(ESP8266.find("ERROR")) {
      Serial.println(F("CIPSTART: Error"));
      return "Error";
    }

    else {
      Serial.println(F("CIPSTART: No Response"));
      return "Error";
    }

    // Send request - 
    Serial.println(F("CIPSEND..."));
    Serial.print(F("AT+CIPSEND=")); 
    Serial.print(httpReq.length());
    Serial.print(F("\r\n"));

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
    while(!ESP8266.find("JMNR:")) {
      j++;
      Serial.print(j);
      if (j>50) {
        Serial.println(F("Error - could not find JMNR"));
        return F("Error - could not find JMNR");
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
void check_status()
{
      if( !ESP8266_Check() ) {
              display("Terminal", "Disconnected");
              while(!ESP8266_Check()) {
                    delay(reset_delay);
              }
              display("Terminal", "Connected");
              Serial.println("Terminal Connected.");
              delay(200);
              display("Waiting for", "RFID..");
       }
       /* if( !connectWiFi() ) {
              display("Wifi", "Disconnected");
              while(!connectWiFi()) {
                    delay(reset_delay);
              }
              display("Wifi", "Connected");
              delay(200);
              display("Waiting for", "RFID..");
       } */
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

String getName(String response)
{
    Serial.println(F("In getname"));
    response.remove(0,2);   //removes 'T' and a whitespace, also, this fxn is
                            //pass by copy, so we're not altering the reponse from before
    Serial.println(response);

    //find whitespace after name
    int k = 0;
    for(k; k < response.length(); k++) {
        if(response[k] == ' '){
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
    // Auto center the strings
    int a = toCenter.length();
    a = a + (a % 2);  //makes divisible by 2
    a = 16 - a;
    a = a/2;
    String center1 = "";
    
    //for loop concatenates whitespaces to beginning of new array
    for (a; a > 0; a--){    
        center1 += ' ';
    }
    center1 += toCenter;
    return center1;
}

