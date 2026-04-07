/**
 * Processing Sketch Memories & Rules
 * Version: 2026.04.07.15.03.35
 * Description: Permanent implementation rules and design principles for all Processing projects.
 */

/* 🛠️ Technical Structure & Code Logic */
// 1. Global Seed: Use a seed parameter to initialize random() values for reproducibility.
// 2. No Magic Numbers: Parameterize ALL values at the top of the script. Use **ALL CAPS** for parameter names to distinguish them clearly.
// 3. Default Values in Comments: Store original values next to parameters (e.g. `float r = 10; // 10`).
// 4. Versioning: Use YYYY.MM.DD.HH.mm.SS formatted timestamps in the header. Only update the version if the file's content has changed.
// 5. Canvas Setup: Default 480x800. Prefer using `void settings() { size(SKETCH_WIDTH, SKETCH_HEIGHT); }`. 
//    EXCEPTION: If a "Duplicate method settings()" error occurs, remove `void settings()` and hard-code `size(480, 800);` as the first line in `void setup()`.
// 6. Padding: Include a `padding` parameter (default 40) for the overall sketch area.
// 7. Background Inversion: Allow background color to be easily inverted via parameter.
// 8. Reserved Words: Do NOT use reserved words (like `color`) as variable names.
// 9. Design Pattern: Use classes if it improves design; otherwise, keep it simple and clean.
// 10. Implement Code: Do not use image generation tools; implement all visuals via code.

/* 📁 Project Structure & Organization */
// 1. Sub-Projects: Create a subfolder for each new PDE file.
// 2. Default Path: New projects are placed under `projects/` by default.
// 3. Nested Folders: Extra folder info specifies subfolders under `projects/`.

/* 🎨 Design, Aesthetics & Color */
// 1. Color Palettes: 5 distinct hex arrays (Adobe Kuler) + 1 Grayscale + 1 Pure Black & White (7 total).
// 2. Palette Selection: Use a `paletteIndex` parameter to switch active sets.
// 3. Background Color: Must be selectable from the active palette.
// 4. Rich Aesthetics: Prioritize premium visuals, smooth gradients, and micro-animations.
// 5. Grid Logic: If using grids, add a show/hide toggle parameter (default: hide).

/* 🎬 Animation & Rendering */
// 1. Frame Limits: `MAX_FRAMES` (default 900).
// 2. Saving: `SAVE_FRAMES` (default false). If true, save as `frames/####.tif`.
// 3. Speed: `ANIMATION_SPEED` (default 30). 
// 4. Loop Control: Only stop (noLoop()) if `SAVE_FRAMES` is true AND `frameCount >= MAX_FRAMES`.

/* 🤖 Interaction & Delivery Style */
// 1. Brief Communication: Concise, direct, and non-sycophantic.
// 2. Revision Confirmation: Never declare "final" until verified working.
// 3. Creative Freedom: Add visual polish beyond basic requirements.
// 4. Git Context: Do NOT perform or propose any git changes (stage/commit/push) unless explicitly specified.
// 5. Collaborative Suggestions: Proactively suggest visual or technical improvements that add value to the creative process.
