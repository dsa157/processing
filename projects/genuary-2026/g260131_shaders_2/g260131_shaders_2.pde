/**
 * Digital Marble: Harmonic Tectonic Morph
 * Version: 2026.01.28.16.02.15
 * Focuses on the rhythmic expansion and contraction of slab geometry.
 */

// --- Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40
int GLOBAL_SEED = 999;        // Default: 12345
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 60;     // Default: 30
int PALETTE_INDEX = 3;        // Default: 0-4
boolean INVERT_BG = false;    // Default: false

// --- Shader Parameters ---
float NOISE_SCALE = 3.5;      // Default: 3.5
float TURBULENCE = 9.2;       // Default: 4.0 (Enhanced distortion)
float FLOW_SPEED = 2.0;       // Default: 0.5 (Accelerated time)
int MIN_SLABS = 21;            // Default: 8
int MAX_SLABS = 21;           // Default: 21

// --- Color Palettes ---
String[][] palettes = {
  {"#2E4057", "#848FA2", "#2D3142", "#BFC0C0", "#FFFFFF"}, 
  {"#0B090A", "#161A1D", "#660708", "#A4161A", "#BA181B"}, 
  {"#EAE2B7", "#FCBF49", "#F77F00", "#D62828", "#00304E"}, 
  {"#001219", "#005F73", "#0A9396", "#94D2BD", "#E9D8A6"}, 
  {"#22223B", "#4A4E69", "#9A8C98", "#C9ADA7", "#F2E9E4"}  
};

PShader marbleShader;
float timeTracker = 0;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT, P2D);
}

void setup() {
  frameRate(ANIMATION_SPEED);
  randomSeed(GLOBAL_SEED);
  
  String[] fragSource = {
    "#ifdef GL_ES", "precision highp float;", "#endif",
    "uniform vec2 u_resolution;",
    "uniform float u_time;",
    "uniform float u_scale;",
    "uniform float u_turbulence;",
    "uniform vec3 u_col1; uniform vec3 u_col2; uniform vec3 u_col3; uniform vec3 u_col4;",

    "float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }",
    "float noise(vec2 p) {",
    "  vec2 i = floor(p); vec2 f = fract(p);",
    "  f = f*f*(3.0-2.0*f);",
    "  return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);",
    "}",

    "float fbm(vec2 p) {",
    "  float v = 0.0; float a = 0.5;",
    "  for (int i = 0; i < 5; i++) { v += a * noise(p); p *= 2.1; a *= 0.5; }",
    "  return v;",
    "}",

    "void main() {",
    "  vec2 uv = gl_FragCoord.xy / u_resolution.xy;",
    "  vec2 p = uv * u_scale;",
    "  float n = fbm(p + u_time * 0.1);",
    "  float dist = sin(p.x + n * u_turbulence + u_time);",
    "  float finalN = fbm(p + dist);",
    "  vec3 col = mix(u_col1, u_col2, clamp(finalN * 1.5, 0.0, 1.0));",
    "  col = mix(col, u_col3, clamp(length(vec2(dist)) - 0.5, 0.0, 1.0));",
    "  col = mix(col, u_col4, clamp(finalN * finalN, 0.0, 1.0));",
    "  gl_FragColor = vec4(col, 1.0);",
    "}"
  };

  saveStrings("data/marble.glsl", fragSource);
  marbleShader = loadShader("marble.glsl");
}

void draw() {
  background(INVERT_BG ? 245 : 10);
  
  updateShaderUniforms();
  
  // Calculate Slab Morphing (Seamless Sinusoidal Cycle)
  float cycleProgress = (float)(frameCount % MAX_FRAMES) / MAX_FRAMES;
  float morphFactor = (sin(cycleProgress * TWO_PI - HALF_PI) + 1.0) / 2.0;
  int currentSlabs = round(lerp(MIN_SLABS, MAX_SLABS, morphFactor));
  
  float totalH = height - (PADDING * 2);
  float slabH = totalH / currentSlabs;
  
  for (int i = 0; i < currentSlabs; i++) {
    float yOffset = PADDING + (i * slabH);
    
    // Horizontal drift based on index and time
    float xShift = sin(timeTracker * 0.5 + i * 0.8) * 15.0;
    
    pushMatrix();
    translate(xShift, 0);
    
    shader(marbleShader);
    noStroke();
    // 2px gap between slabs for structural definition
    rect(PADDING, yOffset + 1, width - (PADDING * 2), slabH - 2); 
    resetShader();
    
    // Aesthetic accent line at the bottom of each slab
    stroke(0, 40);
    line(PADDING, yOffset + slabH - 1, width - PADDING, yOffset + slabH - 1);
    popMatrix();
  }
  
  timeTracker += 0.01 * FLOW_SPEED;

  // Frame Management
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

void updateShaderUniforms() {
  if (marbleShader != null) {
    marbleShader.set("u_time", timeTracker);
    marbleShader.set("u_resolution", (float)width, (float)height);
    marbleShader.set("u_scale", NOISE_SCALE);
    marbleShader.set("u_turbulence", TURBULENCE);
    
    String[] activePal = palettes[PALETTE_INDEX % palettes.length];
    marbleShader.set("u_col1", hexToVec(activePal[0]));
    marbleShader.set("u_col2", hexToVec(activePal[1]));
    marbleShader.set("u_col3", hexToVec(activePal[2]));
    marbleShader.set("u_col4", hexToVec(activePal[3]));
  }
}

PVector hexToVec(String hex) {
  int c = unhex("FF" + hex.substring(1));
  return new PVector(red(c)/255.0, green(c)/255.0, blue(c)/255.0);
}
