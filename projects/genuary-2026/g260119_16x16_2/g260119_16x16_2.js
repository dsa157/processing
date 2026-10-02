/**
 * Genuary 2026 - Day 19: 16x16 (Alternative Design) 
 * Flow Field Voxels - Seamless Y-Rotation (Three.js Version)
 * Version: 2026.10.02.12.54.00
 * Description: 16x16 grid with a seamless looping noise field and optional
 * full Y-axis rotation over the loop duration converted to Three.js.
 */

// --- Parameters ---
let SKETCH_WIDTH = 800;             // Canvas width (default: 800, converted from original 480)
let SKETCH_HEIGHT = 800;            // Canvas height (default: 800)
let PADDING = 40;                   // Grid padding in pixels (default: 40)
let MAX_FRAMES = 900;               // Maximum frames before pausing (default: 900)
let ANIMATION_SPEED = 30;           // Frames per second (default: 30)
let GLOBAL_SEED = 12345;            // Global pseudo-random & noise seed (default: 12345)

let LOOP_LENGTH = 180;              // Frames per seamless loop (default: 180)
let GRID_RES = 16;                  // Voxel grid resolution 16x16 (default: 16)
let NOISE_SCALE = 0.006;            // Spatial scale factor for Perlin noise (default: 0.006)
let SHOW_GRID = false;              // Display wireframe grid cells outline (default: false)
let INVERT_BG = false;              // Invert background color selection (default: false)

// Effect Toggles & Ranges
let ENABLE_WAVE = true;             // Toggle vertical Z-wave motion (default: true)
let ENABLE_Y_ROTATION = false;      // Toggle full 360-degree Y-axis rotation (default: false)
let WAVE_AMPLITUDE = 100.0;         // Maximum amplitude of Z-wave (default: 100.0)
let SIZE_MIN = 0.45;                // Minimum scale factor for voxels (default: 0.45)
let SIZE_MAX = 0.9;                 // Maximum scale factor for voxels (default: 0.9)
let OUTER_MOTION_MULT = 2.5;        // Outer perimeter motion multiplier (default: 2.5)

// Rotation Multipliers for Individual Voxels
let VOXEL_ROT_X_MULT = 0.3;         // Voxel X-axis rotation sensitivity (default: 0.3)
let VOXEL_ROT_Y_MULT = 0.7;         // Voxel Y-axis rotation sensitivity (default: 0.7)
let VOXEL_ROT_Z_MULT = 1.0;         // Voxel Z-axis rotation sensitivity (default: 1.0)
let MOTION_SENS_BASE = 2.0;         // Base motion sensitivity coefficient (default: 2.0)
let NOISE_OFFSET_RADIUS = 0.5;      // Radius of circular loop offset in noise space (default: 0.5)

// 3D Rendering & Camera Parameters
let CAMERA_FOV = 60.0;              // Perspective camera field of view in degrees (default: 60.0)
let CAMERA_NEAR = 1.0;              // Near clipping plane distance (default: 1.0)
let CAMERA_FAR = 10000.0;           // Far clipping plane distance (default: 10000.0)
let CAMERA_DISTANCE = 692.82;       // Distance matching Processing P3D perspective (default: 692.82)
let VOXEL_ROUGHNESS = 0.35;         // Material roughness for voxels (default: 0.35)
let VOXEL_METALNESS = 0.1;          // Material metalness for voxels (default: 0.1)
let GRID_OUTLINE_ALPHA = 0.12;      // Opacity for grid outlines when SHOW_GRID is true (default: 0.12)

// Lighting Parameters
let POINT_LIGHT_COLOR = 0xffffff;   // Point light color (default: 0xffffff)
let POINT_LIGHT_INTENSITY = 0.9;    // Point light intensity (default: 0.9)
let POINT_LIGHT_X = 200.0;          // Point light X position (default: 200.0)
let POINT_LIGHT_Y = 200.0;          // Point light Y position (default: 200.0)
let POINT_LIGHT_Z = 400.0;          // Point light Z position (default: 400.0)

let DIR_LIGHT_COLOR = 0x969696;     // Directional light color (default: 0x969696, rgb 150,150,150)
let DIR_LIGHT_INTENSITY = 0.8;      // Directional light intensity (default: 0.8)
let DIR_LIGHT_X = 200.0;            // Directional light position X (shining toward origin) (default: 200.0)
let DIR_LIGHT_Y = 200.0;            // Directional light position Y (default: 200.0)
let DIR_LIGHT_Z = 200.0;            // Directional light position Z (default: 200.0)

let AMBIENT_LIGHT_COLOR = 0x323232; // Ambient light color (default: 0x323232, rgb 50,50,50)
let AMBIENT_LIGHT_INTENSITY = 0.6;  // Ambient light intensity (default: 0.6)

// Color Palettes (Curated from Adobe Kuler / Color Schemes)
let PALETTE_INDEX = 1;              // Active palette selector [0-4] (default: 1)
const PALETTES = [
  // Palette 0: Sandy Stone & Terracotta (Warm Earthy Minerals)
  ["#264653", "#2a9d8f", "#e9c46a", "#f4a261", "#e76f51"],
  // Palette 1: Deep Emerald Ocean (Coastal Lagoon & Gold Sand)
  ["#001219", "#005f73", "#0a9396", "#94d2bd", "#e9d8a6"],
  // Palette 2: Warm Sunset Fire (Rich Velvet Crimson & Tangerine)
  ["#5f0f40", "#9a031e", "#fb8b24", "#e36414", "#0f4c5c"],
  // Palette 3: Muted Mauve Twilight (Dusty Violet & Warm Alabaster)
  ["#22223b", "#4a4e69", "#9a8c98", "#c9ada7", "#f2e9e4"],
  // Palette 4: Cyberpunk Neon Flare (Midnight Blue & Electric Cyan/Red)
  ["#011627", "#fdfffc", "#2ec4b6", "#e71d36", "#ff9f1c"]
];

// --- Internal Variables ---
let cellSize = 0;
let gridWidth = 0;
let colorIndices = [];

let scene, camera, renderer, controls;
let gridGroup;
let voxelMeshes = [];
let voxelMaterials = [];
let gridLinesMesh = null;
let gridLinesMaterial = null;

let frameCount = 0;
let isPlaying = true;
let lastFrameTime = 0;

// Seeded PRNG using Mulberry32 algorithm
function createMulberry32(seed) {
  let s = Math.floor(seed) >>> 0;
  return function () {
    s = (s + 0x6D2B79F5) >>> 0;
    let t = Math.imul(s ^ (s >>> 15), 1 | s);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

// Seeded 3D Perlin Noise Generator (Matching Processing 4-octave smooth noise)
let perlinNoise3D = null;
function initNoiseGenerator(seed) {
  const rng = createMulberry32(seed);
  const p = new Uint8Array(256);
  for (let i = 0; i < 256; i++) p[i] = i;
  for (let i = 255; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    const tmp = p[i];
    p[i] = p[j];
    p[j] = tmp;
  }
  const perm = new Uint8Array(512);
  const permMod12 = new Uint8Array(512);
  for (let i = 0; i < 512; i++) {
    perm[i] = p[i & 255];
    permMod12[i] = perm[i] % 12;
  }

  const grad3 = [
    [1, 1, 0], [-1, 1, 0], [1, -1, 0], [-1, -1, 0],
    [1, 0, 1], [-1, 0, 1], [1, 0, -1], [-1, 0, -1],
    [0, 1, 1], [0, -1, 1], [0, 1, -1], [0, -1, -1]
  ];

  function fade(t) {
    return t * t * t * (t * (t * 6 - 15) + 10);
  }

  function lerp(a, b, t) {
    return a + t * (b - a);
  }

  function dot(g, x, y, z) {
    return g[0] * x + g[1] * y + g[2] * z;
  }

  function singleNoise(x, y, z) {
    const X = Math.floor(x) & 255;
    const Y = Math.floor(y) & 255;
    const Z = Math.floor(z) & 255;

    const xf = x - Math.floor(x);
    const yf = y - Math.floor(y);
    const zf = z - Math.floor(z);

    const u = fade(xf);
    const v = fade(yf);
    const w = fade(zf);

    const A = perm[X] + Y;
    const AA = perm[A] + Z;
    const AB = perm[A + 1] + Z;
    const B = perm[X + 1] + Y;
    const BA = perm[B] + Z;
    const BB = perm[B + 1] + Z;

    const g000 = grad3[permMod12[AA]];
    const g100 = grad3[permMod12[BA]];
    const g010 = grad3[permMod12[AB]];
    const g110 = grad3[permMod12[BB]];
    const g001 = grad3[permMod12[AA + 1]];
    const g101 = grad3[permMod12[BA + 1]];
    const g011 = grad3[permMod12[AB + 1]];
    const g111 = grad3[permMod12[BB + 1]];

    const d000 = dot(g000, xf, yf, zf);
    const d100 = dot(g100, xf - 1, yf, zf);
    const d010 = dot(g010, xf, yf - 1, zf);
    const d110 = dot(g110, xf - 1, yf - 1, zf);
    const d001 = dot(g001, xf, yf, zf - 1);
    const d101 = dot(g101, xf - 1, yf, zf - 1);
    const d011 = dot(g011, xf, yf - 1, zf - 1);
    const d111 = dot(g111, xf - 1, yf - 1, zf - 1);

    const x1 = lerp(d000, d100, u);
    const x2 = lerp(d010, d110, u);
    const y1 = lerp(x1, x2, v);

    const x3 = lerp(d001, d101, u);
    const x4 = lerp(d011, d111, u);
    const y2 = lerp(x3, x4, v);

    return (lerp(y1, y2, w) + 1.0) * 0.5;
  }

  return function (x, y, z) {
    let total = 0;
    let frequency = 1.0;
    let amplitude = 1.0;
    let maxAmp = 0;
    for (let o = 0; o < 4; o++) {
      total += singleNoise(x * frequency, y * frequency, z * frequency) * amplitude;
      maxAmp += amplitude;
      amplitude *= 0.5;
      frequency *= 2.0;
    }
    return total / maxAmp;
  };
}

// Initialize randomized voxel color indices based on GLOBAL_SEED
function initColorIndices() {
  const rng = createMulberry32(GLOBAL_SEED);
  colorIndices = [];
  for (let i = 0; i < GRID_RES; i++) {
    colorIndices[i] = [];
    for (let j = 0; j < GRID_RES; j++) {
      if (INVERT_BG) {
        colorIndices[i][j] = Math.floor(rng() * 4); // 0, 1, 2, 3
      } else {
        colorIndices[i][j] = 1 + Math.floor(rng() * 4); // 1, 2, 3, 4
      }
    }
  }
}

// Update active palette colors on materials and scene background
function updateColors() {
  const currentPalette = PALETTES[PALETTE_INDEX];
  const bgColorHex = INVERT_BG ? currentPalette[currentPalette.length - 1] : currentPalette[0];
  scene.background = new THREE.Color(bgColorHex);

  for (let c = 0; c < currentPalette.length; c++) {
    if (voxelMaterials[c]) {
      voxelMaterials[c].color.set(currentPalette[c]);
    }
  }

  if (gridLinesMaterial) {
    gridLinesMaterial.color.set(currentPalette[2]);
  }
}

// Initialize the Three.js 3D scene, camera, lights, and geometry
function initScene() {
  const container = document.getElementById("canvas-container") || document.body;

  gridWidth = SKETCH_WIDTH - (PADDING * 2);
  cellSize = gridWidth / GRID_RES;

  perlinNoise3D = initNoiseGenerator(GLOBAL_SEED);
  initColorIndices();

  // Create Scene
  scene = new THREE.Scene();

  // Create Camera
  camera = new THREE.PerspectiveCamera(CAMERA_FOV, SKETCH_WIDTH / SKETCH_HEIGHT, CAMERA_NEAR, CAMERA_FAR);
  camera.position.set(0, 0, CAMERA_DISTANCE);
  camera.lookAt(0, 0, 0);

  // Create Renderer
  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false });
  renderer.setSize(SKETCH_WIDTH, SKETCH_HEIGHT);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  container.appendChild(renderer.domElement);

  // Setup OrbitControls
  if (typeof THREE.OrbitControls !== "undefined") {
    controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.05;
  }

  // Setup Lights
  const pointLight = new THREE.PointLight(POINT_LIGHT_COLOR, POINT_LIGHT_INTENSITY);
  pointLight.position.set(POINT_LIGHT_X, POINT_LIGHT_Y, POINT_LIGHT_Z);
  scene.add(pointLight);

  const dirLight = new THREE.DirectionalLight(DIR_LIGHT_COLOR, DIR_LIGHT_INTENSITY);
  dirLight.position.set(DIR_LIGHT_X, DIR_LIGHT_Y, DIR_LIGHT_Z);
  scene.add(dirLight);

  const ambientLight = new THREE.AmbientLight(AMBIENT_LIGHT_COLOR, AMBIENT_LIGHT_INTENSITY);
  scene.add(ambientLight);

  // Create Materials for the 5 Palette Colors
  const currentPalette = PALETTES[PALETTE_INDEX];
  voxelMaterials = [];
  for (let c = 0; c < 5; c++) {
    voxelMaterials.push(
      new THREE.MeshStandardMaterial({
        color: currentPalette[c],
        roughness: VOXEL_ROUGHNESS,
        metalness: VOXEL_METALNESS
      })
    );
  }

  // Create Grid Group
  gridGroup = new THREE.Group();
  scene.add(gridGroup);

  // Create Unit Box Geometry
  const boxGeometry = new THREE.BoxGeometry(1, 1, 1);

  // Build Voxel Meshes (16x16)
  voxelMeshes = [];
  for (let i = 0; i < GRID_RES; i++) {
    voxelMeshes[i] = [];
    for (let j = 0; j < GRID_RES; j++) {
      const matIndex = colorIndices[i][j];
      const mesh = new THREE.Mesh(boxGeometry, voxelMaterials[matIndex]);
      gridGroup.add(mesh);
      voxelMeshes[i][j] = mesh;
    }
  }

  // Build Optional Grid Cell Outlines
  buildGridLines();

  // Apply Initial Colors
  updateColors();

  // Event Listeners for Interactivity
  window.addEventListener("keydown", handleKeyDown);
  renderer.domElement.addEventListener("click", () => {
    PALETTE_INDEX = (PALETTE_INDEX + 1) % PALETTES.length;
    updateColors();
  });

  // Start Animation Loop
  requestAnimationFrame(animate);
}

// Build wireframe cell outline squares for SHOW_GRID mode
function buildGridLines() {
  const linePositions = [];
  const halfCell = cellSize * 0.5;

  for (let i = 0; i < GRID_RES; i++) {
    for (let j = 0; j < GRID_RES; j++) {
      const cx = (i * cellSize) - (gridWidth / 2) + halfCell;
      const cy = ((GRID_RES - 1 - j) * cellSize) - (gridWidth / 2) + halfCell;

      const x0 = cx - halfCell, x1 = cx + halfCell;
      const y0 = cy - halfCell, y1 = cy + halfCell;

      // 4 segment boundary for cell rectangle
      linePositions.push(x0, y0, 0, x1, y0, 0);
      linePositions.push(x1, y0, 0, x1, y1, 0);
      linePositions.push(x1, y1, 0, x0, y1, 0);
      linePositions.push(x0, y1, 0, x0, y0, 0);
    }
  }

  const lineGeo = new THREE.BufferGeometry();
  lineGeo.setAttribute("position", new THREE.Float32BufferAttribute(linePositions, 3));
  gridLinesMaterial = new THREE.LineBasicMaterial({
    color: PALETTES[PALETTE_INDEX][2],
    transparent: true,
    opacity: GRID_OUTLINE_ALPHA
  });

  gridLinesMesh = new THREE.LineSegments(lineGeo, gridLinesMaterial);
  gridLinesMesh.visible = SHOW_GRID;
  gridGroup.add(gridLinesMesh);
}

// Animation and rendering loop
function animate(timestamp) {
  requestAnimationFrame(animate);

  if (!isPlaying) return;

  // Frame-rate throttle to match ANIMATION_SPEED (30 FPS)
  const frameInterval = 1000 / ANIMATION_SPEED;
  if (!lastFrameTime) lastFrameTime = timestamp;
  const elapsed = timestamp - lastFrameTime;

  if (elapsed < frameInterval) return;
  lastFrameTime = timestamp - (elapsed % frameInterval);

  if (controls) controls.update();

  // Calculate seamless loop progress
  const percent = (frameCount % LOOP_LENGTH) / LOOP_LENGTH;
  const angleLoop = Math.PI * 2 * percent;

  // Circular offsets for noise consistency
  const noiseXOffset = Math.cos(angleLoop) * NOISE_OFFSET_RADIUS;
  const noiseYOffset = Math.sin(angleLoop) * NOISE_OFFSET_RADIUS;

  // Toggleable Y-Axis Rotation for the whole grid
  if (ENABLE_Y_ROTATION) {
    gridGroup.rotation.y = angleLoop;
  } else {
    gridGroup.rotation.y = 0;
  }

  const maxDist = gridWidth / Math.SQRT2;

  for (let i = 0; i < GRID_RES; i++) {
    for (let j = 0; j < GRID_RES; j++) {
      const x = (i * cellSize) - (gridWidth / 2) + (cellSize / 2);
      // Processing Y coordinates are positive downward; map j=0 to top (+Y in Three.js)
      const yProcessing = (j * cellSize) - (gridWidth / 2) + (cellSize / 2);
      const yThree = ((GRID_RES - 1 - j) * cellSize) - (gridWidth / 2) + (cellSize / 2);

      const distToCenter = Math.hypot(x, yProcessing);
      const normDist = Math.min(1.0, Math.max(0.0, distToCenter / maxDist));

      // Multi-dimensional seamless noise
      const noiseVal = perlinNoise3D(
        x * NOISE_SCALE + noiseXOffset,
        yProcessing * NOISE_SCALE + noiseYOffset,
        noiseXOffset
      );

      // Rotation sensitivity increases toward edges
      const motionSens = MOTION_SENS_BASE + normDist * (MOTION_SENS_BASE * OUTER_MOTION_MULT - MOTION_SENS_BASE);
      const rotationAngle = noiseVal * Math.PI * 2 * motionSens;

      // Z-Wave effect
      let z = 0;
      if (ENABLE_WAVE) {
        z = Math.sin(noiseVal * Math.PI + angleLoop) * WAVE_AMPLITUDE * normDist;
      }

      // Scaling based on center proximity
      const scaleFactor = SIZE_MAX + normDist * (SIZE_MIN - SIZE_MAX);
      const s = cellSize * scaleFactor;

      const voxel = voxelMeshes[i][j];
      voxel.position.set(x, yThree, z);
      voxel.rotation.set(
        rotationAngle * VOXEL_ROT_X_MULT,
        rotationAngle * VOXEL_ROT_Y_MULT,
        rotationAngle * VOXEL_ROT_Z_MULT,
        "XYZ"
      );
      voxel.scale.set(s, s, s);
    }
  }

  renderer.render(scene, camera);

  frameCount++;
  if (frameCount >= MAX_FRAMES) {
    isPlaying = false;
  }
}

// Keyboard interaction handler
function handleKeyDown(e) {
  if (e.key === "b" || e.key === "B") {
    INVERT_BG = !INVERT_BG;
    initColorIndices();
    for (let i = 0; i < GRID_RES; i++) {
      for (let j = 0; j < GRID_RES; j++) {
        voxelMeshes[i][j].material = voxelMaterials[colorIndices[i][j]];
      }
    }
    updateColors();
  } else if (e.key === "g" || e.key === "G") {
    SHOW_GRID = !SHOW_GRID;
    if (gridLinesMesh) gridLinesMesh.visible = SHOW_GRID;
  } else if (e.key === "w" || e.key === "W") {
    ENABLE_WAVE = !ENABLE_WAVE;
  } else if (e.key === "y" || e.key === "Y") {
    ENABLE_Y_ROTATION = !ENABLE_Y_ROTATION;
  } else if (e.key === " ") {
    isPlaying = !isPlaying;
  }
}

// Auto-start once DOM is ready
window.addEventListener("DOMContentLoaded", initScene);
