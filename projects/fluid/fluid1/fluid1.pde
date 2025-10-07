// FLUID MIXING SIMULATION
// Processing 4.x

// -- GLOBAL PARAMETERS
final int SEED             = 13579;
final int SKETCH_WIDTH     = 480;
final int SKETCH_HEIGHT    = 800;
final int PADDING          = 0;
final int MAX_FRAMES       = 900;
final boolean SAVE_FRAMES  = false;
final int ANIMATION_SPEED  = 30; // frames per visual change

// PALETTE (hex values)
color[] PALETTE = {
  #000000, // black
  #FFFFFF, // white
  #00FFFF, // blue
  #FFFF00  // red
};

int ALPHACAP = 255;
float ALPHABOOST = 1.5;

// BACKGROUND COLOR INDEX
final int BG_COLOR_INDEX   = 0; // 0 = black, 1 = white, etc.

// -- FLUID FIELD PARAMETERS
final int GRID_SCALE       = 8;   // smaller = finer detail
final float VISCOSITY      = 0.0001;
final float DIFFUSION      = 0.000005;
final float FORCE_MAG      = 1.5;

// Fluid field instance
Fluid fluid;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED);
  frameRate(ANIMATION_SPEED);
  colorMode(RGB, 255);
  background(PALETTE[BG_COLOR_INDEX]);
  
  int cols = (SKETCH_WIDTH - 2*PADDING) / GRID_SCALE;
  int rows = (SKETCH_HEIGHT - 2*PADDING) / GRID_SCALE;
  fluid = new Fluid(cols, rows, DIFFUSION, VISCOSITY, 0.2);
}

void draw() {
  background(PALETTE[BG_COLOR_INDEX]);
  
  // add two opposing sources of fluid (different colors)
  float t = frameCount * 0.01;
  float x1 = (SKETCH_WIDTH/2 - 60 + PADDING)/GRID_SCALE;
  float y1 = (SKETCH_HEIGHT/2 + 80*sin(t) + PADDING)/GRID_SCALE;
  
  float x2 = (SKETCH_WIDTH/2 + 60 + PADDING)/GRID_SCALE;
  float y2 = (SKETCH_HEIGHT/2 + 80*cos(t) + PADDING)/GRID_SCALE;
  
  fluid.addDensity((int)x1, (int)y1, 150);
  fluid.addDensity((int)x2, (int)y2, 150);
  
  fluid.addVelocity((int)x1, (int)y1, FORCE_MAG, FORCE_MAG*0.5);
  fluid.addVelocity((int)x2, (int)y2, -FORCE_MAG, -FORCE_MAG*0.5);
  
  // step simulation
  fluid.step();
  
  // render fluid
  fluid.render();
  
  // save frames if needed
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
  }
  if (frameCount >= MAX_FRAMES) {
    noLoop();
  }
}

// ------------------------------------------------------
// FLUID CLASS
class Fluid {
  int cols, rows;
  float diff, visc, dt;
  
  float[] s, density;
  float[] Vx, Vy;
  float[] Vx0, Vy0;
  
  Fluid(int cols, int rows, float diff, float visc, float dt) {
    this.cols = cols;
    this.rows = rows;
    this.diff = diff;
    this.visc = visc;
    this.dt = dt;
    
    int size = (cols+2)*(rows+2);
    s = new float[size];
    density = new float[size];
    Vx = new float[size];
    Vy = new float[size];
    Vx0 = new float[size];
    Vy0 = new float[size];
  }
  
  void addDensity(int x, int y, float amount) {
    int idx = IX(x, y);
    if (idx < density.length) density[idx] += amount;
  }
  
  void addVelocity(int x, int y, float amountX, float amountY) {
    int idx = IX(x, y);
    if (idx < Vx.length) {
      Vx[idx] += amountX;
      Vy[idx] += amountY;
    }
  }
  
  void step() {
    diffuse(1, Vx0, Vx, visc, dt);
    diffuse(2, Vy0, Vy, visc, dt);
    
    project(Vx0, Vy0, Vx, Vy);
    
    advect(1, Vx, Vx0, Vx0, Vy0, dt);
    advect(2, Vy, Vy0, Vx0, Vy0, dt);
    
    project(Vx, Vy, Vx0, Vy0);
    
    diffuse(0, s, density, diff, dt);
    advect(0, density, s, Vx, Vy, dt);
  }
  
  void render() {
    noStroke();
    for (int i=0; i<=cols; i++) {
      for (int j=0; j<=rows; j++) {
        float d = density[IX(i, j)];
        if (d > 0.1) {
          float px = i*GRID_SCALE + PADDING;
          float py = j*GRID_SCALE + PADDING;
          float sz = GRID_SCALE*1.2;
          
          // blend two palette colors based on velocity
          float vx = Vx[IX(i, j)];
          float vy = Vy[IX(i, j)];
          float mixAmt = constrain(map(vx*vy, -2, 2, 0, 1), 0, 1);
          color c = lerpColor(PALETTE[2], PALETTE[3], mixAmt);
          
          fill(c, constrain(d * ALPHABOOST, 0, ALPHACAP));
          rect(px, py, sz, sz);
        }
      }
    }
  }
  
  int IX(int x, int y) {
    return x + (cols+2) * y;
  }
  
  // simplified stable fluids methods
  void diffuse(int b, float[] x, float[] x0, float diff, float dt) {
    float a = dt * diff * cols * rows;
    lin_solve(b, x, x0, a, 1+4*a);
  }
  
  void advect(int b, float[] d, float[] d0, float[] velocX, float[] velocY, float dt) {
    int i0, i1, j0, j1;
    float x, y, s0, t0, s1, t1, dt0;
    dt0 = dt * cols;
    
    for (int i=1; i<=cols; i++) {
      for (int j=1; j<=rows; j++) {
        x = i - dt0 * velocX[IX(i,j)];
        y = j - dt0 * velocY[IX(i,j)];
        
        if (x < 0.5) x = 0.5;
        if (x > cols + 0.5) x = cols + 0.5;
        i0 = floor(x); i1 = i0+1;
        
        if (y < 0.5) y = 0.5;
        if (y > rows + 0.5) y = rows + 0.5;
        j0 = floor(y); j1 = j0+1;
        
        s1 = x - i0; s0 = 1-s1;
        t1 = y - j0; t0 = 1-t1;
        
        d[IX(i,j)] = 
          s0*(t0*d0[IX(i0,j0)] + t1*d0[IX(i0,j1)]) +
          s1*(t0*d0[IX(i1,j0)] + t1*d0[IX(i1,j1)]);
      }
    }
  }
  
  void project(float[] velocX, float[] velocY, float[] p, float[] div) {
    for (int i=1; i<=cols; i++) {
      for (int j=1; j<=rows; j++) {
        div[IX(i,j)] = -0.5f*(
          velocX[IX(i+1,j)]-velocX[IX(i-1,j)]+
          velocY[IX(i,j+1)]-velocY[IX(i,j-1)]
          )/cols;
        p[IX(i,j)] = 0;
      }
    }
    lin_solve(0, p, div, 1, 4);
    
    for (int i=1; i<=cols; i++) {
      for (int j=1; j<=rows; j++) {
        velocX[IX(i,j)] -= 0.5*(p[IX(i+1,j)]-p[IX(i-1,j)])*cols;
        velocY[IX(i,j)] -= 0.5*(p[IX(i,j+1)]-p[IX(i,j-1)])*rows;
      }
    }
  }
  
  void lin_solve(int b, float[] x, float[] x0, float a, float c) {
    for (int k=0; k<20; k++) {
      for (int i=1; i<=cols; i++) {
        for (int j=1; j<=rows; j++) {
          x[IX(i,j)] = (x0[IX(i,j)] + a*(
            x[IX(i-1,j)]+x[IX(i+1,j)]+
            x[IX(i,j-1)]+x[IX(i,j+1)]
            ))/c;
        }
      }
    }
  }
}
