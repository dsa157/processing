/**
 * Wallpaper Group Morpher - Full Bleed Edition
 * Version: 2026.01.11.13.51.10
 * * Full bleed pattern rendering extending beyond canvas boundaries.
 * * Layered text rendering behind the symmetry groups with opacity control.
 * * Interpolated color and symmetry transitions.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480; // 480
int SKETCH_HEIGHT = 800; // 800
int PADDING = 40; // 40
int MAX_FRAMES = 525; // 900
boolean SAVE_FRAMES = true; // false
int ANIMATION_SPEED = 60; // 60
int SEED = 777; // 777
boolean SHOW_GRID = false; // false
boolean INVERT_BACKGROUND = false; // false
int PALETTE_INDEX = 1; // 1

// --- Customization ---
boolean ENABLE_BLUR = true; // true
int BLUR_STRENGTH = 35; // 35
boolean INTERPOLATE_COLOR = false; // true
int GLYPH_TYPE = 4; // 4: Triangle
String FONT_NAME = "Arial Black"; // Arial Black
int FONT_SIZE = 150; // 64
float TEXT_Y_POS = 400; // 400 (Centered vertically)
int TEXT_OPACITY = 10; // 100 (0-255)

float CELL_SIZE = 120.0; // 120.0
float TRANSITION_DURATION = 0.25; // Seconds
float HOLD_DURATION = 0.25; // Seconds

boolean[] ENABLED_GROUPS = {
  true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true
};

// --- Color Palettes ---
int[][] PALETTES = {
  {#264653, #2a9d8f, #e9c46a, #f4a261, #e76f51}, 
  {#001219, #005f73, #0a9396, #94d2bd, #e9d8a6}, 
  {#5f0f40, #9a031e, #fb8b24, #e36414, #0f4c5c}, 
  {#22223b, #4a4e69, #9a8c98, #c9ada7, #f2e9e4}, 
  {#118ab2, #073b4c, #06d6a0, #ffd166, #ef476f}  
};

String[] GROUP_NAMES = {
  "p1", "p2", "pm", "pg", "cm", "pmm", "pmg", "pgg", "cmm", 
  "p4", "p4m", "p4g", "p3", "p3m1", "p31m", "p6", "p6m"
};

int activeBG, activeStroke;
ArrayList<GroupState> states;
ArrayList<String> activeNames;
int currentIdx = 0;
int nextIdx = 1;
float progress = 0;
PFont labelFont;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED);
  frameRate(ANIMATION_SPEED);
  
  int[] palette = PALETTES[PALETTE_INDEX];
  activeBG = INVERT_BACKGROUND ? palette[4] : palette[0];
  activeStroke = INVERT_BACKGROUND ? palette[0] : palette[4];
  
  labelFont = createFont(FONT_NAME, FONT_SIZE);
  states = new ArrayList<GroupState>();
  activeNames = new ArrayList<String>();
  
  float[][] config = {
    {1,0,0}, {2,0,0}, {1,1,0}, {1,0,1}, {1,1,0.5},
    {2,1,0}, {2,1,0.5}, {2,0,1}, {2,1,1},
    {4,0,0}, {4,1,0}, {4,1,0.5},
    {3,0,0}, {3,1,0}, {3,1,0.2},
    {6,0,0}, {6,1,0}
  };

  for (int i = 0; i < config.length; i++) {
    if (ENABLED_GROUPS[i]) {
      states.add(new GroupState(config[i][0], config[i][1], config[i][2]));
      activeNames.add(GROUP_NAMES[i]);
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

  // Draw fading labels BEHIND the wallpaper
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

  // Centering and Full Bleed Logic
  // We extend the loop range by 2 cells to ensure no gaps at edges
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
      renderGlyph(GLYPH_TYPE);
      if (mir > 0.05) {
        pushMatrix();
        scale(-1 * mir, 1);
        translate(CELL_SIZE * gld, 0);
        renderGlyph(GLYPH_TYPE);
        popMatrix();
      }
      popMatrix();
    }
  }
}

void renderGlyph(int type) {
  noFill();
  float s = CELL_SIZE * 0.22;
  switch(type) {
    case 0: // Poly
      beginShape();
      for(int i=0; i<6; i++) vertex(cos(i*TWO_PI/6)*s, sin(i*TWO_PI/6)*s);
      endShape(CLOSE);
      break;
    case 1: // Star
      beginShape();
      for(int i=0; i<10; i++) {
        float r = (i%2==0) ? s : s*0.4;
        vertex(cos(i*TWO_PI/10)*r, sin(i*TWO_PI/10)*r);
      }
      endShape(CLOSE);
      break;
    case 2: // Cross
      line(-s, -s, s, s); line(s, -s, -s, s);
      break;
    case 3: // Circles
      ellipse(0, 0, s, s); ellipse(0, 0, s*0.6, s*0.6);
      break;
    case 4: // Triangle
      triangle(0, -s, -s*0.8, s*0.8, s*0.8, s*0.8);
      break;
  }
}

void drawFadingLabels() {
  textFont(labelFont);
  textAlign(CENTER, CENTER);
  
  float baseAlpha = TEXT_OPACITY;
  float alphaOut = (1.0 - progress) * baseAlpha;
  float alphaIn = progress * baseAlpha;
  
  fill(activeStroke, alphaOut);
  text(activeNames.get(currentIdx).toUpperCase(), width/2, TEXT_Y_POS);
  
  fill(activeStroke, alphaIn);
  text(activeNames.get(nextIdx).toUpperCase(), width/2, TEXT_Y_POS);
}

class GroupState {
  float folds, mirror, glide;
  GroupState(float f, float m, float g) { folds = f; mirror = m; glide = g; }
}
