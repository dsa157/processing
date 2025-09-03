// --- Global Variables ---
let cols = 10;
let rows = 50;
let gridSize = 32;
let rotationSpeeds = [];
let grid = [];
let paths = [];
let numPaths = 10;
let pathDecaySpeed = 0.5;

let mousePath = [];
let maxMousePathLength = 50;
let mousePathDecaySpeed = 0.02; 
let colorInverted = false;

let charConnections = {
  '─': { left: true, right: true, top: false, bottom: false },
  '│': { left: false, right: false, top: true, bottom: true },
  '┌': { left: false, right: true, top: false, bottom: true },
  '┐': { left: true, right: false, top: false, bottom: true },
  '└': { left: false, right: true, top: true, bottom: false },
  '┘': { left: true, right: false, top: true, bottom: false },
  '┬': { left: true, right: true, top: false, bottom: true },
  '┴': { left: true, right: true, top: true, bottom: false },
  '├': { left: false, right: true, top: true, bottom: true },
  '┤': { left: true, right: false, top: true, bottom: true },
  '┼': { left: true, right: true, top: true, bottom: true },
};

// --- Path Class ---
class Path {
  constructor() {
    this.points = [];
    this.progress = 0;
    this.length = floor(random(50, 200));
    let x = floor(random(cols));
    let y = floor(random(rows));
    this.points.push(createVector(x, y));
    this.generatePath();
  }

  generatePath() {
    let currentX = this.points[0].x;
    let currentY = this.points[0].y;
    for (let i = 0; i < this.length; i++) {
      let nextDir = floor(random(4));
      if (nextDir === 0) currentX++;
      else if (nextDir === 1) currentX--;
      else if (nextDir === 2) currentY++;
      else if (nextDir === 3) currentY--;
      currentX = constrain(currentX, 0, cols - 1);
      currentY = constrain(currentY, 0, rows - 1);
      this.points.push(createVector(currentX, currentY));
    }
  }

  update() {
    this.progress += pathDecaySpeed;
  }

  isFinished() {
    return this.progress > this.length;
  }
}

// --- P5JS Functions ---
function setup() {
  createCanvas(cols * gridSize, rows * gridSize);
  textFont("Courier New", gridSize);
  textAlign(CENTER, CENTER);
  
  generateLattice();
  
  for (let i = 0; i < cols; i++) {
    rotationSpeeds[i] = [];
    for (let j = 0; j < rows; j++) {
      let speed = random(0.01, 0.05);
      let direction = random() > 0.5 ? 1 : -1;
      rotationSpeeds[i][j] = {
        angle: 0,
        speed: speed * direction
      };
    }
  }
  
  for (let i = 0; i < numPaths; i++) {
    paths.push(new Path());
  }
}

function draw() {
  let bgColor = colorInverted ? 0 : 255;
  let fgColor = colorInverted ? 255 : 0;
  background(bgColor);
  
  // Update mouse path
  let mouseXCell = floor(mouseX / gridSize);
  let mouseYCell = floor(mouseY / gridSize);
  if (mouseXCell >= 0 && mouseXCell < cols && mouseYCell >= 0 && mouseYCell < rows) {
    if (mousePath.length === 0 || mouseXCell !== mousePath[mousePath.length - 1].x || mouseYCell !== mousePath[mousePath.length - 1].y) {
      mousePath.push({ x: mouseXCell, y: mouseYCell, decay: 1.0 });
    }
  }
  
  // Trim old path points
  if (mousePath.length > maxMousePathLength) {
    mousePath.shift();
  }

  // Decay points and remove fully decayed ones
  for (let i = mousePath.length - 1; i >= 0; i--) {
    mousePath[i].decay -= mousePathDecaySpeed;
    if (mousePath[i].decay <= 0) {
      mousePath.splice(i, 1);
    }
  }

  for (let i = 0; i < cols; i++) {
    for (let j = 0; j < rows; j++) {
      let x = i * gridSize + gridSize / 2;
      let y = j * gridSize + gridSize / 2;
      
      rotationSpeeds[i][j].angle += rotationSpeeds[i][j].speed;
      
      push();
      translate(x, y);
      rotate(rotationSpeeds[i][j].angle);
      
      let highlight = 0;
      for (let p of paths) {
        for (let k = 0; k < p.points.length; k++) {
          if (p.points[k].x === i && p.points[k].y === j) {
            let distance = abs(p.progress - k);
            if (distance < 10) {
              highlight += cos(distance * PI / 20) * 1.5;
            }
          }
        }
      }

      let mouseHighlight = 0;
      for (let k = 0; k < mousePath.length; k++) {
        if (mousePath[k].x === i && mousePath[k].y === j) {
          mouseHighlight = mousePath[k].decay * 3;
        }
      }

      // Set default colors
      noStroke();
      fill(fgColor);
      
      // Apply highlighting based on priority
      if (mouseHighlight > 0) {
        stroke(255, 0, 0);
        strokeWeight(mouseHighlight);
        fill(255, 0, 0);
      } else if (highlight > 0.01) {
        stroke(fgColor);
        strokeWeight(highlight);
      }
      
      text(grid[i][j], 0, 0);
      pop();
    }
  }
  
  // Update and manage paths
  for (let i = paths.length - 1; i >= 0; i--) {
    paths[i].update();
    if (paths[i].isFinished()) {
      paths.splice(i, 1);
      paths.push(new Path());
    }
  }
}

function mouseClicked() {
  colorInverted = !colorInverted;
}

function generateLattice() {
  for (let i = 0; i < cols; i++) {
    grid[i] = [];
    for (let j = 0; j < rows; j++) {
      grid[i][j] = '';
    }
  }

  for (let j = 0; j < rows; j++) {
    for (let i = 0; i < cols; i++) {
      let requiredLeft = false;
      let requiredTop = false;

      if (i > 0) {
        let leftChar = charConnections[grid[i - 1][j]];
        if (leftChar.right) {
          requiredLeft = true;
        }
      }

      if (j > 0) {
        let topChar = charConnections[grid[i][j - 1]];
        if (topChar.bottom) {
          requiredTop = true;
        }
      }
      
      let possibleChars = [];
      for (let char in charConnections) {
        let connections = charConnections[char];
        if (connections.left === requiredLeft && connections.top === requiredTop) {
          possibleChars.push(char);
        }
      }
      
      let chosenChar = random(possibleChars);
      grid[i][j] = chosenChar;
    }
  }
}
