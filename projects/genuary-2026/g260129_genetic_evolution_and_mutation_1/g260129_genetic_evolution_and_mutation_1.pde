/**
 * Chromo-Strings: Genetic Evolution & Mutation
 * Version: 2026.01.26.22.11.04
 */

// --- Parameters ---
int SKETCH_WIDTH = 480; // Default 480
int SKETCH_HEIGHT = 800; // Default 800
int SEED_VALUE = 157; // Default 42
int MAX_FRAMES = 900; // Default 900
boolean SAVE_FRAMES = false; // Default false
int ANIMATION_SPEED = 30; // Default 30
int PADDING = 40; // Default 40

// Style & Grid
boolean SHOW_GRID = false; // Default false
int GRID_SIZE = 40; // Default 40
boolean INVERT_BACKGROUND = false; // Default false
int PALETTE_INDEX = 2; // Default 2 (Sunset Burn)

// Evolution & Mutation Parameters
int INITIAL_AGENTS = 500; // Default 400
int MAX_AGENTS = 1000; // Default 800
int MIN_AGENTS_THRESHOLD = 200; // Default 200
float MUTATION_CHANCE = 1.95f; // Default 0.45
float MUTATION_STRENGTH = 0.65f; // Default 0.45
float SPONTANEOUS_MUTATION_CHANCE = 0.2f; // Default 0.06
int BASE_LIFESPAN_FRAMES = 440; // Default 240
float AGENT_SPEED_LIMIT = 4.0f; // Default 4.0

// Anti-Clustering Parameters
float DENSITY_SENSING_RADIUS = 150.0f; // Increased radius to sense large clusters
float SPARSE_BOOST_MULTIPLIER = 20.0f; // Aggressive boost for isolated agents

// Hotspot Parameters
boolean SHOW_HOTSPOT = false; // Default false
float HOTSPOT_X = 240; // Default 240
float HOTSPOT_Y = 400; // Default 400
float HOTSPOT_RADIUS = 180; // Default 180
float HOTSPOT_MULTIPLIER = 5.0f; // Default 5.0 

// Color Palettes (Adobe Kuler)
int[][] PALETTES = {
  {#264653, #2a9d8f, #e9c46a, #f4a261, #e76f51}, // Palette 0: Terra Cotta
  {#001219, #005f73, #94d2bd, #ee9b00, #ca6702}, // Palette 1: Deep Sea
  {#5f0f40, #9a031e, #fb8b24, #e36414, #0f4c5c}, // Palette 2: Sunset Burn
  {#22223b, #4a4e69, #9a8c98, #c9ada7, #f2e9e4}, // Palette 3: Grayscale Lavender
  {#335c67, #fff3b0, #e09f3e, #9e2a2b, #540b0e}  // Palette 4: Vintage Autumn
};

ArrayList<StringAgent> agents;
int bgColor;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  int[] activePalette = PALETTES[PALETTE_INDEX];
  bgColor = INVERT_BACKGROUND ? color(245) : activePalette[0];
  background(bgColor);
  
  agents = new ArrayList<StringAgent>();
  spawnAgents(INITIAL_AGENTS);
}

void draw() {
  fill(bgColor, 30);
  noStroke();
  rect(0, 0, width, height);
  
  if (SHOW_GRID) drawGrid();
  
  // Population Maintenance
  if (agents.size() < MIN_AGENTS_THRESHOLD) {
    spawnAgents(40); 
  }

  for (int i = agents.size() - 1; i >= 0; i--) {
    StringAgent a = agents.get(i);
    a.run();
    
    // Mating Logic
    if (i % 2 == 0) { 
      for (int j = i - 1; j >= 0; j--) {
        StringAgent b = agents.get(j);
        if (dist(a.pos.x, a.pos.y, b.pos.x, b.pos.y) < 3.0 && agents.size() < MAX_AGENTS) {
          agents.add(a.mate(b));
          break; 
        }
      }
    }
    
    // Anti-Clustering Mutation Logic
    // High neighbors = low chance. No neighbors = high chance.
    float neighbors = countNeighbors(a);
    float densityFactor = map(neighbors, 0, 15, SPARSE_BOOST_MULTIPLIER, 0.1);
    densityFactor = constrain(densityFactor, 0.1, SPARSE_BOOST_MULTIPLIER);
    
    float currentMutationChance = SPONTANEOUS_MUTATION_CHANCE * densityFactor;
    
    // Mutation Check
    if (random(1) < currentMutationChance) {
      a.mutateDNA();
    }
    
    // Boundaries and Death
    if (a.isDead() || a.isOffscreen()) {
      agents.remove(i);
    }
  }

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

float countNeighbors(StringAgent target) {
  int count = 0;
  for (StringAgent other : agents) {
    if (target != other) {
      if (dist(target.pos.x, target.pos.y, other.pos.x, other.pos.y) < DENSITY_SENSING_RADIUS) {
        count++;
      }
    }
    if (count > 20) break; 
  }
  return count;
}

void spawnAgents(int count) {
  for (int i = 0; i < count; i++) {
    agents.add(new StringAgent());
  }
}

void drawGrid() {
  stroke(150, 30);
  strokeWeight(0.5);
  for (int x = PADDING; x <= width - PADDING; x += GRID_SIZE) line(x, PADDING, x, height - PADDING);
  for (int y = PADDING; y <= height - PADDING; y += GRID_SIZE) line(PADDING, y, width - PADDING, y);
}

class StringAgent {
  PVector pos, prevPos, vel;
  float dnaWeight;
  int dnaColor;
  int colorIndex; 
  float dnaSpeed;
  int remainingFrames;
  float noiseOffset;

  StringAgent() {
    initDefault();
    pos = new PVector(random(PADDING, width-PADDING), random(PADDING, height-PADDING));
    dnaWeight = random(0.5, 4.0);
    dnaSpeed = random(1.0, AGENT_SPEED_LIMIT);
    // Ensure we can pick any index including 0 (though we lerp away from bg in mutation)
    colorIndex = (int)random(PALETTES[PALETTE_INDEX].length);
    dnaColor = PALETTES[PALETTE_INDEX][colorIndex];
  }

  StringAgent(PVector birthPos, int cIdx, float w, float s) {
    initDefault();
    pos = birthPos.copy();
    colorIndex = cIdx;
    dnaColor = PALETTES[PALETTE_INDEX][colorIndex];
    dnaWeight = w;
    dnaSpeed = s;
  }

  void initDefault() {
    prevPos = new PVector();
    vel = PVector.random2D();
    noiseOffset = random(10000);
    remainingFrames = BASE_LIFESPAN_FRAMES;
  }

  void run() {
    update();
    display();
  }

  void update() {
    prevPos.set(pos);
    float angle = noise(noiseOffset) * TWO_PI * 8.0;
    PVector steer = PVector.fromAngle(angle);
    vel.add(steer);
    vel.limit(dnaSpeed);
    pos.add(vel);
    noiseOffset += 0.025;
    remainingFrames--;
  }

  void display() {
    float alpha = map(remainingFrames, 0, BASE_LIFESPAN_FRAMES, 0, 255);
    stroke(dnaColor, alpha);
    strokeWeight(dnaWeight);
    line(prevPos.x, prevPos.y, pos.x, pos.y);
  }

  void mutateDNA() {
    int[] pal = PALETTES[PALETTE_INDEX];
    // Force a cycle through the entire array
    colorIndex = (colorIndex + 1) % pal.length;
    
    // Mix current with the next index to ensure smooth transitions across all palette colors
    dnaColor = lerpColor(dnaColor, pal[colorIndex], MUTATION_STRENGTH);
    dnaWeight = constrain(dnaWeight + random(-MUTATION_STRENGTH, MUTATION_STRENGTH) * 6, 0.5, 14.0);
    dnaSpeed = constrain(dnaSpeed + random(-MUTATION_STRENGTH, MUTATION_STRENGTH) * 4, 0.5, AGENT_SPEED_LIMIT + 4);
  }

  StringAgent mate(StringAgent partner) {
    // Child can take either index or a random one to break clusters
    int childIdx = (random(1) < 0.8) ? this.colorIndex : (int)random(PALETTES[PALETTE_INDEX].length);
    float childWeight = (this.dnaWeight + partner.dnaWeight) / 2.0;
    float childSpeed = (this.dnaSpeed + partner.dnaSpeed) / 2.0;
    
    StringAgent child = new StringAgent(this.pos, childIdx, childWeight, childSpeed);
    
    if (random(1) < MUTATION_CHANCE) {
      child.mutateDNA();
    }
    return child;
  }

  boolean isDead() { return remainingFrames <= 0; }
  
  boolean isOffscreen() {
    return (pos.x < PADDING || pos.x > width - PADDING || 
            pos.y < PADDING || pos.y > height - PADDING);
  }
}
