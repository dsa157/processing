import processing.svg.*; 

int SEED = 12345;
ArrayList<Circle> circles = new ArrayList<Circle>();
Menu menu;
boolean menuVisible = true; // Controls menu visibility

void setup() {
  size(800, 600);
  randomSeed(SEED);
  background(0);
  noFill();
  strokeWeight(2);
  
  // NOTE: You must provide your own SVG icon files for this to work.
  // The paths below assume the files are in a "data" folder in your sketch directory.
  menu = new Menu(40, 40, 50, "gear.svg", "save.svg", "share.svg", "print.svg");
}

void draw() {
  background(0);
  
  if (frameCount % 10 == 0) {
    circles.add(new Circle());
  }

  // Iterate backwards to safely remove circles as they expire
  for (int i = circles.size() - 1; i >= 0; i--) {
    Circle c = circles.get(i);
    c.display();
    if (c.isDead()) {
      circles.remove(i);
    }
  }
  
  // Only display the menu if the flag is true
  if (menuVisible) {
    menu.display();
  }
}

void mousePressed() {
  if (menuVisible) {
    // If the menu is visible, check if a click happened on the close area
    if (!menu.isHovered()) {
      menuVisible = false;
      println("Menu closed.");
    } else {
      // If the menu is visible and an icon was clicked
      println("Menu opened.");
      menu.handleMouseClick();
    }
  } else {
    // If the menu is not visible, check for a click in the "hotspot"
    if (mouseX < 80 && mouseY < 80) { // Top-left corner hotspot
      menuVisible = true;
      println("Menu opened.");
    }
  }
}

// ------------------- Circle Class -------------------

class Circle {
  float x, y, s;
  color c;
  long bornTime;
  
  Circle() {
    this.x = random(width);
    this.y = random(height);
    this.s = random(20, 150);
    this.c = color(random(255), random(255), random(255));
    this.bornTime = millis();
  }

  void display() {
    float age = millis() - bornTime;
    float alpha = 255;
    
    // Fade out after 3 seconds, over a 2-second period
    if (age > 3000) {
      alpha = map(age, 3000, 5000, 255, 0);
    }
    
    stroke(c, alpha);
    ellipse(x, y, s, s);
  }
  
  boolean isDead() {
    return (millis() - bornTime) > 5000;
  }
}

// ------------------- Menu Classes -------------------

class Menu {
  ArrayList<Icon> icons;
  float menuX, menuY;
  float iconSpacing = 60; // Spacing between icons
  
  Menu(float x, float y, float iconSize, String gearPath, String savePath, String sharePath, String printPath) {
    this.menuX = x;
    this.menuY = y;
    
    icons = new ArrayList<Icon>();
    
    icons.add(new Icon(menuX, menuY, iconSize, gearPath, new SettingsHandler()));
    icons.add(new Icon(menuX + iconSpacing, menuY, iconSize, savePath, new SaveHandler()));
    icons.add(new Icon(menuX + iconSpacing * 2, menuY, iconSize, sharePath, new ShareHandler()));
    icons.add(new Icon(menuX + iconSpacing * 3, menuY, iconSize, printPath, new PrintHandler()));
  }
  
  void display() {
    for (Icon icon : icons) {
      icon.display();
    }
  }
  
  void handleMouseClick() {
    for (Icon icon : icons) {
      icon.clicked();
    }
  }
  
  boolean isHovered() {
    for (Icon icon : icons) {
      if (icon.isHovered()) {
        return true;
      }
    }
    return false;
  }
}

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
      alpha = 150; 
    }
    
    pushMatrix();
    translate(x, y);
    shapeMode(CENTER);
    tint(255, alpha); 
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

interface ClickHandler {
  void onClick();
}

class SettingsHandler implements ClickHandler {
  void onClick() {
    println("Settings clicked!");
  }
}

class SaveHandler implements ClickHandler {
  void onClick() {
    println("Save clicked!");
  }
}

class ShareHandler implements ClickHandler {
  void onClick() {
    println("Share clicked!");
  }
}

class PrintHandler implements ClickHandler {
  void onClick() {
    println("Print clicked!");
  }
}
