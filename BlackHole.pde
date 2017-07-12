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

int colorLow =-25;
int colorUp = 50;

Body[] body = new Body[nBodies];

void setup()
{
  size(600, 600);
  background(0);
  noStroke();
  fill(255);
  
  for(int i = 0; i < nBodies; i++)
  {
    body[i] = new Body();
  }
  
  // INITIATE NEW AUDIO OBJECT ------------------------
  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO, 4096, 44100);
  fft = new FFT(in.mix.size(), 44100);
}

void draw()
{
  fill(0, 50);
  rect(0, 0, width, height);
  fft.forward(in.mix);
  oldScoreLow = scoreLow;
  scoreLow = checkScore(0.0, specLow);  
  oldScoreMid = scoreMid;
  scoreMid = checkScore(specLow, specMid);  
  
  //colorLow++;
  colorUp++;  
    
  for(int i = 0; i < nBodies; i++)
  {
    body[i].update();
  }
  
  if(scoreMid > 10 && scoreMid > oldScoreMid)
  {
    colorLow = 0;
    colorUp = 50;
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
  
  Body()
  {
    pushMatrix();
      translate(width/2, height/2);
      
      float rad = random(90, 120);
      float x = random(-rad, rad);
      float y = sqrt(sq(rad) - sq(x));
      if(random(10) > 5)
        y = -y;
      
      loc = new PVector(x, y);
      vel = new PVector(0, 0);
      acc = new PVector(0, 0);
      middle = new PVector(0, 0);
    popMatrix();
  }
  
  void reset()
  {
      float rad = random(150, 200);
      loc.x = random(-rad, rad);
      loc.y = sqrt(sq(rad) - sq(loc.x));
      if(random(10) > 5)
        loc.y = -loc.y;
      inc = random(0.005, 0.02);
  }
  
  void update()
  {
    pushMatrix();
      translate(width/2, height/2); 
      if(scoreLow > 50)
        rotate(i - scoreLow);
      else
        rotate(i);
      
      float distance = sqrt(sq(loc.x) + sq(loc.y));
      
      vel.x = - (loc.x / grav);
      vel.y = - (loc.y / grav);
      loc.add(vel);
      
      //fill(255);
      if(distance < colorUp && distance > colorLow)
        fill(10, 50, 150);
      else
        fill(255);
      ellipse(loc.x, loc.y, size - (distance / 100), size - (distance / 100));
      
      if(distance < 50)
        reset();
      
      i += inc * (100 / distance);
    popMatrix();
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