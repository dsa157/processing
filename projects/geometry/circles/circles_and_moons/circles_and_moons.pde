// ----------------------------------------------------------------------
// GLOBAL CONFIGURATION
// ----------------------------------------------------------------------
final int SKETCH_WIDTH = 480;
final int SKETCH_HEIGHT = 800;

// Canvas setup
final int PADDING = 60;
final boolean INVERT_COLORS = false; // Invert background/foreground

// Animation & Save settings
final int MAX_FRAMES = 900;
final boolean SAVE_FRAMES = false;
final int ANIMATION_SPEED = 30; // Frames per second
final long SEED = 12345; // Global seed for random()

// Color palette (Hex values)
final int[] PALETTE = {
  0xFFE5B581, // Light Creamy Orange
  0xFF9656A1, // Medium Purple
  0xFF3C3B61, // Dark Blue-Purple
  0xFFF4F0F0, // Near White (Used as a potential XOR color)
  0xFF1A1A1A  // Near Black (Used as a potential BG color)
};

final int BG_COLOR_INDEX = 0; // Index of background color in PALETTE

// Sketch parameters
final int MIN_SYSTEMS = 4; // 2 - Number of independent rotating groups
final int MAX_SYSTEMS = 8; // 4
final int MIN_CIRCLES_PER_SYSTEM = 3; // Min circles tangentially connected in a group
final int MAX_CIRCLES_PER_SYSTEM = 4; // Max circles tangentially connected in a group
final float MIN_CIRCLE_RADIUS = 30; // Widely varying min radius
final float MAX_CIRCLE_RADIUS = 120; // 150 Widely varying max radius
final float MIN_ROTATION_SPEED = 0.008;
final float MAX_ROTATION_SPEED = 0.05;
final float MOON_RADIUS_FACTOR = 0.2; // Moon size relative to its parent circle
final float MOON_ROTATION_SPEED = 0.05;

// ----------------------------------------------------------------------
// GLOBAL VARIABLES
// ----------------------------------------------------------------------
System[] systems;
int bgColor;
float drawAreaSize;
float centerX, centerY;

// ----------------------------------------------------------------------
// SETTINGS
// ----------------------------------------------------------------------
void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

// ----------------------------------------------------------------------
// SETUP
// ----------------------------------------------------------------------
void setup() {
  randomSeed(SEED);
  frameRate(ANIMATION_SPEED);

  // Set Background Color from Palette
  bgColor = PALETTE[BG_COLOR_INDEX];
  if (INVERT_COLORS) {
    // Invert the RGB part, keep the Alpha FF
    bgColor = (bgColor & 0xFF000000) | (~(bgColor & 0x00FFFFFF) & 0x00FFFFFF);
  }

  // Calculate drawing area and center
  drawAreaSize = min(width, height) - 2 * PADDING;
  centerX = width / 2.0;
  centerY = height / 2.0;

  // Initialize Systems
  int numSystems = (int)random(MIN_SYSTEMS, MAX_SYSTEMS + 1);
  systems = new System[numSystems];

  for (int i = 0; i < numSystems; i++) {
    // Center the system around the canvas center
    float x = centerX; 
    float y = centerY;
    
    // Max radius for the system to fit roughly in the draw area
    float maxSystemRadius = drawAreaSize / 2; 

    // Random rotation speed and direction (now randomized)
    float speed = random(MIN_ROTATION_SPEED, MAX_ROTATION_SPEED);
    if (random(1) < 0.5) {
      speed *= -1; // Randomly set direction to counter-clockwise
    }
    
    systems[i] = new System(x, y, maxSystemRadius, speed);
  }
}

// ----------------------------------------------------------------------
// DRAW LOOP
// ----------------------------------------------------------------------
void draw() {
  background(bgColor);

  // Set blend mode to XOR (DIFFERENCE for the visual effect)
  blendMode(DIFFERENCE); 

  // Draw all systems
  for (System s : systems) {
    s.update();
    s.display();
  }

  // Restore blend mode to default
  blendMode(BLEND);

  // ----------------------------------------------------------------------
  // FRAME SAVING & LOOP STOP
  // ----------------------------------------------------------------------
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  } else if (frameCount >= MAX_FRAMES) {
    noLoop();
  }
}

// ----------------------------------------------------------------------
// CLASSES
// ----------------------------------------------------------------------

class System {
  float centerX, centerY;
  float systemRadius;
  float rotSpeed;
  float angle;
  ArrayList<Circle> circles;

  System(float x, float y, float r, float speed) {
    centerX = x;
    centerY = y;
    systemRadius = r;
    rotSpeed = speed;
    angle = random(TWO_PI);
    circles = new ArrayList<Circle>();
    
    initializeCircles();
  }
  
  void initializeCircles() {
    int numCircles = (int)random(MIN_CIRCLES_PER_SYSTEM, MAX_CIRCLES_PER_SYSTEM + 1);
    
    // Assign random, widely varying radii
    for (int i = 0; i < numCircles; i++) {
      float r = random(MIN_CIRCLE_RADIUS, MAX_CIRCLE_RADIUS);
      
      // Random color from the palette
      int colorIndex = (int)random(PALETTE.length);
      int c = PALETTE[colorIndex];
      if (INVERT_COLORS) {
         c = (c & 0xFF000000) | (~(c & 0x00FFFFFF) & 0x00FFFFFF);
      }
      
      circles.add(new Circle(r, c));
    }
    
    // Position circles tangentially in a chain and find the pivot point.
    float currentX = 0;
    
    // Calculate local positions relative to an arbitrary center (0, 0)
    for (int i = 0; i < circles.size(); i++) {
      Circle c = circles.get(i);
      
      if (i > 0) {
        Circle prev = circles.get(i-1);
        // Tangent connection: new position is old position + old radius + new radius
        currentX += prev.radius + c.radius; 
      }
      c.localX = currentX;
      c.localY = 0; // The chain is horizontal for calculation ease
    }
    
    // Shift the local coordinates so the visual center of the whole chain is at (0,0)
    // This makes the whole *system* rotate around its center.
    float totalWidth = circles.get(circles.size() - 1).localX + circles.get(circles.size() - 1).radius;
    float shift = totalWidth / 2;
    
    for (Circle c : circles) {
        c.localX -= shift;
    }
  }

  void update() {
    angle += rotSpeed;
    for(Circle c : circles) {
      c.update();
    }
  }

  void display() {
    pushMatrix();
    translate(centerX, centerY);
    rotate(angle); // Rotate the whole system around the canvas center

    for (int i = 0; i < circles.size(); i++) {
      Circle current = circles.get(i);
      current.display();
      
      // Calculate tangent points for the "moons" (except for the last circle)
      if (i < circles.size() - 1) {
          Circle next = circles.get(i + 1);
          
          // Tangent point (midpoint between the two circle centers)
          float tx = (current.localX * next.radius + next.localX * current.radius) / (current.radius + next.radius);
          float ty = 0; // Since they are aligned horizontally in local space
          
          // Draw the moon rotating around the tangent point
          drawMoon(tx, ty, current.rotMoonAngle);
      }
    }

    popMatrix();
  }
  
  void drawMoon(float x, float y, float moonAngle) {
    pushMatrix();
    translate(x, y); // Translate to the tangent point
    rotate(moonAngle); // Rotate the moon itself

    // Draw the moon
    fill(255, 100); // White/Gray transparent for moon
    noStroke();
    // Moon is offset by MOON_RADIUS_FACTOR * 10 (a fixed distance) from the tangent point
    float moonOffset = 10; 
    float moonSize = MOON_RADIUS_FACTOR * 100;
    ellipse(moonOffset, 0, moonSize, moonSize); 

    popMatrix();
  }
}

class Circle {
  float radius;
  int circleColor;
  float localX, localY; // Position relative to the system's center
  float rotMoonAngle;
  float rotMoonSpeed;

  Circle(float r, int c) {
    radius = r;
    circleColor = c;
    rotMoonAngle = random(TWO_PI);
    
    // Randomize moon rotation direction as well
    rotMoonSpeed = MOON_ROTATION_SPEED * (random(1) < 0.5 ? 1 : -1);
  }

  void update() {
    rotMoonAngle += rotMoonSpeed;
  }

  void display() {
    pushMatrix();
    translate(localX, localY); // Move to the circle's position
    
    // Pattern inside the circle
    noStroke();
    fill(circleColor, 200); // Main circle body
    ellipse(0, 0, radius * 2, radius * 2);
    
    popMatrix();
  }
}
