import java.net.URI;

PGraphics textLayer;
PGraphics bgLayer;
PShape shapeTest;
PFont font;
PImage img;
boolean showTextLayer = false;

void setup() {
  size(800, 600);
  textLayer = createGraphics(width, height);
  bgLayer = createGraphics(width, height);
  img = loadImage("http://dsa157.com/NFT/Davids-Lyre-1-small.png");
  image(img, 0, 0);
  //String[] fontList = PFont.list();
  font = createFont("Courier", 18, true);

  textLayer.beginDraw();
  textLayer.fill(color(255, 255, 255, 255));
  textLayer.noStroke();
  textLayer.textFont(font);
  textLayer.textAlign(LEFT);
  textLayer.text(getHelpText(), 40,80);
  textLayer.endDraw();

  bgLayer.beginDraw();
  bgLayer.background(0,0,0,150);
  bgLayer.translate(width/2, height/2);
  bgLayer.endDraw();
  
  try {
  URI uri = new URI("http://dsa157.com/NFT/Davids-Lyre-1-small.png");
  String path = uri.getPath(); // split whatever you need
  String[] pathParts = path.split("/");
  String fn = pathParts[pathParts.length-1];
  println("simple path 1=", fn);
  uri = new URI("Davids-Lyre-1-small.png");
  path = uri.getPath(); 
  pathParts = path.split("/");
  fn = pathParts[pathParts.length-1];
  println("simple path 2=", fn);
  }
  catch(Exception e) {
    e.printStackTrace();
  }

}

void draw() {
  background(125);
//  image(bgLayer, 0, 0);
  image(img, 0, 0);
  if (showTextLayer) {
    image(bgLayer, 0, 0);
    image(textLayer, 0, 0);
  }
}

void keyPressed() {
  if (key == '?') {
    showTextLayer = !showTextLayer;
  }
}

String getHelpText() {
  String t = "Keyboard Control\n";
  t += "'?' - toggle this help screen\n";
  t += "'q' - quit the application\n";
  t += "'n' - next base image\n";
  t += "'p' - previous base image\n";
  t += "'c' - cycle effects on the current image\n";
  t += "'r' - toggle randomize mode\n";
  t += "'o' - randomize the opacity of the color overlay layer\n";
  t += "'a' - toggle auto-display mode\n";
  t += "'s' - save parameters of the current display image\n      to the metadata file in the output folder\n";
  t += "'1' - animate by cycling the gradient colors\n";
  t += "\n\nMouse Control\n";
  t += "- click a point in the image to zoom,\n  subsequent zooms will preserves that point.\n";
  t += "- after returning to zoom level 1,\n  a new point can be selected.\n";

  return t;
}
