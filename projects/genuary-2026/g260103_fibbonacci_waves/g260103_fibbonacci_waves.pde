/**
 * Harmonic Fibonacci Waves - Localized Grid Edition
 * Version: 2025.12.18.14.05.32
 * * Fixed particle coordinate mapping to ensure emission in all grid cells.
 * * Each cell (COLS x ROWS) now maintains a local-space particle system.
 */

import java.util.ArrayList;

// Parameters & Constants
// ---------------------------------------------------------
float VERSION = 2025.1218140532f;

int SKETCH_WIDTH = 480;   // Default: 480
int SKETCH_HEIGHT = 800;  // Default: 800
int MAX_FRAMES = 900;     // Default: 900
int ANIMATION_SPEED = 60; // Default: 60
boolean SAVE_FRAMES = false; // Default: false

float PADDING = 10;       // Default: 40
float ZONE_GAP = 0;       // Default: 5
int SEED_VALUE = 42;      // Default: 42
boolean SHOW_GRID = false; // Default: false
boolean INVERT_BG = false; // Default: false

// Grid Configuration
int GRID_COLS = 1;        // Default: 2
int GRID_ROWS = 3;        // Default: 3

// Glow & Physics Parameters
float LINE_THICKNESS = 1.2;    // Default: 1.2
float GLOW_SIZE = 30.0;        // Default: 30.0
boolean USE_BLEND_MODE = true; // Default: true
float WAVE_STRENGTH = 90.0;    // Default: 90.0
float UNDULATION_SPEED = 0.15; // Default: 0.15
int LINES_PER_ZONE = 10;       // Default: 10

// Particle Parameters
int PARTICLES_PER_ZONE = 5000;  // Default: 250
float PARTICLE_SIZE = 3.0;     // Default: 3.0
float PARTICLE_DECAY = 4.2;    // Default: 4.2
float EMISSION_RATE = 0.35;    // Default: 0.35
float FLOW_SPEED = 6.0;        // Default: 6.0

// Global Variables
color bgColor;
color[] waveColors = new color[5]; 
float timeStep = 0;
float[] fibRatios = { 0.6, 0.625, 0.6153, 0.375, 0.8 }; 
ZoneSystem[] zones;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  noiseSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  if (!INVERT_BG) {
    bgColor = color(1, 22, 39);      
    waveColors[0] = color(46, 196, 182); // Teal
    waveColors[1] = color(231, 29, 54);  // Red
    waveColors[2] = color(255, 159, 28); // Orange
    waveColors[3] = color(165, 105, 189); // Purple
    waveColors[4] = color(93, 173, 226);  // Blue
  } else {
    bgColor = color(245, 245, 245);  
    waveColors[0] = color(20, 150, 140);
    waveColors[1] = color(180, 20, 40);
    waveColors[2] = color(200, 120, 20);
    waveColors[3] = color(120, 60, 150);
    waveColors[4] = color(40, 100, 180);
  }

  zones = new ZoneSystem[GRID_COLS * GRID_ROWS];
  for (int i = 0; i < zones.length; i++) {
    zones[i] = new ZoneSystem(waveColors[i % waveColors.length], fibRatios[i % fibRatios.length]);
  }
}

void draw() {
  background(bgColor);
  
  if (SHOW_GRID) drawDebugGrid();

  float cellW = (width - (PADDING * 2) - (GRID_COLS - 1) * ZONE_GAP) / GRID_COLS;
  float cellH = (height - (PADDING * 2) - (GRID_ROWS - 1) * ZONE_GAP) / GRID_ROWS;

  for (int r = 0; r < GRID_ROWS; r++) {
    for (int c = 0; c < GRID_COLS; c++) {
      int index = r * GRID_COLS + c;
      float xPos = PADDING + (c * (cellW + ZONE_GAP));
      float yPos = PADDING + (r * (cellH + ZONE_GAP));
      
      pushMatrix();
      translate(xPos, yPos);
      
      // Pass the actual cell dimensions for local coordinate calculation
      zones[index].update(cellW);
      zones[index].display(cellW, cellH);
      
      popMatrix();
    }
  }
  
  timeStep += UNDULATION_SPEED; 

  if (SAVE_FRAMES) saveFrame("frames/####.tif");
  if (frameCount >= MAX_FRAMES) noLoop();
}

// ---------------------------------------------------------

class ZoneSystem {
  ArrayList<Particle> particles = new ArrayList<Particle>();
  color zoneColor;
  float ratio;

  ZoneSystem(color c, float r) {
    zoneColor = c;
    ratio = r;
  }

  void update(float cellW) {
    for (int i = particles.size() - 1; i >= 0; i--) {
      Particle p = particles.get(i);
      p.run();
      // Particles are now handled in local space (0 to cellW)
      if (p.isDead() || p.pos.x > cellW) particles.remove(i);
    }
  }

  void display(float w, float h) {
    if (USE_BLEND_MODE) blendMode(ADD);

    for (int i = 0; i < LINES_PER_ZONE; i++) {
      float yBase = map(i, 0, LINES_PER_ZONE, 0, h);
      float alphaVal = map(i, 0, LINES_PER_ZONE, 255, 80);
      
      // Glow Pass
      noFill();
      strokeWeight(GLOW_SIZE);
      stroke(zoneColor, alphaVal * 0.1); 
      renderPath(w, yBase, i, false);
      
      // Core Pass
      strokeWeight(LINE_THICKNESS);
      stroke(zoneColor, alphaVal);
      renderPath(w, yBase, i, true);
    }
    
    // Draw local particles
    for (Particle p : particles) p.display();
    
    blendMode(BLEND);
  }

  void renderPath(float w, float yB, int index, boolean emit) {
    beginShape();
    float xStep = 8.0; 
    for (float x = 0; x <= w; x += xStep) {
      float freq = 0.04 * ratio;
      float angle = (x * freq) + timeStep + (index * 0.2);
      float yOffset = (sin(angle) + sin(x * 0.1 - timeStep * 1.8) * 0.12) * WAVE_STRENGTH;
      float finalY = yB + yOffset;
      vertex(x, finalY);

      if (emit && particles.size() < PARTICLES_PER_ZONE && random(1) < EMISSION_RATE) {
        float slope = freq * cos(angle) * WAVE_STRENGTH;
        // Coordinates are now LOCAL to the pushMatrix/translate cell
        particles.add(new Particle(x, finalY, zoneColor, slope));
      }
    }
    endShape();
  }
}

class Particle {
  PVector pos, vel;
  float alpha, size;
  color c;

  Particle(float x, float y, color _c, float slope) {
    pos = new PVector(x, y);
    vel = new PVector(1.0, slope);
    vel.normalize();
    vel.mult(FLOW_SPEED); 
    c = _c;
    alpha = random(180, 255);
    size = random(1.5, PARTICLE_SIZE);
  }

  void run() {
    pos.add(vel);
    alpha -= PARTICLE_DECAY;
    size *= 0.98;
  }

  void display() {
    noStroke();
    fill(c, alpha);
    circle(pos.x, pos.y, size);
  }

  boolean isDead() { return alpha <= 0; }
}

void drawDebugGrid() {
  stroke(127, 40);
  strokeWeight(1);
  for (int i = 0; i <= width; i += 40) line(i, 0, i, height);
  for (int j = 0; j <= height; j += 40) line(0, j, width, j);
}
