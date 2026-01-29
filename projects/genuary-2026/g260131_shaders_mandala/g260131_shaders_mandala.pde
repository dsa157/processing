/**
 * Kaleidoscope Mandala Shader
 * Technique: UV folding into N radial sectors using atan2 and mod.
 * Fix: Added pixelDensity multiplier to u_resolution to fix high-DPI quadrant rendering.
 */

// --- Global Parameters ---
int SKETCH_WIDTH = 480;      // default: 480
int SKETCH_HEIGHT = 800;     // default: 800
int SEED_VALUE = 42;         // default: 42
int PADDING = 40;            // default: 40
int MAX_FRAMES = 900;        // default: 900
boolean SAVE_FRAMES = false; // default: false
int ANIMATION_SPEED = 60;    // default: 60 fps
int PALETTE_INDEX = 3;       // default: 0-4
boolean INVERT_BG = false;   // default: false

// --- Shader Parameters ---
int SYMMETRY_SECTORS = 12;   // default: 12
float BLOOM_STRENGTH = 1.8;  // default: 1.8
float SPIN_SPEED = 0.5;      // default: 0.5

// --- Color Palettes ---
String[][] PALETTES = {
  {"#2E112D", "#540032", "#820333", "#C02739", "#F1E4E8"}, 
  {"#001B2E", "#294C60", "#ADB5BD", "#FFEFD3", "#FFD60A"}, 
  {"#1A1A1A", "#4E598C", "#AFCBFF", "#FFFFFF", "#F9C784"}, 
  {"#2B2D42", "#8D99AE", "#EDF2F4", "#EF233C", "#D90429"}, 
  {"#011627", "#FDFFFC", "#2EC4B6", "#E71D36", "#FF9F1C"}  
};

PShader mandalaShader;
color bgColor, accent1, accent2, accent3;

void settings() {
  size(SKETCH_WIDTH, SKETCH_HEIGHT, P2D);
  pixelDensity(displayDensity()); // Account for high-DPI screens
}

void setup() {
  randomSeed(SEED_VALUE);
  frameRate(ANIMATION_SPEED);
  
  String[] activePalette = PALETTES[PALETTE_INDEX];
  bgColor = unhex("FF" + activePalette[0].substring(1));
  accent1 = unhex("FF" + activePalette[1].substring(1));
  accent2 = unhex("FF" + activePalette[2].substring(1));
  accent3 = unhex("FF" + activePalette[3].substring(1));
  
  if (INVERT_BG) {
    bgColor = color(255 - red(bgColor), 255 - green(bgColor), 255 - blue(bgColor));
  }

  String[] vertSource = {
    "#version 410",
    "uniform mat4 transform;",
    "in vec4 position;",
    "void main() {",
    "  gl_Position = transform * position;",
    "}"
  };

  String[] fragSource = {
    "#version 410",
    "uniform vec2 u_resolution;",
    "uniform float u_time;",
    "uniform int u_sectors;",
    "uniform vec3 u_color1;",
    "uniform vec3 u_color2;",
    "uniform vec3 u_color3;",
    "uniform float u_bloom;",
    "uniform float u_padding;",
    "out vec4 fragColor;",

    "void main() {",
    "  // Corrected UV centering for high-DPI",
    "  vec2 uv = (gl_FragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.y, u_resolution.x);",
    "  ",
    "  // Corrected Padding check",
    "  vec2 border = (u_resolution - vec2(u_padding * 2.0)) * 0.5;",
    "  vec2 distFromCenter = abs(gl_FragCoord.xy - u_resolution.xy * 0.5);",
    "  if (distFromCenter.x > border.x || distFromCenter.y > border.y) {",
    "    discard;",
    "  }",
    "  ",
    "  float r = length(uv);",
    "  float a = atan(uv.y, uv.x) + u_time * 0.2;",
    "  ",
    "  float sector = 6.2831853 / float(u_sectors);",
    "  a = mod(a, sector) - sector * 0.5;",
    "  a = abs(a);",
    "  ",
    "  vec2 p = vec2(cos(a), sin(a)) * r;",
    "  ",
    "  // Pattern",
    "  float circle1 = abs(r - 0.35 + sin(u_time * 0.5) * 0.05);",
    "  float lines = abs(p.y - 0.01 * sin(r * 40.0 + u_time));",
    "  ",
    "  vec3 col = vec3(0.0);",
    "  col += u_color1 * (0.006 / circle1);",
    "  col += u_color2 * (0.003 / lines);",
    "  col += u_color3 * (0.01 / (r + 0.01));",
    "  ",
    "  col *= u_bloom;",
    "  col *= smoothstep(0.8, 0.2, r);",
    "  ",
    "  fragColor = vec4(col, 1.0);",
    "}"
  };

  mandalaShader = new PShader(this, vertSource, fragSource);
}

void draw() {
  background(bgColor);
  
  // u_resolution must be physical pixels, not CSS pixels
  mandalaShader.set("u_resolution", (float)width * pixelDensity, (float)height * pixelDensity);
  mandalaShader.set("u_time", millis() / 1000.0 * SPIN_SPEED);
  mandalaShader.set("u_sectors", SYMMETRY_SECTORS);
  mandalaShader.set("u_bloom", BLOOM_STRENGTH);
  mandalaShader.set("u_padding", (float)PADDING * pixelDensity);
  
  mandalaShader.set("u_color1", red(accent1)/255.0, green(accent1)/255.0, blue(accent1)/255.0);
  mandalaShader.set("u_color2", red(accent2)/255.0, green(accent2)/255.0, blue(accent2)/255.0);
  mandalaShader.set("u_color3", red(accent3)/255.0, green(accent3)/255.0, blue(accent3)/255.0);

  shader(mandalaShader);
  rect(0, 0, width, height);
  resetShader();

  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
    if (frameCount >= MAX_FRAMES) noLoop();
  }
}
