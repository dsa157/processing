import megamu.mesh.*;
import java.util.ArrayList;

int SEED = 12345;
int numPoints = 15;
color voronoiColor = #FF0000;
color pointColor = #FF0000;
float pointRadius = 3;

Voronoi myVoronoi;
float[][] pointsArray;

void settings() {
  size(800, 800);
}

void setup() {
  randomSeed(SEED);
  background(0);
  
  pointsArray = new float[numPoints][2];
  for (int i = 0; i < numPoints; i++) {
    pointsArray[i][0] = random(width);
    pointsArray[i][1] = random(height);
  }

  myVoronoi = new Voronoi(pointsArray);
}

void draw() {
  background(0);
  
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
  
  // Draw center points
  fill(pointColor);
  noStroke();
  for (int i = 0; i < numPoints; i++) {
    ellipse(pointsArray[i][0], pointsArray[i][1], pointRadius * 2, pointRadius * 2);
  }
  
  noLoop();
}
