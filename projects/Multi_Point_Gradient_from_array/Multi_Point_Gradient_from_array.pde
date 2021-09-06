color from = color(204, 102, 0);
color to = color(0, 102, 153);
color interA = lerpColor(from, to, .33);
color interB = lerpColor(from, to, .66);
int[] palette0 = {#287994,  #E09B53, #54BEE0, #78DDFF, #945819};

// actual simplified color palettes from Gathering Storm created from https://color.adobe.com/create/image
int[] palette1 = {#2A2859, #44428C, #222140, #8C7D32, #73653C};

int[] palette = {#3E3949, #2A264E, #E4DED3, #958C31, #766C5C, #6C63A1};


int paletteSize = palette.length;
int[] keyFrame = new int[paletteSize];
int click=1;

void setup() {
  size(600,100);
  background(255);
  stroke(255);
  //noStroke();
}

void draw() {
  if (click==1) {
    click=0;
    drawGrad();
  }
}

void mouseClicked() {
  println("---");
  click=1;
}

void lerpColors(int ndx, int prev, color from, color to) {
    int segmentWidth = ndx - prev;
    //println(prev, ndx, " - ", segmentWidth, " - ");
    for (int j=prev; j<ndx; j++) {
      float y = 1.0 - (ndx-j)/(segmentWidth * 1.0);
      color x = lerpColor(from, to, y); 
      //println(y);
      line(j,0,j,height);
      stroke(x);
    }
}

void drawGrad() {
  click = 0;
  int ndx = 0;
  int prev = 0;
  //color x = 0;
  for (int i=0; i<paletteSize-1; i++) {
    prev = ndx;
    if (i == paletteSize-2) {
      ndx = width;
    }
    else {
      ndx = int(random(ndx, width));
    }
    //keyFrame[i]=ndx;
    from = color(palette[i]);
    to=color(palette[i+1]);
    lerpColors(ndx,prev,from,to);
  }
}
