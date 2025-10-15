/**
 * Processing Sketch: Fireball Comet-like Particle System with Secondary Sparks
 *
 * This sketch simulates a primary comet particle system (low count for testing) 
 * tracing an infinity symbol path, with smaller, faster-decaying secondary sparks 
 * radiating from the lead particle.
 */

// === Global Parameters and Constants ===

// Canvas Settings
final int SKETCH_WIDTH = 480;  // Default: 480
final int SKETCH_HEIGHT = 800; // Default: 800
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
final boolean SHOW_PATH = false;     // Set to false (Path visibility parameter)
final int PATH_COLOR_INDEX = 1;      // Default: 1 (Vibrant Red for the path line)

// Primary Particle (Comet) Parameters
final int NUM_PARTICLES = 10;    // Default: 1000 -> Set to 10
final float MAX_FORCE = 0.9;     // Default: 0.9 (Maximum steering force)
final float MAX_SPEED = 6.0;     // Default: 6.0 (High speed)
final float INITIAL_SPEED = MAX_SPEED; // Set to MAX_SPEED for instant movement
final float PARTICLE_SIZE = 7.0; // Default: 3.0 -> Set to 7.0

// Secondary Particle (Spark) Parameters
final float SPARK_SIZE = 2.0;         // Default: 2.0 (New: Smaller size for sparks)
final int SPARK_COUNT_PER_FRAME = 3;  // Default: 3 (Number of sparks to generate per frame)
final float SPARK_MAX_VELOCITY = 4.0; // Default: 4.0 (Radial speed of sparks)
final float SPARK_FADE_RATE = 25.0;   // Default: 25.0 (Higher value = faster decay)

// Movement Weights
final float PATH_FOLLOW_WEIGHT = 5.0; // Default: 5.0 (Strong force for tight path following)
final float BOUNDS_WEIGHT = 10.0;     // Default: 10.0 (Strong force to keep particles inside padded area)

// Infinity Symbol (Lemniscate) Parameters
final float INFINITY_SIZE = 350; // Default: 350 (Radius of the lobes)
final float PATH_RADIUS = 1;     // Default: 1.0 (Very small radius for instant path snapping)
final float INITIAL_PATH_SPREAD = 0.01; // Default: 0.2 -> Set to 0.01 (Tighter initial shape)
// Calculated as 4 * PI / MAX_FRAMES (12.56637 / 900) for two loops in 900 frames
final float PATH_SPEED_FACTOR = 0.0139626; 
final int PATH_RESOLUTION = 100; // Default: 100 (Number of segments to draw the path)

// Initialization Seed
final long GLOBAL_SEED = 123456789; // Default: 123456789

// Internal Variables
ArrayList<Particle> particles;
ArrayList<Spark> sparks; // New list for secondary particles
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
  sparks = new ArrayList<Spark>(); // Initialize sparks list
  
  // Find the initial path target (t=0) to orient the initial velocity
  PVector initialTarget = getInfinitySymbolPoint(0);
  
  // Initialize particles along a segment of the path (instantiates the "comet" shape)
  for (int i = 0; i < NUM_PARTICLES; i++) {
    float theta = map(i, 0, NUM_PARTICLES, 0, INITIAL_PATH_SPREAD);
    PVector position = getInfinitySymbolPoint(theta);
    PVector targetAtTheta = getInfinitySymbolPoint(theta + PATH_SPEED_FACTOR); // Direction of the path
    
    particles.add(new Particle(position, targetAtTheta));
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
  
  if (t > TWO_PI * 2) {
    t -= TWO_PI * 2;
  }

  // Draw the current target point (Head of the comet path)
  fill(pathColor, 200); 
  noStroke();
  ellipse(target.x, target.y, 8, 8); 

  // --- Generate and Manage Sparks ---
  if (particles.size() > 0) {
    Particle leadParticle = particles.get(0); // Assume the first particle is the current "leader"
    
    for (int i = 0; i < SPARK_COUNT_PER_FRAME; i++) {
      sparks.add(new Spark(leadParticle.position.copy()));
    }
  }

  // Update and display all primary particles
  for (Particle p : particles) {
    p.update(target);
    p.display(p.particleColor);
  }

  // Update and display sparks, and remove dead ones
  for (int i = sparks.size() - 1; i >= 0; i--) {
    Spark s = sparks.get(i);
    s.update();
    s.display();
    if (s.isDead()) {
      sparks.remove(i);
    }
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

// === Primary Particle Class ===

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

    // Set initial velocity to match the direction of the path segment
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

// ---

// === Secondary Spark Class ===

class Spark {
  PVector position;
  PVector velocity;
  float r;
  float life; // Alpha value (0 to 255)
  int sparkColor;

  Spark(PVector pos) {
    position = pos.copy();
    r = SPARK_SIZE;
    life = 255; // Start fully visible

    // Set velocity radially outward with a random magnitude
    velocity = PVector.random2D();
    velocity.setMag(random(0.5, SPARK_MAX_VELOCITY)); 
    
    // Pick a bright color from the palette for the spark trail
    int colorIndex = (int)random(2, PALETTE.length); // Avoid dark red/black background color
    sparkColor = PALETTE[colorIndex];
    if (INVERT_BACKGROUND) {
        sparkColor = #FFFFFF - (sparkColor & #FFFFFF) | #FF000000;
    }
  }

  void update() {
    // Sparks are only subject to drag (no complex forces)
    position.add(velocity);
    
    // Gravity/slight downward pull (optional, can simulate light physics)
    // velocity.add(new PVector(0, 0.05)); 
    
    // Decay: Fade and shrink over time
    life -= SPARK_FADE_RATE; 
    r *= 0.98; // Shrink slightly
  }

  void display() {
    // Extract RGB from the base spark color and apply the current life (alpha)
    int displayColor = color(red(sparkColor), green(sparkColor), blue(sparkColor), life);
    
    fill(displayColor);
    noStroke();
    ellipse(position.x, position.y, r, r);
  }
  
  boolean isDead() {
    return life <= 0;
  }
}
