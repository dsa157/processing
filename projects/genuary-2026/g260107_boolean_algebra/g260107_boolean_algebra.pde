/**
 * XOR Interference Visualization
 * Two procedural 3D line patterns combined via XOR logic.
 * Parameterized for line thickness and rotation complexity.
 * Version: 2026.01.04.21.28.42
 */

// --- Canvas Parameters ---
int SKETCH_WIDTH = 480;       // Default: 480
int SKETCH_HEIGHT = 800;      // Default: 800
int PADDING = 40;             // Default: 40

// --- Animation Parameters ---
int MAX_FRAMES = 900;         // Default: 900
boolean SAVE_FRAMES = false;  // Default: false
int ANIMATION_SPEED = 30;     // Default: 30
int SEED_VALUE = 42;          // Default: 42

// --- Visual Tuning Parameters ---
float THICKNESS_RATIO = 0.86; // Default: 0.96 (Higher = Thinner lines, 0.0 to 1.0)
float ROT_COMPLEXITY = 1.5;   // Default: 1.5 (Multiplies rotation speed/offset)
float PATTERN_SCALE_A = 28.0; // Default: 18.0
float PATTERN_SCALE_B = 32.0; // Default: 12.0
boolean SHOW_GRID = false;    // Default: false
boolean INVERT_COLORS = false; // Default: false

// --- Color Palette (Adobe Color) ---
String[] HEX_PALETTE = {
  "#0B0D17", // Background (Index 0)
  "#00FFC5", // Primary Neon
  "#0072FF", // Secondary Blue
  "#FF0072", // Accent Pink
  "#FFFFFF"  // White
};

PShader xorShader;
float timeVar = 0;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT, P2D);
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  xorShader = createXorShader();
}

void draw() {
  int bgColor = unhex("FF" + HEX_PALETTE[0].substring(1));
  int fgColor = unhex("FF" + HEX_PALETTE[1].substring(1));
  
  if (INVERT_COLORS) {
    background(fgColor);
    xorShader.set("u_colorMode", 1.0); 
  } else {
    background(bgColor);
    xorShader.set("u_colorMode", 0.0);
  }

  // Update Shader Uniforms
  timeVar += 0.01;
  xorShader.set("u_time", timeVar);
  xorShader.set("u_resolution", (float)width, (float)height);
  xorShader.set("u_padding", (float)PADDING);
  xorShader.set("u_showGrid", SHOW_GRID ? 1.0 : 0.0);
  
  // Custom Parameters passed to Shader
  xorShader.set("u_thickness", THICKNESS_RATIO);
  xorShader.set("u_rotComp", ROT_COMPLEXITY);
  xorShader.set("u_scaleA", PATTERN_SCALE_A);
  xorShader.set("u_scaleB", PATTERN_SCALE_B);
  
  shader(xorShader);
  rect(PADDING, PADDING, width - (PADDING * 2), height - (PADDING * 2));
  resetShader();

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}

PShader createXorShader() {
  String[] vertSource = {
    "#version 150",
    "uniform mat4 transform;",
    "in vec4 vertex;",
    "void main() {",
    "  gl_Position = transform * vertex;",
    "}"
  };

  String[] fragSource = {
    "#version 150",
    "out vec4 fragColor;",
    "uniform vec2 u_resolution;",
    "uniform float u_time;",
    "uniform float u_padding;",
    "uniform float u_showGrid;",
    "uniform float u_colorMode;",
    "uniform float u_thickness;",
    "uniform float u_rotComp;",
    "uniform float u_scaleA;",
    "uniform float u_scaleB;",

    "float getPattern(vec2 uv, float rotation, float scale) {",
    "    float s = sin(rotation), c = cos(rotation);",
    "    mat2 rot = mat2(c, -s, s, c);",
    "    vec2 st = uv * rot;",
    "    vec2 grid = abs(sin(st * scale));",
    "    return step(u_thickness, max(grid.x, grid.y));",
    "}",

    "void main() {",
    "    vec2 uv = (gl_FragCoord.xy - vec2(u_padding)) / (u_resolution - vec2(u_padding * 2.0));",
    "    ",
    "    // Pattern A & B logic using Rotation Complexity",
    "    float patA = getPattern(uv - 0.5, u_time * 0.4 * u_rotComp, u_scaleA);",
    "    float patB = getPattern(uv - 0.5, -u_time * 0.2 * u_rotComp + (u_rotComp * 0.5), u_scaleB);",
    "    ",
    "    float xor = abs(patA - patB);",
    "    ",
    "    if(u_showGrid > 0.5) {",
    "        float g = step(0.995, fract(uv.x * 20.0)) + step(0.995, fract(uv.y * 20.0));",
    "        xor = max(xor, g * 0.3);",
    "    }",
    "    ",
    "    vec3 color = vec3(xor);",
    "    if(u_colorMode > 0.5) { color = 1.0 - color; }",
    "    ",
    "    fragColor = vec4(color, 1.0);",
    "}"
  };

  return new PShader(this, vertSource, fragSource);
}
