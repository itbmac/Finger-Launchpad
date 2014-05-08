class Finger
{
  public int id;
  public int idFired;
  public int playerId;
  public int dirX = 1, dirY = 1;
  public PVector pos;
  public PVector offset;
  public PVector vel;
  public float angle;
  public float majorAxis;
  public float minorAxis;
  public float majorAxisLastTouched;
  public float minorAxisLastTouched;
  public int milliLastTouched;
  public int milliFirstTouched;

  int maxOpacity = 100;
  int wallDelayMax = 30;
  int wallDelay;
  float innerPolygonCoef[];
  float outerPolygonCoef[];
  int maxIterations;

  public static final float fingerScale = 0.007;
  public static final float arrowDistScale = 7;

  public Finger(int id, int time, int pId)
  {
    this.id = id;
    this.idFired = id;
    this.playerId = pId;
    this.milliLastTouched = time;
    this.milliFirstTouched = time;

    this.pos = new PVector(0.5, 0.5);
    this.offset = new PVector(random(-1.0 * MirrorModeOffsetX, MirrorModeOffsetX), random(-1.0 * MirrorModeOffsetY, MirrorModeOffsetY));
    this.vel = new PVector(0.5, 0.5);
    this.angle = 0.0;
    this.majorAxis = 0.0;
    this.minorAxis = 0.0;
    dirX = 1;
    dirY = 1;

    if (ColorMultiplyMode) {
      maxOpacity = opacityMul;
      colorLocMul = colorLocMul;
      colorOpp = colorOppMul;
    }
  }

  public void update(float posX, float posY, float velX, float velY, 
  float angle, float majorAxis, float minorAxis, int time, float percToFire)
  {
    this.majorAxisLastTouched = this.majorAxis;
    this.minorAxisLastTouched = this.minorAxis;
    this.pos.x = posX;
    this.pos.y = posY;
    if (percToFire < 99) {
    this.vel.x = velX;
    this.vel.y = velY;
    }
    this.angle = angle;
    this.majorAxis = majorAxis;
    this.minorAxis = minorAxis;
    this.milliLastTouched = time;

    if (this.majorAxis < this.majorAxisLastTouched/2)
      this.majorAxis = this.majorAxisLastTouched;

    if (this.minorAxis < this.minorAxisLastTouched/2)
      this.minorAxis = this.minorAxisLastTouched;

    if (MirrorMode && (playerId == 1)) {
      this.pos.x = posX + this.offset.x;
      this.pos.y = posY + this.offset.y; 
        
      constrain(this.pos.y, 5.0/height, 0.5);
      constrain(this.pos.x, 0, width-(this.minorAxis/2));
    }
  }

  public void advance()
  {
    float speed = .01;
    speed = majorAxis/minorAxis * SpeedOfBlob; // The more elongated, the faster the speed
    
    float velX = constrain(abs(map(this.vel.x, 0.0, .10, 0.05 * speed, 3.0 * speed)), 0.05 * speed, 3.0 * speed);
    float velY = constrain(abs(map(this.vel.y, 0.0, .10, 0.05 * speed, 3.0 * speed)), 0.05 * speed, 3.0 * speed);
    
    if (!MovementMode) {
      velX = speed;
      velY = speed;
    }
    
    if (wallDelay > 0)
      wallDelay--;

    if (DebugMode)
      println(speed);

    if (playerId == 0) {
      this.pos.x += velX * cos(radians(-angle));
      this.pos.y -= velY * sin(radians(-angle));
    }
    else if (playerId == 1) {
      this.pos.x += velX * cos(radians(angle));
      this.pos.y -= velY * sin(radians(angle));
    }
  }

  public void render(float width, float height, float percToFire)
  {
    float majorAxisAdj = map((percToFire/100), 0, .99, .65, 1.0) * majorAxis;
    float minorAxisAdj = map((percToFire/100), 0, .99, .65, 1.0) * minorAxis;
    
    if (!GrowToFireMode) {
      majorAxisAdj = majorAxis;
      minorAxisAdj = minorAxis;
    }
    
    float absX = pos.x * width;
    float absY = height - (pos.y * height);
    float opac = map(percToFire, 0, 100, 0, maxOpacity);

    pushMatrix();

    translate(absX, absY);

    pushMatrix();
    if (playerId == 0)
      rotate(radians(-angle));
    else if (playerId == 1)
      rotate(radians(angle));

    // draw the fingerprint
    noStroke();

    if ((StrokeMode) || (percToFire < 99)) {
      if (playerId == 0) {
        stroke(colorLoc, opac);
        fill(colorLoc, 0);
      }
      else if (playerId == 1) {
        stroke(colorOpp, opac);
        fill(colorOpp, 0);
      }
    }
    else {
      if (playerId == 0) {
        stroke(colorLoc, 0);
        fill(colorLoc, opac);
      }
      else if (playerId == 1) {
        stroke(colorOpp, 0);
        fill(colorOpp, opac);
      }
    }


    if (percToFire < 99)
      strokeWeight(strokeLoading);
    else 
      strokeWeight(strokeFired);

    ellipse(0.0, 0.0, majorAxisAdj * fingerScale * width, minorAxisAdj * fingerScale * width);

    if ((!StrokeMode) && (percToFire >= 99)) {
      stroke(colorBac);
      fill(colorBac);
    }

    if (percToFire < 100) {
      float arrowDist = majorAxisAdj * fingerScale * width * 0.4;
      float arrowDistN = minorAxisAdj * fingerScale * width * 0.4;
      line(-0.5 * arrowDistScale, 0.0, arrowDist - arrowDistScale, 0.0);
      line(arrowDist - arrowDistScale, 0.0, 0.75 * arrowDistN - arrowDistScale, 0.75 * arrowDistN);
      line(arrowDist - arrowDistScale, 0.0, 0.75 * arrowDistN - arrowDistScale, -0.75 * arrowDistN);
      point(0.0, 0.0);
    }

    popMatrix();

    fill(255);
    //text(idFired, 0.0, 0.0);

    popMatrix();
  }

  public float getAbsX() {
    return pos.x * width;
  }

  public float getAbsY() {
    return height - (pos.y * height);
  }

  public float getMajorAxis() {
    return this.majorAxis * this.fingerScale * width * .5;
  }

  public float getMinorAxis() {
    return this.minorAxis * this.fingerScale * width * .5;
  }

  public float getArea() {
    return PI * this.getMajorAxis() * this.getMinorAxis();
  }

  public void shrinkArea(float oMinorAxis, float oMajorAxis) {
    if (this.majorAxis - oMajorAxis < 3)
      this.majorAxis = 3;
    else
      this.majorAxis -= oMajorAxis;

    if (this.minorAxis - oMinorAxis < 3)
      this.minorAxis = 3;
    else
      this.minorAxis -= oMinorAxis;
  }

  public void switchXDirection() {
    if (wallDelay > 0)
      return;
    wallDelay = wallDelayMax;
    angle = 180-angle;
  }
  public void switchYDirection() {
    if (wallDelay > 0)
      return;
    wallDelay = wallDelayMax;
    angle = 180-angle;
  }
}

