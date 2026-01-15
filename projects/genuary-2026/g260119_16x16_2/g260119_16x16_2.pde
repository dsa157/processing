/*
 * Flow Field Voxels - Seamless Y-Rotation
 * Version: 2026.01.11.16.45.15
 * Description: 16x16 grid with a seamless looping noise field and optional
 * full Y-axis rotation over the loop duration.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;      // default: 480
int SKETCH_HEIGHT = 800;     // default: 800
int PADDING = 40;            // default: 40
int MAX_FRAMES = 900;        // default: 900
boolean SAVE_FRAMES = false; // default: false
int ANIMATION_SPEED = 30;    // default: 30
long GLOBAL_SEED = 12345;    // default: 12345

int LOOP_LENGTH = 180;       // default: 180 (frames per seamless loop)
int GRID_RES = 16;           // default: 16
float NOISE_SCALE = 0.006;   // default: 0.006
boolean SHOW_GRID = false;   // default: false
boolean INVERT_BG = false;   // default: false

// Effect Toggles & Ranges
boolean ENABLE_WAVE = true;       // default: true
boolean ENABLE_Y_ROTATION = false; // default: true (Full 360 degree cycle)
float WAVE_AMPLITUDE = 100.0;     // default: 100.0
float SIZE_MIN = 0.45;            // default: 0.45
float SIZE_MAX = 0.9;             // default: 0.9
float OUTER_MOTION_MULT = 2.5;    // default: 2.5

// Color Palettes
int PALETTE_INDEX = 1;       
int[][] PALETTES = {
  {#264653, #2a9d8f, #e9c46a, #f4a261, #e76f51}, 
  {#001219, #005f73, #0a9396, #94d2bd, #e9d8a6}, 
  {#5f0f40, #9a031e, #fb8b24, #e36414, #0f4c5c}, 
  {#22223b, #4a4e69, #9a8c98, #c9ada7, #f2e9e4}, 
  {#011627, #fdfffc, #2ec4b6, #e71d36, #ff9f1c}  
};

// --- Internal Variables ---
float cellSize;
float gridWidth;
int[][] colorIndices;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT, P3D);
}

void setup() {
  randomSeed(GLOBAL_SEED);
  noiseSeed(GLOBAL_SEED);
  frameRate(ANIMATION_SPEED);
  
  gridWidth = SKETCH_WIDTH - (PADDING * 2);
  cellSize = gridWidth / GRID_RES;
  
  colorIndices = new int[GRID_RES][GRID_RES];
  for (int i = 0; i < GRID_RES; i++) {
    for (int j = 0; j < GRID_RES; j++) {
      if (INVERT_BG) {
        colorIndices[i][j] = (int)random(0, 4); 
      } else {
        colorIndices[i][j] = (int)random(1, 5);
      }
    }
  }
}

void draw() {
  int[] currentPalette = PALETTES[PALETTE_INDEX];
  int bgColor = INVERT_BG ? currentPalette[currentPalette.length - 1] : currentPalette[0];
  background(bgColor);
  
  // Calculate seamless loop progress
  float percent = (float)(frameCount % LOOP_LENGTH) / LOOP_LENGTH;
  float angleLoop = TWO_PI * percent;
  
  // Circular offsets for noise consistency
  float noiseXOffset = cos(angleLoop) * 0.5;
  float noiseYOffset = sin(angleLoop) * 0.5;

  // Global Positioning
  translate(SKETCH_WIDTH / 2, SKETCH_HEIGHT / 2);
  
  // Toggleable Y-Axis Rotation for the whole grid
  if (ENABLE_Y_ROTATION) {
    rotateY(angleLoop);
  }

  // Define lighting relative to the camera, not the rotating grid
  pointLight(255, 255, 255, 200, -200, 400);
  directionalLight(150, 150, 150, -1, 1, -1);
  ambientLight(50, 50, 50);

  float maxDist = gridWidth / sqrt(2);

  for (int i = 0; i < GRID_RES; i++) {
    for (int j = 0; j < GRID_RES; j++) {
      float x = (i * cellSize) - (gridWidth / 2) + (cellSize / 2);
      float y = (j * cellSize) - (gridWidth / 2) + (cellSize / 2);
      
      float distToCenter = dist(x, y, 0, 0);
      float normDist = map(distToCenter, 0, maxDist, 0, 1);
      
      // Multi-dimensional seamless noise
      float noiseVal = noise(
        x * NOISE_SCALE + noiseXOffset, 
        y * NOISE_SCALE + noiseYOffset, 
        noiseXOffset
      );
      
      // Rotation sensitivity increases toward edges
      float motionSens = map(normDist, 0, 1, 2.0, 2.0 * OUTER_MOTION_MULT);
      float rotationAngle = noiseVal * TWO_PI * motionSens;
      
      // Z-Wave effect
      float z = 0;
      if (ENABLE_WAVE) {
        z = sin(noiseVal * PI + angleLoop) * WAVE_AMPLITUDE * normDist;
      }
      
      // Scaling based on center proximity
      float scaleFactor = lerp(SIZE_MAX, SIZE_MIN, normDist);
      
      pushMatrix();
      translate(x, y, z);
      
      if (SHOW_GRID) {
        noFill();
        stroke(currentPalette[2], 30);
        rectMode(CENTER);
        rect(0, 0, cellSize, cellSize);
      }
      
      // Individual Voxel Rotations
      rotateX(rotationAngle * 0.3);
      rotateY(rotationAngle * 0.7);
      rotateZ(rotationAngle);
      
      // Rendering
      noStroke();
      fill(currentPalette[colorIndices[i][j]]);
      box(cellSize * scaleFactor);
      
      popMatrix();
    }
  }

  // --- Frame Management ---
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}
