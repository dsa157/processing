/**
 * Processing Sketch: Two Fireball Comets tracing an Infinity Symbol Path
 *
 * This sketch simulates two independent particle systems (comets) tracing the 
 * infinity symbol path. An explosion of sparks is triggered when the two comet 
 * heads converge near the center.
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
final boolean SHOW_PATH = false;     // Default: false (Path visibility parameter)
final int PATH_COLOR_INDEX = 1;      // Default: 1 (Vibrant Red for the path line)

// Primary Particle (Comet) Parameters
final int NUM_PARTICLES = 1000;  // Default: 1000 (Total particles per comet)
final float MAX_FORCE = 0.9;     // Default: 0.9 (Maximum steering force)
final float MAX_SPEED = 6.0;     // Default: 6.0 (High speed)
final float INITIAL_SPEED = MAX_SPEED; // Set to MAX_SPEED for instant movement
final float PARTICLE_SIZE = 7.0; // Default: 7.0 
final float INITIAL_PATH_SPREAD = 0.01; // Default: 0.01 (Tighter initial shape)

// Secondary Particle (Regular Sparkler) Parameters
final float SPARK_SIZE = 2.0;         // Default: 2.0 (Smaller size for sparks)
final int SPARK_COUNT_PER_FRAME = 3;  // Default: 3 (Number of sparks to generate per frame, per comet)
final float SPARK_MAX_VELOCITY = 4.0; // Default: 4.0 (Radial speed of sparks)
final float SPARK_FADE_RATE = 25.0;   // Default: 25.0 (Decay rate for regular sparks)

// Explosion Parameters (New)
final float EXPLOSION_DISTANCE = 50.0;     // Default: 50.0 (Distance between comet heads to trigger the explosion)
final int EXPLOSION_COUNT = 100;           // Default: 100 (Total sparks in the blast)
final float EXPLOSION_MAX_VELOCITY = 15.0; // Default: 15.0 (High radial speed for blast sparks)
final float EXPLOSION_FADE_RATE = 50.0;    // Default: 50.0 (Very fast decay rate for explosion sparks)

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
ArrayList<Particle> particles1; 
ArrayList<Particle> particles2; 
ArrayList<Spark> sparks;       

float t1; 
float t2; 

int bgColor;
int pathColor; 
int fgColor; 

boolean hasExploded = false; // Flag to prevent explosion on every frame of convergence

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

  particles1 = new ArrayList<Particle>();
  particles2 = new ArrayList<Particle>();
  sparks = new ArrayList<Spark>();

  // Initialize path parameters to their starting clock positions
  t1 = HALF_PI;      // 12 o'clock position
  t2 = HALF_PI * 3; // 6 o'clock position
  
  // Initialize Comet 1 (12 o'clock, standard direction)
  initComet(particles1, t1, PATH_SPEED_FACTOR);

  // Initialize Comet 2 (6 o'clock, reverse direction)
  initComet(particles2, t2, -PATH_SPEED_FACTOR);
}

// Helper function to initialize a comet at a specific point
void initComet(ArrayList<Particle> particleList, float startT, float direction) {
  for (int i = 0; i < NUM_PARTICLES; i++) {
    // Distribute particles along a short segment of the path based on the starting angle (startT)
    // The spread is applied backward from the starting point for a leading head effect.
    float theta = map(i, 0, NUM_PARTICLES, startT - direction * INITIAL_PATH_SPREAD, startT);
    
    PVector position = getInfinitySymbolPoint(theta);
    PVector initialTarget = getInfinitySymbolPoint(theta + direction);
    
    particleList.add(new Particle(position, initialTarget));
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

// === Explosion Management ===

/**
 * Spawns a large burst of high-velocity, fast-fading sparks.
 */
void triggerExplosion(PVector center) {
  for (int i = 0; i < EXPLOSION_COUNT; i++) {
    sparks.add(new Spark(center.copy(), EXPLOSION_MAX_VELOCITY, EXPLOSION_FADE_RATE));
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

  // Calculate targets for the current frame
  PVector target1 = getInfinitySymbolPoint(t1);
  PVector target2 = getInfinitySymbolPoint(t2);

  // --- Convergence Detection and Explosion ---
  PVector headPos1 = particles1.get(0).position;
  PVector headPos2 = particles2.get(0).position;
  
  float distBetweenHeads = PVector.dist(headPos1, headPos2);
  
  if (distBetweenHeads < EXPLOSION_DISTANCE && !hasExploded) {
    // Trigger explosion at the midpoint
    PVector midpoint = PVector.add(headPos1, headPos2);
    midpoint.div(2);
    triggerExplosion(midpoint);
    hasExploded = true;
  } else if (distBetweenHeads > EXPLOSION_DISTANCE * 2) {
    // Reset the flag once the comets have passed and separated sufficiently
    hasExploded = false;
  }

  // --- Update Comet 1 ---
  t1 += PATH_SPEED_FACTOR;
  if (t1 > TWO_PI * 2) t1 -= TWO_PI * 2;
  
  for (Particle p : particles1) {
    p.update(target1);
    p.display(p.particleColor);
  }
  
  // --- Update Comet 2 ---
  t2 -= PATH_SPEED_FACTOR; 
  if (t2 < 0) t2 += TWO_PI * 2;
  
  for (Particle p : particles2) {
    p.update(target2);
    p.display(p.particleColor);
  }


  // --- Generate Regular Sparks (from both comet leaders) ---
  // Note: Only generate regular sparks if the explosion is not active/just happened, 
  // or the visualization will be too dense.
  if (!hasExploded) {
      if (particles1.size() > 0) {
        Particle leadParticle1 = particles1.get(0); 
        for (int i = 0; i < SPARK_COUNT_PER_FRAME; i++) {
          sparks.add(new Spark(leadParticle1.position.copy(), SPARK_MAX_VELOCITY, SPARK_FADE_RATE));
        }
      }
      if (particles2.size() > 0) {
        Particle leadParticle2 = particles2.get(0);
        for (int i = 0; i < SPARK_COUNT_PER_FRAME; i++) {
          sparks.add(new Spark(leadParticle2.position.copy(), SPARK_MAX_VELOCITY, SPARK_FADE_RATE));
        }
      }
  }


  // Update and display ALL sparks
  for (int i = sparks.size() - 1; i >= 0; i--) {
    Spark s = sparks.get(i);
    s.update();
    s.display();
    if (s.isDead()) {
      sparks.remove(i);
    }
  }

  // Draw the current target points (Heads of the comets)
  fill(pathColor, 200); 
  noStroke();
  ellipse(target1.x, target1.y, 8, 8); 
  ellipse(target2.x, target2.y, 8, 8); 

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

    PVector initialDir = PVector.sub(initialTarget, position);
    initialDir.normalize();
    velocity = initialDir.mult(MAX_SPEED); 

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
  float life; 
  int sparkColor;

  // Modified constructor to accept custom speed and fade rate
  Spark(PVector pos, float maxVel, float fadeRate) {
    position = pos.copy();
    r = SPARK_SIZE;
    life = 255; 

    // Set velocity radially outward with a random magnitude
    velocity = PVector.random2D();
    velocity.setMag(random(0.5, maxVel)); 
    
    // Pick a bright color from the palette
    int colorIndex = (int)random(2, PALETTE.length); 
    sparkColor = PALETTE[colorIndex];
    if (INVERT_BACKGROUND) {
        sparkColor = #FFFFFF - (sparkColor & #FFFFFF) | #FF000000;
    }
  }

  void update() {
    position.add(velocity);
    life -= SPARK_FADE_RATE; 
    r *= 0.98; 
  }

  void display() {
    int displayColor = color(red(sparkColor), green(sparkColor), blue(sparkColor), life);
    
    fill(displayColor);
    noStroke();
    ellipse(position.x, position.y, r, r);
  }
  
  boolean isDead() {
    return life <= 0;
  }
}
