// GLOBAL PARAMETERS
int GLOBAL_SEED = 222;
int PADDING = 40;
boolean INVERT_BACKGROUND = false;
int MAX_FRAMES = 600;
boolean SAVE_FRAMES = false;
int ANIMATION_SPEED = 30; // frames
int NUM_CIRCLES = 8;
color CIRCLE_COLOR = #FFFF00;

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
  // Semi-transparent background for trails
  if (INVERT_BACKGROUND) {
    fill(255, TRAIL_ALPHA);
  } else {
    fill(0, TRAIL_ALPHA);
  }
  rect(0, 0, width, height);

  // Update and display all moving circles
  for (MovingCircle c : circles) {
    c.update();
    c.display();
  }

  // Draw the static hex grid
  for (Hexagon h : hexagons) {
    h.drawHexagonShape();
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
  float startTime;
  float moveDuration = MOVE_DURATION;

  MovingCircle(PVector initialPos) {
    this.pos = initialPos;
    this.startPos = initialPos.copy();
    this.targetPos = initialPos.copy();
    this.startTime = millis();
  }
  
  void update() {
    float t = (millis() - startTime) / (moveDuration * 1000);
    if (t >= 1) {
      t = 1;
      pos.set(targetPos);
    }
    
    pos.x = lerp(startPos.x, targetPos.x, t);
    pos.y = lerp(startPos.y, targetPos.y, t);
  }

  void display() {
    pushMatrix();
    translate(pos.x, pos.y);
    noStroke();
    fill(CIRCLE_COLOR);
    ellipse(0, 0, CIRCLE_SIZE, CIRCLE_SIZE);
    popMatrix();
  }
  
  void moveTo(PVector newPos) {
    this.startPos = pos.copy();
    this.targetPos = newPos.copy();
    this.startTime = millis();
  }
  
  boolean isAtTarget() {
    return pos.equals(targetPos);
  }
}

// Class to manage each hexagon
class Hexagon {
  PVector pos;

  Hexagon(float x, float y) {
    pos = new PVector(x, y);
  }
  
  void drawHexagonShape() {
    pushMatrix();
    translate(pos.x, pos.y);
    strokeWeight(LINE_WEIGHT);
    if (INVERT_BACKGROUND) {
      stroke(0);
    } else {
      stroke(255);
    }
    noFill();

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
  float hexHeight = sqrt(3) * HEX_SIZE;
  float totalHexWidth = 2 * HEX_SIZE + HEX_GAP;
  float totalHexHeight = hexHeight + HEX_GAP;

  int rowCount = floor((height - 2 * PADDING) / totalHexHeight);
  
  // Calculate grid dimensions for centering
  float gridWidth = 6 * totalHexWidth - HEX_GAP;
  float gridHeight = rowCount * totalHexHeight - HEX_GAP;
  float startX = (width - gridWidth) / 2.0;
  float startY = (height - gridHeight) / 2.0;

  // Loop through rows
  for (int row = 0; row < rowCount; row++) {
    float y = startY + row * totalHexHeight + HEX_SIZE / 2;
    
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
    circles.add(new MovingCircle(hex.pos.copy()));
  }
}

// Moves all circles to a new, random, available hexagon
void moveAllCircles() {
  // Create a list of available destination hexagons
  ArrayList<Hexagon> availableDestinations = new ArrayList<Hexagon>(hexagons);
  
  // A temporary list to hold the circle-to-destination assignments
  ArrayList<PVector> destinations = new ArrayList<PVector>();
  
  // Assign a random, unique destination to each circle
  for (int i = 0; i < circles.size(); i++) {
    int randomIndex = (int) random(availableDestinations.size());
    Hexagon hex = availableDestinations.remove(randomIndex);
    destinations.add(hex.pos);
  }
  
  // Start the movement for each circle
  for (int i = 0; i < circles.size(); i++) {
    circles.get(i).moveTo(destinations.get(i));
  }
}
