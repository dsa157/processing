
int cols = 45;
int rows = 30;
float w = 20;
float w2 = 8;
int backgroundColor = 0;
int lineColor = 200;
int lineColor2 = 100;
float speed = 1.0;

Cell[][] grid = new Cell[cols][rows];

void setup()
{
  size(900,600);
  smooth(2);
  noFill();
  stroke(lineColor);
  rectMode(CENTER);
  for (int j = 1; j < rows-1; j++) {
    for (int i = 1; i < cols-1; i++) {
      grid[i][j] = new Cell(i,j, lineColor);
    }
  }
}

void mouseMoved() {
  int i = mouseX/int(w)%cols;
  int j = mouseY/int(w)%rows;
  //println(i,j);
  if (i>0 && i <cols-1 && j>0 && j < rows-1) {
    //grid[i][j].speed = 3;
    Cell c = grid[i][j];
    c.myLineColor=lineColor2;
    c.angle = 150;
  }
}


void draw() {
  background(backgroundColor);

  for (int j=1; j<rows-1; j++) {
    for (int i=1; i<cols-1; i++) {
      Cell c = grid[i][j];
      stroke(c.myLineColor);
      c.display();
    }
  }
}


//------------------------------------------------------------------
class Cell {
  int row;
  int col;
  int counter=0;
  int myLineColor = lineColor;
  int multiplier = 1;
  int angle = 15;
  float ax0 = 0;
  float ay0 = 0;
  float bx0 = 0;
  float by0 = 0;
  float cx0 = 0;
  float cy0 = 0;
  float dx0 = 0;
  float dy0 = 0;
  float mySpeed = speed;
  float rad = 1;

  float ax = 0;
  float ay = 0;
  float bx = 0;
  float by = 0;
  float cx = 0;
  float cy = 0;
  float dx = 0;
  float dy = 0;
  //float myLowerSpeed = lowerSpeed;
  //float myUpperSpeed = upperSpeed;

  // Cell Constructor
  Cell(int i, int j, int lineColor) {
    col = i;
    row = j;
    myLineColor=lineColor;
    randomSeed(row+col * millis());
    randomSeed(row * millis());
    //speed = random(-1, 1);
    multiplier = int(random(1, 5));
  } 

  void display() {
    //frameRate(theFrameRate);
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
    rad = radians((frameCount * multiplier * mySpeed) + angle % 360);
    //println(rad);
    rotate(rad);
    if ((mySpeed > 1) && (frameCount % 200 == 0)) {
        mySpeed--;
    }
    if ((angle > 0) && (frameCount % 100 == 0)) {
        angle = angle - 15;
        if (angle < 0) angle = 0;
    }
    if (myLineColor != lineColor) {
      if (myLineColor > lineColor) {
        myLineColor--;
      } else {
        myLineColor++;
      }
    }
    stroke(myLineColor);
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
