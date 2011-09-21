/* 
DOOR CONTROL 
version: 1.3.2
date: 06-09-2011

1.3.2 bug in emergency break
1.3.1 watchdog 2 seconds
1.3   only manual control, watchdog improvments
1.2   added watchdog / optiboot
1.1   bug fix
1.0   inital release

*/

#include <avr/wdt.h>

#define CURRENT_INT              2

#define ENDSTOP_DOOR_IS_OPEN     3      // active high
#define ENDSTOP_DOOR_IS_CLOSED   4
#define DOOR_UNLOCKED            5


#define CMD_OPEN_in              6      // active low
#define CMD_CLOSE_in             7
#define CMD_OPEN_out             8
#define CMD_CLOSE_out            9

#define ENABLE_1                 10    // default motor stop
#define DIR_1                    11    // direction -> close
#define ENABLE_2                 12
#define DIR_2                    13

#define ACTION_DELAY_TIME        150
#define LOCK_TIME                2000  // 2000 * 5 = 10000 (10 sec)


void setup()
{
  wdt_reset();
  watchdogSetup();
  Serial.println("dog is alive");
  
  
  Serial.begin(9600);
  
  pinMode(ENDSTOP_DOOR_IS_OPEN, INPUT);
  digitalWrite(ENDSTOP_DOOR_IS_OPEN, LOW);
  pinMode(ENDSTOP_DOOR_IS_CLOSED, INPUT);
  digitalWrite(ENDSTOP_DOOR_IS_CLOSED, LOW);
  pinMode(DOOR_UNLOCKED, INPUT);
  digitalWrite(DOOR_UNLOCKED, LOW);
  
  pinMode(CURRENT_INT, INPUT);
  digitalWrite(CURRENT_INT, LOW);

  pinMode(CMD_OPEN_in, INPUT);
  digitalWrite(CMD_OPEN_in, HIGH);
  pinMode(CMD_CLOSE_in, INPUT);
  digitalWrite(CMD_CLOSE_in, HIGH);
  pinMode(CMD_OPEN_out, INPUT);
  digitalWrite(CMD_OPEN_out, HIGH);
  pinMode(CMD_CLOSE_out, INPUT);
  digitalWrite(CMD_CLOSE_out, HIGH);

  pinMode(ENABLE_1, OUTPUT);
  digitalWrite(ENABLE_1, LOW);
  pinMode(DIR_1, OUTPUT);
  digitalWrite(DIR_1, LOW);
  pinMode(ENABLE_2, OUTPUT);
  digitalWrite(ENABLE_2 , LOW);
  pinMode(DIR_2, OUTPUT);
  digitalWrite(DIR_2, LOW);  
  Serial.println("* AUTOMATIC DOOR SYSTEM *");
  Serial.println("Version 1.3.1 06/09/2011");
  
  wdt_reset();
}

void loop()
{
  
  // OPEN SEQUENCE
  if (!digitalRead(CMD_OPEN_in) || !digitalRead(CMD_OPEN_out))  // open button pressed
  {
    Serial.println("*CMD_OPEN*");
    if (digitalRead(ENDSTOP_DOOR_IS_OPEN))
    {
      Serial.println("ENDSTOP_DOOR_IS_OPEN, do nothing.");
    }
    else  
    {
      if (!digitalRead(DOOR_UNLOCKED))    // door is locked?
      {
        unlock_door();
        delay(500);
      }
      if (digitalRead(DOOR_UNLOCKED))    // door is unlocked, so open it
      {
        Serial.println("OPENING DOOR...");
        digitalWrite(DIR_1, HIGH);      // DIR set
        delay(ACTION_DELAY_TIME);
        while ((!digitalRead(CMD_OPEN_in) || !digitalRead(CMD_OPEN_out)) && !digitalRead(ENDSTOP_DOOR_IS_OPEN))
        {
          digitalWrite(ENABLE_1, HIGH); // GO MOTOR!
            // security check
            if (!digitalRead(CMD_CLOSE_in) || !digitalRead(CMD_CLOSE_out))
            {
			  Serial.println("*EMERGECENCY BREAK*");
			  stop_motor();
              break;
            }          
          delay(ACTION_DELAY_TIME);
          wdt_reset();
        }
        stop_motor();
      }
     }
     delay(ACTION_DELAY_TIME);
     wdt_reset();
  }      
  
  //CLOSE SEQUENCE
  if (!digitalRead(CMD_CLOSE_in) || !digitalRead(CMD_CLOSE_out))
  {
    Serial.println("*CMD_CLOSE*");
    if (digitalRead(ENDSTOP_DOOR_IS_CLOSED))
    {
      Serial.println("ENDSTOP_DOOR_IS_CLOSED, LOCKING DOOR..");
      lock_door();
    }
    else  
    {
      Serial.println("CLOSING DOOR...");
      digitalWrite(DIR_1, LOW);      // DIR set
      delay(ACTION_DELAY_TIME);
      while ((!digitalRead(CMD_CLOSE_in) || !digitalRead(CMD_CLOSE_out)) && !digitalRead(ENDSTOP_DOOR_IS_CLOSED))
      {
         
        digitalWrite(ENABLE_1, HIGH); // GO MOTOR!
        delay(ACTION_DELAY_TIME);
        if (digitalRead(ENDSTOP_DOOR_IS_CLOSED)) break;  // double check!
        delay(ACTION_DELAY_TIME);
        Serial.print("*");
        wdt_reset();
      }
      
      stop_motor();
      
      if (digitalRead(ENDSTOP_DOOR_IS_CLOSED))
      {
        lock_door();
      }
     
     }
     delay(ACTION_DELAY_TIME);
     wdt_reset();
   }      
}

void stop_motor()
{
  // STOP SEQUENCE
  digitalWrite(ENABLE_1, LOW);   // STOP MOTOR
  delay(ACTION_DELAY_TIME);
  digitalWrite(DIR_1, LOW);      // DIRECTION reset
  Serial.println("*MOTOR STOP*");
}

void unlock_door()
{
  Serial.println("*Unlock DOOR*");
  digitalWrite(DIR_2, HIGH);      // DIR set
  delay(ACTION_DELAY_TIME);
  while ((!digitalRead(CMD_OPEN_in) || !digitalRead(CMD_OPEN_out)) && !digitalRead(DOOR_UNLOCKED))
  {
    digitalWrite(ENABLE_2, HIGH); // GO MOTOR!
    delay(10);
    wdt_reset();
  }
  digitalWrite(ENABLE_2, LOW);     // STOP! 
  delay(ACTION_DELAY_TIME);
  digitalWrite(DIR_2, LOW);      // DIR set
  Serial.println("DOOR is now UNLOCKED!");
  wdt_reset();
}

void lock_door()
{
  Serial.println("*Locking DOOR*");
  // CHECK IF ENDSTOP CLOSE IS ON!
  if (!digitalRead(ENDSTOP_DOOR_IS_CLOSED))  
  {
    Serial.println("DOOR IS NOT CLOSED, CANT LOCK NOW!");
    return;   
  }
  digitalWrite(DIR_2, LOW);      // DIR set
  delay(ACTION_DELAY_TIME);
  
  while ( !digitalRead(CMD_CLOSE_in) || !digitalRead(CMD_CLOSE_out) )
  {
    digitalWrite(ENABLE_2, HIGH); // GO MOTOR!
    delay(ACTION_DELAY_TIME);
    wdt_reset();
  }  
  digitalWrite(ENABLE_2, LOW);     // STOP! 
  delay(ACTION_DELAY_TIME);
  digitalWrite(DIR_2, LOW);      // DIR set
  Serial.println("DOOR is now LOCKED!");
  wdt_reset();
}

void watchdogSetup(void)
{
cli();
// disable all interrupts
wdt_reset();
// reset the WDT timer
/*
WDTCSR configuration:
WDIE = 1: Interrupt Enable
WDE = 1 :Reset Enable
WDP3 = 0 :For 2000ms Time-out
WDP2 = 1 :For 2000ms Time-out
WDP1 = 1 :For 2000ms Time-out
WDP0 = 1 :For 2000ms Time-out
*/
// Enter Watchdog Configuration mode:
WDTCSR |= (1<<WDCE) | (1<<WDE);
// Set Watchdog settings:
WDTCSR = (1<<WDIE) | (1<<WDE) | (1<<WDP3) | (0<<WDP2) | (0<<WDP1) | (0<<WDP0);  // 2000 ms
sei();
}

ISR(WDT_vect) // Watchdog timer interrupt.
{
// Include your code here - be careful not to use functions they may cause the interrupt to hang and
// prevent a reset.
Serial.println("Resetting..");
}
  
  
  
