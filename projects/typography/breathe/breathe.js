let word = "BREATHE";
let charData = [];
let t = 0; // A time variable to control the animation

function setup() {
  createCanvas(450, 800);
  textFont("Arial Black", 48); // Set a clear, bold font
  textAlign(CENTER, CENTER);

  // Initialize data for each character
  let totalWidth = textWidth(word);
  let startX = (width - totalWidth) / 2;

  for (let i = 0; i < word.length; i++) {
    let charWidth = textWidth(word.charAt(i));
    charData[i] = {
      char: word.charAt(i),
      x: startX + charWidth / 2,
      y: height / 2,
      size: 48,
      offset: i * 0.5 // Stagger the sine wave offset for each character
    };
    startX += charWidth;
  }
}

function draw() {
  background(240); // A light gray background
  
  // Update the time variable
  t += 0.05;

  // Loop through each character and draw it with the breathing effect
  for (let i = 0; i < charData.length; i++) {
    let char = charData[i];
    
    // Use the sine function to calculate the new size.
    // The sine function returns values between -1 and 1. We scale this to a small range (e.g., -5 to 5)
    // and add it to the base size. The offset makes each character breathe at a slightly different phase.
    let breathSize = sin(t + char.offset) * 5; 
    let newSize = char.size + breathSize;

    // Draw the character with the new size
    textSize(newSize);
    fill(0); // Black color
    text(char.char, char.x, char.y);
  }
}
