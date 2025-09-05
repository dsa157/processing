import megamu.mesh.*;
import java.util.ArrayList;
import java.util.Arrays;

// == PARAMETERS =======================================================
int SEED = 12345;
int PADDING = 20;
boolean INVERT_COLORS = false;
int MAX_FRAMES = 600;
boolean SAVE_FRAMES = false;
float ANIMATION_SPEED = 60; // frames per second

int numPoints = 15;
float pointRadius = 3;

int minInitialSpokes = 30;
int maxInitialSpokes = 50;
int minSpokes = 2;
int maxSpokes = 3;
float minSpokeLength = 60;
float maxSpokeLength = 150;
int maxSpokeDepth = 5;
float pulseDecayRate = 0.9;
float minSpokeBranchAngle = 20;
float maxSpokeBranchAngle = 60;
boolean drawSpokes = true;
boolean showPaddedCells = false;
int paddedCellAlpha = 102;
boolean showPaddedCanvas = false;

// Colors
color backgroundColor = #000000;
color foregroundColor = #FFFFFF;
color voronoiColor = #FF0000;
color pointColor = #FFFF00;
color spokeColor = #FFFF00;
color pulseColor = #FFFF00;
color paddedCellColor = color(0, 0, 255, paddedCellAlpha);
color paddedCanvasColor = color(0, 255, 0, 102);


// Voronoi
Voronoi myVoronoi;
float[][] pointsArray;
MPolygon[] voronoiRegions;
ArrayList<SpokeSystem> spokeSystems;

PGraphics paddedCellsBuffer;

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
    paddedCellColor = color(0, 0, 255, paddedCellAlpha);
    paddedCanvasColor = color(0, 255, 0, 102);
  }
  frameRate(ANIMATION_SPEED);
  paddedCellsBuffer = createGraphics(width, height);
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
  
  // Draw padded canvas rectangle
  if (showPaddedCanvas) {
    noStroke();
    fill(paddedCanvasColor);
    rect(PADDING, PADDING, width - PADDING * 2, height - PADDING * 2);
  }

  // Draw padded cell boundaries to the off-screen buffer
  if (showPaddedCells) {
    paddedCellsBuffer.beginDraw();
    paddedCellsBuffer.background(0, 0);
    paddedCellsBuffer.noStroke();
    paddedCellsBuffer.fill(paddedCellColor);
    for (SpokeSystem ss : spokeSystems) {
      if (ss.paddedPolygon != null && ss.paddedPolygon.length > 0) {
        paddedCellsBuffer.beginShape();
        for (PVector p : ss.paddedPolygon) {
          paddedCellsBuffer.vertex(p.x, p.y);
        }
        paddedCellsBuffer.endShape(CLOSE);
      }
    }
    paddedCellsBuffer.endDraw();
    image(paddedCellsBuffer, 0, 0);
  }

  // Update and draw spoke systems
  if (drawSpokes) {
    for (SpokeSystem ss : spokeSystems) {
      ss.update();
    }

    for (SpokeSystem ss : spokeSystems) {
      ss.display();
    }
  }

  // Draw pulsing cells
  for (SpokeSystem ss : spokeSystems) {
    ss.displayPulse();
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

    int num = floor(random(minInitialSpokes, maxInitialSpokes + 1));
    for (int i = 0; i < num; i++) {
      spokes.add(new Spoke(center, maxSpokeDepth, center, true, paddedPolygon));
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
            spokes.add(new Spoke(center, maxSpokeDepth, center, true, paddedPolygon));
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
          nextGen.add(new Spoke(s.end, s.depth - 1, center, false, paddedPolygon));
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
      s.display();
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
    PVector[] paddedPoints = new PVector[coords.length];
    
    PVector centroid = new PVector(0, 0);
    for (int i = 0; i < coords.length; i++) {
      centroid.add(coords[i][0], coords[i][1]);
    }
    centroid.div(coords.length);
    
    for (int i = 0; i < coords.length; i++) {
      PVector p = new PVector(coords[i][0], coords[i][1]);
      PVector dir = PVector.sub(centroid, p);
      dir.normalize();
      dir.mult(pad);
      paddedPoints[i] = PVector.add(p, dir);
    }
    
    PVector[] canvasBoundary = {
      new PVector(PADDING, PADDING), 
      new PVector(width - PADDING, PADDING),
      new PVector(width - PADDING, height - PADDING),
      new PVector(PADDING, height - PADDING)
    };
    
    return clipPolygon(paddedPoints, canvasBoundary);
  }
  
  PVector[] clipPolygon(PVector[] poly, PVector[] clipper) {
      ArrayList<PVector> outputList = new ArrayList<PVector>();
      
      for (int i = 0; i < clipper.length; i++) {
          ArrayList<PVector> inputList = new ArrayList<PVector>(outputList);
          outputList.clear();
          
          PVector p1 = clipper[i];
          PVector p2 = clipper[(i + 1) % clipper.length];
          
          if (inputList.isEmpty()) {
              inputList.addAll(Arrays.asList(poly));
          }
          
          PVector s = inputList.get(inputList.size() - 1);
          
          for (PVector e : inputList) {
              boolean isEInside = isInside(e, p1, p2);
              boolean isSInside = isInside(s, p1, p2);
              
              if (isEInside) {
                  if (!isSInside) {
                      outputList.add(lineIntersection(s, e, p1, p2));
                  }
                  outputList.add(e);
              } else if (isSInside) {
                  outputList.add(lineIntersection(s, e, p1, p2));
              }
              s = e;
          }
      }
      
      return outputList.toArray(new PVector[0]);
  }
  
  boolean isInside(PVector p, PVector a, PVector b) {
      return (b.x - a.x) * (p.y - a.y) > (b.y - a.y) * (p.x - a.x);
  }
  
  PVector lineIntersection(PVector a1, PVector a2, PVector b1, PVector b2) {
      float denom = (b2.y - b1.y) * (a2.x - a1.x) - (b2.x - b1.x) * (a2.y - a1.y);
      if (abs(denom) < 0.0001) return null;
      
      float ua = ((b2.x - b1.x) * (a1.y - b1.y) - (b2.y - b1.y) * (a1.x - b1.x)) / denom;
      
      return new PVector(a1.x + ua * (a2.x - a1.x), a1.y + ua * (a2.y - a1.y));
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
  PVector[] boundary;

  Spoke(PVector _start, int _depth, PVector _origin, boolean _isInitial, PVector[] _boundary) {
    this.start = _start.copy();
    this.end = _start.copy();
    this.depth = _depth;
    this.targetLength = random(minSpokeLength, maxSpokeLength);
    this.currentLength = 0;
    this.origin = _origin;
    this.boundary = _boundary;
    
    if (_isInitial) {
      this.angle = random(TWO_PI);
    } else {
      PVector direction = PVector.sub(start, origin);
      float baseAngle = atan2(direction.y, direction.x);
      float branchAngle = radians(random(minSpokeBranchAngle, maxSpokeBranchAngle));
      if (random(1) > 0.5) {
        this.angle = baseAngle + branchAngle;
      } else {
        this.angle = baseAngle - branchAngle;
      }
    }
  }

  void update() {
    if (currentLength < targetLength) {
      float nextLength = currentLength + 1;
      float x = start.x + cos(angle) * nextLength;
      float y = start.y + sin(angle) * nextLength;
      
      PVector testEnd = new PVector(x, y);
      if (!pointInPolygon(testEnd, boundary)) {
          PVector intersection = findIntersection(start, testEnd, boundary);
          if (intersection != null) {
              end.set(intersection);
              currentLength = targetLength;
          } else {
              currentLength = targetLength; 
          }
      } else {
          currentLength = nextLength;
          end.set(x, y);
      }
    }
  }

  void display() {
    line(start.x, start.y, end.x, end.y);
  }

  boolean isComplete() {
    return canBranch && currentLength >= targetLength && depth > 0;
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
  
  PVector findIntersection(PVector p1, PVector p2, PVector[] poly) {
      PVector intersection = null;
      float closestDistance = Float.MAX_VALUE;
      
      for (int i = 0; i < poly.length; i++) {
          PVector p3 = poly[i];
          PVector p4 = poly[(i + 1) % poly.length];
          
          PVector intersectionPoint = lineIntersection(p1, p2, p3, p4);
          if (intersectionPoint != null) {
              float distance = PVector.dist(p1, intersectionPoint);
              if (distance < closestDistance) {
                  closestDistance = distance;
                  intersection = intersectionPoint;
              }
          }
      }
      return intersection;
  }
  
  PVector lineIntersection(PVector a1, PVector a2, PVector b1, PVector b2) {
      float denom = (b2.y - b1.y) * (a2.x - a1.x) - (b2.x - b1.x) * (a2.y - a1.y);
      if (abs(denom) < 0.0001) return null; // Parallel lines
      
      float ua = ((b2.x - b1.x) * (a1.y - b1.y) - (b2.y - b1.y) * (a1.x - b1.x)) / denom;
      float ub = ((a2.x - a1.x) * (a1.y - b1.y) - (a2.y - a1.y) * (a1.x - b1.x)) / denom;
      
      if (ua >= 0 && ua <= 1 && ub >= 0 && ub <= 1) {
          return new PVector(a1.x + ua * (a2.x - a1.x), a1.y + ua * (a2.y - a1.y));
      }
      return null;
  }
}
