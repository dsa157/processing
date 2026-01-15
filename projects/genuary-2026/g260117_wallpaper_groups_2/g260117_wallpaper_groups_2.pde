/**
 * Scalene Wallpaper Group Morpher - Offset Edition
 * Version: 2026.01.11.14.33.45
 * * Fixed p1 vs pg ambiguity by offsetting the motif from the cell center.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480; 
int SKETCH_HEIGHT = 800;
int PADDING = 40;
int MAX_FRAMES = 1200;
boolean SAVE_FRAMES = false;
int ANIMATION_SPEED = 60;
int SEED = 777;
boolean INVERT_BACKGROUND = false;
int PALETTE_INDEX = 1;

// --- Group Selection ---
String[] GROUPS_TO_INCLUDE_TEST = { "p1", "pg", "p2", "pm", "p4m", "p6m" }; // Limited for testing fix
String[] GROUPS_TO_INCLUDE = {
  "p1", "p2", "pg", "pm", "cm", "pmm", "pmg", "cmm", "p4", 
  "pgg", "p4g", "p4m", "p3", "p6", "p3m1", "p6m", "p31m"
};

// --- Visual Customization ---
boolean ENABLE_BLUR = true;
int BLUR_STRENGTH = 35;
boolean INTERPOLATE_COLOR = false;
String FONT_NAME = "Arial Black";
int FONT_SIZE = 145;
float TEXT_Y_POS = 400;
int TEXT_OPACITY = 10;
float CELL_SIZE = 140.0;
float TRANSITION_DURATION = 0.5;
float HOLD_DURATION = 0.5;

// --- IMPORTANT FIX PARAMETER ---
float MOTIF_OFFSET = 25.0; // 25.0 - Offsets the motif to reveal glide/mirror operations

// --- Internal State ---
int[][] PALETTES = {
  {#264653, #2a9d8f, #e9c46a, #f4a261, #e76f51}, 
  {#001219, #005f73, #0a9396, #94d2bd, #e9d8a6}, 
  {#5f0f40, #9a031e, #fb8b24, #e36414, #0f4c5c}, 
  {#22223b, #4a4e69, #9a8c98, #c9ada7, #f2e9e4}, 
  {#118ab2, #073b4c, #06d6a0, #ffd166, #ef476f}  
};

int activeBG, activeStroke;
ArrayList<GroupState> states;
int currentIdx = 0, nextIdx = 1;
float progress = 0;
PFont labelFont;

void settings() { size(SKETCH_WIDTH, SKETCH_HEIGHT); }

void setup() {
  randomSeed(SEED);
  frameRate(ANIMATION_SPEED);
  int[] palette = PALETTES[PALETTE_INDEX];
  activeBG = INVERT_BACKGROUND ? palette[4] : palette[0];
  activeStroke = INVERT_BACKGROUND ? palette[0] : palette[4];
  labelFont = createFont(FONT_NAME, FONT_SIZE);
  states = new ArrayList<GroupState>();
  
  Object[][] masterList = {
    {"p1", 1f, 0f, 0f},     {"p2", 2f, 0f, 0f},    {"pm", 1f, 1f, 0f}, 
    {"pg", 1f, 0f, 1f},     {"cm", 1f, 1f, 0.5f},  {"pmm", 2f, 1f, 0f}, 
    {"pmg", 2f, 1f, 0.5f},  {"pgg", 2f, 0f, 1f},   {"cmm", 2f, 1f, 1f},
    {"p4", 4f, 0f, 0f},     {"p4m", 4f, 1f, 0f},   {"p4g", 4f, 1f, 0.5f}, 
    {"p3", 3f, 0f, 0f},     {"p3m1", 3f, 1f, 0f},  {"p31m", 3f, 1f, 0.2f}, 
    {"p6", 6f, 0f, 0f},     {"p6m", 6f, 1f, 0f}
  };

  for (String target : GROUPS_TO_INCLUDE) {
    for (Object[] row : masterList) {
      if (target.equals(row[0])) {
        states.add(new GroupState((String)row[0], (float)row[1], (float)row[2], (float)row[3]));
      }
    }
  }
}

void draw() {
  if (ENABLE_BLUR) {
    fill(activeBG, BLUR_STRENGTH);
    noStroke();
    rect(0, 0, width, height);
  } else {
    background(activeBG);
  }
  
  updateTimer();
  drawFadingLabels();

  GroupState s1 = states.get(currentIdx);
  GroupState s2 = states.get(nextIdx);
  
  float curRot = lerp(s1.folds, s2.folds, progress);
  float curMir = lerp(s1.mirror, s2.mirror, progress);
  float curGld = lerp(s1.glide, s2.glide, progress);
  
  int drawColor = activeStroke;
  if (INTERPOLATE_COLOR) {
    int[] p = PALETTES[PALETTE_INDEX];
    drawColor = lerpColor(p[1], p[3], progress);
  }

  float offsetX = (width % CELL_SIZE) / 2.0;
  float offsetY = (height % CELL_SIZE) / 2.0;

  pushMatrix();
  translate(offsetX, offsetY);
  for (float x = -CELL_SIZE; x <= width + CELL_SIZE; x += CELL_SIZE) {
    for (float y = -CELL_SIZE; y <= height + CELL_SIZE; y += CELL_SIZE) {
      pushMatrix();
      translate(x, y);
      drawGroup(curRot, curMir, curGld, drawColor);
      popMatrix();
    }
  }
  popMatrix();

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void updateTimer() {
  float total = TRANSITION_DURATION + HOLD_DURATION;
  float tCycle = (frameCount / (float)ANIMATION_SPEED) % total;
  if (tCycle > HOLD_DURATION) {
    float t = (tCycle - HOLD_DURATION) / TRANSITION_DURATION;
    progress = 0.5 - 0.5 * cos(PI * t); 
  } else {
    if (progress > 0.9) {
      currentIdx = nextIdx;
      nextIdx = (currentIdx + 1) % states.size();
    }
    progress = 0;
  }
}

void drawGroup(float rot, float mir, float gld, int c) {
  stroke(c);
  strokeWeight(2.5);
  for (int i = 0; i < 6; i++) {
    if (i < rot) {
      pushMatrix();
      rotate(i * (TWO_PI / rot));
      
      // Base Motif with offset
      pushMatrix();
      translate(MOTIF_OFFSET, 0); 
      renderUnifiedMotif(c);
      popMatrix();

      // Symmetrized Motif (Glide/Mirror)
      if (mir > 0.01 || gld > 0.01) {
        pushMatrix();
        scale(mir > 0.01 ? -1 : 1, 1);
        translate(MOTIF_OFFSET, CELL_SIZE * gld * 0.5); // Glide is 0.5 shift
        renderUnifiedMotif(c);
        popMatrix();
      }
      popMatrix();
    }
  }
}

void renderUnifiedMotif(int c) {
  float b = CELL_SIZE * 0.3; 
  float x1=0, y1=-b, x2=-b*0.4, y2=b*0.7, x3=b*0.9, y3=b*0.5;
  noFill(); stroke(c);
  triangle(x1, y1, x2, y2, x3, y3);
  fill(c); noStroke();
  ellipse(x1, y1, b*0.3, b*0.3);
}

void drawFadingLabels() {
  textFont(labelFont);
  textAlign(CENTER, CENTER);
  float alphaOut = (1.0 - progress) * TEXT_OPACITY;
  float alphaIn = progress * TEXT_OPACITY;
  fill(activeStroke, alphaOut);
  text(states.get(currentIdx).name.toUpperCase(), width/2, TEXT_Y_POS);
  fill(activeStroke, alphaIn);
  text(states.get(nextIdx).name.toUpperCase(), width/2, TEXT_Y_POS);
}

class GroupState {
  String name;
  float folds, mirror, glide;
  GroupState(String n, float f, float m, float g) { name = n; folds = f; mirror = m; glide = g; }
}
