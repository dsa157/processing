/*
 * Sketch: The Zero-Crossing Glitch - Particle Decay Edition
 * Version: 2026.01.27.09.38.22
 * Description: High-performance audio visualization. Zero-crossings flicker colors,
 * while peaks trigger ghost waves and snappy geometric particle bursts. 
 * Decay is frame-based for predictable life cycles.
 */

import ddf.minim.*;

// --- PARAMETERS ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int SEED = 42;                // Default: 42
int ANIMATION_SPEED = 60;     // Default: 60 (Increased for smoothness)
float THRESHOLD = 0.130;      // Default: 0.130
float VERTICAL_SCALE = 300.0; // Default: 300.0
int WAVE_ALPHA = 60;          // Default: 60
int GHOST_START_ALPHA = 200;  // Default: 200
int DECAY_FRAMES = 10;        // Default: 45 (Life of ghosts/particles in frames)
int PARTICLES_PER_EXPLOSION = 5; // Default: 8
float PARTICLE_SPEED = 60.0;   // Default: 6.0

int PALETTE_INDEX = 0;        // Range: 0-4
boolean INVERT_BG = false;    // Default: false
boolean SAVE_FRAMES = false;  // Default: false
int MAX_FRAMES = 900;         

// --- COLORS ---
String[][] PALETTES = {
  {"#1A1A1A", "#FF0055", "#00FF99", "#0088FF", "#FFFF00"},
  {"#F2F2F2", "#2E3440", "#5E81AC", "#BF616A", "#D08770"},
  {"#0B0D0F", "#45062E", "#7F055F", "#E5A4CB", "#FB3640"},
  {"#264653", "#2A9D8F", "#E9C46A", "#F4A261", "#E76F51"},
  {"#000000", "#FFFFFF", "#777777", "#AAAAAA", "#444444"}
};

// --- GLOBALS ---
Minim minim;
AudioPlayer song;
ArrayList<GhostWave> ghosts = new ArrayList<GhostWave>();
ArrayList<Particle> particles = new ArrayList<Particle>();
int activeStroke;
int bgBase;
float lastVal = 0;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED);
  frameRate(ANIMATION_SPEED);
  
  minim = new Minim(this);
  song = minim.loadFile("frenzy.mp3", 1024);
  song.play();
  
  MAX_FRAMES = floor((song.length() / 1000.0) * ANIMATION_SPEED);
  pickColors();
}

void pickColors() {
  String[] currentPalette = PALETTES[PALETTE_INDEX];
  bgBase = unhex("FF" + currentPalette[0].substring(1));
  if (INVERT_BG) bgBase = color(255 - red(bgBase), 255 - green(bgBase), 255 - blue(bgBase));
  activeStroke = unhex("FF" + currentPalette[1].substring(1));
}

void draw() {
  background(bgBase);
  float centerY = height / 2.0;

  // Draw Ghost Waves
  for (int i = ghosts.size() - 1; i >= 0; i--) {
    GhostWave gw = ghosts.get(i);
    gw.update();
    gw.display(centerY);
    if (gw.isDead()) ghosts.remove(i);
  }

  // Draw Particles (Simplified for speed)
  for (int i = particles.size() - 1; i >= 0; i--) {
    Particle p = particles.get(i);
    p.update();
    p.display();
    if (p.isDead()) particles.remove(i);
  }

  // Live Waveform
  noFill();
  strokeWeight(2);
  stroke(activeStroke, WAVE_ALPHA);
  
  beginShape();
  for (int i = 0; i < song.bufferSize(); i += 2) {
    float x = map(i, 0, song.bufferSize(), PADDING, width - PADDING);
    float val = song.mix.get(i);
    float y = centerY + val * VERTICAL_SCALE;
    vertex(x, y);
    
    // Zero-Crossing Logic
    if ((lastVal <= 0 && val > 0) || (lastVal >= 0 && val < 0)) {
      triggerGlitch();
    }
    
    // Threshold Trigger
    if (abs(val) > THRESHOLD && frameCount % 6 == 0) {
      spawnGhost(song.mix.toArray(), x, y);
    }
    lastVal = val;
  }
  endShape();

  // Lifecycle Management
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
  if (!song.isPlaying() && SAVE_FRAMES) noLoop();
}

void triggerGlitch() {
  String[] p = PALETTES[PALETTE_INDEX];
  activeStroke = unhex("FF" + p[floor(random(1, p.length))].substring(1));
}

void spawnGhost(float[] buffer, float x, float y) {
  String[] p = PALETTES[PALETTE_INDEX];
  int col = unhex("FF" + p[floor(random(1, p.length))].substring(1));
  ghosts.add(new GhostWave(buffer, col));
  
  for (int i = 0; i < PARTICLES_PER_EXPLOSION; i++) {
    particles.add(new Particle(x, y, col));
  }
}

// --- CLASSES ---

class GhostWave {
  float[] points;
  int c;
  int age = 0;

  GhostWave(float[] b, int col) {
    points = new float[b.length];
    arrayCopy(b, points);
    c = col;
  }

  void update() { age++; }

  void display(float cy) {
    float alpha = map(age, 0, DECAY_FRAMES, GHOST_START_ALPHA, 0);
    stroke(c, alpha);
    noFill();
    beginShape();
    for (int i = 0; i < points.length; i += 12) { // Sparse for speed
      float x = map(i, 0, points.length, PADDING, width - PADDING);
      float y = cy + points[i] * VERTICAL_SCALE;
      vertex(x, y);
    }
    endShape();
  }

  boolean isDead() { return age >= DECAY_FRAMES; }
}

class Particle {
  PVector pos, vel;
  int c;
  int age = 0;

  Particle(float x, float y, int col) {
    pos = new PVector(x, y);
    vel = PVector.random2D().mult(random(2, PARTICLE_SPEED));
    c = col;
  }

  void update() {
    pos.add(vel);
    age++;
  }

  void display() {
    float alpha = map(age, 0, DECAY_FRAMES, GHOST_START_ALPHA, 0);
    stroke(c, alpha);
    strokeWeight(3);
    point(pos.x, pos.y);
  }

  boolean isDead() { return age >= DECAY_FRAMES; }
}

void stop() {
  song.close();
  minim.stop();
  super.stop();
}
