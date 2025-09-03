class Menu {
  ArrayList<Icon> icons;
  float menuX, menuY;
  float iconSpacing = 60; // Spacing between icons
  
  Menu(float x, float y, float iconSize) {
    this.menuX = x;
    this.menuY = y;
    
    // Initialize the icon list
    icons = new ArrayList<Icon>();
    
    // Note: Replace "path/to/icon.svg" with the actual path to your SVG files
    icons.add(new Icon(menuX, menuY, iconSize, "path/to/gear.svg", new SettingsHandler()));
    icons.add(new Icon(menuX + iconSpacing, menuY, iconSize, "path/to/save.svg", new SaveHandler()));
    icons.add(new Icon(menuX + iconSpacing * 2, menuY, iconSize, "path/to/share.svg", new ShareHandler()));
    icons.add(new Icon(menuX + iconSpacing * 3, menuY, iconSize, "path/to/print.svg", new PrintHandler()));
  }
  
  void display() {
    // Only show the menu when the mouse is within the sketch area
    if (mouseX >= 0 && mouseX <= width && mouseY >= 0 && mouseY <= height) {
      for (Icon icon : icons) {
        icon.display();
      }
    }
  }
  
  void handleMouseClick() {
    for (Icon icon : icons) {
      icon.clicked();
    }
  }
}
