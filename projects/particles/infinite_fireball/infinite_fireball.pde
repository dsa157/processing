/**
 * Processing Sketch: Fireball Comet-like Particle System following an Infinity Symbol Path
 *
 * This sketch simulates a dense clump of non-flocking particles tracing a vertical 
 * infinity symbol (lemniscate) path, creating a dense, long-tailed fireball effect.
 */

// === Global Parameters and Constants ===

// Canvas Settings
final int SKETCH_WIDTH = 480;  // Default: 480 (Your specified default)
final int SKETCH_HEIGHT = 800; // Default: 800 (Your specified default)
final int PADDING = 40;        // Default: 40

// Animation and Save Settings
final int MAX_FRAMES = 900;       // Default: 900
final boolean SAVE_FRAMES = false; // Default: false
final int ANIMATION_SPEED = 30;    // Default: 30 (frames per second)

// Color Palette (Warm Fireball Palette: Red, Orange, Yellow)
final int[] PALETTE = {
  #0D0000, // 0: Deep Black-Red (BG default - acts as a heat sink)
  #FF0000, // 1: Vibrant Red
  #FF6A00, // 2: Bright Orange
  #FFD400, // 3: Gold Yellow
  #FFFFCC  // 4: Pale Yellow/White (for highlights)
};
final int BACKGROUND_COLOR_INDEX = 0; // Index in PALETTE for the background
final boolean INVERT_BACKGROUND = false; // Default: false (true inverts the colors)

// Path Visualization Parameters
final boolean SHOW_PATH = false;      // Default: false (Path visibility parameter)
final int PATH_COLOR_INDEX = 1;      // Default: 1 (Vibrant Red for the path line)

// Particle System Parameters
final int NUM_PARTICLES = 10;  // Default: 1000
final float MAX_FORCE = 0.9;    // Default: 0.9 (Maximum steering force)
final float MAX_SPEED = 6.0;    // Default: 6.0 (High speed)
final float PARTICLE_SIZE = 7.0; // Default: 3.0 
final float INITIAL_PATH_SPREAD = 0.01; // New: Angle (radians) along the path to distribute particles (0.2 radians is a short trail segment)

// Movement Weights
final float PATH_FOLLOW_WEIGHT = 5.0; // Default: 5.0 (Strong force for tight path following)
final float BOUNDS_WEIGHT = 10.0;     // Default: 10.0 (Strong force to keep particles inside padded area)

// Infinity Symbol (Lemniscate) Parameters
final float INFINITY_SIZE = 350; // Default: 350 (Radius of the lobes)
final float PATH_RADIUS = 1;     // Default: 1.0 (Very small radius for instant path snapping)
// Calculated as 4 * PI / MAX_FRAMES (12.56637 / 900) for two loops in 900 frames
final float PATH_SPEED_FACTOR = 0.0139626; 
final int PATH_RESOLUTION = 100; // Default: 100 (Number of segments to draw the path)

// Initialization Seed
final long GLOBAL_SEED = 123456789; // Default: 123456789

// Internal Variables
ArrayList<Particle> particles;
float t = 0;
int bgColor;
int pathColor; 
int fgColor; 

// ---

// === Processing Setup and Configuration ===

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(GLOBAL_SEED);
  frameRate(ANIMATION_SPEED);

  setColors();
  background(bgColor);

  particles = new ArrayList<Particle>();
  
  // Initialize particles along a segment of the path (instantiates the "comet" shape)
  for (int i = 0; i < NUM_PARTICLES; i++) {
    // Distribute particles linearly along the path parameter 'theta' from 0 up to INITIAL_PATH_SPREAD
    float theta = map(i, 0, NUM_PARTICLES, 0, INITIAL_PATH_SPREAD);
    
    // Get the position on the path
    PVector position = getInfinitySymbolPoint(theta);
    
    // Get the instantaneous direction of the path at that point
    PVector initialTarget = getInfinitySymbolPoint(theta + PATH_SPEED_FACTOR);
    
    particles.add(new Particle(position, initialTarget));
  }
}

// Function to set background and foreground colors based on parameters
void setColors() {
  bgColor = PALETTE[BACKGROUND_COLOR_INDEX];
  pathColor = PALETTE[PATH_COLOR_INDEX];
  fgColor = PALETTE[1]; 

  if (INVERT_BACKGROUND) {
    bgColor = #FFFFFF - (bgColor & #FFFFFF) | #FF000000;
    pathColor = #FFFFFF - (pathColor & #FFFFFF) | #FF000000;
    fgColor = #FFFFFF - (fgColor & #FFFFFF) | #FF000000;
  }
}

// ---

// === Draw Loop ===

void draw() {
  // Soft transition effect (comet trail)
  fill(bgColor, 10); 
  noStroke();
  rect(0, 0, width, height);

  // --- Draw the Infinity Symbol Path ---
  if (SHOW_PATH) {
    stroke(pathColor, 100); 
    strokeWeight(1);
    noFill();
    beginShape();
    for (int i = 0; i < PATH_RESOLUTION; i++) {
      float angle = map(i, 0, PATH_RESOLUTION, 0, TWO_PI);
      PVector pathPoint = getInfinitySymbolPoint(angle);
      vertex(pathPoint.x, pathPoint.y);
    }
    endShape(CLOSE);
  }

  // Calculate the target point on the vertical infinity symbol
  PVector target = getInfinitySymbolPoint(t);
  t += PATH_SPEED_FACTOR;
  
  // Ensure the path parameter loops precisely for a seamless animation (two loops in MAX_FRAMES)
  if (t > TWO_PI * 2) {
    t -= TWO_PI * 2;
  }

  // Draw the current target point (Head of the comet path)
  fill(pathColor, 200); 
  noStroke();
  ellipse(target.x, target.y, 8, 8); 

  // Update and display all particles
  for (Particle p : particles) {
    p.update(target);
    p.display(p.particleColor);
  }

  // --- Save Frame Logic (Conditional) ---
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    
    if (frameCount >= MAX_FRAMES) {
      noLoop();
      println("Maximum frames reached. Sketch stopped.");
    }
  }
}

// ---

// === Path Functions ===

/**
 * Calculates a point on a vertical infinity symbol (lemniscate of Bernoulli).
 */
PVector getInfinitySymbolPoint(float theta) {
  float centerX = (float)width / 2;
  float centerY = (float)height / 2;

  float cosTheta = cos(theta);
  float sinTheta = sin(theta);
  float denominator = 1 + cosTheta * cosTheta;

  float xRaw = INFINITY_SIZE * sinTheta * cosTheta / denominator;
  float yRaw = INFINITY_SIZE * sinTheta / denominator;

  return new PVector(centerX + xRaw, centerY + yRaw);
}

// ---

// === Particle Class ===

class Particle {
  PVector position;
  PVector velocity;
  PVector acceleration;
  float r;
  int particleColor;
  
  Particle(PVector pos, PVector initialTarget) {
    position = pos.copy();
    acceleration = new PVector(0, 0);
    r = PARTICLE_SIZE;

    // Set initial velocity to match the direction of the path segment, 
    // ensuring the particle is already moving along the curve.
    PVector initialDir = PVector.sub(initialTarget, position);
    initialDir.normalize();
    velocity = initialDir.mult(MAX_SPEED); 

    // Assign random color
    int colorIndex = (int)random(1, PALETTE.length);
    particleColor = PALETTE[colorIndex];
    if (INVERT_BACKGROUND) {
        particleColor = #FFFFFF - (particleColor & #FFFFFF) | #FF000000;
    }
  }

  void update(PVector target) {
    PVector fol = followPath(target);
    PVector bounds = stayInBounds();

    fol.mult(PATH_FOLLOW_WEIGHT);
    bounds.mult(BOUNDS_WEIGHT);

    applyForce(fol);
    applyForce(bounds);

    velocity.add(acceleration);
    velocity.limit(MAX_SPEED);
    position.add(velocity);
    acceleration.mult(0);
  }

  void applyForce(PVector force) {
    force.limit(MAX_FORCE);
    acceleration.add(force);
  }

  PVector stayInBounds() {
    PVector targetDir = new PVector(0, 0);
    boolean outside = false;
    
    if (position.x < PADDING) {
      targetDir = new PVector(MAX_SPEED, velocity.y);
      outside = true;
    } else if (position.x > width - PADDING) {
      targetDir = new PVector(-MAX_SPEED, velocity.y);
      outside = true;
    }
    
    if (position.y < PADDING) {
      targetDir = new PVector(velocity.x, MAX_SPEED);
      outside = true;
    } else if (position.y > height - PADDING) {
      targetDir = new PVector(velocity.x, -MAX_SPEED);
      outside = true;
    }

    if (outside) {
      return steerForce(targetDir);
    }
    return new PVector(0, 0);
  }

  PVector followPath(PVector target) {
    float distToPath = PVector.dist(position, target);
    if (distToPath > PATH_RADIUS) {
      return seek(target);
    } else {
      return new PVector(0, 0);
    }
  }

  PVector seek(PVector target) {
    PVector desired = PVector.sub(target, position);
    return steerForce(desired);
  }

  PVector steerForce(PVector desired) {
    desired.normalize();
    desired.mult(MAX_SPEED);
    PVector steer = PVector.sub(desired, velocity);
    steer.limit(MAX_FORCE);
    return steer;
  }

  void display(int particleColor) {
    fill(particleColor);
    noStroke();
    ellipse(position.x, position.y, r, r);
  }
}
