//Symulacja napełniania zbiornika cieczą

#include <Adafruit_NeoPixel.h>

#define yellow 2
#define red 3
#define blue 4
#define btn1 5
#define btn2 6
#define pot1 A1
#define pot2 A2

Adafruit_NeoPixel linijka = Adafruit_NeoPixel(8,A0, NEO_GRB + NEO_KHZ800);

float fsf = 0.0;  //filling speed factor 0-1 (1 -> m^3/s)
float esf = 0.0;  //emptying speed factor 0-1
bool filling = true;
bool emptying = false;
bool alarm = false; //>85%
bool over = false;  //>100%
bool spill = false; //>120%
long int base = 314159;  //m^2 / 10^5
long int capacity = 12566000;  //Pojemnosc zbiornika [ml]
long int ACapacity = 0;  //Actual capacity [ml]
int level = 0;  //mm
int diody = 0;  //ile diod ma się zapalić nalinijce led

void setup() {
  pinMode(yellow, OUTPUT);
  pinMode(red, OUTPUT);
  pinMode(blue, OUTPUT);
  pinMode(btn1, INPUT_PULLUP);
  pinMode(btn2, INPUT_PULLUP);
  digitalWrite(yellow, LOW);
  digitalWrite(red, LOW);
  digitalWrite(blue, LOW);
  Serial.begin(9600);
  linijka.begin();
  linijka.show();
  Serial.print("fill\t");
  Serial.print("empty\t");
  Serial.print("fsf\t");
  Serial.print("esf\t");
  Serial.print("Objetosc [l]\t");
  Serial.println("level [m]");
}

void loop() {
  if(digitalRead(btn1) == LOW){
    filling = true;
  }else{
    filling = false;
  }
  if(digitalRead(btn2) == LOW){
    emptying = true;
  }else{
    emptying = false;
  }

  fsf = map(analogRead(pot1), 0, 1023, 0.0, 1000.0) / 1000.0;
  esf = map(analogRead(pot2), 0, 1023, 0.0, 1000.0) / 1000.0;
  
  if(filling == true){
    ACapacity += fsf*pow(10,6);
  }
  if(emptying == true){
    ACapacity -= esf*pow(10,6);
  }
  delay(1000);

  if(ACapacity < 0) ACapacity = 0;  //zabezpieczenie przed ujemą objętnością
  if(ACapacity > 1.2*capacity){     //wylewanie (zabezpieczenie przed przekroczeniem maksymalnej, krytycznej pojemnosci zbiornika
    ACapacity = 1.2*capacity;
    spill = true;    
  }else{
    spill = false;
  }
  if(ACapacity > capacity){     //Przepełnienie
    over = true;
  }else{
    over = false;
  }
  if(ACapacity > 0.85*capacity){    //Stan alarmowy
    alarm = true;
  }else{
    alarm = false;
  }

  level = (ACapacity / base)*100; //mm

  if(alarm == true){
    digitalWrite(yellow, HIGH);
  }else{
    digitalWrite(yellow, LOW);
  }
  if(over == true){
    digitalWrite(red, HIGH);
  }else{
    digitalWrite(red, LOW);
  }
  if(spill == true){
    digitalWrite(blue, HIGH);
  }else{
    digitalWrite(blue, LOW);
  }

  diody = map(level, 0, 4200, 0, 8);
  linijka.clear();
  for(int i=0; i<diody; i++){
    linijka.setPixelColor(i, linijka.Color(0,0,255)); //ustawienie i-tej diody na niebieski
  }
  linijka.show();
  

  Serial.print(filling);
  Serial.print("\t");
  Serial.print(emptying);
  Serial.print("\t");
  Serial.print(fsf);
  Serial.print("\t");
  Serial.print(esf);
  Serial.print("\t");
  Serial.print(ACapacity/1000);
  Serial.print("\t\t");
  Serial.println(level/1000.0);
  
}
