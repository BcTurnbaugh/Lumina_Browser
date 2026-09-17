import java.text.SimpleDateFormat;
import java.util.Date;

void drawRightPanel() {
  float panelX = width - rightSidePanelWidth + 20;
  float panelY = topBarHeight + 20;
  float panelW = rightSidePanelWidth - 40;
  
  // 1. RENDER PANEL TITLE HEADER
  fill(255);
  textSize(15);
  textAlign(LEFT, TOP);
  text("Properties", panelX, panelY);
  
  stroke(90);
  strokeWeight(1);
  line(panelX, panelY + 25, panelX + panelW, panelY + 25);
  noStroke();
  
  float contentY = panelY + 40;
  
  // 2. CHOOSE TARGET ITEM TO INSPECT (Selected file has priority, falls back to viewed directory)
  File inspectFile = null;
  boolean isFolder = false;
  
  if (selectedFiles != null && !selectedFiles.isEmpty()) {
    inspectFile = (File) selectedFiles.get(selectedFiles.size() - 1);
    isFolder = inspectFile.isDirectory();
  } else if (currentViewedNode != null && currentViewedNode.file != null) {
    inspectFile = currentViewedNode.file;
    isFolder = true;
  }
  
  // Fallback if nothing is selected or active
  if (inspectFile == null) {
    fill(130);
    textSize(12);
    textAlign(CENTER, CENTER);
    text("Select a file or folder\nto view its details here.", width - rightSidePanelWidth / 2.0, height / 2.0);
    return;
  }
  
  // 3. DRAW CUSTOM SELECTION VECTOR GRAPHIC ICON
  float iconX = panelX + panelW / 2.0;
  float iconY = contentY + 25;
  
  if (isFolder) {
    // Warm Yellow Folder Icon
    fill(240, 196, 15);
    rect(iconX - 25, iconY - 20, 50, 40, 4);
    // Folder Tab
    rect(iconX - 25, iconY - 25, 20, 8, 2);
  } else {
    // Silver/Blue File Document Icon
    fill(180, 190, 200);
    rect(iconX - 20, iconY - 25, 40, 50, 4);
    // Mimic written text lines on file
    fill(43);
    rect(iconX - 12, iconY - 12, 24, 3, 1);
    rect(iconX - 12, iconY - 4, 24, 3, 1);
    rect(iconX - 12, iconY + 4, 16, 3, 1);
  }
  
  contentY += 65;
  
  // 4. DISPLAY ACCENTED FILE/FOLDER NAME Label
  fill(255);
  textSize(13);
  textFont(createFont("SansSerif-Bold", 13, true));
  textAlign(CENTER, TOP);
  
  String name = (inspectFile.getParent() == null) ? inspectFile.getPath() : inspectFile.getName();
  float maxLabelW = panelW;
  if (textWidth(name) > maxLabelW) {
    while (name.length() > 3 && textWidth(name + "...") > maxLabelW) {
      name = name.substring(0, name.length() - 1);
    }
    name += "...";
  }
  text(name, panelX + panelW / 2.0, contentY);
  
  contentY += 35;
  
  // 5. METADATA PROPERTY GRID (Left labels, Right values)
  textSize(11);
  textFont(createFont("SansSerif", 11, true));
  textAlign(LEFT, TOP);
  
  // Row 1: Type Description
  fill(140);
  text("Type:", panelX, contentY);
  fill(220);
  text(isFolder ? "File Folder" : "Standard File Document", panelX + 70, contentY);
  contentY += 24;
  
  // Row 2: File/Directory Size
  fill(140);
  text("Size:", panelX, contentY);
  fill(220);
  String sizeText = isFolder ? getFolderContentsCount(inspectFile) : formatFileSize(inspectFile.length());
  text(sizeText, panelX + 70, contentY);
  contentY += 24;
  
  // Row 3: Absolute Storage Path Link
  fill(140);
  text("Location:", panelX, contentY);
  fill(180);
  String path = inspectFile.getAbsolutePath();
  float maxPathW = panelW - 70;
  if (textWidth(path) > maxPathW) {
    while (path.length() > 3 && textWidth("..." + path) > maxPathW) {
      path = path.substring(1);
    }
    path = "..." + path;
  }
  text(path, panelX + 70, contentY);
  contentY += 24;
  
  // Row 4: OS Date Last Modified
  fill(140);
  text("Modified:", panelX, contentY);
  fill(220);
  long lastModifiedTime = inspectFile.lastModified();
  Date date = new Date(lastModifiedTime);
  SimpleDateFormat formatter = new SimpleDateFormat("MM/dd/yyyy hh:mm a");
  text(formatter.format(date), panelX + 70, contentY);
}

// Helper: Safely reads children metrics from directories
String getFolderContentsCount(File f) {
  try {
    File[] children = f.listFiles();
    if (children != null) {
      int count = 0;
      for (File child : children) {
        if (!child.isHidden()) count++;
      }
      return count + " items";
    }
  } catch (SecurityException e) {
    return "[Access Restricted]";
  }
  return "0 items";
}
