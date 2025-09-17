class Gut{
  float[] location;
  int when;
  int PIECES = 5;
  float[][] pieces_coor;
  int DURATION = 60;
  int species;
  
  public Gut(float[] L, int w, int s){
    location = L;
    when = w;
    species = s;
    pieces_coor = new float[PIECES][6];
    for(int p = 0; p < PIECES; p++){
      float angle = random(0,2*PI);
      float dist = random(3,7);
      float vx = dist*cos(angle);
      float vy = dist*sin(angle);
      float vz = random(7,15);
      float[] coor = {L[0]+vx,L[1]+vy,L[2]+vz,vx,vy,vz};
      pieces_coor[p] = coor;
    }
  }
  
  void doPhysics(){
    float FAC = 0.7; // bouncing factor
    for(int p = 0; p < PIECES; p++){
      float[] coor = pieces_coor[p];
      coor[5] -= 1; // gravity
      for(int dim = 0; dim < 3; dim++){
        coor[dim] += coor[dim+3];
      }
      float ground = map.getGroundLevel(coor);
      if(coor[2] <= ground){
        coor[2] = ground;
        coor[3] *= FAC;
        coor[4] *= FAC;
        coor[5] = abs(coor[5])*FAC; // bouncing guts
      }
    }
  }
  void drawGut(){
    float size = 1-(float)(ticks-when)/DURATION;
    g.fill(SPECIES_COLORS[species]);
    for(int p = 0; p < PIECES; p++){
      float[] c = pieces_coor[p];
      g.pushMatrix();
      g.translate(unloop_two(c[0],camera[0]),unloop_two(c[1],camera[1]),c[2]);
      g.sphere(12*size);
      g.popMatrix();
    }
  }
  
  boolean toDie(){
    return (ticks-when >= DURATION);
  }
}
