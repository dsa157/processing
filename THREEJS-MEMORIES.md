# Three.js Generative Art Workspace Memories

## 🚀 Overview & Tech Stack
This workspace documents generalized architectural patterns, design standards, and technical insights gained while building high-performance 3D generative art projects using **Three.js** as a replacement for standard **Processing (processing.org / p5.js)**.

### Core Tech Stack
*   **Engine**: Three.js modular WebGL library.
*   **Post-Processing**: `EffectComposer`, `RenderPass`, and standard shader passes (e.g. `UnrealBloomPass`) for glow and volumetric lighting.
*   **Interactivity**: `OrbitControls` for fluid 3D scene camera exploration (pan, zoom, orbit).
*   **Recording**: HTML5 `MediaRecorder` capturing WebGL frames directly from the canvas buffers.

---

## 🏗️ Retained-Mode 3D Scene Graph vs. Processing Immediate-Mode

| Feature | Processing (p5.js) | Three.js (WebGL) |
| :--- | :--- | :--- |
| **Drawing Paradigm** | **Immediate-Mode**: The canvas is cleared and entirely redrawn shape-by-shape in every frame loop (`draw()`). | **Retained-Mode**: persistent object structures (`THREE.Scene`, `THREE.Group`) are instantiated once and manipulated dynamically. |
| **Computational Load** | **CPU-Bound**: Iterating and drawing thousands of independent shapes in JS loops causes major CPU bottlenecking. | **GPU-Bound**: Geometries and textures are uploaded to GPU VRAM once; positioning and coloring are handled in parallel on the graphics card. |
| **Camera & Depth** | Flat 2D drawing matrix by default. 3D requires manual perspective math and matrix translations. | Native 3D perspective camera (`THREE.PerspectiveCamera`) with robust 3D matrix math and depth-sorting. |
| **Lighting Systems** | Basic simulated light functions. Shadows and complex shading are highly expensive to code. | Realistic physics-based light sources (`THREE.AmbientLight`, `THREE.PointLight`, `THREE.DirectionalLight`) with organic reflection paths. |

---

## 🎨 Generalized WebGL Architecture & Custom GPU Shaders

### 1. Dynamic Particle Clouds & GPU Processing
*   **Traditional Draw Loops**: In Processing, drawing massive numbers of shapes requires nested CPU loops, resulting in immediate frame rate drops.
*   **Retained Particle Clusters**: In Three.js, thousands of particles are rendered as a single unified `THREE.Points` object. Dynamic behaviors (swirling, morphing, gaseous color patches) are computed on the GPU via custom **Vertex Shaders** and **Fragment Shaders** within a `THREE.ShaderMaterial`.
*   **Performance Impact**: Eliminating CPU draw loop overhead allows rendering upwards of **30,000+ particles at 120 FPS**.

### 2. Elastic Displacement Fields & Vector Math
*   **Base Coordinate Preservation**: To animate dynamic field distortions (such as wakes, ripples, or gravitational pushes), keep a static `basePositions` Float32Array and a dynamic `displacements` Float32Array.
*   **Damped Spring Mechanics**: In the animation loop, calculate distance-based vector displacements on local coordinates, then multiply the offsets by a spring damping factor (e.g., `0.93`). This allows particles to push outward organically and elastically snap back to their original configurations when forces exit the system.

### 3. Localized Surface Shader Effects & Matrix Transforms
*   **Inverse Coordinate Transformation**: When external, world-space event coordinates interact with a spinning 3D object, convert the world coordinates into the object's local-space coordinates using the inverse of the object's matrix (e.g., `worldPos.applyMatrix4(object.matrixWorld.clone().invert())`).
*   **Shader Uniform Mapping**: Pass these local coordinates to custom shaders as uniform arrays (e.g., `uniform vec3 uImpactPos[N]`).
*   **Locked Rotating Effects**: The vertex and fragment shaders evaluate distance-based filters relative to these local coordinates. This renders localized visual phenomena (like impact craters, ripples, or color surges) that **rotate naturally with the parent object** and fade out smoothly over time.

---

## 🎥 High-Precision Canvas Recording & Latency Compensation
*   **Direct Buffer Capture**: The canvas WebGL buffer is captured directly using `renderer.domElement.captureStream(60)`.
*   **Encoder Lag Compensation**: Modern browser video encoders have an initialization lag (300ms to 800ms) before the first chunk is emitted. To guarantee a video of an **exact parameterized duration**, do not start the countdown timer when the record command is triggered. Instead, start the duration timer **only when the first actual encoded data chunk is received** by `ondataavailable`.
*   **Timing Resolution**: Call `mediaRecorder.start(100)` to request small data slices every 100ms. This maintains high timing resolution and ensures clean, precise automatic stopping.

---

## 💡 Developer Guidelines for Three.js Generative Art
1.  **Strict Resource Recycling**: Reuse a single global texture for all particle and spark systems rather than instantiating new canvas textures inside active loop events.
2.  **Double Buffering Attribute Updates**: When updating particle coordinates, modify Float32Arrays and flag buffer attributes for updates (`needsUpdate = true`). Avoid creating/destroying objects during `animate()`.
3.  **Disable Browser Cache**: Keep Chrome DevTools open with **Disable cache** checked in the Network tab to ensure local parameter changes reload instantly.
4.  **Canvas Sizing**: Project canvases should always be exactly **480x800** in dimensions and centered on the window.
5.  **Control UI Panel**: Do not show a control panel UI on the page for editing parameters; keep parameters in the code under a clean `PARAMS` configuration block at the top of the script.
6.  **Agent Testing**: Do not run the automated agent tester unless explicitly instructed by the user.
7.  **Version Control**: Do not run Git commands unless explicitly instructed by the user.

