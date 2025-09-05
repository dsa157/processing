// Tiling with Predefined Shapes - Dynamic & Complex
// by Processing.org

// Global parameters
final int SEED = 12345;
final int PADDING = 40;
final boolean INVERT_BACKGROUND = false;
final int MAX_FRAMES = 600;
final boolean SAVE_FRAMES = false;
final int ANIMATION_SPEED = 500;

// Tiling parameters
final int COLS = 12;
final int ROWS = 12;
final float STROKE_WEIGHT = 2;
final float STROKE_WEIGHT_SMALL = 1;
final float OBJECT_SCALE = 4;

// Colors
final color BG_LIGHT = #FFFFFF;
final color BG_DARK = #000000;
final color STROKE_LIGHT = #000000;
final color STROKE_DARK = #FFFFFF;
final color COLOR_A = #FF69B4; // Pink
final color COLOR_B = #FFD700; // Gold
final color COLOR_C = #00BFFF; // DeepSkyBlue

Tile[][] tiles;
float tileWidth;
float tileHeight;

void settings() {
  size(480, 800);
}

void setup() {
  randomSeed(SEED);
  frameRate(ANIMATION_SPEED);
  
  if (INVERT_BACKGROUND) {
    background(BG_DARK);
    stroke(STROKE_DARK);
  } else {
    background(BG_LIGHT);
    stroke(STROKE_LIGHT);
  }

  tileWidth = (width - PADDING * 2.0) / COLS;
  tileHeight = (height - PADDING * 2.0) / ROWS;
  tiles = new Tile[COLS][ROWS];

  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      tiles[x][y] = new Tile(x * tileWidth + PADDING, y * tileHeight + PADDING, tileWidth, tileHeight);
    }
  }
}

void draw() {
  if (INVERT_BACKGROUND) {
    background(BG_DARK);
  } else {
    background(BG_LIGHT);
  }

  for (int x = 0; x < COLS; x++) {
    for (int y = 0; y < ROWS; y++) {
      tiles[x][y].update();
      tiles[x][y].display();
    }
  }

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

class Tile {
  float x, y, w, h;
  int type;
  float rotation;
  float rotationSpeed;
  
  // Dynamic element
  float colorHue;
  float hueSpeed;

  Tile(float _x, float _y, float _w, float _h) {
    x = _x;
    y = _y;
    w = _w;
    h = _h;
    
    type = floor(random(7)); // More tile types
    rotation = floor(random(4)) * 90;
    rotationSpeed = random(-0.5, 0.5); // Slower, subtle rotation

    colorMode(HSB, 360, 100, 100);
    colorHue = random(360);
    hueSpeed = random(0.1, 0.5);
  }

  void update() {
    rotation += rotationSpeed;
    colorHue = (colorHue + hueSpeed) % 360;
  }

  void display() {
    pushMatrix();
    translate(x + w / 2, y + h / 2);
    rotate(radians(rotation));
    scale(OBJECT_SCALE);
    translate(-w / 2, -h / 2);

    strokeWeight(STROKE_WEIGHT / OBJECT_SCALE);
    
    color c1 = color(colorHue, 80, 80);
    color c2 = color((colorHue + 120) % 360, 80, 80);
    color c3 = color((colorHue + 240) % 360, 80, 80);

    switch(type) {
    case 0:
      // Wavy lines with dynamic color dots
      noFill();
      strokeWeight(STROKE_WEIGHT / OBJECT_SCALE);
      line(0, h/2, w, h/2);
      strokeWeight(STROKE_WEIGHT_SMALL / OBJECT_SCALE);
      line(w/4, 0, w/4, h);
      line(3*w/4, 0, 3*w/4, h);
      
      noStroke();
      fill(c1);
      ellipse(w/2, h/2, w/4, w/4);
      break;

    case 1:
      // Half-circles and quarter circles with dynamic color
      noFill();
      strokeWeight(STROKE_WEIGHT / OBJECT_SCALE);
      arc(0, h/2, w, h, PI, TWO_PI);
      arc(w, h/2, w, h, 0, PI);
      
      strokeWeight(STROKE_WEIGHT_SMALL / OBJECT_SCALE);
      noStroke();
      fill(c2);
      triangle(0, h/2, w/2, h, w, h/2);
      break;
      
    case 2:
      // Spiral with line
      noFill();
      strokeWeight(STROKE_WEIGHT / OBJECT_SCALE);
      arc(w/2, h/2, w, h, PI, TWO_PI);
      arc(w/2, h/2, w/2, h/2, TWO_PI, PI);
      line(w/2, h/2, w/2, 0);
      
      noStroke();
      fill(c3);
      ellipse(w/2, 0, w/4, w/4);
      break;
      
    case 3:
      // Complex intersecting arcs and squares
      noFill();
      strokeWeight(STROKE_WEIGHT / OBJECT_SCALE);
      arc(0, 0, w, h, 0, HALF_PI);
      arc(w, h, w, h, PI, PI+HALF_PI);
      
      noStroke();
      fill(c1);
      rect(w/4, h/4, w/2, h/2);
      break;
      
    case 4:
      // Star with dynamic points
      noFill();
      strokeWeight(STROKE_WEIGHT / OBJECT_SCALE);
      beginShape();
      float starRadius1 = w/2 * (1 + sin(frameCount * 0.05) * 0.1); // Dynamic radius
      float starRadius2 = w/4 * (1 + cos(frameCount * 0.05) * 0.1);
      for (int i = 0; i < 5; i++) {
        float angle1 = radians(i * 72 - 90);
        float angle2 = radians(i * 72 - 90 + 36);
        vertex(w/2 + cos(angle1) * starRadius1, h/2 + sin(angle1) * starRadius1);
        vertex(w/2 + cos(angle2) * starRadius2, h/2 + sin(angle2) * starRadius2);
      }
      endShape(CLOSE);
      break;

    case 5:
      // Intersecting lines with dynamic color circles
      strokeWeight(STROKE_WEIGHT / OBJECT_SCALE);
      line(0, 0, w, h);
      line(w, 0, 0, h);
      
      noStroke();
      fill(c2);
      ellipse(w/2, h/2, w/4, h/4);
      break;
      
    case 6:
      // Asymmetric shapes with dynamic fills
      noFill();
      strokeWeight(STROKE_WEIGHT / OBJECT_SCALE);
      arc(0, h, w*2, h*2, PI + HALF_PI, TWO_PI);
      
      noStroke();
      fill(c3);
      triangle(w/2, 0, w, h/2, w, 0);
      fill(c1);
      rect(0, h/2, w/4, h/4);
      break;
    }

    popMatrix();
  }
}
