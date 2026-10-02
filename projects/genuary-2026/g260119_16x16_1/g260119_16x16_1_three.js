/**
 * Genuary 2026 - Day 19: 16x16
 * Seamless Kinetic Cube Loop (Three.js Version)
 * Version: 2026.10.02.12.40.00
 * Author: dsa157@gmail.com
 * 
 * Description:
 * High-performance Three.js implementation of the 3D kinetic lattice cube (16x16x16).
 * True 3D cube with equal width (900px), height (900px), and depth (900px).
 * Uses GPU-accelerated THREE.InstancedMesh for enlarged 3D node spheres and
 * direct THREE.LineSegments BufferAttribute updates for silky-smooth 60+ FPS playback.
 */

// --- Global Parameters ---
let SKETCH_WIDTH = 800;       // Canvas viewport width (Default: 800)
let SKETCH_HEIGHT = 800;      // Canvas viewport height (Default: 800)
let SEED_VALUE = 42;          // Global random seed (Default: 42)
let MAX_FRAMES = 900;         // Frames for seamless rotation cycle (Default: 900)
let ANIMATION_SPEED = 30;     // Target animation frame rate (Default: 30)

// --- Transformation Timing ---
let CYCLE_DURATION = 300;     // Frames for one full loop cycle (Default: 300)
let HOLD_RATIO = 0.2;         // Ratio of cycle spent as a rigid cube (Default: 0.2)

// --- Grid & 3D Dimensions (True Cube: Width = Height = Depth = 900px) ---
let GRID_X = 16;              // Number of points along X-axis (Default: 16)
let GRID_Y = 16;              // Number of points along Y-axis (Default: 16)
let GRID_Z = 16;              // Number of points along Z-axis (Default: 16)
let CUBE_WIDTH = 900.0;       // Total physical width of cube (Default: 900.0)
let CUBE_HEIGHT = 900.0;      // Total physical height of cube (Default: 900.0)
let CUBE_DEPTH = 900.0;       // Total physical depth of cube (Default: 900.0)
let SPHERE_SIZE = 6.0;        // Radius of node spheres (Default: 6.0)
let SPHERE_DETAIL = 10;       // Sphere geometry segments (Default: 10)
let BEZIER_STRENGTH = 100.0;  // Amplitude of curved link displacements (Default: 100.0)
let BEZIER_SEGMENTS = 2;      // Subdivisions for 3D quadratic curve interpolation (Default: 2)
let ROTATION_X_FACTOR = 0.5;  // Multiplier for X-axis rotation relative to Y-axis (Default: 0.5)
let BEZIER_Z_SPEED = 0.5;     // Phase multiplier for bezier Z-axis drift (Default: 0.5)
let CAMERA_DISTANCE = 2300;   // Camera distance along Z-axis (Default: 2300)
let CAMERA_FOV = 45;          // Camera field of view in degrees (Default: 45)

// --- Motion & Wobble Dynamics ---
let WOBBLE_XY_AMP = 35.0;     // Amplitude of XY position oscillation (Default: 35.0)
let WOBBLE_Z_AMP = 45.0;      // Amplitude of Z position oscillation (Default: 45.0)
let WOBBLE_SPEED_XY = 2.0;    // Oscillation frequency multiplier on XY (Default: 2.0)

// --- Color Palette Setup (Adobe Kuler / Color Schemes) ---
const PALETTES = [
  // Palette 0: Industrial Red
  ["#1A1A1D", "#6F2232", "#950740", "#C3073F", "#4E4E50"],
  // Palette 1: Cyberpunk Neon
  ["#011627", "#FDFFFC", "#2EC4B6", "#E71D36", "#FFFF1C"],
  // Palette 2: Cool Slate
  ["#2D3142", "#4F5D75", "#BFC0C0", "#FFFFFF", "#EF8354"],
  // Palette 3: Lavender Dark
  ["#0B0D17", "#FCF6F5", "#807182", "#CBAACB", "#6B5B95"],
  // Palette 4: Grayscale Monochrome
  ["#000000", "#333333", "#666666", "#999999", "#CCCCCC"]
];

let PALETTE_INDEX = 1;        // Selected palette index [0-4] (Default: 1)
let INVERT_BG = false;        // Invert background flag (Default: false)
let BG_COLOR_INDEX = 0;       // Palette index for normal background (Default: 0)
let BG_INVERT_INDEX = 3;      // Palette index for inverted background (Default: 3)
let LINK_COLOR_INDEX = 2;     // Palette index for connecting line links (Default: 2)
let NODE_COLOR_INDEX = 3;     // Palette index for spheres (Default: 3)
let LINE_ALPHA = 0.6;         // Transparency alpha for connecting links [0.0 - 1.0] (Default: 0.6)

// --- Three.js Internals ---
let scene, camera, renderer, controls;
let instancedSpheres, lineSegmentsMesh;
let linePositions;
let anchors = [];
let links = [];
let dummy = new THREE.Object3D();
let bezierBasis = [];
let frameCount = 0;
let isPlaying = true;

// Preallocated trigonometric lookup arrays
let cosXTable = new Float32Array(GRID_X);
let sinYTable = new Float32Array(GRID_Y);
let sinZTable = new Float32Array(GRID_Z);
let halfCosXTable = new Float32Array(GRID_X);
let halfSinYTable = new Float32Array(GRID_Y);
let halfSinZTable = new Float32Array(GRID_Z);
let sinWobbleY = new Float32Array(GRID_Y);
let cosWobbleX = new Float32Array(GRID_X);
let sinWobbleZ = new Float32Array(GRID_X + GRID_Y);

function initBezierBasis() {
  bezierBasis = [];
  for (let s = 0; s <= BEZIER_SEGMENTS; s++) {
    let u = s / BEZIER_SEGMENTS;
    let invU = 1.0 - u;
    bezierBasis.push({
      c0: invU * invU,
      c1: 2.0 * invU * u,
      c2: u * u
    });
  }
}

function initScene() {
  const container = document.getElementById("canvas-container") || document.body;

  scene = new THREE.Scene();
  updateBackgroundColor();

  camera = new THREE.PerspectiveCamera(CAMERA_FOV, SKETCH_WIDTH / SKETCH_HEIGHT, 10, 15000);
  camera.position.set(0, 0, CAMERA_DISTANCE);

  renderer = new THREE.WebGLRenderer({ antialias: true, alpha: false });
  renderer.setSize(SKETCH_WIDTH, SKETCH_HEIGHT);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
  container.appendChild(renderer.domElement);

  if (typeof THREE.OrbitControls !== "undefined") {
    controls = new THREE.OrbitControls(camera, renderer.domElement);
    controls.enableDamping = true;
    controls.dampingFactor = 0.05;
  }

  initBezierBasis();
  buildLattice();
  buildMeshes();

  window.addEventListener("keydown", handleKeyDown);
  renderer.domElement.addEventListener("click", () => {
    PALETTE_INDEX = (PALETTE_INDEX + 1) % PALETTES.length;
    updateColors();
  });

  animate();
}

function updateBackgroundColor() {
  let bgHex = INVERT_BG
    ? PALETTES[PALETTE_INDEX][BG_INVERT_INDEX]
    : PALETTES[PALETTE_INDEX][BG_COLOR_INDEX];
  scene.background = new THREE.Color(bgHex);
}

function updateColors() {
  updateBackgroundColor();
  if (instancedSpheres) {
    instancedSpheres.material.color.set(PALETTES[PALETTE_INDEX][NODE_COLOR_INDEX]);
  }
  if (lineSegmentsMesh) {
    lineSegmentsMesh.material.color.set(PALETTES[PALETTE_INDEX][LINK_COLOR_INDEX]);
  }
}

function buildLattice() {
  // Equal spacing along X, Y, and Z for a perfect cube (60px spacing)
  let spacingX = CUBE_WIDTH / (GRID_X - 1);
  let spacingY = CUBE_HEIGHT / (GRID_Y - 1);
  let spacingZ = CUBE_DEPTH / (GRID_Z - 1);

  // 16x16x16 = 4,096 points spanning -450 to +450 on all three axes
  anchors = [];
  for (let z = 0; z < GRID_Z; z++) {
    for (let y = 0; y < GRID_Y; y++) {
      for (let x = 0; x < GRID_X; x++) {
        let posX = -(CUBE_WIDTH / 2) + x * spacingX;
        let posY = -(CUBE_HEIGHT / 2) + y * spacingY;
        let posZ = -(CUBE_DEPTH / 2) + z * spacingZ;
        anchors.push({
          origin: new THREE.Vector3(posX, posY, posZ),
          curr: new THREE.Vector3(posX, posY, posZ),
          ix: x,
          iy: y,
          iz: z
        });
      }
    }
  }

  // Pre-generate link pairs (11,520 links: 3,840 along X, 3,840 along Y, 3,840 along Z)
  links = [];
  for (let i = 0; i < anchors.length; i++) {
    let a = anchors[i];
    if (a.ix < GRID_X - 1) links.push({ a, b: anchors[i + 1] });
    if (a.iy < GRID_Y - 1) links.push({ a, b: anchors[i + GRID_X] });
    if (a.iz < GRID_Z - 1) links.push({ a, b: anchors[i + GRID_X * GRID_Y] });
  }
}

function buildMeshes() {
  // 1. Instanced Mesh for All 4,096 Enlarged Node Spheres (Single Draw Call)
  let sphereGeo = new THREE.SphereGeometry(SPHERE_SIZE, SPHERE_DETAIL, SPHERE_DETAIL);
  let sphereMat = new THREE.MeshBasicMaterial({
    color: new THREE.Color(PALETTES[PALETTE_INDEX][NODE_COLOR_INDEX])
  });
  instancedSpheres = new THREE.InstancedMesh(sphereGeo, sphereMat, anchors.length);
  instancedSpheres.instanceMatrix.setUsage(THREE.DynamicDrawUsage);
  scene.add(instancedSpheres);

  // 2. LineSegments for All 11,520 Links (Single Draw Call)
  let totalSegments = links.length * BEZIER_SEGMENTS;
  let totalVertices = totalSegments * 2;
  linePositions = new Float32Array(totalVertices * 3);

  let lineGeo = new THREE.BufferGeometry();
  lineGeo.setAttribute("position", new THREE.BufferAttribute(linePositions, 3));
  lineGeo.attributes.position.setUsage(THREE.DynamicDrawUsage);

  let lineMat = new THREE.LineBasicMaterial({
    color: new THREE.Color(PALETTES[PALETTE_INDEX][LINK_COLOR_INDEX]),
    transparent: true,
    opacity: LINE_ALPHA
  });

  lineSegmentsMesh = new THREE.LineSegments(lineGeo, lineMat);
  scene.add(lineSegmentsMesh);
}

function animate() {
  requestAnimationFrame(animate);

  if (!isPlaying) return;

  if (controls) controls.update();

  let progress = (frameCount % CYCLE_DURATION) / CYCLE_DURATION;
  let morphFactor;
  if (progress < HOLD_RATIO) {
    morphFactor = 0;
  } else {
    let internalTheta = ((progress - HOLD_RATIO) / (1.0 - HOLD_RATIO)) * Math.PI;
    morphFactor = Math.sin(internalTheta);
  }

  let t = ((frameCount % CYCLE_DURATION) / CYCLE_DURATION) * Math.PI * 2;
  let offset = morphFactor * BEZIER_STRENGTH;
  let halfOffset = offset * 0.5;

  for (let x = 0; x < GRID_X; x++) {
    let cosVal = Math.cos(t + x);
    cosXTable[x] = cosVal * offset;
    halfCosXTable[x] = cosVal * halfOffset;
    cosWobbleX[x] = Math.cos(t * WOBBLE_SPEED_XY + x) * (WOBBLE_XY_AMP * morphFactor);
  }
  for (let y = 0; y < GRID_Y; y++) {
    let sinVal = Math.sin(t + y);
    sinYTable[y] = sinVal * offset;
    halfSinYTable[y] = sinVal * halfOffset;
    sinWobbleY[y] = Math.sin(t * WOBBLE_SPEED_XY + y) * (WOBBLE_XY_AMP * morphFactor);
  }
  for (let z = 0; z < GRID_Z; z++) {
    let sinZVal = Math.sin(t * BEZIER_Z_SPEED + z);
    sinZTable[z] = sinZVal * offset;
    halfSinZTable[z] = sinZVal * halfOffset;
  }
  for (let k = 0; k < GRID_X + GRID_Y; k++) {
    sinWobbleZ[k] = Math.sin(t + k) * (WOBBLE_Z_AMP * morphFactor);
  }

  // Update All 4,096 Anchor Point Positions and Instanced Matrices
  for (let i = 0; i < anchors.length; i++) {
    let a = anchors[i];
    a.curr.x = a.origin.x + sinWobbleY[a.iy];
    a.curr.y = a.origin.y + cosWobbleX[a.ix];
    a.curr.z = a.origin.z + sinWobbleZ[a.ix + a.iy];

    dummy.position.copy(a.curr);
    dummy.updateMatrix();
    instancedSpheres.setMatrixAt(i, dummy.matrix);
  }
  instancedSpheres.instanceMatrix.needsUpdate = true;

  // Direct Float32Array Buffer Update for all 11,520 Links
  let ptr = 0;
  if (morphFactor < 0.001) {
    // Rigid Hold Phase: straight connections
    for (let i = 0; i < links.length; i++) {
      let a = links[i].a.curr;
      let b = links[i].b.curr;
      let midX = (a.x + b.x) * 0.5;
      let midY = (a.y + b.y) * 0.5;
      let midZ = (a.z + b.z) * 0.5;

      linePositions[ptr++] = a.x; linePositions[ptr++] = a.y; linePositions[ptr++] = a.z;
      linePositions[ptr++] = midX; linePositions[ptr++] = midY; linePositions[ptr++] = midZ;

      linePositions[ptr++] = midX; linePositions[ptr++] = midY; linePositions[ptr++] = midZ;
      linePositions[ptr++] = b.x; linePositions[ptr++] = b.y; linePositions[ptr++] = b.z;
    }
  } else if (BEZIER_SEGMENTS === 2) {
    // Morph Phase: smooth 2-segment quadratic Bézier midpoint interpolation
    for (let i = 0; i < links.length; i++) {
      let link = links[i];
      let a = link.a;
      let b = link.b;
      let ax = a.curr.x, ay = a.curr.y, az = a.curr.z;
      let bx = b.curr.x, by = b.curr.y, bz = b.curr.z;

      let qx = (ax + bx) * 0.5 + halfCosXTable[a.ix];
      let qy = (ay + by) * 0.5 + halfSinYTable[b.iy];
      let qz = (az + bz) * 0.5 + halfSinZTable[a.iz];

      linePositions[ptr++] = ax; linePositions[ptr++] = ay; linePositions[ptr++] = az;
      linePositions[ptr++] = qx; linePositions[ptr++] = qy; linePositions[ptr++] = qz;

      linePositions[ptr++] = qx; linePositions[ptr++] = qy; linePositions[ptr++] = qz;
      linePositions[ptr++] = bx; linePositions[ptr++] = by; linePositions[ptr++] = bz;
    }
  } else {
    // Multi-segment quadratic Bézier loop
    for (let i = 0; i < links.length; i++) {
      let link = links[i];
      let a = link.a;
      let b = link.b;
      let ax = a.curr.x, ay = a.curr.y, az = a.curr.z;
      let bx = b.curr.x, by = b.curr.y, bz = b.curr.z;

      let cx = (ax + bx) * 0.5 + cosXTable[a.ix];
      let cy = (ay + by) * 0.5 + sinYTable[b.iy];
      let cz = (az + bz) * 0.5 + sinZTable[a.iz];

      for (let s = 0; s < BEZIER_SEGMENTS; s++) {
        let b0 = bezierBasis[s];
        let b1 = bezierBasis[s + 1];

        linePositions[ptr++] = b0.c0 * ax + b0.c1 * cx + b0.c2 * bx;
        linePositions[ptr++] = b0.c0 * ay + b0.c1 * cy + b0.c2 * by;
        linePositions[ptr++] = b0.c0 * az + b0.c1 * cz + b0.c2 * bz;

        linePositions[ptr++] = b1.c0 * ax + b1.c1 * cx + b1.c2 * bx;
        linePositions[ptr++] = b1.c0 * ay + b1.c1 * cy + b1.c2 * by;
        linePositions[ptr++] = b1.c0 * az + b1.c1 * cz + b1.c2 * bz;
      }
    }
  }
  lineSegmentsMesh.geometry.attributes.position.needsUpdate = true;

  // Scene Rotation (Centered at Origin)
  let globalRotation = ((frameCount % MAX_FRAMES) / MAX_FRAMES) * Math.PI * 2;
  instancedSpheres.rotation.y = globalRotation;
  instancedSpheres.rotation.x = globalRotation * ROTATION_X_FACTOR;

  lineSegmentsMesh.rotation.y = globalRotation;
  lineSegmentsMesh.rotation.x = globalRotation * ROTATION_X_FACTOR;

  renderer.render(scene, camera);
  frameCount++;
}

function handleKeyDown(e) {
  if (e.key === "b" || e.key === "B") {
    INVERT_BG = !INVERT_BG;
    updateBackgroundColor();
  } else if (e.key === " ") {
    isPlaying = !isPlaying;
  }
}

// Auto-start on DOMContentLoaded
window.addEventListener("DOMContentLoaded", initScene);
