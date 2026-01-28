/**
 * Kinetic HTML Field: Grayscale Shadow Typography
 * Version: 2026.01.24.17.18.10
 * An artistic representation of HTML tags.
 * Features a readability toggle that stabilizes text while shadows rotate.
 */

// --- Configuration Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
int GLOBAL_SEED = 123;        // Default: 123
boolean INVERT_BG = false;    // Default: false
int PALETTE_INDEX = 1;        // Default: 1 (Grayscale)
boolean SHOW_GRID = false;    // Default: false

// Behavior Parameters
boolean STRICT_READABILITY = true; // Default: true (true = vertical, false = rotating)
int SHADOW_LAYERS = 50;            // Default: 50
float EXTRUSION_MAG = 1.1;         // Default: 1.1
int TOTAL_TAGS = 50;               // Default: 20

String[] HTML_TAGS = {
  "<h1>", "<div>", "<a>", "<span>", "<p>", "<img>", 
  "<ul>", "<li>", "<section>", "<header>", "<footer>", 
  "<main>", "<nav>", "<button>", "<input>", "<form>", 
  "<canvas>", "<video>", "<svg>", "<style>"
};

// --- Color Palettes (Grayscale Focus) ---
color[][] PALETTES = {
  {#000000, #333333, #666666, #999999, #FFFFFF}, // Standard Gray
  {#121212, #242424, #484848, #808080, #E0E0E0}, // Deep Charcoal
  {#F0F0F0, #DCDCDC, #A9A9A9, #696969, #000000}, // High Contrast Light
  {#1A1A1A, #2A2A2A, #3A3A3A, #4A4A4A, #5A5A5A}, // Low Variance Dark
  {#FFFFFF, #CCCCCC, #999999, #666666, #333333}  // Inverted Standard
};

TagElement[] tags;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(GLOBAL_SEED);
  frameRate(ANIMATION_SPEED);
  
  tags = new TagElement[TOTAL_TAGS];
  for (int i = 0; i < TOTAL_TAGS; i++) {
    String label = HTML_TAGS[i % HTML_TAGS.length];
    tags[i] = new TagElement(label);
  }
}

void draw() {
  color[] currentPalette = PALETTES[PALETTE_INDEX];
  color bgColor = currentPalette[0];
  
  if (INVERT_BG) {
    background(255 - red(bgColor));
  } else {
    background(bgColor);
  }

  if (SHOW_GRID) {
    drawDebugGrid(40);
  }

  // Update and Render Tags
  for (TagElement t : tags) {
    t.update();
    t.display(currentPalette);
  }

  // --- Export / Loop Control ---
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}

class TagElement {
  float x, y;
  float currentRot;
  float rotSpeed;
  float floatSpeed;
  float floatOffset;
  float textSize;
  String label;
  
  TagElement(String _label) {
    label = _label;
    x = random(PADDING, width - PADDING);
    y = random(PADDING, height - PADDING);
    currentRot = random(TWO_PI);
    rotSpeed = random(-0.03, 0.03);
    floatSpeed = random(0.01, 0.04);
    floatOffset = random(1000);
    textSize = random(18, 38);
  }
  
  void update() {
    currentRot += rotSpeed;
    // Oscillate position slightly
    y += sin(frameCount * floatSpeed + floatOffset) * 0.4;
    x += cos(frameCount * (floatSpeed * 0.5) + floatOffset) * 0.2;
  }
  
  void display(color[] palette) {
    pushMatrix();
    translate(x, y);
    
    // Determine if the text itself rotates or stays upright
    if (!STRICT_READABILITY) {
      rotate(currentRot);
    }
    
    textSize(textSize);
    textAlign(CENTER, CENTER);
    
    // 3D Extrusion using Shadow Loop
    for (int i = SHADOW_LAYERS; i > 0; i--) {
      // Trigonometric offset for the 3D depth effect
      // If READABILITY is on, the shadow rotates while text stays still
      float angleReference = STRICT_READABILITY ? (frameCount * 0.03 + floatOffset) : 0;
      float ox = cos(angleReference) * i * EXTRUSION_MAG;
      float oy = sin(angleReference) * i * EXTRUSION_MAG;
      
      // Calculate color value (Texture)
      float inter = map(i, 0, SHADOW_LAYERS, 0, 1);
      color shadowCol = lerpColor(palette[1], palette[3], inter);
      
      fill(shadowCol, map(i, 0, SHADOW_LAYERS, 180, 0));
      text(label, ox, oy);
    }
    
    // Main Face (Top Layer)
    fill(palette[4]); 
    text(label, 0, 0);
    popMatrix();
  }
}

void drawDebugGrid(int step) {
  stroke(127, 30);
  for (int x = PADDING; x <= width - PADDING; x += step) {
    line(x, PADDING, x, height - PADDING);
  }
  for (int y = PADDING; y <= height - PADDING; y += step) {
    line(PADDING, y, width - PADDING, y);
  }
}
