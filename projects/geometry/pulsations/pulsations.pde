// VERSION: 2025.10.20.11.35.00

// --- Parameters ---
// Canvas Setup
final int SKETCH_WIDTH = 480;       // default: 480
final int SKETCH_HEIGHT = 800;      // default: 800
final int PADDING = 40;             // default: 40

// Animation & Save
final int MAX_FRAMES = 900;         // default: 900
final boolean SAVE_FRAMES = false;  // default: false
final int ANIMATION_SPEED = 30;     // default: 30 (frames)

// Color Palette (Adobe Kuler - a harmonious mix of blues, purples, and an accent)
final int[] PALETTE0 = {
  0xFF03045E, // Deep Indigo (Background)
  0xFF0077B6, // Vibrant Blue
  0xFF00B4D8, // Light Cerulean
  0xFF90E0EF, // Pale Cyan
  0xFFCAF0F8  // Very Light Blue
};

final int[] PALETTE = {
  0xFF1B033A, // Very Dark Purple (Background)
  0xFFF72585, // Hot Pink
  0xFF4CC9F0, // Electric Cyan
  0xFFB5179E, // Violet/Fuchsia
  0xFFF8FF00  // Neon Yellow (Accent)
};


// Color & Visuals
final int BACKGROUND_COLOR_INDEX = 0; // default: 0 (Deep Indigo)
final boolean INVERT_BACKGROUND = false; // default: false
final boolean SHOW_GRID = false;    // default: false (used for showing/hiding initial mesh lines)

// Subdivision Settings
final int INITIAL_POINTS_MIN = 3;   // default: 3 (triangle)
final int INITIAL_POINTS_MAX = 6;   // default: 6 (hexagon)
final float INITIAL_RADIUS_BASE = 5;  // default: 5 (reduced for high count)
final float INITIAL_RADIUS_VARIATION = 15; // default: 15 (increased variation)
final int MAX_SUBDIVISIONS = 4;     // default: 4

// Multiple Shapes
final int NUM_SHAPES = 1000;          // default: 1000
final float SHAPE_ALPHA_MIN = 50;     // default: 50
final float SHAPE_ALPHA_MAX = 200;    // default: 200
final float STROKE_WEIGHT_MIN = 1.0f; // default: 0.5f (new)
final float STROKE_WEIGHT_MAX = 2.5f; // default: 2.5f (new)
final float ANIMATION_DURATION_MIN = 1.0f; // min cycle duration in seconds, default: 2.0f
final float ANIMATION_DURATION_MAX = 4.0f; // max cycle duration in seconds, default: 5.0f

// Seed for Randomness
final long GLOBAL_SEED = 157;     // default: 12345

// --- Global Variables ---
PVector sketchAreaCenter;
int bgColor;
ArrayList<SubdivisionShape> subdivisionShapes;

// --- Catmull-Clark Subdivision Class (Simplified for a single closed curve) ---
class Polygon {
  ArrayList<PVector> vertices;

  Polygon(ArrayList<PVector> initialVertices) {
    this.vertices = initialVertices;
  }

  // Simplified Catmull-Clark-like subdivision for a polygon/polyline
  Polygon subdivide() {
    ArrayList<PVector> finalVertices = new ArrayList<PVector>();
    int n = vertices.size();

    for (int i = 0; i < n; i++) {
      PVector p_prev = vertices.get((i - 1 + n) % n);
      PVector p_curr = vertices.get(i);
      PVector p_next = vertices.get((i + 1) % n);

      // Adjusted corner point (P'_i = (P_{i-1} + 6*P_i + P_{i+1}) / 8)
      PVector adjustedCorner = new PVector();
      adjustedCorner.add(PVector.mult(p_prev, 1.0f));
      adjustedCorner.add(PVector.mult(p_curr, 6.0f));
      adjustedCorner.add(PVector.mult(p_next, 1.0f));
      adjustedCorner.div(8.0f);

      // New edge point (E_i = (P_i + P_{i+1}) / 2)
      PVector edgePoint = PVector.mult(p_curr, 0.5f);
      edgePoint.add(PVector.mult(p_next, 0.5f));

      // Insert the adjusted corner point and the new edge point
      finalVertices.add(adjustedCorner);
      finalVertices.add(edgePoint);
    }
    return new Polygon(finalVertices);
  }
}

// --- SubdivisionShape Class ---
class SubdivisionShape {
  ArrayList<PVector> basePolygonPoints;
  PVector position;
  float rotationAngle;
  int shapeColor;
  float scaleFactor;
  float cycleDuration;
  float startTimeOffset;
  float strokeWeight;
  float alphaValue;

  // Pre-calculate all subdivision levels (0 to MAX_SUBDIVISIONS)
  ArrayList<ArrayList<PVector>> allLevels;
  
  // Pre-calculate the "start" points for interpolation (Level N mapped to N+1 structure)
  ArrayList<ArrayList<PVector>> mappedPrevLevels;


  SubdivisionShape(PVector pos, float rot, int col, float scale, float duration, float offset, float strokeW, float alpha) {
    position = pos;
    rotationAngle = rot;
    shapeColor = col;
    scaleFactor = scale;
    cycleDuration = duration;
    startTimeOffset = offset;
    strokeWeight = strokeW;
    alphaValue = alpha;
    
    // 1. Generate initial polygon points
    basePolygonPoints = new ArrayList<PVector>();
    int numPoints = floor(random(INITIAL_POINTS_MIN, INITIAL_POINTS_MAX + 1));
    float radius = INITIAL_RADIUS_BASE + random(-INITIAL_RADIUS_VARIATION, INITIAL_RADIUS_VARIATION);
    float angleStep = TWO_PI / numPoints;
    for (int i = 0; i < numPoints; i++) {
      float angle = angleStep * i + random(-PI/10, PI/10);
      float r = radius + random(-radius * 0.2, radius * 0.2);
      basePolygonPoints.add(new PVector(cos(angle) * r, sin(angle) * r));
    }
    
    // 2. Pre-calculate all subdivision levels (0 to MAX_SUBDIVISIONS)
    allLevels = new ArrayList<ArrayList<PVector>>();
    Polygon currentPoly = new Polygon(basePolygonPoints);
    allLevels.add(currentPoly.vertices); // Level 0
    
    for (int i = 0; i < MAX_SUBDIVISIONS; i++) {
      currentPoly = currentPoly.subdivide();
      allLevels.add(currentPoly.vertices); // Level 1 to MAX_SUBDIVISIONS
    }
    
    // 3. Pre-calculate all "start" points for interpolation (mapped previous levels)
    mappedPrevLevels = new ArrayList<ArrayList<PVector>>();
    // The first element is Level 0, which is the start of the L0 -> L1 interpolation
    mappedPrevLevels.add(allLevels.get(0)); 
    
    for (int level = 1; level <= MAX_SUBDIVISIONS; level++) {
        ArrayList<PVector> prevLevel = allLevels.get(level - 1);
        ArrayList<PVector> mappedPrevLevel = new ArrayList<PVector>();
        
        int n_prev = prevLevel.size();
        
        // Map the sparser previous level (L_i-1) onto the current level's structure (L_i)
        for (int i = 0; i < n_prev; i++) {
            PVector p_curr = prevLevel.get(i);
            PVector p_next = prevLevel.get((i + 1) % n_prev);
            
            // Corner point in L_i (2i) maps back to p_curr
            mappedPrevLevel.add(p_curr.copy());
            
            // Edge point in L_i (2i+1) maps back to midpoint (p_curr, p_next)
            PVector edgePoint = PVector.add(p_curr, p_next).mult(0.5f);
            mappedPrevLevel.add(edgePoint);
        }
        mappedPrevLevels.add(mappedPrevLevel);
    }
  }
  
  void display() {
    // Calculate animation time (in seconds)
    float currentTime = (frameCount + startTimeOffset) / (float)ANIMATION_SPEED;
    
    // Normalized time within the shape's cycle (0.0 to 1.0)
    float cycleTime = (currentTime % cycleDuration) / cycleDuration;
    
    // --- Smooth Boomerang Progress Calculation (0.0 to MAX_SUBDIVISIONS and back) ---
    // Use a cosine wave to generate a smooth 0 to 1 to 0 movement.
    // Progress Factor: 0.0 to 1.0 to 0.0
    float progressFactor = 0.5f + 0.5f * cos(TWO_PI * cycleTime + PI); // Range: 0.0 to 1.0 to 0.0

    // currentProgress: 0.0 to MAX_SUBDIVISIONS and back to 0.0
    float currentProgress = progressFactor * MAX_SUBDIVISIONS;
    
    drawSubdividedShape(currentProgress);
  }
  
  void drawSubdividedShape(float currentProgress) {
    // The step is the lower subdivision level we are starting from (0 to MAX_SUBDIVISIONS - 1)
    int step = floor(currentProgress);
    step = constrain(step, 0, MAX_SUBDIVISIONS - 1); 

    // The interpolation factor is the progress from one integer level to the next (0.0 to 1.0)
    float interpolationFactor = currentProgress - step; 
    
    // Determine the start and end level indices for the interpolation
    int startLevelIndex = step;
    int endLevelIndex = step + 1;

    // --- Determine Start and End Point Sets ---
    ArrayList<PVector> startPoints;
    ArrayList<PVector> endPoints;
    
    if (endLevelIndex > MAX_SUBDIVISIONS) {
        // We are interpolating from MAX_SUBDIVISIONS back to MAX_SUBDIVISIONS - 1
        // The *visual* step is MAX_SUBDIVISIONS-1 to MAX_SUBDIVISIONS to MAX_SUBDIVISIONS-1
        // When progress is 3.5 to 4.0 to 3.5, the 'step' is 3 for forward, 3 for backward.
        
        // Use the highest level (MAX_SUBDIVISIONS) and the one before it (MAX_SUBDIVISIONS - 1)
        startPoints = mappedPrevLevels.get(MAX_SUBDIVISIONS); // L_max-1 mapped to L_max structure
        endPoints = allLevels.get(MAX_SUBDIVISIONS);          // L_max structure
        
        // Reverse the interpolation factor for the backward half of the cycle
        // Since we are moving between the final two states, we use the complementary factor to blend back
        interpolationFactor = 1.0f - interpolationFactor;
    } else {
        // Forward motion (or regression at lower levels)
        startPoints = mappedPrevLevels.get(endLevelIndex); // L_step mapped to L_step+1 structure
        endPoints = allLevels.get(endLevelIndex);          // L_step+1 structure
    }
    
    // --- Final Interpolation (Constant Point Count) ---
    ArrayList<PVector> interpolatedSurface = new ArrayList<PVector>();
    // The point count is constant for any given step transition (always the size of the higher level)
    int n = endPoints.size(); 

    for (int i = 0; i < n; i++) {
        PVector start = startPoints.get(i);
        PVector end = endPoints.get(i);
        
        PVector interpolatedPoint = PVector.lerp(start, end, interpolationFactor);
        interpolatedSurface.add(interpolatedPoint);
    }


    pushMatrix();
    // 1. Position and Rotation
    translate(position.x, position.y);
    rotate(rotationAngle + sin(frameCount * 0.01f * cycleDuration) * 0.1f);
    scale(scaleFactor);

    // Draw the Emergent Smooth Form
    noFill();
    strokeWeight(strokeWeight); // Use instance property
    stroke(shapeColor, alphaValue); // Use instance property

    beginShape();
    for (PVector v : interpolatedSurface) {
      vertex(v.x, v.y);
    }
    endShape(CLOSE);

    // Draw initial polygon (grid) if enabled
    if (SHOW_GRID) {
      strokeWeight(0.5);
      stroke(255, 50);
      
      beginShape();
      for (PVector v : basePolygonPoints) {
        vertex(v.x, v.y);
      }
      endShape(CLOSE);
    }

    popMatrix();
  }
}

// --- Setup ---

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  // Setup Random Seed
  randomSeed(GLOBAL_SEED);

  // Set frame rate
  frameRate(ANIMATION_SPEED);

  // Calculate Sketch Area Center
  sketchAreaCenter = new PVector(SKETCH_WIDTH / 2.0f, SKETCH_HEIGHT / 2.0f);

  // Set Colors
  bgColor = PALETTE[BACKGROUND_COLOR_INDEX];
  if (INVERT_BACKGROUND) {
    bgColor = (0xFF << 24) | (~(bgColor & 0x00FFFFFF) & 0x00FFFFFF);
  }
  
  // Initialize multiple SubdivisionShapes
  subdivisionShapes = new ArrayList<SubdivisionShape>();
  
  // Define the boundary for spawning shapes (respecting padding)
  float minX = PADDING;
  float minY = PADDING;
  float maxX = SKETCH_WIDTH - PADDING;
  float maxY = SKETCH_HEIGHT - PADDING;

  for (int i = 0; i < NUM_SHAPES; i++) {
    float x = random(minX, maxX);
    float y = random(minY, maxY);
    PVector pos = new PVector(x, y);
    
    float rot = random(TWO_PI);
    int colorIndex = floor(random(1, PALETTE.length));
    int col = PALETTE[colorIndex];
    
    float scale = random(0.5f, 3.0f);
    float duration = random(ANIMATION_DURATION_MIN, ANIMATION_DURATION_MAX);
    float offset = random(duration * ANIMATION_SPEED);
    
    float strokeW = random(STROKE_WEIGHT_MIN, STROKE_WEIGHT_MAX);
    float alpha = random(SHAPE_ALPHA_MIN, SHAPE_ALPHA_MAX);
    
    subdivisionShapes.add(new SubdivisionShape(pos, rot, col, scale, duration, offset, strokeW, alpha));
  }
}

// --- Draw Loop ---

void draw() {
  background(bgColor);
  
  // Display all shapes asynchronously
  for (SubdivisionShape shape : subdivisionShapes) {
    shape.display();
  }
  
  // --- Frame Saving ---
  if (SAVE_FRAMES) {
    if (frameCount <= MAX_FRAMES) {
      saveFrame("frames/####.tif");
    } else {
      noLoop();
    }
  }
}
