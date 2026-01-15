// VERSION: 2023.11.29.14.00.00

// --- CONFIGURATION PARAMETERS ---

// Canvas Dimensions
int SKETCH_WIDTH = 480; 
int SKETCH_HEIGHT = 800; 

// Input File
String FILE_NAME = "map.jpg";

// Layout & Sampling
int PADDING = 40;          // Space around the drawing area
int GLOBAL_SEED = 998877;  // Seed for random generation
int SAMPLING_RES = 10;     // Grid resolution (lower = denser circuit lines)

// Animation & Output
int MAX_FRAMES = 900;      // Stop after this many frames
boolean SAVE_FRAMES = false; // Save TIF sequence
int ANIMATION_SPEED = 30;  // FPS

// Visual Style
boolean INVERT_BG = false;       // Toggle dark/light background
boolean SHOW_GRID_POINTS = true; // Show 'vias' (dots) at intersections
boolean DRAW_ORIGINAL_IMG = false; // Debug: set true to see underlying map faintly

// Color Thresholds (Approximate for standard maps)
float THRESH_WATER_HUE_MIN = 130; // Blue/Cyan range start (0-255 scale in HSB)
float THRESH_WATER_HUE_MAX = 170; // Blue/Cyan range end
float THRESH_BRIGHTNESS = 200;    // Minimum brightness to be considered a 'street' area

// Color Palette (Cyberpunk Circuit)
int[] PALETTE = {
  #0D1117, // 0: PCB Dark Base
  #F0F6FC, // 1: PCB Light Base
  #161B22, // 2: Substrate (Darker sections)
  #21262D, // 3: Inactive Traces (Dim)
  #D29922, // 4: Gold Traces (Active)
  #3FB950, // 5: Data/Signal (Green)
  #58A6FF, // 6: Water/Cool area
  #F0883E, // 7: Hot Data Packet
  #FF7B72  // 8: Error/Alert
};

// Indicies
int C_BG = 0;
int C_SUBSTRATE = 2;
int C_TRACE_DIM = 3;
int C_TRACE_GOLD = 4;
int C_DATA = 5;
int C_PACKET = 7;

// --- GLOBALS ---
PImage sourceMap;
ArrayList<Node> gridNodes;
ArrayList<Packet> dataPackets;
float drawW, drawH;
int currentBg;

// --- SETUP ---
void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  frameRate(ANIMATION_SPEED);
  randomSeed(GLOBAL_SEED);
  colorMode(HSB, 255);
  
  currentBg = INVERT_BG ? PALETTE[1] : PALETTE[0];
  
  // Calculate drawing bounds
  drawW = width - (PADDING * 2);
  drawH = height - (PADDING * 2);
  
  // Load and process image
  try {
    sourceMap = loadImage(FILE_NAME);
    if (sourceMap != null) {
      // Resize image to fit our grid area exactly to make sampling easy
      sourceMap.resize((int)drawW, (int)drawH);
      buildCircuitFromMap();
    } else {
      println("ERROR: map.jpg not found or could not be loaded.");
    }
  } catch (Exception e) {
    println("Exception loading image: " + e.getMessage());
  }
  
  // Initialize Agents
  dataPackets = new ArrayList<Packet>();
  for(int i = 0; i < 20; i++) {
    dataPackets.add(new Packet());
  }
}

// Analyze the pixels of the loaded map to create the node graph
void buildCircuitFromMap() {
  gridNodes = new ArrayList<Node>();
  
  sourceMap.loadPixels();
  
  int cols = (int)drawW / SAMPLING_RES;
  int rows = (int)drawH / SAMPLING_RES;
  
  // 1. Create Nodes
  // Use a 2D array for easy neighbor lookup
  Node[][] nodeMap = new Node[cols][rows];
  
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      
      // Map grid coordinates to pixel coordinates
      int px = x * SAMPLING_RES;
      int py = y * SAMPLING_RES;
      int loc = px + py * sourceMap.width;
      
      if (loc < sourceMap.pixels.length) {
        int c = sourceMap.pixels[loc];
        float h = hue(c);
        float b = brightness(c);
        
        boolean isWater = (h > THRESH_WATER_HUE_MIN && h < THRESH_WATER_HUE_MAX);
        // We assume valid circuit ground is bright (streets) and not water
        boolean isValidGround = !isWater; 
        
        if (isValidGround) {
          Node n = new Node(x * SAMPLING_RES, y * SAMPLING_RES);
          nodeMap[x][y] = n;
          gridNodes.add(n);
        }
      }
    }
  }
  
  // 2. Connect Nodes (Create Traces)
  for (int x = 0; x < cols; x++) {
    for (int y = 0; y < rows; y++) {
      Node n = nodeMap[x][y];
      if (n != null) {
        // Connect Right
        if (x < cols - 1 && nodeMap[x+1][y] != null) {
          n.addNeighbor(nodeMap[x+1][y]);
          // Bi-directional connection not strictly necessary for visuals but good for logic
          nodeMap[x+1][y].addNeighbor(n); 
        }
        // Connect Down
        if (y < rows - 1 && nodeMap[x][y+1] != null) {
          n.addNeighbor(nodeMap[x][y+1]);
          nodeMap[x][y+1].addNeighbor(n);
        }
      }
    }
  }
}

// --- DRAW LOOP ---
void draw() {
  background(currentBg);
  
  // Optional: Draw faint original map for reference
  if (DRAW_ORIGINAL_IMG && sourceMap != null) {
    tint(255, 30);
    image(sourceMap, PADDING, PADDING);
  }
  
  translate(PADDING, PADDING);
  
  if (gridNodes == null) return; // Guard clause if map failed
  
  // Draw Static Circuitry (Traces)
  strokeWeight(1);
  strokeCap(SQUARE);
  
  for (Node n : gridNodes) {
    n.displayTraces();
  }
  
  // Draw Vias (Intersections) - Draw afterwards to sit on top of lines
  if (SHOW_GRID_POINTS) {
    noStroke();
    fill(PALETTE[C_TRACE_GOLD], 100); 
    for (Node n : gridNodes) {
      // Only draw a via if it has more than 2 connections (an intersection)
      if (n.neighbors.size() > 2) {
        ellipse(n.x, n.y, 2, 2);
      }
    }
  }
  
  // Update and Draw Data Packets
  for (Packet p : dataPackets) {
    p.update();
    p.display();
  }
  
  handleOutput();
}

// --- OUTPUT HANDLER ---
void handleOutput() {
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
  }
  
  if (frameCount >= MAX_FRAMES) {
    noLoop();
    println("MAX_FRAMES reached (" + MAX_FRAMES + "). Stopped.");
  }
}

// --- CLASSES ---

class Node {
  float x, y;
  ArrayList<Node> neighbors;
  
  Node(float _x, float _y) {
    x = _x;
    y = _y;
    neighbors = new ArrayList<Node>();
  }
  
  void addNeighbor(Node n) {
    if (!neighbors.contains(n)) {
      neighbors.add(n);
    }
  }
  
  void displayTraces() {
    stroke(PALETTE[C_TRACE_DIM]);
    for (Node neighbor : neighbors) {
      // Draw line to neighbor. 
      // Optimization: Only draw if neighbor is to right or down to avoid double drawing lines
      if (neighbor.x > x || neighbor.y > y) {
        line(x, y, neighbor.x, neighbor.y);
      }
    }
  }
}

class Packet {
  Node current;
  Node target;
  float progress; // 0.0 to 1.0
  float speed;
  color pColor;
  
  Packet() {
    respawn();
  }
  
  void respawn() {
    if (gridNodes.size() > 0) {
      current = gridNodes.get(int(random(gridNodes.size())));
      pickNextTarget();
      progress = 0;
      speed = random(0.05, 0.15);
      pColor = (random(1) > 0.8) ? PALETTE[C_PACKET] : PALETTE[C_TRACE_GOLD];
    }
  }
  
  void pickNextTarget() {
    if (current != null && current.neighbors.size() > 0) {
      target = current.neighbors.get(int(random(current.neighbors.size())));
    } else {
      respawn();
    }
  }
  
  void update() {
    if (current == null || target == null) {
      respawn();
      return;
    }
    
    progress += speed;
    
    if (progress >= 1.0) {
      progress = 0;
      current = target;
      pickNextTarget();
    }
  }
  
  void display() {
    if (current == null || target == null) return;
    
    float dx = lerp(current.x, target.x, progress);
    float dy = lerp(current.y, target.y, progress);
    
    // Glow
    noStroke();
    fill(pColor, 100);
    ellipse(dx, dy, 6, 6);
    
    // Core
    fill(255);
    ellipse(dx, dy, 2, 2);
  }
}
