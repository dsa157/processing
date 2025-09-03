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
