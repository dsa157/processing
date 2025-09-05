import megamu.mesh.*;
import java.util.ArrayList;

// == PARAMETERS =======================================================
int SEED = 12345;
int PADDING = 10;
boolean INVERT_COLORS = false;
int MAX_FRAMES = 600;
boolean SAVE_FRAMES = false;
float ANIMATION_SPEED = 60; // frames per second

int numPoints = 15;
float pointRadius = 3;

int minInitialSpokes = 15;
int maxInitialSpokes = 30;
int minSpokes = 2;
int maxSpokes = 3;
float minSpokeLength = 10;
float maxSpokeLength = 40;
int maxSpokeDepth = 5;
float pulseDecayRate = 0.9;

// Colors
color backgroundColor = #000000;
color foregroundColor = #FFFFFF;
color voronoiColor = #FF0000;
color pointColor = #FFFF00;
color spokeColor = #FFFF00;
color pulseColor = #FFFF00;

// Voronoi
Voronoi myVoronoi;
float[][] pointsArray;
MPolygon[] voronoiRegions;
ArrayList<SpokeSystem> spokeSystems;

// == SETUP & DRAW =====================================================
void settings() {
  size(480, 800);
}

void setup() {
  randomSeed(SEED);
  if (INVERT_COLORS) {
    backgroundColor = #FFFFFF;
    foregroundColor = #000000;
    voronoiColor = #FF0000;
    pointColor = #FFFF00;
    spokeColor = #FFFF00;
    pulseColor = #FFFF00;
  }
  frameRate(ANIMATION_SPEED);
  resetSketch();
}

void draw() {
  background(backgroundColor);

  // Draw Voronoi edges
  stroke(voronoiColor);
  strokeWeight(2);
  noFill();

  float[][] myEdges = myVoronoi.getEdges();
  for (int i = 0; i < myEdges.length; i++) {
    float startX = myEdges[i][0];
    float startY = myEdges[i][1];
    float endX = myEdges[i][2];
    float endY = myEdges[i][3];
    line(startX, startY, endX, endY);
  }

  // Update and draw spoke systems
  for (SpokeSystem ss : spokeSystems) {
    ss.update();
  }

  // Draw pulsing cells
  for (SpokeSystem ss : spokeSystems) {
    ss.displayPulse();
  }

  // Draw spoke systems and check for completion
  stroke(spokeColor);
  strokeWeight(1.5);
  for (SpokeSystem ss : spokeSystems) {
    ss.display();
  }

  // Draw center points
  fill(pointColor);
  noStroke();
  for (int i = 0; i < numPoints; i++) {
    ellipse(pointsArray[i][0], pointsArray[i][1], pointRadius * 2, pointRadius * 2);
  }

  // Save frames and stop animation
  if (SAVE_FRAMES) {
    saveFrame("frames/####.tif");
  }
  if (frameCount >= MAX_FRAMES) {
    noLoop();
  }
}

void mousePressed() {
  resetSketch();
}

void resetSketch() {
  randomSeed(millis());
  
  pointsArray = new float[numPoints][2];
  for (int i = 0; i < numPoints; i++) {
    pointsArray[i][0] = random(PADDING, width - PADDING);
    pointsArray[i][1] = random(PADDING, height - PADDING);
  }

  myVoronoi = new Voronoi(pointsArray);
  voronoiRegions = myVoronoi.getRegions();
  spokeSystems = new ArrayList<SpokeSystem>();

  for (int i = 0; i < numPoints; i++) {
    if (i < voronoiRegions.length && voronoiRegions[i] != null) {
      PVector center = new PVector(pointsArray[i][0], pointsArray[i][1]);
      spokeSystems.add(new SpokeSystem(center, voronoiRegions[i]));
    }
  }
  
  loop();
}

// == CLASSES ==========================================================
class SpokeSystem {
  PVector center;
  MPolygon polygon;
  PVector[] paddedPolygon;
  ArrayList<Spoke> spokes;
  boolean isComplete = false;
  float pulseAlpha = 0;

  SpokeSystem(PVector _center, MPolygon _polygon) {
    this.center = _center;
    this.polygon = _polygon;
    this.paddedPolygon = padPolygon(this.polygon, PADDING);
    this.spokes = new ArrayList<Spoke>();

    // Create initial spokes using minInitialSpokes and maxInitialSpokes
    int num = floor(random(minInitialSpokes, maxInitialSpokes + 1));
    for (int i = 0; i < num; i++) {
      spokes.add(new Spoke(center, maxSpokeDepth, center, true));
    }
  }
  
  void startPulse() {
    isComplete = true;
    pulseAlpha = 255;
  }

  void update() {
    if (isComplete) {
      if (pulseAlpha > 0.5) {
        pulseAlpha *= pulseDecayRate;
      } else {
        isComplete = false;
        pulseAlpha = 0;
        spokes.clear();
        int num = floor(random(minInitialSpokes, maxInitialSpokes + 1));
        for (int i = 0; i < num; i++) {
            spokes.add(new Spoke(center, maxSpokeDepth, center, true));
        }
      }
      return;
    }

    ArrayList<Spoke> nextGen = new ArrayList<Spoke>();
    boolean allSpokesComplete = true;
    for (Spoke s : spokes) {
      s.update();
      if (s.isComplete() && !s.hasBranched) {
        s.hasBranched = true;
        int num = floor(random(minSpokes, maxSpokes + 1));
        for (int i = 0; i < num; i++) {
          nextGen.add(new Spoke(s.end, s.depth - 1, center, false));
        }
      }
      if (!s.isComplete() || !s.hasBranched) {
        allSpokesComplete = false;
      }
    }
    spokes.addAll(nextGen);

    if (allSpokesComplete && nextGen.isEmpty()) {
      startPulse();
    }
  }

  void display() {
    for (Spoke s : spokes) {
      if (pointInPolygon(s.end, paddedPolygon)) {
        s.display();
      }
    }
  }

  void displayPulse() {
    if (isComplete && pulseAlpha > 0.5) {
      noStroke();
      fill(red(pulseColor), green(pulseColor), blue(pulseColor), pulseAlpha);
      beginShape();
      for (PVector v : paddedPolygon) {
        vertex(v.x, v.y);
      }
      endShape(CLOSE);
    }
  }

  PVector[] padPolygon(MPolygon poly, float pad) {
    if (poly == null || poly.getCoords().length == 0) return null;

    float[][] coords = poly.getCoords();
    PVector[] points = new PVector[coords.length];
    for (int i = 0; i < coords.length; i++) {
      points[i] = new PVector(coords[i][0], coords[i][1]);
    }

    PVector[] padded = new PVector[points.length];

    // Calculate the centroid of the polygon
    PVector centroid = new PVector(0, 0);
    for (PVector p : points) {
      centroid.add(p);
    }
    centroid.div(points.length);

    // Move each vertex towards the centroid to "pad" it
    for (int i = 0; i < points.length; i++) {
      PVector p = points[i];
      PVector dir = PVector.sub(centroid, p);
      dir.normalize();
      dir.mult(pad);
      padded[i] = PVector.add(p, dir);
    }

    return padded;
  }

  boolean pointInPolygon(PVector p, PVector[] poly) {
    if (poly == null || poly.length == 0) return false;

    boolean inside = false;
    for (int i = 0, j = poly.length - 1; i < poly.length; j = i++) {
      if (((poly[i].y > p.y) != (poly[j].y > p.y)) &&
        (p.x < (poly[j].x - poly[i].x) * (p.y - poly[i].y) / (poly[j].y - poly[i].y) + poly[i].x)) {
        inside = !inside;
      }
    }
    return inside;
  }
}

class Spoke {
  PVector start;
  PVector end;
  float targetLength;
  float currentLength;
  float angle;
  int depth;
  boolean canBranch = true;
  boolean hasBranched = false;
  PVector origin;

  Spoke(PVector _start, int _depth, PVector _origin, boolean _isInitial) {
    this.start = _start.copy();
    this.end = _start.copy();
    this.depth = _depth;
    this.targetLength = random(minSpokeLength, maxSpokeLength);
    this.currentLength = 0;
    this.origin = _origin;
    
    if (_isInitial) {
      // For initial spokes, use a random angle for 360-degree spread
      this.angle = random(TWO_PI);
    } else {
      // For subsequent spokes, calculate angle away from the origin
      PVector direction = PVector.sub(start, origin);
      float baseAngle = atan2(direction.y, direction.x);
      float angleVariation = radians(random(-10, 10));
      this.angle = baseAngle + angleVariation;
    }
  }

  void update() {
    if (currentLength < targetLength) {
      currentLength += 1;
      float x = start.x + cos(angle) * currentLength;
      float y = start.y + sin(angle) * currentLength;
      end.set(x, y);
    }
  }

  void display() {
    line(start.x, start.y, end.x, end.y);
  }

  boolean isComplete() {
    return canBranch && currentLength >= targetLength && depth > 0;
  }
}
