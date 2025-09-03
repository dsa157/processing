import java.util.Date; //<>//
import java.text.DateFormat;
import java.text.SimpleDateFormat;

int width=1000;
int height=750;
Challenge challenge = new Challenge();
PImage fill;

void settings() {
  size(width, height);
}

void setup() {
  background(255);
  fill = loadImage("fill.png");
}

void draw() {
  challenge.tl.draw();
}

class Challenge {
  int numPhotos = 4;
  int challengeLength = 24;
  int boostLength = 4;
  int challengeLocked = 18;
  Date startTime = new Date();
  Date endTime = new Date();
  Timeline tl = new Timeline();
}

//-----

class Timeline {

  int startX=100;
  int startY=200;
  int timeLineHeight = 100;
  int iconWidth=20;

  void draw() {
    noStroke();
    fill(200, 200, 255);
    rect(startX, startY, getTimeLineLength(), timeLineHeight);
    drawFreeJoinPeriod();
    drawMileStones();
    drawFills();
  }

  int getTimeLineLength() {
    switch(challenge.challengeLength) {
    case 24:
      return challenge.challengeLength * 30;
    case 48:
      return challenge.challengeLength * 20;
    }
    return 100;
  }

  int getHourSegmentWidth() {
    return (getTimeLineLength() / challenge.challengeLength);
  }

  void drawFreeJoinPeriod() {
    int freeJoinWidth = (challenge.challengeLength - challenge.challengeLocked) * getHourSegmentWidth();
    fill(200, 255, 255);
    rect(startX, startY, freeJoinWidth, timeLineHeight);
  }

  void drawMileStones() {
    int hrWidth = getHourSegmentWidth(); 
    for (int i=0; i<=challenge.challengeLength; i++) {
      fill(0);
      if (i%2 ==0) {
        circle((startX+(hrWidth*i)), startY-20, 5);
      }
      if (i%4 ==0) {
        circle((startX+(hrWidth*i)), startY-20, 5);
      }
    }
  }

  void drawFills() {
    int hrWidth = getHourSegmentWidth(); 
    for (int i=0; i<=challenge.challengeLength; i++) {
      fill(0);
      if (i%4 ==0) {
        image(fill, (startX+(hrWidth*i)-iconWidth/2), startY+timeLineHeight, iconWidth,iconWidth);
      }
    }
  }
}

//-----


//-----


//-----
