/*--------MINIM AUDIO---------*/
import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioInput in;
FFT fft;

float specLow = 0.03;
float specMid = 0.125;

float scoreLow = 0;
float scoreMid = 0;

float oldScoreLow = scoreLow;
float oldScoreMid = scoreMid;
/*----------------------------*/

int nBodies = 2000;
Body[] body = new Body[nBodies];

int nRings = 10;
Ring[] ring = new Ring[nRings];

int colCount = 0;
color[] colarray = new color[5];

int ringCount = 0;

void setup()
{
  //size(600, 600);
  size(1366, 720);
  background(0);
  noStroke();
  fill(255);
  
  for(int i = 0; i < nBodies; i++)
  {
    body[i] = new Body();
  }
  
  for(int i = 0; i < nRings; i++)
  {
    ring[i] = new Ring();
  }
  
  // INITIATE NEW AUDIO OBJECT ------------------------
  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO, 4096, 44100);
  fft = new FFT(in.mix.size(), 44100);
  
  // SET UP COLORS ------------------------------------
  colarray[0] = color(166, 50, 125, 150);
  colarray[1] = color(103, 66, 140, 150);
  colarray[2] = color(42, 32, 64, 150);
  colarray[3] = color(132, 123, 166, 150);
  colarray[4] = color(49, 37, 89, 150);
  
  /*
  colarray[0] = color(255, 136, 231, 150);
  colarray[1] = color(255, 245, 193, 150);
  colarray[2] = color(252, 143, 110, 150);
  colarray[3] = color(122, 11, 18, 150);
  colarray[4] = color(123, 54, 98, 150);
  */
}

void draw()
{
  fill(0, 50);
  rect(0, 0, width, height);
  
  fft.forward(in.mix);
  
  oldScoreLow = scoreLow;
  scoreLow = checkScore(0.0, specLow);  
  println(scoreLow);
  
  oldScoreMid = scoreMid;
  scoreMid = checkScore(specLow, specMid);
  println("Scoremid: ", scoreMid);
  
 
  for(int i = 0; i < nBodies; i++)
  {
    body[i].update();
  }
  
  for(int i = 0; i < nRings; i++)
  {
    ring[i].update();
  }
  
  if(scoreMid > 0.025 && scoreMid > oldScoreMid)
  {
    ringCount++;
    if(ringCount > nRings - 1)
      ringCount = 0;
    colCount++;
    if(colCount > 4)
      colCount = 0;
    ring[ringCount].reset(colCount);
    println("SCOREMID: ", scoreMid);
  }
  
  pushMatrix();
  translate(width/2, height/2);
    fill(0);
    ellipse(0, 0, 100, 100);
  popMatrix();
}

class Body
{
  PVector loc;
  PVector vel;
  PVector acc;
  PVector middle;
  
  float size = 2;
  int velocity = 5;
  float i = 0;
  float inc = random(0.0075, 0.0125);
  float grav = random(1000,1500);
  
  float[] vals = new float[2];
  
  Body()
  {
    pushMatrix();
      translate(width/2, height/2);
      
      float rad = random(50, 175);
      float x = random(-rad, rad);
      float y = sqrt(sq(rad) - sq(x));
      if(random(10) > 5)
        y = -y;
      
      loc = new PVector(x, y);
      vel = new PVector(0, 0);
      acc = new PVector(0, 0);
      middle = new PVector(0, 0);
    popMatrix();
    
    vals[0] = 200;
    vals[1] = 3;
  }
  
  void reset()
  {
      float rad = random(150, 200);
      loc.x = random(-rad, rad);
      loc.y = sqrt(sq(rad) - sq(loc.x));
      if(random(10) > 5)
        loc.y = -loc.y;
      inc = random(0.005, 0.02);
      
      vals[0] = 200;
      //vals[1] = 3;
  }
  
  void update()
  {
    pushMatrix();
      translate(width/2, height/2); 
      if(scoreLow > 0.16)
        rotate(i - scoreLow);
      else
        rotate(i);
      
      float distance = sqrt(sq(loc.x) + sq(loc.y));
      
      vel.x = - (loc.x / grav);
      vel.y = - (loc.y / grav);
      loc.add(vel);
      

      
      float[] temp = new float[2];
      for(int i = 0; i < nRings - 1; i++)
      {
        temp = ring[i].vals();
        if(temp[0] > distance && temp[0] < vals[0])
        {
          vals = temp;
        }        
      }
      
      fill(color(colarray[int(vals[1])]));
      
      ellipse(loc.x, loc.y, size - (distance / 100), size - (distance / 100));
      
      if(distance < 50)
        reset();
      
      i += inc * (100 / distance);
    popMatrix();
  }
}

class Ring
{
  float rad = 50;
  float inc = 5;
  int colNum = 0;
  
  Ring()
  {
    
  }
  
  void update()
  {
    rad += 1;
  }
  
  void reset(int col)
  {
    colNum = col;
    println("COL: ", colNum);
    rad = 50;
  }
  
  float[] vals()
  {
    float[] temp = new float[2];
    temp[0] = rad;
    temp[1] = colNum;
    return temp;
  }
}

// Check average spectrum value.
float checkScore(float specLower, float specUpper)
{
  float score = 0;    
  for(int i = (int)(fft.specSize()*specLower); i < fft.specSize()*specUpper; i++)
  {
    score += fft.getBand(i);
  }  
  // Calculate spectrum size.
  float specSize = (fft.specSize()*specUpper) - (fft.specSize()*specLower);
  // Get score average across spectrum.
  score = score / specSize;  
  return score;
}
