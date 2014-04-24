class Finger
{
  public int id;
  public int idFired;
  public int playerId;
  public int dirX = 1, dirY = 1;
  public PVector pos;
  public PVector vel;
  public float angle;
  public float majorAxis;
  public float minorAxis;
  public float majorAxisLastTouched;
  public float minorAxisLastTouched;
  public int milliLastTouched;
  public int milliFirstTouched;

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
    this.vel = new PVector(0.5, 0.5);
    this.angle = 0.0;
    this.majorAxis = 0.0;
    this.minorAxis = 0.0;
    dirX = 1;
    dirY = 1;
  }

  public void update(float posX, float posY, float velX, float velY, 
  float angle, float majorAxis, float minorAxis, int time)
  {
    this.majorAxisLastTouched = this.majorAxis;
    this.minorAxisLastTouched = this.minorAxis;
    this.pos.x = posX;
    this.pos.y = posY;
    this.vel.x = velX;
    this.vel.y = velY;
    this.angle = angle;
    this.majorAxis = majorAxis;
    this.minorAxis = minorAxis;
    this.milliLastTouched = time;
    
    if (this.majorAxis < this.majorAxisLastTouched/2)
      this.majorAxis = this.majorAxisLastTouched;
      
    if (this.minorAxis < this.minorAxisLastTouched/2)
      this.minorAxis = this.minorAxisLastTouched;
  }
  
  public void advance()
  {
    float speed = .01;
    speed = majorAxis/minorAxis * .0065; // The more elongated, the faster the speed
    
    
    if (DebugMode)
      println(speed);
    
    if (playerId == 0) {
      this.pos.x += dirX * speed * cos(radians(-angle));
      this.pos.y -= dirY * speed * sin(radians(-angle));
    }
    else if (playerId == 1) {
      this.pos.x += dirX * speed * cos(radians(angle));
      this.pos.y -= dirY * speed * sin(radians(angle));
    }
  }

  public void render(float width, float height, float percToFire)
  {
    float absX = pos.x * width;
    float absY = height - (pos.y * height);
    
    pushMatrix();

    translate(absX, absY);

    pushMatrix();
    if (playerId == 0)
      rotate(radians(-angle));
    else if (playerId == 1)
      rotate(radians(angle));

    // draw the fingerprint
    noStroke();
    
    if (playerId == 0) {
      stroke(colorLoc, percToFire);
      fill(151, 49, 103, 0);
    }
    else if (playerId == 1) {
      stroke(colorOpp, percToFire);
      fill(26, 75, 98, 0);
    }
    
    if (percToFire < 99)
      strokeWeight(2);
    else 
      strokeWeight(4);
    
    ellipse(0.0, 0.0, majorAxis * fingerScale * width, minorAxis * fingerScale * width);
    
    if (percToFire < 100) {
      float arrowDist = majorAxis * fingerScale * width * 0.4;
      line(0.0, 0.0, arrowDist - arrowDistScale, 0.0);
      line(arrowDist - arrowDistScale, 0.0, 0.75 * arrowDist - arrowDistScale, 0.35 * arrowDist);
      line(arrowDist - arrowDistScale, 0.0, 0.75 * arrowDist - arrowDistScale, -0.35 * arrowDist);
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
    dirX *= -1;
  }
  public void switchYDirection() {
    dirY *= -1;
  }
}

