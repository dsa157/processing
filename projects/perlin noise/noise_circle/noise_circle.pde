// Processing.org Flow Field Sketch (Annulus Constraint)

// === Configuration Parameters ===

// Canvas Setup
final int SKETCH_WIDTH = 480;
final int SKETCH_HEIGHT = 800;

// Layout
final int PADDING = 40; 
final boolean INVERT_COLORS = false; 

// Animation Control
final int MAX_FRAMES = 900; 
final int ANIMATION_SPEED = 30; 
final boolean SAVE_FRAMES = false; 

// Flow Field Parameters
final int PARTICLE_COUNT = 1500; 
final float PARTICLE_SPEED = 1.5; 
final float NOISE_SCALE = 0.003; 
final float TIME_INCREMENT = 0.005; 
final float FIELD_ANGLE_MULTIPLIER = 2.0; 

// Annulus Boundary
// CIRCLE_RADIUS is the CENTER reference of the ring
final float CIRCLE_RADIUS = (SKETCH_WIDTH - 2 * PADDING) / 2.0; 
final float ANNULUS_BOUNDARY_PADDING = 60.0; 

// Grid/Visualization
final boolean SHOW_GRID = false; 

// Color Palette
final int[] PALETTE = {
  #011936, // Deep Blue/BG
  #043565, // Medium Blue
  #79ADDC, // Light Blue
  #A2D8FF, // Very Light Blue
  #456990  // Muted Slate
};
final int BACKGROUND_COLOR_INDEX = 0; 

// Global Seed for Reproducible Randomness
final int GLOBAL_SEED = 12345;

// === Global Variables ===
Particle[] particles;
float centerX, centerY;
int backgroundColor;

// Annulus Calculation Variables
float innerRadius;
float outerRadius;
float innerRadiusSq;
float outerRadiusSq;

// ====================================================================

// === Setup Functions ===

void setup() {
  size(480, 800);
  randomSeed(GLOBAL_SEED);
  noiseSeed(GLOBAL_SEED);
  frameRate(ANIMATION_SPEED);

  // Initialize center coordinates
  centerX = width / 2.0;
  centerY = height / 2.0;

  backgroundColor = PALETTE[BACKGROUND_COLOR_INDEX];
  if (INVERT_COLORS) {
    backgroundColor = 0xFFFFFF - (backgroundColor & 0xFFFFFF);
  }
  
  // Calculate Annulus Boundaries
  innerRadius = max(0, CIRCLE_RADIUS - ANNULUS_BOUNDARY_PADDING);
  outerRadius = CIRCLE_RADIUS + ANNULUS_BOUNDARY_PADDING;
  innerRadiusSq = innerRadius * innerRadius;
  outerRadiusSq = outerRadius * outerRadius;

  // Initialize Particles 
  particles = new Particle[PARTICLE_COUNT];
  for (int i = 0; i < PARTICLE_COUNT; i++) {
    particles[i] = new Particle(centerX, centerY, innerRadiusSq, outerRadiusSq);
  }

  background(backgroundColor);
  smooth();
}

// ====================================================================

// === Main Draw Loop ===

void draw() {
  // Semi-transparent background for a fading trail effect
  fill(backgroundColor, 50); 
  noStroke();
  rect(0, 0, width, height);

  // Update and display particles
  for (Particle p : particles) {
    p.update();
    p.display();
  }

  // Optional: Display the boundary circles (inner and outer)
  if (SHOW_GRID) {
    noFill();
    stroke(INVERT_COLORS ? 0 : 255, 100); 
    
    ellipse(centerX, centerY, outerRadius * 2, outerRadius * 2);
    ellipse(centerX, centerY, innerRadius * 2, innerRadius * 2);
  }

  // === Frame Saving and Looping Control ===
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  } else if (frameCount >= MAX_FRAMES) {
    noLoop();
  }
}

// ====================================================================

// === Particle Class (All constants are visible in this single file) ===

class Particle {
  PVector pos;
  PVector vel;
  PVector acc;
  float rInnerSq, rOuterSq;
  int particleColor;

  Particle(float cx, float cy, float rInSq, float rOutSq) {
    rInnerSq = rInSq;
    rOuterSq = rOutSq;
    
    // 💥 FIX: Initialize ALL PVector objects immediately to prevent NullPointerException
    pos = new PVector(0, 0); 
    vel = new PVector(0, 0);
    acc = new PVector(0, 0);
    
    // Color setup
    int colorIndex = (int) random(1, PALETTE.length);
    particleColor = PALETTE[colorIndex];
    if (INVERT_COLORS) {
      particleColor = 0xFFFFFF - (particleColor & 0xFFFFFF);
    }
    
    // Initial position reset
    resetPosition(new PVector(cx, cy));
  }

  void update() {
    // Flow Field Mapping
    float x_offset = pos.x * NOISE_SCALE;
    float y_offset = pos.y * NOISE_SCALE;
    float t_offset = frameCount * TIME_INCREMENT;

    float noiseValue = noise(x_offset, y_offset, t_offset);
    float angle = map(noiseValue, 0, 1, 0, TWO_PI * FIELD_ANGLE_MULTIPLIER);
    PVector force = PVector.fromAngle(angle);
    force.mult(PARTICLE_SPEED); 

    // Apply force and update position
    acc.add(force);
    acc.limit(PARTICLE_SPEED);
    vel.add(acc);
    vel.limit(PARTICLE_SPEED);
    pos.add(vel);
    acc.mult(0);

    // Boundary Check
    PVector center = new PVector(centerX, centerY);
    
    // 💥 FIX: Correctly calculates squared distance using PVector.magSq()
    PVector displacement = PVector.sub(pos, center); 
    float distSq = displacement.magSq(); 
    
    if (distSq < rInnerSq || distSq > rOuterSq) {
      resetPosition(center);
    }
  }
  
  void resetPosition(PVector center) {
    // Reset to a random position within the annulus
    float angle = random(TWO_PI);
    float dist = sqrt(random(rInnerSq, rOuterSq));
    
    pos.set(center.x + cos(angle) * dist, center.y + sin(angle) * dist);
    vel.mult(0); 
  }

  void display() {
    stroke(particleColor, 150);
    strokeWeight(1.5);
    point(pos.x, pos.y);
  }
}
