    /* @pjs pauseOnBlur = "true"; 
     preload = "/static/uploaded_resources/p.6273/searichter.jpg"; */
    
    final static int GRID = 2, NUM = GRID*GRID;
    final PImage[] pieces = new PImage[NUM];
    
    int jigX, jigY;
    boolean isShuffling = true;
        
    void settings() {
      size(1000, 750);
    }
    
    void setup() {
      frameRate(10);
      final PImage img = loadImage("http://dsa157.com/NFT/Davids-Lyre-1-small.png");
    
      jigX = (int) (img.width/GRID);  // (int) is to force integer division for JS!
      jigY = (int) (img.height/GRID);
    
      for ( int i = 0; i != NUM; 
        pieces[i] = img.get((int) (i/GRID) * jigX, i++ % GRID * jigY, jigX, jigY) );
    }
    
    void draw() {
      if (isShuffling) {
        for ( int i = 0; i != NUM; 
        image(pieces[i++], (int) random(GRID)*jigX, (int) random(GRID)*jigY) );
      }
      else {
        for ( int i = 0; i != NUM; 
        image(pieces[i], (int) (i/GRID) * jigX, i++ % GRID * jigY) );
      }
    }
    
    void mousePressed() {
      isShuffling = !isShuffling;
    }
    
    void keyPressed() {
      mousePressed();
    }
