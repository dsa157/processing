/*
 * The Perfectionist's Nightmare
 * Version: 2026.01.18.09.47.12
 * 1. Uses ortho() to ensure cubes are perfectly flat to the camera at rest.
 * 2. Rogue is colored with a specific discordant Hex.
 * 3. Rogue is misaligned by position and angle at rest.
 * 4. MAX_FRAMES = 899.
 */

// --- Configuration Parameters ---
int SKETCH_WIDTH = 480;       
int SKETCH_HEIGHT = 800;      
int MAX_FRAMES = 899;         
boolean SAVE_FRAMES = false;  
int ANIMATION_SPEED = 30;     
long SEED_VALUE = 42;         

// Grid Settings
int GRID_ROWS = 25;           
int GRID_COLS = 15;           
float BOX_SIZE = 18.0;        
float SPACING = 30.0;         
int ROGUE_X = 5;              
int ROGUE_Y = 9;              

// Rogue "Nightmare" Parameters
String ROGUE_HEX = "#FF5733"; 
float ROGUE_ANGLE = 4.0;     
float ROGUE_POS_OFFSET = 3.0; 

// Animation Timing
int PAUSE_DURATION = 60;      
int CYCLE_FRAMES = 240;       

// Visual Effects
float EXPLOSION_STRENGTH = 600.0; 
int BOX_ALPHA = 255;              

boolean INVERT_COLORS = false;    
int PALETTE_INDEX = 3;            

// --- Color Palettes ---
String[][] PALETTES = {
  {"#2E294E", "#541388", "#F1E9DA", "#FFD400", "#D90368"}, 
  {"#1B1B1B", "#292929", "#F3F3F3", "#FF3562", "#FFFFFF"}, 
  {"#002626", "#0E4749", "#95C623", "#E55812", "#EFE7BC"}, 
  {"#272727", "#747474", "#FF6B6B", "#4ECDC4", "#F7FFF7"}, 
  {"#1A1A1D", "#4E4E50", "#6F2232", "#950740", "#C3073F"}  
};

// --- Internal Variables ---
color bgColor, boxColor, rogueColor;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT, P3D);
}

void setup() {
  frameRate(ANIMATION_SPEED);
  randomSeed(SEED_VALUE);
  
  String[] activePalette = PALETTES[PALETTE_INDEX];
  if (!INVERT_COLORS) {
    bgColor = unhex("FF" + activePalette[0].substring(1));
    boxColor = unhex("FF" + activePalette[2].substring(1));
  } else {
    bgColor = unhex("FF" + activePalette[2].substring(1));
    boxColor = unhex("FF" + activePalette[0].substring(1));
  }
  
  rogueColor = unhex("FF" + ROGUE_HEX.substring(1));
}

void draw() {
  background(bgColor);
  
  // Set Orthographic Projection to remove perspective distortion
  ortho(); 

  int totalCycle = CYCLE_FRAMES + PAUSE_DURATION;
  int currentCycleFrame = frameCount % totalCycle;
  
  float explosionFactor = 0;
  if (currentCycleFrame >= PAUSE_DURATION) {
    float motionProgress = map(currentCycleFrame, PAUSE_DURATION, totalCycle, 0, 1);
    explosionFactor = sin(motionProgress * PI); 
  }

  // Use simple directional lighting to show 3D form only when they tumble
  ambientLight(150, 150, 150);
  directionalLight(255, 255, 255, 0, 0, -1);
  
  float totalW = (GRID_COLS - 1) * SPACING;
  float totalH = (GRID_ROWS - 1) * SPACING;
  
  translate(width/2, height/2, 0);

  for (int y = 0; y < GRID_ROWS; y++) {
    for (int x = 0; x < GRID_COLS; x++) {
      float targetX = (x * SPACING) - totalW/2;
      float targetY = (y * SPACING) - totalH/2;
      
      randomSeed(SEED_VALUE + (x * 1337) + (y * 42));
      float randDirX = random(-1, 1) * EXPLOSION_STRENGTH;
      float randDirY = random(-1, 1) * EXPLOSION_STRENGTH;
      float randDirZ = random(-1, 1) * EXPLOSION_STRENGTH;
      
      float rogueOff = (x == ROGUE_X && y == ROGUE_Y) ? ROGUE_POS_OFFSET : 0;
      
      float curX = (targetX + rogueOff) + (randDirX * explosionFactor);
      float curY = (targetY + rogueOff) + (randDirY * explosionFactor);
      float curZ = (randDirZ * explosionFactor);
      
      pushMatrix();
      translate(curX, curY, curZ);
      
      if (x == ROGUE_X && y == ROGUE_Y) {
        rotateZ(radians(ROGUE_ANGLE) + (explosionFactor * TWO_PI));
        rotateX(explosionFactor * PI);
        fill(rogueColor);
      } else {
        rotateX(explosionFactor * TWO_PI);
        rotateY(explosionFactor * PI);
        fill(boxColor, BOX_ALPHA);
      }
      
      noStroke();
      box(BOX_SIZE);
      popMatrix();
    }
  }

  if (SAVE_FRAMES) saveFrame("frames/####.tif");
  if (frameCount >= MAX_FRAMES) noLoop();
}
