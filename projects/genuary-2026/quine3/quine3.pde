/**
 * Chiaroscuro Code (Quine)
 * Renders the source code of the sketch using character density mapping.
 * The brightness of a generated noise field determines which character from the source is displayed.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 20;             // Default: 40
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
int RANDOM_SEED = 42;         // Default: 42

// Color Settings
int PALETTE_INDEX = 4;        // Default: 0 (0-4)
boolean INVERT_COLORS = false;// Default: false
boolean SHOW_GRID = false;    // Default: false

// Visual Parameters
float NOISE_SCALE = 0.005;    // Default: 0.005
int FONT_SIZE = 10;           // Default: 10
float DISTORTION_STR = 50.0;  // Default: 50.0

// Palette Definitions (Adobe Color / Kuler inspired)
color[][] PALETTES = {
  {#0D0D0D, #F2E205, #F2CB05, #F29F05, #F24405}, // Cyber Glow
  {#1A1A1A, #00FF41, #008F11, #003B00, #0D0D0D}, // Matrix
  {#F2F2F2, #262626, #595959, #8C8C8C, #BFBFBF}, // Monochrome High Contrast
  {#2B303B, #BF616A, #D08770, #EBCB8B, #A3BE8C}, // Nord Dark
  {#011627, #FDFFFC, #2EC4B6, #E71D36, #FF9F1C}  // Night Owl
};

String sourceCode = "void settings(){size(SKETCH_WIDTH,SKETCH_HEIGHT);}void setup(){frameRate(ANIMATION_SPEED);randomSeed(RANDOM_SEED);noiseSeed(RANDOM_SEED);textAlign(LEFT,TOP);PFont mono=createFont(\"Courier\",FONT_SIZE);textFont(mono);}void draw(){color bg=PALETTES[PALETTE_INDEX][0];color fg=PALETTES[PALETTE_INDEX][1];if(INVERT_COLORS){color temp=bg;bg=fg;fg=temp;}background(bg);fill(fg);int charIdx=0;for(int y=PADDING;y<height-PADDING;y+=FONT_SIZE){for(int x=PADDING;x<width-PADDING;x+=FONT_SIZE/2){float n=noise(x*NOISE_SCALE,y*NOISE_SCALE,frameCount*0.01);if(n>0.4){char c=sourceCode.charAt(charIdx%sourceCode.length());text(c,x,y);charIdx++;}}}if(SAVE_FRAMES){saveFrame(\"frames/####.tif\");if(frameCount>=MAX_FRAMES)noLoop();}}";

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  frameRate(ANIMATION_SPEED);
  randomSeed(RANDOM_SEED);
  noiseSeed(RANDOM_SEED);
  
  // Clean source code for display (removing extra whitespace for density)
  sourceCode = sourceCode.replaceAll("\\s+", "");
  
  textAlign(CENTER, CENTER);
  textSize(FONT_SIZE);
}

void draw() {
  // Handle Color Inversion
  color bgColor = PALETTES[PALETTE_INDEX][0];
  color mainColor = PALETTES[PALETTE_INDEX][1];
  color accentColor = PALETTES[PALETTE_INDEX][2];
  
  if (INVERT_COLORS) {
    color temp = bgColor;
    bgColor = mainColor;
    mainColor = temp;
  }
  
  background(bgColor);
  
  int charCounter = 0;
  int cols = (width - (PADDING * 2)) / (FONT_SIZE / 2);
  int rows = (height - (PADDING * 2)) / FONT_SIZE;
  
  pushMatrix();
  translate(PADDING, PADDING);
  
  for (int j = 0; j < rows; j++) {
    for (int i = 0; i < cols; i++) {
      float xPos = i * (FONT_SIZE / 2.0);
      float yPos = j * FONT_SIZE;
      
      // Calculate Chiaroscuro Value using Noise
      float val = noise(xPos * NOISE_SCALE, yPos * NOISE_SCALE, frameCount * 0.02);
      
      // Grid visualization
      if (SHOW_GRID) {
        stroke(mainColor, 50);
        noFill();
        rect(xPos, yPos, FONT_SIZE / 2.0, FONT_SIZE);
      }
      
      // Thresholding for "Light" areas where code manifests
      if (val > 0.45) {
        char c = sourceCode.charAt(charCounter % sourceCode.length());
        
        // Dynamic coloring based on value depth
        if (val > 0.7) {
          fill(accentColor);
        } else {
          fill(mainColor);
        }
        
        text(c, xPos + (FONT_SIZE / 4.0), yPos + (FONT_SIZE / 2.0));
        charCounter++;
      }
    }
  }
  popMatrix();
  
  // Saving Logic
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}
