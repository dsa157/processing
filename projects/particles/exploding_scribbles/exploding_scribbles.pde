// Scribble and Scratch Animation with Explosions

// === Parameters ===

// Canvas Settings
final int SKETCH_WIDTH = 480;
final int SKETCH_HEIGHT = 800;

// Animation Control
final int ANIMATION_SPEED = 30; // 30 frames per second
final int MAX_FRAMES = 900; // 900 frames (30 seconds at 30fps)
final boolean SAVE_FRAMES = false; // set to true to save frames

// Design Parameters
final int PADDING = 40; // 40 pixels padding around the sketch area
final boolean INVERT_COLORS = false; // false for light background, true for dark
final int RANDOM_SEED = 12345; // Seed for random()
final boolean SHOW_GRID = false; // Unused in this sketch, but kept for compliance

// Color Palette (Adobe Kuler: "The Dark Wood")
// Black, Dark Brown, Medium Brown, Light Brown, Cream/Tan
final int[] PALETTE = {
  #000000, // Black
  #3A1F1F, // Dark Reddish Brown
  #6B3838, // Medium Reddish Brown
  #A25757, // Light Reddish Brown
  #DDD4C0  // Cream / Tan
};

final int BG_COLOR_INDEX = 4; // 4 -> Cream/Tan
final int FG_COLOR_INDEX = 0; // 0 -> Black

// Scribble Parameters
final int MAX_SCRIBBLES = 700; // 500 scribble objects
final float SCRIBBLING_FORCE = 3.5; // Max random step size for a scribble point
final float MIN_STROKE = 0.5; // Minimum stroke thickness
final float MAX_STROKE = 6.0; // Maximum stroke thickness
final float HARDNESS_MIN = 0.1; // Minimum opacity (0.0 to 1.0)
final float HARDNESS_MAX = 0.7; // Maximum opacity (0.0 to 1.0)
final int SCRIBBLE_LENGTH = 150; // Max number of points per scribble

// Collision Parameters
final float COLLISION_DISTANCE = 5.0; // Max distance for two points to trigger an explosion
final float EXPLOSION_CHANCE = 0.01; // 0.1 (10%) chance an explosion occurs on collision (parameterized)

// Persistence/Decay Parameter (controls how fast the old lines fade)
final int PERSISTENCE_ALPHA = 30; // Increased from 15 for a quicker fade

// Explosion Parameters
final int MAX_EXPLOSION_PARTICLES = 50; // Number of particles in an explosion
final float EXPLOSION_LIFETIME = 45; // Frames the explosion lasts (1.5 seconds at 30fps)
final float EXPLOSION_FORCE = 4.0; // Max initial speed of particles
final float PARTICLE_SIZE_MIN = 1.0; // 2.0 -> 1.0 (smaller explosion)
final float PARTICLE_SIZE_MAX = 3.0; // 5.0 -> 3.0 (smaller explosion)

// === Global Variables ===

Scribble[] scribbles;
ArrayList<Explosion> explosions; // Array list to manage active explosions
int bgColor;
int fgColor;
PGraphics pg; // Off-screen buffer for persistent drawing

// === Setup ===

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(RANDOM_SEED);
  frameRate(ANIMATION_SPEED);

  // Set colors based on INVERT_COLORS
  if (INVERT_COLORS) {
    bgColor = 0; // Black
    fgColor = PALETTE[FG_COLOR_INDEX]; // Foreground is the chosen palette color
  } else {
    bgColor = PALETTE[BG_COLOR_INDEX]; // Background is the chosen palette color
    fgColor = PALETTE[FG_COLOR_INDEX]; // Foreground is the chosen palette color
  }

  // Initialize PGraphics buffer
  pg = createGraphics(width, height);
  pg.beginDraw();
  pg.background(bgColor);
  pg.endDraw();
  
  // Initialize Scribbles
  scribbles = new Scribble[MAX_SCRIBBLES];
  for (int i = 0; i < MAX_SCRIBBLES; i++) {
    float startX = random(PADDING, width - PADDING);
    float startY = random(PADDING, height - PADDING);
    scribbles[i] = new Scribble(i, startX, startY); // Pass index for collision check
  }
  
  // Initialize Explosions list
  explosions = new ArrayList<Explosion>();
}

// === Draw Loop ===

void draw() {
  
  // --- Collision and Update Phase ---
  
  // Check for collisions and update all scribbles
  for (int i = 0; i < scribbles.length; i++) {
    PVector collisionPoint = scribbles[i].update();
    
    // Check if the scribble triggered a collision AND if we hit the random chance
    if (collisionPoint != null) {
      if (random(1.0) < EXPLOSION_CHANCE) {
        // Create a new explosion at the collision point
        Explosion newExplosion = new Explosion(collisionPoint.x, collisionPoint.y);
        explosions.add(newExplosion);
      }
    }
  }
  
  // --- Drawing Phase ---
  
  // 1. Apply Decay to the Off-Screen Buffer (pg)
  pg.beginDraw();
  
  // Draw a semi-transparent rectangle over the entire buffer to create a fade/decay effect
  pg.noStroke();
  int decayColor = pg.color(pg.red(bgColor), pg.green(bgColor), pg.blue(bgColor), PERSISTENCE_ALPHA);
  pg.fill(decayColor);
  pg.rect(0, 0, width, height);

  // 2. Center the drawing on the buffer
  pg.pushMatrix();
  pg.translate(width/2, height/2);
  
  // 3. Draw new scribble segments to the buffer
  for (Scribble s : scribbles) {
    s.display(pg); // Pass the PGraphics object to the display method
  }
  
  // 4. Update and Draw Explosions
  for (int i = explosions.size() - 1; i >= 0; i--) {
    Explosion e = explosions.get(i);
    e.update();
    e.display(pg);
    if (e.isDead()) {
      explosions.remove(i);
    }
  }

  pg.popMatrix();
  pg.endDraw();
  
  // 5. Draw the persistent buffer to the main canvas
  image(pg, 0, 0);

  // === Frame Saving Logic ===
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  } else if (frameCount >= MAX_FRAMES) {
    noLoop();
  }
}

// ---

// === Scribble Class ===

class Scribble {
  int id; // Unique ID to prevent self-collision
  PVector[] points;
  int currentLength;
  int scribbleColor; 
  
  float nextStrokeWeight;
  int nextStrokeCap;
  int nextAlpha; 

  Scribble(int _id, float startX, float startY) {
    id = _id;
    // Convert startX/startY from screen coordinates to center-relative coordinates
    float centerX = width / 2;
    float centerY = height / 2;
    PVector currentPos = new PVector(startX - centerX, startY - centerY);
    
    points = new PVector[SCRIBBLE_LENGTH];
    currentLength = 0;
    scribbleColor = fgColor; 
    
    points[0] = currentPos.copy();
    currentLength = 1;
    
    randomizeSegmentProps();
  }

  void randomizeSegmentProps() {
    nextStrokeWeight = random(MIN_STROKE, MAX_STROKE);
    
    float sharp = random(1);
    if (sharp < 0.33) {
      nextStrokeCap = ROUND; 
    } else if (sharp < 0.66) {
      nextStrokeCap = SQUARE; 
    } else {
      nextStrokeCap = PROJECT; 
    }
    
    nextAlpha = (int) map(random(HARDNESS_MIN, HARDNESS_MAX), 0, 1, 0, 255);
  }

  // Returns the collision PVector if a collision is detected, otherwise null.
  PVector update() {
    PVector collisionPos = null;
    
    // The boundaries for the constrained movement are calculated based on PADDING
    float halfW = (width - PADDING * 2) / 2.0;
    float halfH = (height - PADDING * 2) / 2.0;
    
    // Get the last known position
    PVector prevPos = points[currentLength - 1];
    
    // Calculate next position with a random perturbation
    float dx = random(-SCRIBBLING_FORCE, SCRIBBLING_FORCE);
    float dy = random(-SCRIBBLING_FORCE, SCRIBBLING_FORCE);
    PVector nextPos = new PVector(prevPos.x + dx, prevPos.y + dy);
    
    // Constrain the new position within the padded, center-relative bounds
    nextPos.x = constrain(nextPos.x, -halfW, halfW);
    nextPos.y = constrain(nextPos.y, -halfH, halfH);

    // --- Collision Check ---
    // Only check the newest point against all others for efficiency
    for (Scribble other : scribbles) {
      if (other.id != this.id && other.currentLength > 0) {
        PVector otherPos = other.points[other.currentLength - 1]; // Only check the newest point of the other scribble
        if (nextPos.dist(otherPos) < COLLISION_DISTANCE) {
          // Collision detected! Store the position.
          collisionPos = nextPos.copy(); 
          // Stop this scribble's movement for one frame to accentuate the collision
          nextPos = prevPos.copy(); 
          break;
        }
      }
    }
    // --- End Collision Check ---

    if (currentLength < SCRIBBLE_LENGTH) {
      points[currentLength] = nextPos;
      currentLength++;
    } else {
      for (int i = 0; i < SCRIBBLE_LENGTH - 1; i++) {
        points[i] = points[i+1];
      }
      points[SCRIBBLE_LENGTH - 1] = nextPos;
    }
    
    return collisionPos; // Return collision point or null
  }

  void display(PGraphics buffer) {
    buffer.noFill();
    
    for (int i = max(0, currentLength - 6); i < currentLength - 1; i++) {
      
      if (i % 2 == 0) {
        randomizeSegmentProps();
      }
      
      int c = buffer.color(buffer.red(scribbleColor), buffer.green(scribbleColor), buffer.blue(scribbleColor), nextAlpha);
      buffer.stroke(c);
      buffer.strokeWeight(nextStrokeWeight);
      buffer.strokeCap(nextStrokeCap);
      
      PVector p1 = points[i];
      PVector p2 = points[i+1];
      
      buffer.line(p1.x, p1.y, p2.x, p2.y);
    }
  }
}

// ---

// === Explosion Class ===

class Explosion {
  PVector position;
  Particle[] particles;
  float life = EXPLOSION_LIFETIME;

  Explosion(float x, float y) {
    position = new PVector(x, y);
    particles = new Particle[MAX_EXPLOSION_PARTICLES];
    
    // Pick a non-background color for the explosion (0 to PALETTE.length - 2)
    int colorIndex = (int) random(0, PALETTE.length - 1); 
    int expColor = PALETTE[colorIndex];
    
    for (int i = 0; i < MAX_EXPLOSION_PARTICLES; i++) {
      particles[i] = new Particle(position.copy(), expColor);
    }
  }

  void update() {
    life--;
    for (Particle p : particles) {
      p.update();
    }
  }

  void display(PGraphics buffer) {
    // Fade the particles based on remaining life
    float alphaFactor = life / EXPLOSION_LIFETIME;
    
    for (Particle p : particles) {
      p.display(buffer, alphaFactor);
    }
  }
  
  boolean isDead() {
    return life <= 0;
  }
}

// === Particle Class (Used by Explosion) ===

class Particle {
  PVector pos;
  PVector vel;
  int particleColor;
  float size;

  Particle(PVector startPos, int c) {
    pos = startPos.copy();
    particleColor = c;
    // Uses the new, smaller size parameters
    size = random(PARTICLE_SIZE_MIN, PARTICLE_SIZE_MAX); 
    
    // Set a random velocity
    float angle = random(TWO_PI);
    float speed = random(1.0, EXPLOSION_FORCE);
    vel = new PVector(cos(angle) * speed, sin(angle) * speed);
  }

  void update() {
    pos.add(vel);
    // Apply slight friction/drag
    vel.mult(0.95);
  }

  void display(PGraphics buffer, float alphaFactor) {
    // Calculate fading alpha
    int baseAlpha = (int) buffer.alpha(particleColor);
    int currentAlpha = (int) (255 * alphaFactor);
    
    int c = buffer.color(buffer.red(particleColor), buffer.green(particleColor), buffer.blue(particleColor), currentAlpha);
    
    buffer.fill(c);
    buffer.noStroke();
    buffer.ellipse(pos.x, pos.y, size, size);
  }
}
