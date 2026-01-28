import ddf.minim.*;
import ddf.minim.analysis.*;

/**
 * Sound-Reactive Evolving Chromosome
 * Fixed Sync Logic: Maps frameCount directly to the audio sample buffer.
 */

// --- GLOBAL PARAMETERS ---
int SKETCH_WIDTH = 480;      // Width of the canvas
int SKETCH_HEIGHT = 800;     // Height of the canvas
int PADDING = 80;            // Padding around the central sketch (80)
int MAX_FRAMES = 920;        // Total frames before sketch stops (920)
boolean SAVE_FRAMES = false;  // Toggle to save tif frames (true/false)
int ANIMATION_SPEED = 30;    // Target frame rate (30)
int GLOBAL_SEED = 123;       // Seed for random/noise (123)
boolean INVERT_BG = false;   // Invert background logic (false)
boolean SHOW_GRID = false;   // Debug grid visibility (false)

// --- EVOLUTION PARAMETERS ---
int PARTICLE_START_FRAME = 310;     // Shedding and strand fade begins (310)
int DISSOCIATION_START_FRAME = 910; // Trigger for final burst (910)
float DEFORM_STRENGTH = 0.6;        // Sound-driven displacement (0.6)
float STRAND_WEIGHT = 3.8;          // Starting thickness of strands (3.8)
float MIN_PARTICLE_SIZE = 4.5;      // Floor for particle pulsing (4.5)
float MAX_PARTICLE_SIZE = 8.0;      // Ceiling for particle pulsing (8.0)
float DENSITY_CURVE = 2.0;          // Exponential growth of particle count (2.0)
float HORIZONTAL_EXCURSION = 120.0; // Allowed drift past X padding (120.0)

// --- TOGGLES ---
boolean FLASH_ON_DISSOCIATE = true; // Background flash at dissociation (true)

// --- AUDIO PARAMETERS ---
String AUDIO_FILE = "sunrise.mp3"; 
boolean LOOP_AUDIO = false;        
boolean SHOW_UI = true;            

// --- PALETTES (Adobe Color) ---
String[][] PALETTES = {
  {"#0F2027", "#4A859C", "#4A7A90", "#F2F2F2", "#E2E2E2"}, // 0: Deep Sea (Updated)
  {"#1A1A1D", "#4E4E50", "#6F2232", "#950740", "#C3073F"}, // 1: Industrial Red
  {"#2E1114", "#501B1D", "#64485C", "#83677B", "#ADADAD"}, // 2: Muted Purple
  {"#05386B", "#379683", "#5CDB95", "#8EE4AF", "#EDF5E1"}, // 3: Neon Mint
  {"#242582", "#553D67", "#F64C72", "#99738E", "#2F2FA2"}  // 4: Synthwave
};
int PALETTE_INDEX = 0; 

Minim minim;
AudioSample sample; // Using AudioSample to load entire file into memory
FFT fft;
float[] leftChannel;
float[] rightChannel;

Organism dna;
int currentBg, flashCol;
int[] currentColors;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT);
}

void setup() {
  frameRate(ANIMATION_SPEED);
  randomSeed(GLOBAL_SEED);
  noiseSeed(GLOBAL_SEED);
  
  minim = new Minim(this);
  // Load the entire file into memory as an AudioSample
  sample = minim.loadSample(AUDIO_FILE, 1024);
  
  if (sample != null) {
    leftChannel = sample.getChannel(AudioSample.LEFT);
    rightChannel = sample.getChannel(AudioSample.RIGHT);
    fft = new FFT(1024, sample.sampleRate());
    sample.trigger(); // Start audio playback
  } else {
    println("Could not find " + AUDIO_FILE);
    exit();
  }

  currentColors = new int[5];
  for (int i = 0; i < 5; i++) {
    currentColors[i] = unhex("FF" + PALETTES[PALETTE_INDEX][i].substring(1));
  }
  currentBg = INVERT_BG ? currentColors[3] : currentColors[0];
  flashCol = currentColors[4]; 

  dna = new Organism(width/2, PADDING, height - PADDING);
}

void draw() {
  // --- BUFFER SYNC LOGIC ---
  // Map current frameCount to the exact sample index in the audio buffer
  float secondsPerFrame = 1.0 / (float)ANIMATION_SPEED;
  float currentTime = frameCount * secondsPerFrame;
  int startSample = (int)(currentTime * sample.sampleRate());
  
  // Create a temporary buffer for the FFT to analyze
  float[] buffer = new float[1024];
  for (int i = 0; i < 1024; i++) {
    int idx = startSample + i;
    if (idx < leftChannel.length) {
      // Mix stereo to mono for analysis
      buffer[i] = (leftChannel[idx] + rightChannel[idx]) / 2.0;
    } else {
      buffer[i] = 0; // Padding if audio ends
    }
  }
  fft.forward(buffer);

  // Background Flash
  if (FLASH_ON_DISSOCIATE && frameCount == DISSOCIATION_START_FRAME) {
    background(flashCol);
  } else {
    background(currentBg);
  }
  
  if (SHOW_GRID) drawDebugGrid();

  float evolution = constrain((float)frameCount / (float)MAX_FRAMES, 0, 1);
  dna.update(evolution);
  dna.display(evolution);

  if (SHOW_UI) drawUI();

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
  }
  
  if (frameCount >= MAX_FRAMES) {
    sample.stop();
    noLoop();
  }
}

class Organism {
  float xPos, yStart, yEnd;
  PVector[] nodes;
  ArrayList<Particle> particles;
  int SEGMENTS = 120;

  Organism(float x, float yS, float yE) {
    xPos = x; yStart = yS; yEnd = yE;
    nodes = new PVector[SEGMENTS];
    particles = new ArrayList<Particle>();
    for (int i = 0; i < SEGMENTS; i++) {
      nodes[i] = new PVector(xPos, map(i, 0, SEGMENTS - 1, yStart, yEnd));
    }
  }

  void update(float evolution) {
    float mutationPower = pow(evolution, 2) * 12.0 * DEFORM_STRENGTH; 
    
    for (int i = 0; i < SEGMENTS; i++) {
      int bandIdx = (int)map(i, 0, SEGMENTS, 0, fft.specSize() * 0.25);
      float amp = fft.getBand(bandIdx);
      
      float n = noise(nodes[i].y * 0.01, frameCount * 0.05);
      float angle = n * TWO_PI * evolution;
      
      nodes[i].x = xPos + cos(angle) * (amp * mutationPower);
      nodes[i].x = constrain(nodes[i].x, PADDING * 1.2, width - PADDING * 1.2);
      
      if (frameCount > PARTICLE_START_FRAME && frameCount < DISSOCIATION_START_FRAME) {
        float pProgress = map(frameCount, PARTICLE_START_FRAME, DISSOCIATION_START_FRAME, 0, 1);
        float particleChance = pow(pProgress, DENSITY_CURVE) * 0.35; 
        if (random(1) < particleChance) {
          particles.add(new Particle(nodes[i].x, nodes[i].y, bandIdx, nodes[i]));
        }
      }
    }

    for (int i = particles.size()-1; i >= 0; i--) {
      Particle p = particles.get(i);
      p.update();
      if (p.isDead()) particles.remove(i);
    }
  }

  void display(float evolution) {
    float separation = map(evolution, 0, 1, 15, 80 * evolution);
    float strandAlpha = 220;
    if (frameCount >= PARTICLE_START_FRAME) {
      strandAlpha = map(frameCount, PARTICLE_START_FRAME, DISSOCIATION_START_FRAME, 220, 0);
    }
    strandAlpha = constrain(strandAlpha, 0, 220);
    
    for (Particle p : particles) p.display();

    if (strandAlpha > 1) {
      noFill();
      strokeWeight(lerp(STRAND_WEIGHT, 0.8, evolution));
      for (int side = -1; side <= 1; side += 2) {
        stroke(side == -1 ? currentColors[1] : currentColors[2], strandAlpha);
        beginShape();
        for (int i = 0; i < SEGMENTS; i++) {
          float xOff = side * (separation * 0.5);
          curveVertex(constrain(nodes[i].x + xOff, PADDING, width-PADDING), nodes[i].y);
        }
        endShape();
      }
    }
  }
}

class Particle {
  PVector pos, vel, offset;
  PVector anchor; 
  float lifespan = 255;
  int bandIdx;

  Particle(float x, float y, int band, PVector nodeAnchor) {
    pos = new PVector(x, y);
    anchor = nodeAnchor;
    offset = new PVector(random(-15, 15), random(-5, 5));
    vel = PVector.random2D().mult(random(8, 16));
    bandIdx = band;
  }

  void update() {
    if (frameCount < DISSOCIATION_START_FRAME) {
      pos.x = anchor.x + offset.x;
      pos.y = anchor.y + offset.y;
      lifespan -= 2.5;
    } else {
      pos.add(vel);
      lifespan -= 1.0; 
    }
  }

  void display() {
    float amp = fft.getBand(bandIdx % fft.specSize());
    float pSize;
    
    if (frameCount >= DISSOCIATION_START_FRAME) {
      pSize = MAX_PARTICLE_SIZE;
    } else {
      pSize = map(amp, 0, 20, MIN_PARTICLE_SIZE, MAX_PARTICLE_SIZE);
      pSize = constrain(pSize, MIN_PARTICLE_SIZE, MAX_PARTICLE_SIZE);
    }
    
    int colorIdx = (int)map(amp, 0, 15, 1, 4);
    int pCol = currentColors[constrain(colorIdx, 1, 4)];
    
    if (pos.x > (PADDING - HORIZONTAL_EXCURSION) && pos.x < (width - PADDING + HORIZONTAL_EXCURSION)) {
      stroke(pCol, lifespan);
      strokeWeight(pSize);
      point(pos.x, pos.y);
    }
  }

  boolean isDead() { return lifespan < 0; }
}

void drawUI() {
  float barY = height - 20;
  float progress = map(frameCount, 0, MAX_FRAMES, PADDING, width - PADDING);
  fill(currentColors[3], 40);
  noStroke();
  rect(PADDING, barY - 1, width - 2*PADDING, 2);
  fill(currentColors[4]);
  ellipse(progress, barY, 8, 8);
  
  textAlign(CENTER);
  textSize(10);
  fill(currentColors[4]);
  
  String status = "BUFFERED SYNC ACTIVE";
  if (frameCount >= PARTICLE_START_FRAME) status = "MUTATION TO PARTICLES";
  if (frameCount >= DISSOCIATION_START_FRAME) status = "DISSOCIATION ACTIVE";
  
  text(status, width/2, barY - 12);
}

void drawDebugGrid() {
  stroke(currentColors[2], 15);
  for (int i = 0; i <= width; i += 40) line(i, 0, i, height);
  for (int j = 0; j <= height; j += 40) line(0, j, width, j);
}

void stop() {
  sample.close();
  minim.stop();
  super.stop();
}
