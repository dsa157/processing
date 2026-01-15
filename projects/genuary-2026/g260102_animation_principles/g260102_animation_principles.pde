/**
 * Animation Principles Showcase - Extended Trails & Precision Landing
 * Version: 2025.12.18.12.04.15
 * * PRINCIPLES USED:
 * 1. SQUASH AND STRETCH: Applied to Blobs based on Y-velocity and Platform impact.
 * 2. ANTICIPATION: Handled via the spawn delay and the platform's initial bend.
 * 3. STAGING: Clear chasm layout and contrasting colors to guide the eye.
 * 4. STRAIGHT AHEAD vs POSE TO POSE: Physics-driven "Straight Ahead" motion.
 * 5. FOLLOW THROUGH & OVERLAPPING ACTION: Dynamic motion trails (history array).
 * 6. SLOW IN AND SLOW OUT: Gravity and friction acceleration/deceleration.
 * 7. ARCS: Natural falling trajectories and curved platform shapes.
 * 8. SECONDARY ACTION: Platform bending motion upon impact.
 * 9. TIMING: Configurable spawn intervals and platform spring physics.
 * 10. EXAGGERATION: Intensified squash/stretch and platform "snap-back."
 * 11. SOLID DRAWING: Use of volume highlights and 2D shapes that imply 3D space.
 * 12. APPEAL: Blobby character designs with expressive, downward-looking eyes.
 */

// --- GLOBAL CONFIGURATION ---
int SKETCH_WIDTH = 480;
int SKETCH_HEIGHT = 800;
int SEED_VALUE = 2024; 
int PADDING = 40; 
int MAX_FRAMES = 900; 
boolean SAVE_FRAMES = false; 
int ANIMATION_SPEED = 60; 
boolean SHOW_GRID = false; 
boolean INVERT_COLORS = false; 

// --- CONFIGURABLE PARAMETERS ---
int ENTITY_COUNT = 6; 
int PLATFORM_COUNT = 6; 
float PLATFORM_WIDTH = 180.0; 
float GRAVITY = 0.1; 
float BOUNCE_FRICTION = -0.50; 
float HORIZONTAL_FRICTION = 0.96; 
float PLATFORM_DAMPING = 0.80; 
float PUSH_AWAY_FORCE = 0.2; 
int SPAWN_INTERVAL = 120; 
int TRAIL_LENGTH = 25; // Original: 12 - Configurable trail length

// --- COLOR PALETTE (Adobe Color: "Deep Sea Bio") ---
int[] PALETTE = {
  0xFF011627, // Midnight Blue (Background)
  0xFF203C56, // Steel Blue (Platforms)
  0xFF2EC4B6, // Tiffany Blue (Character)
  0xFFE71D36, // Crimson (Eyes)
  0xFFFDFFFC  // Snow (Highlights)
};

Jumper[] blobs;
Platform[] platforms;
int activeBlobs = 0;
int spawnTimer = 0;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  platforms = new Platform[PLATFORM_COUNT];
  for (int i = 0; i < PLATFORM_COUNT; i++) {
    float y = map(i, 0, PLATFORM_COUNT, PADDING + 120, height - PADDING - 80);
    boolean isLeft = (i % 2 == 0);
    float x = isLeft ? PADDING : width - PADDING;
    // Principle: STAGING - The last platform is wider to catch sprites
    float customWidth = (i == PLATFORM_COUNT - 1) ? PLATFORM_WIDTH + 60 : PLATFORM_WIDTH;
    platforms[i] = new Platform(x, y, isLeft, customWidth);
  }
  
  blobs = new Jumper[ENTITY_COUNT];
  for (int i = 0; i < ENTITY_COUNT; i++) {
    blobs[i] = new Jumper();
  }
  
  blobs[0].isActive = true;
  activeBlobs = 1;
}

void draw() {
  int bgColor = INVERT_COLORS ? PALETTE[4] : PALETTE[0];
  background(bgColor);
  
  drawGrid();

  // Principle: TIMING - Staggered entry
  if (activeBlobs < ENTITY_COUNT) {
    spawnTimer++;
    if (spawnTimer >= SPAWN_INTERVAL) {
      blobs[activeBlobs].isActive = true;
      activeBlobs++;
      spawnTimer = 0;
    }
  }
  
  for (Platform p : platforms) {
    p.update();
    p.display();
  }
  
  for (Jumper b : blobs) {
    if (b.isActive) {
      b.update();
      b.display();
    }
  }
  
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void drawGrid() {
  if (!SHOW_GRID) return;
  stroke(INVERT_COLORS ? 0 : 255, 10);
  for (int x = PADDING; x <= width - PADDING; x += 40) line(x, PADDING, x, height - PADDING);
  for (int y = PADDING; y <= height - PADDING; y += 40) line(PADDING, y, width - PADDING, y);
}

class Platform {
  float x, y, bend, bendVel, w;
  float k = 0.15;
  boolean leftAligned;

  Platform(float xPos, float yPos, boolean left, float platformW) {
    x = xPos; y = yPos; leftAligned = left; w = platformW;
  }

  void impact(float force) { bendVel += force * 0.6; }
  void update() {
    float force = -k * bend;
    bendVel += force; bendVel *= PLATFORM_DAMPING; bend += bendVel;
  }

  void display() {
    stroke(PALETTE[1]);
    strokeWeight(6); noFill();
    beginShape();
    if (leftAligned) {
      vertex(x, y);
      quadraticVertex(x + w/2, y + bend, x + w, y);
    } else {
      vertex(x, y);
      quadraticVertex(x - w/2, y + bend, x - w, y);
    }
    endShape();
  }
}

class Jumper {
  PVector pos, vel;
  float baseDim = 42;
  float currentW, currentH;
  PVector[] history; // Principle: FOLLOW THROUGH
  boolean isActive = false;

  Jumper() {
    history = new PVector[TRAIL_LENGTH];
    reset();
  }

  void reset() {
    pos = new PVector(PADDING + random(20, 80), -100);
    vel = new PVector(0, random(1, 1.5));
    for (int i = 0; i < history.length; i++) history[i] = pos.copy();
  }

  void update() {
    vel.y += GRAVITY;
    vel.x *= HORIZONTAL_FRICTION; 
    pos.add(vel);

    for (Platform p : platforms) {
      boolean over = p.leftAligned ? (pos.x < p.x + p.w) : (pos.x > p.x - p.w);
      if (over) {
        float dynamicY = p.y + (p.bend * 0.5);
        if (pos.y + baseDim/2 > dynamicY - 8 && pos.y + baseDim/2 < dynamicY + 12 && vel.y > 0) {
          pos.y = dynamicY - baseDim/2;
          p.impact(vel.y * 4);
          vel.y *= BOUNCE_FRICTION;
          
          // Principle: ARCS - Redirection
          vel.x += p.leftAligned ? PUSH_AWAY_FORCE : -PUSH_AWAY_FORCE;
        }
      }
    }

    // Principle: SQUASH AND STRETCH
    float stretch = map(vel.y, -5, 8, -10, 20);
    currentW = baseDim - stretch;
    currentH = baseDim + stretch;

    if (pos.y > height + 100) reset();
    
    // Boundary Constraint
    if (pos.x < PADDING + baseDim/2 || pos.x > width - PADDING - baseDim/2) {
      vel.x *= -0.5;
      pos.x = constrain(pos.x, PADDING + baseDim/2, width - PADDING - baseDim/2);
    }
    
    // Principle: OVERLAPPING ACTION (Motion Trails)
    for (int i = history.length - 1; i > 0; i--) history[i] = history[i-1].copy();
    history[0] = pos.copy();
  }

  void display() {
    // Render Trail
    for (int i = 0; i < history.length; i++) {
      if (history[i] == null) continue;
      float factor = (float) (history.length - i) / history.length;
      float a = map(factor, 0, 1, 0, 80);
      float s = map(factor, 0, 1, baseDim * 0.1, baseDim * 0.7);
      fill(PALETTE[2], a); noStroke();
      ellipse(history[i].x, history[i].y, s, s);
    }

    pushMatrix();
    translate(pos.x, pos.y);
    
    // Character (Appeal)
    fill(PALETTE[2]); noStroke();
    ellipse(0, 0, currentW, currentH);
    
    // Eyes (Staging)
    fill(PALETTE[4]);
    ellipse(-9, 4, 11, 11); ellipse(9, 4, 11, 11);
    fill(PALETTE[3]);
    ellipse(-9, 6, 4, 4); ellipse(9, 6, 4, 4);
    popMatrix();
  }
}
