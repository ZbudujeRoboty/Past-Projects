#include <Keypad.h>             //biblioteka klawiatury
#include <Adafruit_NeoPixel.h>  //biblioteka linijki LED

#define buzzer 11
#define kontaktron 10
#define PIR 1

const byte ROWS = 4; //ile wierszy
const byte COLS = 4; //ile kolumn

byte rowPins[ROWS] = {5, 4, 3, 2}; //piny wierszy
byte colPins[COLS] = {6, 7, 8, 9}; //piny kolumn

char keys[ROWS][COLS] = { //mapowanie klawaitury - tablica dwuwymiarowa
  {'1','2','3','A'},
  {'4','5','6','B'},
  {'7','8','9','C'},
  {'*','0','#','D'}
};

volatile int stanAlarmu = 1;  //zmienna wykorzystywana do maszyny stanów (funkcji switch)
int pinAlarmuPozycja = 1;     //zmienna pomocnicza do wpisywania hasla
char kodCyfra1 = '1';         //Ustawienei HASŁA!
char kodCyfra2 = '2';
char kodCyfra3 = '3';
char kodCyfra4 = '4';
int czasNaUcieczke = 5;       //Tutaj ustawiamy ile mamy czasu na ucieczke po uzbrojeniu alarmu [s]
int ileCzasuMinelo = 0;       //licznikowa zmienna pomocnicza do ograniczonego czasu wpisywania kodu
int czasNaKod = 10;           //Tutaj ustawiamy ile mamy czasu na wpisanie kodu [s]

Keypad klawiatura = Keypad( makeKeymap(keys), rowPins, colPins, ROWS, COLS); //inizjalizacja klawiatury - dodawnie obiektu "klawiatura"
Adafruit_NeoPixel linijka = Adafruit_NeoPixel(8, A0, NEO_GRB + NEO_KHZ800);

void setup() {
  pinMode(buzzer, OUTPUT);
  pinMode(kontaktron, INPUT_PULLUP);
  pinMode(PIR, INPUT_PULLUP);
  linijka.begin();
  linijka.show();
}

void loop() {
  char klawisz = 0;
  int i = 0;
  switch(stanAlarmu) {
    case 1:   //Czuwanie
      linijka.setPixelColor(0, linijka.Color(0,15,0)); //Dioda 0 na zielono
      linijka.show();
      klawisz = klawiatura.getKey();
      if (klawisz  == 'A'){
        for(i=0; i<8; i++){
          linijka.setPixelColor(i, linijka.Color(0,0,15)); //Dioda i na niebiesko
          linijka.show();
          tone(buzzer,300);
          delay(25*czasNaUcieczke);
          noTone(buzzer);
          delay(100*czasNaUcieczke);           //tutaj zmiana czasu na ucieczke
        }
        wylaczDiody();
        stanAlarmu = 2;
      }
    break;

    case 2:   //Monitorowanie
      linijka.setPixelColor(7, linijka.Color(15,0,0)); //Dioda 7 na czerwono
      linijka.show();
      delay(50);
      linijka.setPixelColor(7, linijka.Color(0,0,0)); //Dioda 7 OFF
      linijka.show();
      delay(50);

      if(digitalRead(PIR) == HIGH){
        stanAlarmu = 4; //Natychmiastowy alarm
      }else if (digitalRead(kontaktron) == HIGH){
        ileCzasuMinelo = 0; //Zerowanie licznika tuz przez przesciem do stanu rozbrajania
        stanAlarmu = 3; //Szansa na rozbrojenie
      }
    break;

    case 3:   //Rozbrajanie
      klawisz = klawiatura.getKey();
      if(klawisz){
        //Czy kolejna podana cyfra jest poprawna?
        if(pinAlarmuPozycja == 1 && klawisz == kodCyfra1){ //sprawdzamy 1 pozycje Pinu
          pinAlarmuPozycja ++; //Cyfra poprawna, wiec mozna sprawdzic kolejna
          tone(buzzer,500);
          delay(50);
          noTone(buzzer);
        } else if(pinAlarmuPozycja == 2 && klawisz == kodCyfra2){
          pinAlarmuPozycja ++;
          tone(buzzer,500);
          delay(50);
          noTone(buzzer);
        } else if(pinAlarmuPozycja == 3 && klawisz == kodCyfra3){
          pinAlarmuPozycja ++;
          tone(buzzer,500);
          delay(50);
          noTone(buzzer);
        } else if(pinAlarmuPozycja == 4 && klawisz == kodCyfra4){
          stanAlarmu = 1; //Wszystkie 4 cyfry kodu są poprawne - czuwanie
          pinAlarmuPozycja = 1;
          tone(buzzer,500);
          delay(50);
          noTone(buzzer);
          tone(buzzer,1000);
          delay(100);
          noTone(buzzer);
        } else {
          stanAlarmu = 4; // Blad w kodzie - wlacz alarm!
          pinAlarmuPozycja = 1;
        }
      }
      delay(100);
      ileCzasuMinelo++; //1 sekunda = 10*ileCzasuMinelo
      if(ileCzasuMinelo >= 10*czasNaKod) {
        stanAlarmu = 4;
      }
    break;

    case 4:   //Alarm
      for(i=0;i<8;i++){
        linijka.setPixelColor(i,linijka.Color(255,0,0)); //Dioda i na czerwono
      }
      linijka.show();
      tone(buzzer,4300);
      delay(200);
      for(i=0;i<8;i++){
        linijka.setPixelColor(i,linijka.Color(0,0,255)); //Dioda i na niebiesko
      }
      linijka.show();
      tone(buzzer, 3500);
      delay(200);
    break;
  }
}

void wylaczDiody(){
  int i = 0;
  for(i=0; i<8; i++){
    linijka.setPixelColor(i,linijka.Color(0,0,0)); //Dioda i OFF
  }
  linijka.show();
}
