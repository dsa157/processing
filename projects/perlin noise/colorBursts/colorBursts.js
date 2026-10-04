/**
 * Color Bursts - low Field with Dynamic Color Bursts
 * Version: 2026.10.04.16.10.00
 * 
 * Description:
 * Tracing particles follow an animated 2D vector field. Periodic radial bursts ignite clusters
 * of particles into vibrant colors that trail through the field before decaying.
 */

// ==========================================
// Parameters & Configuration (No Magic Numbers)
// ==========================================

// Canvas Dimensions
let SKETCH_WIDTH = 800;                 // Canvas viewport width (default: 800, requested: 800, original pde: 450)
let SKETCH_HEIGHT = 800;                // Canvas viewport height (default: 800, original pde: 800)

// Random Seed & Reproducibility
let GLOBAL_SEED = 12345;                // Global random seed (default: 12345)

// Flow Field & Motion Dynamics (Direct PDE Equivalents)
let TIME_SPEED = 0.005;                 // Flow field time progression speed (default: 0.005)
let NOISE_SCALE = 0.01;                 // Perlin noise scale (default: 0.01, original pde: 0.01)
let STEP_SIZE = 5.0;                    // Particle step size (default: 5.0, original pde: 5)
let NUM_PARTICLES = 5000;               // Total particle count (default: 5000, original pde: 5000)
let FIELD_UPDATE_INTERVAL = 10;         // Flow field recomputation interval in frames (default: 10)
let FIELD_GRID_STEP = 4;                // Flow field spatial grid resolution in pixels (default: 4)
let FADE_ALPHA = 15;                    // Background fade alpha 0-255 (default: 15, original pde: 15)

// Color Burst Parameters
// New global variables for random color bursts
let MIN_DELAY = 1000;                   // Minimum delay in milliseconds (default: 1000) // 1 second
let MAX_DELAY = 4000;                   // Maximum delay in milliseconds (default: 4000) // 4 seconds
let NUM_COLOR_BURSTS = 3;               // Number of concurrent color bursts (default: 3)
let COLOR_RADIUS = 100.0;               // Radius for color effect (default: 100.0, original pde: 100)
let COLOR_FRAMES = 100;                 // Number of frames the color lasts (default: 100, original pde: 100)
let USE_HSB_RANDOM_BURSTS = true;       // Use vibrant random HSB bursts matching original PDE (default: true)

// 3D Depth Toggle (kept false by default to faithfully mirror original 2D PDE)
let ENABLE_3D_DEPTH = false;            // Enable 3D depth undulation (default: false)
let DEPTH_AMPLITUDE = 0.0;              // Amplitude of 3D depth (default: 0.0)

// ==========================================
// Color Palettes (Curated from Adobe Kuler / Color)
// ==========================================
// Each palette contains 5 colors: [Background, Base Particle, Burst Accent 1, Burst Accent 2, Burst Accent 3]
const PALETTES = [
  // Palette 0: "Original Monochrome & Vibrant" (Pure white background with black trails and vivid bursts)
  ["#FFFFFF", "#000000", "#FF007F", "#00F0FF", "#FFE600"],
  // Palette 1: "Paper Ink & Neon" (Ivory paper with rich ink trails)
  ["#F8F9FA", "#1A1A1D", "#FF2A6D", "#05D9E8", "#FFD700"],
  // Palette 2: "Neon Night" (Deep obsidian with luminous trails)
  ["#0B0C10", "#C5C6C7", "#66FCF1", "#45A29E", "#FF007F"],
  // Palette 3: "Botanical Aurora" (Forest dark with emerald trails)
  ["#0A1D16", "#8EB897", "#00FF87", "#60EFFF", "#B8FF66"],
  // Palette 4: "Solar Flare" (Cosmic dusk with flame trails)
  ["#0D1117", "#8B949E", "#FF3366", "#F0883E", "#FFD700"]
];

let PALETTE_INDEX = 0;                  // Selected active palette [0-4] (default: 0)
let BACKGROUND_COLOR_INDEX = 0;         // Index for background color (default: 0)
let BASE_PARTICLE_COLOR_INDEX = 1;      // Index for default particle color (default: 1)

// ==========================================
// Deterministic Seeded PRNG & Processing Perlin Noise
// ==========================================
let currentSeed = GLOBAL_SEED;

function seededRandom() {
  let t = (currentSeed += 0x6D2B79F5);
  t = Math.imul(t ^ (t >>> 15), t | 1);
  t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
}

function seededRandomRange(min, max) {
  return min + seededRandom() * (max - min);
}

// Processing standard 4-octave Perlin noise table
const PERLIN_YWRAPB = 4;
const PERLIN_YWRAP = 1 << PERLIN_YWRAPB;
const PERLIN_ZWRAPB = 8;
const PERLIN_ZWRAP = 1 << PERLIN_ZWRAPB;
const PERLIN_SIZE = 4095;
let perlinTable = new Float32Array(PERLIN_SIZE + 1);

function initNoise(seedVal) {
  currentSeed = seedVal;
  for (let i = 0; i <= PERLIN_SIZE; i++) {
    perlinTable[i] = seededRandom();
  }
}

function noise(x, y = 0, z = 0) {
  if (x < 0) x = -x;
  if (y < 0) y = -y;
  if (z < 0) z = -z;
  let xi = Math.floor(x), yi = Math.floor(y), zi = Math.floor(z);
  let xf = x - xi, yf = y - yi, zf = z - zi;
  let r = 0;
  let ampl = 0.5;
  for (let o = 0; o < 4; o++) {
    let of = xi + (yi << PERLIN_YWRAPB) + (zi << PERLIN_ZWRAPB);
    let rxf = 0.5 * (1.0 - Math.cos(xf * Math.PI));
    let ryf = 0.5 * (1.0 - Math.cos(yf * Math.PI));
    let n1 = perlinTable[of & PERLIN_SIZE];
    n1 += rxf * (perlinTable[(of + 1) & PERLIN_SIZE] - n1);
    let n2 = perlinTable[(of + PERLIN_YWRAP) & PERLIN_SIZE];
    n2 += rxf * (perlinTable[(of + PERLIN_YWRAP + 1) & PERLIN_SIZE] - n2);
    n1 += ryf * (n2 - n1);
    of += PERLIN_ZWRAP;
    n2 = perlinTable[of & PERLIN_SIZE];
    n2 += rxf * (perlinTable[(of + 1) & PERLIN_SIZE] - n2);
    let n3 = perlinTable[(of + PERLIN_YWRAP) & PERLIN_SIZE];
    n3 += rxf * (perlinTable[(of + PERLIN_YWRAP + 1) & PERLIN_SIZE] - n3);
    n2 += ryf * (n3 - n2);
    let rzf = 0.5 * (1.0 - Math.cos(zf * Math.PI));
    n1 += rzf * (n2 - n1);
    r += n1 * ampl;
    ampl *= 0.5;
    xi <<= 1; xf *= 2;
    yi <<= 1; yf *= 2;
    zi <<= 1; zf *= 2;
    if (xf >= 1.0) { xi++; xf--; }
    if (yf >= 1.0) { yi++; yf--; }
    if (zf >= 1.0) { zi++; zf--; }
  }
  return r;
}

// ==========================================
// Three.js State Variables
// ==========================================
let scene, camera, renderer;
let fadeScene, fadeCamera, fadeMaterial;
let lineGeometry, lineMaterial, lineSegments;
let positionsArray, colorsArray;

let particles = [];
let lastColorChange = 0;
let nextColorDelay = 0;
let frameCount = 0;

// Flow field grid
let gridCols = Math.ceil(SKETCH_WIDTH / FIELD_GRID_STEP);
let gridRows = Math.ceil(SKETCH_HEIGHT / FIELD_GRID_STEP);
let fieldAngles = new Float32Array(gridCols * gridRows);

// Colors
let baseColor = new THREE.Color();
let bgColor = new THREE.Color();

// ==========================================
// Particle Representation
// ==========================================
class Particle {
  constructor(x, y) {
    this.x = x;
    this.y = y;
    this.prevX = x;
    this.prevY = y;
    this.color = baseColor.clone();
    this.colorFramesLeft = 0;
  }

  update() {
    // Reset particle if it goes off-screen
    if (this.x < 0 || this.x >= SKETCH_WIDTH || this.y < 0 || this.y >= SKETCH_HEIGHT) {
      this.x = seededRandomRange(0, SKETCH_WIDTH);
      this.y = seededRandomRange(0, SKETCH_HEIGHT);
      this.prevX = this.x;
      this.prevY = this.y;
    }

    // Store current position before updating
    this.prevX = this.x;
    this.prevY = this.y;

    // Get vector from flow field grid (matching PDE field[x][y])
    let col = Math.floor(this.x / FIELD_GRID_STEP);
    let row = Math.floor(this.y / FIELD_GRID_STEP);
    col = Math.max(0, Math.min(gridCols - 1, col));
    row = Math.max(0, Math.min(gridRows - 1, row));
    let angle = fieldAngles[row * gridCols + col];

    this.x += Math.cos(angle) * STEP_SIZE;
    this.y += Math.sin(angle) * STEP_SIZE;

    // Decrease color timer
    if (this.colorFramesLeft > 0) {
      this.colorFramesLeft--;
    } else {
      this.color.copy(baseColor); // Revert to base color (black in original PDE)
    }
  }

  setColor(targetColor, frames) {
    this.color.copy(targetColor);
    this.colorFramesLeft = frames;
  }
}

// Compute flow field angles for the grid
function updateFlowField(t) {
  let idx = 0;
  for (let r = 0; r < gridRows; r++) {
    let y = r * FIELD_GRID_STEP;
    for (let c = 0; c < gridCols; c++) {
      let x = c * FIELD_GRID_STEP;
      let noiseVal = noise(x * NOISE_SCALE, y * NOISE_SCALE, t);
      // Processing mapping: map(noiseValue, 0, 1, 0, TWO_PI * 4)
      fieldAngles[idx++] = noiseVal * Math.PI * 8.0;
    }
  }
}

// ==========================================
// Color Burst Application
// ==========================================
function applyRandomColorBurst() {
  let burstColor = new THREE.Color();
  let currentPalette = PALETTES[PALETTE_INDEX];

  if (USE_HSB_RANDOM_BURSTS) {
    // Exact Processing behavior: colorMode(HSB, 255); color(random(255), 255, 255);
    burstColor.setHSL(seededRandom(), 1.0, 0.5);
  } else {
    // Pick an accent color from active palette
    let burstIndex = Math.floor(seededRandomRange(2, currentPalette.length));
    burstColor.set(currentPalette[burstIndex]);
  }

  let burstX = seededRandomRange(0, SKETCH_WIDTH);
  let burstY = seededRandomRange(0, SKETCH_HEIGHT);

  for (let i = 0; i < particles.length; i++) {
    let p = particles[i];
    let dx = p.x - burstX;
    let dy = p.y - burstY;
    let dist = Math.sqrt(dx * dx + dy * dy);
    if (dist < COLOR_RADIUS) {
      p.setColor(burstColor, COLOR_FRAMES);
    }
  }
}

// ==========================================
// Initialization
// ==========================================
function init() {
  const container = document.getElementById("canvas-container");

  // 1. Initialize PRNG and Perlin noise
  initNoise(GLOBAL_SEED);

  // 2. Setup Color Variables
  let currentPalette = PALETTES[PALETTE_INDEX];
  bgColor.set(currentPalette[BACKGROUND_COLOR_INDEX]);
  baseColor.set(currentPalette[BASE_PARTICLE_COLOR_INDEX]);

  // 3. Three.js Scene & Orthographic 2D Camera
  // Maps 1-to-1 with Processing 2D screen coordinates: (0,0) is top-left, (width, height) is bottom-right
  scene = new THREE.Scene();

  camera = new THREE.OrthographicCamera(0, SKETCH_WIDTH, 0, SKETCH_HEIGHT, -10, 10);
  camera.position.z = 1;

  // 4. WebGL Renderer with alpha: false and preserveDrawingBuffer: true
  // alpha: false ensures no transparency blending with the webpage background
  renderer = new THREE.WebGLRenderer({
    antialias: true,
    preserveDrawingBuffer: true,
    alpha: false
  });
  renderer.setSize(SKETCH_WIDTH, SKETCH_HEIGHT);
  renderer.setPixelRatio(window.devicePixelRatio || 1);
  renderer.autoClear = false;
  container.appendChild(renderer.domElement);

  // 5. Fade Screen Quad for Exact Motion Trails
  // Exactly corresponds to Processing's fill(255, 15); rect(0, 0, width, height);
  fadeScene = new THREE.Scene();
  fadeCamera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
  fadeMaterial = new THREE.MeshBasicMaterial({
    color: bgColor,
    transparent: true,
    opacity: FADE_ALPHA / 255.0,
    depthTest: false,
    depthWrite: false
  });
  const fadeQuad = new THREE.Mesh(new THREE.PlaneGeometry(2, 2), fadeMaterial);
  fadeScene.add(fadeQuad);

  // 6. Particle System (LineSegments with BufferGeometry)
  positionsArray = new Float32Array(NUM_PARTICLES * 2 * 3);
  colorsArray = new Float32Array(NUM_PARTICLES * 2 * 3);

  lineGeometry = new THREE.BufferGeometry();
  lineGeometry.setAttribute('position', new THREE.BufferAttribute(positionsArray, 3));
  lineGeometry.setAttribute('color', new THREE.BufferAttribute(colorsArray, 3));

  lineMaterial = new THREE.LineBasicMaterial({
    vertexColors: true,
    transparent: false,
    depthTest: false,
    depthWrite: false
  });

  lineSegments = new THREE.LineSegments(lineGeometry, lineMaterial);
  scene.add(lineSegments);

  // 7. Initial Flow Field Computation
  updateFlowField(0);

  // 8. Create Particles (matching Processing setup loop)
  particles = [];
  for (let i = 0; i < NUM_PARTICLES; i++) {
    let px = seededRandomRange(0, SKETCH_WIDTH);
    let py = seededRandomRange(0, SKETCH_HEIGHT);
    particles.push(new Particle(px, py));
  }

  nextColorDelay = Math.floor(seededRandomRange(MIN_DELAY, MAX_DELAY));
  lastColorChange = performance.now();

  // Clear initial frame with solid background
  renderer.setClearColor(bgColor, 1.0);
  renderer.clear();

  // Start Animation Loop
  animate();
}

// ==========================================
// Animation Loop
// ==========================================
function animate() {
  requestAnimationFrame(animate);

  frameCount++;
  let now = performance.now();

  // Check for random color event (matching PDE millis() > lastColorChange + nextColorDelay)
  if (now > lastColorChange + nextColorDelay) {
    for (let x = 0; x < NUM_COLOR_BURSTS; x++) {
      applyRandomColorBurst();
    }
    lastColorChange = now;
    nextColorDelay = Math.floor(seededRandomRange(MIN_DELAY, MAX_DELAY));
  }

  // Animate the flow field over time (matching PDE: if (frameCount % 10 == 0))
  if (frameCount % FIELD_UPDATE_INTERVAL === 0) {
    updateFlowField(frameCount * TIME_SPEED);
  }

  // Update particles and populate vertex buffers
  let posIdx = 0;
  let colIdx = 0;

  for (let i = 0; i < NUM_PARTICLES; i++) {
    let p = particles[i];
    p.update();

    // Vertex 1: Previous Position (prevPosition.x, prevPosition.y)
    positionsArray[posIdx++] = p.prevX;
    positionsArray[posIdx++] = p.prevY;
    positionsArray[posIdx++] = 0;

    colorsArray[colIdx++] = p.color.r;
    colorsArray[colIdx++] = p.color.g;
    colorsArray[colIdx++] = p.color.b;

    // Vertex 2: Current Position (position.x, position.y)
    positionsArray[posIdx++] = p.x;
    positionsArray[posIdx++] = p.y;
    positionsArray[posIdx++] = 0;

    colorsArray[colIdx++] = p.color.r;
    colorsArray[colIdx++] = p.color.g;
    colorsArray[colIdx++] = p.color.b;
  }

  lineGeometry.attributes.position.needsUpdate = true;
  lineGeometry.attributes.color.needsUpdate = true;

  // 1. Semi-transparent overlay for motion trails (equivalent to fill(255, 15); rect(0, 0, width, height);)
  renderer.render(fadeScene, fadeCamera);

  // 2. Render current line segments
  renderer.render(scene, camera);
}

// Start once DOM is ready
window.addEventListener('DOMContentLoaded', init);
