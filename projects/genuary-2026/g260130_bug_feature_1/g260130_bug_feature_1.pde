/**
 * Threshold Trigger Echo (Audio Reactive)
 * Version: 2026.01.27.08.15.55
 * Logic: Analyzes "frenzy.mp3" for volume peaks. 
 * Cross-threshold moments stamp permanent artifacts to a buffer.
 * The space fills up with the history of the song's loudest moments.
 */

import processing.sound.*;

// --- Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
int RANDOM_SEED = 42;         // Default: 42

// Color & Style
int PALETTE_INDEX = 0;        // Default: 0 (0 to 4)
boolean INVERT_BACKGROUND = false; // Default: false
boolean SHOW_GRID = false;    // Default: false
int GRID_RES = 10;            // Default: 10

// Audio Analysis Parameters
float THRESHOLD = 0.20;       // Trigger point (Default: 0.20)
float SMOOTHING = 0.2;        // Amplitude smoothing (Default: 0.2)

// --- Global Variables ---
SoundFile song;
Amplitude analyzer;
PGraphics canvasBuffer;
float volumeTrack = 0;

// Hex Palettes from Adobe Color/Kuler
String[][] palettes = {
  {"#1A1A1A", "#FF355E", "#FD5B78", "#FF6037", "#FF9966"}, // Neon Punch
  {"#2E112D", "#540032", "#820333", "#C02739", "#F1E4E8"}, // Deep Wine
  {"#004445", "#2C7873", "#6FB98F", "#021C1E", "#FFEEAD"}, // Forest Mist
  {"#112D4E", "#3F72AF", "#DBE2EF", "#F9F7F7", "#112D4E"}, // Crisp Blue
  {"#222831", "#393E46", "#00ADB5", "#EEEEEE", "#FFD369"}  // Techno
};

color[] activePalette;
color bgColor;
color strokeColor;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(RANDOM_SEED);
  noiseSeed(RANDOM_SEED);
  frameRate(ANIMATION_SPEED);
  
  // Audio Setup - Requires "frenzy.mp3" in /data folder
  song = new SoundFile(this, "frenzy.mp3");
  song.loop();
  
  analyzer = new Amplitude(this);
  analyzer.input(song);
  
  // Initialize Palette
  activePalette = new color[5];
  for (int i = 0; i < 5; i++) {
    activePalette[i] = unhex("FF" + palettes[PALETTE_INDEX][i].substring(1));
  }
  
  bgColor = INVERT_BACKGROUND ? activePalette[4] : activePalette[0];
  strokeColor = INVERT_BACKGROUND ? activePalette[0] : activePalette[4];
  
  // Initialize persistent buffer (the "Echo" space)
  canvasBuffer = createGraphics(width - (PADDING * 2), height - (PADDING * 2));
  canvasBuffer.beginDraw();
  canvasBuffer.background(bgColor);
  canvasBuffer.endDraw();
}

void draw() {
  background(activePalette[0]); // Outer frame color
  
  // 1. Analyze Audio
  float rawVol = analyzer.analyze();
  volumeTrack = lerp(volumeTrack, rawVol, SMOOTHING);
  
  // 2. Update Echo Buffer
  canvasBuffer.beginDraw();
  
  if (SHOW_GRID) drawDebugGrid();
  
  // Threshold Trigger Logic: Stamp artifacts on volume peaks
  if (volumeTrack > THRESHOLD) {
    stampArtifact(volumeTrack);
  }
  
  canvasBuffer.endDraw();
  
  // 3. Render Buffer Centered
  image(canvasBuffer, PADDING, PADDING);
  
  // 4. Draw Peak Indicator UI
  drawVolumeBar();

  // --- Export Logic ---
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

void stampArtifact(float intensity) {
  canvasBuffer.pushMatrix();
  float x = random(canvasBuffer.width);
  float y = random(canvasBuffer.height);
  
  // Map intensity to visual properties
  float size = map(intensity, THRESHOLD, 1.0, 40, 300);
  float alpha = map(intensity, THRESHOLD, 1.0, 50, 200);
  
  canvasBuffer.translate(x, y);
  canvasBuffer.rotate(random(TWO_PI));
  
  // Pick random accent color from palette
  int colIdx = floor(random(1, 4));
  canvasBuffer.noFill();
  canvasBuffer.stroke(activePalette[colIdx], alpha);
  canvasBuffer.strokeWeight(map(intensity, THRESHOLD, 1.0, 0.5, 4.0));
  
  // Geometric Artifact: Concentric Echoes
  int rings = floor(random(2, 5));
  for (int i = 0; i < rings; i++) {
    float rSize = size * (1.0 - (i * 0.2));
    canvasBuffer.rectMode(CENTER);
    canvasBuffer.rect(0, 0, rSize, rSize);
    canvasBuffer.ellipse(0, 0, rSize * 0.5, rSize * 0.5);
  }
  
  canvasBuffer.popMatrix();
}

void drawDebugGrid() {
  canvasBuffer.stroke(strokeColor, 20);
  canvasBuffer.strokeWeight(1);
  for (int i = 0; i <= GRID_RES; i++) {
    float x = map(i, 0, GRID_RES, 0, canvasBuffer.width);
    canvasBuffer.line(x, 0, x, canvasBuffer.height);
    float y = map(i, 0, GRID_RES, 0, canvasBuffer.height);
    canvasBuffer.line(0, y, canvasBuffer.width, y);
  }
}

void drawVolumeBar() {
  float barWidth = width - (PADDING * 2);
  float xPos = PADDING;
  float yPos = height - (PADDING / 2.0);
  
  // Background bar
  stroke(strokeColor, 50);
  strokeWeight(1);
  line(xPos, yPos, xPos + barWidth, yPos);
  
  // Threshold tick
  stroke(activePalette[1]);
  float tx = xPos + (THRESHOLD * barWidth);
  line(tx, yPos - 5, tx, yPos + 5);
  
  // Current volume marker
  float vx = xPos + (volumeTrack * barWidth);
  fill(volumeTrack > THRESHOLD ? activePalette[1] : activePalette[3]);
  noStroke();
  ellipse(vx, yPos, 8, 8);
}
