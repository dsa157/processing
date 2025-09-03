// Tessellation Explorer
// Generates intricate, non-repeating tessellations.

int seed = 12345;
PShader tessellationShader;
PGraphics buffer;
PVector cameraPos;
float zoom;

void settings() {
  size(800, 800, P2D);
}

void setup() {
  randomSeed(seed);
  cameraPos = new PVector(0, 0);
  zoom = 1.0;

  buffer = createGraphics(width, height, P2D);
  tessellationShader = loadShader("tessellation.glsl");
}

void draw() {
  if (frameCount == 1) {
    updateTessellation();
  }

  image(buffer, 0, 0);

  // Simple camera controls
  if (keyPressed) {
    float moveSpeed = 10 / zoom;
    if (key == 'w') cameraPos.y -= moveSpeed;
    if (key == 's') cameraPos.y += moveSpeed;
    if (key == 'a') cameraPos.x -= moveSpeed;
    if (key == 'd') cameraPos.x += moveSpeed;
    updateTessellation();
  }
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  float zoomFactor = 1.1;
  if (e > 0) {
    zoom /= zoomFactor;
  } else {
    zoom *= zoomFactor;
  }
  updateTessellation();
}

void updateTessellation() {
  buffer.beginDraw();
  tessellationShader.set("u_resolution", (float)width, (float)height);
  tessellationShader.set("u_cameraPos", cameraPos.x, cameraPos.y);
  tessellationShader.set("u_zoom", zoom);
  tessellationShader.set("u_time", millis() / 1000.0);
  buffer.shader(tessellationShader);
  buffer.rect(0, 0, width, height);
  buffer.endDraw();
}

/*
  Paste this into a new file named "tessellation.glsl"
  
  #ifdef GL_ES
  precision mediump float;
  #endif
  
  uniform vec2 u_resolution;
  uniform vec2 u_cameraPos;
  uniform float u_zoom;
  uniform float u_time;
  
  float a_rule(vec2 p) {
      return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
  }
  
  void main() {
      vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution) / u_resolution.y;
      p /= u_zoom;
      p += u_cameraPos / u_resolution.y;
  
      vec2 grid = floor(p * 10.0);
      vec2 cell = fract(p * 10.0);
  
      float pattern = 0.0;
      float noise = a_rule(grid);
  
      if (noise > 0.5) {
          pattern = mod(floor(p.x * 20.0) + floor(p.y * 20.0), 2.0);
      } else {
          pattern = mod(floor(p.x * 20.0), 2.0);
      }
      
      float color = pattern * (0.8 + 0.2 * sin(u_time));
      gl_FragColor = vec4(vec3(color), 1.0);
  }
*/
