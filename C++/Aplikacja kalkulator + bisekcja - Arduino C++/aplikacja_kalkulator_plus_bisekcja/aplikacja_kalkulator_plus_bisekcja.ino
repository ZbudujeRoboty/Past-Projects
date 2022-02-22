/*  Aplikacja łącząca:
 *  KALKULATOR
 *  GRĘ - BISEKCJE
 *  
 *  Arduino UNO + Wyświetlacz LCD 16x2 + I2C Module + Klawiatura matrycowa 4x4 + buzer z generatorem
 *  
 *  Jan Brzyk 2020
 */

#include <Wire.h>
#include <Keypad.h>                 //biblioteka klawiatury
#include <LiquidCrystal_I2C.h>      //biblioteka wyswietlacza LCD + modułu i2c

#define buzz 10 //buzzer z generatorem

//custom char - cross "X"
uint8_t cross[8] = {0x0, 0x1b, 0xe, 0x4, 0xe, 0x1b, 0x0};

//Klawiatura
const byte ROWS = 4; //ile wierszy
const byte COLS = 4; //ile kolumn
byte rowPins[ROWS] = {5, 4, 3, 2}; //piny wierszy
byte colPins[COLS] = {9, 8, 7, 6}; //piny kolumn
char keys[ROWS][COLS] = { //mapowanie klawaitury - tablica dwuwymiarowa
  {'1','2','3','+'},
  {'4','5','6','-'},
  {'7','8','9','*'},
  {'.','0','=','/'}
};
Keypad klawiatura = Keypad( makeKeymap(keys), rowPins, colPins, ROWS, COLS); //inizjalizacja klawiatury - dodawnie obiektu "klawiatura"

//Wyswietlacz LCD 16x2
LiquidCrystal_I2C lcd(0x27, 16, 2); //Ustawienie adresu LCD na 0x27 (Nie ma zworek na A1,A2,A3 na module IC2

//zmienne globalne kalkulator
 int licz1 = 0; //zmienna pomocnicza do okreslenia miejsca kursora dla pierwszej liczby (numerowanie od 0 do 9)
 int licz2 = 0; //zmienna pomocnicza do okreslania miejsca kursora dla drugiej liczby (numerowanie od 0 do 9)
 int row = 1; //zmienna pomocnicza okreslajaca ktora liczbe wpisujemy (1 ub 2)
 int liczba1[5]; //pomocniczy wektor o dlugosci 5 do przechowywania cyfr pierwszej liczby (0-4)
 int liczba2[5]; //pomocniczy wektor o dlugosci 5 do przechowywania cyfr drugiej liczby (0-4)
 int size1 = sizeof(liczba1)/sizeof(liczba1[0]); //sizeof(tab)/sizeof(tab[0]) = rozmiar tablicy 
 int size2 = sizeof(liczba2)/sizeof(liczba2[0]);
 long int wart1 = 0;  //ostateczna wartosc pierwszej liczby
 long int wart2 = 0;  //ostateczna wartosc drugiej liczby
 char znak = 'x'; //zmienna pomocnicza do przechowywania aktualnie używanego znaku
 long int wynik = 0; //zmienna przechowujaca wynik operacji

//zmienne globalne bisekcja
 int maks = 1000; //GLOWNA ZMIENNA GORNY PRZEDZIAL    -     -     -     -     -     -     -                            
 bool again = true;  //zmienna kontrolujaca ponowne granie                                |   
 bool writing = true;  //zmienna kontrolujace wpisywanie z klawiatury
 bool writing2 = true; //zmienna kontrolujaca TAK/NIE pod koniec
 int licz = 0;   //zmienna pomocnicza okreslajaca ile zostalo wpisane cyfr                |
 int liczba[4];  //pomocniczy wektor o dlugosci 3 przechowujacy cyfry liczby (0-2)  <   - ilosc cyfr
 int size0 = sizeof(liczba)/sizeof(liczba[0]);
 int x = 0; //losowana liczba
 int los = 0; //typ gracza
 int ile_prob = 0;

//zmienne globalne menu
 bool writing3 = true;

void setup() {
  lcd.begin();  //inicjalizacja wyswietlacza lcd
  lcd.clear();
  pinMode(buzz,OUTPUT);
}

void menu(){
  lcd.clear();
  lcd.setCursor(6,0);
  lcd.print("Menu");
  delay(1500);
  lcd.clear();
  lcd.print("Kalkulator - 1");
  lcd.setCursor(0,1);
  lcd.print("Gra Bisekcja - 2");
  bool writing3 = true;
  while(writing3 == true){
    char klawisz = 'x';
    klawisz = klawiatura.getKey();
    if(klawisz == '1'){
      kalkulator();
      writing3 = false;
    }
    if(klawisz == '2'){
      bisekcja();
      writing3 = false;
    }
  }
}

void kalkulator(){
  lcd.clear();
  lcd.setCursor(3,0); //środek wyswietlacza dla nastepujacego napisu
  lcd.print("KALKULATOR");

  while(true){  //nieskonczona petla kalkulatora
    char klawisz = 'x';
    klawisz = klawiatura.getKey();

    if(row == 1){
      //WPISANIE PIERWSZEJ LICZBY
      if(klawisz=='1'||klawisz=='2'||klawisz=='3'||klawisz=='4'||klawisz=='5'||klawisz=='6'||klawisz=='7'||klawisz=='8'||klawisz=='9'||klawisz=='0'){
        if(klawisz == '0' && licz1 == 0){ //pierwsza wpisana liczba to zero
          //nie możemy zacząć liczby od zera, więc nie robimy tutaj nic
        }else{
          if(licz1 == 0){ //pierwsza wpisywana cyfra czyści wyswietlacz
            lcd.clear(); //RESET
            memset(liczba1, 0, size1*sizeof(int)); //wyzerowanie wektora (memset operuje na bajtach). 
            memset(liczba2, 0, (sizeof(liczba2)/sizeof(liczba2[0]))*sizeof(int));
            wynik = 0; //reset wyniku tutaj, bo możliwa jest operacja na wyniku jako pierwszej liczbie
          }
          lcd.print(klawisz); //wypisanie cyfry na wyswietlaczu
          liczba1[licz1] = klawisz - 48; //wpisanie cyfry do wektora pomocniczego (odjęcie 48 to powrót z kodu ASCII)
          licz1++; //inkrementacja zmiennej pomocniczej
          if(licz1 > size1){ //procedura informujaca o za duzej ilosc wpisanych cyfr
            zaduzo();
          }
       }
      //WPISANIE PLUSA, MINUSA, RAZY, PODZIEL
      } else if(klawisz == '+' || klawisz == '-' || klawisz == '*' || klawisz == '/'){
        if(licz1 == 0 && wynik != 0){ //pierwsza wpisana rzecz to znak, a wynik nie jest zerowy        
          lcd.clear();
          lcd.print(wynik);
          lcd.print(" ");
          lcd.print(klawisz);
          znak = klawisz;
          row = 2;
          wart1 = wynik;
        }else if(licz1 != 0){
          lcd.print(" "); //odstęp między liczbą a znakiem
          lcd.print(klawisz);
          znak = klawisz; //przypisanie wpisanego znaku do zmiennej znak
          row = 2;  //zmiana na drugi rząd (oczekiwanie wpisania drugiej liczby
        }
      } else if(klawisz == '='){
        lcd.print("XDD"); ////////////////////////DO ZROBIENIA PONOWNE "="
      }
    } else if(row == 2){
      //WPISANIE DRUGIEJ LICZBY
      if(klawisz=='1'||klawisz=='2'||klawisz=='3'||klawisz=='4'||klawisz=='5'||klawisz=='6'||klawisz=='7'||klawisz=='8'||klawisz=='9'||klawisz=='0'){
        if(licz2 == 0){ //pierwsza wpisywana cyfra w drugim rzędzie
          lcd.setCursor(0,1); //ustawienie kursora na początku drugiego wiersza
        }
        if(klawisz == '0' && licz2 == 0){ //pierwsza wpisana liczba to zero
          //nie możemy zacząć liczby od zera, więc nie robimy tutaj nic
        }else{
          lcd.print(klawisz); //wypisanie cyfry na wyswietlaczu
          liczba2[licz2] = klawisz - 48; //wpisanie cyfry do wektora pomocniczego (odjęcie 48 to powrót z kodu ASCII)
          licz2++; //inkrementacja zmiennej pomocniczej
          if(licz2 > size2){ //procedura informujaca o za duzej ilosc wpisanych cyfr
            zaduzo();
          }
        }
      //WPISANIE ZNAKU RÓWNOŚCI
      }else if(klawisz == '='){
        if(licz2 != 0){ //jeżeli cokolwiek jest wpisane jako druga liczba
          for(int i = 0; i < licz1; i++){  //policzenie wartosci ostatecznej pierwszej liczby (licz1 - ile cyfr ma liczba)
            int ii = (-1)*i + licz1 - 1;  //funkcja zależności między kolejną cyfrą a potęgą tej cyfry (ii=f(i)=-i+licz1)
            wart1 += liczba1[i]*int(pow(10, ii)+0.5);  //funkcja pow zwraca typ float, więc potrzebna jest prosta konwersja float -> int
          }
          for(int j = 0; j < licz2; j++){ //policzenie wartosci ostatecznej drugiej liczby
            int jj = (-1)*j + licz2 - 1;  //funkcja zależności między kolejną cyfrą a potęgą tej cyfry (ii=f(i)=-i+licz1)
            wart2 += liczba2[j]*int(pow(10, jj)+0.5);  //funkcja pow zwraca typ float, więc potrzebna jest prosta konwersja float -> int 
          }
          if(znak == '+'){  //dodawanie
            wynik = wart1 + wart2;
          }
          if(znak == '-'){  //odejmowanie
            wynik = wart1 - wart2;
          }
          if(znak == '*'){  //mnozenie
            wynik = wart1 * wart2;
          }
          if(znak == '/'){ //dzielenie
            wynik = wart1 / wart2;
          }
          lcd.clear();
          lcd.print("="); //w pierwszym wierszu "="
          lcd.setCursor(0,1); //w drugim wierszy wynik
          lcd.print(wynik);
          //Procedura resetu
          licz1 = 0;
          licz2 = 0;
          row = 1;
          wart1 = 0;
          wart2 = 0;
          znak = 'x';
        }
      }
    }
  }
}

void bisekcja(){ 
  lcd.clear();
  lcd.createChar(0, cross);
  lcd.setCursor(2,0);
  lcd.write(0);
  lcd.setCursor(4,0);
  lcd.print("BISEKCJA");  //Nazwa gry
  lcd.setCursor(13,0);
  lcd.write(0);
  lcd.setCursor(3,1);
  lcd.print("Prosta gra");
  delay(3000);
  lcd.clear();        //zasady
  lcd.setCursor(5,0);
  lcd.print("Witaj!");
  delay(1500);
  lcd.clear();
  lcd.print("Pomyslalem sobie");
  lcd.setCursor(0,1);
  lcd.print("liczbe z zakresu");
  delay(3000);
  lcd.clear();
  lcd.setCursor(1,0);
  lcd.print("od 1 do ");
  lcd.print(maks);
  delay(2000);

  while(again == true){
    randomSeed(analogRead(A0)); //trik na losowe liczby
    x = random(1,maks+1);          //losowanie liczby 1-100
    ile_prob = 0;
    los = 0;
    while(los != x){              //jeżeli gracz nie trafia
      ile_prob++;
      licz = 0;                   //reset zmiennej liczacej cyfry
      los = 0;
      if(ile_prob == 1){
        lcd.clear();
      }
      if(ile_prob<10){          //ustalenie pozycji ilosci prob
        lcd.setCursor(15,0);    //w prawym gornym rogu
      }else{
        lcd.setCursor(14,0);
      }
      lcd.print(ile_prob);
      lcd.setCursor(0,1);
      lcd.print("Zgadnij(=) ");
      lcd.cursor();
      writing=true; //wpisanie liczby i zatwierdzenie "="
      while(writing == true){
        char klawisz = 'x';
        klawisz = klawiatura.getKey();
        //WPISANIE CYFRY
        if(klawisz=='1'||klawisz=='2'||klawisz=='3'||klawisz=='4'||klawisz=='5'||klawisz=='6'||klawisz=='7'||klawisz=='8'||klawisz=='9'||klawisz=='0'){
          if(klawisz == '0' && licz == 0){  //pierwsza wpisana liczba to zero
            //nie mozemy zaczac liczby od zera, wiec nie rob nic
          }else if(licz >= size0){
            lcd.print("x");
            //nic nie rob bo masymalnie mamy liczbe 3 cyfrowa
          }else{
            if(licz == 0){
              memset(liczba,0,size0*sizeof(int)); //zerowanie wektora
            }
            lcd.print(klawisz); //wypisanie cyfry na wyswietlaczu
            liczba[licz] = klawisz - 48; //wpisanie cyfry do wektora
            licz++;
          }
        }else if(klawisz == '='){
          if(licz != 0){    //jezeli cokolwiek jest wpisane
            for(int i = 0; i<licz; i++){
              int ii = (-1)*i + licz - 1;
              los += liczba[i]*int(pow(10, ii)+0.5);
            }
            writing=false;
            lcd.noCursor();
            lcd.print(".");
            delay(250);
            lcd.print(".");
            delay(250);
            lcd.print(".");
            delay(250);
          }
        }
      }

      if(los<x){        //za malo
        lcd.clear();
        lcd.print("To za malo..");
      }else if(los>x){  //za duzo
        lcd.clear();
        lcd.print("To za duzo..");
      }else if(los==x){  //TRAFIONE
        lcd.clear();
        lcd.noCursor();
        lcd.print("WOW! Trawiles!");
        lcd.setCursor(0,1);
        lcd.print("Za ");
        lcd.print(ile_prob);
        lcd.print(" razem!");
        delay(2000);
        lcd.setCursor(15,1);
        lcd.print("=");
        while(klawiatura.getKey() != '='){    
          //"=" wcisniete aby przejsc dalej
        }
      }  
    }
    lcd.clear();
    lcd.setCursor(2,0);
    lcd.print("Grasz dalej?");
    lcd.setCursor(1,1);
    lcd.print("TAK-1 || NIE-0");
    writing2 = true;
    while(writing2 == true){
      char klawisz = 'x';
      klawisz = klawiatura.getKey();
      if(klawisz == '1'){
        again = true;
        writing2 = false;
      }
      if(klawisz == '0'){
        again = false;
        writing2 = false;
      }
    }
  }
}

void zaduzo(){  //procedura informujaca o za duzej ilosc wpisanych cyfr
  licz1 = 0;
  licz2 = 0;
  row = 1;
  znak = 'x';
  lcd.clear();
  lcd.print("ERROR:");
  lcd.setCursor(0,1);
  lcd.print("Za duzo cyfr!");
}

void loop(){
  menu();  
}
