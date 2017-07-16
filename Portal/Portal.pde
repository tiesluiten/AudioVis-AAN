/*
Clusters of stars surrounding a portal respond to the music. 
by accident this turns out to be the COSMOS eye.  

Open problem:
Overcoming inherent lags due to buffering and inefficient code(many particles). 
----------
The idea is to have group of particles moving across a Torus,
but not to draw them all at once. Efficiency is questionable, prototyping is easy. 

Regarding the supposedely space pattern:
The more particles, the better, visually.
Computationally your computer might think differently.
The hard work lies in N_PHI*N_THETA 

We use the very nice Minim lib:
http://code.compartmental.net/minim/

For Ubuntu systems set up the input music easily through pavucontrol(recording tab)  
*/ 
import ddf.minim.*;
import ddf.minim.analysis.*;

Minim minim;
// http://code.compartmental.net/minim/audioinput_class_audioinput.html
AudioInput in;
FFT fft;

/*
To describe the Torus we use its radius and the 
inner and outer angles, similar to Wikipedia, but with
phi and theta flipped:
https://en.wikipedia.org/wiki/Torus

*/
int N_CLUSTERS = 40;
int activeClusters = 40; 
int R_IN = 150;
int R_OUT = 300; 
int N_PHI = 25;
int N_THETA = 25;
float[][] Phi = new float[N_CLUSTERS][N_PHI]; 
float[][] Theta = new float[N_CLUSTERS][N_THETA];
float relIntTheta = PI/N_THETA;
float relIntPhi = PI/N_PHI; 
//Each cluster has its one matrix of theta and phi variables, like a grid.  
float[][][] Pts = new float[N_CLUSTERS][2][N_THETA*N_PHI]; 
int initFlag = 0;

//Variables related to the audio response
int sign = 1;
//nSig was 5> 
int nSig = 2; 
float[] AvgSigE = new float[nSig]; 
int FLAG = 0; 
int N = 0; 

float amp = 0;
float maxAmp = 0;
float ampAvg = 0;
float bassOld = 0; 

//Drawing vars
color white = color(255,255,255);
color purple = color(51,0,102);
color red = color(153,0,0);
color orange = color(255,128,0);
color blue = color(175,225,255);
int colorIndex = 0;
float sAlpha = 0;
float sW = 0;


void setup() {
  //fullScreen might not work in 3D for every processing version
  //fullScreen(P3D);
  size(1000,1000,P3D);
  colorMode(RGB, 255,255,255,100);
  //frameRate(30);
  background(0);
  initPts(); 
  //Init the signal energies
  for(int i=0; i<nSig; i++){
   AvgSigE[i] = 1;  
  }
  //Init new audio object
  minim = new Minim(this);
  in = minim.getLineIn(Minim.STEREO, 512, 44100);
  fft = new FFT(in.mix.size(), in.sampleRate());
  N = fft.specSize();
  //If somehow you need very specific frequency ranges, a proper window function might do the trick. 
  //fft.window(FFT.HANN); 
}

/*
To get the opacity in 3D, use the Reddit answer
https://www.reddit.com/r/processing/comments/6dtoq6/alpha_background_level_in_3d/
*/
void draw() {
  //using the magic hint() function get a opaque background. 
  int opac = int(random(10,50));
  fill(0,opac); 
  noStroke();
  hint(DISABLE_DEPTH_TEST);
  rect(0,0,width,height);
  hint(ENABLE_DEPTH_TEST);
 
  fft.forward(in.mix);
  //print("level: ", in.mix.level(), "\n"); 
   
  //We do not live in the upperleft corner
  translate(width/2,height/2,0); 
  
  //sMax and sMin relate to particle opacity ranges(stroke)  
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
  //Assuming the "bass" lies within the 0-100Hz band. 
  float lower = 0;
  float upper = 100; 
  float bassCurr = fft.calcAvg(lower, upper);
  
  sigE = fft.calcAvg(0,in.sampleRate()/2); 
  //Update the average signal energy array 
  //which is useful in comparing with current signal. 
  for(int i=nSig-1; i>0; i--){
    AvgSigE[i] = AvgSigE[i-1];
  }
  AvgSigE[0] = sigE; 
  
  //Compute the avg E 
  for(int i=0; i<nSig; i++){
   avgSigE += AvgSigE[i]/nSig;  
  }
  
  //Base stroke intensity on the current Amplitude relative to previous ones. 
  amp = abs(in.mix.get(in.bufferSize()-1)); 
  if(amp>maxAmp){
   maxAmp = amp;  
  } 
  sMax = int(map(amp,0,maxAmp,10,100));
  
  /*
  Respond to the music.
  Completely arbitrary and tuned towards what looks cool. 
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
    sign = sign*-1;
  }
  if(sigE <avgSigE){
   FLAG = 0; 
  }
  
  //To have a vivid canvas, let the music(bass) deceide how much to draw 
  if(FLAG == 1){
    activeClusters = N_CLUSTERS;
  }
  else{
    activeClusters = int(0.5*N_CLUSTERS);
  }
  //Let the first elements of the clusters be the leader of their group. 
  for(int c=0; c<activeClusters; c++){
    relV = random(0.025);
    phi = Pts[c][0][0]-random(relV)*sigE+amp/10; 
    if(phi>2*PI){
      phi=phi-2*PI;
    }
    Pts[c][0][0] = phi;
    theta = Pts[c][1][0]+random(2*relV)*sign*sigE+0.01*sigE*sign+sign*amp/100;
    if(theta>2*PI){
      theta=theta-2*PI;
    }
    Pts[c][1][0] = theta;  
  }
  //Let the rest follow the leader  
  //Yes, the velocity scaling is super random. 
  for(int c=0; c<activeClusters; c++){
    relV = random(0.025); 
    for(int k=1;k<N_THETA*N_PHI;k++){
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
        theta = Pts[c][1][k]+random(2*relV)*sign*sigE+sign*amp/100; 
      }
      //move towards the leader
      else{
        theta = Pts[c][1][k]+(Pts[c][1][k-1]-Pts[c][1][k])*random(2*relV)*sigE*sign+0.01*sigE*sign+sign*amp/100;
      }
      if(theta>2*PI){
      theta=theta-2*PI;
      }
      Pts[c][1][k] = theta;
      
      //From the phi and theta compute the x,y,z which we can draw. 
      z = sin(phi)*R_IN;
      rExt = cos(phi)*R_IN;
      rEff = R_OUT+rExt+random(0.01); 
      
      x = rEff*cos(theta);
      y = rEff*sin(theta);
      drawPt(x,y,z,sMax,sMin);  
    }
  }
  //print("elapsed time: ", millis(), "(ms)\n");  
  //Mainly for debugging purposes 
  /*
  translate(-width/2,-height/2,0);
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
  //Save the old bass and if you like, an image. 
  bassOld = bassCurr; 
  //save("portal.tif");
  //saveFrame();
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
  // Create a scene with randomly spaced clusters consisting of randomly spaced points.
  // Create the Theta and Phi matrices/arrays just once. 
    for(int c=0;c<N_CLUSTERS; c++){
      thetaOffset = random(10);
      phiOffset = random(10);
      for(int i=0;i<N_THETA;i++){
        if(initFlag == 0){
        Theta[c][i] = (i*(relIntTheta)/N_THETA)-c*relIntTheta+random(rand);
        }
        for(int j=0;j<N_PHI;j++){
          if(initFlag == 0 ){
          Phi[c][j] = (j*(relIntPhi)/N_PHI)-c*relIntPhi+random(rand); 
          }
          Pts[c][0][k] = Phi[c][j]+phiOffset+random(rand);
          Pts[c][1][k] = Theta[c][i]+thetaOffset+random(rand);
          k+=1;
        }
      }
      k=0; 
    }
    initFlag = 1;   
}

/*
A point(end of a vector) is drawn based on its norm.
The further away, the more opaque and smaller plus a special color assigned. 
*/
void drawPt(float x, float y, float z, float sMax, float sMin){
  
  //Due to the computer grid, translate! However, better not here. 
  //pushMatrix();
  //translate(width/2,height/2,0);
  if(z>0){
    sMax = 0.5*sMax;
  }
  sAlpha = int(map(getNorm(x,y,z),R_OUT-R_IN,R_IN+R_OUT,sMax,sMin)); 
  //sW is used for the strokeWeight();
  //Setting it to say 3,1 instead of 2,1 removes a bit of the "realism" 
  sW = int(map(getNorm(x,y,z),R_OUT-R_IN,R_IN+R_OUT,2,1)); 
  colorIndex = int(map(getNorm(x,y,z),R_OUT-R_IN,R_IN+R_OUT,0,10));
  colorIndex += int(random(2));  
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

  //popMatrix();  
}

float getNorm(float x, float y, float z){
  float norm = sqrt(x*x+y*y+z*z); 
  return norm; 
}