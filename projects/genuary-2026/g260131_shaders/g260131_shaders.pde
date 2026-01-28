/**
 * Molten Topography
 * Version: 2026.01.28.13.41.05
 * A shader-based exploration of domain warping to simulate heat-map aesthetics.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;      // Default 480
int SKETCH_HEIGHT = 800;     // Default 800
int SEED = 12345;            // Global seed
int PADDING = 40;            // Padding around the sketch
int MAX_FRAMES = 900;        // Max frames for saving
boolean SAVE_FRAMES = false; // Save frames toggle
int ANIMATION_SPEED = 30;    // Frame rate
int PALETTE_INDEX = 0;       // Choose 0-4
boolean INVERT_BG = false;   // Invert background logic
boolean SHOW_GRID = false;   // (Not applicable for full-screen shader, but included per spec)

// Color Palettes (Adobe Color / Kuler inspired)
String[][] PALETTES = {
  {"#1B1B1B", "#FF4E50", "#FC913A", "#F9D423", "#EDE574"}, // Volcanic
  {"#0F2027", "#203A43", "#2C5364", "#32AFA9", "#F1F1F1"}, // Deep Sea Thermal
  {"#2D033B", "#810CA8", "#C147E9", "#E5B8F4", "#FFFFFF"}, // Neon Plasma
  {"#1A1A1D", "#662483", "#950740", "#C3073F", "#4E4E50"}, // Brutalist Heat
  {"#000000", "#123456", "#789ABC", "#DEF012", "#FFFFFF"}  // Abstract Contrast
};

PShader moltenShader;
float time = 0;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT, P2D);
}

void setup() {
  frameRate(ANIMATION_SPEED);
  randomSeed(SEED);
  
  // Initialize Shader
  moltenShader = loadShader("shader.frag");
  
  // Set constant uniforms
  moltenShader.set("resolution", (float)width, (float)height);
  moltenShader.set("padding", (float)PADDING);
  
  // Handle Palette
  String[] activePalette = PALETTES[PALETTE_INDEX];
  color bg = unhex("FF" + activePalette[0].substring(1));
  if (INVERT_BG) bg = color(255 - red(bg), 255 - green(bg), 255 - blue(bg));
  
  // Pass palette to shader
  for (int i = 0; i < 5; i++) {
    int c = unhex("FF" + activePalette[i].substring(1));
    moltenShader.set("palette" + i, red(c)/255.0, green(c)/255.0, blue(c)/255.0);
  }
}

void draw() {
  background(0); // Handled by shader
  
  time += 0.01;
  moltenShader.set("time", time);
  
  shader(moltenShader);
  rect(PADDING, PADDING, width - PADDING*2, height - PADDING*2);
  resetShader();

  // Export and Loop Control
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}
