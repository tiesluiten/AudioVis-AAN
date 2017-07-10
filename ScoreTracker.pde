/*
*     Tracks and displays average spectrum
*     values of low, middle, and high.
*/

import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioInput in;
FFT fft;

// Set spectrums' upper limits.
float specLow = 0.03;   // 3%
float specMid = 0.125;  // 12.5%
float specHi = 0.2;     // 20%

// Initialize scores.
float scoreLow = 0;
float scoreMid = 0;
float scoreHi = 0;

// Initialize old scores.
float oldScoreLow = scoreLow;
float oldScoreMid = scoreMid;
float oldScoreHi = scoreHi;

float amp = 4;

void setup()
{
  size(800, 400);
  background(0); 
  smooth();
  
  noStroke();
  fill(255);
  
  textSize(16);
  textAlign(CENTER);
  
  // INITIATE NEW AUDIO OBJECT ------------------------
  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO, 4096, 44100);
  fft = new FFT(in.mix.size(), 44100);
}

void draw()
{
  background(0);

  fft.forward(in.mix);
  
  // CHECK NEW SCORE LOW
  oldScoreLow = scoreLow;
  scoreLow = checkScore(0.0, specLow);
  ellipse(200, (height / 2)  - (scoreLow * amp), 30, 30);
    text("scoreLow", 200, (height / 2) + 50);
    text(scoreLow, 200, (height / 2) + 70);
  
  // CHECK NEW SCORE MID
  oldScoreMid = scoreMid;
  scoreMid = checkScore(specLow, specMid);
  ellipse(400, (height / 2)  - (scoreMid * amp), 30, 30);
    text("scoreMid", 400, (height / 2) + 50);
    text(scoreMid, 400, (height / 2) + 70);
  
  // CHECK NEW SCORE HI
  oldScoreHi = scoreHi;
  scoreHi = checkScore(specMid, specHi);
  ellipse(600, (height / 2)  - (scoreHi * amp), 30, 30);
    text("scoreHi", 600, (height / 2) + 50);
    text(scoreHi, 600, (height / 2) + 70);
}

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
