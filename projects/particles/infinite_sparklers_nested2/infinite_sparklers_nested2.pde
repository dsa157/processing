/**
 * Processing Sketch: Two Fireball Comets tracing an Infinity Symbol Path
 *
 * This sketch uses a Comet class to manage two separate particle systems: 
 * a Warm (Red/Orange) comet and a Cool (Blue/Cyan) comet. They trace the 
 * vertical infinity symbol path at the same speed (4 loops per MAX_FRAMES) 
 * and trigger an explosion when their heads pass through the center.
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

// Color Palette 1 (Warm Fireball Palette: Red, Orange, Yellow) - Used for Comet 1
final int[] PALETTE_WARM = {
  #0D0000, // 0: Deep Black-Red (BG default - acts as a heat sink)
  #FF0000, // 1: Vibrant Red (Path/Head color)
  #FF6A00, // 2: Bright Orange
  #FFD400, // 3: Gold Yellow
  #FFFFCC  // 4: Pale Yellow/White (for highlights)
};
// Color Palette 2 (Cool Fireball Palette: Blue, Cyan, Green) - Used for Comet 2
final int[] PALETTE_COOL = {
  #0D0000, // 0: Deep Black-Red (UNUSED, kept for index consistency)
  #00A0FF, // 1: Bright Blue (Path/Head color)
  #00B0FF, // 2: Cyan
  #00AA8C, // 3: Mint Green
  #CCFFFF  // 4: Pale Cyan/White
};
final int BACKGROUND_COLOR_INDEX = 0; // Index in PALETTE_WARM for the background
final boolean INVERT_BACKGROUND = false; // Default: false (true inverts the colors)

// Path Visualization Parameters
final boolean SHOW_PATH = false;     // Default: false (Visibility parameter for the path line)
final int PATH_COLOR_INDEX = 1;      // Default: 1 (Color index for path line/targets)
final boolean SHOW_TARGETS = true;   // Default: true (Visibility parameter for target markers)
final float TARGET_SIZE = 15.0;       // Default: 8.0 (Size parameter for target markers)

// Particle System Parameters
final int NUM_PARTICLES = 10;    // Default: 10 (Total particles per comet)
final float MAX_FORCE = 0.9;   // Default: 100.0 (High steering force)
final float MAX_SPEED = 6.0;     // Default: 6.0 (High speed)
final float INITIAL_SPEED = MAX_SPEED; // Set to MAX_SPEED for instant movement
final float PARTICLE_SIZE = 10.0; // Default: 20.0 (Base size for main particles)

// Secondary Particle (Sparkler) Parameters
final float SPARK_SIZE = 4.0;         // Default: 20.0 (Independent spark size)
final int SPARK_COUNT_PER_FRAME = 3;  // Default: 3 (Number of sparks to generate per frame, per comet)
final float SPARK_MAX_VELOCITY = 4.0; // Default: 4.0 (Radial speed of sparks)
final float SPARK_FADE_RATE = 25.0;   // Default: 25.0 (Decay rate for regular sparks)

// Explosion Parameters
final float CENTER_TRIGGER_DISTANCE = 30.0; // Default: 30.0 (Distance from center to trigger INNER explosion)
final int EXPLOSION_COUNT = 100;           // Default: 100 (Total sparks in the blast)
final float EXPLOSION_MAX_VELOCITY = 15.0; // Default: 15.0 (High radial speed for blast sparks)
final float EXPLOSION_FADE_RATE = 20.0;    // Default: 50.0 (Very fast decay rate for explosion sparks)
final float OUTER_TRIGGER_THRESHOLD = 0.05; // Angular distance from PI or 0 to trigger OUTER explosion

// Movement Weights
final float PATH_FOLLOW_WEIGHT = 5.0; // Default: 5.0 (Strong force for tight path following)
final float BOUNDS_WEIGHT = 10.0;     // Default: 10.0 (Strong force to keep particles inside padded area)

// Infinity Symbol (Lemniscate) Parameters
final float INFINITY_SIZE = 350; // Default: 350 (Radius of the lobes)
final float PATH_RADIUS = 1;     // Default: 1.0 (Very small radius for instant path snapping)
final float INITIAL_PATH_SPREAD = 0.01; // Default: 0.01 (Tighter initial shape)

final int PATH_LOOPS_PER_MAX_FRAMES = 4; // Default: 4 
final float PATH_SPEED_FACTOR = (float)(PATH_LOOPS_PER_MAX_FRAMES * TWO_PI) / MAX_FRAMES; 

final int PATH_RESOLUTION = 100; // Default: 100 (Number of segments to draw the path)

// Initialization Seed
final long GLOBAL_SEED = 123456789; // Default: 123456789

// Internal Variables
ArrayList<Comet> comets; 
ArrayList<Spark> sparks;       

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

  comets = new ArrayList<Comet>();
  sparks = new ArrayList<Spark>();

  // Comet 1: Warm, 12 o'clock (HALF_PI), clockwise
  comets.add(new Comet(HALF_PI, PATH_SPEED_FACTOR, PALETTE_WARM, INITIAL_PATH_SPREAD));
  
  // Comet 2: Cool, 6 o'clock (HALF_PI * 3), counter-clockwise
  comets.add(new Comet(HALF_PI * 3, -PATH_SPEED_FACTOR, PALETTE_COOL, INITIAL_PATH_SPREAD));
}

// Function to set background and foreground colors based on parameters
void setColors() {
  bgColor = PALETTE_WARM[BACKGROUND_COLOR_INDEX]; 
  pathColor = PALETTE_WARM[PATH_COLOR_INDEX]; 
  fgColor = PALETTE_WARM[1]; 

  if (INVERT_BACKGROUND) {
    bgColor = #FFFFFF - (bgColor & #FFFFFF) | #FF000000;
    pathColor = #FFFFFF - (pathColor & #FFFFFF) | #FF000000;
    fgColor = #FFFFFF - (fgColor & #FFFFFF) | #FF000000;
  }
}

// ---

// === Explosion Management ===

/**
 * Spawns a large burst of high-velocity, fast-fading sparks at the center of the canvas.
 */
void triggerExplosion() {
  PVector center = new PVector(width / 2, height / 2);
  for (int i = 0; i < EXPLOSION_COUNT; i++) {
    sparks.add(new Spark(center.copy(), EXPLOSION_MAX_VELOCITY, EXPLOSION_FADE_RATE, PALETTE_WARM, SPARK_SIZE)); 
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

  // --- Update Comets ---
  for (Comet comet : comets) {
    comet.update();
    comet.display();
    
    // Check for explosion trigger
    if (comet.checkExplosion()) {
        triggerExplosion();
    }
    
    // Generate regular sparks
    if (!comet.hasExploded) {
      Particle lead = comet.getLeadParticle();
      if (lead != null) {
        for (int i = 0; i < SPARK_COUNT_PER_FRAME; i++) {
          sparks.add(new Spark(lead.position.copy(), SPARK_MAX_VELOCITY, SPARK_FADE_RATE, comet.palette, SPARK_SIZE));
        }
      }
    }
    
    // Draw comet target point (Marker at the head of the path)
    if (SHOW_TARGETS) {
      PVector target = comet.getTarget();
      fill(comet.palette[PATH_COLOR_INDEX], 255); // Solid marker color
      noStroke();
      ellipse(target.x, target.y, TARGET_SIZE, TARGET_SIZE); 
    }
  }

  // --- Update and display ALL sparks ---
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

// === Comet Class (Encapsulates particles, state, and path movement) ===

class Comet {
    ArrayList<Particle> particles;
    float t; // Path parameter
    float direction; // PATH_SPEED_FACTOR or -PATH_SPEED_FACTOR
    int[] palette; // Assigned color palette
    float spread; // Local storage for initial path spread (from global param)
    boolean hasExploded = false; // Explosion state tracked here
    
    // Comet constructor
    Comet(float startT, float dir, int[] p, float initialSpread) {
        t = startT;
        direction = dir;
        palette = p;
        spread = initialSpread; // Store the initial spread value
        particles = new ArrayList<Particle>();
        
        // Initialization logic correctly uses the local 'spread' variable
        for (int i = 0; i < NUM_PARTICLES; i++) {
            float theta = map(i, 0, NUM_PARTICLES, startT - direction * spread, startT);
            
            PVector position = getInfinitySymbolPoint(theta);
            PVector initialTarget = getInfinitySymbolPoint(theta + direction);
            
            particles.add(new Particle(position, initialTarget, palette));
        }
    }
    
    PVector getTarget() {
        return getInfinitySymbolPoint(t);
    }
    
    PVector getLeadPosition() {
        if (particles.isEmpty()) return new PVector(0, 0); 
        return particles.get(0).position;
    }
    
    Particle getLeadParticle() {
         if (particles.isEmpty()) return null;
        return particles.get(0);
    }
    
    void update() {
        PVector target = getTarget();
        
        // Update path parameter
        t += direction;
        float pathMax = PATH_LOOPS_PER_MAX_FRAMES * TWO_PI;
        
        // Wrap t
        if (t > pathMax) t -= pathMax;
        if (t < 0) t += pathMax;
        
        // Update all particles
        for (Particle p : particles) {
            p.update(target);
        }
    }
    
    void display() {
        for (Particle p : particles) {
            p.display(p.particleColor);
        }
    }

    boolean checkExplosion() {
        if (particles.isEmpty()) return false;
        
        PVector center = new PVector(width / 2, height / 2);
        PVector leadPos = getLeadPosition();
        
        // --- 1. Inner (Central) Explosion Trigger ---
        if (PVector.dist(leadPos, center) < CENTER_TRIGGER_DISTANCE) {
            if (!hasExploded) {
                hasExploded = true;
                return true; // Signal explosion trigger
            }
        } 
        
        // --- 2. Outer Lobe Explosion Trigger ---
        float normalizedT = t % TWO_PI;
        if (normalizedT < 0) normalizedT += TWO_PI;

        // Check proximity to 0/2*PI (top/bottom horizontal extreme) OR PI (middle horizontal extreme)
        boolean nearOuterTrigger = 
            (normalizedT < OUTER_TRIGGER_THRESHOLD) || 
            (normalizedT > TWO_PI - OUTER_TRIGGER_THRESHOLD) || 
            (abs(normalizedT - PI) < OUTER_TRIGGER_THRESHOLD); 

        if (nearOuterTrigger) {
            if (!hasExploded) {
                hasExploded = true;
                return true;
            }
        }
        
        // Reset Logic: If the comet has moved significantly away from BOTH the center 
        // and the outer trigger zones, reset the flag.
        float distFromCenter = PVector.dist(leadPos, center);
        
        if (distFromCenter > CENTER_TRIGGER_DISTANCE * 2 && !nearOuterTrigger) {
             hasExploded = false;
        }
        
        return false;
    }
}

// ---

// === Primary Particle Class ===

class Particle {
  PVector position;
  PVector velocity;
  PVector acceleration;
  float r;
  int particleColor;
  
  Particle(PVector pos, PVector initialTarget, int[] palette) {
    position = pos.copy();
    acceleration = new PVector(0, 0);
    r = PARTICLE_SIZE; // Uses PARTICLE_SIZE

    PVector initialDir = PVector.sub(initialTarget, position);
    initialDir.normalize();
    velocity = initialDir.mult(MAX_SPEED); 

    int colorIndex = (int)random(1, palette.length);
    particleColor = palette[colorIndex];
    if (INVERT_BACKGROUND) {
        int colorIndexInv = (palette[colorIndex] & 0xFFFFFF) ^ 0xFFFFFF; // Simplified invert logic
        particleColor = colorIndexInv | 0xFF000000;
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
  float decayRate; // New instance variable to fix scope error

  Spark(PVector pos, float maxVel, float fadeRate, int[] palette, float rSize) {
    position = pos.copy();
    r = rSize; // Correctly uses the passed size parameter
    life = 255; 
    decayRate = fadeRate; // Store the fade rate

    velocity = PVector.random2D();
    velocity.setMag(random(0.5, maxVel)); 
    
    int colorIndex = (int)random(2, palette.length); 
    sparkColor = palette[colorIndex];
    if (INVERT_BACKGROUND) {
        int colorValue = (palette[colorIndex] & 0xFFFFFF) ^ 0xFFFFFF;
        sparkColor = colorValue | 0xFF000000;
    }
  }

  void update() {
    position.add(velocity);
    life -= decayRate; // Correctly uses the instance variable
    r *= 0.999; 
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
