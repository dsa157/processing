/**
 * The Living Circuitry: Multiple letters are drawn simultaneously in a grid.
 * Glowing cybernetic paths trace alphanumeric characters across a centered grid,
 * producing pulsating circuit lines, spark trails, and organic digital typography.
 * 
 * Version: 2026.09.30.16.15.13
 */

// ==========================================
// CONFIGURATION & GLOBAL PARAMETERS
// ==========================================

// Global seed for reproducible random generation
let seed = 12345; // Default: 12345

// Canvas Dimensions
let canvasWidth = 800; // Default: 480
let canvasHeight = 800; // Default: 800

// Grid layout parameters
let cols = 9; // Default: 5 (number of columns)
let rows = 9; // Default: 9 (number of rows)
let charSize = 80; // Default: 80 (size of each character bounding box)
let charScale = 0.7; // Default: 0.7 (glyph scale relative to cell)

// Circuit animation parameters
let speed = 5; // Default: 5 (speed of circuit line tracing)
let minChangeInterval = 2000; // Default: 2000 (minimum interval in ms before grid refresh)
let maxChangeInterval = 4000; // Default: 4000 (maximum interval in ms before grid refresh)
let bgFadeAlpha = 10; // Default: 10 (trail persistence fade alpha, 0-255)

// Glow & Pulse parameters
let pulseSpeed = 0.1; // Default: 0.1 (oscillation frequency for glow thickness)
let pulseBase = 30; // Default: 30 (base glow thickness)
let pulseAmp = 20; // Default: 20 (glow thickness amplitude)
let mainStrokeWeight = 5; // Default: 5 (core stroke thickness)
let glowAlpha = 50; // Default: 50 (transparency for glow aura [0-100%])

// Spark & Trail parameters
let trailCount = 5; // Default: 5 (number of spark filaments per segment)
let trailMinOffset = 10; // Default: 10 (min spark reach distance)
let trailMaxOffset = 50; // Default: 50 (max spark reach distance)
let trailWeightMin = 1; // Default: 1 (min spark line thickness)
let trailWeightMax = 3; // Default: 3 (max spark line thickness)
let trailMaxAlpha = 50; // Default: 50 (max alpha for spark trails)

// Color cycling parameters
let glowHueStep = 0.5; // Default: 0.5 (glow hue progression per frame)
let lineHueStep = 1.0; // Default: 1.0 (line hue progression per frame)

// Frame saving / recording options
let maxFrames = 600; // Default: 600
let saveFrames = false; // Default: false

// ==========================================
// COLOR PALETTES (Curated from Adobe Color / Kuler)
// ==========================================
const PALETTES = [
  // Palette 0: "Cyberpunk Neon" - High-contrast electric night
  {
    name: "Cyberpunk Neon",
    bg: "#050510",
    colors: ["#00f0ff", "#ff007f", "#ffe600", "#7928ca", "#00ff9f"]
  },
  // Palette 1: "Bio Circuit" - Phosphor green digital matrix
  {
    name: "Bio Circuit",
    bg: "#040d06",
    colors: ["#00ff66", "#00cc44", "#10f5a9", "#39ff14", "#80ff72"]
  },
  // Palette 2: "Retro Synthwave" - Sunset purple and cyan drive
  {
    name: "Retro Synthwave",
    bg: "#120424",
    colors: ["#f706cf", "#2dfcfd", "#7916fc", "#fbe555", "#ff598f"]
  },
  // Palette 3: "Electric Ocean" - Deep aquatic luminescence
  {
    name: "Electric Ocean",
    bg: "#02121e",
    colors: ["#0077b6", "#00b4d8", "#90e0ef", "#caf0f8", "#48cae4"]
  },
  // Palette 4: "Solar Flare" - Radiant plasma energy
  {
    name: "Solar Flare",
    bg: "#180303",
    colors: ["#ff3000", "#ff7700", "#ffaa00", "#ffee33", "#ff0055"]
  }
];

let activePaletteIndex = 0; // Default: 0 (Choose active palette 0-4)
let bgPaletteColorIndex = 0; // Default: 0 (0: custom bg from palette, or index within colors)

// ==========================================
// RUNTIME STATE VARIABLES
// ==========================================
let grid;
let lines;
let offsetX, offsetY;
let glowHue = 0;
let lineHue = 0;
let lastChangeTime;
let changeInterval;

function setup() {
  createCanvas(canvasWidth, canvasHeight);
  randomSeed(seed);

  // Calculate offsets for centering the grid on canvas
  offsetX = (width - cols * charSize) / 2;
  offsetY = (height - rows * charSize) / 2;

  // Initialize the grid and lines 2D arrays
  grid = [];
  lines = [];
  for (let x = 0; x < cols; x++) {
    grid[x] = [];
    lines[x] = [];
  }

  drawNewGrid();
  lastChangeTime = millis();
  changeInterval = floor(random(minChangeInterval, maxChangeInterval));

  // Color setup
  colorMode(HSB, 360, 100, 100, 100);

  // Set initial background from active palette
  let activePalette = PALETTES[activePaletteIndex];
  background(color(activePalette.bg));

  // Font setup
  textFont("Arial", 48);
}

function draw() {
  // Fade the background slightly for motion blur / phosphor persistence
  let activePalette = PALETTES[activePaletteIndex];
  let bgC = color(activePalette.bg);
  fill(hue(bgC), saturation(bgC), brightness(bgC), bgFadeAlpha);
  noStroke();
  rect(0, 0, width, height);

  // Update the grid if the interval has passed
  if (millis() - lastChangeTime > changeInterval) {
    drawNewGrid();
    lastChangeTime = millis();
    changeInterval = floor(random(minChangeInterval, maxChangeInterval));
  }

  // Draw and update each circuit line
  for (let x = 0; x < cols; x++) {
    for (let y = 0; y < rows; y++) {
      if (lines[x][y]) {
        lines[x][y].update();
        lines[x][y].display();

        // Check if a character is finished, and reset it
        if (lines[x][y].isComplete()) {
          let gridPos = createVector(x, y);
          grid[x][y] = String.fromCharCode(65 + floor(random(26)));
          let newPath = getPathForChar(grid[x][y], gridPos);
          lines[x][y] = new CircuitLine(newPath);
        }
      }
    }
  }

  // Pulsating glow and line color
  glowHue = (glowHue + glowHueStep) % 360;
  lineHue = (lineHue + lineHueStep) % 360;

  if (saveFrames) {
    if (frameCount <= maxFrames) {
      saveCanvas(`frame_${nf(frameCount, 4)}`, "png");
    } else {
      noLoop();
    }
  }
}

function drawNewGrid() {
  // Create a circuit line for each grid cell
  for (let x = 0; x < cols; x++) {
    for (let y = 0; y < rows; y++) {
      grid[x][y] = String.fromCharCode(65 + floor(random(26)));
      let gridPos = createVector(x, y);
      let path = getPathForChar(grid[x][y], gridPos);
      lines[x][y] = new CircuitLine(path);
    }
  }
}

// Class to handle the circuit line drawing
class CircuitLine {
  constructor(p) {
    this.path = p;
    this.pathIndex = 0;
    this.currentPos = (p.length > 0) ? p[0].copy() : createVector(0, 0);
  }

  update() {
    if (this.pathIndex < this.path.length - 1) {
      let target = this.path[this.pathIndex + 1];
      let dir = p5.Vector.sub(target, this.currentPos);
      let dist = dir.mag();

      if (dist < speed) {
        this.currentPos = target.copy();
        this.pathIndex++;
      } else {
        dir.normalize().mult(speed);
        this.currentPos.add(dir);
      }
    }
  }

  display() {
    if (this.pathIndex < this.path.length - 1) {
      // Main line with pulsating glow
      let pulse = sin(frameCount * pulseSpeed) * pulseAmp + pulseBase;

      strokeWeight(mainStrokeWeight);
      stroke(lineHue, 80, 100);
      line(this.path[this.pathIndex].x, this.path[this.pathIndex].y, this.currentPos.x, this.currentPos.y);

      // Glow effect
      strokeWeight(pulse);
      stroke(glowHue, 100, 100, glowAlpha);
      line(this.path[this.pathIndex].x, this.path[this.pathIndex].y, this.currentPos.x, this.currentPos.y);

      // Smaller fading lines (spark filaments)
      for (let i = 0; i < trailCount; i++) {
        let offset = random(trailMinOffset, trailMaxOffset);
        let trailPos = p5.Vector.lerp(this.path[this.pathIndex], this.currentPos, random(0, 1));
        let trailEnd = p5.Vector.add(trailPos, p5.Vector.random2D().mult(offset));
        strokeWeight(random(trailWeightMin, trailWeightMax));
        stroke(lineHue, 50, 80, random(trailMaxAlpha));
        line(trailPos.x, trailPos.y, trailEnd.x, trailEnd.y);
      }
    }
  }

  isComplete() {
    return this.pathIndex >= this.path.length - 1;
  }
}

// Function to define paths for each character
function getPathForChar(c, gridPos) {
  let xOffset = gridPos.x * charSize + charSize / 2 + offsetX;
  let yOffset = gridPos.y * charSize + charSize / 2 + offsetY;
  let s = charSize * charScale;

  switch (c) {
    case 'A':
      return [
        createVector(xOffset - s / 2, yOffset + s / 2),
        createVector(xOffset, yOffset - s / 2),
        createVector(xOffset + s / 2, yOffset + s / 2),
        createVector(xOffset - s / 4, yOffset),
        createVector(xOffset + s / 4, yOffset)
      ];
    case 'B':
      return [
        createVector(xOffset - s / 2, yOffset - s / 2),
        createVector(xOffset - s / 2, yOffset + s / 2),
        createVector(xOffset, yOffset + s / 2),
        createVector(xOffset + s / 4, yOffset + s / 4),
        createVector(xOffset + s / 4, yOffset),
        createVector(xOffset - s / 2, yOffset),
        createVector(xOffset + s / 4, yOffset - s / 4),
        createVector(xOffset + s / 4, yOffset - s / 2),
        createVector(xOffset - s / 2, yOffset - s / 2)
      ];
    case 'C':
      return [
        createVector(xOffset + s / 4, yOffset - s / 4),
        createVector(xOffset, yOffset - s / 2),
        createVector(xOffset - s / 4, yOffset - s / 4),
        createVector(xOffset - s / 4, yOffset + s / 4),
        createVector(xOffset, yOffset + s / 2),
        createVector(xOffset + s / 4, yOffset + s / 4)
      ];
    case 'D':
      return [
        createVector(xOffset - s / 2, yOffset - s / 2),
        createVector(xOffset - s / 2, yOffset + s / 2),
        createVector(xOffset, yOffset + s / 2),
        createVector(xOffset + s / 4, yOffset),
        createVector(xOffset, yOffset - s / 2),
        createVector(xOffset - s / 2, yOffset - s / 2)
      ];
    case 'E':
      return [
        createVector(xOffset + s / 4, yOffset - s / 2),
        createVector(xOffset - s / 4, yOffset - s / 2),
        createVector(xOffset - s / 4, yOffset),
        createVector(xOffset + s / 4, yOffset),
        createVector(xOffset - s / 4, yOffset),
        createVector(xOffset - s / 4, yOffset + s / 2),
        createVector(xOffset + s / 4, yOffset + s / 2)
      ];
    case 'F':
      return [
        createVector(xOffset + s / 4, yOffset - s / 2),
        createVector(xOffset - s / 4, yOffset - s / 2),
        createVector(xOffset - s / 4, yOffset),
        createVector(xOffset + s / 4, yOffset),
        createVector(xOffset - s / 4, yOffset)
      ];
    case 'G':
      return [
        createVector(xOffset + s / 4, yOffset - s / 2),
        createVector(xOffset - s / 4, yOffset - s / 2),
        createVector(xOffset - s / 4, yOffset + s / 2),
        createVector(xOffset + s / 4, yOffset + s / 2),
        createVector(xOffset + s / 4, yOffset / 2),
        createVector(xOffset, yOffset / 2)
      ];
    case 'H':
      return [
        createVector(xOffset - s / 2, yOffset - s / 2),
        createVector(xOffset - s / 2, yOffset + s / 2),
        createVector(xOffset - s / 2, yOffset),
        createVector(xOffset + s / 2, yOffset),
        createVector(xOffset + s / 2, yOffset - s / 2),
        createVector(xOffset + s / 2, yOffset + s / 2)
      ];
    case 'I':
      return [
        createVector(xOffset - s / 4, yOffset - s / 2),
        createVector(xOffset + s / 4, yOffset - s / 2),
        createVector(xOffset, yOffset - s / 2),
        createVector(xOffset, yOffset + s / 2),
        createVector(xOffset - s / 4, yOffset + s / 2),
        createVector(xOffset + s / 4, yOffset + s / 2)
      ];
    case 'J':
      return [
        createVector(xOffset + s / 4, yOffset - s / 2),
        createVector(xOffset + s / 4, yOffset + s / 2),
        createVector(xOffset, yOffset + s / 2),
        createVector(xOffset - s / 4, yOffset + s / 4)
      ];
    case 'K':
      return [
        createVector(xOffset - s / 2, yOffset - s / 2),
        createVector(xOffset - s / 2, yOffset + s / 2),
        createVector(xOffset - s / 2, yOffset),
        createVector(xOffset + s / 2, yOffset - s / 2),
        createVector(xOffset - s / 2, yOffset),
        createVector(xOffset + s / 2, yOffset + s / 2)
      ];
    case 'L':
      return [
        createVector(xOffset - s / 2, yOffset - s / 2),
        createVector(xOffset - s / 2, yOffset + s / 2),
        createVector(xOffset + s / 2, yOffset + s / 2)
      ];
    case 'M':
      return [
        createVector(xOffset - s / 2, yOffset + s / 2),
        createVector(xOffset - s / 2, yOffset - s / 2),
        createVector(xOffset, yOffset),
        createVector(xOffset + s / 2, yOffset - s / 2),
        createVector(xOffset + s / 2, yOffset + s / 2)
      ];
    case 'N':
      return [
        createVector(xOffset - s / 2, yOffset + s / 2),
        createVector(xOffset - s / 2, yOffset - s / 2),
        createVector(xOffset + s / 2, yOffset + s / 2),
        createVector(xOffset + s / 2, yOffset - s / 2)
      ];
    case 'O':
      return [
        createVector(xOffset, yOffset - s / 2),
        createVector(xOffset + s / 4, yOffset - s / 4),
        createVector(xOffset + s / 4, yOffset + s / 4),
        createVector(xOffset, yOffset + s / 2),
        createVector(xOffset - s / 4, yOffset + s / 4),
        createVector(xOffset - s / 4, yOffset - s / 4),
        createVector(xOffset, yOffset - s / 2)
      ];
    case 'P':
      return [
        createVector(xOffset - s / 2, yOffset + s / 2),
        createVector(xOffset - s / 2, yOffset - s / 2),
        createVector(xOffset + s / 4, yOffset - s / 2),
        createVector(xOffset + s / 4, yOffset),
        createVector(xOffset - s / 2, yOffset)
      ];
    case 'Q':
      return [
        createVector(xOffset, yOffset - s / 2),
        createVector(xOffset + s / 4, yOffset - s / 4),
        createVector(xOffset + s / 4, yOffset + s / 4),
        createVector(xOffset, yOffset + s / 2),
        createVector(xOffset - s / 4, yOffset + s / 4),
        createVector(xOffset - s / 4, yOffset - s / 4),
        createVector(xOffset, yOffset - s / 2),
        createVector(xOffset, yOffset),
        createVector(xOffset + s / 2, yOffset + s / 2)
      ];
    case 'R':
      return [
        createVector(xOffset - s / 2, yOffset + s / 2),
        createVector(xOffset - s / 2, yOffset - s / 2),
        createVector(xOffset + s / 4, yOffset - s / 2),
        createVector(xOffset + s / 4, yOffset),
        createVector(xOffset - s / 2, yOffset),
        createVector(xOffset + s / 4, yOffset + s / 2)
      ];
    case 'S':
      return [
        createVector(xOffset + s / 4, yOffset - s / 2),
        createVector(xOffset - s / 4, yOffset - s / 2),
        createVector(xOffset - s / 4, yOffset),
        createVector(xOffset + s / 4, yOffset),
        createVector(xOffset + s / 4, yOffset + s / 2),
        createVector(xOffset - s / 4, yOffset + s / 2)
      ];
    case 'T':
      return [
        createVector(xOffset - s / 2, yOffset - s / 2),
        createVector(xOffset + s / 2, yOffset - s / 2),
        createVector(xOffset, yOffset - s / 2),
        createVector(xOffset, yOffset + s / 2)
      ];
    case 'U':
      return [
        createVector(xOffset - s / 2, yOffset - s / 2),
        createVector(xOffset - s / 2, yOffset + s / 2),
        createVector(xOffset + s / 2, yOffset + s / 2),
        createVector(xOffset + s / 2, yOffset - s / 2)
      ];
    case 'V':
      return [
        createVector(xOffset - s / 2, yOffset - s / 2),
        createVector(xOffset, yOffset + s / 2),
        createVector(xOffset + s / 2, yOffset - s / 2)
      ];
    case 'W':
      return [
        createVector(xOffset - s / 2, yOffset - s / 2),
        createVector(xOffset - s / 4, yOffset + s / 2),
        createVector(xOffset, yOffset - s / 2),
        createVector(xOffset + s / 4, yOffset + s / 2),
        createVector(xOffset + s / 2, yOffset - s / 2)
      ];
    case 'X':
      return [
        createVector(xOffset - s / 2, yOffset - s / 2),
        createVector(xOffset + s / 2, yOffset + s / 2),
        createVector(xOffset + s / 2, yOffset - s / 2),
        createVector(xOffset - s / 2, yOffset + s / 2)
      ];
    case 'Y':
      return [
        createVector(xOffset - s / 2, yOffset - s / 2),
        createVector(xOffset, yOffset),
        createVector(xOffset + s / 2, yOffset - s / 2),
        createVector(xOffset, yOffset),
        createVector(xOffset, yOffset + s / 2)
      ];
    case 'Z':
      return [
        createVector(xOffset - s / 2, yOffset - s / 2),
        createVector(xOffset + s / 2, yOffset - s / 2),
        createVector(xOffset - s / 2, yOffset + s / 2),
        createVector(xOffset + s / 2, yOffset + s / 2)
      ];
    default:
      return [createVector(xOffset, yOffset)];
  }
}
