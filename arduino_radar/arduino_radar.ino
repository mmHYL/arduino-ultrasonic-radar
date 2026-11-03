
#include <Servo.h>

// Arduino MEGA 2560 pin configuration
const int SERVO_PIN = 9;
const int TRIG_PIN = 10;
const int ECHO_PIN = 11;

Servo radarServo;

// Measure distance in centimeters
float readDistance() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);

  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  unsigned long duration =
    pulseIn(ECHO_PIN, HIGH, 30000UL);

  // Return -1 if no echo is detected
  if (duration == 0) {
    return -1;
  }

  // Distance = (time x speed of sound) / 2
  return duration * 0.0343 / 2.0;
}

// Take three measurements and filter noise
float filteredDistance() {
  float readings[3];
  int count = 0;

  for (int i = 0; i < 3; i++) {
    float distance = readDistance();

    if (distance > 0) {
      readings[count++] = distance;
    }

    delay(60);
  }

  // No valid readings
  if (count == 0) {
    return -1;
  }

  // Sort valid readings in ascending order
  for (int i = 0; i < count - 1; i++) {
    for (int j = i + 1; j < count; j++) {
      if (readings[i] > readings[j]) {
        float temp = readings[i];
        readings[i] = readings[j];
        readings[j] = temp;
      }
    }
  }

  // Return median for odd count
  if (count % 2 == 1) {
    return readings[count / 2];
  }

  // Average middle values for even count
  return (readings[count / 2 - 1]
        + readings[count / 2]) / 2.0;
}

// Rotate servo and measure distance
void scanAt(int angle) {
  radarServo.write(angle);

  // Allow servo to reach position
  delay(180);

  float distance = filteredDistance();

  // Send angle,distance to Processing
  Serial.print(angle);
  Serial.print(",");
  Serial.println(distance, 1);
}

void setup() {
  Serial.begin(9600);

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);

  radarServo.attach(SERVO_PIN);
  radarServo.write(90);

  delay(1000);
}

void loop() {

  // Scan from 20 to 160 degrees
  for (int angle = 20; angle <= 160; angle += 5) {
    scanAt(angle);
  }

  // Scan backward from 155 to 25 degrees
  for (int angle = 155; angle >= 25; angle -= 5) {
    scanAt(angle);
  }
}
