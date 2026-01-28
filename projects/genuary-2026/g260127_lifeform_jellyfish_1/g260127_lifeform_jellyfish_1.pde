/**
 * Kinematic Medusozoa (V18)
 * Features: Corrected vertical boundary masking, amplitude sound reactivity,
 * asynchronous pulsing, and soft-body collisions.
 */

import ddf.minim.*;

// --- Configuration Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int SEED_VALUE = 555;         // Global random seed
int PADDING = 60;             // Canvas padding (respected on all sides)
int MAX_FRAMES = 960;         // Max frames for save mode
boolean SAVE_FRAMES = false;  // Toggle frame saving
int ANIMATION_SPEED = 30;     // Target frame rate
boolean INVERT_BG = false;    // Toggle background inversion
boolean SHOW_GRID = false;    // Toggle debug grid
int PALETTE_INDEX = 1;        // Chosen palette index

// Sound Parameters
boolean SOUND_REACTIVE = true; // Toggle amplitude reactivity
String AUDIO_FILE = "jellyfish.mp3"; 
float SOUND_SENSITIVITY = 1.5; // Multiplier for volume impact

// Jellyfish Parameters
int JELLY_COUNT = 19;         
int MIN_TENTACLES = 7;        
int MAX_TENTACLES = 11;       
float T_THICK_MIN = 1.5;      
float T_THICK_MAX = 7.5;      
float GRAVITY_FORCE = 3.5;    

// Physics & Effects
float SURGE_STRENGTH = 0.5;   
float RISING_SPEED = -1.1;   
float SINKING_SPEED = 0.9;   
boolean PULSE_LIGHT = true;   
float PULSE_GLOW_MAX = 1.5;   
boolean COLLISION_ON = false;  
float COLLISION_STR = 0.05;   

// Color Palettes
String[][] PALETTES = {
  {"#2E112D", "#540032", "#820333", "#C02739", "#F1BB7B"}, // 0: Deep Reds
  {"#0B0C10", "#C5C3C3", "#C5C6C7", "#66FCF1", "#45A29E"}, // 1: Updated Biolum
  {"#2D4263", "#C84B31", "#ECDBBA", "#191919", "#56445D"}, // 2: Muted Earth
  {"#121212", "#323232", "#FFAC41", "#FF1E56", "#EEEEEE"}, // 3: Cyber
  {"#222831", "#393E46", "#00ADB5", "#EEEEEE", "#FFD369"}  // 4: Oceanic
};

Jellyfish[] swarm;
int[] activePalette;
Minim minim;
AudioPlayer player;
boolean audioLoaded = false;
float currentVolume = 0;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  activePalette = new int[5];
  for (int i = 0; i < 5; i++) {
    activePalette[i] = unhex("FF" + PALETTES[PALETTE_INDEX][i].substring(1));
  }

  if (SOUND_REACTIVE) {
    try {
      minim = new Minim(this);
      player = minim.loadFile(AUDIO_FILE, 1024);
      if (player != null) {
        player.loop();
        audioLoaded = true;
      }
    } catch (Exception e) {
      println("Audio file issue.");
    }
  }

  swarm = new Jellyfish[JELLY_COUNT];
  for (int i = 0; i < JELLY_COUNT; i++) {
    swarm[i] = new Jellyfish(random(PADDING + 40, width - PADDING - 40), random(height * 0.5, height - PADDING - 100));
  }
}

void draw() {
  int bgColor = INVERT_BG ? activePalette[4] : activePalette[0];
  background(bgColor);

  if (SHOW_GRID) drawDebugGrid();

  if (audioLoaded) currentVolume = player.mix.level() * SOUND_SENSITIVITY;

  float currentSurge = sin(frameCount * 0.015) * SURGE_STRENGTH;

  for (int i = 0; i < swarm.length; i++) {
    if (COLLISION_ON) {
      for (int j = i + 1; j < swarm.length; j++) {
        swarm[i].checkCollision(swarm[j]);
      }
    }
    swarm[i].update(currentSurge, currentVolume);
    swarm[i].display(currentVolume);
  }

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void drawDebugGrid() {
  noFill();
  stroke(activePalette[3], 50);
  rect(PADDING, PADDING, width - PADDING * 2, height - PADDING * 2);
}

class Jellyfish {
  PVector pos, vel;
  Tentacle[] limbs;
  float pulseOffset, bSize, bVar, pulseFreq;
  int clr;
  boolean isSinking = false;

  Jellyfish(float x, float y) {
    pos = new PVector(x, y);
    vel = new PVector(random(-0.1, 0.1), RISING_SPEED);
    pulseOffset = random(TWO_PI);
    pulseFreq = random(0.04, 0.08); 
    bSize = random(25, 40);
    bVar = random(0.5, 1.2); 
    clr = activePalette[(int)random(1, 4)];
    
    int tCount = (int)random(MIN_TENTACLES, MAX_TENTACLES + 1);
    limbs = new Tentacle[tCount];
    for (int i = 0; i < tCount; i++) {
      limbs[i] = new Tentacle(bSize, pos);
    }
  }

  void checkCollision(Jellyfish other) {
    float minDist = (this.bSize + other.bSize) * 1.1;
    if (PVector.dist(this.pos, other.pos) < minDist) {
      PVector force = PVector.sub(this.pos, other.pos).setMag(COLLISION_STR);
      this.vel.add(force);
      other.vel.sub(force);
    }
  }

  void update(float surge, float volume) {
    float pulse = sin(frameCount * pulseFreq + pulseOffset);
    float drive = map(pulse, -1, 1, 0.1, 2.0) + (volume * 1.5);
    
    pos.x += (vel.x + surge);
    pos.y += (isSinking ? SINKING_SPEED : vel.y) * drive;
    vel.x *= 0.95;

    // Strict Padding Constraints
    float bellBottom = (bSize * 0.6 * bVar);
    // Boundary checks for X
    if (pos.x < PADDING + bSize) { pos.x = PADDING + bSize; vel.x *= -1; }
    if (pos.x > width - PADDING - bSize) { pos.x = width - PADDING - bSize; vel.x *= -1; }
    
    // Boundary checks for Y (Top & Bottom)
    if (pos.y < PADDING + bellBottom) { 
      pos.y = PADDING + bellBottom; 
      isSinking = true; 
    } 
    // Ensuring tentacles (which dangle below) don't clip the bottom padding
    // Approximation: 150px for max tentacle dangle
    if (pos.y > height - PADDING - 150) { 
      pos.y = height - PADDING - 150; 
      isSinking = false; 
    } 

    for (Tentacle t : limbs) t.update(pos, pulse, surge, bVar);
  }

  void display(float volume) {
    float pulse = sin(frameCount * pulseFreq + pulseOffset);
    float contract = map(pulse, -1, 1, 0.7, 1.15);
    
    float glowBase = 1.0;
    if (PULSE_LIGHT) {
      float contractionGlow = map(pulse, -1, -0.2, 0.5, 0);
      glowBase = 1.0 + max(0, contractionGlow) + (volume * 2.0);
      glowBase = min(glowBase, 5.0);
    }

    for (Tentacle t : limbs) t.display(clr);

    pushMatrix();
    translate(pos.x, pos.y);
    noFill();
    for (int i = 5; i > 0; i--) {
      stroke(clr, (35 / i) * glowBase);
      strokeWeight(i * 4);
      drawBellShape(contract, i * 2);
    }
    noStroke();
    fill(clr, 210);
    drawBellShape(contract, 0);
    popMatrix();
  }

  void drawBellShape(float contract, float offset) {
    beginShape();
    for (float a = 0; a <= PI; a += 0.1) {
      float r = (bSize + offset) * contract;
      float x = cos(a + PI) * r;
      float y = sin(a + PI) * r * (0.6 * bVar);
      vertex(x, y);
    }
    bezierVertex(bSize * 0.6 * contract, 18 * contract, -bSize * 0.6 * contract, 18 * contract, -bSize * contract, 0);
    endShape(CLOSE);
  }
}

class Tentacle {
  PVector[] segs;
  float[] lens;
  float relX, relY, tBase, tTip;
  int sCount;

  Tentacle(float bellR, PVector startPos) {
    sCount = (int)random(14, 22);
    segs = new PVector[sCount];
    lens = new float[sCount];
    relX = random(-bellR * 0.6, bellR * 0.6);
    relY = 5;
    tBase = random(T_THICK_MIN + 2.0, T_THICK_MAX);
    tTip = T_THICK_MIN;

    for (int i = 0; i < sCount; i++) {
      lens[i] = map(i, 0, sCount, 14, 6);
      segs[i] = new PVector(startPos.x + relX, startPos.y + (i * 10)); 
    }
  }

  void update(PVector head, float pulse, float surge, float bVar) {
    float contractX = map(pulse, -1, 1, 0.45, 1.1);
    float pullUp = map(pulse, 0.5, 1, 0, -10); 
    float bellBottomY = (abs(sin(PI)) * 0.6 * bVar); 

    for (int i = 1; i < sCount; i++) {
      segs[i].y += GRAVITY_FORCE;
      segs[i].x += (surge * 0.5) + sin(frameCount * 0.05 + i * 0.4) * 0.8;
    }

    segs[0].set(head.x + (relX * contractX), head.y + bellBottomY + relY + (pullUp < 0 ? pullUp : 0));
    for (int i = 1; i < sCount; i++) {
      PVector d = PVector.sub(segs[i], segs[i-1]).setMag(lens[i-1]);
      segs[i] = PVector.add(segs[i-1], d);
    }
  }

  void display(int c) {
    noFill();
    for (int i = 1; i < sCount; i++) {
      float w = map(i, 0, sCount, tBase, tTip);
      stroke(c, map(i, 0, sCount, 220, 0));
      strokeWeight(w);
      line(segs[i-1].x, segs[i-1].y, segs[i].x, segs[i].y);
    }
  }
}

void stop() {
  if (audioLoaded) { player.close(); minim.stop(); }
  super.stop();
}
