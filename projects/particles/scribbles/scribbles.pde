
// Scribble and Scratch Animation

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
final int MAX_SCRIBBLES = 700; // 500 scribble objects (changed from 50)
final float SCRIBBLING_FORCE = 3.5; // Max random step size for a scribble point
final float MIN_STROKE = 0.5; // Minimum stroke thickness
final float MAX_STROKE = 6.0; // Maximum stroke thickness
final float HARDNESS_MIN = 0.1; // Minimum opacity (0.0 to 1.0)
final float HARDNESS_MAX = 0.7; // Maximum opacity (0.0 to 1.0)
final int SCRIBBLE_LENGTH = 150; // Max number of points per scribble

// Persistence/Decay Parameter (controls how fast the old lines fade)
final int PERSISTENCE_ALPHA = 30; // Increased from 15 for a quicker fade

// === Global Variables ===

Scribble[] scribbles;
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
    // Start scribbles randomly within the padded area
    float startX = random(PADDING, width - PADDING);
    float startY = random(PADDING, height - PADDING);
    scribbles[i] = new Scribble(startX, startY);
  }
}

// === Draw Loop ===

void draw() {
  // 1. Apply Decay to the Off-Screen Buffer (pg)
  pg.beginDraw();
  
  // Draw a semi-transparent rectangle over the entire buffer to create a fade/decay effect
  pg.noStroke();
  int decayColor = color(red(bgColor), green(bgColor), blue(bgColor), PERSISTENCE_ALPHA);
  pg.fill(decayColor);
  pg.rect(0, 0, width, height);

  // 2. Center the drawing on the buffer
  pg.pushMatrix();
  pg.translate(width/2, height/2);
  
  // 3. Update and draw new scribble segments to the buffer
  for (Scribble s : scribbles) {
    s.update();
    s.display(pg); // Pass the PGraphics object to the display method
  }

  pg.popMatrix();
  pg.endDraw();
  
  // 4. Draw the persistent buffer to the main canvas
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
  PVector[] points;
  PVector currentPos;
  int currentLength;
  int scribbleColor; 
  
  // Per-segment randomization
  float nextStrokeWeight;
  int nextStrokeCap; // Sharpness
  int nextAlpha; // Hardness

  Scribble(float startX, float startY) {
    // Convert startX/startY from screen coordinates to center-relative coordinates
    float centerX = width / 2;
    float centerY = height / 2;
    currentPos = new PVector(startX - centerX, startY - centerY);
    
    points = new PVector[SCRIBBLE_LENGTH];
    currentLength = 0;
    scribbleColor = fgColor; 
    
    // Initialize the first point
    points[0] = currentPos.copy();
    currentLength = 1;
    
    // Initialize segment parameters
    randomizeSegmentProps();
  }

  void randomizeSegmentProps() {
    // Randomize thickness
    nextStrokeWeight = random(MIN_STROKE, MAX_STROKE);
    
    // Randomize sharpness (stroke cap)
    float sharp = random(1);
    if (sharp < 0.33) {
      nextStrokeCap = ROUND; 
    } else if (sharp < 0.66) {
      nextStrokeCap = SQUARE; 
    } else {
      nextStrokeCap = PROJECT; 
    }
    
    // Randomize hardness (alpha/opacity)
    nextAlpha = (int) map(random(HARDNESS_MIN, HARDNESS_MAX), 0, 1, 0, 255);
  }

  void update() {
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

    if (currentLength < SCRIBBLE_LENGTH) {
      // Append the new point
      points[currentLength] = nextPos;
      currentLength++;
    } else {
      // Shift points for the looping trail
      for (int i = 0; i < SCRIBBLE_LENGTH - 1; i++) {
        points[i] = points[i+1];
      }
      // The new point takes the last spot
      points[SCRIBBLE_LENGTH - 1] = nextPos;
    }
  }

  // Modified to draw to a PGraphics object
  void display(PGraphics buffer) {
    buffer.noFill();
    
    // Draw only the last segment or few segments for a continuous effect
    for (int i = max(0, currentLength - 6); i < currentLength - 1; i++) {
      
      // Randomize segment properties every few steps 
      if (i % 2 == 0) {
        randomizeSegmentProps();
      }
      
      // Create the color with randomized alpha (hardness)
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
