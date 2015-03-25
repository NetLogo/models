
int LED_PIN = 13;

void setup() {
  Serial.begin(9600);
  pinMode(LED_PIN, OUTPUT);
}

void loop() {
  //If we get a valid byte....
  if (Serial.available() > 0) {
    //Read the available byte
    int inByte = Serial.read();
    //Then, turn the LED on or off:
    //off if the byte is a 0; on otherwise
    if (inByte == 0) {
      digitalWrite(LED_PIN, LOW);
    } else {
      digitalWrite(LED_PIN, HIGH);
    }
  }
  //Wait 100 milliseconds before checking again.
  delay(100);
}
