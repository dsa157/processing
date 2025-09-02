// The Living Circuitry: Multiple letters are drawn simultaneously in a grid.

// Global seed for random number generation
long seed = 12345;

int cols = 5;
int rows = 9;
float charSize = 80;
char[][] grid;
CircuitLine[][] lines;
float offsetX, offsetY;

PFont font;
float glowHue = 0;
float lineHue = 0;
int lastChangeTime;
int changeInterval;

void setup() {
  size(480, 800);
  randomSeed(seed);

  // Calculate offsets for centering the grid
  offsetX = (width - cols * charSize) / 2;
  offsetY = (height - rows * charSize) / 2;
  
  // Initialize the grid and lines array
  grid = new char[cols][rows];
  lines = new CircuitLine[cols][rows];
  
  drawNewGrid();
  lastChangeTime = millis();
  changeInterval = (int)random(2000, 4000);

  // Color setup
  colorMode(HSB, 360, 100, 100);
  background(0);

  // Font for the finished message
  font = createFont("Arial", 48);
  textFont(font);
}

void draw() {
  // Fade the background slightly
  fill(0, 10);
  noStroke();
  rect(0, 0, width, height);

  // Update the grid if the interval has passed
  if (millis() - lastChangeTime > changeInterval) {
    drawNewGrid();
    lastChangeTime = millis();
    changeInterval = (int)random(2000, 4000);
  }

  // Draw and update each circuit line
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      lines[x][y].update();
      lines[x][y].display();

      // Check if a character is finished, and reset it
      if (lines[x][y].isComplete()) {
        PVector gridPos = new PVector(x, y);
        grid[x][y] = (char)('A' + floor(random(26)));
        PVector[] newPath = getPathForChar(grid[x][y], gridPos);
        lines[x][y] = new CircuitLine(newPath);
      }
    }
  }

  // Pulsating glow and line color
  glowHue = (glowHue + 0.5) % 360;
  lineHue = (lineHue + 1) % 360;
}

void drawNewGrid() {
  // Create a circuit line for each grid cell
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      grid[x][y] = (char)('A' + floor(random(26)));
      PVector gridPos = new PVector(x, y);
      PVector[] path = getPathForChar(grid[x][y], gridPos);
      lines[x][y] = new CircuitLine(path);
    }
  }
}

// Class to handle the circuit line drawing
class CircuitLine {
  PVector[] path;
  int pathIndex = 0;
  PVector currentPos;
  float speed = 5;

  CircuitLine(PVector[] p) {
    this.path = p;
    this.currentPos = path[0].copy();
  }

  void update() {
    if (pathIndex < path.length - 1) {
      PVector target = path[pathIndex + 1];
      PVector dir = PVector.sub(target, currentPos);
      float dist = dir.mag();

      if (dist < speed) {
        currentPos = target.copy();
        pathIndex++;
      } else {
        dir.normalize().mult(speed);
        currentPos.add(dir);
      }
    }
  }

  void display() {
    if (pathIndex < path.length - 1) {
      // Main line with pulsating glow
      float pulse = sin(frameCount * 0.1) * 20 + 30;
      strokeWeight(5);
      stroke(lineHue, 80, 100);
      line(path[pathIndex].x, path[pathIndex].y, currentPos.x, currentPos.y);

      // Glow effect
      strokeWeight(pulse);
      stroke(glowHue, 100, 100, 50);
      line(path[pathIndex].x, path[pathIndex].y, currentPos.x, currentPos.y);

      // Smaller fading lines
      for (int i = 0; i < 5; i++) {
        float offset = random(10, 50);
        PVector trailPos = PVector.lerp(path[pathIndex], currentPos, random(0, 1));
        PVector trailEnd = PVector.add(trailPos, PVector.random2D().mult(offset));
        strokeWeight(random(1, 3));
        stroke(lineHue, 50, 80, random(50));
        line(trailPos.x, trailPos.y, trailEnd.x, trailEnd.y);
      }
    }
  }

  boolean isComplete() {
    return pathIndex >= path.length - 1;
  }
}

// Function to define paths for each character
PVector[] getPathForChar(char c, PVector gridPos) {
  float xOffset = gridPos.x * charSize + charSize / 2 + offsetX;
  float yOffset = gridPos.y * charSize + charSize / 2 + offsetY;
  float s = charSize * 0.7;

  switch (c) {
    case 'A':
      return new PVector[]{
        new PVector(xOffset - s/2, yOffset + s/2),
        new PVector(xOffset, yOffset - s/2),
        new PVector(xOffset + s/2, yOffset + s/2),
        new PVector(xOffset - s/4, yOffset),
        new PVector(xOffset + s/4, yOffset)
      };
    case 'B':
      return new PVector[]{
        new PVector(xOffset - s/2, yOffset - s/2),
        new PVector(xOffset - s/2, yOffset + s/2),
        new PVector(xOffset, yOffset + s/2),
        new PVector(xOffset + s/4, yOffset + s/4),
        new PVector(xOffset + s/4, yOffset),
        new PVector(xOffset - s/2, yOffset),
        new PVector(xOffset + s/4, yOffset - s/4),
        new PVector(xOffset + s/4, yOffset - s/2),
        new PVector(xOffset - s/2, yOffset - s/2)
      };
    case 'C':
      return new PVector[]{
        new PVector(xOffset + s/4, yOffset - s/4),
        new PVector(xOffset, yOffset - s/2),
        new PVector(xOffset - s/4, yOffset - s/4),
        new PVector(xOffset - s/4, yOffset + s/4),
        new PVector(xOffset, yOffset + s/2),
        new PVector(xOffset + s/4, yOffset + s/4)
      };
    case 'D':
      return new PVector[]{
        new PVector(xOffset - s/2, yOffset - s/2),
        new PVector(xOffset - s/2, yOffset + s/2),
        new PVector(xOffset, yOffset + s/2),
        new PVector(xOffset + s/4, yOffset),
        new PVector(xOffset, yOffset - s/2),
        new PVector(xOffset - s/2, yOffset - s/2)
      };
    case 'E':
      return new PVector[]{
        new PVector(xOffset + s/4, yOffset - s/2),
        new PVector(xOffset - s/4, yOffset - s/2),
        new PVector(xOffset - s/4, yOffset),
        new PVector(xOffset + s/4, yOffset),
        new PVector(xOffset - s/4, yOffset),
        new PVector(xOffset - s/4, yOffset + s/2),
        new PVector(xOffset + s/4, yOffset + s/2)
      };
    case 'F':
      return new PVector[]{
        new PVector(xOffset + s/4, yOffset - s/2),
        new PVector(xOffset - s/4, yOffset - s/2),
        new PVector(xOffset - s/4, yOffset),
        new PVector(xOffset + s/4, yOffset),
        new PVector(xOffset - s/4, yOffset)
      };
    case 'G':
      return new PVector[]{
        new PVector(xOffset + s/4, yOffset - s/2),
        new PVector(xOffset - s/4, yOffset - s/2),
        new PVector(xOffset - s/4, yOffset + s/2),
        new PVector(xOffset + s/4, yOffset + s/2),
        new PVector(xOffset + s/4, yOffset/2),
        new PVector(xOffset, yOffset/2)
      };
    case 'H':
      return new PVector[]{
        new PVector(xOffset - s/2, yOffset - s/2),
        new PVector(xOffset - s/2, yOffset + s/2),
        new PVector(xOffset - s/2, yOffset),
        new PVector(xOffset + s/2, yOffset),
        new PVector(xOffset + s/2, yOffset - s/2),
        new PVector(xOffset + s/2, yOffset + s/2)
      };
    case 'I':
      return new PVector[]{
        new PVector(xOffset - s/4, yOffset - s/2),
        new PVector(xOffset + s/4, yOffset - s/2),
        new PVector(xOffset, yOffset - s/2),
        new PVector(xOffset, yOffset + s/2),
        new PVector(xOffset - s/4, yOffset + s/2),
        new PVector(xOffset + s/4, yOffset + s/2)
      };
    case 'J':
      return new PVector[]{
        new PVector(xOffset + s/4, yOffset - s/2),
        new PVector(xOffset + s/4, yOffset + s/2),
        new PVector(xOffset, yOffset + s/2),
        new PVector(xOffset - s/4, yOffset + s/4)
      };
    case 'K':
      return new PVector[]{
        new PVector(xOffset - s/2, yOffset - s/2),
        new PVector(xOffset - s/2, yOffset + s/2),
        new PVector(xOffset - s/2, yOffset),
        new PVector(xOffset + s/2, yOffset - s/2),
        new PVector(xOffset - s/2, yOffset),
        new PVector(xOffset + s/2, yOffset + s/2)
      };
    case 'L':
      return new PVector[]{
        new PVector(xOffset - s/2, yOffset - s/2),
        new PVector(xOffset - s/2, yOffset + s/2),
        new PVector(xOffset + s/2, yOffset + s/2)
      };
    case 'M':
      return new PVector[]{
        new PVector(xOffset - s/2, yOffset + s/2),
        new PVector(xOffset - s/2, yOffset - s/2),
        new PVector(xOffset, yOffset),
        new PVector(xOffset + s/2, yOffset - s/2),
        new PVector(xOffset + s/2, yOffset + s/2)
      };
    case 'N':
      return new PVector[]{
        new PVector(xOffset - s/2, yOffset + s/2),
        new PVector(xOffset - s/2, yOffset - s/2),
        new PVector(xOffset + s/2, yOffset + s/2),
        new PVector(xOffset + s/2, yOffset - s/2)
      };
    case 'O':
      return new PVector[]{
        new PVector(xOffset, yOffset - s/2),
        new PVector(xOffset + s/4, yOffset - s/4),
        new PVector(xOffset + s/4, yOffset + s/4),
        new PVector(xOffset, yOffset + s/2),
        new PVector(xOffset - s/4, yOffset + s/4),
        new PVector(xOffset - s/4, yOffset - s/4),
        new PVector(xOffset, yOffset - s/2)
      };
    case 'P':
      return new PVector[]{
        new PVector(xOffset - s/2, yOffset + s/2),
        new PVector(xOffset - s/2, yOffset - s/2),
        new PVector(xOffset + s/4, yOffset - s/2),
        new PVector(xOffset + s/4, yOffset),
        new PVector(xOffset - s/2, yOffset)
      };
    case 'Q':
      return new PVector[]{
        new PVector(xOffset, yOffset - s/2),
        new PVector(xOffset + s/4, yOffset - s/4),
        new PVector(xOffset + s/4, yOffset + s/4),
        new PVector(xOffset, yOffset + s/2),
        new PVector(xOffset - s/4, yOffset + s/4),
        new PVector(xOffset - s/4, yOffset - s/4),
        new PVector(xOffset, yOffset - s/2),
        new PVector(xOffset, yOffset),
        new PVector(xOffset + s/2, yOffset + s/2)
      };
    case 'R':
      return new PVector[]{
        new PVector(xOffset - s/2, yOffset + s/2),
        new PVector(xOffset - s/2, yOffset - s/2),
        new PVector(xOffset + s/4, yOffset - s/2),
        new PVector(xOffset + s/4, yOffset),
        new PVector(xOffset - s/2, yOffset),
        new PVector(xOffset + s/4, yOffset + s/2)
      };
    case 'S':
      return new PVector[]{
        new PVector(xOffset + s/4, yOffset - s/2),
        new PVector(xOffset - s/4, yOffset - s/2),
        new PVector(xOffset - s/4, yOffset),
        new PVector(xOffset + s/4, yOffset),
        new PVector(xOffset + s/4, yOffset + s/2),
        new PVector(xOffset - s/4, yOffset + s/2)
      };
    case 'T':
      return new PVector[]{
        new PVector(xOffset - s/2, yOffset - s/2),
        new PVector(xOffset + s/2, yOffset - s/2),
        new PVector(xOffset, yOffset - s/2),
        new PVector(xOffset, yOffset + s/2)
      };
    case 'U':
      return new PVector[]{
        new PVector(xOffset - s/2, yOffset - s/2),
        new PVector(xOffset - s/2, yOffset + s/2),
        new PVector(xOffset + s/2, yOffset + s/2),
        new PVector(xOffset + s/2, yOffset - s/2)
      };
    case 'V':
      return new PVector[]{
        new PVector(xOffset - s/2, yOffset - s/2),
        new PVector(xOffset, yOffset + s/2),
        new PVector(xOffset + s/2, yOffset - s/2)
      };
    case 'W':
      return new PVector[]{
        new PVector(xOffset - s/2, yOffset - s/2),
        new PVector(xOffset - s/4, yOffset + s/2),
        new PVector(xOffset, yOffset - s/2),
        new PVector(xOffset + s/4, yOffset + s/2),
        new PVector(xOffset + s/2, yOffset - s/2)
      };
    case 'X':
      return new PVector[]{
        new PVector(xOffset - s/2, yOffset - s/2),
        new PVector(xOffset + s/2, yOffset + s/2),
        new PVector(xOffset + s/2, yOffset - s/2),
        new PVector(xOffset - s/2, yOffset + s/2)
      };
    case 'Y':
      return new PVector[]{
        new PVector(xOffset - s/2, yOffset - s/2),
        new PVector(xOffset, yOffset),
        new PVector(xOffset + s/2, yOffset - s/2),
        new PVector(xOffset, yOffset),
        new PVector(xOffset, yOffset + s/2)
      };
    case 'Z':
      return new PVector[]{
        new PVector(xOffset - s/2, yOffset - s/2),
        new PVector(xOffset + s/2, yOffset - s/2),
        new PVector(xOffset - s/2, yOffset + s/2),
        new PVector(xOffset + s/2, yOffset + s/2)
      };
    default:
      return new PVector[]{new PVector(xOffset, yOffset)};
  }
}
