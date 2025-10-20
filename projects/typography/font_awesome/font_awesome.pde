/*
 * 2023.10.27.10.30.00
 */

import java.util.Random;

// --- Parameters ---
final int SKETCH_WIDTH = 480;
final int SKETCH_HEIGHT = 800;
final int PADDING = 40; // default 40
final int MAX_FRAMES = 900; // default 900
final int ANIMATION_SPEED = 30; // default 30
final boolean SAVE_FRAMES = false; // default false
final boolean INVERT_BACKGROUND = false; // default false
final boolean SHOW_GRID_CELLS = false; // default false

final long SEED = 12345L; // default 12345L for random initialization

// Adobe Kuler Palette: "Calm Serenity"
final int[] PALETTE = {
  #E0BBE4, #957DAD, #D291BC, #FFC72C, #DA2C31
};
final int BACKGROUND_COLOR_INDEX = 0; // Index from PALETTE for background color

final int NUM_GRID_LAYERS = 3; // default 3
final float MIN_GRID_SIZE_MULTIPLIER = 0.5f; // default 0.5f
final float MAX_GRID_SIZE_MULTIPLIER = 2.0f; // default 2.0f

// FontAwesome icon characters (examples, you might need to find more)
final char[] FA_ICONS = {
  '\uf004', '\uf005', '\uf006', '\uf007', '\uf008', '\uf009', '\uf00a', '\uf00b', '\uf00c', '\uf00d',
  '\uf010', '\uf011', '\uf012', '\uf013', '\uf014', '\uf015', '\uf016', '\uf017', '\uf018', '\uf019'
};
// --- End Parameters ---

PFont fontAwesome;
PGraphics mainCanvas;
Random randomGenerator;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomGenerator = new Random(SEED);
  frameRate(ANIMATION_SPEED);

  mainCanvas = createGraphics(SKETCH_WIDTH - PADDING * 2, SKETCH_HEIGHT - PADDING * 2);

  if (INVERT_BACKGROUND) {
    background(255 - PALETTE[BACKGROUND_COLOR_INDEX]);
  } else {
    background(PALETTE[BACKGROUND_COLOR_INDEX]);
  }

  // Load FontAwesome. Make sure the font file is in the 'data' folder
  fontAwesome = createFont("Font Awesome 7 Free-Solid-900.otf", 32);
  if (fontAwesome == null) {
    println("FontAwesome.otf not found. Please ensure it's in the 'data' folder.");
    exit();
  }
}

void draw() {
  randomGenerator = new Random(SEED + frameCount); // Re-seed for animation consistency

  if (INVERT_BACKGROUND) {
    background(255 - PALETTE[BACKGROUND_COLOR_INDEX]);
  } else {
    background(PALETTE[BACKGROUND_COLOR_INDEX]);
  }

  mainCanvas.beginDraw();
  mainCanvas.clear(); // Clear mainCanvas for fresh drawing each frame
  mainCanvas.textFont(fontAwesome);
  mainCanvas.textAlign(CENTER, CENTER);

  for (int layer = 0; layer < NUM_GRID_LAYERS; layer++) {
    float gridSize = map(randomGenerator.nextFloat(), 0, 1,
      mainCanvas.width / (FA_ICONS.length * MAX_GRID_SIZE_MULTIPLIER),
      mainCanvas.width / (FA_ICONS.length * MIN_GRID_SIZE_MULTIPLIER));

    // Ensure gridSize is at least big enough for 1 icon
    gridSize = max(gridSize, mainCanvas.width / (float)FA_ICONS.length);

    mainCanvas.pushMatrix();
    // Apply XOR blend mode for overlaying layers
    mainCanvas.blendMode(DIFFERENCE); // XOR equivalent in PGraphics is DIFFERENCE

    // Random offset for each layer
    float offsetX = randomGenerator.nextFloat() * gridSize;
    float offsetY = randomGenerator.nextFloat() * gridSize;

    for (float y = -gridSize; y < mainCanvas.height + gridSize; y += gridSize) {
      for (float x = -gridSize; x < mainCanvas.width + gridSize; x += gridSize) {
        if (SHOW_GRID_CELLS) {
          mainCanvas.noFill();
          mainCanvas.stroke(PALETTE[(layer + 1) % PALETTE.length]);
          mainCanvas.rect(x + offsetX, y + offsetY, gridSize, gridSize);
        }

        mainCanvas.fill(PALETTE[layer % PALETTE.length], 150); // Semi-transparent
        char icon = FA_ICONS[randomGenerator.nextInt(FA_ICONS.length)];
        mainCanvas.textSize(gridSize * 0.7f); // Scale icon size with grid
        mainCanvas.text(icon, x + offsetX + gridSize / 2, y + offsetY + gridSize / 2);
      }
    }
    mainCanvas.popMatrix();
  }
  mainCanvas.endDraw();

  image(mainCanvas, PADDING, PADDING);

  // --- Frame Saving Logic ---
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
  // --- End Frame Saving Logic ---
}
