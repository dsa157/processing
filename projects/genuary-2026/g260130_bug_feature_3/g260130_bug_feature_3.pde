/**
 * Bitwise Architectural Noise - Sound Reactive
 * A study in emergent structures from logical bitwise operations,
 * driven by the amplitude of an audio track.
 */

import ddf.minim.*;

// --- Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int SEED = 12345;             // Default: 12345
int MAX_FRAMES = 900;         // Calculated in setup() based on audio length
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
boolean INVERT_COLORS = false;// Default: false
boolean SHOW_GRID = false;    // Default: false

// Palettes from Adobe Color (Kuler)
String[][] PALETTES = {
  {"#2C3E50", "#E74C3C", "#ECF0F1", "#3498DB", "#2980B9"}, // Flat UI
  {"#0F0F0F", "#FF5200", "#37E2D5", "#590696", "#C70A80"}, // Cyberpunk
  {"#1A1A1D", "#66FCF1", "#45A29E", "#C5C6C7", "#1F2833"}, // Steel
  {"#F9F7F7", "#3F72AF", "#112D4E", "#DBE2EF", "#333333"}, // Soft Blue
  {"#222831", "#393E46", "#00ADB5", "#EEEEEE", "#FFD369"}  // Dark Mode
};
int PALETTE_INDEX = 1;        // Range 0-4
int BG_COLOR_INDEX = 0;       // Color within palette for background

// Bitwise Logic Parameters
int CELL_SIZE = 40;           // Default: 40
float ZOOM = 0.05;            // Scaling for the bitwise input
float SPEED_MULT = 0.1;       // Speed of evolution

// --- Sound Variables ---
Minim minim;
AudioPlayer player;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED);
  frameRate(ANIMATION_SPEED);
  
  // Initialize Minim
  minim = new Minim(this);
  player = minim.loadFile("frenzy.mp3");
  
  if (player == null) {
    println("Error: Could not find frenzy.mp3");
    exit();
  }
  
  // Set MAX_FRAMES to length of sound file based on frameRate
  float durationSeconds = player.length() / 1000.0;
  MAX_FRAMES = round(durationSeconds * ANIMATION_SPEED);
  
  player.play();
  player.loop(0); // Do not loop the sound
}

void draw() {
  // Setup Colors
  String[] activePalette = PALETTES[PALETTE_INDEX];
  int bg = unhex("FF" + activePalette[BG_COLOR_INDEX].substring(1));
  int mainColor = unhex("FF" + activePalette[2].substring(1));
  int accentColor = unhex("FF" + activePalette[1].substring(1));
  int secondaryColor = unhex("FF" + activePalette[4].substring(1));

  if (INVERT_COLORS) {
    background(255 - red(bg), 255 - green(bg), 255 - blue(bg));
  } else {
    background(bg);
  }

  // Audio Analysis
  float level = player.mix.level(); // 0.0 to 1.0
  float bitShift = level * 50;      // Sound modulation factor

  // Calculate Drawing Area
  int drawWidth = width - (PADDING * 2);
  int drawHeight = height - (PADDING * 2);
  
  pushMatrix();
  translate(PADDING, PADDING);

  // Iterate through grid
  for (int x = 0; x < drawWidth; x += CELL_SIZE) {
    for (int y = 0; y < drawHeight; y += CELL_SIZE) {
      
      // Logical Texture Generation
      int t = round(frameCount * SPEED_MULT);
      int audioOffset = round(bitShift);
      int val = ((x + t + audioOffset) & (y - t)) ^ (x | (y + t + audioOffset));
      
      // Determine visual properties based on bitwise "errors"
      float noiseVal = (val % 255) / 255.0;
      
      if (SHOW_GRID) {
        stroke(secondaryColor, 50);
        noFill();
        rect(x, y, CELL_SIZE, CELL_SIZE);
      }

      // Pass level to affect visual scale or alpha
      drawArchitecturalElement(x, y, CELL_SIZE, noiseVal, mainColor, accentColor, level);
    }
  }
  popMatrix();

  // Export and Loop Control
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
  }
  
  if (frameCount >= MAX_FRAMES) {
    player.pause();
    noLoop();
  }
}

/**
 * Draws a shape based on the bitwise noise value.
 * Elements scale and change intensity based on audio level.
 */
void drawArchitecturalElement(float x, float y, float size, float n, int c1, int accent, float level) {
  noStroke();
  float pulse = level * 20; // Extra size based on volume
  
  if (n > 0.8) {
    // Solid Block
    fill(c1);
    rect(x + 2 - pulse/2, y + 2 - pulse/2, size - 4 + pulse, size - 4 + pulse);
  } else if (n > 0.5) {
    // Cross-hatch/Bars
    fill(accent);
    float barW = (size/2) * (1 + level);
    rect(x + (size - barW)/2, y, barW, size);
  } else if (n > 0.3) {
    // Small detailing
    fill(c1, 150 + (level * 105));
    rect(x + 5, y + 5, size/4 + pulse, size/4 + pulse);
    rect(x + size - 10, y + size - 10, 5, 5);
  } else if (n > 0.1) {
    // Horizontal thin lines
    stroke(c1, 100 + (level * 155));
    strokeWeight(1 + (level * 3));
    line(x, y + size/2, x + size, y + size/2);
  }
}

/**
 * Ensures audio resources are released when the sketch is closed.
 */
void exit() {
  player.close();
  minim.stop();
  super.exit();
}
