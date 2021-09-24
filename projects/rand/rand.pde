//import java.util.Random;
//import java.math.BigInteger;
import java.security.SecureRandom;

SecureRandom sr;

String hash = ""; 
String defaultHash = "dsa157+gen.art=awesome" + String.valueOf(System.currentTimeMillis());

void setRandSeed() {
  if (hash == "") {
    hash = defaultHash;
  }
  sr.setSeed(hash.getBytes());
}

public int getRandomInt(int min, int max) {
    max++;
    return (int) ((Math.random() * (max - min)) + min);
}

void setup() {
  try {
  sr = SecureRandom.getInstance("SHA1PRNG");     
  setRandSeed();
  
  for (int i=0; i<5; i++) {
    int x = getRandomInt(0,3);
    print(x, " ");
  }  

  exit();
  }
  catch (Exception e) {
    e.printStackTrace();
  }
}
