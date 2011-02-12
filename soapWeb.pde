/*
  soap web client
 
 created 11 Feb 2011
 by Andrew LeCain
 
 */

//#include <SPI.h> 
#include <Ethernet.h>
#include <OneWire.h>

#define SIDE "n"
#define LOCATION "Stairs"

//One wire declarations

OneWire  ds1(14);  // on pin 14
byte     addr[8];
char     buf[19];

////////////////////////////////////////////////////////////////////////
// MAC address and IP for device
////////////////////////////////////////////////////////////////////////
// The IP address will be dependent on your local network:
int retries = 4;
byte mac[] = {  0xDE, 0xAD, 0xBE, 0xEF, 0xF0, 0x0D };
byte ip[] = { 129,21,50,68 };
byte gateway[] = { 129,21,50,254 };
byte subnet[] = { 255,255,255,0 };

////////////////////////////////////////////////////////////////////////
//  Modify to point to soapd server
////////////////////////////////////////////////////////////////////////
byte server[] = { 129,21,50,34};//ip address
Client client(server, 7628);//port

void setup() {

  Ethernet.begin(mac, ip);
  Serial.begin(9600);
  Serial.println("READY!");

}

void loop()
{
  
  if(getIButton(addr)){
      if(!sendRequest(addr,retries)){
        Serial.print("Resetting");
        resetETH();
      }
      else{
        Serial.println("Great success!");
      }
  }
  
  if (client.available()){
     Serial.print(client.read());//flush the buffer
  }

  if (!client.connected()) {
    client.stop();
    
  }
}


/////////////////////////////////////////////////////
//Ethernet support functions
/////////////////////////////////////////////////////

void resetETH(){
  pinMode(9,OUTPUT);
  digitalWrite(9,LOW);//reset
  delay(500);
  digitalWrite(9,HIGH);//not reset
  delay(500);  
  
}

int sendRequest(byte* addr,int retries){
 
  Serial.println("connecting...");

  // if you get a connection, report back via serial:
  for(int i=0; i<retries;i++){
    delay(1000);
    if (client.connect()) {
      Serial.println("connected");
      
      while (client.available()) {
        char c = client.read();
        Serial.print(c);
      } 

      // Make a HTTP request:
      client.print(SIDE"\r\n");
      client.print(LOCATION"\r\n");
      
      sprintf(buf, "%02X%02X%02X%02X%02X%02X%02X%02X\r\n",
              addr[7], addr[6], addr[5], addr[4],
              addr[3], addr[2], addr[1], addr[0]); 
      
      
      client.print(buf);
      //client.print("DD00000E4220DA01\r\n");


      return true;

    } 
   
    else {
      // if you didn't get a connection to the server:
      Serial.println("connection failed, retrying");
    }
  } 
  return false;
}

/////////////////////////////////////////////////////////////////
//One wire shit
/////////////////////////////////////////////////////////////

int getIButton(byte* addr1){
 
  byte i = 01;
  
  if ( !ds1.search(addr1)) {
     ds1.reset_search();
     return false;
     
  } else {
     for( i = 8; i >= 1; i--) {
       if (addr1[i-1] < 16) {
         Serial.print("0");
       }
       Serial.print(addr1[i-1], HEX);
     }
     Serial.println();
     return checkCRC(addr1);
  }
}

int checkCRC(byte addr[8]) {
  if ( OneWire::crc8( addr, 7) != addr[7]) {
      Serial.print("CRC is not valid!\n");
      return false;
  }
  return true;
}


