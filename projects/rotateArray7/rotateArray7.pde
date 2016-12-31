
int cols = 45;
int rows = 30;
float w = 20;
float w2 = 8;
Cell[][] grid = new Cell[cols][rows];

void setup()
{
  size(900,600);
  noFill();
  stroke(255);
  rectMode(CENTER);
  for (int j = 0; j < rows; j++) {
    for (int i = 0; i < cols; i++) {
      grid[i][j] = new Cell(i,j);
    }
  }
}


void draw() {
  background(0);
  for (int j=0; j<rows; j++) {
    for (int i=0; i<cols; i++) {
      Cell c = grid[i][j];
      c.display();
    }
  }
}


//------------------------------------------------------------------
class Cell {
  int row;
  int col;
  int multiplier = 1;
  float ax0 = 100;
  float ay0 = 100;
  float bx0 = 100;
  float by0 = 300;
  float cx0 = 300;
  float cy0 = 100;
  float dx0 = 300;
  float dy0 = 300;
  float speed = 0;

  float ax = 0;
  float ay = 0;
  float bx = 0;
  float by = 0;
  float cx = 0;
  float cy = 0;
  float dx = 0;
  float dy = 0;
  int lowerSpeed = 15;
  int upperSpeed = 20;

  // Cell Constructor
  Cell(int i, int j) {
    col = i;
    row = j;
    randomSeed(millis() * i * j);
    speed = random(lowerSpeed,upperSpeed);
  } 

  void display() {
    //background(0);
    pushMatrix();
    float tx = (col*w) + w/2;
    float ty = (row*w) + w/2;
    translate(tx, ty);
    noStroke();
    rect(0, 0, w, w);
    float h = w/2;
    ax0 = tx - h;
    ay0 = ty - h;
    bx0 = tx - h;
    by0 = ty - h+w;
    cx0 = tx - h+w;
    cy0 = ty - h;
    dx0 = tx - h+w;
    dy0 = ty - h+w;
    //println(i,j);
    if (speed > upperSpeed) { multiplier = -1; }
    if (speed < lowerSpeed) { multiplier = 1; }  
    speed = speed + (multiplier * .1 * speed);
    //speed = 15 * row * col * millis();

    rotate(radians(speed));
    stroke(255);
    rect(0, 0, w2, w2);
    float h2 = w2/2;
    ax = screenX(-h2, -h2);
    ay = screenY(-h2, -h2);
    bx = screenX(-h2, h2);
    by = screenY(-h2, h2);
    cx = screenX(h2, -h2);
    cy = screenY(h2, -h2);
    dx = screenX(h2, h2);
    dy = screenY(h2, h2);
    popMatrix();
    line(ax0, ay0, ax, ay);
    line(bx0, by0, bx, by);
    line(cx0, cy0, cx, cy);
    line(dx0, dy0, dx, dy);
  }
}