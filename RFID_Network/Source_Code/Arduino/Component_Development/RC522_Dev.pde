#include <SPI.h>
#include <MFRC522.h>
#include <SoftwareSerial.h>

#define RST_PIN   5   // 
#define SS_PIN    10    //

boolean present=false; // Boolean variables to track card
boolean card=false;

// For the timer
unsigned long t0 = 0;  
unsigned long t1 = 0;
unsigned long t2 = 0;

MFRC522 RFID(SS_PIN, RST_PIN);  // Create mfrc522 instance
MFRC522::MIFARE_Key key;
SoftwareSerial ESP8266(8, 9); // D8 -> ESP8266 RX, D9 -> ESP8266 TX (Set by Sparkfun Shield)
SoftwareSerial LCD(3,2);     // D2 -> LCD TX, D3 -> LCD RX (unused)


void setup() {
  Serial.begin(9600);   // Initialize serial communications with the PC
  LCD.begin(9600); // set up serial port for 9600 baud
  display("Booting", "  up..."); 
  delay(1500);
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
  dump_byte_array(key.keyByte, MFRC522::MF_KEY_SIZE);
  Serial.println();
}

void loop() {
  // This needs to be here since the Halt causes issues with the timing.
  // By having 2 calls, it's always even (Which flips the 
  card = RFID.PICC_IsNewCardPresent();
  
  delay(500);
  // Look for new cards
  if ( ! RFID.PICC_IsNewCardPresent()) {
    if (present==true){
      Serial.println("The RFID has been lost");
      t1 = millis();
      t2 = t1 - t0;
      t2 = t2/1000;
      Serial.print("Elapsed time - ");
      Serial.print(t2);
      Serial.println(" seconds");
    }
    present = false;
    return;
  }
  
  if ( ! RFID.PICC_ReadCardSerial()) return;

  if (present==false){
    present=true;
    Serial.println("An RFID has been detected");
    t0 = millis();
    Serial.print(F("Card UID:"));
    dump_byte_array(RFID.uid.uidByte, RFID.uid.size);
    Serial.println();
  }
  
  // Stop encryption on PCD
  RFID.PCD_StopCrypto1();
}

void dump_byte_array(byte *buffer, byte bufferSize) {
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
}

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
