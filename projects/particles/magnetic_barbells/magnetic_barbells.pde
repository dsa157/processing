// ====================================================================
// GLOBAL PARAMETERS
// ====================================================================

// Canvas Dimensions - CORRECTED TO DEFAULT 480x800
final int SKETCH_WIDTH  = 480;  // Default: 480
final int SKETCH_HEIGHT = 800;  // Default: 800

// Padding and Sketch Area
final int PADDING = 20;         // Default: 40 (Updated to 20)

// Animation and Saving
final int MAX_FRAMES    = 900;  // Default: 900
final boolean SAVE_FRAMES = true; // Default: false
final int ANIMATION_SPEED = 30; // Default: 30 (frames per second)

// Colors
final boolean INVERT_COLORS = false; // Default: false (true for dark background)
// Adobe Kuler Palette: "Midnight Run"
// [0] Background/Filings, [1] Magnet N-Pole, [2] Magnet S-Pole
final int[] PALETTE = {
  #EFECCA, // Light Beige
  #940C0C, // Dark Red (N-Pole)
  #0C4294, // Dark Blue (S-Pole)
  #79B185, // Greenish Gray
  #3A5E41  // Dark Green
};

// Seed for random initialization
final long SEED = 12345;

// Particle System Parameters - UPDATED
final int NUM_PARTICLES = 5000;   // Default: 1500 (Updated to 5000)
final float PARTICLE_LENGTH = 10; // Default: 5 (Updated to 10)
final float PARTICLE_MAX_SPEED = 1.5; // Default: 0.5 (Updated to 1.5)

// Visual Interest Parameters
final float END_POINT_RADIUS = 3.0; // Default: 3.0 (Radius of the circle at the end of the filing)

// Magnet Parameters - UPDATED
final float MAGNET_FIELD_STRENGTH = 15000.0; // Default: 15000.0 (Strength of the dipole field)
final float MAGNET_DISTANCE = 50.0;          // Default: 50.0 (Distance between N and S poles)
final float MAGNET_MOVEMENT_RADIUS = 150.0;  // Default: 150.0 (Radius of magnet's circular path)
final float MAGNET_MOVEMENT_SPEED = 0.020;   // Default: 0.005 (Updated to 0.020)
final boolean SHOW_MAGNET = false;           // Default: false (Magnet Visualization)

// Debugging
final boolean SHOW_GRID_CELLS = false; // Default: false (not applicable for this sketch)

// ====================================================================
// CLASS DEFINITIONS
// ====================================================================

/**
 * Represents a single iron filing particle.
 * It's drawn as a line segment and is influenced by the magnetic field.
 */
class Filing {
  PVector position;
  PVector velocity;
  float angle; // The angle of the filing, aligned with the field
  
  // New: Store random colors for the end points
  int colorA; 
  int colorB;

  Filing(float x, float y) {
    position = new PVector(x, y);
    velocity = PVector.random2D();
    velocity.mult(random(PARTICLE_MAX_SPEED));
    angle = 0;
    
    // Assign random colors from the palette, excluding the first (background) color
    colorA = PALETTE[(int)random(1, PALETTE.length)];
    colorB = PALETTE[(int)random(1, PALETTE.length)];
  }

  /**
   * Updates the particle's position and rotation based on the magnetic field.
   * @param nPos Position of the North pole.
   * @param sPos Position of the South pole.
   */
  void update(PVector nPos, PVector sPos) {
    // 1. Calculate Field Vector (Dipole Simulation)
    PVector rN = PVector.sub(position, nPos);
    PVector rS = PVector.sub(position, sPos);

    float rNsq = rN.magSq();
    float rSsq = rS.magSq();

    if (rNsq < 1) rNsq = 1;
    if (rSsq < 1) rSsq = 1;

    // Field from N-Pole (Source/Repulsion)
    PVector fieldN = rN.copy();
    fieldN.normalize();
    fieldN.div(rNsq);

    // Field from S-Pole (Sink/Attraction)
    PVector fieldS = rS.copy();
    fieldS.normalize();
    fieldS.div(rSsq);
    fieldS.mult(-1); 

    PVector fieldVector = PVector.add(fieldN, fieldS);

    // 2. Apply Field (Rotation and Movement)
    fieldVector.mult(MAGNET_FIELD_STRENGTH);
    PVector acceleration = fieldVector;
    
    // Smoothly align the filing's angle to the field direction
    float targetAngle = acceleration.heading();
    
    // Interpolate the angle
    float diff = targetAngle - angle;
    while (diff > PI) diff -= TWO_PI;
    while (diff < -PI) diff += TWO_PI;
    angle += diff * 0.2; 

    // Apply a small force along the field line to move the particle
    velocity.add(acceleration.setMag(0.01)); 
    velocity.limit(PARTICLE_MAX_SPEED);
    position.add(velocity);

    // 3. Implement Wrap-Around (Toroidal Boundary)
    float minX = PADDING;
    float maxX = width - PADDING;
    float minY = PADDING;
    float maxY = height - PADDING;

    if (position.x < minX) {
      position.x = maxX - (minX - position.x); 
    } else if (position.x > maxX) {
      position.x = minX + (position.x - maxX);
    }

    if (position.y < minY) {
      position.y = maxY - (minY - position.y);
    } else if (position.y > maxY) {
      position.y = minY + (position.y - maxY);
    }
  }

  /**
   * Draws the particle as a short line segment with colored circles on the ends.
   */
  void display() {
    float halfLength = PARTICLE_LENGTH / 2.0;

    pushMatrix();
    translate(position.x, position.y);
    rotate(angle);
    
    // Draw the main filing line
    strokeWeight(1);
    stroke(getForeground());
    line(-halfLength, 0, halfLength, 0);
    
    // Draw the colored end circles
    noStroke();
    
    // Circle A
    fill(colorA);
    ellipse(-halfLength, 0, END_POINT_RADIUS * 2, END_POINT_RADIUS * 2);
    
    // Circle B
    fill(colorB);
    ellipse(halfLength, 0, END_POINT_RADIUS * 2, END_POINT_RADIUS * 2);

    popMatrix();
  }
}

// ====================================================================
// GLOBAL VARIABLES AND UTILITY
// ====================================================================

Filing[] filings;

PVector magnetCenter;
PVector nPolePos;
PVector sPolePos;

float sketchAreaX;
float sketchAreaY;
float sketchAreaWidth;
float sketchAreaHeight;

/**
 * Returns the appropriate foreground color based on the INVERT_COLORS setting.
 */
int getForeground() {
  return INVERT_COLORS ? PALETTE[0] : #000000;
}

// ====================================================================
// SETUP AND DRAW
// ====================================================================

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  frameRate(ANIMATION_SPEED);
  randomSeed(SEED);

  // Calculate sketch area
  sketchAreaX = PADDING;
  sketchAreaY = PADDING;
  sketchAreaWidth = width - 2 * PADDING;
  sketchAreaHeight = height - 2 * PADDING;

  // Initialize particles
  filings = new Filing[NUM_PARTICLES];
  for (int i = 0; i < NUM_PARTICLES; i++) {
    float x = random(sketchAreaX, sketchAreaX + sketchAreaWidth);
    float y = random(sketchAreaY, sketchAreaY + sketchAreaHeight);
    filings[i] = new Filing(x, y);
  }

  // Initialize magnet positions
  magnetCenter = new PVector(width / 2.0, height / 2.0);
  nPolePos = new PVector();
  sPolePos = new PVector();

  // Set initial drawing styles
  noFill();
}

void draw() {
  // Set background color
  int bg = PALETTE[0];
  if (INVERT_COLORS) {
    bg = #000000;
  }

  background(bg);
  
  // 1. Update Magnet Position (Circular Movement)
  float angle = frameCount * MAGNET_MOVEMENT_SPEED;
  float centerX = width / 2.0;
  float centerY = height / 2.0;
  
  // Center of the magnet moves in a circle
  magnetCenter.x = centerX + cos(angle) * MAGNET_MOVEMENT_RADIUS;
  magnetCenter.y = centerY + sin(angle) * MAGNET_MOVEMENT_RADIUS * 1.5; 

  // Orientation of the dipole 
  float dipoleAngle = angle * 5.0; 

  // Calculate N and S pole positions relative to the center
  nPolePos.x = magnetCenter.x + cos(dipoleAngle) * MAGNET_DISTANCE / 2.0;
  nPolePos.y = magnetCenter.y + sin(dipoleAngle) * MAGNET_DISTANCE / 2.0;
  sPolePos.x = magnetCenter.x - cos(dipoleAngle) * MAGNET_DISTANCE / 2.0;
  sPolePos.y = magnetCenter.y - sin(dipoleAngle) * MAGNET_DISTANCE / 2.0;

  // 2. Update and Display Filings
  for (Filing f : filings) {
    f.update(nPolePos, sPolePos);
    f.display();
  }

  // 3. Draw Magnet for Visualization (Optional)
  if (SHOW_MAGNET) {
    noStroke();
    
    // N-Pole (Red)
    fill(PALETTE[1]);
    ellipse(nPolePos.x, nPolePos.y, 8, 8);
    
    // S-Pole (Blue)
    fill(PALETTE[2]);
    ellipse(sPolePos.x, sPolePos.y, 8, 8);
    
    // Magnet bar connecting the poles
    strokeWeight(4);
    stroke(#999999);
    line(nPolePos.x, nPolePos.y, sPolePos.x, sPolePos.y);
  }

  // ====================================================================
  // FRAME SAVING
  // ====================================================================
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
      println("Animation finished and saved.");
    }
  } else {
    if (frameCount >= MAX_FRAMES) {
      noLoop();
      println("Animation finished.");
    }
  }
}
