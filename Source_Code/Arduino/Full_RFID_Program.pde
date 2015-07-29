#include <SPI.h>
#include <MFRC522.h>
#include <SoftwareSerial.h>
#include <SparkFunESP8266WiFi.h>

// Physical components
const int OVRD = A0; // Keylock overide
const int DECL = A1; // Red LED
const int APPR = A2; // Green LED
const int INTLK = 4; // Interlock pin

// WARNING, WARNING ... DANGER, WILL ROBINSON, DANGER!!!
// The station ID is unique to each terminal and must be manually entered.
// Double and triple check this value is what you intend it to be.
#define SID 1  // Station ID number  

// Wireless network information
const char SSID[] = "tuftswireless";
const char PSK[] = "";
const char DBIP[] = "130.64.17.0";

#define RST_PIN   5   // 
#define SS_PIN    10  // 

boolean present=false; // Boolean variables to track card
boolean card=false;

// For the timer
unsigned long t0 = 0;
unsigned long t1 = 0;
unsigned long t2 = 0;
String timer = "";

unsigned long RFID_UID;

MFRC522 RFID(SS_PIN, RST_PIN);  // Create mfrc522 instance
MFRC522::MIFARE_Key key;
// SoftwareSerial ESP8266(8, 9); 
    // D8 -> ESP8266 RX, D9 -> ESP8266 TX (Set by Sparkfun Shield)
SoftwareSerial LCD(3,2);     // D2 -> LCD TX, D3 -> LCD RX (unused)


void setup() {
  // Turn off all lights and signals
  pinMode(OVRD, INPUT);
  digitalWrite(A0, HIGH); //Set 
  pinMode(DECL, OUTPUT);
  digitalWrite(DECL, LOW);
  pinMode(APPR, OUTPUT);
  digitalWrite(APPR, LOW);
  pinMode(INTLK, OUTPUT);
  digitalWrite(INTLK, LOW);
  // Initialize Serial Communications
  Serial.begin(9600);   // with the PC for debugging displays
  LCD.begin(9600);      // With the LCD for external displays


  display("Booting", "  up...");
  delay(500);
  int retVal;
  retVal = esp8266.connect(SSID, PSK);
  if (retVal < 0)
  {
    Serial.print(F("Error connecting: "));
    Serial.println(retVal);
  }

  while (!Serial);    // Do nothing if no serial port is opened (added for Arduinos based on ATMEGA32U4)
  SPI.begin();      // Init SPI bus
  RFID.PCD_Init();    // Init MFRC522
  Serial.println(F("And it begins..."));
  
  // Prepare the key (used both as key A and as key B)
  // using FFFFFFFFFFFFh which is the default at chip delivery from the factory
  for (byte i = 0; i < 6; i++) {
    key.keyByte[i] = 0xFF;
  }
  Serial.println(F("Scan a MIFARE Classic PICC to demonstrate read and write."));
  Serial.print(F("Using key (for A and B):"));
  GetRFID(key.keyByte, MFRC522::MF_KEY_SIZE);
  Serial.println();
}




void loop() {
  // Check to see if override is engaged
  if (digitalRead(A0) == LOW){
    digitalWrite(INTLK, HIGH);
    display("Override","Engaged");
    digitalWrite(DECL, HIGH);
    delay(500);
    digitalWrite(DECL, LOW);
    delay(250);
    return;
  }
  // This needs to be here since the Halt causes issues with the timing.
  // By having 2 calls, it's always even (Which flips the 
  card = RFID.PICC_IsNewCardPresent();
  
  delay(500);
  // Look for new cards
  if ( ! RFID.PICC_IsNewCardPresent()) {
    if (present==true){
      Serial.println(F("The RFID has been lost"));
      t1 = millis();
      t2 = t1 - t0;
      t2 = t2/1000;
      timer = String(t2);
      timer += " Seconds";
      Serial.print(F("Elapsed time - "));
      Serial.print(timer);
      // Here is where you can send the time to the database
      ReqJMN(String(RFID_UID), "2", timer);
    }
    digitalWrite(DECL, LOW);
    digitalWrite(APPR, LOW);
    digitalWrite(INTLK, LOW);
    present = false;
    return;
  }
  
  if ( ! RFID.PICC_ReadCardSerial()) return;

  if (present==false){
    present=true;
    Serial.println(F("An RFID has been detected"));
    t0 = millis();
    Serial.print(F("Card UID:"));
    RFID_UID = GetRFID(RFID.uid.uidByte, RFID.uid.size);
    Serial.println();

    // Here is where you can ping the database for permissions
    ReqJMN(String(RFID_UID), "1", "N/A");
  }
  


  // Stop encryption on PCD
  RFID.PCD_StopCrypto1();
}





// Grab the hex values from a byte array, returns decimal equivalent
long int GetRFID(byte *buffer, byte bufferSize) {
  Serial.print(" ");
  String tmp = "";
  String tmp2;
  for (byte i = 0; i < bufferSize; i++) {
    tmp2 = "";
    tmp2 += String(buffer[i] < 0x10 ? "0" : "");
    tmp2 += String(buffer[i], HEX);
    tmp = tmp2 + tmp;
  }
  tmp.toUpperCase();
  Serial.print(tmp);
  Serial.print("\t");
  Serial.println(hexToDec(tmp));
  return hexToDec(tmp);
}

// Convert a hex string to a long int
long int hexToDec(String hexString) {
  long int decValue = 0;
  int nextInt;
  for (int i = 0; i < hexString.length(); i++) {
    nextInt = int(hexString.charAt(i));
    if (nextInt >= 48 && nextInt <= 57) nextInt = map(nextInt, 48, 57, 0, 9);
    if (nextInt >= 65 && nextInt <= 70) nextInt = map(nextInt, 65, 70, 10, 15);
    if (nextInt >= 97 && nextInt <= 102) nextInt = map(nextInt, 97, 102, 10, 15);
    decValue = (decValue * 16) + nextInt;
  }
  return decValue;
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

// Function to display a system error and instructions
void SystemError(String error1, String error2)
{
  String Ecmd1 = " ";
  String Ecmd2 = " ";
  while(digitalRead(A0) == HIGH){
    digitalWrite(DECL, HIGH);
    digitalWrite(APPR, LOW);
    Ecmd1 = error1;
    Ecmd2 = error2;
    display(error1, error2);
    delay(500);
    digitalWrite(DECL, LOW);
    digitalWrite(APPR, HIGH);
    delay(500);
    digitalWrite(DECL, HIGH);
    digitalWrite(APPR, LOW);
    Ecmd1 = "PLEASE CONTACT";
    Ecmd2 = " A STAFF MEMBER";
    display(error1, error2);
    delay(500);
    digitalWrite(DECL, LOW);
    digitalWrite(APPR, HIGH);
    delay(500);
  }
}

boolean connectESP8266()
{
  // Check communication with the ESP8266
  // Initialize the ESP8266 and check it's return status
  if (esp8266.begin()){
    Serial.println(F("ESP8866 ready to go!"));
    display("ESP8266 Ready.","");
    delay(250);
  }
  else{
    Serial.println(F("Communicate with the ESP8266 failed."));
    return false;
  }
  // Set the ESP8266 mode to Station/AP combo
  int retVal = esp8266.getMode();
  int ESP8266_MOD_STAAP = 3;
  if (retVal != ESP8266_MOD_STAAP){
    retVal = esp8266.setMode(ESP8266_MOD_STAAP);
    if (retVal < 0){
      Serial.println(F("Error setting mode."));
      return false;
    }
  }
  Serial.println(F("Mode set to Station/AP"));
  // Connect to tufts-guest wireless network
  retVal = esp8266.connect(SSID,PSK);
  if (retVal < 0){
    Serial.println(F("Error Connecting"));
    return false;
  }
  Serial.println(F("Connected to tufts-guest."));
  display("Connected to"," tufts-guest ");
  delay(250);
  return true;
}

String ReqJMN(String RFID1, String req, String info)
{
  Serial.println(F("Contacting JMN Database."));
  ESP8266Client JMN; // Create a client object
  delay(100);
  int retVal = JMN.connect(DBIP, 80); // Connect to sparkfun (HTTP port)
  if (retVal <= 0) {
    Serial.println(F("Could not connect"));
    display("Could not","connect.");
    delay(100);
    return "Error";
  }
  Serial.println(F("Successfully connected!"));
  display("Successfully","connected!");
  delay(100);
  display("Sending","  Request");
  String cmd = "GET /Terminal.php?sid=";
  cmd += SID;
  cmd += "&rfid=";
  cmd += RFID1;
  cmd += "&req=";
  cmd += req;
  cmd += "&info=";
  cmd += info;
  cmd += " HTTP/1.0\r\n\r\n";
  JMN.print(cmd);
  delay(250);

  String response = "";
  char character;
  display("Reading","  Response");
  while (JMN.available()) // While there's data available
  {
    character = JMN.read();
    response.concat(JMN.read());
  }

  if (response != "") {
    Serial.println(response);
  }
  
  JMN.stop();
//  if (JMN.connected())
//  {
//    JMN.stop();
//  }

  int loc = find_text("Access",response);
  response = response.substring(loc);

}

void Access(String Response)
{
  String fname = Response.substring(14);
  if (String(Response.charAt(7)) == "T")
  {
    digitalWrite(APPR, HIGH);
    digitalWrite(INTLK, HIGH);
    display("Access Granted",fname);
    Serial.print(F("Access Granted for "));
    Serial.println(fname);
  }
  else if (String(Response.charAt(7)) == "F")
  {
    digitalWrite(DECL, HIGH);
    digitalWrite(INTLK, LOW);
    display("Access Denied","");
    Serial.println(F("Access Denied for "));
    Serial.println(fname);
  }
  else
  {
    digitalWrite(DECL, HIGH);
    digitalWrite(APPR, HIGH);
    digitalWrite(INTLK, LOW);
    display("Error occured"," ");
    Serial.println(F("Error ocurred"));
  }
}




// For searching through a String to get the 
int find_text(String needle, String haystack) {
  int foundpos = -1;
  for (int i = 0; (i < haystack.length() - needle.length()); i++) {
    if (haystack.substring(i,needle.length()+i) == needle) {
      foundpos = i;
    }
  }
  return foundpos;
}






