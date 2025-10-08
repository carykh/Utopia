import com.jogamp.newt.opengl.GLWindow;
import processing.sound.*;
SoundFile[] sfx;
String[] sfx_names = {"splash0", "splash1", "splash2", "splash3", "splash4", "jump", "land",
"eat1","eat2","eat3","eat4","eat5","seed","baby","oof"};

int PLAYER_COUNT = 110;
int DIM_COUNT = 3;
int CENTER_X = 760; // try setting this to 760 or 761 if there is horizontal camera-pan-drifting
color SKY_COLOR = color(150,200,255);
KeyHandler keyHandler;
float TICKS_PER_DAY = 4500;
boolean TRAP_MOUSE = true;

int SIZE = 36;
int T = 140; // T = tile size
float COLLISION_DISTANCE = 33; // how close to creatures have to be to interact?
int MAX_PER_TILE = 2;
float VISION_DISTANCE = T*7.0;


float EPS = 0.001;
PGraphics g;
PGraphics ui;
int frames = 0;
int ticks = 0;
int playback_speed = 1;
int FPS = 30;
GLWindow r;
Map map;
PImage ui_title;
int MAX_ID = 0;

float DISTANCE_FROM_PLAYER = 200;
ArrayList<Record> archive;
int ARCHIVE_EVERY = 30;
int ARCHIVE_SIZE = 200;
int SPECIES_COUNT = 6;
int[] START_SPECIES = {0,0,0,0,0,0,0,1,1,1,1,1,2,2,2,3,3,4};
color[] SPECIES_COLORS = {color(255,100,255),color(0,255,255),color(255,200,0),color(0,160,160),color(255,0,0),color(128,128,128)};
color WATER_COLOR = color(40,80,220);
ArrayList<Player> players;
ArrayList<Gut> guts;
boolean followSpecimen = false;

String[] PRIORITY_NAMES = {"Hunger", "Thirst", "Freaky", "Eepy", "Flee Monsters", "Caretaking"};
color[] PRIORITY_COLORS = {color(150,100,50), color(0,0,255), color(255,0,255), color(128,255,0), color(255,0,0), color(255,188,120)};
float[] PRIORITY_CAPS = {0.0,0.0,0.2,0.6,0.0,0.0};

// how quickly does each species gain urgency in doing the fundamental tasks?
// Each row is per species
// Each element in row is per priority
float[][] PRIORITY_RATES = {
{3.0,0,0,0,0,0}, // Pink flower
{2.3,0,0,0,0,0}, // Ice flower
{13.2, 3.3, 0.8*7.5, 0, 0, -90}, // yellow cow
{13.0, 3.5, 0.8*7.1, 0, 0, -90}, // teal cow
{12.5,   5.0, 0.8*5.4, 0, 0, -90}, // red predator
{9.0,   4,   0.8*4.5, 0, 0, -90}}; // 6th species (not yet implemented)

boolean[][] IS_FOOD = { // can each species eat the others?
{false,false,false,false,false,false},
{false,false,false,false,false,false},
{true,false,false,false,false,false},
{false,true,false,false,false,false},
{false,false,true,true,false,false},
{false,false,false,false,true,false}};

float[] CALORIES_RATE = {1.35,1.35,1.00,1.00,0.80,1.0};
// what multiplier of calories does consuming each animal give? (multiplied by hunger level)

float WATER_CALORIES = 0.40;
float[] SPECIES_SPEED = {0.0, 0.0, 0.5, 0.52, 0.54, 1.00};
int ACTION_COUNT = 8; // jump, WASD, turn left, turn right, wander

Player closest_AI;
float[] camera = {0,0,0,0,0};
int TICK_BUCKET_COUNT = 20;
void setup(){
  map = new Map(SIZE);
  archive = new ArrayList<Record>(0);
  guts = new ArrayList<Gut>(0);

  players = new ArrayList<Player>(0);
  for(int i = 0; i < PLAYER_COUNT; i++){
    float dx = random(0,SIZE*T);
    float dy = random(0,SIZE*T);
    float[] coor = {dx,dy,-10,random(0,2*PI)};
    int species = -1;
    if(i >= 1){
      int index = (int)(((float)i)/PLAYER_COUNT*START_SPECIES.length);
      species = START_SPECIES[index];
    }
    Player newPlayer = new Player(species, coor, false, true, random(0.3333,0.6666), random(0.3333,0.6666), 0,"PRIMORDIAL");
    players.add(newPlayer);
  }
  
  keyHandler = new KeyHandler();
  size(1920,1080,P3D);
  
  r = (GLWindow)surface.getNative();
  if(TRAP_MOUSE){
    r.confinePointer(true);
    r.setPointerVisible(false);
  }
  g = createGraphics(1520,1080,P3D);
  ui = createGraphics(400,1080,P2D);
  clearUI();
  
  sfx = new SoundFile[sfx_names.length];
  for(int i = 0; i < sfx_names.length; i++){
    sfx[i] = new SoundFile(this, sfx_names[i]+".wav");
  }
  sfx[10].play();
  frameRate(FPS);
  ellipseMode(RADIUS);
  ui_title = loadImage("title.png");
}
void draw(){
  for(int i = 0; i < 1; i++){
    doMouse();
    doPhysics();
    doArchive();
    doGarbageRemoval();
  }
  
  drawVisuals();
  drawUI();
  background(255,0,255);
  
  image(g,0,0);
  image(ui,width-ui.width,0);
  drawCrosshairs();
  
  frames++;
}
void drawCrosshairs(){
  noStroke();
  fill(255);
  float W = 2;
  float L = 20;
  rect(g.width/2-W,g.height/2-L,W*2,L*2);
  rect(g.width/2-L,g.height/2-W,L*2,W*2);
}
int[] getPopulations(){
  int[] result = new int[SPECIES_COUNT];
  for(int s = 0; s < SPECIES_COUNT; s++){
    result[s] = 0;
  }
  for(int i = 0; i < players.size(); i++){
    int s = players.get(i).species;
    if(s >= 0){
      result[s]++;
    }
  }
  return result;
}

void doArchive(){
  if(ticks%ARCHIVE_EVERY != 0){
    return;
  }
  Record newRecord = new Record(getPopulations(), daylight());
  archive.add(newRecord);
  while(archive.size() > ARCHIVE_SIZE){
    archive.remove(0);
  }
}
String getNewName(){
  int len = (int)random(4.8,8);
  String[] lets = {"BCDFGHJKLMNPQRSTVWXZ","AEIOUY"};
  String result = "";
  boolean inversion = (random(1) < 0.5);
  
  for(int L = 0; L < len; L++){
    String options = lets[L%2];
    if(inversion){
      options = lets[1-L%2];
    }
    char let = options.charAt((int)random(options.length()));
    if(L >= 1){
      let = Character.toLowerCase(let);
    }
    result += let;
  }
  return result;
}
void doGarbageRemoval(){
  for(int i = players.size()-1; i >= 0; i--){
    Player p = players.get(i);
    if(p.toDie){
      Gut gut = new Gut(p.coor, ticks, p.species);
      guts.add(gut);
      players.remove(i);
    }
  }
  for(int i = guts.size()-1; i >= 0; i--){
    if(guts.get(i).toDie()){
      guts.remove(i);
    }
  }
}
double[] getArchiveRange(){
  double[] result = {999999999,-999999999};
  for(int i = 0; i < archive.size(); i++){
    for(int s = 0; s < SPECIES_COUNT; s++){
      int val = archive.get(i).populations[s];
      if(val < result[0]){
        result[0] = val;
      }
      if(val > result[1]){
        result[1] = val;
      }
    }
  }
  return result;
}

void drawUI(){
  double[] range = getArchiveRange();
  ui.beginDraw();
  if(closest_AI != null){
    closest_AI.trait.drawDisplay();
    ui.image(closest_AI.trait.display,0,ui_title.height);
  }
  ui.textSize(24);
  ui.strokeWeight(3);
  ui.textAlign(LEFT);
  
  if(archive.size() == 0){
    return;
  }
  Record archiveNow = archive.get(archive.size()-1);
  int[] species_order = new int[SPECIES_COUNT];
  boolean[] taken = new boolean[SPECIES_COUNT];
  for(int s = 0; s < SPECIES_COUNT; s++){
    taken[s] = false;
  }
  for(int spot = 0; spot < SPECIES_COUNT; spot++){
    int record = -1;
    int recordHolder = -1;
    for(int s = 0; s < SPECIES_COUNT; s++){
      if(taken[s]){
        continue;
      }
      if(archiveNow.populations[s] > record){
        record = archiveNow.populations[s];
        recordHolder = s;
      }
    }
    taken[recordHolder] = true;
    species_order[spot] = recordHolder;
  }
  
  float textY = 100000;
  for(int i = 0; i < archive.size()-1; i++){
    float x1 = i*340.0/(archive.size()-1);
    float x2 = (i+1)*340.0/(archive.size()-1);
    float y1 = DL_to_Y(archive.get(i).daylight);
    float y2 = DL_to_Y(archive.get(i+1).daylight);
    ui.stroke(128);
    ui.line(x1,y1,x2,y2);

    for(int spot = SPECIES_COUNT-1; spot >= 0; spot--){
      int s = species_order[spot];
      int val1 = archive.get(i).populations[s];
      int val2 = archive.get(i+1).populations[s];
      y1 = val_to_Y(val1, range);
      y2 = val_to_Y(val2, range);
      ui.stroke(SPECIES_COLORS[s]);
      ui.line(x1,y1,x2,y2);
      if(i == archive.size()-2){
        ui.fill(SPECIES_COLORS[s]);
        textY = min(textY-23,y2+6);
        ui.text(""+val2,x2+4,textY);
      }
    }
  }
  ui.image(ui_title,0,0);
  ui.fill(255);
  ui.textAlign(LEFT);
  ui.textSize(24);
  ui.text(nowToDateString(),10,ui.height-10);
  ui.endDraw();
}

String nowToDateString(){
  float days = ticks/TICKS_PER_DAY;
  
  int hour = (int)((days%1)*24);
  int minute = (int)((((days%1)*24)%1)*60)+1;
  String hourPiece = (hour%12 == 0 ? "12" : (hour%12)+"");
  String hourString = hourPiece+":"+nf(minute,2,0)+" "+((hour >= 12) ? "PM" : "AM");
  return "Day "+(int)(days+1)+" at "+hourString;
}

float daylight(){
  return 0.5-0.5*cos(ticksToDays(ticks)*(2*PI));
}

float DL_to_Y(double DL){
  return (float)(1020-200*DL);
}
float val_to_Y(double elev, double[] range){
  double ratio = (elev-range[0])/(range[1]-range[0]);
  return (float)(1020-200*ratio);
}
color colorLerp(color a, color b, float prog){
  float newR = red(a)+prog*(red(b)-red(a));
  float newG = green(a)+prog*(green(b)-green(a));
  float newB = blue(a)+prog*(blue(b)-blue(a));
  return color(newR, newG, newB);
}
void doPhysics(){
  for(int p = 0; p < playback_speed; p++){
    ticks++;
  }
  for(int i = 0; i < players.size(); i++){
    players.get(i).doActions(keyHandler);
  }
  for(int i = 0; i < players.size(); i++){
    players.get(i).doPhysics(map);
  }
  for(int i = 0; i < guts.size(); i++){
    guts.get(i).doPhysics();
  }
  if(!followSpecimen){
    getClosestAI();
  }
}
public double sigmoid(double input){
  return 1.0/(1.0+Math.pow(2.71828182846,-input));
}
void getClosestAI(){
  closest_AI = getClosestAIto(camera, players.get(0), 3.0*T);
}
Player getClosestAIto(float[] loc, Player ignore, float MAX_DIST){
  Player cAI = null;
  float record = 9999999;
  for(int i = 0; i < players.size(); i++){
    Player p = players.get(i);
    if(getSpeciesType(p.species) <= 0 || p == ignore){
      continue;
    }
    float dist_ = d_loop(players.get(i).coor, loc, false);
    if(dist_ < record){
      record = dist_;
      cAI = players.get(i);
    }
  }
  if(record >= MAX_DIST){
    cAI = null;
  }
  return cAI;
}

float d(float[] c1, float[] c2){
  return dist(c1[0],c1[1],c2[0],c2[1]);
}
float d_loop(float[] c1, float[] c2, boolean include_3rd){
  float dx = unloop(c1[0]-c2[0]);
  float dy = unloop(c1[1]-c2[1]);
  float dz = 0;
  if(include_3rd){
    dz = c1[2]-c2[2];
  }
  return dist(dx, dy, dz, 0, 0, 0);
}
float unloop(float val){
  while(val <= -SIZE*T/2){
    val += SIZE*T;
  }
  while(val > SIZE*T/2){
    val -= SIZE*T;
  }
  return val;
}
float unloop_arr(float val){
  while(val <= 0){
    val += SIZE*T;
  }
  while(val > SIZE*T){
    val -= SIZE*T;
  }
  return val;
}

int unloop_int(int val, int N){
  while(val < 0){
    val += N;
  }
  while(val >= N){
    val -= N;
  }
  return val;
}
float unloop_angle(float val){
  while(val <= -PI){
    val += PI*2;
  }
  while(val > PI){
    val -= PI*2;
  }
  return val;
}
float unloop_two(float val, float target){
  while(val-target <= -SIZE*T/2){
    val += SIZE*T;
  }
  while(val-target > SIZE*T/2){
    val -= SIZE*T;
  }
  return val;
}

boolean mapVisible(float[] coor){
    float dist_ = d_loop(camera, coor, true);
    if(dist_ < 3*T){
      return true;
    }
    int x = (int)min(max(coor[0]/T,0),SIZE-EPS);
    int y = (int)min(max(coor[1]/T,0),SIZE-EPS);
    return map.visible[x][y][0];
  }

void drawVisuals(){
  clearUI();
  g.beginDraw();
  g.sphereDetail(8);
  g.noStroke();
  g.lights();
  g.background(darken(SKY_COLOR,pow(daylight(),0.5)));
  g.pushMatrix();
  g.translate(g.width/2,g.height/2,0);
  for(int i = 0; i < players.size(); i++){
    if((!followSpecimen && players.get(i).species == -1) || 
    (followSpecimen && players.get(i) == closest_AI)){
      players.get(i).snapCamera(!followSpecimen);
    }
  }
  g.directionalLight(26, 51, 63, -0.934, -0.37, 0);
  g.directionalLight(26, 51, 63, 1.2, 0.55, 0);
  g.directionalLight(50, 50, 50, 0, 0, -1);
  map.drawMap();
  for(int i = 0; i < players.size(); i++){
    players.get(i).drawPlayer();
  }
  for(int i = 0; i < guts.size(); i++){
    guts.get(i).drawGut();
  }
  g.popMatrix();
  g.endDraw();
}

void clearUI(){
  ui.beginDraw();
  ui.background(0);
  ui.endDraw();
}

color darken(color c, float perc){
  float newR = red(c)*perc;
  float newG = green(c)*perc;
  float newB = blue(c)*perc;
  return color(newR, newG, newB);
}
float[] deepCopy(float[] input){
  float[] result = new float[input.length];
  for(int i = 0; i < input.length; i++){
    result[i] = input[i];
  }
  return result;
}
double[] deepCopy(double[] input){
  double[] result = new double[input.length];
  for(int i = 0; i < input.length; i++){
    result[i] = input[i];
  }
  return result;
}

void deepCopy(float[] input, float[] output){
  for(int i = 0; i < input.length; i++){
    output[i] = input[i];
  }
}

float[][] deepCopy(float[][] input){
  float[][] result = new float[input.length][input[0].length];
  for(int i = 0; i < input.length; i++){
    for(int j = 0; j < input[i].length; j++){
      result[i][j] = input[i][j];
    }
  }
  return result;
}

float ticksToDays(float age){
  return age/TICKS_PER_DAY;
}
void keyPressed(){
  keyHandler.handle(keyCode,true);
}
void keyReleased(){
  keyHandler.handle(keyCode,false);
}
void mousePressed() {
  sfx[5].play();
  /*g.pushMatrix();
  g.translate(width/2,height/2,0);
  for(int i = 0; i < players.size(); i++){
    players.get(i).snapCamera();
  }
  g.popMatrix();*/
}
void doMouse(){
  if(TRAP_MOUSE){
    if(frames >= 2){
      camera[3] += (mouseX-CENTER_X)*0.005;
      camera[4] += (mouseY-g.height/2)*0.005;
    }
    r.warpPointer(g.width/2,g.height/2);
  }
}
color color_lerp(color a, color b, float x){
  float newR = red(a)+(red(b)-red(a))*x;
  float newG = green(a)+(green(b)-green(a))*x;
  float newB = blue(a)+(blue(b)-blue(a))*x;
  return color(newR,newG,newB);
}
int getSpeciesType(int n){
  int[] IS_PLANT = {0,0,1,1,2,2};
  if(n == -1 || n == -2){
    return -1;
  }
  return IS_PLANT[n];
}
void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  if(e < -0.5){
    DISTANCE_FROM_PLAYER /= 1.1;
  }else if(e >= 0.5){
    DISTANCE_FROM_PLAYER *= 1.1;
  }
}
