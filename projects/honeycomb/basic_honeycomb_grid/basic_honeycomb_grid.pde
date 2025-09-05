// GLOBAL PARAMETERS
int GLOBAL_SEED = 222 + millis();
int PADDING = 40;
boolean INVERT_BACKGROUND = true;
int MAX_FRAMES = 600;
boolean SAVE_FRAMES = false;
int ANIMATION_SPEED = 30; // frames

// SKETCH-SPECIFIC PARAMETERS
float HEX_SIZE = 40; // Size of each hexagon
float HEX_GAP = -10; // Configurable spacing between hexagons
float LINE_WEIGHT = 2.0;

void setup() {
  size(480, 800);
  randomSeed(GLOBAL_SEED);

  if (INVERT_BACKGROUND) {
    background(255);
  } else {
    background(0);
  }
}

void draw() {
  if (INVERT_BACKGROUND) {
    background(255);
  } else {
    background(0);
  }

  drawHexGrid();

  // Check if we need to save frames
  if (SAVE_FRAMES) {
    if (frameCount <= MAX_FRAMES) {
      saveFrame("frames/####.tif");
    } else {
      noLoop();
    }
  }
}

void drawHexGrid() {
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
    float y = startY + row * totalHexHeight;
    
    // Rows with 5 hexagons
    if (row % 2 == 0) {
      float rowWidth5 = 5 * totalHexWidth - HEX_GAP;
      float rowStartX5 = startX + (gridWidth - rowWidth5) / 2.0;
      for (int col = 0; col < 5; col++) {
        // Special case for the last row's last hexagon
        if (row == rowCount - 1 && col == 4) {
          continue; 
        }
        float x = rowStartX5 + col * totalHexWidth;
        drawHexagon(x, y, HEX_SIZE);
      }
    }
    // Rows with 6 hexagons
    else {
      for (int col = 0; col < 6; col++) {
        float x = startX + col * totalHexWidth;
        drawHexagon(x, y, HEX_SIZE);
      }
    }
  }
}



void drawHexagon(float x, float y, float s) {
  pushMatrix();
  translate(x + s, y + s / 2.0);
  strokeWeight(LINE_WEIGHT);
  stroke(0);
  noFill();

  // Draw the hexagon shape with a 30-degree offset for the point-top
  beginShape();
  for (int i = 0; i < 6; i++) {
    float angle = TWO_PI / 6 * i + PI/6;
    vertex(s * cos(angle), s * sin(angle));
  }
  endShape(CLOSE);
  
  popMatrix();
}
