import java.util.Map;
import oscP5.*;
import netP5.*;
import ddf.minim.*;
Minim minim;
AudioSample[] player = new AudioSample[1];
AudioSample[] playerDamageSound = new AudioSample[11];
AudioSample[] playerScoreSound = new AudioSample[11];
AudioSample[] playerCollisionSound = new AudioSample[3];
int lastPlayed = -100;
float minimGain = -20.0; //-40.0;

import beads.*;
AudioContext ac;
SamplePlayer[] locFinger = new SamplePlayer[11];

// we can run both SamplePlayers through the same Gain
Gain[] sampleGain = new Gain[11];
Glide[] gainValue = new Glide[11];
Glide[] frequencyGlide = new Glide[11];
float beadsGain = 0.3; // 0.015;

// the object we will be using to handle OSC communication.
OscP5 oscP5;

// a map from finger IDs (integers unique to each continuous finger touch) to a Finger instance
HashMap<Integer, Finger> candidateFingerMapLoc;
HashMap<Integer, Finger> candidateFingerMapOpp;
// the fingers that should be added to the map during the next draw call, detected from OSC messages
ArrayList fingersToAddLoc;
ArrayList fingersToAddOpp;
// the fingers that have been lifted from the surface and should be removed from the mapping after rendering
ArrayList fingersToRemoveLoc;
ArrayList fingersToRemoveOpp;
// the fingers that have been shot
ArrayList fingersToFireLoc;
ArrayList fingersToFireOpp;
// a map from finger IDs (integers unique to each continuous finger touch) to a Finger instance
HashMap<Integer, Finger> firedFingerMapLoc;
HashMap<Integer, Finger> firedFingerMapOpp;

public color colorLoc = #c89b87;
public color colorLocMul = #cf7070;
public color colorOpp = #7d70cf;
public color colorOppMul = #e8e780;
public color colorBac = #1d1d1d;
public color colorAcc = #131311;
public color colorDiv = #565656;
public int opacityBac = 70;
public int opacityMul = 65;
public int healthBarYOffset = 4;
public int strokeFired = 4;
public int strokeLoading = 2;
public int dividerHeight = 20;
/* 
 * Level 0 - One Gap, 400px wide
 * Level 1 - One Gap, 200px wide
 * Level 2 - Two Gap, 200px wide each
 * Level 3 - Three Gap, 100px wide each
 */
public float[][] dividerPos = {{120.0, 520.0}, {220.0, 420.0}, {60.0, 260.0, 380.0, 580.0}, {56.6666, 156.6666, 270.0, 370.0, 483.3333, 583.3333}}; 
public int dividerLevel = 0;
public int dividerLastSwitch = - 100;
public int dividerLevelLength = 30 * 1000; // 30 seconds

public boolean NoDamageMode = false;
public boolean FriendlyFireMode = false;
public boolean MovementMode = false;
public boolean AutoFireMode = false;
public boolean DividerMode = true;
//public boolean ChargeToFireMode = false;
public boolean StrokeMode = false;
public boolean GrowToFireMode = true;
public boolean ColorMultiplyMode = false;
public boolean MirrorMode = false;
public float MirrorModeOffsetX = 0.25;
public float MirrorModeOffsetY = 0.1;
public boolean DebugMode = false;
public boolean GameRecentlyOver = false;
public int GameOverWinner;
public int GameOverLength = 5;
public int GameOverTimer;

public float SpeedOfBlob = 0.004; //0.004; //0.0065;
public float DamageOfBlob = 0.001; //0.003;

// the port that we will be listening for osc signals over
int listenPort = 9109;
// the type tag for the small multitouch messages (no rotation or size)
String shortTypeTag = "iff";
// the type tag for the complete multitouch messages (full rotation and size)
String longTypeTag = "ifffffffiif";
// the number of milliseconds that we wait to remove a finger once we stop receiving messages
int timeToRemove = 20;
int timeToFire = 900;

float innerPolygonCoef[];
float outerPolygonCoef[];
int maxIterations;

int playerChargeMax = 100;
int playerChargeLoc = 100, playerChargeOpp = 100;

int playerHealthMax = 100;
int playerHealthLoc = 100, playerHealthOpp = 100;
int playerScoreLoc = 0, playerScoreOpp = 0;
float playerHealthHeightLoc = 70.0, playerHealthHeightOpp = 70.0;

void setup() {
  size(640, 980);
  colorMode(RGB, 255, 255, 255, 100);
  frameRate(30);
  strokeWeight(2.0);
  noCursor();
  
  minim = new Minim(this); // initialaizing minim object
  player[0] = minim.loadSample("Drum_Loop_Short.mp3", 2048);
  playerCollisionSound[0] = minim.loadSample("Collision_Sound_Loss.mp3", 2048);
  playerCollisionSound[1] = minim.loadSample("Collision_Sound_Tie.mp3", 2048);
  playerCollisionSound[2] = minim.loadSample("Collision_Sound_Win_2.mp3", 2048);
  
  ac = new AudioContext(); // create our AudioContext
  
  for (int i = 0; i < locFinger.length; i++) {
    try {  
      if ((i == 0) || (i == 5))
        locFinger[i] = new SamplePlayer(ac, new Sample(sketchPath("") + "data/Charging_Sound_6.mp3"));
      else if ((i == 1) || (i == 6))
        locFinger[i] = new SamplePlayer(ac, new Sample(sketchPath("") + "data/Charging_Sound_Opt_3.mp3"));
      else if ((i == 2) || (i == 7))
        locFinger[i] = new SamplePlayer(ac, new Sample(sketchPath("") + "data/Charging_Sound_Opt_4.mp3"));
      else if ((i == 3) || (i == 8) || (i == 10))
        locFinger[i] = new SamplePlayer(ac, new Sample(sketchPath("") + "data/Charging_Sound_Opt_5.mp3"));
      else
        locFinger[i] = new SamplePlayer(ac, new Sample(sketchPath("") + "data/Charging_Sound_Opt_2_3.mp3"));
        
      if ((i == 0) || (i == 3) || (i == 6) || (i == 9)) {
        playerScoreSound[i] = minim.loadSample("Score_Sound_2.mp3", 2048);
        playerDamageSound[i] = minim.loadSample("Damage_Sound_2.mp3", 2048);
      }
      else if ((i == 1) || (i == 4) || (i == 7) || (i == 10)) {
        playerScoreSound[i] = minim.loadSample("Score_Sound_Opt_2.mp3", 2048);
        playerDamageSound[i] = minim.loadSample("Damage_Sound_Opt_2.mp3", 2048);
      }
      else {
        playerScoreSound[i] = minim.loadSample("Score_Sound_Opt_3.mp3", 2048);
        playerDamageSound[i] = minim.loadSample("Damage_Sound_Opt_3.mp3", 2048);
      }
      
      playerDamageSound[i].setGain(minimGain);
      playerScoreSound[i].setGain(minimGain);
    }
    catch(Exception e)
    {
      // if there is an error, show an error message (at the bottom of the processing window)
      println("Exception while attempting to load sample!");
      e.printStackTrace(); // then print a technical description of the error
    }
    
    // note that we want to play the sample multiple times
    locFinger[i].setKillOnEnd(false);
    
    frequencyGlide[i] = new Glide(ac, 1);
    frequencyGlide[i].setGlideTime(20);
    
    locFinger[i].setPitch(frequencyGlide[i]);
    
    gainValue[i] = new Glide(ac, 0.0, 30);
    sampleGain[i] = new Gain(ac, 1, gainValue[i]);
    sampleGain[i].addInput(locFinger[i]);
    ac.out.addInput(sampleGain[i]);
    
   // locFinger[i] = minim.loadSample("Charging_Sound.mp3", 2048);
   // locFinger[i].setGain(-40.0);
  }
  
  ac.start(); // begin audio processing

  // create a new instance of oscP5 to listen to incoming osc messages
  oscP5 = new OscP5(this, listenPort);

  resetGame();

   //player[0].setGain(-30.0);
   player[0].setGain(minimGain);
   playerCollisionSound[0].setGain(minimGain);
   playerCollisionSound[1].setGain(minimGain);
   playerCollisionSound[2].setGain(minimGain);
  
 // player[0].loop();
}

void resetGame() {
  // initialize the data structures to keep track of fingers
  candidateFingerMapLoc = new HashMap<Integer, Finger>();
  candidateFingerMapOpp = new HashMap<Integer, Finger>();

  firedFingerMapLoc = new HashMap<Integer, Finger>();
  firedFingerMapOpp = new HashMap<Integer, Finger>();

  fingersToAddLoc = new ArrayList();
  fingersToAddOpp = new ArrayList();

  fingersToRemoveLoc = new ArrayList();
  fingersToRemoveOpp = new ArrayList();

  fingersToFireLoc = new ArrayList();
  fingersToFireOpp = new ArrayList();

  playerHealthLoc = playerHealthMax;
  playerHealthOpp = playerHealthMax;
  
  playerChargeLoc = playerChargeMax;
  playerChargeOpp = playerChargeMax;
}


void draw() {
  if(player[0].length() + lastPlayed - 120 <= millis()) {
    player[0].trigger();
    lastPlayed = millis();
  }
  
  if(dividerLevelLength + dividerLastSwitch <= millis()) {
    dividerLevel = (dividerLevel + 1) % dividerPos.length;
    dividerLastSwitch = millis();
  }
  
  println(dividerLevel);
  
  if (playerHealthLoc <= 0) {
    playerScoreOpp++;
    resetGame();
    GameRecentlyOver = true;
    GameOverWinner = 1;
    GameOverTimer = GameOverLength;
  }
  else if (playerHealthOpp <= 0) {
    playerScoreLoc++;
    resetGame();
    GameRecentlyOver = true;
    GameOverWinner = 0;
    GameOverTimer = GameOverLength;
  }

  if (GameRecentlyOver) {
    GameOverTimer--;

    if (GameOverTimer <= 0)
      GameRecentlyOver = false;
  }

  noStroke();
  if (GameRecentlyOver) {
    if (GameOverWinner == 1)
      fill(colorOpp, opacityBac-40);
    else
      fill(colorLoc, opacityBac-40);
  }
  else
    fill(colorBac, opacityBac);
  rect(0.0, 0.0, width, height);

  stroke(colorAcc, opacityBac);
  fill(colorAcc, opacityBac);
  strokeWeight(4);
  
  if (!DividerMode)
    line(0.0, height/2, width, height/2);
  
  strokeCap(SQUARE);
  stroke(colorDiv, opacityBac);
  fill(colorDiv, opacityBac);
  strokeWeight(dividerHeight/2);
  
  if (DividerMode) {
    if ((dividerLevel == 0) || (dividerLevel == 1)) {
      line(0.0, height/2, dividerPos[dividerLevel][0], height/2);
      line(dividerPos[dividerLevel][1], height/2, width, height/2);
    }
    
    else if (dividerLevel == 2) {
      line(0.0, height/2, dividerPos[dividerLevel][0], height/2);
      line(dividerPos[dividerLevel][1], height/2, dividerPos[dividerLevel][2], height/2);
      line(dividerPos[dividerLevel][3], height/2, width, height/2);
    }
    
    else if (dividerLevel == 3) {
      line(0.0, height/2, dividerPos[dividerLevel][0], height/2);
      line(dividerPos[dividerLevel][1], height/2, dividerPos[dividerLevel][2], height/2);
      line(dividerPos[dividerLevel][3], height/2, dividerPos[dividerLevel][4], height/2);
      line(dividerPos[dividerLevel][5], height/2, width, height/2);
    }
  }

  stroke(colorOpp); // (109, 148, 167);
  fill(colorOpp);
  //strokeWeight(4);
  //rect(0.0, 0.0, (float)width, playerHealthHeightLoc);

  strokeWeight(3);
  int numLines = (playerHealthOpp/(playerHealthMax/10)) + 1;
  float residual = (playerHealthOpp - numLines * (playerHealthMax/10.0));
  for (int i = 0; i < numLines - 1; i++)
    line(0.0, healthBarYOffset + i * 7, (float) width, healthBarYOffset + i * 7);
  stroke(colorOpp, residual * 10);
  fill(colorOpp, residual * 10);
  line(0.0, healthBarYOffset + (numLines - 1) * 7, (float) width, healthBarYOffset + (numLines - 1) * 7);
  playerHealthHeightOpp = 3 + healthBarYOffset + (numLines - 1) * 7;

  //println("Health: " + playerHealthOpp + " ;;; Num Lines: " + numLines + " ;;; Resid: " + residual);
  //println("health line: " + playerHealthHeightOpp);

  stroke(colorLoc);
  fill(colorLoc);
  //strokeWeight(4);
  //rect(0.0, height - playerHealthHeightOpp, (float)width, playerHealthHeightOpp);

  strokeWeight(3);
  numLines = (playerHealthLoc/(playerHealthMax/10)) + 1;
  residual = (playerHealthLoc - numLines * (playerHealthMax/10.0));
  for (int i = 0; i < numLines - 1; i++) 
    line(0.0, height - healthBarYOffset - i * 7, (float) width, height - healthBarYOffset - i * 7);
  stroke(colorLoc, residual * 10);
  fill(colorLoc, residual * 10);
  line(0.0, height - healthBarYOffset - (numLines - 1) * 7, (float) width, height - healthBarYOffset - (numLines - 1) * 7);
  playerHealthHeightLoc = 3 + healthBarYOffset + (numLines - 1) * 7;

  if (DebugMode) {
    color(0.8);
    text("Fingers0: " + candidateFingerMapLoc.size(), 10, 20);
    text("Fingers1: " + candidateFingerMapOpp.size(), 10, 20);
    text("Health0: " + playerHealthLoc, 10, 40);
    text("Health1: " + playerHealthOpp, 10, 60);
    text("Score0 : " + playerScoreLoc, 10, 80);
    text("Score1 : " + playerScoreOpp, 10, 100);
  }


  int curTime = millis();

  // ========================================================
  // ========================================================
  // ========================================================

  // add any new fingers we got from the OSC messages
  for (int i = 0; i < fingersToAddLoc.size(); i++)
  {
    Finger fingerToAdd = (Finger)fingersToAddLoc.get(i);
    candidateFingerMapLoc.put(fingerToAdd.id, fingerToAdd);
  }
  fingersToAddLoc.clear();

  // ========================================================

  // add any new fingers we got from the OSC messages
  for (int i = 0; i < fingersToAddOpp.size(); i++)
  {
    Finger fingerToAdd = (Finger)fingersToAddOpp.get(i);
    candidateFingerMapOpp.put(fingerToAdd.id, fingerToAdd);
  }
  fingersToAddOpp.clear();

  // ========================================================
  // ========================================================
  // ========================================================

  // iterate through existing fingers and render them
  for (Map.Entry me : candidateFingerMapLoc.entrySet())
  {
    Finger finger = (Finger)me.getValue();
    
    if (curTime - finger.milliFirstTouched > timeToFire)
        {
          int fingerId = - 1;
          Finger fingerF;

          do {
            fingerId++;
            fingerF = (Finger)firedFingerMapLoc.get(fingerId);
          }
          while (fingerF != null);

        gainValue[finger.id].setValue(0.0);
        locFinger[finger.id].reset();
      }

    if (AutoFireMode) {
      // if we haven't heard from this finger in a while,
      // it must have been lifted, so remove it
      if (curTime - finger.milliLastTouched > timeToRemove)
      {
        fingersToRemoveLoc.add(finger.id);
      }

      if (curTime - finger.milliFirstTouched > timeToFire)
      {
        int fingerId = - 1;
        Finger fingerF;

        do {
          fingerId++;
          fingerF = (Finger)firedFingerMapLoc.get(fingerId);
        }
        while (fingerF != null);

        finger.idFired = fingerId;
        fingersToFireLoc.add(fingerId);
        firedFingerMapLoc.put(fingerId, finger);

        if (DebugMode) {
          println("LFIRE: " + fingerId);
          println("LAREA: " + finger.getArea());
        }
        fingersToRemoveLoc.add(finger.id);
      }
    }
    else {
      if (curTime - finger.milliLastTouched > timeToRemove)
      {

        if (curTime - finger.milliFirstTouched > timeToFire)
        {
          int fingerId = - 1;
          Finger fingerF;

          do {
            fingerId++;
            fingerF = (Finger)firedFingerMapLoc.get(fingerId);
          }
          while (fingerF != null);

          finger.idFired = fingerId;
          fingersToFireLoc.add(fingerId);
          firedFingerMapLoc.put(fingerId, finger);
          
          //player[2].trigger();

          if (DebugMode) {
            println("LFIRE: " + fingerId);
            println("LAREA: " + finger.getArea());
          }
        }
        else {
          gainValue[finger.id].setValue(0.0);
          locFinger[finger.id].reset();
        }  
        
        
        //locFinger[finger.id].setPosition(000);
        //locFinger[finger.id].stop();
        //gainValue[finger.id].setValue(0.0);
        //locFinger[finger.id].reset();
        
        fingersToRemoveLoc.add(finger.id);
      }
    }

    if (curTime - finger.milliFirstTouched > 900)
      finger.render((float)width, (float)height, 99);
    else {
      float percFired = map((curTime - finger.milliFirstTouched), 0, 900, 0, 99);
      finger.render((float)width, (float)height, percFired);
    }
  }

  // ========================================================

  // iterate through existing fingers and render them
  for (Map.Entry me : candidateFingerMapOpp.entrySet())
  {
    Finger finger = (Finger)me.getValue();

    if (AutoFireMode) {
      // if we haven't heard from this finger in a while,
      // it must have been lifted, so remove it
      if (curTime - finger.milliLastTouched > timeToRemove)
      {
        fingersToRemoveOpp.add(finger.id);
      }

      if (curTime - finger.milliFirstTouched > timeToFire)
      {
        int fingerId = - 1;
        Finger fingerF;

        do {
          fingerId++;
          fingerF = (Finger)firedFingerMapOpp.get(fingerId);
        }
        while (fingerF != null);

        finger.idFired = fingerId;
        fingersToFireOpp.add(fingerId);
        firedFingerMapOpp.put(fingerId, finger);

        if (DebugMode) {
          println("FIRE: " + fingerId);
          println("AREA: " + finger.getArea());
        }
        fingersToRemoveOpp.add(finger.id);
      }
    }
    else {
      if (curTime - finger.milliLastTouched > timeToRemove)
      {

        if (curTime - finger.milliFirstTouched > timeToFire)
        {
          int fingerId = - 1;
          Finger fingerF;

          do {
            fingerId++;
            fingerF = (Finger)firedFingerMapOpp.get(fingerId);
          }
          while (fingerF != null);

          finger.idFired = fingerId;
          fingersToFireOpp.add(fingerId);
          firedFingerMapOpp.put(fingerId, finger);

          if (DebugMode) {
            println("FIRE: " + fingerId);
            println("AREA: " + finger.getArea());
          }
        }
        fingersToRemoveOpp.add(finger.id);
      }
    }

    if (curTime - finger.milliFirstTouched > 900)
      finger.render((float)width, (float)height, 99);
    else {
      float percFired = map((curTime - finger.milliFirstTouched), 0, 900, 0, 99);
      finger.render((float)width, (float)height, percFired);
    }
  }

  // ========================================================
  // ========================================================
  // ========================================================

  // remove all the fingers that were lifted
  for (int j = 0; j < fingersToRemoveLoc.size(); j++)
  {
    Integer idToRemove = (Integer)fingersToRemoveLoc.get(j);
    candidateFingerMapLoc.remove(idToRemove);
  }
  fingersToRemoveLoc.clear();

  // ========================================================

  // remove all the fingers that were lifted
  for (int j = 0; j < fingersToRemoveOpp.size(); j++)
  {
    Integer idToRemove = (Integer)fingersToRemoveOpp.get(j);
    candidateFingerMapOpp.remove(idToRemove);
  }
  fingersToRemoveOpp.clear();

  // ========================================================
  // ========================================================
  // ========================================================

  HashMap<Integer, Finger> firedFingerMapNew = (HashMap<Integer, Finger>)firedFingerMapOpp.clone();

  // iterate through fired fingers and render them
  for (Map.Entry me1 : firedFingerMapLoc.entrySet())
  {
    Finger finger1 = (Finger)me1.getValue();

    if ((finger1.getAbsX() - finger1.getMajorAxis())  < 0)
      finger1.switchXDirection();
    else if (((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMajorAxis()) > width) 
      || ((finger1.getAbsX() + cos(radians(finger1.angle + 180)) * finger1.getMajorAxis()) > width)) {
      finger1.switchXDirection();
    }

    //if ((finger1.getAbsY() - 8 - sin(radians(finger1.angle)) * finger1.getMinorAxis())  < playerHealthHeightOpp)  {
    if ((finger1.getAbsY() - (strokeFired * 2) - sin(radians(finger1.angle)) * finger1.getMajorAxis())  < playerHealthHeightOpp) {
      if (finger1.playerId == 0) {
        //println("abs y: " + finger1.getAbsY() + " ;;; calc y: " + (finger1.getAbsY() - 8 - sin(radians(finger1.angle)) * finger1.getMinorAxis()));
        //println("health line: " + playerHealthHeightOpp);
        playerHealthOpp -= finger1.getArea() * DamageOfBlob;
        fingersToRemoveLoc.add(finger1.idFired);
        playerScoreSound[finger1.id].trigger();
      }
      else 
        finger1.switchYDirection();
    }
    else if ((finger1.getAbsY() - finger1.getMinorAxis()) > height - playerHealthHeightLoc) {
      finger1.switchYDirection();
    }
    
    if (DividerMode) {
      int collided = 1;
      
      if ((dividerLevel == 0) || (dividerLevel == 1)) {
        if (((finger1.getAbsY() + 8 - sin(radians(finger1.angle)) * finger1.getMajorAxis()) >= height/2 - dividerHeight/2) && ((finger1.getAbsY() - sin(radians(finger1.angle)) * finger1.getMajorAxis()) <= height/2)) {
          if (((finger1.getAbsX() - finger1.getMajorAxis()) >= 0.0) && ((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMajorAxis()) <= dividerPos[dividerLevel][0]))
            fingersToRemoveLoc.add(finger1.idFired);
          else if (((finger1.getAbsX() - finger1.getMajorAxis()) <= width) && ((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMajorAxis()) >= dividerPos[dividerLevel][1]))
            fingersToRemoveLoc.add(finger1.idFired);
          else
            collided = 0;
            
          if (collided == 1)
            playerCollisionSound[0].trigger();
        }
      }
      
      else if (dividerLevel == 2) {
        if (((finger1.getAbsY() + 8 - sin(radians(finger1.angle)) * finger1.getMajorAxis()) >= height/2 - dividerHeight/2) && ((finger1.getAbsY() - sin(radians(finger1.angle)) * finger1.getMajorAxis()) <= height/2)) {
          if (((finger1.getAbsX() - finger1.getMajorAxis()) >= 0.0) && ((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMajorAxis()) <= dividerPos[dividerLevel][0]))
            fingersToRemoveLoc.add(finger1.idFired);
          else if (((finger1.getAbsX() - finger1.getMajorAxis()) <= dividerPos[dividerLevel][2]) && ((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMajorAxis()) >= dividerPos[dividerLevel][1]))
            fingersToRemoveLoc.add(finger1.idFired);
          else if (((finger1.getAbsX() - finger1.getMajorAxis()) <= width) && ((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMajorAxis()) >= dividerPos[dividerLevel][3]))
            fingersToRemoveLoc.add(finger1.idFired);
          else
            collided = 0;
            
          if (collided == 1)
            playerCollisionSound[0].trigger();
        }
      }
      
      else if (dividerLevel == 3) {
        if (((finger1.getAbsY() + 8 - sin(radians(finger1.angle)) * finger1.getMajorAxis()) >= height/2 - dividerHeight/2) && ((finger1.getAbsY() - sin(radians(finger1.angle)) * finger1.getMajorAxis()) <= height/2)) {
          if (((finger1.getAbsX() - finger1.getMajorAxis()) >= 0.0) && ((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMajorAxis()) <= dividerPos[dividerLevel][0]))
            fingersToRemoveLoc.add(finger1.idFired);
          else if (((finger1.getAbsX() - finger1.getMajorAxis()) <= dividerPos[dividerLevel][2]) && ((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMajorAxis()) >= dividerPos[dividerLevel][1]))
            fingersToRemoveLoc.add(finger1.idFired);
          else if (((finger1.getAbsX() - finger1.getMajorAxis()) <= dividerPos[dividerLevel][4]) && ((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMajorAxis()) >= dividerPos[dividerLevel][3]))
            fingersToRemoveLoc.add(finger1.idFired);
          else if (((finger1.getAbsX() - finger1.getMajorAxis()) <= width) && ((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMajorAxis()) >= dividerPos[dividerLevel][5]))
            fingersToRemoveLoc.add(finger1.idFired);
          else
            collided = 0;
            
          if (collided == 1)
            playerCollisionSound[0].trigger();
        }
      }
    }

    if (!NoDamageMode) {
      for (Map.Entry me2 : firedFingerMapNew.entrySet())
      {
        Finger finger2 = (Finger)me2.getValue();

        if (finger1 != finger2) {
          // draw an arrow for its direction
          if (collide(finger1.getAbsX(), finger1.getAbsY(), finger1.getMajorAxis() + (strokeFired * 0), finger1.getMinorAxis() + (strokeFired * 0), 
          finger2.getAbsX(), finger2.getAbsY(), finger2.getMajorAxis() + (strokeFired * 0), finger2.getMinorAxis() + (strokeFired * 0))) {
            if (finger1.getArea() == finger2.getArea()) {
              fingersToRemoveLoc.add(finger1.idFired);
              fingersToRemoveOpp.add(finger2.idFired);
            }
            else if (finger1.getArea() > finger2.getArea()) {
              fingersToRemoveOpp.add(finger2.idFired);
              finger1.shrinkArea(finger2.minorAxis, finger2.majorAxis);
            }
            else {
              fingersToRemoveLoc.add(finger1.idFired);
              finger2.shrinkArea(finger1.minorAxis, finger1.majorAxis);
            }
          }
        }
      }
    }

    finger1.advance();
    finger1.render((float)width, (float)height, 100.0);

    if (DebugMode) {
      strokeWeight(4);
      stroke(255);
      point((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMinorAxis()), finger1.getAbsY());
      stroke(255, 0, 0);
      point((finger1.getAbsX() + cos(radians(finger1.angle + 180)) * finger1.getMajorAxis()), finger1.getAbsY());

      strokeWeight(4);
      stroke(255);
      point(finger1.getAbsX(), (finger1.getAbsY() - finger1.getMinorAxis()));
    }
  }

  // ========================================================

  firedFingerMapNew = (HashMap<Integer, Finger>)firedFingerMapLoc.clone();

  // iterate through fired fingers and render them
  for (Map.Entry me1 : firedFingerMapOpp.entrySet())
  {
    Finger finger1 = (Finger)me1.getValue();

    if ((finger1.getAbsX() - finger1.getMajorAxis())  < 0)
      finger1.switchXDirection();
    else if (((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMajorAxis()) > width) 
      || ((finger1.getAbsX() + cos(radians(finger1.angle + 180)) * finger1.getMajorAxis()) > width)) 
      finger1.switchXDirection();


    if ((finger1.getAbsY() + 8 + sin(radians(finger1.angle)) * finger1.getMinorAxis()) > height - playerHealthHeightLoc) {
      playerHealthLoc -= finger1.getArea() * DamageOfBlob;
      playerDamageSound[finger1.id].trigger();
      fingersToRemoveOpp.add(finger1.idFired);
    }
    else if ((finger1.getAbsY() - finger1.getMinorAxis()) < playerHealthHeightOpp) {
      finger1.switchYDirection();
    }
    
    if (DividerMode) {
      if ((dividerLevel == 0) || (dividerLevel == 1)) {
        if (((finger1.getAbsY() - 8 + sin(radians(finger1.angle)) * finger1.getMajorAxis()) >= height/2 - dividerHeight) && ((finger1.getAbsY() + sin(radians(finger1.angle)) * finger1.getMajorAxis()) <= height/2)) {
          if (((finger1.getAbsX() - finger1.getMajorAxis()) >= 0.0) && ((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMajorAxis()) <= dividerPos[dividerLevel][0]))
            fingersToRemoveOpp.add(finger1.idFired);
          if (((finger1.getAbsX() - finger1.getMajorAxis()) <= width) && ((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMajorAxis()) >= dividerPos[dividerLevel][1]))
            fingersToRemoveOpp.add(finger1.idFired);
        }
      }
      
      else if (dividerLevel == 2) {
        if (((finger1.getAbsY() - 8 + sin(radians(finger1.angle)) * finger1.getMajorAxis()) >= height/2 - dividerHeight) && ((finger1.getAbsY() + sin(radians(finger1.angle)) * finger1.getMajorAxis()) <= height/2)) {
          if (((finger1.getAbsX() - finger1.getMajorAxis()) >= 0.0) && ((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMajorAxis()) <= dividerPos[dividerLevel][0]))
            fingersToRemoveOpp.add(finger1.idFired);
          if (((finger1.getAbsX() - finger1.getMajorAxis()) <= dividerPos[dividerLevel][2]) && ((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMajorAxis()) >= dividerPos[dividerLevel][1]))
            fingersToRemoveOpp.add(finger1.idFired);
          if (((finger1.getAbsX() - finger1.getMajorAxis()) <= width) && ((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMajorAxis()) >= dividerPos[dividerLevel][3]))
            fingersToRemoveOpp.add(finger1.idFired);
        }
      }
      
      else if (dividerLevel == 3) {
        if (((finger1.getAbsY() - 8 + sin(radians(finger1.angle)) * finger1.getMajorAxis()) >= height/2 - dividerHeight) && ((finger1.getAbsY() + sin(radians(finger1.angle)) * finger1.getMajorAxis()) <= height/2)) {
          if (((finger1.getAbsX() - finger1.getMajorAxis()) >= 0.0) && ((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMajorAxis()) <= dividerPos[dividerLevel][0]))
            fingersToRemoveOpp.add(finger1.idFired);
          if (((finger1.getAbsX() - finger1.getMajorAxis()) <= dividerPos[dividerLevel][2]) && ((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMajorAxis()) >= dividerPos[dividerLevel][1]))
            fingersToRemoveOpp.add(finger1.idFired);
          if (((finger1.getAbsX() - finger1.getMajorAxis()) <= dividerPos[dividerLevel][4]) && ((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMajorAxis()) >= dividerPos[dividerLevel][3]))
            fingersToRemoveOpp.add(finger1.idFired);
          if (((finger1.getAbsX() - finger1.getMajorAxis()) <= width) && ((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMajorAxis()) >= dividerPos[dividerLevel][5]))
            fingersToRemoveOpp.add(finger1.idFired);
        }
      }
    }

    if (!NoDamageMode) {
      for (Map.Entry me2 : firedFingerMapNew.entrySet())
      {
        Finger finger2 = (Finger)me2.getValue();

        if (finger1 != finger2) {
          // draw an arrow for its direction
          if (collide(finger1.getAbsX(), finger1.getAbsY(), finger1.getMajorAxis() + (strokeFired * 2), finger1.getMinorAxis() + (strokeFired * 2), 
          finger2.getAbsX(), finger2.getAbsY(), finger2.getMajorAxis() + (strokeFired * 0), finger2.getMinorAxis() + (strokeFired * 0))) {
            if (finger1.getArea() == finger2.getArea()) {
              fingersToRemoveOpp.add(finger1.idFired);
              fingersToRemoveLoc.add(finger2.idFired);
              playerCollisionSound[1].trigger();
            }
            else if (finger1.getArea() > finger2.getArea()) {
              fingersToRemoveLoc.add(finger2.idFired);
              finger1.shrinkArea(finger2.minorAxis, finger2.majorAxis);
              playerCollisionSound[0].trigger();
            }
            else {
              fingersToRemoveOpp.add(finger1.idFired);
              finger2.shrinkArea(finger1.minorAxis, finger1.majorAxis);
              playerCollisionSound[2].trigger();
            }
          }
        }
      }
    }

    finger1.advance();
    finger1.render((float)width, (float)height, 100.0);

    if (DebugMode) {
      strokeWeight(4);
      stroke(255);
      point((finger1.getAbsX() + cos(radians(-finger1.angle)) * finger1.getMinorAxis()), finger1.getAbsY());
      stroke(255, 0, 0);
      point((finger1.getAbsX() + cos(radians(finger1.angle + 180)) * finger1.getMajorAxis()), finger1.getAbsY());
    }
  }

  // ========================================================

  if (FriendlyFireMode && !NoDamageMode) {

    firedFingerMapNew = (HashMap<Integer, Finger>)firedFingerMapLoc.clone();

    // iterate through fired fingers and render them
    for (Map.Entry me1 : firedFingerMapLoc.entrySet())
    {
      Finger finger1 = (Finger)me1.getValue();
      firedFingerMapNew.remove(finger1.idFired);

      for (Map.Entry me2 : firedFingerMapNew.entrySet())
      {
        Finger finger2 = (Finger)me2.getValue();

        if (finger1 != finger2) {
          // draw an arrow for its direction
          if (collide(finger1.getAbsX(), finger1.getAbsY(), finger1.getMajorAxis() + (strokeFired * 2), finger1.getMinorAxis() + (strokeFired * 2), 
          finger2.getAbsX(), finger2.getAbsY(), finger2.getMajorAxis() + (strokeFired * 2), finger2.getMinorAxis() + (strokeFired * 2))) {
            if (finger1.getArea() == finger2.getArea()) {
              fingersToRemoveLoc.add(finger1.idFired);
              fingersToRemoveLoc.add(finger2.idFired);
              playerCollisionSound[1].trigger();
            }
            else if (finger1.getArea() > finger2.getArea()) {
              fingersToRemoveLoc.add(finger2.idFired);
              finger1.shrinkArea(finger2.minorAxis, finger2.majorAxis);
              playerCollisionSound[0].trigger();
            }
            else {
              fingersToRemoveLoc.add(finger1.idFired);
              finger2.shrinkArea(finger1.minorAxis, finger1.majorAxis);
              playerCollisionSound[0].trigger();
            }
          }
        }
      }
    }

    firedFingerMapNew = (HashMap<Integer, Finger>)firedFingerMapOpp.clone();

    // iterate through fired fingers and render them
    for (Map.Entry me1 : firedFingerMapOpp.entrySet())
    {
      Finger finger1 = (Finger)me1.getValue();
      firedFingerMapNew.remove(finger1.idFired);

      for (Map.Entry me2 : firedFingerMapNew.entrySet())
      {
        Finger finger2 = (Finger)me2.getValue();

        if (finger1 != finger2) {
          // draw an arrow for its direction
          if (collide(finger1.getAbsX(), finger1.getAbsY(), finger1.getMajorAxis() + (strokeFired * 2), finger1.getMinorAxis() + (strokeFired * 2), 
          finger2.getAbsX(), finger2.getAbsY(), finger2.getMajorAxis() + (strokeFired * 2), finger2.getMinorAxis() + (strokeFired * 2))) {
            if (finger1.getArea() == finger2.getArea()) {
              fingersToRemoveOpp.add(finger1.idFired);
              fingersToRemoveOpp.add(finger2.idFired);
            }
            else if (finger1.getArea() > finger2.getArea()) {
              fingersToRemoveOpp.add(finger2.idFired);
              finger1.shrinkArea(finger2.minorAxis, finger2.majorAxis);
            }
            else {
              fingersToRemoveOpp.add(finger1.idFired);
              finger2.shrinkArea(finger1.minorAxis, finger1.majorAxis);
            }
          }
        }
      }
    }
  }

  // ========================================================
  // ========================================================
  // ========================================================

  // remove all the fingers that were lifted
  for (int j = 0; j < fingersToRemoveLoc.size(); j++)
  {
    Integer idToRemove = (Integer)fingersToRemoveLoc.get(j);
    firedFingerMapLoc.remove(idToRemove);
  }
  fingersToRemoveLoc.clear();

  // ========================================================

  // remove all the fingers that were lifted
  for (int j = 0; j < fingersToRemoveOpp.size(); j++)
  {
    Integer idToRemove = (Integer)fingersToRemoveOpp.get(j);
    firedFingerMapOpp.remove(idToRemove);
  }
  fingersToRemoveOpp.clear();

  /*
  strokeWeight(0);
   stroke(255);
   fill(255);
   
   float x1 = 100.0, y1 = 100.0, w1 = 100.0, h1 = 200.0;
   float x2 = 192.0, y2 = 243.0, w2 = 200.0, h2 = 150.0;
   
   if (collide(x1, y1, w1/2, h1/2, x2, y2, w2/2, h2/2)) {
   stroke(255,0,0);
   fill(255,0,0);
   }
   
   ellipse(x1, y1, w1, h1);
   ellipse(x2, y2, w2, h2);
   */
}


// incoming osc message are forwarded to the oscEvent method.
void oscEvent(OscMessage oscMsg) {

  //println(oscMsg.toString());

  String addr = oscMsg.addrPattern();
  String typeTag = oscMsg.typetag();

  if (!addr.equals("/finger") || (!typeTag.equals(shortTypeTag) && !typeTag.equals(longTypeTag)))
  {
    return;
  }

  Integer fingerId = oscMsg.get(0).intValue();
  float posX = oscMsg.get(1).floatValue();
  float posY = oscMsg.get(2).floatValue();
  float posY2 = oscMsg.get(2).floatValue();
  Integer playerId = 0;

  if (!oscMsg.toString().substring(0, 10).equals("/127.0.0.1"))
    playerId = 1;

  if (playerId == 0) {
    if (height - (posY * height) < height * .55)
      posY = 0.45;

    if (height - (posY * height) > height - 95.0)
      posY = 95.0/height;
  }
  else {
    if (height - (posY * height) < height * .45)
      posY = 0.55;

    if (height - (posY * height) > height - 95.0)
      posY = 95.0/height;

    posY = (Math.abs(height - (posY * height)))/height;
  }

  if (MirrorMode) {
    if (height - (posY2 * height) < height * .45)
      posY2 = 0.55;

    if (height - (posY2 * height) > height - 95.0)
      posY2 = 95.0/height;

    posY2 = (Math.abs(height - (posY2 * height)))/height;
  }

  float velX = 0.0;
  float velY = 0.0;
  float angle = 0.0;
  float majorAxis = 20.0;
  float minorAxis = 20.0;
  Integer frame = 0;
  Integer state = 0;
  float size = 0.0;
  int time = millis();

  if (typeTag.equals(longTypeTag))
  {
    velX = oscMsg.get(3).floatValue();
    velY = oscMsg.get(4).floatValue();
    angle = oscMsg.get(5).floatValue();
    majorAxis = oscMsg.get(6).floatValue();
    minorAxis = oscMsg.get(7).floatValue();
    frame = oscMsg.get(8).intValue();
    state = oscMsg.get(9).intValue();
    size = oscMsg.get(10).floatValue();
  }
  
  if (DebugMode)
    println("CirclePerc: " + majorAxis/minorAxis);

  Finger finger = null, finger2 = null;

  if (playerId == 0)
    finger  = (Finger)candidateFingerMapLoc.get(fingerId);
  else if (playerId == 1)
    finger  = (Finger)candidateFingerMapOpp.get(fingerId);

  if (MirrorMode) {
    finger2  = (Finger)candidateFingerMapOpp.get(fingerId);
  }

  boolean firstContact = false;
  // finger doesn't exist yet, so create it
  if (finger == null)
  {
    firstContact = true;
    finger = new Finger(fingerId, time, playerId);
    if (playerId == 0) {
      fingersToAddLoc.add(finger);
      //locFinger[fingerId].trigger();
      gainValue[fingerId].setValue(beadsGain); // (0.03); //(0.05);
      locFinger[fingerId].setPosition(000);
      locFinger[fingerId].start();
    }
    else if (playerId == 1)
      fingersToAddOpp.add(finger);

    if (MirrorMode) {
      finger2 = new Finger(fingerId, time, 1);
      fingersToAddOpp.add(finger2);
    }
  }
  
  int curTime = millis();
  float percFired = map((curTime - finger.milliFirstTouched), 0, 900, 0, 99);
  
  if (DebugMode)
    println(5000.0 - finger.getArea());
  
  finger.update(posX, posY, velX, velY, angle, majorAxis, minorAxis, time, percFired);
  
  if (firstContact)
    finger.setFirstContactArea();
  
  frequencyGlide[fingerId].setValue(map((6500.0 - finger.getArea()), 0.0, 6500.0, 0.5, 2.3));
  // frequencyGlide[fingerId].setValue(map((5000.0 - finger.getArea()), 0.0, 5000.0, 0.5, 2.3));
  //~~ frequencyGlide[fingerId].setValue(map((3000.0 - finger.getArea()), 1200.0, 3000.0, 0.0001, 0.001));
  //~~ frequencyGlide[fingerId].setValue(map((0.1/min(.00001, finger.getArea())), 0.0, 1.0, 0.0001, 0.001)*0.1);
  
  if (MirrorMode) 
    finger2.update(posX, posY2, velX, velY, angle, majorAxis, minorAxis, time, percFired);
}


// Test for collision between an ellipse of horizontal radius w0 and vertical radius h0 at (x0, y0) and
// an ellipse of horizontal radius w1 and vertical radius h1 at (x1, y1)
public boolean collide(float x0, float y0, float w0, float h0, float x1, float y1, float w1, float h1) {

  setUpCollisionTest(100);

  float x = Math.abs(x1 - x0)*h1;
  float y = Math.abs(y1 - y0)*w1;
  w0 *= h1;
  h0 *= w1;
  float r = w1*h1;

  if (x*x + (h0 - y)*(h0 - y) <= r*r || (w0 - x)*(w0 - x) + y*y <= r*r || x*h0 + y*w0 <= w0*h0
    || ((x*h0 + y*w0 - w0*h0)*(x*h0 + y*w0 - w0*h0) <= r*r*(w0*w0 + h0*h0) && x*w0 - y*h0 >= -h0*h0 && x*w0 - y*h0 <= w0*w0)) {
    return true;
  } 
  else {
    if ((x-w0)*(x-w0) + (y-h0)*(y-h0) <= r*r || (x <= w0 && y - r <= h0) || (y <= h0 && x - r <= w0)) {
      return iterate(x, y, w0, 0, 0, h0, r*r);
    }
    return false;
  }
}

void setUpCollisionTest (int maxIterations) {
  this.maxIterations = maxIterations;
  innerPolygonCoef = new float[maxIterations+1];
  outerPolygonCoef = new float[maxIterations+1];
  for (int t = 0; t <= maxIterations; t++) {
    int numNodes = 4 << t;
    innerPolygonCoef[t] = 0.5/cos(4*acos(0.0)/numNodes);
    outerPolygonCoef[t] = 0.5/(cos(2*acos(0.0)/numNodes)*cos(2*acos(0.0)/numNodes));
  }
}

boolean iterate(float x, float y, float c0x, float c0y, float c2x, float c2y, float rr) {
  for (int t = 1; t <= maxIterations; t++) {
    float c1x = (c0x + c2x)*innerPolygonCoef[t];
    float c1y = (c0y + c2y)*innerPolygonCoef[t];
    float tx = x - c1x;
    float ty = y - c1y;
    if (tx*tx + ty*ty <= rr) {
      return true;
    }
    float t2x = c2x - c1x;
    float t2y = c2y - c1y;
    if (tx*t2x + ty*t2y >= 0 && tx*t2x + ty*t2y <= t2x*t2x + t2y*t2y &&
      (ty*t2x - tx*t2y >= 0 || rr*(t2x*t2x + t2y*t2y) >= (ty*t2x - tx*t2y)*(ty*t2x - tx*t2y))) {
      return true;
    }
    float t0x = c0x - c1x;
    float t0y = c0y - c1y;
    if (tx*t0x + ty*t0y >= 0 && tx*t0x + ty*t0y <= t0x*t0x + t0y*t0y &&
      (ty*t0x - tx*t0y <= 0 || rr*(t0x*t0x + t0y*t0y) >= (ty*t0x - tx*t0y)*(ty*t0x - tx*t0y))) {
      return true;
    }    
    float c3x = (c0x + c1x)*outerPolygonCoef[t];
    float c3y = (c0y + c1y)*outerPolygonCoef[t];
    if ((c3x-x)*(c3x-x) + (c3y-y)*(c3y-y) < rr) {
      c2x = c1x;
      c2y = c1y;
      continue;
    }
    float c4x = c1x - c3x + c1x;
    float c4y = c1y - c3y + c1y;
    if ((c4x-x)*(c4x-x) + (c4y-y)*(c4y-y) < rr) {
      c0x = c1x;
      c0y = c1y;
      continue;
    }
    float t3x = c3x - c1x;
    float t3y = c3y - c1y;
    if (ty*t3x - tx*t3y <= 0 || rr*(t3x*t3x + t3y*t3y) > (ty*t3x - tx*t3y)*(ty*t3x - tx*t3y)) {
      if (tx*t3x + ty*t3y > 0) {
        if (Math.abs(tx*t3x + ty*t3y) <= t3x*t3x + t3y*t3y || (x-c3x)*(c0x-c3x) + (y-c3y)*(c0y-c3y) >= 0) {
          c2x = c1x;
          c2y = c1y;
          continue;
        }
      } 
      else if (-(tx*t3x + ty*t3y) <= t3x*t3x + t3y*t3y || (x-c4x)*(c2x-c4x) + (y-c4y)*(c2y-c4y) >= 0) {
        c0x = c1x;
        c0y = c1y;
        continue;
      }
    }
    return false;
  }
  return false; // Out of iterations so it is unsure if there was a collision. But have to return something.
}

