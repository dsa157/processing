float[] grad;

void setup() 
  {
  size(800, 600);
  colorMode(HSB, 360, 100, 100);
  //test();
  drawGrad();
}

void test() {
  //for(int i = 0; i<360; i++) {
  //  stroke(i, 100, 100);  
  //  line(i, 0, i, height/2);      
  //}
  
  for(int i = 0; i<360; i++) {  
    float hue = map(i, 0, 360, 10, 100);
    println(i, int(hue), int(360+hue));   // See what is going on!

    if (hue < 0) {
      hue = 360+hue;  
    }
    
    stroke(hue, 100, 100);  
    line(i, height/2, i, height);      
  }   }


void drawGrad() {
  noStroke();
  int[] colors = {#287994, #78DDFF, #54BEE0, #945819, #E09B53};
  for (int i=0; i<colors.length; i++) {
    rect(100*i, 0, 100, 100);
    fill(color(colors[i]));
  }

}
