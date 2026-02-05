/*
 * Dynamic Particle Clock - Initial Glow Fix
 * Version: 2026.02.05.14.30.00
 * * --- Logic Overview ---
 * 1. Typography: A 3D array [digit][row][col] provides a 1:1 visual map of the clock.
 * 2. State Machine: 
 * - Phase 0 (Scatter): Particles explode from their current positions.
 * - Phase 1 (Coalesce): Particles lerp toward the next time's target grid.
 * - Phase 2 (Display): Particles lock to the grid; colons pulse at 1Hz.
 * 3. Ghosting Fix: Every frame, all particle 'active' states are reset before targets are assigned.
 * 4. Time Formatting: Zero-padding is enforced on HH, mm, and ss via nf().
 */

// --- Configuration Parameters ---
int SKETCH_WIDTH = 480;    
int SKETCH_HEIGHT = 800;   
int PADDING = 0;           // No internal padding for maximum digit scale
int MAX_FRAMES = 900;      
boolean SAVE_FRAMES = false; 
int ANIMATION_SPEED = 60;  // FPS
int GLOBAL_SEED = 42;      

// --- Toggle Features ---
boolean ENABLE_TRAILS = true;   // Enables semi-transparent background wipes
boolean ENABLE_PARALLAX = true; // Background stars drift downward
boolean INVERT_BG = false;       // Flips background/foreground color logic
boolean USE_24HOUR = false;      // false = 12hr (with padding), true = 24hr

// --- Timing and Visuals ---
float TIME_SCATTER = 3.0;  // Duration of explosion phase
float TIME_COALESCE = 2.0; // Duration of movement to target
float TIME_DISPLAY = 10.0; // Duration of static time display
float GLOW_ALPHA = 10.0;   // Transparency of the outer glow ellipse

// --- Background and Scaling ---
int BG_PARTICLE_COUNT = 500;    // Number of parallax stars
float BG_PARTICLE_SIZE = 5.0;   
float PARALLAX_SPEED = 0.05;    
float GRID_CELL_SIZE = 9.0;    // Horizontal/Vertical spacing of digit dots
float PARTICLE_SIZE = 7.0;     // Diameter of individual time particles
float DATE_V_OFFSET = 80.0;    // Vertical distance from center for the date string
int PALETTE_INDEX = 2;         // Initial palette (0-4)

// --- Vivid Color Palettes ---
// Format: {Background, Primary 1, Primary 2, Primary 3, Primary 4}
String[][] PALETTES = {
  {"#0A0A0A", "#FF0000", "#FF4F00", "#FF8D00", "#FFFB00"}, // 0: Solar Fire
  {"#050505", "#00FF00", "#00FF9F", "#00EFFF", "#007BFF"}, // 1: Cyber Electric
  {"#000000", "#FF00FF", "#9D00FF", "#4900FF", "#00FFFF"}, // 2: Synthwave (Default)
  {"#0A0500", "#FFFF00", "#FFD700", "#FFA500", "#FF4500"}, // 3: Molten Gold
  {"#050A05", "#ADFF2F", "#32CD32", "#00FA9A", "#00CED1"}  // 4: Acid Green
};

// --- Internal Variables ---
ArrayList<Particle> particles = new ArrayList<Particle>();
PVector[] bgStars;
float[] starSpeeds;
int currentPhase = 2; 
float phaseTimer = 0.01; // Tiny offset to trigger initial state logic
color[] activePalette;
color targetThemeColor;
color currentInterpColor;
int currentPaletteIdx;
float textAlpha = 0;

/*
 * EXPLICIT BINARY MATRIX (7 rows x 5 columns)
 * 1 = Pixel On (X), 0 = Pixel Off (.)
 * This visual map allows for direct editing of digit shapes.
 */
int[][][] font = {
  { // 0: Rounded Oval
    {0,1,1,1,0},
    {1,0,0,0,1},
    {1,0,0,0,1},
    {1,0,0,0,1},
    {1,0,0,0,1},
    {1,0,0,0,1},
    {0,1,1,1,0}
  },
  { // 1: Pillar
    {0,0,1,0,0},
    {0,1,1,0,0},
    {0,0,1,0,0},
    {0,0,1,0,0},
    {0,0,1,0,0},
    {0,0,1,0,0},
    {0,1,1,1,0}
  },
  { // 2: Rounded S-Reverse
    {0,1,1,1,0},
    {1,0,0,0,1},
    {0,0,0,0,1},
    {0,0,0,1,0},
    {0,0,1,0,0},
    {0,1,0,0,0},
    {1,1,1,1,1}
  },
  { // 3: Rounded Arches
    {0,1,1,1,0},
    {1,0,0,0,1},
    {0,0,0,0,1},
    {0,0,1,1,0},
    {0,0,0,0,1},
    {1,0,0,0,1},
    {0,1,1,1,0}
  },
  { // 4: Calibrated Diagonal (Matched to user reference)
    {0,0,0,1,0},
    {0,0,1,1,0},
    {0,1,0,1,0},
    {1,0,0,1,0},
    {1,1,1,1,1},
    {0,0,0,1,0},
    {0,0,0,1,0}
  },
  { // 5: Rounded S-Shape
    {1,1,1,1,1},
    {1,0,0,0,0},
    {1,1,1,1,0},
    {0,0,0,0,1},
    {0,0,0,0,1},
    {1,0,0,0,1},
    {0,1,1,1,0}
  },
  { // 6: Rounded G-Shape
    {0,1,1,1,0},
    {1,0,0,0,0},
    {1,1,1,1,0},
    {1,0,0,0,1},
    {1,0,0,0,1},
    {1,0,0,0,1},
    {0,1,1,1,0}
  },
  { // 7: Diagonal Spine
    {1,1,1,1,1},
    {0,0,0,0,1},
    {0,0,0,1,0},
    {0,0,1,0,0},
    {0,1,0,0,0},
    {1,0,0,0,0},
    {1,0,0,0,0}
  },
  { // 8: Figure Eight
    {0,1,1,1,0},
    {1,0,0,0,1},
    {1,0,0,0,1},
    {0,1,1,1,0},
    {1,0,0,0,1},
    {1,0,0,0,1},
    {0,1,1,1,0}
  },
  { // 9: Rounded P-Shape
    {0,1,1,1,0},
    {1,0,0,0,1},
    {1,0,0,0,1},
    {0,1,1,1,1},
    {0,0,0,0,1},
    {1,0,0,0,1},
    {0,1,1,1,0}
  }
};

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(GLOBAL_SEED);
  frameRate(ANIMATION_SPEED);
  
  // Initialize colors immediately to prevent background flash on startup
  currentPaletteIdx = PALETTE_INDEX;
  activePalette = new color[5];
  for (int i = 0; i < 5; i++) {
    activePalette[i] = unhex("FF" + PALETTES[currentPaletteIdx][i].substring(1));
  }
  targetThemeColor = activePalette[floor(random(1, 5))];
  currentInterpColor = targetThemeColor;
  
  // Setup Background Stars for parallax
  bgStars = new PVector[BG_PARTICLE_COUNT];
  starSpeeds = new float[BG_PARTICLE_COUNT];
  for (int i = 0; i < BG_PARTICLE_COUNT; i++) {
    bgStars[i] = new PVector(random(width), random(height));
    starSpeeds[i] = random(0.5, 2.0) * PARALLAX_SPEED;
  }

  // Pre-fill particle buffer (enough for 6 digits + 2 colons)
  for (int i = 0; i < 800; i++) {
    particles.add(new Particle());
  }
  
  // Ensure targets are set for the initial display frame
  updateTargets();
}

void initPaletteColors() {
  // Update the theme when phases cycle
  for (int i = 0; i < 5; i++) {
    activePalette[i] = unhex("FF" + PALETTES[currentPaletteIdx][i].substring(1));
  }
  targetThemeColor = activePalette[floor(random(1, 5))];
}

void draw() {
  // Calculate Background
  color bg = activePalette[0];
  if (INVERT_BG) bg = color(255 - red(bg), 255 - green(bg), 255 - blue(bg));
  
  // Apply trails if toggled
  if (ENABLE_TRAILS) {
    noStroke();
    fill(bg, 55); 
    rect(0, 0, width, height);
  } else {
    background(bg);
  }
  
  // Smooth color shifting
  currentInterpColor = lerpColor(currentInterpColor, targetThemeColor, 0.04);
  
  drawBackground();
  updatePhases();
  updateTargets();
  
  // Process particles
  for (Particle p : particles) {
    p.update();
    p.display();
  }
  
  // Date is only visible in display phase
  if (currentPhase == 2) drawDate();
}

void drawBackground() {
  noStroke();
  fill(255, 15); 
  for (int i = 0; i < BG_PARTICLE_COUNT; i++) {
    if (ENABLE_PARALLAX) {
      bgStars[i].y += starSpeeds[i];
      if (bgStars[i].y > height) bgStars[i].y = 0;
    }
    ellipse(bgStars[i].x, bgStars[i].y, BG_PARTICLE_SIZE, BG_PARTICLE_SIZE);
  }
}

void drawDate() {
  textAlpha = lerp(textAlpha, 255, 0.05);
  if (textAlpha > 1) {
    textAlign(CENTER, CENTER);
    java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("MM/dd/yyyy");
    java.text.SimpleDateFormat dayName = new java.text.SimpleDateFormat("EEEE");
    java.util.Date now = new java.util.Date();
    String dateStr = dayName.format(now).toUpperCase() + "  " + sdf.format(now);
    
    fill(currentInterpColor, textAlpha);
    textSize(14);
    text(dateStr, width/2, (height/2) + DATE_V_OFFSET);
  }
}

void updatePhases() {
  phaseTimer += 1.0 / ANIMATION_SPEED;
  float threshold = (currentPhase == 0) ? TIME_SCATTER : (currentPhase == 1) ? TIME_COALESCE : TIME_DISPLAY;
  
  if (phaseTimer >= threshold) {
    phaseTimer = 0;
    currentPhase = (currentPhase + 1) % 3;
    
    // On phase 0, trigger explosion and change colors
    if (currentPhase == 0) {
      textAlpha = 0;
      currentPaletteIdx = (currentPaletteIdx + 1) % PALETTES.length;
      initPaletteColors();
      for (Particle p : particles) p.prepareExplosion();
    }
  }
}

void updateTargets() {
  // Handle 12/24 hour conversion
  int h = hour();
  if (!USE_24HOUR) {
    h = h % 12;
    if (h == 0) h = 12;
  }
  
  // String format with mandatory zero padding
  String timeStr = nf(h, 2) + ":" + nf(minute(), 2) + ":" + nf(second(), 2);
  
  float charWidth = 5 * GRID_CELL_SIZE;
  float charSpacing = GRID_CELL_SIZE * 1.5; 
  float totalWidth = (6 * charWidth) + (2 * (3 * GRID_CELL_SIZE)) + (7 * charSpacing);
  float startX = (width - totalWidth) / 2;
  float startY = (height - (7 * GRID_CELL_SIZE)) / 2;
  
  int pIdx = 0;
  // CRITICAL: Set all particles to inactive to clear the previous digit's buffer
  for (Particle p : particles) p.active = false;

  for (int i = 0; i < timeStr.length(); i++) {
    char c = timeStr.charAt(i);
    float xOff = getCharOffset(i, charWidth, charSpacing);
    if (c == ':') {
      pIdx = setTargetColon(startX + xOff, startY, pIdx, GRID_CELL_SIZE);
    } else {
      pIdx = setTargetDigit(Character.getNumericValue(c), startX + xOff, startY, pIdx, GRID_CELL_SIZE);
    }
  }
}

float getCharOffset(int charIdx, float cw, float cs) {
  float offset = 0;
  for (int i = 0; i < charIdx; i++) {
    if (i == 2 || i == 5) offset += (3 * GRID_CELL_SIZE) + cs;
    else offset += cw + cs;
  }
  return offset;
}

int setTargetDigit(int d, float x, float y, int pIdx, float space) {
  for (int r = 0; r < 7; r++) {
    for (int c = 0; c < 5; c++) {
      if (font[d][r][c] == 1) {
        if (pIdx < particles.size()) {
          particles.get(pIdx).setTarget(x + c * space, y + r * space, false);
          particles.get(pIdx).active = true;
          pIdx++;
        }
      }
    }
  }
  return pIdx;
}

int setTargetColon(float x, float y, int pIdx, float space) {
  int[] rows = {1, 5}; // Vertical dots for the colon
  for (int r : rows) {
    if (pIdx < particles.size()) {
      particles.get(pIdx).setTarget(x + space, y + r * space, true);
      particles.get(pIdx).active = true;
      pIdx++;
    }
  }
  return pIdx;
}

class Particle {
  PVector pos, vel, acc, target, startPos;
  boolean active = false;
  boolean isColon = false;

  Particle() {
    pos = new PVector(random(width), random(height));
    startPos = pos.copy();
    vel = new PVector(0, 0);
    acc = new PVector(0, 0);
    target = pos.copy();
  }

  void setTarget(float tx, float ty, boolean colon) {
    target.set(tx, ty);
    isColon = colon;
  }

  void prepareExplosion() {
    PVector burst = PVector.random2D().mult(random(15, 28));
    vel.set(burst);
    startPos.set(pos);
  }

  void update() {
    if (currentPhase == 0) { // Scatter: Physics simulation
      acc.add(PVector.random2D().mult(0.4));
      vel.add(acc);
      pos.add(vel);
      acc.mult(0);
      vel.mult(0.94);
    } else if (currentPhase == 1) { // Coalesce: Quadratic easing toward target
      float pct = phaseTimer / TIME_COALESCE;
      float ease = 1 - pow(1 - pct, 4); 
      if (pct == 0) startPos.set(pos); 
      pos.x = lerp(startPos.x, target.x, ease);
      pos.y = lerp(startPos.y, target.y, ease);
    } else { // Display: Rigid positioning
      pos.set(target);
      vel.set(0, 0);
    }
  }

  void display() {
    if (!active && currentPhase != 0) return;
    
    float renderSize = PARTICLE_SIZE;
    // Apply pulsing to colons in display phase
    if (isColon && currentPhase == 2) {
      float pulse = sin((millis() % 1000) / 1000.0 * PI);
      renderSize += (pulse * 3.0) - 1.5;
    }
    
    noStroke();
    fill(currentInterpColor, GLOW_ALPHA);
    ellipse(pos.x, pos.y, renderSize * 3.5, renderSize * 3.5);
    fill(currentInterpColor);
    ellipse(pos.x, pos.y, renderSize, renderSize);
  }
}
