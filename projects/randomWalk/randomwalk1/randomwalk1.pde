
int numWalkers = 100;
Walker[] walkers;
int seed = 123;
int HEIGHT=600;
int WIDTH=800;

String colorPalette[] = {"B8D9D9", "D98F4E", "D9AE89", "A62F03", "732210"};

class Walker {
  float x, y;
  color c;
  
  Walker(float startX, float startY, color startC) {
    x = random(0, WIDTH); //startX;
    y = random(0, HEIGHT); //startY;
    c = startC;
  }
  
  void step() {
    float choice = random(1);
    
    // Choose a random direction (up, down, left, right)
    if (choice < 0.25) {
      x++;
    } else if (choice < 0.5) {
      x--;
    } else if (choice < 0.75) {
      y++;
    } else {
      y--;
    }
  }
  
  void display() {
    stroke(c, 50); // Faded, transparent lines
    strokeWeight(10);
    point(x, y);
  }
}

void setup() {
  size(800, 600);
  background(0);
  
  randomSeed(seed);
  
  walkers = new Walker[numWalkers];
  for (int i = 0; i < numWalkers; i++) {
    String colorName = colorPalette[int(random(0,  colorPalette.length))];
    color c = unhex(colorName);
    color c1 = color(random(255), random(255), random(255));
    walkers[i] = new Walker(width / 2, height / 2, c1 );
  }
}

void draw() {
  // Add a semi-transparent black rectangle to create a trailing effect
  fill(255, 10);
  noStroke();
  rect(0, 0, width, height);

  for (int i = 0; i < numWalkers; i++) {
    walkers[i].step();
    walkers[i].display();
  }
}
