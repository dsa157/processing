/**
 * Bitwise Architectural Noise - FFT Sound Reactive
 * Frequency bands modulate logical bitwise calculations across the grid.
 */

import ddf.minim.*;
import ddf.minim.analysis.*;

// --- Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int SEED = 42;             // Default: 12345
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
int CELL_SIZE = 20;           // Default: 20 (smaller for higher FFT resolution)
float SPEED_MULT = 0.15;      // Speed of evolution
float SENSITIVITY = 1.5;      // Multiplier for FFT impact

// --- Sound Variables ---
Minim minim;
AudioPlayer player;
FFT fft;

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
  
  // Initialize FFT
  fft = new FFT(player.bufferSize(), player.sampleRate());
  
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

  // Perform FFT
  fft.forward(player.mix);

  // Calculate Drawing Area
  int drawWidth = width - (PADDING * 2);
  int drawHeight = height - (PADDING * 2);
  
  pushMatrix();
  translate(PADDING, PADDING);

  // Iterate through grid
  for (int x = 0; x < drawWidth; x += CELL_SIZE) {
    for (int y = 0; y < drawHeight; y += CELL_SIZE) {
      
      // Map Y-coordinate to FFT frequency band
      // Lower Y (top) = higher frequencies, Higher Y (bottom) = bass
      int band = (int) map(y, 0, drawHeight, fft.specSize() - 1, 0);
      float bandAmp = fft.getBand(band) * SENSITIVITY;
      
      // Logical Texture Generation
      int t = round(frameCount * SPEED_MULT);
      int audioOffset = round(bandAmp * 10);
      
      // Bitwise operation influenced by specific frequency band amplitude
      int val = ((x + t + audioOffset) & (y - t)) ^ (x | (y + t + audioOffset));
      
      // Determine visual properties based on bitwise "errors"
      float noiseVal = (val % 255) / 255.0;
      
      if (SHOW_GRID) {
        stroke(secondaryColor, 30);
        noFill();
        rect(x, y, CELL_SIZE, CELL_SIZE);
      }

      // Draw elements modulated by the specific band's amplitude
      drawArchitecturalElement(x, y, CELL_SIZE, noiseVal, mainColor, accentColor, bandAmp / 20.0);
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
 * Frequency intensity (bandLevel) drives the scale and stroke weight.
 */
void drawArchitecturalElement(float x, float y, float size, float n, int c1, int accent, float bandLevel) {
  noStroke();
  float pulse = constrain(bandLevel * 15, 0, size); 
  
  if (n > 0.85) {
    // Solid Block
    fill(c1);
    rect(x + 1, y + 1, size - 2 + pulse, size - 2);
  } else if (n > 0.6) {
    // Bars modulated by frequency
    fill(accent);
    float barW = (size/3) * (1 + bandLevel);
    rect(x + (size - barW)/2, y, barW, size);
  } else if (n > 0.4) {
    // Micro-structures
    fill(c1, 100 + (bandLevel * 155));
    rect(x + size/2, y + size/2, 2 + pulse, 2 + pulse);
  } else if (n > 0.15) {
    // Grid-aligned lines
    stroke(c1, 80 + (bandLevel * 175));
    strokeWeight(0.5 + bandLevel);
    line(x, y, x + size, y);
  }
}

/**
 * Ensures audio resources are released when the sketch is closed.
 */
void exit() {
  if (player != null) player.close();
  if (minim != null) minim.stop();
  super.exit();
}
