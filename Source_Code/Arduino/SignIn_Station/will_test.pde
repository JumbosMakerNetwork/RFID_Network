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
const char DBIP[] = "172.16.95.216";

/////////////////////////////////// Hardware assignments /////////////////////////////

SoftwareSerial ESP8266(8, 9); // D9 -> ESP8266 RX, D10 -> ESP8266 TX

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
    ESP8266.begin(9600);

    while(!ESP8266_Check()){ delay(reset_delay); }
    Serial.println(F("esp8266 checked!"));

    while( !ESP8266_Mode(3) ){ delay(reset_delay); }
    Serial.println(F("esp8266 set to mode 3!"));

    display("Connecting", "To Wifi...");
    while( !connectWiFi() ){ delay(reset_delay); }
    Serial.println(F("esp8266 successfully connected to wifi!"));  
}


void loop() {
    delay(1000);
    String info = "hello";
    do {
        //for debugging: wait for serial commands while looping
        while(ESP8266.available()) Serial.write(ESP8266.read());
        while(Serial.available()) ESP8266.write(Serial.read());
        resp = ReqJMN( info);
        Serial.println(resp);
        delay(5000);
    } while ( 1 );
}

////////////////////////////////////////////////////////////////////////
/////////////////////// WIFI / DATABASE UTILITIES //////////////////////
////////////////////////////////////////////////////////////////////////

String ReqJMN(String RFID1, String req1, String info1)
{
    String resp="";
    char z;
    Serial.println(F("Starting request..."));

    String httpReq = "GET /handler.php?info=";
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
    while(!ESP8266.find("Success")) {
      delay(100);
      j++;
      Serial.print(j);
      if (j>50) {
        Serial.println(F("Error - could not find response"));
        return F("Error - could not find response");
      }
    }

    Serial.println(F("Found Success:..."));
    for (int i = 0; i<=18; i++) {
      while(!ESP8266.available());
      z = (char)ESP8266.read();
      Serial.write(z);
      resp.concat(z);
    }

    Serial.println(F("<-- END"));

    return resp;
}

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

