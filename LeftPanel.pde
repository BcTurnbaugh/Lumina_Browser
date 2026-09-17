class FileNode {
  File file;
  String name;
  boolean isExpanded = false;
  boolean isFolder = true;
  boolean isLoaded = false; 
  ArrayList children = new ArrayList();
  
  FileNode(File file, String name, boolean isFolder) {
    this.file = file;
    this.name = name;
    this.isFolder = isFolder;
  }
  
  void addChild(FileNode child) {
    children.add(child);
  }
  
  void populate() {
    if (isLoaded || !isFolder || file == null) return;
    
    try {
      File[] subFiles = file.listFiles();
      if (subFiles != null) {
        for (File f : subFiles) {
          if (f.isDirectory() && !f.isHidden()) {
            children.add(new FileNode(f, f.getName(), true));
          }
        }
      }
    } catch (SecurityException e) {
      System.err.println("Access restricted: " + file.getAbsolutePath());
    }
    
    isLoaded = true;
  }
}

class RenderRow {
  FileNode node;
  int depth;
  float y;
  float indent;
  
  RenderRow(FileNode node, int depth, float y, float indent) {
    this.node = node;
    this.depth = depth;
    this.y = y;
    this.indent = indent;
  }
}

void buildFileTree() {
  fileTreeRoot = new FileNode(null, "This PC", true);
  File[] roots = File.listRoots();
  if (roots != null) {
    for (File r : roots) {
      String driveLabel = r.getPath();
      if (driveLabel.equals("/")) {
        driveLabel = "This PC (/)";
      }
      fileTreeRoot.addChild(new FileNode(r, driveLabel, true));
    }
  }
  fileTreeRoot.isExpanded = true;
  fileTreeRoot.populate();
}

void drawLeftPanel() {
  visibleRows.clear();
  buildVisibleRows(fileTreeRoot, 0, fileTreeTopY - leftScrollOffset);
  
  float totalContentHeight = visibleRows.size() * 20; 
  
  for (int i = 0; i < visibleRows.size(); i++) {
    RenderRow row = (RenderRow) visibleRows.get(i);
    if (row.y >= fileTreeTopY - 15 && row.y < fileTreeBottomY) {
      drawFileNode(row.node, row.depth, row.y, row.indent);
    }
  }
  
  // Mask background panels to cleanly overlay and hide scroll overflow
  fill(12);
  noStroke();
  rect(0, halfLeftHeight - 1, leftSidePanelWidth, height - halfLeftHeight); 
  rect(0, topBarHeight + 2, leftSidePanelWidth, fileTreeTopY - topBarHeight - 12); 
  
  fill(90);
  rect(0, halfLeftHeight - 1, leftSidePanelWidth, 2); 
  
  // Panel Headers
  fill(255);
  textSize(14);
  textAlign(CENTER, CENTER);
  text("Folders", leftSidePanelWidth / 2.0, topBarHeight + 12); 
  
  // Render Custom Scrollbar Target
  float scrollBarX = leftSidePanelWidth - 10;
  float scrollBarW = 8;
  drawCustomScrollbar(scrollBarX, fileTreeTopY, fileTreeBottomY, scrollBarW, totalContentHeight, fileTreeHeightLimit);
}

float buildVisibleRows(FileNode node, int depth, float startY) {
  float currentY = startY;
  float indent = 15 + (depth * 15);
  
  if (node != fileTreeRoot) {
    visibleRows.add(new RenderRow(node, depth, currentY, indent));
    currentY += 20;
  }
  
  if (node == fileTreeRoot || (node.isFolder && node.isExpanded)) {
    node.populate(); 
    for (int i = 0; i < node.children.size(); i++) {
      FileNode child = (FileNode) node.children.get(i);
      int nextDepth = (node == fileTreeRoot) ? depth : depth + 1;
      currentY = buildVisibleRows(child, nextDepth, currentY); 
    }
  }
  return currentY;
}

void drawFileNode(FileNode node, int depth, float y, float indent) {
  boolean isHovered = mouseX > 5 && mouseX < leftSidePanelWidth - 15 && mouseY >= y - 8 && mouseY <= y + 8;
  boolean isSelected = selectedNodes.contains(node);
  
  if (isSelected) {
    fill(41, 128, 185, 100); 
    noStroke();
    rect(5, y - 9, leftSidePanelWidth - 15, 18, 4);
  } else if (isHovered) {
    fill(50);
    noStroke();
    rect(5, y - 9, leftSidePanelWidth - 15, 18, 4);
  }
  
  if (node.isFolder) {
    fill(180);
    pushMatrix();
    translate(indent - 6, y);
    if (node.isExpanded) {
      triangle(-3, -2, 3, -2, 0, 2); 
    } else {
      triangle(-2, -3, -2, 3, 2, 0); 
    }
    popMatrix();
  }
  
  fill(240, 196, 15);
  rect(indent + 2, y - 4, 8, 8, 1);
  
  fill(255);
  textAlign(LEFT, CENTER);
  textSize(12);
  
  String displayName = node.name;
  float maxTextWidth = leftSidePanelWidth - indent - 30;
  if (textWidth(displayName) > maxTextWidth) {
    while (displayName.length() > 3 && textWidth(displayName + "...") > maxTextWidth) {
      displayName = displayName.substring(0, displayName.length() - 1);
    }
    displayName += "...";
  }
  
  text(displayName, indent + 15, y);
}
