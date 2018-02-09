int counter = 0;    //we'll send this counter value over the Serial port to be read by NetLogo
int ledPin = 13;    //pin 13, which has an associated onboard LED

void setup() {
  //start listening to the serial port at 9600 bps,
  //the baud rate expected by NetLogo's Arduino extension
  Serial.begin(9600);

  //set up the LED pin to act as an output
  pinMode(ledPin, OUTPUT);
}

void loop() {

  if (counter >= 100) {
    counter = 0;
  }
  counter++;

  //Write out our counter value
  Serial.print("C,");    // send a value named "C"       
  Serial.print("D,");    // specify it is a numeric ("Double") value
  Serial.print(counter);
  Serial.print(";");

  //Create and write out a random number from 0 to 10, with two digits of decimals.
  double rnum = random(1000) / 100.0;
  Serial.print("R,");         // send a value named "R"
  Serial.print("D,");         // specify it is a numeric ("Double") value
  Serial.print(rnum, 2);      // sending 2 digit accuracy
  Serial.print(";");

  Serial.print("GAME,");      // send a value named "GAME"
  Serial.print("S,");         // specify it is a String value
  if (counter % 3 != 2) {     // play a fun game
    Serial.print("DUCK");
  } else {
    Serial.print("GOOSE");
  }
  Serial.print(";");

  if (Serial.available() > 0) {
    int cmd = Serial.read();
    if (cmd == 48 || cmd == 0) {        //0 or ascii "0" sent with write-string
      digitalWrite(ledPin, LOW);        //turn the onboard LED associated with pin 13 off
    } else if (cmd == 49 || cmd == 1) { //1 or ascii "1" sent with write-string
      digitalWrite(ledPin, HIGH);       //turn the onboard LED associated with pin 13 on
    }
  }

  delay(200);  //1/5 second delay --> this could be removed or adjusted for more or less frequent cycles.
}
