#include <SPI.h>
#include <MFRC522.h>
#include <SoftwareSerial.h>

// WARNING, WARNING ... DANGER, WILL ROBINSON, DANGER!!!
// The station ID is unique to each terminal and must be manually entered.
// Double and triple check this value is what you intend it to be.

#define STID      9                  // Station ID number 
#define RST_PIN   5   
#define SS_PIN    10 

///////////////////////////////// RFID Inits /////////////////////////////////////////

// RFID_UID will be stored and sent as a hex string
String RFID_UID ="";
MFRC522 RFID(SS_PIN, RST_PIN);  // Create mfrc522 instance
MFRC522::MIFARE_Key key;

void setup() {

    // Initialize Serial Communications
    Serial.begin(9600);   // with the PC for debugging displays
    delay(100);
    Serial.println(F("Serial checked! Waiting for RFID."));

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
        delay(100);
    } while ( !getPICC() );

    RFID_UID = GetRFID(RFID.uid.uidByte, RFID.uid.size);

    while(getPICC()) {
        Serial.println(RFID_UID);
    }

    RFID.PICC_HaltA();       // Halt PICC
    RFID.PCD_StopCrypto1();  // Stop encryption on PCD

    Serial.println(F("Waiting for", "RFID.."));
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
