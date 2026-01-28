/**
 * Audio-Driven Physics Engine
 * Version: 2026.01.27.09.22.15
 * * Maps audio amplitude to gravity. 
 * High volume = Heavy gravity / Collapse
 * Low volume = Zero gravity / Floating
 */

import ddf.minim.*;
import ddf.minim.analysis.*;

// --- Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int SEED_VALUE = 42;          // Default: 42
int MAX_FRAMES = 1800;        // Default: 900 (Adjusted for typical mp3 length)
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
boolean INVERT_BG = false;    // Default: false
boolean SHOW_GRID = false;    // Default: false
int PALETTE_INDEX = 2;        // Default: 0-4

// Physics Constants
float FRICTION = 0.98;        // Default: 0.98
float BOUNCE = -0.7;          // Default: -0.7
float GRAVITY_MULT = 1.5;     // Default: 1.5 (Scale for amplitude)
int PARTICLE_COUNT = 150;     // Default: 150

// --- Color Palettes (Adobe Color / Kuler) ---
String[][] PALETTES = {
  {"#1B676B", "#519548", "#88C425", "#BEF202", "#EAFDE6"}, // Fresh
  {"#020122", "#352D39", "#6B818C", "#F2E94E", "#C2E812"}, // Night Neon
  {"#FF2E63", "#08D9D6", "#252A34", "#EAEAEA", "#FFD700"}, // Retro Modern
  {"#222831", "#393E46", "#00ADB5", "#EEEEEE", "#FF5722"}, // Cyber
  {"#540D6E", "#EE4266", "#FFD23F", "#3BCEAC", "#0EAD69"}  // Vibrant
};

// --- Global Variables ---
Minim minim;
AudioPlayer song;
ArrayList<Particle> particles;
int bgColor, strokeColor;
float currentGravity = 0;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  // Audio Setup
  minim = new Minim(this);
  song = minim.loadFile("frenzy.mp3", 1024);
  song.play();
  
  // Set MAX_FRAMES to song length if necessary
  // MAX_FRAMES = int((song.length() / 1000.0) * ANIMATION_SPEED);

  // Color Setup
  String[] activePalette = PALETTES[PALETTE_INDEX];
  bgColor = unhex("FF" + activePalette[0].substring(1));
  if (INVERT_BG) bgColor = color(255 - red(bgColor), 255 - green(bgColor), 255 - blue(bgColor));
  strokeColor = unhex("FF" + activePalette[1].substring(1));

  // Initialize Physics
  particles = new ArrayList<Particle>();
  for (int i = 0; i < PARTICLE_COUNT; i++) {
    particles.add(new Particle(activePalette));
  }
}

void draw() {
  background(bgColor);
  
  if (SHOW_GRID) drawDebugGrid();

  // Map volume to gravity
  float amplitude = song.mix.level(); 
  currentGravity = amplitude * GRAVITY_MULT;

  // Update and Display Particles
  for (Particle p : particles) {
    p.applyForce(currentGravity);
    p.update();
    p.edges();
    p.display();
  }

  // Visual feedback for gravity "floor"
  stroke(strokeColor, 100);
  line(PADDING, height - PADDING, width - PADDING, height - PADDING);

  // Record/End Logic
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      song.stop();
      noLoop();
    }
  }
}

void drawDebugGrid() {
  stroke(127, 50);
  for (int i = PADDING; i <= width - PADDING; i += 20) line(i, PADDING, i, height - PADDING);
  for (int j = PADDING; j <= height - PADDING; j += 20) line(PADDING, j, width - PADDING, j);
}

// --- Particle Class ---
class Particle {
  PVector pos, vel, acc;
  float radius;
  int pColor;

  Particle(String[] palette) {
    pos = new PVector(random(PADDING, width - PADDING), random(PADDING, height - PADDING));
    vel = PVector.random2D().mult(random(1, 4));
    acc = new PVector(0, 0);
    radius = random(4, 12);
    pColor = unhex("FF" + palette[int(random(1, palette.length))].substring(1));
  }

  void applyForce(float force) {
    acc.y += force;
  }

  void update() {
    vel.add(acc);
    vel.mult(FRICTION);
    pos.add(vel);
    acc.mult(0); // Reset acceleration
  }

  void edges() {
    // Bottom boundary
    if (pos.y > height - PADDING - radius) {
      pos.y = height - PADDING - radius;
      vel.y *= BOUNCE;
    }
    // Top boundary (allow floating out slightly but keep in frame)
    if (pos.y < PADDING + radius) {
      pos.y = PADDING + radius;
      vel.y *= BOUNCE;
    }
    // Left/Right
    if (pos.x > width - PADDING - radius || pos.x < PADDING + radius) {
      vel.x *= BOUNCE;
      pos.x = constrain(pos.x, PADDING + radius, width - PADDING - radius);
    }
  }

  void display() {
    noStroke();
    fill(pColor, 200);
    ellipse(pos.x, pos.y, radius * 2, radius * 2);
    
    // Add a small "glow" or connection line if close to floor during high gravity
    if (currentGravity > 0.5) {
      stroke(pColor, 50);
      line(pos.x, pos.y, pos.x, height - PADDING);
    }
  }
}

void stop() {
  song.close();
  minim.stop();
  super.stop();
}
