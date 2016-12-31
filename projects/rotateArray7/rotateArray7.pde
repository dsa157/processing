
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
  for (int j = 1; j < rows-1; j++) {
    for (int i = 1; i < cols-1; i++) {
      grid[i][j] = new Cell(i,j);
    }
  }
}

void mouseMoved() {
  int i = mouseX/int(w)%cols;
  int j = mouseY/int(w)%rows;
  //println(i,j);
  if (i>0 && i <cols-1 && j>0 && j < rows-1) {
    grid[i][j].speed = 3;
  }
}


void draw() {
  background(0);
  for (int j=1; j<rows-1; j++) {
    for (int i=1; i<cols-1; i++) {
      Cell c = grid[i][j];
      c.display();
    }
  }
}


//------------------------------------------------------------------
class Cell {
  int row;
  int col;
  int counter=0;
  int multiplier = 1;
  float ax0 = 0;
  float ay0 = 0;
  float bx0 = 0;
  float by0 = 0;
  float cx0 = 0;
  float cy0 = 0;
  float dx0 = 0;
  float dy0 = 0;
  float speed = 1;
  float rad = 1;

  float ax = 0;
  float ay = 0;
  float bx = 0;
  float by = 0;
  float cx = 0;
  float cy = 0;
  float dx = 0;
  float dy = 0;
  float lowerSpeed = -1;
  float upperSpeed = -5;

  // Cell Constructor
  Cell(int i, int j) {
    col = i;
    row = j;
    randomSeed(row+col * millis());
    randomSeed(row * millis());
    //speed = random(-1, 1);
    multiplier = int(random(1, 5));
  } 

  void display() {
    //background(0);
    //frameRate(5);
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
    counter++;
    float multiplier = 2; //.05;
    rad = radians((frameCount * multiplier * speed) % 360);
    //println(rad);
    rotate(rad);
    if ((speed > 1) && (frameCount % 200 == 0)) speed--;
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