class Trait{
  float size;
  
  // hunger, thirst, reprod, flee, play
  float [] priorities;
  PGraphics display;
  int id;
  String name;
  int birth_tick;
  int generation;
  String parents;
  float bw;
  int mc = 0;
  int timeOfLastMeal = -99999;
  ArrayList<String> children;
  Player player;
  
  public Trait(Player p, boolean DETAILED, float startingHunger, float startingThirst){
    player = p;
    size = 0;
    if(DETAILED){
      priorities = new float[PRIORITY_NAMES.length];
      for(int i = 0; i < PRIORITY_NAMES.length; i++){
        priorities[i] = random(0,1);
      }
      priorities[0] = startingHunger;
      priorities[1] = startingThirst;
      priorities[2] = 1; // freakiness and playtime start at their lowest.
      priorities[3] = 1;
      priorities[5] = 1;
      display = createGraphics(400,700);
    }
    bw = startingHunger;
    birth_tick = ticks;
    children = new ArrayList<String>(0);
  }
  String getChildrenString(){
    if(children.size() == 0){
      return "0";
    }
    String result = children.size()+" (";
    for(int c = 0; c < children.size(); c++){
      result += children.get(c);
      if(c < children.size()-1){
        result += ", ";
      }
    }
    result += ")";
    return result;
  }
  
  String weightToString(float n){
    return nf(n*100,0,1)+" lbs";
  }
  void drawDisplay(){
    boolean[] RIGHT_SIDE = {true, true, false, false, false, false};
    int[] order = ArrayUtils.argsort(priorities, true);
    display.beginDraw();
    display.background(0);
    
    display.fill(80);
    display.rect(8,0,384,420,25);
    display.fill(255);
    display.textAlign(LEFT);
    display.textSize(36);
    display.text(name,15,36);
    display.textSize(18);
    String[] info = {"Creature #"+(id+1), "Generation "+(generation+1),
    "Birth weight: "+weightToString(bw),"Weight now: "+weightToString(priorities[0]),
    "Age: "+nf(ticksToDays(ticks-birth_tick),0,2)+" days","Parents: "+parents,
    "Children: "+getChildrenString(),"Meal Count: "+mc};
    
    
    for(int i = 0; i < info.length; i++){
      float y = (i%(info.length/2))*18+60;
      float x = ((i >= info.length/2) ? 205 : 15);
      display.text(info[i],x,y);
    }
    
    for(int i = 0; i < priorities.length; i++){
      int p = order[i];
      display.pushMatrix();
      display.translate(120,150+44*i);
      display.noStroke();
      
      float fullW = 250;
      float appW = (1-PRIORITY_CAPS[p])*fullW;
      if(i == 0){
        display.fill(255);
        display.rect(-3,-3,appW+6,36);
      }
      display.fill(0);
      display.rect(0,0,appW,30);
      display.fill(PRIORITY_COLORS[p]);
      float lineX = fullW*(1-priorities[p]);
      if(RIGHT_SIDE[p]){
        display.rect(lineX,0,appW-lineX,30);
      }else{
        display.rect(0,0,lineX,30);
      }
      
      display.textAlign(RIGHT);
      display.textSize(16);
      display.fill(255);
      display.text(PRIORITY_NAMES[p],-5,20);
      
      display.popMatrix();
    }
    display.endDraw();
  }
}
