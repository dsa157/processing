
int s1 = 20;
int s2 = 40;
int counter=1;
int loop=10;
int sk=0;
int multiplier = 1;
int i=5;
int j=5;

void setup() {
  size(500, 500);
}

void draw() {
  
  if (sk > 254) {
    multiplier = -1;
  }
  if (sk < 1) {
    multiplier = 1;
  }
  sk = sk + (1 * multiplier);

  stroke(sk);
  fill(sk);
  rect(s2*i, s2*j, s2, s2);
  translate(s2, s2);
  rotate(radians(counter++));
  translate(-s2, -s2);
  //frameRate(1);
  //print(sk,  " ");
}