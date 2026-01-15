/**
 * Luminance Flux - Glitch Edition
 * Version: 2026.01.01.20.05.42
 * * Features:
 * - Automated light cycle with glitch transitions.
 * - Customizable particle size ranges.
 * - 3 Switchable color palettes.
 */

// --- Global Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int SEED_VALUE = 42;          // Default: 42
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
boolean SHOW_GRID = false;    // Default: false

// --- Logic Parameters ---
int CYCLE_DURATION = 100;     // Default: 150
float LIGHT_TRANSITION = 0.1f;// Default: 0.1
int PARTICLE_COUNT = 1000;     // Default: 200
float NOISE_SCALE = 0.006f;   // Default: 0.006
float GLITCH_STRENGTH = 1.0f;// Default: 15.0

// --- Particle Size Parameters ---
float MIN_SIZE = 15.0f;        // Default: 2.0
float MAX_SIZE = 40.0f;       // Default: 12.0

// --- Color Palettes (Pick one) ---
// Option 1: Cyber Dusk (Default)
//String[] PALETTE = {"#0B0D17", "#FFD700", "#00F5FF", "#F0F0F0", "#BF00FF"};
//String[] PALETTE =  {"#2D3047", "#FF9F1C", "#FFBF69", "#FFFFFF", "#2EC4B6"};
String[] PALETTE = {"#1A1A1A", "#70E000", "#38B000", "#FFFFFF", "#008000"};

// --- State Variables ---
boolean lightsOn = false;
float transitionFactor = 0;   
ArrayList<Particle> particles;
float glitchOffset = 0;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  noiseSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  particles = new ArrayList<Particle>();
  for (int i = 0; i < PARTICLE_COUNT; i++) {
    particles.add(new Particle());
  }
}

void draw() {
  // --- Automated Light Cycle & Glitch Logic ---
  if (frameCount % CYCLE_DURATION == 0) {
    lightsOn = !lightsOn;
    glitchOffset = GLITCH_STRENGTH; // Trigger glitch
  }
  glitchOffset *= 0.85f; // Decay glitch effect

  transitionFactor = lerp(transitionFactor, lightsOn ? 1.0 : 0.0, LIGHT_TRANSITION);
  
  // Background Interpolation
  color colDark = unhex("FF" + PALETTE[0].substring(1));
  color colLight = unhex("FF" + PALETTE[3].substring(1));
  background(lerpColor(colDark, colLight, transitionFactor));
  
  // Apply Glitch Screen Shake
  pushMatrix();
  float gx = random(-glitchOffset, glitchOffset);
  float gy = random(-glitchOffset, glitchOffset);
  translate(PADDING + gx, PADDING + gy);
  
  int activeWidth = width - (PADDING * 2);
  int activeHeight = height - (PADDING * 2);

  if (SHOW_GRID) drawDebugGrid(activeWidth, activeHeight);

  // Update and Draw Particles
  for (Particle p : particles) {
    p.update(activeWidth, activeHeight);
    p.display();
  }
  
  // Glitch "Scanlines" or displacement
  if (glitchOffset > 1.0) {
    drawGlitchArtifacts(activeWidth, activeHeight);
  }
  
  popMatrix();

  // --- Frame Saving and Termination ---
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void drawGlitchArtifacts(int w, int h) {
  stroke(unhex("FF" + PALETTE[2].substring(1)), 100);
  for (int i = 0; i < 5; i++) {
    float y = random(h);
    float hSize = random(2, 10);
    line(random(-20, 0), y, w + random(0, 20), y + random(-2, 2));
  }
}

void drawDebugGrid(int w, int h) {
  stroke(128, 50);
  int gridSteps = 10;
  for (int i = 0; i <= gridSteps; i++) {
    line(i * (w/gridSteps), 0, i * (w/gridSteps), h);
    line(0, i * (h/gridSteps), w, i * (h/gridSteps));
  }
}

// --- Particle Entity ---
class Particle {
  PVector pos, vel, acc;
  float maxSpeed;
  color pColor;
  float pSize;

  Particle() {
    pos = new PVector(random(width - PADDING * 2), random(height - PADDING * 2));
    vel = PVector.random2D().mult(random(2, 4));
    acc = new PVector(0, 0);
    maxSpeed = random(3, 6);
    pSize = random(MIN_SIZE, MAX_SIZE);
    pColor = unhex("FF" + PALETTE[int(random(1, 5))].substring(1));
  }

  void update(int w, int h) {
    if (lightsOn) {
      pos.add(vel);
      if (pos.x <= 0 || pos.x >= w) vel.x *= -1;
      if (pos.y <= 0 || pos.y >= h) vel.y *= -1;
      pos.x = constrain(pos.x, 0, w);
      pos.y = constrain(pos.y, 0, h);
    } else {
      float n = noise(pos.x * NOISE_SCALE, pos.y * NOISE_SCALE, frameCount * 0.005);
      float angle = n * TWO_PI * 4;
      acc = PVector.fromAngle(angle).mult(0.2);
      vel.add(acc);
      vel.limit(maxSpeed * 0.6);
      pos.add(vel);
      if (pos.x < 0) pos.x = w;
      if (pos.x > w) pos.x = 0;
      if (pos.y < 0) pos.y = h;
      if (pos.y > h) pos.y = 0;
    }
  }

  void display() {
    float alphaVal = lerp(150, 255, transitionFactor);
    pushMatrix();
    translate(pos.x, pos.y);
    
    if (transitionFactor > 0.5) {
      // Lights On: Geometric Squares
      noFill();
      stroke(pColor, alphaVal);
      strokeWeight(1.5);
      rectMode(CENTER);
      rect(0, 0, pSize, pSize);
      // Occasional glitch stretching
      if (glitchOffset > 5) {
        line(-pSize, 0, pSize * 2, 0);
      }
    } else {
      // Lights Off: Organic Circles
      fill(pColor, 40);
      stroke(pColor, alphaVal);
      strokeWeight(1);
      ellipse(0, 0, pSize, pSize);
      fill(pColor, 200);
      noStroke();
      ellipse(0, 0, 2, 2);
    }
    popMatrix();
  }
}
