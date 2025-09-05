// GLOBAL PARAMETERS
int GLOBAL_SEED = 222;
int PADDING = 40;
boolean INVERT_BACKGROUND = false;
int MAX_FRAMES = 600;
boolean SAVE_FRAMES = false;
int ANIMATION_SPEED = 30; // frames per second
int NUM_CIRCLES = 3;
color CIRCLE_COLOR = #FFFF00;
float PULSE_DURATION = 0.5; // in seconds

// SKETCH-SPECIFIC PARAMETERS
float HEX_SIZE = 40; // Size of each hexagon
float HEX_GAP = -10; // Configurable spacing between hexagons
float LINE_WEIGHT = 2.0;
float CIRCLE_SIZE = HEX_SIZE * 0.4;
float MOVE_DURATION = 1.0; // in seconds
float TRAIL_ALPHA = 5;

// Lists to hold hexagon and circle objects
ArrayList<Hexagon> hexagons = new ArrayList<Hexagon>();
ArrayList<MovingCircle> circles = new ArrayList<MovingCircle>();

void setup() {
  size(480, 800);
  randomSeed(GLOBAL_SEED);
  frameRate(ANIMATION_SPEED);

  if (INVERT_BACKGROUND) {
    background(255);
  } else {
    background(0);
  }

  createHexGrid();
  createCircles();
}

void draw() {
  // Apply a translucent overlay to create a trail effect.
  if (INVERT_BACKGROUND) {
    fill(255, TRAIL_ALPHA);
  } else {
    fill(0, TRAIL_ALPHA);
  }
  noStroke(); // Ensure no outline is drawn on the trail rectangle
  rect(0, 0, width, height);
  
  // Update and draw the hex grid.
  for (Hexagon h : hexagons) {
    h.update();
    h.drawHexagonShape();
  }
  
  // Update and display all moving circles.
  for (MovingCircle c : circles) {
    c.update();
    c.display();
  }
  
  // Check if all circles have arrived and it's time to move again
  float moveInterval = ANIMATION_SPEED * MOVE_DURATION;
  if (frameCount % moveInterval == 0) {
    moveAllCircles();
  }

  // Check if we need to save frames
  if (SAVE_FRAMES) {
    if (frameCount <= MAX_FRAMES) {
      saveFrame("frames/####.tif");
    } else {
      noLoop();
    }
  }
}

// Class to manage the moving circle
class MovingCircle {
  PVector pos;
  PVector startPos;
  PVector targetPos;
  Hexagon currentHex;
  float startTime;
  float moveDuration = MOVE_DURATION;
  boolean atTarget = true;
  float ARRIVAL_THRESHOLD = 0.5;

  MovingCircle(PVector initialPos, Hexagon initialHex) {
    this.pos = initialPos;
    this.startPos = initialPos.copy();
    this.targetPos = initialPos.copy();
    this.startTime = millis();
    this.currentHex = initialHex;
  }
  
  void update() {
    float t = (millis() - startTime) / (moveDuration * 1000);
    
    if (t >= 1) {
      t = 1;
      pos.set(targetPos);
      if (!atTarget) {
        currentHex.startPulse();
        atTarget = true;
      }
    }
    
    pos.x = lerp(startPos.x, targetPos.x, t);
    pos.y = lerp(startPos.y, targetPos.y, t);
    
    // Check for arrival using a distance threshold
    if (!atTarget && PVector.dist(pos, targetPos) < ARRIVAL_THRESHOLD) {
      pos.set(targetPos);
      currentHex.startPulse();
      atTarget = true;
    }
  }

  void display() {
    pushMatrix();
    translate(pos.x, pos.y);
    noStroke();
    fill(CIRCLE_COLOR);
    ellipse(0, 0, CIRCLE_SIZE, CIRCLE_SIZE);
    popMatrix();
  }
  
  void moveTo(PVector newPos, Hexagon newHex) {
    this.startPos = pos.copy();
    this.targetPos = newPos.copy();
    this.currentHex = newHex;
    this.startTime = millis();
    this.atTarget = false;
  }
}

// Class to manage each hexagon
class Hexagon {
  PVector pos;
  color pulseColor;
  boolean isPulsing = false;
  float pulseStartTime;

  Hexagon(float x, float y) {
    pos = new PVector(x, y);
    if (INVERT_BACKGROUND) {
      pulseColor = color(255);
    } else {
      pulseColor = color(0);
    }
  }
  
  void update() {
    if (isPulsing) {
      float t = (millis() - pulseStartTime) / (PULSE_DURATION * 1000);
      if (t >= 1) {
        isPulsing = false;
        if (INVERT_BACKGROUND) {
          pulseColor = color(255, 20); // Make the pulse effect transparent
        } else {
          pulseColor = color(0, 20); // Make the pulse effect transparent
        }
      } else {
        color from = INVERT_BACKGROUND ? color(255) : color(0);
        color to = CIRCLE_COLOR;
        if (t < 0.5) {
          pulseColor = lerpColor(from, to, t * 2);
        } else {
          pulseColor = lerpColor(to, from, (t - 0.5) * 2);
        }
      }
    }
  }
  
  void startPulse() {
    isPulsing = true;
    pulseStartTime = millis();
  }
  
  void drawHexagonShape() {
    pushMatrix();
    translate(pos.x, pos.y);
    strokeWeight(LINE_WEIGHT);
    
    // Set stroke and fill based on pulse state
    if (INVERT_BACKGROUND) {
      stroke(0);
    } else {
      stroke(255);
    }
    
    // Use a transparent fill for the background of the hexagons
    if (isPulsing) {
        fill(pulseColor);
    } else {
        if (INVERT_BACKGROUND) {
          fill(255, 20);
        } else {
          fill(0, 20);
        }
    }
    
    // Draw the hexagon shape with a 30-degree offset for the point-top
    beginShape();
    for (int i = 0; i < 6; i++) {
      float angle = TWO_PI / 6 * i + PI / 6;
      vertex(HEX_SIZE * cos(angle), HEX_SIZE * sin(angle));
    }
    endShape(CLOSE);
    popMatrix();
  }
}

// Function to create and populate the hex grid
void createHexGrid() {
  float hexWidth = 2 * HEX_SIZE;
  float hexHeight = sqrt(3) * HEX_SIZE;
  float totalHexWidth = hexWidth + HEX_GAP;
  float totalHexHeight = hexHeight + HEX_GAP;

  int rowCount = floor((height - 2 * PADDING) / totalHexHeight);
  
  // Calculate grid dimensions for centering
  float gridWidth = 6 * totalHexWidth - HEX_GAP;
  float gridHeight = rowCount * totalHexHeight - HEX_GAP;
  float startX = (width - gridWidth) / 2.0;
  float startY = (height - gridHeight) / 2.0;

  // Loop through rows
  for (int row = 0; row < rowCount; row++) {
    float y = startY + row * totalHexHeight + hexHeight / 2.0;
    
    // Rows with 5 hexagons
    if (row % 2 == 0) {
      float rowWidth5 = 5 * totalHexWidth - HEX_GAP;
      float rowStartX5 = startX + (gridWidth - rowWidth5) / 2.0;
      for (int col = 0; col < 5; col++) {
        // Special case for the last row's last hexagon
        if (row == rowCount - 1 && col == 4) {
          continue; 
        }
        float x = rowStartX5 + col * totalHexWidth + HEX_SIZE;
        hexagons.add(new Hexagon(x, y));
      }
    }
    // Rows with 6 hexagons
    else {
      for (int col = 0; col < 6; col++) {
        float x = startX + col * totalHexWidth + HEX_SIZE;
        hexagons.add(new Hexagon(x, y));
      }
    }
  }
}

// Creates a moving circle for a random subset of hexagons
void createCircles() {
  // Create a copy of the hexagons list to pick from
  ArrayList<Hexagon> availableHexes = new ArrayList<Hexagon>(hexagons);
  
  // Ensure we don't try to create more circles than there are hexagons
  int numToCreate = min(NUM_CIRCLES, availableHexes.size());

  for (int i = 0; i < numToCreate; i++) {
    int randomIndex = (int) random(availableHexes.size());
    Hexagon hex = availableHexes.remove(randomIndex);
    circles.add(new MovingCircle(hex.pos.copy(), hex));
  }
}

// Moves all circles to a new, random, available hexagon
void moveAllCircles() {
  // Create a list of available destination hexagons
  ArrayList<Hexagon> availableDestinations = new ArrayList<Hexagon>(hexagons);
  
  // A temporary list to hold the circle-to-destination assignments
  ArrayList<PVector> destinations = new ArrayList<PVector>();
  ArrayList<Hexagon> destinationHexes = new ArrayList<Hexagon>();

  // Assign a random, unique destination to each circle
  for (int i = 0; i < circles.size(); i++) {
    int randomIndex = (int) random(availableDestinations.size());
    Hexagon hex = availableDestinations.remove(randomIndex);
    destinations.add(hex.pos);
    destinationHexes.add(hex);
  }
  
  // Start the movement for each circle
  for (int i = 0; i < circles.size(); i++) {
    circles.get(i).moveTo(destinations.get(i), destinationHexes.get(i));
  }
}
