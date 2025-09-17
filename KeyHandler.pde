class KeyHandler{
  int[] KEYS = {65,87,68,83,32,16,10,67};
  int LEN = KEYS.length;
  boolean[] keysDown = new boolean[LEN];
  public KeyHandler(){
    for(int i = 0; i < LEN; i++){
      keysDown[i] = false;
    }
  }
  void handle(int k, boolean state){
    for(int i = 0; i < LEN; i++){
      if(KEYS[i] == k){
        keysDown[i] = state;
      }
      if(i == 6 && KEYS[i] == k && state){ // ENTER to toggle mouse lock
        TRAP_MOUSE = !TRAP_MOUSE;
        r.confinePointer(TRAP_MOUSE);
        r.setPointerVisible(!TRAP_MOUSE);
      }
      if(i == 7 && KEYS[i] == k && state){
        followSpecimen = !followSpecimen;
      }
    }
  }
}
