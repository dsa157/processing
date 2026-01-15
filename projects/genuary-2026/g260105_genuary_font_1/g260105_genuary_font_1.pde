/**
 * GENUARY Two-Stage Extended Decay
 * Letters fade quickly to a threshold, then slowly decay to zero for a ghosting effect.
 * Version: 2025.12.18.15.06.45
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;           // Default: 480
int SKETCH_HEIGHT = 800;          // Default: 800
int PADDING = 40;                 // Default: 40
int MAX_FRAMES = 900;             // Default: 900
boolean SAVE_FRAMES = false;      // Default: false
int ANIMATION_SPEED = 30;         // Default: 30
int SEED_VALUE = 42;              // Default: 42
boolean INVERT_BG = false;        // Default: false
boolean SHOW_GRID = false;        // Default: false

// --- Ghosting Tuning ---
float GHOST_THRESHOLD = 51.0;     // Default: 51.0 (20% of 255)
float GHOST_DECAY_FACTOR = 0.09;  // Default: 0.25 (1/4 speed decay after threshold)

// --- Grid Config ---
int COLS = 3;                     // Default: 3
int ROWS = 4;                     // Default: 4
float GRID_GUTTER = 35.0;         // Default: 35.0

// --- Visual Tuning ---
float CYCLE_SPEED = 4.0;          // Default: 6.0 (Base fade speed)
float RANDOM_SPEED_OFFSET = 0.0;  // Default: 0.0
float STROKE_WEIGHT = 5.0;        // Default: 6.0
float OSC_SIZE = 15.0;            // Default: 15.0
float OSC_SPEED = 0.08;           // Default: 0.08
float SPAWN_THRESHOLD = 150.0;    // Default: 150.0 (Trigger next letter when current is this alpha)

// --- Color Palette ---
color[] PALETTE = {
  #264653, #2a9d8f, #e9c46a, #f4a261, #e76f51
};

char[] CHARS = {'G', 'E', 'N', 'U', 'A', 'R', 'Y'};
LetterCell[] gridCells = new LetterCell[COLS * ROWS];

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  float totalGutterW = GRID_GUTTER * (COLS - 1);
  float totalGutterH = GRID_GUTTER * (ROWS - 1);
  float cellW = (width - (PADDING * 2) - totalGutterW) / COLS;
  float cellH = (height - (PADDING * 2) - totalGutterH) / ROWS;

  for (int i = 0; i < ROWS; i++) {
    for (int j = 0; j < COLS; j++) {
      float x = PADDING + j * (cellW + GRID_GUTTER);
      float y = PADDING + i * (cellH + GRID_GUTTER);
      int startIdx = (i * COLS + j) % CHARS.length;
      gridCells[i * COLS + j] = new LetterCell(startIdx, x, y, cellW, cellH);
    }
  }
}

void draw() {
  color bgColor = INVERT_BG ? color(255) - PALETTE[0] : PALETTE[0];
  background(bgColor);

  for (LetterCell lc : gridCells) {
    lc.update();
    lc.display();
  }

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

class LetterCell {
  float x, y, w, h;
  int nextCharIdx;
  ArrayList<LetterInstance> activeLetters;
  float localSpeed;

  LetterCell(int _startIdx, float _x, float _y, float _w, float _h) {
    x = _x; y = _y; w = _w; h = _h;
    nextCharIdx = _startIdx;
    activeLetters = new ArrayList<LetterInstance>();
    localSpeed = CYCLE_SPEED + random(-RANDOM_SPEED_OFFSET, RANDOM_SPEED_OFFSET);
    spawnNext(true); 
  }

  void spawnNext(boolean instant) {
    char c = CHARS[nextCharIdx];
    color col = PALETTE[int(random(1, PALETTE.length))];
    activeLetters.add(new LetterInstance(c, col, w, h, instant));
    nextCharIdx = (nextCharIdx + 1) % CHARS.length;
  }

  void update() {
    boolean triggerFound = false;
    for (int i = activeLetters.size() - 1; i >= 0; i--) {
      LetterInstance li = activeLetters.get(i);
      li.update(localSpeed);
      
      // Spawn logic: Trigger next letter if newest active letter passes alpha threshold
      if (i == activeLetters.size() - 1) {
        if (!li.fadingIn && li.alpha < SPAWN_THRESHOLD && !li.hasSpawnedNext) {
          li.hasSpawnedNext = true;
          triggerFound = true;
        }
      }
      
      if (li.isDead()) activeLetters.remove(i);
    }
    if (triggerFound) spawnNext(false);
  }

  void display() {
    pushMatrix();
    translate(x, y);
    for (LetterInstance li : activeLetters) {
      li.display();
    }
    popMatrix();
  }
}

class LetterInstance {
  char type;
  color col;
  float alpha;
  boolean fadingIn;
  boolean hasSpawnedNext = false;
  float t;
  ArrayList<PathSegment> segments;

  LetterInstance(char _type, color _col, float w, float h, boolean instant) {
    type = _type;
    col = _col;
    t = random(TWO_PI);
    alpha = instant ? 255 : 0;
    fadingIn = !instant;
    segments = new ArrayList<PathSegment>();
    buildLetter(w, h);
  }

  void buildLetter(float w, float h) {
    if (type == 'G') {
      segments.add(new PathSegment(w/2, h/2, w, h, PI*0.2, TWO_PI*0.9));
      segments.add(new PathSegment(w/2, h/2, w, h/2));
    } else if (type == 'E') {
      segments.add(new PathSegment(w, 0, 0, 0));
      segments.add(new PathSegment(0, 0, 0, h));
      segments.add(new PathSegment(0, h, w, h));
      segments.add(new PathSegment(0, h/2, w*0.7, h/2));
    } else if (type == 'N') {
      segments.add(new PathSegment(0, h, 0, 0));
      segments.add(new PathSegment(0, 0, w, h));
      segments.add(new PathSegment(w, h, w, 0));
    } else if (type == 'U') {
      segments.add(new PathSegment(0, 0, 0, h*0.7));
      segments.add(new PathSegment(w, 0, w, h*0.7));
      segments.add(new PathSegment(w/2, h*0.7, w, h*0.6, 0, PI));
    } else if (type == 'A') {
      segments.add(new PathSegment(w/2, 0, 0, h));
      segments.add(new PathSegment(w/2, 0, w, h));
      segments.add(new PathSegment(w*0.15, h*0.7, w*0.85, h*0.7));
    } else if (type == 'R') {
      segments.add(new PathSegment(0, 0, 0, h));
      segments.add(new PathSegment(w/2, h*0.3, w, h*0.6, -HALF_PI, HALF_PI));
      segments.add(new PathSegment(0, h*0.6, w, h));
    } else if (type == 'Y') {
      segments.add(new PathSegment(w/2, h, w/2, h/2));
      segments.add(new PathSegment(0, 0, w/2, h/2));
      segments.add(new PathSegment(w, 0, w/2, h/2));
    }
  }

  void update(float speed) {
    t += OSC_SPEED;
    if (fadingIn) {
      alpha += speed;
      if (alpha >= 255) { 
        alpha = 255; 
        fadingIn = false; 
      }
    } else {
      // Two-stage decay logic
      if (alpha > GHOST_THRESHOLD) {
        alpha -= speed;
      } else {
        alpha -= (speed * GHOST_DECAY_FACTOR);
      }
    }
  }

  boolean isDead() { return alpha <= 0 && !fadingIn; }

  void display() {
    for (PathSegment s : segments) {
      s.draw(col, alpha, t);
    }
  }
}

class PathSegment {
  float x1, y1, x2, y2, arcW, arcH, startA, endA;
  boolean isArc = false;

  PathSegment(float _x1, float _y1, float _x2, float _y2) {
    x1 = _x1; y1 = _y1; x2 = _x2; y2 = _y2;
  }

  PathSegment(float cx, float cy, float w, float h, float s, float e) {
    x1 = cx; y1 = cy; arcW = w; arcH = h; startA = s; endA = e;
    isArc = true;
  }

  void draw(color c, float a, float t) {
    stroke(c, a);
    strokeWeight(STROKE_WEIGHT);
    strokeCap(ROUND);
    noFill();
    float osc = (sin(t) + 1.0) / 2.0;

    if (isArc) {
      arc(x1, y1, arcW, arcH, startA, endA);
      float ang = lerp(startA, endA, osc);
      drawNode(x1 + cos(ang) * arcW/2, y1 + sin(ang) * arcH/2, c, a);
    } else {
      line(x1, y1, x2, y2);
      drawNode(lerp(x1, x2, osc), lerp(y1, y2, osc), c, a);
    }
  }

  void drawNode(float px, float py, color c, float a) {
    fill(c, a);
    noStroke();
    ellipse(px, py, OSC_SIZE, OSC_SIZE);
  }
}
