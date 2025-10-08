class Map{
  float[][] elev;
  Tile[][] tiles;
  int[][][] closestWater;
  boolean[][][] visible;
  int N;
  float ELEV_FACTOR = 10;
  float WATER_DEEP = 20; // creatures can "drink" water only if it's this deep.
  float WATER_LEVEL = 2.44*T;
  float WAVE_SIZE = 10;
  float WAVE_PERIOD = 100;
  
  color[] colors = {color(150, 135, 120),color(150, 135, 120),color(237,219,199),color(121, 212, 85), color(41, 163, 61), color(153, 153, 153), color(124, 138, 156), color(255,255,255), color(255,255,255)};
  public Map(int _N){
    N = _N;
    elev = new float[N][N];
    tiles = new Tile[N][N];
    closestWater = new int[N][N][2];
    visible = new boolean[N][N][2]; // ground level, water level
    float maxElev = -9999;
    float minElev = 9999;
    for(int x = 0; x < N; x++){
      for(int y = 0; y < N; y++){
        elev[x][y] = getNoiseAt(x,y,N, N*0.1);
        tiles[x][y] = new Tile();
        maxElev = max(maxElev,elev[x][y]);
        minElev = min(minElev,elev[x][y]);
      }
    }
    for(int x = 0; x < N; x++){
      for(int y = 0; y < N; y++){
        elev[x][y] = (elev[x][y]-minElev)/(maxElev-minElev)*ELEV_FACTOR;
      }
    }
    for(int x = 0; x < N; x++){
      for(int y = 0; y < N; y++){
        closestWater[x][y] = getClosestWater(x,y,N);
      }
    }
  }
  int[] getClosestWater(int x, int y, int N){
    int[] here = {x,y};
    if(elev[x][y]*T <= WATER_LEVEL-WATER_DEEP){
      return here;
    }
    for(int dist = 1; dist <= N/2; dist++){
      for(int shift = -dist; shift < dist; shift++){
        int[][] delta = {{dist,shift},{-dist,-shift},{shift,-dist},{-shift,dist}};
        for(int dire = 0; dire < delta.length; dire++){
          int x_t = unloop_int(x+delta[dire][0],N);
          int y_t = unloop_int(y+delta[dire][1],N);
          if(elev[x_t][y_t]*T <= WATER_LEVEL-WATER_DEEP){
            int[] result = {x_t,y_t};
            return result;
          }
        }
      }
    }
    return here;
  }
  float getNoiseAt(float x, float y, int N, float smooth){
    float NR = 0.1;
    float[][] noi = {{noise(x*NR,y*NR), noise(x*NR,(y-N)*NR)},{noise((x-N)*NR,y*NR), noise((x-N)*NR,(y-N)*NR)}};
    float x_lerp = min(max((x-(N-smooth))/smooth,0),1);
    float y_lerp = min(max((y-(N-smooth))/smooth,0),1);
    
    float mid_val_1 = lerp(noi[0][0], noi[0][1], y_lerp);
    float mid_val_2 = lerp(noi[1][0], noi[1][1], y_lerp);
    float final_val = lerp(mid_val_1, mid_val_2, x_lerp);
    return final_val;
  }
  color getColorAt(float x, float y){
    float[] coor = {(x)*T,(y)*T};
    float e = min(max(getGroundLevel(coor)/T/ELEV_FACTOR,0),1);
    e = max(0,-0.1+e*1.10); // dumb tweak to give myself more sand
    float fac = e*(colors.length-1-EPS);
    color col = color_lerp(colors[(int)e],colors[(int)fac+1],fac%1.0);
    return col;
  }
  color getWaterColorAt(float x, float y){
    color groundColor = getColorAt(x,y);
    
    float[] coor = {(x)*T,(y)*T};
    float e = getGroundLevel(coor);
    float e_rel = e-getWaterLevel(x,y);
    float prog = min(max(1+e_rel/100,0),1);
    if(prog == 0){
      return WATER_COLOR;
    }
    return colorLerp(WATER_COLOR, darken(groundColor,0.75), prog);
  }
  
  float getWaterLevel(float x, float y){
    float cycle_offset = (x*3+y*2)/SIZE; // sorta random but has to be an integer for smooth looping
    return WATER_LEVEL+sin(cycle_offset+ticks*2*PI/WAVE_PERIOD)*WAVE_SIZE;
  }
  
  boolean getVis(float x, float y, float[][] arr, PGraphics g){
    float[][] screenXY = {
    {g.screenX(0,0,arr[0][0]), g.screenY(0,0,arr[0][0])},
    {g.screenX(0,T,arr[0][1]), g.screenY(0,T,arr[0][1])},
    {g.screenX(T,0,arr[1][0]), g.screenY(T,0,arr[1][0])},
    {g.screenX(T,T,arr[1][1]), g.screenY(T,T,arr[1][1])}};
    
    boolean[] all_to_one_side = {true,true,true,true};
    for(int p = 0; p < 4; p++){
      if(screenXY[p][0] < g.width){
        all_to_one_side[0] = false;
      }
      if(screenXY[p][0] >= 0){
        all_to_one_side[1] = false;
      }
      if(screenXY[p][1] < g.height){
        all_to_one_side[2] = false;
      }
      if(screenXY[p][1] >= 0){
        all_to_one_side[3] = false;
      }
    }
    for(int p = 0; p < 4; p++){
      if(all_to_one_side[p]){
        return false;
      }
    }
    return true;
  }
  
  void drawMap(){
    for(int x = 0; x < N; x++){
      for(int y = 0; y < N; y++){
        int x2 = (x+1)%N;
        int y2 = (y+1)%N;
        
        float[][] g_elev = {{T*elev[x][y], T*elev[x][y2]}, {T*elev[x2][y], T*elev[x2][y2]}};
        
        float[][] w_elev = {{getWaterLevel(x,y),getWaterLevel(x,y2)}, {getWaterLevel(x2,y),getWaterLevel(x2,y2)}};
        
        g.pushMatrix();
        g.translate(unloop_two(x*T,camera[0]),unloop_two(y*T,camera[1]));
        
        visible[x][y][0] = getVis(x,y,g_elev,g);
        visible[x][y][1] = getVis(x,y,w_elev,g);
        
        if(visible[x][y][0]){
          g.beginShape();
          g.fill(getColorAt(x,y));
          g.vertex(0,0,g_elev[0][0]);
          g.fill(getColorAt(x,y2));
          g.vertex(0,T,g_elev[0][1]);
          g.fill(getColorAt(x2,y2));
          g.vertex(T,T,g_elev[1][1]);
          g.fill(getColorAt(x2,y));
          g.vertex(T,0,g_elev[1][0]);
          g.endShape(CLOSE);
        }
        
        if(visible[x][y][1] &&
        (g_elev[0][0] <= w_elev[0][0] || g_elev[0][1] <= w_elev[0][1]
        || g_elev[1][0] <= w_elev[1][0] || g_elev[1][1] <= w_elev[1][1])){
          
          g.beginShape();
          g.fill(getWaterColorAt(x,y));
          g.vertex(0,0,w_elev[0][0]);
          g.fill(getWaterColorAt(x,y2));
          g.vertex(0,T,w_elev[0][1]);
          g.fill(getWaterColorAt(x2,y2));
          g.vertex(T,T,w_elev[1][1]);
          g.fill(getWaterColorAt(x2,y));
          g.vertex(T,0,w_elev[1][0]);
          g.endShape(CLOSE);
        }
        
        g.popMatrix();
      }
    }
  }
  float getGroundLevel(float x, float y){
    float[] coor = {unloop_arr(x),unloop_arr(y)};
    return getGroundLevel(coor);
  }
  float getGroundLevel(float[] coor){
    float x_val = min(max(coor[0]/T,0),SIZE-EPS);
    float y_val = min(max(coor[1]/T,0),SIZE-EPS);
    int x_int = (int)x_val;
    float x_rem = x_val-x_int;
    int y_int = (int)y_val;
    float y_rem = y_val-y_int;
    int x2_int = (x_int+1)%N;
    int y2_int = (y_int+1)%N;
    
    
    float elev1 = lerp(elev[x_int][y_int],elev[x_int][y2_int],y_rem);
    float elev2 = lerp(elev[x2_int][y_int],elev[x2_int][y2_int],y_rem);
    return T*lerp(elev1,elev2,x_rem);
  }
}
