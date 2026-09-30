/**
 * Chiaroscuro Code (Quine) - p5.js Version
 * Version: 2026.09.30.14.13.41
 * Renders the source code of the sketch using character density mapping.
 * The brightness of a generated noise field determines which character from the source is displayed.
 */

// --- Parameters ---
let SKETCH_WIDTH = 800;       // Default: 480
let SKETCH_HEIGHT = 800;      // Default: 800
let PADDING = 20;             // Default: 20
let MAX_FRAMES = 900;         // Default: 900
let SAVE_FRAMES = false;      // Default: false
let ANIMATION_SPEED = 30;     // Default: 30
let RANDOM_SEED = 42;         // Default: 42

// Color Settings
let PALETTE_INDEX = 0;        // Default: 0 (0-4)
let INVERT_COLORS = false;    // Default: false
let SHOW_GRID = false;        // Default: false

// Visual Parameters
let NOISE_SCALE = 0.007;      // Default: 0.007
let FONT_SIZE = 12;           // Default: 12
let DISTORTION_STR = 20.0;    // Default: 20.0

// Palette Definitions (Adobe Color / Kuler inspired)
const PALETTES = [
  ["#0D0D0D", "#F2E205", "#F2CB05", "#F29F05", "#F24405"], // Cyber Glow
  ["#1A1A1A", "#00FF41", "#008F11", "#003B00", "#0D0D0D"], // Matrix
  ["#F2F2F2", "#262626", "#595959", "#8C8C8C", "#BFBFBF"], // Monochrome High Contrast
  ["#2B303B", "#BF616A", "#D08770", "#EBCB8B", "#A3BE8C"], // Nord Dark
  ["#011627", "#FDFFFC", "#2EC4B6", "#E71D36", "#FF9F1C"]  // Night Owl
];

let sourceCode = "function setup(){createCanvas(SKETCH_WIDTH,SKETCH_HEIGHT);frameRate(ANIMATION_SPEED);randomSeed(RANDOM_SEED);noiseSeed(RANDOM_SEED);textAlign(CENTER,CENTER);textSize(FONT_SIZE);textFont('Courier');}function draw(){let bg=PALETTES[PALETTE_INDEX][0];let fg=PALETTES[PALETTE_INDEX][1];let accent=PALETTES[PALETTE_INDEX][2];if(INVERT_COLORS){let temp=bg;bg=fg;fg=temp;}background(bg);let charCounter=0;let cols=floor((width-(PADDING*2))/(FONT_SIZE/2));let rows=floor((height-(PADDING*2))/FONT_SIZE);push();translate(PADDING,PADDING);for(let j=0;j<rows;j++){for(let i=0;i<cols;i++){let xPos=i*(FONT_SIZE/2.0);let yPos=j*FONT_SIZE;let val=noise(xPos*NOISE_SCALE,yPos*NOISE_SCALE,frameCount*0.02);if(SHOW_GRID){let gridCol=color(fg);gridCol.setAlpha(50);stroke(gridCol);noFill();rect(xPos,yPos,FONT_SIZE/2.0,FONT_SIZE);}if(val>0.45){let c=sourceCode.charAt(charCounter%sourceCode.length);if(val>0.7){fill(accent);}else{fill(fg);}noStroke();text(c,xPos+(FONT_SIZE/4.0),yPos+(FONT_SIZE/2.0));charCounter++;}}}pop();if(SAVE_FRAMES){saveCanvas('frames/'+nf(frameCount,4),'png');if(frameCount>=MAX_FRAMES)noLoop();}}";

function setup() {
  createCanvas(SKETCH_WIDTH, SKETCH_HEIGHT);
  frameRate(ANIMATION_SPEED);
  randomSeed(RANDOM_SEED);
  noiseSeed(RANDOM_SEED);

  // Clean source code for display (removing extra whitespace for density)
  sourceCode = sourceCode.replace(/\s+/g, "");

  textAlign(CENTER, CENTER);
  textSize(FONT_SIZE);
  textFont("Courier");
}

function draw() {
  // Handle Color Inversion
  let bgColor = PALETTES[PALETTE_INDEX][0];
  let mainColor = PALETTES[PALETTE_INDEX][1];
  let accentColor = PALETTES[PALETTE_INDEX][2];

  if (INVERT_COLORS) {
    let temp = bgColor;
    bgColor = mainColor;
    mainColor = temp;
  }

  background(bgColor);

  let charCounter = 0;
  let cols = Math.floor((width - (PADDING * 2)) / (FONT_SIZE / 2));
  let rows = Math.floor((height - (PADDING * 2)) / FONT_SIZE);

  push();
  translate(PADDING, PADDING);

  for (let j = 0; j < rows; j++) {
    for (let i = 0; i < cols; i++) {
      let xPos = i * (FONT_SIZE / 2.0);
      let yPos = j * FONT_SIZE;

      // Calculate Chiaroscuro Value using Noise
      let val = noise(xPos * NOISE_SCALE, yPos * NOISE_SCALE, frameCount * 0.02);

      // Grid visualization
      if (SHOW_GRID) {
        let gridCol = color(mainColor);
        gridCol.setAlpha(50);
        stroke(gridCol);
        noFill();
        rect(xPos, yPos, FONT_SIZE / 2.0, FONT_SIZE);
      }

      // Thresholding for "Light" areas where code manifests
      if (val > 0.45) {
        let c = sourceCode.charAt(charCounter % sourceCode.length);

        // Dynamic coloring based on value depth
        if (val > 0.7) {
          fill(accentColor);
        } else {
          fill(mainColor);
        }

        noStroke();
        text(c, xPos + (FONT_SIZE / 4.0), yPos + (FONT_SIZE / 2.0));
        charCounter++;
      }
    }
  }
  pop();

  // Saving Logic
  if (SAVE_FRAMES) {
    saveCanvas("frames/" + nf(frameCount, 4), "png");
    if (frameCount >= MAX_FRAMES) {
      noLoop();
    }
  }
}
