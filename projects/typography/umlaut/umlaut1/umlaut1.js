/**
 * Umlaut Kinetic Typography Animation
 * Version: 2026.09.30.16.01.30
 * Description: Renders a grid of rotating umlaut characters using a DIFFERENCE blend mode
 * buffer to create intricate overlapping typographic patterns. Converted from Processing (Java).
 * Includes interactive font switching on mouse click and palette cycling on spacebar.
 */

// ==========================================
// Global Parameters & Configuration
// ==========================================
let globalSeed = 42; // Default: 42 (Global seed for deterministic randomness)

let canvasWidth = 800; // Default: 450
let canvasHeight = 800; // Default: 800

let letters = ['ë', 'ö', 'ä', 'ü']; // Default: ['ë', 'ö', 'ä', 'ü']
let fonts = ['Impact', 'Arial Black', 'Georgia', 'Courier New', 'sans-serif']; // Default: ['Impact', 'Arial Black', 'Georgia', 'Courier New', 'sans-serif']
let activeFontIndex = 0; // Default: 0 (Index from fonts array)

let defaultFontSize = 160; // Default: 160
let xSpacing = 80; // Default: 80
let ySpacing = 80; // Default: 80
let minRotationSpeed = -3.0; // Default: -3.0
let maxRotationSpeed = 3.0; // Default: 3.0
let maxAngle = 360; // Default: 360

let maxFrames = 600; // Default: 600
let saveFrames = false; // Default: false

// Color Palettes (Curated Adobe Color / Kuler palettes)
const PALETTES = [
  // 0: Monochrome Minimal (High contrast black & white)
  { name: "Monochrome Minimal", colors: ["#FFFFFF", "#FFFFFF", "#000000", "#666666", "#333333"] },
  // 1: Retro Neon (Electric vibrant tones)
  { name: "Retro Neon", colors: ["#00F0FF", "#0D0221", "#0F084B", "#26408B", "#A6CFD5"] },
  // 2: Sunset Glow (Warm dusk gradient shades)
  { name: "Sunset Glow", colors: ["#FF8C42", "#2B0938", "#591A53", "#8C2458", "#D94E43"] },
  // 3: Cyberpunk Pastel (Modern futuristic pastels)
  { name: "Cyberpunk Pastel", colors: ["#FF70A6", "#1A1A24", "#332941", "#70587C", "#FF9770"] },
  // 4: Bauhaus Primary (Bold graphic primaries)
  { name: "Bauhaus Primary", colors: ["#E07A5F", "#F4F1DE", "#3D405B", "#81B29A", "#F2CC8F"] }
];

let activePaletteIndex = 0; // Default: 0 (Index from PALETTES array)
let activeBgColorIndex = 1; // Default: 1 (Index within active palette colors for background)
let activeTextColorIndex = 0; // Default: 0 (Index within active palette colors for text/fill)

let characters = [];
let pg;
let selectedFont;

function setup() {
  createCanvas(canvasWidth, canvasHeight);
  randomSeed(globalSeed);
  noiseSeed(globalSeed);

  selectedFont = fonts[activeFontIndex];

  // Initialize the offscreen graphics buffer for drawing
  pg = createGraphics(width, height);
  pg.textFont(selectedFont);
  pg.textAlign(CENTER, CENTER);

  characters = [];

  // Calculate centered grid offsets
  let cols = floor(width / xSpacing);
  let rows = floor(height / ySpacing);
  let offsetX = (width - (cols * xSpacing)) / 2 + xSpacing / 2;
  let offsetY = (height - (rows * ySpacing)) / 2 + ySpacing / 2;

  // Populate the list with Character objects
  for (let y = offsetY; y < height; y += ySpacing) {
    for (let x = offsetX; x < width; x += xSpacing) {
      characters.push(new Character(x, y));
    }
  }
}

function draw() {
  let currentPalette = PALETTES[activePaletteIndex];
  let bgColor = color(currentPalette.colors[activeBgColorIndex]);
  let textColor = color(currentPalette.colors[activeTextColorIndex]);

  background(bgColor);

  // Clear the PGraphics buffer
  pg.clear();
  pg.background(bgColor);

  // Set the blend mode for XOR effect
  pg.blendMode(DIFFERENCE);
  pg.fill(textColor);
  pg.noStroke();

  // Draw each character to the PGraphics buffer
  for (let c of characters) {
    c.update();
    c.display(pg);
  }

  // Display the PGraphics buffer to the main window
  image(pg, 0, 0);

  if (saveFrames) {
    if (frameCount >= maxFrames) {
      noLoop();
    }
  }
}

function mousePressed() {
  // Cycle through fonts on mouse click
  activeFontIndex = (activeFontIndex + 1) % fonts.length;
  selectedFont = fonts[activeFontIndex];
  if (pg) {
    pg.textFont(selectedFont);
  }
}

function keyPressed() {
  // Cycle through color palettes on space bar press
  if (key === ' ' || keyCode === 32) {
    activePaletteIndex = (activePaletteIndex + 1) % PALETTES.length;
  }
}

class Character {
  constructor(_x, _y) {
    this.x = _x;
    this.y = _y;
    this.angle = random(maxAngle); // Random initial angle
    this.rotationSpeed = random(minRotationSpeed, maxRotationSpeed); // Random rotation speed
    this.randomIndex = floor(random(letters.length));

    // Select the letter at that random index
    this.myChar = letters[this.randomIndex];
  }

  update() {
    // Update the angle based on its unique speed
    this.angle += this.rotationSpeed;
  }

  display(buffer) {
    buffer.push();
    buffer.translate(this.x, this.y);
    buffer.rotate(radians(this.angle));
    buffer.textSize(defaultFontSize);
    buffer.text(this.myChar, 0, 0);
    buffer.pop();
  }
}
