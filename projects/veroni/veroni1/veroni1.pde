import java.util.Collections;
import processing.libraries.delaunay.*;

int SEED = 12345;
int numPoints = 80;
float lineDensity = 0.5;
float maxLineJitter = 10;
float maxLineLength = 200;

Delaunay delaunay;
ArrayList<PVector> points;

void settings() {
  size(800, 800);
}

void setup() {
  randomSeed(SEED);
  background(0);
  noFill();
  stroke(255);
  strokeWeight(1);
  
  points = new ArrayList<PVector>();
  for (int i = 0; i < numPoints; i++) {
    points.add(new PVector(random(width), random(height)));
  }

  delaunay = new Delaunay(points);
}

void draw() {
  background(0);
  
  // Get Voronoi cells from the Delaunay triangulation
  ArrayList<Polygon2D> voronoiCells = delaunay.voronoiCells();
  
  // Draw lines within each cell
  for (int i = 0; i < voronoiCells.size(); i++) {
    Polygon2D cell = voronoiCells.get(i);
    PVector cellCenter = points.get(i);
    
    // Iterate through the vertices of the Voronoi cell
    for (int j = 0; j < cell.getVertices().size(); j++) {
      PVector vertex = cell.getVertices().get(j);
      
      // Draw multiple lines radiating from the center towards the vertex
      for (int k = 0; k < lineDensity * 100; k++) {
        float angle = atan2(vertex.y - cellCenter.y, vertex.x - cellCenter.x);
        float distance = dist(cellCenter.x, cellCenter.y, vertex.x, vertex.y);
        
        // Add jitter to the angle and line length
        float jitterAngle = angle + random(-PI/50, PI/50);
        float jitterDist = random(distance * 0.8, distance * 1.2);

        // Calculate the end point of the line
        float endX = cellCenter.x + cos(jitterAngle) * jitterDist;
        float endY = cellCenter.y + sin(jitterAngle) * jitterDist;
        
        line(cellCenter.x, cellCenter.y, endX, endY);
      }
    }
  }
  
  // A simple way to stop after one frame to show the full pattern
  noLoop();
}
