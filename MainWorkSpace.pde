import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Collections;
import java.util.Comparator;

// Workspace Scrolling and View States
float workspaceScrollOffset = 0;
boolean draggingWorkspaceScroll = false;
float dragWorkScrollStartMouseY = 0;
float dragWorkScrollStartThumbY = 0;

// Main Workspace selection tracking
ArrayList selectedFiles = new ArrayList();
File lastClickedFile = null;
int lastFileClickTime = 0;

// Path History / Currently viewed directory node reference
FileNode currentViewedNode = null;

// File Previewer View Mode States
File fileToPreview = null;
String[] previewLines = new String[0];
float previewScrollOffset = 0;

// Flat storage list for items inside the currently viewed folder
ArrayList visibleWorkspaceRows = new ArrayList();

class WorkspaceRow {
  File file;
  float y;
  boolean isDirectory;
  String name;
  String sizeText;
  
  WorkspaceRow(File file, String name, boolean isDirectory, String sizeText) {
    this.file = file;
    this.name = name;
    this.isDirectory = isDirectory;
    this.sizeText = sizeText;
  }
}

void drawMainWorkspace() {
  float workspaceX = leftSidePanelWidth + 20;
  float workspaceY = topBarHeight + 20;
  float workspaceW = width - leftSidePanelWidth - rightSidePanelWidth - 40;
  
  // Update viewed directory dynamically based on what is selected in the Sidebar Tree
  if (!selectedNodes.isEmpty() && fileToPreview == null) {
    currentViewedNode = (FileNode) selectedNodes.get(selectedNodes.size() - 1); 
  }
  
  if (currentViewedNode == null && fileToPreview == null) {
    fill(130);
    textAlign(CENTER, CENTER);
    textSize(16);
    text("No folder selected.\nClick a folder in the sidebar list to inspect.", 
         leftSidePanelWidth + (width - leftSidePanelWidth - rightSidePanelWidth) / 2.0, height / 2.0);
    return;
  }
  
  // Render File Content Preview Mode if a file is loaded
  if (fileToPreview != null) {
    drawFilePreviewContent(workspaceX, workspaceY, workspaceW);
    return;
  }
  
  // --- DIRECTORY BROWSER MODE ---
  
  // 1. RENDER CURRENT FILE PATH HIERARCHY BAR AT VERY TOP
  String pathString = (currentViewedNode.file != null) ? currentViewedNode.file.getAbsolutePath() : "This PC";
  fill(180);
  textSize(12);
  textAlign(LEFT, TOP);
  text("📍 " + pathString, workspaceX, workspaceY);
  
  // Dimensions for the actual Data Table (Calculated with top spacing for path bar)
  float tableTopY = workspaceY + 25; 
  float tableHeightLimit = height - tableTopY - 30;
  float headerHeight = 22;
  float rowHeight = 22;
  float contentStartY = tableTopY + headerHeight;
  
  // 2. REBUILD VISIBLE WORKSPACE ROWS CACHE
  visibleWorkspaceRows.clear();
  ArrayList directories = new ArrayList();
  ArrayList files = new ArrayList();
  
  if (currentViewedNode.file != null) {
    try {
      File[] children = currentViewedNode.file.listFiles();
      if (children != null) {
        for (File f : children) {
          if (!f.isHidden()) {
            if (f.isDirectory()) directories.add(f);
            else files.add(f);
          }
        }
      }
    } catch (SecurityException e) {
      // Access Restricted container placeholder
    }
  } else {
    File[] roots = File.listRoots();
    if (roots != null) {
      for (File r : roots) directories.add(r);
    }
  }
  
  // Sort alphabetically
  Comparator alphaCompare = new Comparator() {
    public int compare(Object aObj, Object bObj) { 
      File a = (File) aObj;
      File b = (File) bObj;
      return a.getName().compareToIgnoreCase(b.getName()); 
    }
  };
  Collections.sort(directories, alphaCompare);
  Collections.sort(files, alphaCompare);
  
  float currentY = contentStartY - workspaceScrollOffset;
  
  // Append directories
  for (int i = 0; i < directories.size(); i++) {
    File f = (File) directories.get(i);
    String dName = (f.getParent() == null) ? f.getPath() : f.getName();
    visibleWorkspaceRows.add(new WorkspaceRow(f, dName, true, ""));
  }
  // Append files
  for (int i = 0; i < files.size(); i++) {
    File f = (File) files.get(i);
    visibleWorkspaceRows.add(new WorkspaceRow(f, f.getName(), false, formatFileSize(f.length())));
  }
  
  // Assign rendering coordinate paths dynamically
  for (int i = 0; i < visibleWorkspaceRows.size(); i++) {
    WorkspaceRow row = (WorkspaceRow) visibleWorkspaceRows.get(i);
    row.y = currentY;
    currentY += rowHeight;
  }
  
  float totalContentHeight = visibleWorkspaceRows.size() * rowHeight;
  
  // 3. RENDER THE SCROLLABLE CONTENT ROWS
  textSize(12);
  for (int i = 0; i < visibleWorkspaceRows.size(); i++) {
    WorkspaceRow row = (WorkspaceRow) visibleWorkspaceRows.get(i);
    if (row.y >= contentStartY - 5 && row.y < tableTopY + tableHeightLimit) {
      
      boolean isSelected = selectedFiles.contains(row.file);
      boolean isHovered = mouseX >= workspaceX && mouseX <= workspaceX + workspaceW && 
                          mouseY >= row.y && mouseY < row.y + rowHeight;
                          
      if (isSelected) {
        fill(41, 128, 185, 100); 
        rect(workspaceX, row.y, workspaceW, rowHeight, 2);
      } else if (isHovered) {
        fill(60); 
        rect(workspaceX, row.y, workspaceW, rowHeight, 2);
      }
      
      // Split the column widths in half (50% split)
      float columnWidth = workspaceW * 0.50;
      
      // Column 1: Name (0% to 50%)
      if (row.isDirectory) fill(240, 196, 15); 
      else fill(200, 214, 229); 
      
      textAlign(LEFT, CENTER);
      String displayName = row.name;
      float maxNameWidth = columnWidth - 25;
      if (textWidth(displayName) > maxNameWidth) {
        while (displayName.length() > 3 && textWidth(displayName + "...") > maxNameWidth) {
          displayName = displayName.substring(0, displayName.length() - 1);
        }
        displayName += "...";
      }
      text((row.isDirectory ? "📁  " : "📄  ") + displayName, workspaceX + 5, row.y + rowHeight/2.0);
      
      // Column 2: Size (50% to 100%)
      fill(160);
      text(row.sizeText, workspaceX + columnWidth + 10, row.y + rowHeight/2.0);
    }
  }
  
  // 4. MASKING OVERFLOWS
  fill(43); noStroke();
  rect(workspaceX - 5, topBarHeight + 2, workspaceW + 10, tableTopY - topBarHeight - 2); 
  rect(workspaceX - 5, tableTopY + tableHeightLimit, workspaceW + 10, height); 
  
  // 5. FROZEN HEADINGS BAR (Drawn to cleanly overlay scrolled rows)
  fill(53); stroke(75); strokeWeight(1);
  rect(workspaceX, tableTopY, workspaceW, headerHeight, 3);
  noStroke();
  
  // Header text markers aligned to 50% split
  fill(255); textSize(11); textFont(createFont("SansSerif", 11, true));
  textAlign(LEFT, CENTER);
  text("Name", workspaceX + 8, tableTopY + headerHeight/2.0);
  text("Size", workspaceX + (workspaceW * 0.50) + 10, tableTopY + headerHeight/2.0);
  
  // 6. RENDER WORKSPACE CUSTOM SCROLLBAR
  float scrollW = 8;
  float scrollX = workspaceX + workspaceW - scrollW - 5; 
  drawWorkspaceScrollbar(scrollX, contentStartY, tableTopY + tableHeightLimit, scrollW, totalContentHeight, tableHeightLimit - headerHeight);
}

// Sub-view: Draws File contents directly in the main panel with custom header options
void drawFilePreviewContent(float x, float y, float w) {
  float viewH = height - y - 30;
  
  // Draw header back button path bar
  fill(100, 110, 120);
  rect(x, y, 70, 22, 4);
  fill(255);
  textSize(11);
  textAlign(CENTER, CENTER);
  text("← Back", x + 35, y + 11);
  
  textAlign(LEFT, CENTER);
  fill(180);
  text("📄 " + fileToPreview.getAbsolutePath(), x + 85, y + 11);
  
  float textTopY = y + 35;
  float textHeightLimit = viewH - 45;
  
  // Drawing base text bounding container box
  fill(30);
  rect(x, textTopY, w, textHeightLimit, 4);
  
  // Draw file contents
  fill(240);
  textSize(12);
  textAlign(LEFT, TOP);
  
  float currentY = textTopY + 10 - previewScrollOffset;
  for (int i = 0; i < previewLines.length; i++) {
    if (currentY >= textTopY + 5 && currentY < textTopY + textHeightLimit - 20) {
      text(previewLines[i], x + 12, currentY);
    }
    currentY += 18;
  }
  
  float totalTextHeight = previewLines.length * 18 + 20;
  
  // Render file viewer scrollbar
  float scrollW = 8;
  float scrollX = x + w - scrollW - 5;
  drawPreviewScrollbar(scrollX, textTopY + 5, textTopY + textHeightLimit - 5, scrollW, totalTextHeight, textHeightLimit - 10);
  
  // Mask boundary panels to preserve visual scope
  fill(43); noStroke();
  rect(x - 5, y - 5, w + 10, 38);
  rect(x - 5, textTopY + textHeightLimit, w + 10, height);
}

// File preview scrolling bar mathematics helper
void drawPreviewScrollbar(float x, float topY, float bottomY, float w, float contentHeight, float viewportHeight) {
  if (contentHeight <= viewportHeight) {
    previewScrollOffset = 0;
    return;
  }
  
  float trackHeight = bottomY - topY;
  float thumbHeight = (viewportHeight / contentHeight) * trackHeight;
  if (thumbHeight < 20) thumbHeight = 20; 
  
  fill(25, 30);
  rect(x, topY, w, trackHeight, 3);
  
  float maxScroll = contentHeight - viewportHeight;
  float maxThumbTravel = trackHeight - thumbHeight;
  float thumbY = topY + (previewScrollOffset / maxScroll) * maxThumbTravel;
  
  if (draggingWorkspaceScroll) fill(120);
  else if (mouseX >= x && mouseX <= x + w && mouseY >= thumbY && mouseY <= thumbY + thumbHeight) fill(95);
  else fill(70);
  
  rect(x, thumbY, w, thumbHeight, 3);
  
  if (draggingWorkspaceScroll) {
    float deltaY = mouseY - dragWorkScrollStartMouseY;
    float newThumbY = dragWorkScrollStartThumbY + deltaY;
    if (newThumbY < topY) newThumbY = topY;
    if (newThumbY > topY + maxThumbTravel) newThumbY = topY + maxThumbTravel;
    
    previewScrollOffset = ((newThumbY - topY) / maxThumbTravel) * maxScroll;
  }
}

String formatFileSize(long bytes) {
  if (bytes < 1024) return bytes + " B";
  int exp = (int) (Math.log(bytes) / Math.log(1024));
  String pre = "KMGTPE".charAt(exp-1) + "";
  return String.format("%.1f %sB", bytes / Math.pow(1024, exp), pre);
}

void drawWorkspaceScrollbar(float x, float topY, float bottomY, float w, float contentHeight, float viewportHeight) {
  if (contentHeight <= viewportHeight) {
    workspaceScrollOffset = 0;
    return;
  }
  
  float trackHeight = bottomY - topY;
  float thumbHeight = (viewportHeight / contentHeight) * trackHeight;
  if (thumbHeight < 20) thumbHeight = 20; 
  
  fill(25, 30);
  rect(x, topY, w, trackHeight, 3);
  
  float maxScroll = contentHeight - viewportHeight;
  float maxThumbTravel = trackHeight - thumbHeight;
  float thumbY = topY + (workspaceScrollOffset / maxScroll) * maxThumbTravel;
  
  if (draggingWorkspaceScroll) fill(120);
  else if (mouseX >= x && mouseX <= x + w && mouseY >= thumbY && mouseY <= thumbY + thumbHeight) fill(95);
  else fill(70);
  
  rect(x, thumbY, w, thumbHeight, 3);
  
  if (draggingWorkspaceScroll) {
    float deltaY = mouseY - dragWorkScrollStartMouseY;
    float newThumbY = dragWorkScrollStartThumbY + deltaY;
    if (newThumbY < topY) newThumbY = topY;
    if (newThumbY > topY + maxThumbTravel) newThumbY = topY + maxThumbTravel;
    
    workspaceScrollOffset = ((newThumbY - topY) / maxThumbTravel) * maxScroll;
  }
}
