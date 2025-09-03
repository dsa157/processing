import processing.svg.*; // Import the SVG library

class Icon {
  float x, y, size;
  PShape iconShape;
  ClickHandler handler;
  
  Icon(float x, float y, float size, String svgPath, ClickHandler handler) {
    this.x = x;
    this.y = y;
    this.size = size;
    this.iconShape = loadShape(svgPath);
    this.handler = handler;
  }
  
  void display() {
    float alpha = 255;
    if (isHovered()) {
      alpha = 150; // Fade slightly when hovered
    }
    
    pushMatrix();
    translate(x, y);
    shapeMode(CENTER);
    tint(255, alpha); // Apply transparency
    shape(iconShape, 0, 0, size, size);
    popMatrix();
  }
  
  boolean isHovered() {
    return dist(mouseX, mouseY, x, y) < size / 2;
  }
  
  void clicked() {
    if (isHovered() && handler != null) {
      handler.onClick();
    }
  }
}

// ------------------- Handler Interface -------------------

interface ClickHandler {
  void onClick();
}

// ------------------- Specific Handlers -------------------

class SettingsHandler implements ClickHandler {
  void onClick() {
    println("Settings clicked!");
    // Your settings screen logic here
  }
}

class SaveHandler implements ClickHandler {
  void onClick() {
    println("Save clicked!");
    // Your save logic here
  }
}

class ShareHandler implements ClickHandler {
  void onClick() {
    println("Share clicked!");
    // Your share logic here
  }
}

class PrintHandler implements ClickHandler {
  void onClick() {
    println("Print clicked!");
    // Your print logic here
  }
}
