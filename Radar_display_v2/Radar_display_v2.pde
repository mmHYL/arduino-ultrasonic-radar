
import processing.serial.*;

Serial radarPort;

String portName = "COM4";
final int BAUD_RATE = 9600;

float[] distances = new float[181];
int[] timestamps = new int[181];

int currentAngle = 90;
int previousAngle = 90;
int scanDirection = 1;

float currentDistance = -1;
float maxRange = 100;

int fadeDuration = 12000;
int lastDataTime = 0;

float cx, cy, radarRadius;

void setup() {
  size(1100, 700);
  smooth(8);
  frameRate(60);

  cx = width / 2.0;
  cy = height - 65;
  radarRadius = min(width * 0.42, height * 0.64);

  for (int i = 0; i <= 180; i++) {
    distances[i] = -1;
    timestamps[i] = -fadeDuration;
  }

  println("Available serial ports:");
  printArray(Serial.list());

  radarPort = new Serial(this, portName, BAUD_RATE);
  radarPort.clear();
  radarPort.bufferUntil('\n');
}

void draw() {
  background(5, 16, 19);

  drawHeader();
  drawRadarGrid();
  drawDetections();
  drawSweep();
  drawFooter();
}

void serialEvent(Serial p) {
  String raw = p.readStringUntil('\n');

  if (raw == null) return;

  String[] values = split(trim(raw), ',');

  if (values.length != 2) return;

  try {
    int angle = Integer.parseInt(trim(values[0]));
    float distance = Float.parseFloat(trim(values[1]));

    if (angle < 0 || angle > 180) return;
    if (Float.isNaN(distance) ||
        Float.isInfinite(distance)) return;

    if (angle > previousAngle) scanDirection = 1;
    if (angle < previousAngle) scanDirection = -1;

    previousAngle = angle;
    currentAngle = angle;
    currentDistance = distance;

    distances[angle] = distance;
    timestamps[angle] = millis();
    lastDataTime = millis();
  }
  catch (NumberFormatException e) {
    // Ignore invalid serial data
  }
}

float theta(int angle) {
  return radians(180 - angle);
}

void drawHeader() {
  textAlign(CENTER);
  fill(40, 255, 160);

  textSize(28);
  text("ULTRASONIC SCANNING SYSTEM",
       width / 2, 48);

  textSize(13);
  fill(115, 180, 160);
  text("ARDUINO MEGA 2560  |  HC-SR04  |  SG90",
       width / 2, 73);

  textAlign(LEFT);
  fill(35, 245, 155);
  textSize(17);

  text("ANGLE: " + currentAngle + "\u00b0", 50, 110);

  if (currentDistance < 0) {
    text("DISTANCE: NO ECHO", 50, 137);
  } else {
    text("DISTANCE: " +
         nf(currentDistance, 0, 1) + " cm",
         50, 137);
  }

  textAlign(RIGHT);

  if (millis() - lastDataTime < 3000) {
    fill(30, 240, 130);
    text("LIVE", width - 50, 110);
  } else {
    fill(255, 180, 65);
    text("WAITING FOR DATA", width - 50, 110);
  }

  if (currentDistance < 0) {
    fill(255, 180, 65);
    text("NO ECHO", width - 50, 137);
  } else if (currentDistance > maxRange) {
    fill(255, 180, 65);
    text("BEYOND DISPLAY RANGE", width - 50, 137);
  } else {
    fill(50, 245, 140);
    text("OBJECT DETECTED", width - 50, 137);
  }
}

void drawRadarGrid() {
  noFill();
  strokeWeight(1.5);
  stroke(20, 145, 95, 190);

  // Distance rings
  for (int i = 1; i <= 5; i++) {
    float r = radarRadius * i / 5.0;
    arc(cx, cy, 2*r, 2*r, PI, TWO_PI);
  }

  // Angle lines
  for (int a = 0; a <= 180; a += 30) {
    float t = theta(a);

    float x = cx + radarRadius * cos(t);
    float y = cy - radarRadius * sin(t);

    stroke(20, 145, 95, 125);
    line(cx, cy, x, y);
  }

  stroke(40, 255, 150);
  strokeWeight(2);
  line(cx - radarRadius, cy,
       cx + radarRadius, cy);

  fill(55, 220, 145);
  textSize(13);
  textAlign(CENTER);

  // Angle labels
  for (int a = 0; a <= 180; a += 30) {
    float t = theta(a);

    float x = cx + (radarRadius + 26) * cos(t);
    float y = cy - (radarRadius + 26) * sin(t);

    if (a == 0 || a == 180) {
      y = cy + 25;
    }

    text(a + "\u00b0", x, y);
  }

  // Distance labels
  textAlign(RIGHT);

  for (int i = 1; i <= 5; i++) {
    float r = radarRadius * i / 5.0;
    int d = int(maxRange * i / 5.0);

    fill(75, 190, 140);
    text(d + " cm", cx + r - 8, cy - 12);
  }
}

void drawDetections() {
  noStroke();

  for (int a = 0; a <= 180; a++) {
    float distance = distances[a];

    if (distance <= 0 || distance > maxRange) {
      continue;
    }

    int age = millis() - timestamps[a];

    if (age < 0 || age > fadeDuration) {
      continue;
    }

    float alpha = map(
      age, 0, fadeDuration, 255, 0
    );

    float r = map(
      distance, 0, maxRange, 0, radarRadius
    );

    float t = theta(a);

    float x = cx + r * cos(t);
    float y = cy - r * sin(t);

    fill(255, 75, 65, alpha);
    ellipse(x, y, 8, 8);
  }
}

void drawSweep() {
  // Fading sweep trail
  for (int i = 8; i >= 0; i--) {
    int a = currentAngle - scanDirection * i * 5;

    if (a < 20 || a > 160) continue;

    float t = theta(a);

    float x = cx + radarRadius * cos(t);
    float y = cy - radarRadius * sin(t);

    float alpha = map(i, 0, 8, 230, 12);

    stroke(25, 255, 120, alpha);
    strokeWeight(i == 0 ? 3.5 : 1.3);

    line(cx, cy, x, y);
  }

  noStroke();
  fill(45, 255, 145);
  ellipse(cx, cy, 10, 10);
}

void drawFooter() {
  fill(85, 160, 135);
  textAlign(CENTER);
  textSize(12);

  text("RANGE: " + int(maxRange) +
       " cm    |    DETECTION TRAIL: " +
       (fadeDuration / 1000) + " s",
       width / 2, height - 15);
}
