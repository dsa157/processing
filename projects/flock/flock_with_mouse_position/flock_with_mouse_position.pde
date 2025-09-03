// A global seed for reproducible randomness.
long seed = 157157;

ArrayList<Boid> flock;
FlockLeader leader;

void setup() {
  size(800, 600);
  randomSeed(seed);
  
  flock = new ArrayList<Boid>();
  // Create a flock of 200 boids
  for (int i = 0; i < 200; i++) {
    flock.add(new Boid(random(width), random(height)));
  }
  
  // Create the flock leader
  leader = new FlockLeader();
}

void draw() {
  background(255); // White background
  
  // Update the leader's position to follow the mouse
  leader.update(mouseX, mouseY);
  leader.display();
  
  // Update and display each boid in the flock
  for (Boid b : flock) {
    b.run(flock, leader);
  }
}

// Boid class represents a single particle
class Boid {
  PVector position;
  PVector velocity;
  PVector acceleration;
  float r;
  float maxforce;    // Maximum steering force
  float maxspeed;    // Maximum speed

  Boid(float x, float y) {
    acceleration = new PVector(0, 0);
    velocity = PVector.random2D();
    position = new PVector(x, y);
    r = random(2, 6); // Random size for each particle
    maxspeed = random(2, 4); // Random speed for each particle
    maxforce = 0.05;
  }

  void run(ArrayList<Boid> boids, FlockLeader leader) {
    flock(boids, leader);
    update();
    borders();
    render();
  }

  void flock(ArrayList<Boid> boids, FlockLeader leader) {
    PVector sep = separate(boids); // Separation
    PVector ali = align(boids);    // Alignment
    PVector coh = cohesion(boids);   // Cohesion
    PVector fol = followLeader(leader); // Follow the leader
    
    // Weight the forces
    sep.mult(1.5);
    ali.mult(1.0);
    coh.mult(1.0);
    fol.mult(0.5); // Give less weight to following the leader to maintain flocking behavior
    
    // Add the force vectors to acceleration
    acceleration.add(sep);
    acceleration.add(ali);
    acceleration.add(coh);
    acceleration.add(fol);
  }

  // Update position and acceleration
  void update() {
    velocity.add(acceleration);
    velocity.limit(maxspeed);
    position.add(velocity);
    acceleration.mult(0);
  }
  
  // A method to keep the boids within the window boundaries
  void borders() {
    if (position.x < 0) position.x = width;
    if (position.y < 0) position.y = height;
    if (position.x > width) position.x = 0;
    if (position.y > height) position.y = 0;
  }

  // Render the boid
  void render() {
    noStroke();
    fill(0, 50); // Semi-transparent black
    ellipse(position.x, position.y, r, r);
  }
  
  // Separation: steer away from neighbors
  PVector separate(ArrayList<Boid> boids) {
    float desiredseparation = 25.0;
    PVector steer = new PVector(0, 0, 0);
    int count = 0;
    for (Boid other : boids) {
      float d = PVector.dist(position, other.position);
      if ((d > 0) && (d < desiredseparation)) {
        PVector diff = PVector.sub(position, other.position);
        diff.normalize();
        diff.div(d); // Weight by distance
        steer.add(diff);
        count++;
      }
    }
    if (count > 0) {
      steer.div(count);
    }
    if (steer.mag() > 0) {
      steer.normalize();
      steer.mult(maxspeed);
      steer.sub(velocity);
      steer.limit(maxforce);
    }
    return steer;
  }
  
  // Alignment: Steer towards the average heading of neighbors
  PVector align(ArrayList<Boid> boids) {
    float neighborDist = 50;
    PVector sum = new PVector(0, 0);
    int count = 0;
    for (Boid other : boids) {
      float d = PVector.dist(position, other.position);
      if ((d > 0) && (d < neighborDist)) {
        sum.add(other.velocity);
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      sum.normalize();
      sum.mult(maxspeed);
      PVector steer = PVector.sub(sum, velocity);
      steer.limit(maxforce);
      return steer;
    } else {
      return new PVector(0, 0);
    }
  }

  // Cohesion: Steer to move toward the center of the flock
  PVector cohesion(ArrayList<Boid> boids) {
    float neighborDist = 50;
    PVector sum = new PVector(0, 0);
    int count = 0;
    for (Boid other : boids) {
      float d = PVector.dist(position, other.position);
      if ((d > 0) && (d < neighborDist)) {
        sum.add(other.position);
        count++;
      }
    }
    if (count > 0) {
      sum.div(count);
      return steerTo(sum); // Steer towards the center of mass
    } else {
      return new PVector(0, 0);
    }
  }

  // Follow Leader: Steer towards the leader
  PVector followLeader(FlockLeader leader) {
    return steerTo(leader.position);
  }

  // A generic method to calculate the steering force towards a target
  PVector steerTo(PVector target) {
    PVector desired = PVector.sub(target, position);
    float d = desired.mag();
    if (d > 0) {
      desired.normalize();
      if (d < 100) {
        float m = map(d, 0, 100, 0, maxspeed);
        desired.mult(m);
      } else {
        desired.mult(maxspeed);
      }
      PVector steer = PVector.sub(desired, velocity);
      steer.limit(maxforce);
      return steer;
    }
    return new PVector(0, 0);
  }
}

// FlockLeader class represents the leader that the flock follows
class FlockLeader {
  PVector position;
  float size = 15;

  FlockLeader() {
    position = new PVector(width / 2, height / 2);
  }
  
  void update(float x, float y) {
    position.x = x;
    position.y = y;
  }
  
  void display() {
    stroke(255, 0, 0); // Red
    strokeWeight(2);
    fill(255, 0, 0, 50);
    ellipse(position.x, position.y, size, size);
    noStroke();
  }
}
