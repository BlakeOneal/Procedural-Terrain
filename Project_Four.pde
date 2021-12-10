import controlP5.*;
ControlP5 cp5;

Slider Rows;
int numRows = 20;
Slider Columns;
int numCols = 20;
Slider TerrainSize;
float terrainSize = 20;

boolean isGenerated = false;
Button generate;

Textfield fileLoad;
String fileString;
Toggle useStroke;
boolean strokeUsed = true;
Toggle useColor;
boolean colorUsed;
Toggle useBlend;
boolean blendUsed;

Slider heightMod;
float heightModifier = 1.0;
Slider snowThresh;
float snowThreshold = 5.0;

boolean isSmoothed = false;
Button smooth;

Textlabel labelOne;
Textlabel labelTwo;
Textlabel labelThree;
Textlabel labelFour;
Textlabel labelFive;

float eyeY = 0;
float eyeZ = 0;
float camX = 0;
float camY = 0;
float camZ = 0;
float pMouseXPos;
float pMouseYPos;
float mouseXPos;
float mouseYPos;


void setup() {
  size(1200, 800, P3D);
  background(0, 0, 0);
  cp5 = new ControlP5(this);

  // Slider that controls the number of rows of polygons the terrain will have
  Rows = cp5.addSlider("numRows", 1, 100).setLabel("").setPosition(10, 10);
  labelOne = cp5.addLabel("Rows").setPosition(110, 10);

  // Slider that controls the number of columns of polygons the terrain will have
  Columns = cp5.addSlider("numCols", 1, 100).setLabel("").setPosition(10, 30);
  labelTwo = cp5.addLabel("Columns").setPosition(110, 30);

  // Slider that controls the overall size of the terrain (aka GRID SIZE)
  TerrainSize = cp5.addSlider("terrainSize", 20, 50).setLabel("").setPosition(10, 50);
  labelThree = cp5.addLabel("Terrain Size").setPosition(110, 50);

  // Button that generates terrain on click
  generate = cp5.addButton("Generate").setPosition(10, 80);

  // Takes in a file string from data folder, generates data based on color mapping
  fileLoad = cp5.addTextfield("fileString").setPosition(10, 110).setLabel("Load from file").setValue("terrain1").setAutoClear(false); 

  // Toggle for stroke being used when drawing triangles
  useStroke = cp5.addToggle("strokeUsed").setLabel("Stroke").setPosition(200, 10);

  // Toggle for color being used when drawing vertices, solid white by default
  useColor = cp5.addToggle("colorUsed").setLabel("Color").setPosition(250, 10);

  // Toggle to change between simple color or blending color between ranges based on vertex height
  useBlend = cp5.addToggle("blendUsed").setLabel("Blend").setPosition(300, 10);

  // Multiplier for vertex height
  heightMod = cp5.addSlider("heightModifier", -5.0, 5.0).setLabel("").setPosition(200, 50);
  labelFour = cp5.addLabel("Height Modifier").setPosition(300, 50);

  // How high a vertex must be to be considered "snow"
  snowThresh = cp5.addSlider("snowThreshold", 1.0, 5.0).setLabel("").setPosition(200, 70);
  labelFive = cp5.addLabel("Snow Threshold").setPosition(300, 70);
  
  smooth = cp5.addButton("Smooth").setPosition(360, 10);

  width = 1200;
  height = 800;
  perspective(radians(90), width/(float)height, 0.1, 1000);
}

class sphereCam {
  float eyeX = 10;
  float derX = eyeX * cos(radians(0.15)) * sin(radians(0.15));
  float derY = eyeX * cos(radians(0.15));
  float derZ = eyeX * sin(radians(0.15)) * sin(radians(0.15));
  float phi = 0;
  float theta = 0;

  void Update() {
    mouseXPos = mouseX;
    mouseYPos = mouseY;
    float deltaX = (mouseXPos - pMouseXPos) * 0.15f;
    float deltaY = (mouseYPos - pMouseYPos) * 0.15f;
    // Derived values when converting to spherical coords
    // radius = distance, mapped by zoom function
    float radius = eyeX;
    phi += deltaX;
    if (phi > 360) {
      phi = 360;
    }
    if (phi < 0) {
      phi = 0;
    }
    theta += deltaY;
    if (theta > 179) {
      theta = 179;
    }
    if (theta < 1) {
      theta = 1;
    }
    derX = radius * cos(radians(phi)) * sin(radians(theta));
    derY = radius * cos(radians(theta));
    derZ = radius * sin(radians(theta)) * sin(radians(phi));
    // Modify cam every frame (when this is called in draw()) 
    camera(derX, derY, derZ, 0, 0, 0, 0, 1, 0);
  }
  void zoom(float desiredZoom) {
    // Function that takes mouse scroll wheel input and modifies camera zoom
    desiredZoom *= 3;
    eyeX += desiredZoom;
    eyeY += desiredZoom;
    eyeZ += desiredZoom;
    // min value of radius
    if (eyeX < 10) {
      eyeX = 30;
      eyeY = 30;
      eyeZ = 30;
    }
    // max value of radius
    if (eyeX > 200) {
      eyeX = 200;
      eyeY = 200;
      eyeZ = 200;
    }
    float radius = eyeX;
    derX = radius * cos(radians(phi)) * sin(radians(theta));
    derY = radius * cos(radians(theta));
    derZ = radius * sin(radians(theta)) * sin(radians(phi));
    // Modify cam every frame (when this is called in draw()) 
    camera(derX, derY, derZ, 0, 0, 0, 0, 1, 0);
  }
}

sphereCam mainCam = new sphereCam();
ArrayList<PVector> vertices = new ArrayList<PVector>();
ArrayList<Integer> trianglePoints = new ArrayList<Integer>();
PImage imageLoaded;
String imageName;
boolean drawn = false;


void draw() {
  background(0, 0, 0);
  camera(mainCam.derX, mainCam.derY, mainCam.derZ, 0, 0, 0, 0, 1, 0);
  perspective(radians(90), width/(float)height, 0.1, 1000);
  pMouseXPos = mouseX;
  pMouseYPos = mouseY;
  // Draw terrain grid
  if(!drawn) {
    Generate();
    drawn = true;
  }
  beginShape(TRIANGLES);
  if(strokeUsed){
     stroke(0, 0, 0);
  }
  else{
    noStroke();
  }
  for (int i = 0; i < trianglePoints.size(); i++) {
    int vertIndex = trianglePoints.get(i);
    PVector vert = vertices.get(vertIndex);
     if(colorUsed) {
    float relativeHeight = abs(vert.y * heightModifier/(-1 * snowThreshold));
    color snow = color(255, 255, 255);
      color grass = color(143, 170, 64);
      color rock = color(135, 135, 135);
      color dirt = color(160, 126, 84);
      color water = color(0, 75, 200);
    if(relativeHeight >= 0.8) {
      // if blend is toggled, blend colors using lerp interpolation
      if(blendUsed) {
        float ratio = (relativeHeight - 0.8) / 0.2f;
        color fillColor = lerpColor(rock, snow, ratio);
        fill(fillColor);
      }
      // if not toggled, just fill with a specific color
      else{
      fill(snow);
      }
    }
    else if(relativeHeight < 0.8 &&  relativeHeight >= 0.4) {
      if(blendUsed){
        float ratio = (relativeHeight - 0.4f) / 0.4f;
        color fillColor = lerpColor(grass, rock, ratio);
        fill(fillColor);
      }
      else{
      fill(rock);
      }
    }
    else if(relativeHeight < 0.4 && relativeHeight >= 0.2) {
      if(blendUsed){
        float ratio = (relativeHeight - 0.2f) / 0.2f;
        color fillColor = lerpColor(dirt, grass, ratio);
        fill(fillColor);
      }
      else{
      fill(grass);
      }
    }
    else{
      if(blendUsed){
        float ratio = relativeHeight/ 0.2f;
        color fillColor = lerpColor(water, dirt, ratio);
        fill(fillColor);
      }
      else{
      fill(water);
      }
    }
  }
  else{
    fill(255, 255, 255);
  }
    vertex(-vert.x, vert.y * heightModifier, vert.z);
  }
  endShape();
  resetMatrix(); // Reset the "world" matrix
  camera(); // Reset world camera
  perspective(); // Reset the projection matrix
}

void mouseDragged() {
  // If the mouse is over GUI, do nothing
  if (cp5.isMouseOver()) {
    camera();
    perspective(); // Reset the projection matrix
    return;
  } else {
    // Else, update cam pos. based on x y offset
    mainCam.Update();
    camera();
    perspective(); // Reset the projection matrix
  }
}

void mouseWheel(MouseEvent event) {
  float count = event.getCount();
  mainCam.zoom(count);
  camera();
  perspective(); // Reset the projection matrix
}

// Array of vertices needed to make triangle grid
ArrayList<PVector> vertexSetup() {
  ArrayList<PVector> vertexData = new ArrayList<PVector>();
  float rowVal = -terrainSize/2.0f;
  float colVal = -terrainSize/2.0f;
  float rowSpace = terrainSize/numRows;
  float colSpace = terrainSize/numCols;
  // Make triangle vertice grid
  for (int i = 0; i <= numRows; i++) {
    for (int j = 0; j <= numCols; j++) {
      vertexData.add(new PVector(rowVal, 0, colVal));
      colVal += colSpace;
    }
    colVal = -terrainSize/2.0f;
    rowVal += rowSpace;
  }
  return vertexData;
}

// Array of the indices needed to make the triangle grid
ArrayList<Integer> triangleSetup() {
  ArrayList<Integer> triangleCoords = new ArrayList<Integer>();
  for (int i = 0; i < numRows; i++) {
    for (int j = 0; j < numCols; j++) {
      int startingIndex = i * (numCols + 1) + j;
      int secondIndex = startingIndex + 1;
      int thirdIndex = startingIndex + numCols + 1;
      triangleCoords.add(startingIndex);
      triangleCoords.add(secondIndex);
      triangleCoords.add(thirdIndex);
      int fourthIndex = startingIndex + 1;
      int fifthIndex = startingIndex + numCols + 2;
      int sixthIndex = startingIndex + numCols + 1;
      triangleCoords.add(fourthIndex);
      triangleCoords.add(fifthIndex);
      triangleCoords.add(sixthIndex);
    }
  }
  return triangleCoords;
}

// Runs on generate, initializes both ArrayLists
void Generate() {
  String fileName = fileLoad.getText();
  vertices = vertexSetup();
  trianglePoints = triangleSetup();
  if(fileName != null && drawn) {
    fileString(fileName);
  }
}
// If file is given, add .png and load the image, assigning proper height vals dependent on pixel
void fileString(String fileToOpen) {
  String file = fileToOpen + ".png";
  imageLoaded = loadImage(file);
  if(imageLoaded != null) {
  for(int i = 0; i <= numRows; i++) {
    for(int j = 0; j <= numCols; j++) {
      float x_index = map(j, 0, numCols + 1, 0, imageLoaded.width);
      float y_index = map(i, 0, numRows + 1, 0, imageLoaded.height);
      color colorGot= imageLoaded.get((int)x_index, (int)y_index);
      float heightFromColor = map(red(colorGot), 0, 255, 0, 1.0f);
      int vertex_index = i*(numCols + 1) + j;
      vertices.get(vertex_index).y = -heightFromColor;
    }
  }
  }
}

// Smooth out the image to reduce sharp edges
void Smooth() {
  ArrayList<PVector> smoothedCoords = new ArrayList<PVector>();
  for(int i = 0; i <= numRows; i++) {
    for(int j = 0; j <= numCols; j++) {
      int vertex_index = i*(numCols + 1) + j;
      smoothedCoords.add(vertices.get(vertex_index));
    }
  }
  for(int i = 0; i <= numRows; i++)
  {
    for(int j = 0; j <= numCols; j++) {
      int vertex_index = i*(numCols + 1) + j;
      if(i == 0 && j == 0) {
        float sampleOne = vertices.get(vertex_index + 1).y;
        float sampleTwo = vertices.get(vertex_index + numCols).y;
        float avg = (sampleOne + sampleTwo) / 2.0f;
        smoothedCoords.get(vertex_index).y = avg;
      }
      else if(i == 0 && j == numCols) {
        float sampleOne = vertices.get(vertex_index - 1).y;
        float sampleTwo = vertices.get(vertex_index + numCols).y;
        float avg = (sampleOne + sampleTwo) / 2.0f;
        smoothedCoords.get(vertex_index).y = avg;
      }
      else if(i == numRows && j == 0) {
        float sampleOne = vertices.get(vertex_index + 1).y;
        float sampleTwo = vertices.get(vertex_index - numCols).y;
        float avg = (sampleOne + sampleTwo) / 2.0f;
        smoothedCoords.get(vertex_index).y = avg;
      }
      else if(i == numRows && j == numCols) {
        float sampleOne = vertices.get(vertex_index - 1).y;
        float sampleTwo = vertices.get(vertex_index - numCols).y;
        float avg = (sampleOne + sampleTwo) / 2.0f;
        smoothedCoords.get(vertex_index).y = avg;
      }
      else if(j == 0) {
        // Right
        float sampleOne = vertices.get(vertex_index + 1).y;
        // Up
        float sampleTwo = vertices.get(vertex_index - numCols).y;
        // Down
        float sampleThree = vertices.get(vertex_index + numCols).y;
        float avg = (sampleOne + sampleTwo + sampleThree) / 3.0f;
        smoothedCoords.get(vertex_index).y = avg;
      }
      else if(j == numCols) {
        // Left
        float sampleOne = vertices.get(vertex_index - 1).y;
        // Up
        float sampleTwo = vertices.get(vertex_index - numCols).y;
        // Down
        float sampleThree = vertices.get(vertex_index + numCols).y;
        float avg = (sampleOne + sampleTwo + sampleThree) / 3.0f;
        smoothedCoords.get(vertex_index).y = avg;
      }
      else if(i == 0) {
        // Left
        float sampleOne = vertices.get(vertex_index - 1).y;
        // Right
        float sampleTwo = vertices.get(vertex_index + 1).y;
        // Down
        float sampleThree = vertices.get(vertex_index + numCols).y;
        float avg = (sampleOne + sampleTwo + sampleThree) / 3.0f;
        smoothedCoords.get(vertex_index).y = avg;
      }
      else if(i == numRows) {
        // Left
        float sampleOne = vertices.get(vertex_index - 1).y;
        // Right
        float sampleTwo = vertices.get(vertex_index + 1).y;
        // Up
        float sampleThree = vertices.get(vertex_index - numCols).y;
        float avg = (sampleOne + sampleTwo + sampleThree) / 3.0f;
        smoothedCoords.get(vertex_index).y = avg;
      }
      else{
        // Left
        float sampleOne = vertices.get(vertex_index - 1).y;
        // Right
        float sampleTwo = vertices.get(vertex_index + 1).y;
         // Up
        float sampleThree = vertices.get(vertex_index - numCols).y;
         // Down
        float sampleFour = vertices.get(vertex_index + numCols).y;
        float avg = (sampleOne + sampleTwo + sampleThree + sampleFour) / 4.0f;
        smoothedCoords.get(vertex_index).y = avg;
      }
    }
  }
  for(int i = 0; i <= numRows; i++) {
    for(int j = 0; j <= numCols; j++) {
      int vertex_index = i*(numCols + 1) + j;
      vertices.get(vertex_index).y = smoothedCoords.get(vertex_index).y;
    }
  }
  return;
}
