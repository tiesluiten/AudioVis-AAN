/*
Clusters of stars surrounding a portal respond to the music. 
by accident this turns out to be the COSMOS eye.  

Open problem:
The more cool stuff you add, the more lags you experience.
At this point the animation is so wild that it is hard to see that actually the
whole thing is very much behind. 
Since must beats(the bass part) are similar throughout a song you will not quickly notice this problem. 
Thus either the code must be more efficient, or the audio most be somehow predicted. 
----------
The idea is to have group of particles moving across a Torus,
but not to draw them all. Efficiency is questionable, which
is compensated with the ease of prototyping. 

Regarding the supposedely space pattern:
The more particles, the better, visually.
Computationally your computer might think differently.
The hard work lies in nPhi*nTheta 

We use the very nice Minim lib:
http://code.compartmental.net/minim/

For Ubuntu systems set up the input music easily through pavucontrol(recording tab)  
*/ 
import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
AudioInput in;
FFT fft;

/*
To describe the Torus we use its radius and the 
inner and outer angles, similar to Wikipedia, but with
phi and theta flipped:
https://en.wikipedia.org/wiki/Torus

*/
int nClusters = 40;
float rIn = 150.0;
float rOut = 300.0; 
int nPhi = 25;
int nTheta = 25;
float[][] Phi = new float[nClusters][nPhi]; 
float[][] Theta = new float[nClusters][nTheta];
float relIntTheta = PI/nTheta;
float relIntPhi = PI/nPhi; 
//Each cluster has its one matrix of theta and phi variables, like a grid.  
float[][][] Pts = new float[nClusters][2][nTheta*nPhi]; 
float ANG = 0; 

//Variables related to the audio response
int SIGN = 1; 
int nSig = 5; 
float[] AvgSigE = new float[nSig]; 
float Tr = 0;
int FLAG = 0; 
int N = 0; 

float amp = 0;
float maxAmp = 0;
float ampBuffer [] = new float[22];
float ampAvg = 0;
float bassOld = 0; 


void setup() {
  //fullScreen might not work in 3D for every processing version
  //fullScreen(P3D);
  size(1000,1000,P3D);
  colorMode(RGB, 255,255,255,100);
  frameRate(30);
  background(0);
  
  initPts(); 
  
  //Init the signal energies
  for(int i=0; i<nSig; i++){
   AvgSigE[i] = 1;  
  }
  //Init new audio object, 44100 due to Shannon/Nyquist. 
  //Q: effectively, what do we see when we change 4096? 
  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO, 1024*4, 44100);
  fft = new FFT(in.mix.size(), 44100);
  N = fft.specSize(); 
  background(0);   
}

/*
To get the opacity in 3D, use the Reddit answer
https://www.reddit.com/r/processing/comments/6dtoq6/alpha_background_level_in_3d/
*/
void draw() {
  //using the magic hint() function get a opaque background. 
  float opac = random(10,50);
  fill(0,opac); 
  noStroke();
  hint(DISABLE_DEPTH_TEST);
  rect(0,0,width,height);
  hint(ENABLE_DEPTH_TEST);
  
  fft.forward(in.mix);
  
  int sMax = 100; 
  int sMin = 0;
  //Init coorinate related variables.
  float x = 0;
  float y = 0;
  float z = 0;
  float rExt = 0;
  float rEff = 0;
  float phi = 0;
  float theta = 0;
  float relV = 0.01; 
  float relDist = 0;
  
  float avgSigE = 0; 
  float sigE = 0;
  float lower = 0;
  float upper = 100; 
  float bassCurr = fft.calcAvg(lower, upper);
  
  //Calc the signal energy 
    for(int i = 0; i < N; i++){
      sigE += fft.getBand(i)/N;
      //Uncomment line below to part of the freq spectrum. 
      //line(i, height, i, height - fft.getBand(i)*2);
    }
    //Update the average signal energy
    //which is useful in comparing with current signal. 
    for(int i=nSig-1; i>0; i--){
      AvgSigE[i] = AvgSigE[i-1];
    }
    AvgSigE[0] = sigE; 
    
    //Compute the avg E 
    for(int i=0; i<nSig; i++){
     avgSigE += AvgSigE[i]/nSig;  
    }
    
    //Update the history of average bass
    
    //Compute the average bass 
    
    //Get the max amp from the buffer(the one we set) 
    for(int i = 0; i < in.bufferSize() - 1; i++) {
      if ( abs(in.mix.get(i)) > amp ) {
        amp = abs(in.mix.get(i));
      }
    }
    //Remember the max amp 
    if(amp>maxAmp){
     maxAmp = amp;  
    }
  
    //Right not this is not used: 
    //Determine the average amplitude of the input audio
    //Using this is a better indication of changes in music then a fixed threshold 
    /*
    ampAvg = amp/ampBuffer.length;
    for(int j=ampBuffer.length-1; j>0; j--){
      ampBuffer[j]=ampBuffer[j-1];
      ampAvg += (ampBuffer[j]/ampBuffer.length); 
    }
    ampBuffer[0]=amp;
    */
    
    //Base stroke intensity on current amp  
    sMax = int(map(amp,0,maxAmp,10,100));
    
    /*
    Respond to the music
    Completely arbitrary and tuned
    */
    if(bassCurr>2*bassOld){
     FLAG=1; 
    }
    //Extremer bass
    if(bassCurr>3*bassOld){
     initPts();  
    }
    //Flip the direction 
    if(sigE>1.15*avgSigE){
      SIGN = SIGN*-1;
    }
    if(sigE <avgSigE){
     FLAG = 0; 
    }
  
  //To have a vivid canvas, let the music(bass) deceide how much to draw 
  if(FLAG == 1){
    nClusters = 40;
  }
  else{
    nClusters = 20;
  }
  
  for(int c=0; c<nClusters; c++){
    relV = random(0.025);
    phi = Pts[c][0][0]-random(relV)*sigE+amp/10; 
    if(phi>2*PI){
      phi=phi-2*PI;
    }
    Pts[c][0][0] = phi;
    theta = Pts[c][1][0]+random(2*relV)*SIGN*sigE+0.01*sigE*SIGN+SIGN*amp/100;
    if(theta>2*PI){
      theta=theta-2*PI;
    }
    Pts[c][1][0] = theta;  
  }
  //Let the rest follow the leader  
  //Yes, the velocity scaling is super random. 
  for(int c=0; c<nClusters; c++){
    relV = random(0.025); 
    for(int k=1;k<nTheta*nPhi;k++){
      //Check if the point is within the interval
      relDist = abs(Pts[c][0][k]-Pts[c][0][k-1]); 
      if(relDist<relIntPhi){
        phi = Pts[c][0][k]-random(relV)*sigE+amp/10; 
      }
      //If not, move towards the leader
      else{
        phi = Pts[c][0][k]+(Pts[c][0][k-1]-Pts[c][0][k])*random(relV)*sigE+amp/10;  
      }
      if(phi>2*PI){
      phi=phi-2*PI;
      }
      Pts[c][0][k] = phi;
      //Same story for theta 
      relDist = abs(Pts[c][1][k]-Pts[c][1][k-1]); 
      if(relDist<relIntTheta){
        theta = Pts[c][1][k]+random(2*relV)*SIGN*sigE+SIGN*amp/100; 
      }
      //move towards the leader
      else{
        theta = Pts[c][1][k]+(Pts[c][1][k-1]-Pts[c][1][k])*random(2*relV)*sigE*SIGN+0.01*sigE*SIGN+SIGN*amp/100;
      }
      if(theta>2*PI){
      theta=theta-2*PI;
      }
      Pts[c][1][k] = theta;
      
      //From the phi and theta compute the x,y,z which we can draw. 
      z = sin(phi)*rIn;
      rExt = cos(phi)*rIn;
      rEff = rOut+rExt+random(0.01); 
      
      x = rEff*cos(theta);
      y = rEff*sin(theta);
      drawPt(x,y,z,sMax,sMin);  
    }
  }
  //print("elapsed time: ", millis(), "(ms)\n");  
  //Mainly for debugging purposes 
  /*
  textSize( 18 );
  strokeWeight(2);
  stroke(255); 
  fill(255); 
  line(0,7,sigE*100,7); 
  text("Signal Energy: "+ sigE,5,30); 
  line(0,37,avgSigE*100,37); 
  text("Avg Signal Energy: "+ avgSigE,5,55); 
  line(0,62,bassCurr*5,62);
  text("Bass: "+ bassCurr,5,80); 
  line(0,87,amp*100,87);
  text("Amp: "+ amp,5,105); 
  */
  //reset amp and save the old bass
  amp = 0; 
  bassOld = bassCurr; 
}

/*
This function places the clusters of points somewhere on the torus.
Again, tuned to make it look nice, therefore the offset and rand variables. 
*/
void initPts(){
  //delay(100); 
  //To get this right was purely tuning. 
  int k = 0;
  float thetaOffset = 0;
  float phiOffset = 0;
  float rand = 0.5; 
  // Create a linspaced theta and phi array per clusters
  // Assuming they are the same length one loop suffices 
  for(int c=0;c<nClusters; c++){
    for(int i=0;i<nPhi;i++){
      Phi[c][i] = (i*(relIntPhi)/nPhi)-c*relIntPhi+random(rand);
      Theta[c][i] = (i*(relIntTheta)/nTheta)-c*relIntTheta+random(rand);
    }
  }
  // Then init the first random set of Pts coords
  for(int c=0;c<nClusters; c++){
    thetaOffset = random(10);
    phiOffset = random(10);
    for(int i=0;i<nTheta;i++){
      for(int j=0;j<nPhi;j++){
     Pts[c][0][k] = Phi[c][j]+phiOffset+random(rand);
     Pts[c][1][k] = Theta[c][i]+thetaOffset+random(rand);
     k+=1;
      }
    }
    k=0; 
  }
}

/*
A point(end of a vector) is drawn based on its norm.
The further away, the more opaque and smaller plus a special color assigned. 
*/
void drawPt(float x, float y, float z, float sMax, float sMin){
  color white = color(255,255,255);
  color purple = color(51,0,102);
  color red = color(153,0,0);
  color orange = color(255,128,0);
  color blue = color(175,225,255);
  int colorIndex = 0;
  float sAlpha = 0;
  float sW = 0;
  //Due to the computer grid, translate! 
  pushMatrix();
  translate(width/2,height/2,0);
  if(z>0){
    sMax = 0.5*sMax;
  }
  sAlpha = int(map(getNorm(x,y,z),rOut-rIn,rIn+rOut,sMax,sMin)); 
  //sW is used for the strokeWeight();
  //Setting it to say 3,1 instead of 2,1 removes a bit of the "realism" 
  sW = int(map(getNorm(x,y,z),rOut-rIn,rIn+rOut,2,1)); 
  colorIndex = int(map(getNorm(x,y,z),rOut-rIn,rIn+rOut,0,10));
  colorIndex = colorIndex + int(random(2));  
  if(colorIndex>6){
   stroke(purple,sAlpha); 
  }
  else if(colorIndex>3){
    stroke(red,sAlpha);
  }
  else if(colorIndex>2){
    stroke(orange,sAlpha);
  }
  else if(colorIndex>1){
    stroke(white,sAlpha);
  }
  else{
    stroke(blue,sAlpha);
  } 
  
  strokeWeight(sW);
  point(x+random(0.01),y+random(0.01),z+random(0.01));
  
  stroke(white,0.25*sAlpha);
  strokeWeight(2*sW);
  point(x,y,z); 
  stroke(white,sAlpha); 
  strokeWeight(sW);
  point(x,y,z);

  popMatrix();  
}

float getNorm(float x, float y, float z){
  float norm = sqrt(x*x+y*y+z*z); 
  return norm; 
}