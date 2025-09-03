// A global seed for reproducible randomness.
long seed = 12345;

ArrayList<Boid> flock;
FlockLeader leader;

// Global parameter for how often the leader changes its target position
int leaderChangeInterval = 5; // in seconds

void setup() {
  size(480, 800);
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
  
  // Update and display the leader and its trail
  leader.run();
  
  // Update and display each boid in the flock
  for (Boid b : flock) {
    b.run(flock, leader);
  }
}

// Boid class remains the same as the previous sketch
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
  PVector velocity;
  PVector targetPosition;
  float maxspeed;
  float maxforce;
  long lastChangeTime;

  // Trail history for the gradient effect
  ArrayList<PVector> history;
  int historySize = 50;
  
  // A boolean to track if the leader is "waiting" at a target
  boolean atTarget = true;

  FlockLeader() {
    position = new PVector(width / 2, height / 2);
    velocity = new PVector(0, 0);
    targetPosition = new PVector(width / 2, height / 2);
    maxspeed = 3;
    maxforce = 0.1;
    lastChangeTime = millis();
    history = new ArrayList<PVector>();
  }
  
  void run() {
    update();
    display();
  }

  void update() {
    float distanceToTarget = PVector.dist(position, targetPosition);
    
    // Check if the leader has reached its current target
    if (distanceToTarget < 10) {
      atTarget = true;
      velocity.set(0, 0); // Stop the leader
    } else {
      atTarget = false;
    }

    // If the leader is at the target AND the time interval has passed,
    // choose a new random target position.
    if (atTarget && millis() - lastChangeTime > leaderChangeInterval * 1000) {
      targetPosition.x = random(width);
      targetPosition.y = random(height);
      lastChangeTime = millis();
      atTarget = false; // The leader is no longer "at" the target
    }
    
    // Steer towards the target position if not at the target
    if (!atTarget) {
      PVector desired = PVector.sub(targetPosition, position);
      float d = desired.mag();
      if (d > 0) {
        desired.normalize();
        desired.mult(maxspeed);
        PVector steer = PVector.sub(desired, velocity);
        steer.limit(maxforce);
        velocity.add(steer);
      }
    }
    
    // Update position and add to history for the trail
    velocity.limit(maxspeed);
    position.add(velocity);
    
    // Add current position to history list
    history.add(position.copy());
    if (history.size() > historySize) {
      history.remove(0);
    }
  }
  
  void display() {
    // Draw the gradient trail
    for (int i = 0; i < history.size(); i++) {
      PVector trailPos = history.get(i);
      float alpha = map(i, 0, history.size(), 0, 255);
      float size = map(i, 0, history.size(), 1, 15);
      
      // Interpolate color from black to white
      float c = map(i, 0, history.size(), 0, 255);
      
      noStroke();
      fill(c, alpha);
      ellipse(trailPos.x, trailPos.y, size, size);
    }

    // Draw the leader itself
    stroke(0); // Black outline
    strokeWeight(2);
    fill(0);   // Black fill
    ellipse(position.x, position.y, 15, 15);
  }
}
