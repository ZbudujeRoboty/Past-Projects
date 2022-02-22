/*  Engineer Diploma Thesis
 *  AGH - University of Science and Technology | Cracow - WIMiR
 *  Design and construction of prototype of the robot cleaning urban green areas
 *  "Wall-e"
 *  
 *  Main code
 *  
 *  The circuit:
 *  - Arduino UNO
 *  - Servo TowerPro SG-90 - micro - 180 x2
 *  - Servo Feetech FS5106R - 360 x2
 *  - PCA9685 - Servo controller
 *  - HC-SR04 - Ultrasonic sensor
 *  - TSOP31236 - IR recriver module
 *  - Buzzer
 *  - LED diode x3
 *  - Rocker switch
 *  - Tact switch
 *  
 *  created 2021 by Jan Brzyk
 */ 

#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>
#include "Adafruit_NECremote.h"

#define trig 12       // Ultrasonic sensor's trig pin
#define echo 11       // Ultrasonic sensor's echo pin
#define IRpin 4       // IR recriver pin
#define buzz 10       // Buzzer pin
#define eStop 2       // Emergency Stop (tact switch) Interrupt pin
#define modeSwitch 3  // Rocker switch pin: Manual-OFF | Auto-ON (LOW)
#define yellow 5      // Yellow LED pin
#define red 6         // Red LED pin
#define OE 7          // OE on Servo PCA controller: HIGH = OFF servos

//Servos on PCA9685
#define servo0 0      // Left big servo 360
#define servo1 1      // Right big servo 360
#define servo2 2      // Belly small servo 180
#define servo3 3      // Head small servo 180

Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver();  //Default adress 0x40
Adafruit_NECremote remote(IRpin);

int SERVO_FREQ = 50;          // Analog servos run at ~50 Hz updates
int SERVO2MIN = 110;          // "minimum" pulse length count for servo2
int SERVO2MAX = 480;          // "maximum" pulse length count for servo2
int SERVO3MIN = 122;          // "minimum" pulse length count for servo3
int SERVO3MAX = 506;          // "maximum" pulse length count for servo3
int mode = 0;                 // Manual-0 | Auto-1 | E-stop-2
int c;                        // Remote value
int emergencyBuzzFreq = 200;  // Frequency for emergency beeps [Hz]
int opened = -85;             // Belly's servo limit angles
int closed = -35;
int x = 120;                  // buzzer's music tact time [ms]
int distance = 20;            // wall detection minimum distance [cm]

bool first = true;            // "first time in a mode" indicator


void setup() {
  Serial.begin(9600);  
  pwm.begin();
  pwm.setPWMFreq(SERVO_FREQ); // 50Hz for analog servos
  attachInterrupt(digitalPinToInterrupt(eStop), emergency, FALLING);
  pinMode(trig, OUTPUT);
  pinMode(echo, INPUT);
  pinMode(buzz, OUTPUT);
  pinMode(eStop, INPUT_PULLUP); 
  pinMode(modeSwitch, INPUT_PULLUP);
  pinMode(yellow, OUTPUT);
  pinMode(red, OUTPUT);
  pinMode(OE, OUTPUT);
  Serial.println("START - Setup");
  pwm.setPWM(servo2, 0, angle2(closed));  // Micro servos's start position
  pwm.setPWM(servo3, 0, angle3(0));
  noTone(buzz);
  digitalWrite(yellow, LOW);
  digitalWrite(red, LOW);
  digitalWrite(OE, LOW);
  startBuzz();
  if(digitalRead(modeSwitch)==LOW){       // Begining Mode switch
    mode = 1;
  }else{
    mode = 0;
  }
}

void loop() {
  switch(mode){                           // State machine
    
    case 0:                               // Manual Mode (mode 0)
      if(first==true){                    // First cycle of manual mode
        Serial.println("Manual Mode ON");
        digitalWrite(yellow, LOW);
        digitalWrite(red, LOW);
        manualBuzz();
        for(int i = 0; i < 3; i++){ //x3
          fastRedBlink();
        }
      }
      c = remote.listen(1);
      if(c!=-1)                             // Red LED blink when remote button clicked
        fastRedBlink();
      switch(c){
        case -3:                            // same button
          //Serial.println("Same button");
        break;
        case -2:                            // data error
          Serial.println("Data error");
        break;
        case -1:                            // time out
          Serial.println("Time out");
        break;

        case 64:                            // forward
          Serial.println("FORWARD!");
          digitalWrite(OE, LOW);            // Servos on
          pwm.setPWM(servo0, 0, 360);       // left servo max CCW
          pwm.setPWM(servo1, 0, 250);       // right servo max CW
        break;
        case 65:                            // backward
          Serial.println("BACKWARD");
          digitalWrite(OE, LOW);            // Servos on
          pwm.setPWM(servo0, 0, 250);       // left servo max CW
          pwm.setPWM(servo1, 0, 360);       // right servo max CCW
        break;
        case 7:                             // left
          Serial.println("LEFT");
          digitalWrite(OE, LOW);            // Servos on
          pwm.setPWM(servo0, 0, 250);       // left servo max CW
          pwm.setPWM(servo1, 0, 250);       // right servo max CW
        break;
        case 6:                             // right
          Serial.println("RIGHT");
          digitalWrite(OE, LOW);            // Servos on
          pwm.setPWM(servo0, 0, 360);       // left servo max CCW
          pwm.setPWM(servo1, 0, 360);       // right servo max CCW
        break;
        case 68:                            // stop
          Serial.println("STOP");
          digitalWrite(OE, HIGH);           // Servos off
          pwm.setPWM(servo0, 0, 305);       // left servo STOP
          pwm.setPWM(servo1, 0, 301);       // right servo STOP
        break;

        case 17:                            // 1 - head -90 deg
          Serial.println("Head -90");
          digitalWrite(OE, LOW);            // Servos on
          pwm.setPWM(servo3, 0, angle3(-90));
        break;
        case 20:                            // 4 - haed -60 deg
          Serial.println("Head -60");
          digitalWrite(OE, LOW);            // Servos on
          pwm.setPWM(servo3, 0, angle3(-60));
        break;
        case 23:                            // 7 - head -30 deg
          Serial.println("Head -30");
          digitalWrite(OE, LOW);            // Servos on
          pwm.setPWM(servo3, 0, angle3(-30));
        break; 
        case 16:                            // 0 - head 0 deg   
          Serial.println("Head 0");
          digitalWrite(OE, LOW);            // Servos on     
          pwm.setPWM(servo3, 0, angle3(0));
        break;
        case 25:                            // 9 - head +30 deg
          Serial.println("Head +30");
          digitalWrite(OE, LOW);            // Servos on
          pwm.setPWM(servo3, 0, angle3(30));
        break;
        case 22:                            // 6 - head +60 deg
          Serial.println("Head +60");
          digitalWrite(OE, LOW);            // Servos on
          pwm.setPWM(servo3, 0, angle3(60));
        break;
        case 19:                            // 3 - head +90 deg
          Serial.println("Head +90");
          digitalWrite(OE, LOW);            // Servos on
          pwm.setPWM(servo3, 0, angle3(90));
        break;

        case 2:                             // vol+ - belly close
          Serial.println("Belly close");
          digitalWrite(OE, LOW);            // Servos on
          pwm.setPWM(servo2, 0, angle2(closed));
        break;
        case 3:                             // vol- - belly open
          Serial.println("Belly open");
          digitalWrite(OE, LOW);            // Servos on
          pwm.setPWM(servo2, 0, angle2(opened));
        break;
      }
      if(mode != 2){
        if(digitalRead(modeSwitch)==LOW){ //Mode switch
          mode = 1;
          first = true;                     // switch to mode 1
        }else{
          mode = 0;
          first = false;                    // still mode 0
        }
      }
    break;

    case 1:                                 // Auto Mode (mode 1)
      if(first==true){                      // first cycle of auto mode
        Serial.println("Auto Mode ON");
        digitalWrite(yellow, HIGH);
        digitalWrite(red, LOW);
        autoBuzz();
        digitalWrite(OE, LOW);              // Servos on
        pwm.setPWM(servo3, 0, angle3(0));   // head forward
      }
      Serial.print("Distance: ");
      Serial.println(ultrasonic());
      if(ultrasonic() < distance){          // obstacle detected!
         avoid();
      }else{                                // no obstacle = go forward
        Serial.println("FORWARD");
        pwm.setPWM(servo0, 0, 330);         // left servo CCW
        pwm.setPWM(servo1, 0, 270);         // right servo CW
      }
      if(mode != 2){
        if(digitalRead(modeSwitch)!=LOW){   // Mode switch
          mode = 0;
          first = true;                     // switch to mode 0
        }else{
          mode = 1;
          first = false;                    // still mode 1
        }
      }
    break;

    case 2:                                 // E-stop (mode 2)
      pwm.setPWM(servo0, 0, 305);           // left servo STOP
      pwm.setPWM(servo1, 0, 301);           // right servo STOP
      digitalWrite(buzz, LOW);              // disable buzzer
      digitalWrite(yellow, LOW);            // disable LEDs
      digitalWrite(red, LOW);
      while(1){                             // infinite emergency loop
        Serial.println("E-STOP!!!");
        tone(buzz, emergencyBuzzFreq, 500);
        delay(500);
        noTone(buzz);
        delay(500);
      }
    break;
  }
}

// E-stop
void emergency(){ 
  mode = 2;
  digitalWrite(OE, HIGH);               // disable all servo outputs
}

//Ultrasonic sensor distance measurement
int ultrasonic(){
  long czas, dystans;
  digitalWrite(trig, LOW);
  delayMicroseconds(2);
  digitalWrite(trig, HIGH);
  delayMicroseconds(10);
  digitalWrite(trig, LOW);
  czas = pulseIn(echo, HIGH);
  dystans = czas / 58;
  return dystans;                       // distance in cm
}

void avoid(){
  Serial.println("Avoiding...");
  tone(buzz, 350, 100);
  delay(100);
  noTone(buzz);
  delay(20);
  // a little bit backward
  pwm.setPWM(servo0, 0, 290);           // left servo slow CW
  pwm.setPWM(servo1, 0, 320);           // right servo slow CCW
  delay(2000);
  // a little right turn
  pwm.setPWM(servo0, 0, 330);           // left servo max CCW
  pwm.setPWM(servo1, 0, 330);           // right servo max CCW
  delay(1000);
}

// Servo2's angle mapping
int angle2 (int angle){
  int pulse = map(angle, -90, 90, SERVO2MIN, SERVO2MAX); // value mapped
  return pulse;
}

//Servo3's angle mapping
int angle3 (int angle){
  int pulse = map(angle, -90, 90, SERVO3MIN, SERVO3MAX); // value mapped
  return pulse;
}

// Red LED blink
void fastRedBlink(){
  digitalWrite(red, HIGH);
  delay(50);
  digitalWrite(red, LOW);
  delay(50);
}

// Music for Arduino start | active
void startBuzz(){
  tone(buzz, 262, x);
  delay(x);
  tone(buzz, 330, x);
  delay(x);
  tone(buzz, 392, x);
  delay(x);
  tone(buzz, 531, x);
  delay(x);
  noTone(buzz);
  delay(x);
  tone(buzz, 392, x);
  delay(x);
  tone(buzz, 531, 1.5*x);
  delay(10*x);
}

// Music for turning on Manual Mode | calm
void manualBuzz(){
  tone(buzz, 440, x);
  delay(x);
  tone(buzz, 392, x);
  delay(x);
  tone(buzz, 330, x);
  delay(x);
  tone(buzz, 294, x);
  delay(x);
  noTone(buzz);
  delay(x);
  tone(buzz, 330, 1.5*x);
  delay(5*x);
}

// Music for turning on Auto Mode | jazzy
void autoBuzz(){
  tone(buzz, 523, x);
  delay(x);
  tone(buzz, 622, x);
  delay(x);
  tone(buzz, 698, x);
  delay(x);
  tone(buzz, 740, x);
  delay(x);
  tone(buzz, 784, x);
  delay(x);
  tone(buzz, 932, x);
  delay(x);
  tone(buzz, 1047, 1.5*x);
  delay(10*x);
}
