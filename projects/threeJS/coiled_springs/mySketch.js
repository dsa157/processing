/**
 * Coiled Springs: Generative Grid of Pulses and Dynamic Staggered Animations
 * Author: dsa157@gmail.com
 * Version: 2026.10.02.17.55.00
 * Description: Self-contained generative Three.js sketch displaying a grid of coiled springs 
 *              viewed from above. Springs are rendered in a single efficient draw call using 
 *              custom ShaderMaterial, animated by a staggered wave system with real-time mouse 
 *              interaction (tightening, loosening, and twisting) in a centered canvas container.
 */

import * as THREE from 'three';
import { OrbitControls } from 'three/addons/controls/OrbitControls.js';
import { EffectComposer } from 'three/addons/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/addons/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/addons/postprocessing/UnrealBloomPass.js';

// ==========================================
// ⚙️ GLOBAL PARAMETERS
// ==========================================
const PARAMS = {
    // System Configs
    VERSION: "2026.10.02.17.55.00",        // 2026.10.02.17.55.00 - Incrementing version timestamp (Rule 6)
    SEED: 424242,                         // 424242 - Global PRNG seed for reproducibility (Rule 4)
    PALETTE_INDEX: 0,                     // 0 - Selected color palette index (0-4) (Rule 13)
    BACKGROUND_COLOR_INDEX: 0,            // 0 - Index from selected palette for background (Rule 11)

    // Canvas Constraints
    CANVAS_WIDTH: 800,                    // 480 - Output locked canvas width (pixels)
    CANVAS_HEIGHT: 800,                   // 800 - Output locked canvas height (pixels)

    // Grid settings
    GRID_ROWS: 8,                         // 8 - Number of rows in the 2D grid
    GRID_COLS: 8,                         // 4 - Number of columns in the 2D grid
    GRID_SPACING: 1.0,                    // 1.6 - Spatial spacing between spring centers

    // Spring Geometry Settings
    POINTS_PER_SPRING: 120,               // 120 - Detail points per spring line
    BASE_TURNS: 5.5,                      // 5.5 - Base spiral turns count (winds)
    TURNS_DELTA: 1.8,                     // 1.8 - Amplitude of turns tightening/loosening
    INNER_RADIUS: 0.1,                    // 0.1 - Inner radius of the spiral spring
    OUTER_RADIUS: 0.65,                   // 0.65 - Base outer radius of the spring
    RADIUS_DELTA: 0.15,                   // 0.15 - Outer radius shrinkage delta when tightening
    RADIUS_POWER: 1.0,                    // 1.0 - Power distribution of radius (1.0 = Archimedean)
    SPRING_HEIGHT: 0.6,                   // 0.6 - Helical 3D height depth of the spring (Z-axis)

    // Animation & Wave Settings
    PULSE_SPEED: 2.2,                     // 2.2 - Master speed of the pulse animation
    WAVE_FREQUENCY: 0.45,                 // 0.45 - Frequency of wave ripple stagger
    WAVE_TYPE: 0,                         // 0 - Active wave pattern (0: Radial, 1: Diagonal, 2: Spiral, 3: Random, 4: Noise)

    // Mouse Interaction Settings
    MOUSE_RADIUS: 4.5,                    // 4.5 - World space radius of mouse hover influence
    MOUSE_FORCE: 1.2,                     // 1.2 - Amplification factor of mouse tightening/loosening
    MOUSE_MODE: 0,                        // 0 - Mouse hover mode (0: Tighten, 1: Loosen, 2: Twist)
    MOUSE_TIGHTEN_LIMIT: 1.2,             // 1.2 - Maximum tightening multiplier under mouse influence
    MOUSE_LOOSEN_LIMIT: -1.2,             // -1.2 - Maximum loosening multiplier under mouse influence
    MOUSE_TWIST_FACTOR: 2.2,              // 2.2 - Angular twist factor under mouse influence
    MOUSE_BREATH_FACTOR: 0.12,            // 0.12 - Radial breathing expansion factor under mouse hover
    MOUSE_TILT_FACTOR: 0.28,              // 0.28 - 3D volumetric tilt intensity towards cursor

    // Spring Visual & Shader Shimmer Settings
    COLOR_INTENSITY: 0.8,                 // 0.8 - Color saturation gradient intensity at spring tips
    SPRING_BASE_COLOR: '#ffffff',         // '#ffffff' - Base center core color for spring lines
    SPRING_ACCENT_COLOR_INDEX: 4,         // 4 - Palette color index for spring outer tips accent
    SHIMMER_SPEED: 4.5,                   // 4.5 - Moving speed of light-pulse shimmer along spring wire
    SHIMMER_FREQ: 15.0,                   // 15.0 - Frequency cycles of wire shimmer along spring length
    SHIMMER_INTENSITY: 0.18,              // 0.18 - Brightness boost added by shimmer highlights
    ALPHA_MAX: 0.95,                      // 0.95 - Maximum line alpha opacity
    ALPHA_INNER_FADE: 0.12,               // 0.12 - Smoothstep inner start fade threshold
    ALPHA_OUTER_FADE: 0.85,               // 0.85 - Smoothstep outer end fade threshold

    // Alignment Backing Grid Settings
    GRID_VISIBLE: false,                  // false - Toggle visibility of backing alignment grid
    GRID_COLOR1_INDEX: 1,                 // 1 - Palette index for primary grid lines
    GRID_COLOR1_SCALAR: 0.4,              // 0.4 - Dimming brightness scalar for primary grid lines
    GRID_COLOR2_INDEX: 2,                 // 2 - Palette index for secondary grid lines
    GRID_COLOR2_SCALAR: 0.12,             // 0.12 - Dimming brightness scalar for secondary grid lines
    GRID_Z_OFFSET: 0.05,                  // 0.05 - Z-axis backward offset for grid plane behind springs

    // Bloom (Post-Processing) Settings
    BLOOM_STRENGTH: 1.4,                  // 1.4 - Bloom glow intensity
    BLOOM_RADIUS: 0.5,                    // 0.5 - Bloom scattering blur radius
    BLOOM_THRESHOLD: 0.1,                 // 0.1 - Bloom high-pass luminance threshold

    // Camera Settings
    CAMERA_FOV: 40,                       // 40 - Camera vertical field of view in degrees
    CAMERA_NEAR: 0.1,                     // 0.1 - Camera near clipping plane distance
    CAMERA_FAR: 100.0,                    // 100.0 - Camera far clipping plane distance
    CAMERA_TILT: true,                    // true - Allow initial camera tilt for 3D depth perspective
    CAMERA_TILT_Y: -6.5,                  // -6.5 - Initial camera Y offset for tilted view
    CAMERA_TILT_Z_OFFSET: -2.0,           // -2.0 - Camera Z delta offset when tilted
    CAMERA_Z: 18.0,                       // 18.0 - Default camera Z height

    // Orbit Controls Settings
    CONTROLS_DAMPING: true,               // true - Enable damping (inertia) on orbit controls
    CONTROLS_DAMPING_FACTOR: 0.05,        // 0.05 - Damping inertia factor for controls
    CONTROLS_MAX_DISTANCE: 35.0,          // 35.0 - Maximum camera zoom-out distance
    CONTROLS_MIN_DISTANCE: 5.0,           // 5.0 - Minimum camera zoom-in distance
    CONTROLS_POLAR_ANGLE_OFFSET: 0.05,    // 0.05 - Angle offset from PI/2 to constrain below-ground view

    // Scene Lighting Settings
    AMBIENT_LIGHT_COLOR: 0xffffff,        // 0xffffff - Ambient light color
    AMBIENT_LIGHT_INTENSITY: 0.2,         // 0.2 - Ambient light intensity
    POINT_LIGHT_PALETTE_INDEX: 4,         // 4 - Palette color index for point light
    POINT_LIGHT_INTENSITY: 1.5,           // 1.5 - Point light intensity
    POINT_LIGHT_DISTANCE: 30.0,           // 30.0 - Point light decay distance
    POINT_LIGHT_Z: 8.0,                   // 8.0 - Point light Z position

    // Renderer & Performance Settings
    MAX_PIXEL_RATIO: 2,                   // 2 - Maximum device pixel ratio clamp for performance
    TONE_MAPPING_EXPOSURE: 1.0,           // 1.0 - ACES Filmic tone mapping exposure
    FPS_UPDATE_INTERVAL_MS: 1000          // 1000 - FPS update frequency in milliseconds
};

// ==========================================
// 🎨 COLOR PALETTES (Adobe Kuler Curated - Rules 10, 11, 12, 13, 14)
// ==========================================
const COLOR_PALETTES = [
    // 0: "Midnight Neon" - Vibrant cyan and purple highlights against a deep dark violet backdrop
    ['#080612', '#7b2cbf', '#9d4edd', '#3a0ca3', '#4cc9f0'],
    // 1: "Desert Solstice" - Hot copper, warm amber gold, obsidian depths, and bright sand accents
    ['#140d07', '#ffb703', '#fb8500', '#219ebc', '#8ecae6'],
    // 2: "Mint Ice" - Premium clean turquoise, icy mint green, frost white, and deep ocean base
    ['#051515', '#2ec4b6', '#cbf3f0', '#ff9f1c', '#ffffff'],
    // 3: "Cyber Punk" - Hyper electric magenta, dark indigo void, and neon glowing blues
    ['#08020f', '#f72585', '#7209b7', '#3f37c9', '#4cc9f0'],
    // 4: "Earthy Sage" - Natural deep forest slate, soothing pale sage, charcoal, and warm silver
    ['#0e1210', '#3a5a40', '#588157', '#a3b18a', '#dad7cd']
];

const PALETTE_NAMES = [
    "Midnight Neon",
    "Desert Solstice",
    "Mint Ice",
    "Cyber Punk",
    "Earthy Sage"
];

// ==========================================
// 🎲 SEEDABLE RANDOM GENERATOR (Rule 4)
// ==========================================
let prngState = PARAMS.SEED;
function seedRandom() {
    let t = prngState += 0x6D2B79F5;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
}

function mulberry32(seedValue) {
    return function () {
        let t = seedValue += 0x6D2B79F5;
        t = Math.imul(t ^ (t >>> 15), t | 1);
        t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
    };
}

// ==========================================
// 🚀 SCENE CONTEXT GLOBALS
// ==========================================
let scene, camera, renderer, composer;
let controls, clock;
let springGeometry, springMaterial, springMesh;
let gridHelper;
let frameCount = 0;
let lastTime = 0;

// Mouse and Raycasting
const raycaster = new THREE.Raycaster();
const mouse = new THREE.Vector2(-9999, -9999);
const gridPlane = new THREE.Plane(new THREE.Vector3(0, 0, 1), 0); // X-Y plane
const intersection = new THREE.Vector3(-9999, -9999, 0);

// ==========================================
// 🌀 CUSTOM GLSL SHADERS FOR SPRINGS
// ==========================================
const springVertexShader = `
    uniform float uTime;
    uniform float uBaseTurns;
    uniform float uTurnsDelta;
    uniform float uInnerRadius;
    uniform float uOuterRadius;
    uniform float uRadiusDelta;
    uniform float uRadiusPower;
    uniform float uSpringHeight;
    uniform float uPulseSpeed;
    uniform float uWaveFreq;
    uniform int uWaveType;
    uniform vec2 uMousePos;
    uniform float uMouseRadius;
    uniform float uMouseForce;
    uniform int uMouseMode;
    uniform float uMouseTightenLimit;
    uniform float uMouseLoosenLimit;
    uniform float uMouseTwistFactor;
    uniform float uMouseBreathFactor;
    uniform float uMouseTiltFactor;

    attribute vec3 aCenter;
    attribute float aT;
    attribute float aSpringIndex;
    attribute float aPhaseOffset;

    varying float vT;
    varying float vSpringIndex;
    varying float vPulseState;
    varying float vMouseInfluence;

    // Simple hash for shader noise
    float hash(float n) { return fract(sin(n) * 43758.5453123); }

    void main() {
        // 1. Wave stagger patterns
        float phaseOffset = 0.0;
        
        if (uWaveType == 0) {
            // Radial ripple from canvas center
            float distToCenter = length(aCenter.xy);
            phaseOffset = distToCenter * uWaveFreq;
        } else if (uWaveType == 1) {
            // Diagonal linear wave
            phaseOffset = (aCenter.x + aCenter.y) * uWaveFreq;
        } else if (uWaveType == 2) {
            // Spiral vortex wave
            float angle = atan(aCenter.y, aCenter.x);
            float distToCenter = length(aCenter.xy);
            phaseOffset = (angle + distToCenter * 0.5) * uWaveFreq;
        } else if (uWaveType == 3) {
            // Seeded random staggered phases
            phaseOffset = aPhaseOffset;
        } else if (uWaveType == 4) {
            // Double sine noise grid pattern
            phaseOffset = (sin(aCenter.x * uWaveFreq * 1.5) + cos(aCenter.y * uWaveFreq * 1.5)) * 1.8;
        }

        // 2. Main harmonic tightening/loosening pulse state
        float pulse = sin(uTime * uPulseSpeed - phaseOffset);
        vPulseState = pulse;

        // 3. Mouse raycast intersection influence calculation
        float distToMouse = distance(aCenter.xy, uMousePos);
        float mouseInfluence = smoothstep(uMouseRadius, 0.0, distToMouse);
        vMouseInfluence = mouseInfluence;

        // Combine pulse with mouse action depending on active mode
        float s = pulse;
        if (uMouseMode == 0) {
            // Mouse tightens springs locally
            s = mix(pulse, uMouseTightenLimit, mouseInfluence * uMouseForce);
        } else if (uMouseMode == 1) {
            // Mouse loosens springs locally
            s = mix(pulse, uMouseLoosenLimit, mouseInfluence * uMouseForce);
        }

        // 4. Calculate dynamic spiral geometric parameters
        float currentTurns = uBaseTurns + uTurnsDelta * s;
        
        if (uMouseMode == 2) {
            // Mouse twists the spring
            currentTurns += mouseInfluence * uMouseForce * uMouseTwistFactor;
        }

        float currentOuterRadius = uOuterRadius - uRadiusDelta * s;
        
        // Breath effect: hover pushes size slightly outward
        currentOuterRadius *= (1.0 + mouseInfluence * uMouseForce * uMouseBreathFactor);

        // Math spiral: calculate Archimedean helix coordinates
        float theta = aT * currentTurns * 2.0 * 3.14159265;
        float r = uInnerRadius + (currentOuterRadius - uInnerRadius) * pow(aT, uRadiusPower);

        // Build 3D coordinates relative to spring center (X-Y plane with helical Z height depth)
        float dx = r * cos(theta);
        float dy = r * sin(theta);
        float dz = uSpringHeight * (aT - 0.5);

        vec3 localPos = vec3(dx, dy, dz);

        // Interactive 3D tilt towards mouse for volumetric depth
        if (mouseInfluence > 0.0 && uSpringHeight > 0.0) {
            vec2 dir = normalize(aCenter.xy - uMousePos);
            float tiltAngle = mouseInfluence * uMouseForce * uMouseTiltFactor;
            localPos.z += (localPos.x * dir.x + localPos.y * dir.y) * tiltAngle;
        }

        // Apply to grid cell center (Rule 9 - Perfectly centered coordinates)
        vec3 worldPos = aCenter + localPos;

        vT = aT;
        vSpringIndex = aSpringIndex;

        vec4 mvPosition = modelViewMatrix * vec4(worldPos, 1.0);
        gl_Position = projectionMatrix * mvPosition;
    }
`;

const springFragmentShader = `
    uniform vec3 uBaseColor;
    uniform vec3 uAccentColor;
    uniform float uColorIntensity;
    uniform float uTime;
    uniform float uShimmerSpeed;
    uniform float uShimmerFreq;
    uniform float uShimmerIntensity;
    uniform float uAlphaMax;
    uniform float uAlphaInnerFade;
    uniform float uAlphaOuterFade;
    
    varying float vT;
    varying float vSpringIndex;
    varying float vPulseState;
    varying float vMouseInfluence;

    void main() {
        // Base color core
        vec3 springColor = uBaseColor;
        
        // Smooth aesthetic gradient blending towards the outer edge of spring
        float colorGrad = pow(vT, 2.0) * uColorIntensity;
        colorGrad = clamp(colorGrad + vMouseInfluence * 0.25, 0.0, 1.0);

        // Linear interpolation with selected active palette color
        vec3 finalColor = mix(springColor, uAccentColor, colorGrad);

        // Add moving light-pulse shimmer along the spring wire
        float shimmer = sin(vT * uShimmerFreq - uTime * uShimmerSpeed) * 0.5 + 0.5;
        finalColor += uAccentColor * shimmer * uShimmerIntensity;

        // Soft transparency near the core start and soft outer fade for anti-aliasing
        float alpha = smoothstep(0.0, uAlphaInnerFade, vT);
        alpha *= smoothstep(1.0, uAlphaOuterFade, vT);

        gl_FragColor = vec4(finalColor, alpha * uAlphaMax);
    }
`;

// ==========================================
// 🚀 INITIALIZATION & SETUP
// ==========================================
function init() {
    const container = document.getElementById('canvas-container');
    container.innerHTML = ''; // Clear container

    // Set fixed dimensions on the container dynamically (Rule 9)
    const width = PARAMS.CANVAS_WIDTH;
    const height = PARAMS.CANVAS_HEIGHT;
    container.style.width = width + 'px';
    container.style.height = height + 'px';

    // Set HUD and labels
    const hudVersion = document.getElementById('hud-version');
    if (hudVersion) hudVersion.innerText = PARAMS.VERSION;

    const hudSeed = document.getElementById('hud-seed');
    if (hudSeed) hudSeed.innerText = PARAMS.SEED;

    const hudPalette = document.getElementById('hud-palette');
    if (hudPalette) hudPalette.innerText = PALETTE_NAMES[PARAMS.PALETTE_INDEX];

    const hudGrid = document.getElementById('hud-grid');
    if (hudGrid) hudGrid.innerText = `${PARAMS.GRID_ROWS} x ${PARAMS.GRID_COLS}`;

    const hudSprings = document.getElementById('hud-springs');
    if (hudSprings) hudSprings.innerText = PARAMS.GRID_ROWS * PARAMS.GRID_COLS;

    // 1. Create Scene
    scene = new THREE.Scene();

    const palette = COLOR_PALETTES[PARAMS.PALETTE_INDEX];
    const bgColorHex = palette[PARAMS.BACKGROUND_COLOR_INDEX];
    scene.background = new THREE.Color(bgColorHex);
    document.body.style.backgroundColor = bgColorHex;

    // 2. Camera Setup (Rule 9 - View from above, centered on locked aspect ratio)
    camera = new THREE.PerspectiveCamera(PARAMS.CAMERA_FOV, width / height, PARAMS.CAMERA_NEAR, PARAMS.CAMERA_FAR);

    // Set starting camera looking straight down with optional tilt for 3D depth
    if (PARAMS.CAMERA_TILT) {
        camera.position.set(0, PARAMS.CAMERA_TILT_Y, PARAMS.CAMERA_Z + PARAMS.CAMERA_TILT_Z_OFFSET);
    } else {
        camera.position.set(0, 0, PARAMS.CAMERA_Z);
    }

    // 3. WebGL Renderer
    renderer = new THREE.WebGLRenderer({ antialias: true });
    renderer.setSize(width, height);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, PARAMS.MAX_PIXEL_RATIO));
    renderer.toneMapping = THREE.ACESFilmicToneMapping;
    renderer.toneMappingExposure = PARAMS.TONE_MAPPING_EXPOSURE;
    container.appendChild(renderer.domElement);

    // 4. Orbit Controls (Interactive camera panning)
    controls = new OrbitControls(camera, renderer.domElement);
    controls.enableDamping = PARAMS.CONTROLS_DAMPING;
    controls.dampingFactor = PARAMS.CONTROLS_DAMPING_FACTOR;
    controls.maxDistance = PARAMS.CONTROLS_MAX_DISTANCE;
    controls.minDistance = PARAMS.CONTROLS_MIN_DISTANCE;
    // Lock rotation slightly to maintain the "viewed from above" feel
    controls.maxPolarAngle = Math.PI / 2 - PARAMS.CONTROLS_POLAR_ANGLE_OFFSET;

    // 5. Lights
    const ambientLight = new THREE.AmbientLight(PARAMS.AMBIENT_LIGHT_COLOR, PARAMS.AMBIENT_LIGHT_INTENSITY);
    scene.add(ambientLight);

    const pointLight = new THREE.PointLight(
        palette[PARAMS.POINT_LIGHT_PALETTE_INDEX],
        PARAMS.POINT_LIGHT_INTENSITY,
        PARAMS.POINT_LIGHT_DISTANCE
    );
    pointLight.position.set(0, 0, PARAMS.POINT_LIGHT_Z);
    scene.add(pointLight);

    // 6. Build Grid Springs Geometry
    buildSpringsGeometry();

    // 7. Add Backing Grid Helper
    buildBackingGrid();

    // 8. Unreal Bloom Compositing for Glowing Visuals
    const renderScene = new RenderPass(scene, camera);
    const bloomPass = new UnrealBloomPass(
        new THREE.Vector2(width, height),
        PARAMS.BLOOM_STRENGTH,
        PARAMS.BLOOM_RADIUS,
        PARAMS.BLOOM_THRESHOLD
    );

    composer = new EffectComposer(renderer);
    composer.addPass(renderScene);
    composer.addPass(bloomPass);

    clock = new THREE.Clock();

    // Register Input Listeners
    window.addEventListener('resize', onWindowResize);
    window.addEventListener('mousemove', onPointerMove);
    window.addEventListener('touchmove', onPointerMove, { passive: true });
    window.addEventListener('mouseleave', onPointerLeave);
}

// ==========================================
// 🌀 GENERATE SPRING GEOMETRY IN A SINGLE DRAW CALL
// ==========================================
function buildSpringsGeometry() {
    if (springMesh) {
        scene.remove(springMesh);
        springGeometry.dispose();
        springMaterial.dispose();
    }

    const gridRows = PARAMS.GRID_ROWS;
    const gridCols = PARAMS.GRID_COLS;
    const pointsPerSpring = PARAMS.POINTS_PER_SPRING;
    const spacing = PARAMS.GRID_SPACING;

    const totalSprings = gridRows * gridCols;
    const verticesPerSpring = 2 * (pointsPerSpring - 1);
    const totalVertices = totalSprings * verticesPerSpring;

    // Arrays for WebGL Buffer Attributes
    const positions = new Float32Array(totalVertices * 3);
    const centers = new Float32Array(totalVertices * 3);
    const tParams = new Float32Array(totalVertices);
    const springIndices = new Float32Array(totalVertices);
    const phaseOffsets = new Float32Array(totalVertices);

    // Initialize seed-based PRNG for staggered random phases (Rule 4)
    const prng = mulberry32(PARAMS.SEED);

    let vertexIdx = 0;
    for (let r = 0; r < gridRows; r++) {
        for (let c = 0; c < gridCols; c++) {
            const springIdx = r * gridCols + c;

            // Center coordinates of this grid cell (Rule 9 - centered on canvas)
            const cx = (c - (gridCols - 1) / 2) * spacing;
            const cy = (r - (gridRows - 1) / 2) * spacing;
            const cz = 0.0;

            // Generate a seeded phase offset unique to this spring
            const randomPhase = prng() * Math.PI * 2;

            for (let i = 0; i < pointsPerSpring - 1; i++) {
                const t1 = i / (pointsPerSpring - 1);
                const t2 = (i + 1) / (pointsPerSpring - 1);

                // Line Segment Vertex 1
                centers[vertexIdx * 3] = cx;
                centers[vertexIdx * 3 + 1] = cy;
                centers[vertexIdx * 3 + 2] = cz;
                tParams[vertexIdx] = t1;
                springIndices[vertexIdx] = springIdx;
                phaseOffsets[vertexIdx] = randomPhase;
                vertexIdx++;

                // Line Segment Vertex 2
                centers[vertexIdx * 3] = cx;
                centers[vertexIdx * 3 + 1] = cy;
                centers[vertexIdx * 3 + 2] = cz;
                tParams[vertexIdx] = t2;
                springIndices[vertexIdx] = springIdx;
                phaseOffsets[vertexIdx] = randomPhase;
                vertexIdx++;
            }
        }
    }

    // Create Buffer Geometry
    springGeometry = new THREE.BufferGeometry();
    springGeometry.setAttribute('position', new THREE.BufferAttribute(positions, 3));
    springGeometry.setAttribute('aCenter', new THREE.BufferAttribute(centers, 3));
    springGeometry.setAttribute('aT', new THREE.BufferAttribute(tParams, 1));
    springGeometry.setAttribute('aSpringIndex', new THREE.BufferAttribute(springIndices, 1));
    springGeometry.setAttribute('aPhaseOffset', new THREE.BufferAttribute(phaseOffsets, 1));

    // Create custom shader material
    const palette = COLOR_PALETTES[PARAMS.PALETTE_INDEX];
    springMaterial = new THREE.ShaderMaterial({
        vertexShader: springVertexShader,
        fragmentShader: springFragmentShader,
        uniforms: {
            uTime: { value: 0.0 },
            uBaseTurns: { value: PARAMS.BASE_TURNS },
            uTurnsDelta: { value: PARAMS.TURNS_DELTA },
            uInnerRadius: { value: PARAMS.INNER_RADIUS },
            uOuterRadius: { value: PARAMS.OUTER_RADIUS },
            uRadiusDelta: { value: PARAMS.RADIUS_DELTA },
            uRadiusPower: { value: PARAMS.RADIUS_POWER },
            uSpringHeight: { value: PARAMS.SPRING_HEIGHT },
            uPulseSpeed: { value: PARAMS.PULSE_SPEED },
            uWaveFreq: { value: PARAMS.WAVE_FREQUENCY },
            uWaveType: { value: PARAMS.WAVE_TYPE },
            uMousePos: { value: new THREE.Vector2(-9999.0, -9999.0) },
            uMouseRadius: { value: PARAMS.MOUSE_RADIUS },
            uMouseForce: { value: PARAMS.MOUSE_FORCE },
            uMouseMode: { value: PARAMS.MOUSE_MODE },
            uMouseTightenLimit: { value: PARAMS.MOUSE_TIGHTEN_LIMIT },
            uMouseLoosenLimit: { value: PARAMS.MOUSE_LOOSEN_LIMIT },
            uMouseTwistFactor: { value: PARAMS.MOUSE_TWIST_FACTOR },
            uMouseBreathFactor: { value: PARAMS.MOUSE_BREATH_FACTOR },
            uMouseTiltFactor: { value: PARAMS.MOUSE_TILT_FACTOR },
            uBaseColor: { value: new THREE.Color(PARAMS.SPRING_BASE_COLOR) },
            uAccentColor: { value: new THREE.Color(palette[PARAMS.SPRING_ACCENT_COLOR_INDEX]) },
            uColorIntensity: { value: PARAMS.COLOR_INTENSITY },
            uShimmerSpeed: { value: PARAMS.SHIMMER_SPEED },
            uShimmerFreq: { value: PARAMS.SHIMMER_FREQ },
            uShimmerIntensity: { value: PARAMS.SHIMMER_INTENSITY },
            uAlphaMax: { value: PARAMS.ALPHA_MAX },
            uAlphaInnerFade: { value: PARAMS.ALPHA_INNER_FADE },
            uAlphaOuterFade: { value: PARAMS.ALPHA_OUTER_FADE }
        },
        transparent: true,
        depthWrite: false,
        blending: THREE.AdditiveBlending
    });

    // Single unified Lines system drawing all springs in a single draw call
    springMesh = new THREE.LineSegments(springGeometry, springMaterial);
    scene.add(springMesh);
}

// ==========================================
// 🕸️ ALIGNMENT BACKING GRID DESIGN
// ==========================================
function buildBackingGrid() {
    if (gridHelper) {
        scene.remove(gridHelper);
    }

    if (!PARAMS.GRID_VISIBLE) return;

    const gridCols = PARAMS.GRID_COLS;
    const spacing = PARAMS.GRID_SPACING;
    const size = gridCols * spacing;

    const palette = COLOR_PALETTES[PARAMS.PALETTE_INDEX];

    // Generate grid on X-Y plane (subtle lines)
    gridHelper = new THREE.GridHelper(
        size,
        gridCols,
        new THREE.Color(palette[PARAMS.GRID_COLOR1_INDEX]).multiplyScalar(PARAMS.GRID_COLOR1_SCALAR),
        new THREE.Color(palette[PARAMS.GRID_COLOR2_INDEX]).multiplyScalar(PARAMS.GRID_COLOR2_SCALAR)
    );

    // Align perfectly with the X-Y springs plane
    gridHelper.rotation.x = Math.PI / 2;
    gridHelper.position.z = -PARAMS.SPRING_HEIGHT * 0.5 - PARAMS.GRID_Z_OFFSET;

    scene.add(gridHelper);
}

// ==========================================
// 🖱️ MOUSE INTERACTION & RAYCASTING
// ==========================================
function onPointerMove(e) {
    let clientX, clientY;
    if (e.touches && e.touches.length > 0) {
        clientX = e.touches[0].clientX;
        clientY = e.touches[0].clientY;
    } else {
        clientX = e.clientX;
        clientY = e.clientY;
    }

    // Normalise coordinate space mapping exact canvas bounding client coordinates
    const rect = renderer.domElement.getBoundingClientRect();
    mouse.x = ((clientX - rect.left) / rect.width) * 2 - 1;
    mouse.y = -((clientY - rect.top) / rect.height) * 2 + 1;

    // Raycast intersection with the X-Y plane
    raycaster.setFromCamera(mouse, camera);
    raycaster.ray.intersectPlane(gridPlane, intersection);

    if (springMaterial) {
        springMaterial.uniforms.uMousePos.value.set(intersection.x, intersection.y);
    }
}

function onPointerLeave() {
    // Send mouse coordinates out of bounds when mouse exits viewport
    if (springMaterial) {
        springMaterial.uniforms.uMousePos.value.set(-9999.0, -9999.0);
    }
}

// ==========================================
// 🔄 ANIMATION LOOP
// ==========================================
function animate() {
    requestAnimationFrame(animate);

    const dt = clock.getDelta();
    const elapsedTime = clock.getElapsedTime();
    frameCount++;

    // 1. Calculate FPS rates
    const time = performance.now();
    if (time > lastTime + PARAMS.FPS_UPDATE_INTERVAL_MS) {
        const fps = (frameCount * 1000) / (time - lastTime);
        const hudFps = document.getElementById('hud-fps');
        if (hudFps) hudFps.innerText = Math.round(fps);
        frameCount = 0;
        lastTime = time;
    }

    // 2. Interactive Camera updates
    controls.update();

    // 3. Update Custom Shader Time
    if (springMaterial) {
        springMaterial.uniforms.uTime.value = elapsedTime;
    }

    // 4. Render Scene with Postprocessing Bloom glow
    composer.render();
}

// ==========================================
// 📐 RESIZING HANDLER
// ==========================================
function onWindowResize() {
    // Centering is handled by CSS flex layout within locked canvas dimensions
}

// Start Sketch
init();
animate();
