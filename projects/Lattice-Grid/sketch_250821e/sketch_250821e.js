let cols = 30;
let rows = 50;
let gridSize = 16;
let rotationSpeeds = [];
let grid = [];

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

function setup() {
  createCanvas(cols * gridSize, rows * gridSize);
  textFont("Courier New", gridSize);
  textAlign(CENTER, CENTER);
  
  // Set up the grid and rotation speeds
  generateLattice();
  
  // Initialize rotation speeds for each cell
  for (let i = 0; i < cols; i++) {
    rotationSpeeds[i] = [];
    for (let j = 0; j < rows; j++) {
      // Random speed between 0.01 and 0.05
      let speed = random(0.01, 0.05);
      // Randomly choose clockwise or counter-clockwise
      let direction = random() > 0.5 ? 1 : -1;
      rotationSpeeds[i][j] = {
        angle: 0,
        speed: speed * direction
      };
    }
  }
}

function draw() {
  background(255);
  fill(0);
  
  for (let i = 0; i < cols; i++) {
    for (let j = 0; j < rows; j++) {
      // Calculate the center of the cell
      let x = i * gridSize + gridSize / 2;
      let y = j * gridSize + gridSize / 2;
      
      // Update the angle of rotation
      rotationSpeeds[i][j].angle += rotationSpeeds[i][j].speed;
      
      // Use push() and pop() to isolate transformations for each character
      push();
      translate(x, y);
      rotate(rotationSpeeds[i][j].angle);
      text(grid[i][j], 0, 0); // Draw the text at the new origin (0,0)
      pop();
    }
  }
}

function generateLattice() {
  // Initialize the grid with empty characters
  for (let i = 0; i < cols; i++) {
    grid[i] = [];
    for (let j = 0; j < rows; j++) {
      grid[i][j] = '';
    }
  }

  // Iterate through the grid and fill each cell
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
