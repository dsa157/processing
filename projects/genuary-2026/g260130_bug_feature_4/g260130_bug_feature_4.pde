/**
 * Sketch: Dual-Stem Spiral Coordinate Swap
 * Description: Two separate Archimedean spiral emitters with 5 arms. 
 * Top emitter reacts to Treble, bottom to Bass. Axes swap on snares, emitters 
 * jump on kicks. Features frequency-synced breathing and chromatic aberration.
 * Version: 2026.01.28.10.55.12
 */

import ddf.minim.*;
import ddf.minim.analysis.*;

// --- Parameters & Constants ---
int SKETCH_WIDTH = 480;          // Canvas width (480)
int SKETCH_HEIGHT = 800;         // Canvas height (800)

int RANDOM_SEED = 42;            // Seed for reproducibility (42)
int PADDING = 40;                // Screen border padding (40)
int MAX_FRAMES = 900;            // Total duration (updated by audio length)
boolean SAVE_FRAMES = false;     // Toggle saving frames (false)
int ANIMATION_SPEED = 30;        // Frames per second (30)
boolean INVERT_BACK = false;     // Invert background color (false)
boolean SHOW_GRID = false;       // Toggle grid visibility (false)
int PALETTE_INDEX = 4;           // Color palette index (0-4)

// --- Visual & Particle Parameters ---
int SPIRAL_ARMS = 15;             // Number of spiral arms (5)
float BLUR_ALPHA = 20.0;        // Motion blur transparency (200.0)
float PARTICLE_LIFESPAN = 70.0;  // Particle starting frames (70.0)
float LIFESPAN_DECAY = 1.1;      // Decay per frame (1.1)
float SPIRAL_TIGHTNESS = 1.2;    // Growth rate of spiral (0.2)
float SPIRAL_VELOCITY = 0.5;    // Rotation of emitter (0.05)
float PARTICLE_SPEED = 0.1;     // Radial expansion speed (0.01)
float P_SIZE_MIN = 1.0;          // Minimum particle size (1.0)
float P_SIZE_MAX = 3.0;          // Maximum particle size (8.0)
float GRID_STEP = 40.0;          // Grid line spacing (40.0)
int BEAT_SENSITIVITY = 50;      // Beat detection threshold in ms (500)

// --- Toggles ---
boolean USE_DISTORTION = true;   // Background pulse on bass
boolean USE_ABERRATION = false;   // Color shift on coordinate swap
boolean USE_BREATHING = true;    // Fluctuating tightness based on frequency

// --- Color Palettes ---
color[][] PALETTES = {
  {#2E112D, #540032, #820333, #C02739, #F1E4E8}, // Retro Red
  {#1A508B, #00334E, #14FFEC, #0D7377, #EEEEEE}, // Cyber Neon
  {#FFBCBC, #FF4848, #C400C6, #670067, #310031}, // Pink/Purple
  {#F9ED69, #F08A5D, #B83B5E, #6A2C70, #3F3250}, // Sunset
  {#111111, #444444, #888888, #CCCCCC, #FFFFFF}  // Grayscale
};

// --- Global Objects ---
Minim minim;
AudioPlayer player;
BeatDetect beat;
FFT fft;
ParticleSystem ps;

// --- State Variables ---
boolean isSwapped = false;
PVector emitterTop, emitterBottom;
float globalTheta = 0;
int swapTimer = 0;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  frameRate(ANIMATION_SPEED);
  randomSeed(RANDOM_SEED);
  
  minim = new Minim(this);
  player = minim.loadFile("frenzy.mp3", 1024);
  
  if (player == null) {
    println("File frenzy.mp3 not found.");
    exit();
  }

  beat = new BeatDetect();
  beat.setSensitivity(BEAT_SENSITIVITY); 
  fft = new FFT(player.bufferSize(), player.sampleRate());
  
  // Set MAX_FRAMES to audio length
  MAX_FRAMES = int((player.length() / 1000.0) * ANIMATION_SPEED);
  
  emitterTop = new PVector(width/2, height * 0.33);
  emitterBottom = new PVector(width/2, height * 0.66);
  
  ps = new ParticleSystem();
  player.play();
}

void draw() {
  beat.detect(player.mix);
  fft.forward(player.mix);
  
  color[] activePalette = PALETTES[PALETTE_INDEX];
  color backColor = activePalette[0];
  if (INVERT_BACK) {
    backColor = color(255 - red(backColor), 255 - green(backColor), 255 - blue(backColor));
  }
  
  // Distortion logic
  float bassMag = fft.calcAvg(20, 150);
  float trebleMag = fft.calcAvg(4000, 10000);
  float distScale = USE_DISTORTION ? 1.0 + (bassMag * 0.02) : 1.0;

  pushMatrix();
  translate(width/2, height/2);
  scale(distScale);
  noStroke();
  fill(backColor, BLUR_ALPHA);
  rectMode(CENTER);
  rect(0, 0, width * 2, height * 2); 
  popMatrix();
  rectMode(CORNER);
  
  // Snare logic for X/Y swap and Aberration
  if (beat.isSnare()) {
    isSwapped = !isSwapped;
    swapTimer = 10;
  }
  // Kick logic for emitter jump
  if (beat.isKick()) {
    emitterTop.x = random(PADDING * 2, width - PADDING * 2);
    emitterBottom.x = random(PADDING * 2, width - PADDING * 2);
  }
  
  if (SHOW_GRID) drawGrid(activePalette[1]);
  
  globalTheta += SPIRAL_VELOCITY;
  
  // Calculate breathing tightness
  float trebleTight = SPIRAL_TIGHTNESS + (USE_BREATHING ? trebleMag * 0.5 : 0);
  float bassTight = SPIRAL_TIGHTNESS + (USE_BREATHING ? bassMag * 0.1 : 0);

  // Emit Particles for both stems
  for (int i = 0; i < SPIRAL_ARMS; i++) {
    float offset = (TWO_PI / SPIRAL_ARMS) * i;
    ps.addParticle(emitterTop, globalTheta + offset, 1, trebleTight);
    ps.addParticle(emitterBottom, globalTheta + offset, 0, bassTight);
  }
  
  // Render loop with optional Chromatic Aberration
  if (USE_ABERRATION && swapTimer > 0) {
    pushStyle();
    tint(255, 0, 0, 200);
    ps.run(activePalette, new PVector(swapTimer, 0));
    tint(0, 0, 255, 200);
    ps.run(activePalette, new PVector(-swapTimer, 0));
    popStyle();
    swapTimer--;
  } else {
    ps.run(activePalette, new PVector(0, 0));
  }
  
  // Saving and Termination
  if (SAVE_FRAMES) saveFrame("frames/####.tif");
  if (frameCount >= MAX_FRAMES) exit();
}

void drawGrid(color c) {
  stroke(c, 30);
  strokeWeight(1);
  for (float i = PADDING; i <= width - PADDING; i += GRID_STEP) line(i, PADDING, i, height - PADDING);
  for (float j = PADDING; j <= height - PADDING; j += GRID_STEP) line(PADDING, j, width - PADDING, j);
}

void exit() {
  if (player != null) player.close();
  if (minim != null) minim.stop();
  super.exit();
}

class ParticleSystem {
  ArrayList<Particle> particles;

  ParticleSystem() {
    particles = new ArrayList<Particle>();
  }

  void addParticle(PVector origin, float angle, int type, float tightness) {
    particles.add(new Particle(origin, angle, type, tightness));
  }

  void run(color[] palette, PVector offset) {
    for (int i = particles.size() - 1; i >= 0; i--) {
      Particle p = particles.get(i);
      p.update();
      p.display(palette, offset);
      if (p.isDead()) particles.remove(i);
    }
  }
}

class Particle {
  PVector origin;
  float startTheta, age, lifespan, currentTightness;
  int freqType; // 0: Bass, 1: Treble

  Particle(PVector o, float t, int type, float tight) {
    origin = o.copy();
    startTheta = t;
    age = 0;
    lifespan = PARTICLE_LIFESPAN;
    freqType = type;
    currentTightness = tight;
  }

  void update() {
    float bass = fft.calcAvg(20, 150);
    float treble = fft.calcAvg(4000, 10000);
    float growthRate = (freqType == 0) ? (PARTICLE_SPEED + bass * 0.1) : (PARTICLE_SPEED + treble * 0.4);
    age += growthRate;
    lifespan -= LIFESPAN_DECAY;
  }

  PVector getDisplayPos() {
    float theta = startTheta + (age * 0.4); 
    float r = age * (currentTightness * 10.0);
    float x = origin.x + cos(theta) * r;
    float y = origin.y + sin(theta) * r;
    
    if (isSwapped) {
      float tx = map(y, 0, height, PADDING, width - PADDING);
      float ty = map(x, 0, width, PADDING, height - PADDING);
      x = tx; y = ty;
    }
    return new PVector(x, y);
  }

  void display(color[] palette, PVector offset) {
    PVector dPos = getDisplayPos();
    dPos.add(offset);

    // Border bounds check
    if (dPos.x < PADDING || dPos.x > width - PADDING || dPos.y < PADDING || dPos.y > height - PADDING) {
      lifespan = -1;
    }

    if (lifespan > 0) {
      float alpha = map(lifespan, 0, PARTICLE_LIFESPAN, 0, 255);
      color c = (freqType == 0) ? palette[2] : palette[3]; 
      fill(c, alpha);
      noStroke();
      
      float s = map(lifespan, 0, PARTICLE_LIFESPAN, P_SIZE_MIN, P_SIZE_MAX);
      
      if (freqType == 1) {
        rectMode(CENTER);
        square(dPos.x, dPos.y, s);
      } else {
        ellipse(dPos.x, dPos.y, s, s);
      }
    }
  }

  boolean isDead() { return lifespan <= 0; }
}
