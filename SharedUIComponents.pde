void drawBasePanels() {
  noStroke();
  fill(12);       
  rect(0, 0, width, topBarHeight); // Top Bar
  rect(0, topBarHeight, leftSidePanelWidth, height - topBarHeight); // Left Panel
  rect(width - rightSidePanelWidth, topBarHeight, rightSidePanelWidth, height - topBarHeight); // Right Panel
  
  // Visual workspace dividers
  fill(90);
  rect(leftSidePanelWidth, topBarHeight, 2, height - topBarHeight); 
  rect(width - rightSidePanelWidth - 2, topBarHeight, 2, height - topBarHeight); 
  rect(0, topBarHeight, width, 2); 
}

void drawCustomScrollbar(float x, float topY, float bottomY, float w, float contentHeight, float viewportHeight) {
  if (contentHeight <= viewportHeight) {
    leftScrollOffset = 0;
    return;
  }
  
  float trackHeight = bottomY - topY;
  float thumbHeight = (viewportHeight / contentHeight) * trackHeight;
  if (thumbHeight < 20) thumbHeight = 20; 
  
  fill(25, 30);
  noStroke();
  rect(x, topY, w, trackHeight, 3);
  
  float maxScroll = contentHeight - viewportHeight;
  float maxThumbTravel = trackHeight - thumbHeight;
  float thumbY = topY + (leftScrollOffset / maxScroll) * maxThumbTravel;
  
  if (draggingLeftScroll) {
    fill(120);
  } else if (mouseX >= x && mouseX <= x + w && mouseY >= thumbY && mouseY <= thumbY + thumbHeight) {
    fill(95);
  } else {
    fill(70);
  }
  
  rect(x, thumbY, w, thumbHeight, 3);
  
  if (draggingLeftScroll) {
    float deltaY = mouseY - dragScrollStartMouseY;
    float newThumbY = dragScrollStartThumbY + deltaY;
    
    if (newThumbY < topY) newThumbY = topY;
    if (newThumbY > topY + maxThumbTravel) newThumbY = topY + maxThumbTravel;
    
    leftScrollOffset = ((newThumbY - topY) / maxThumbTravel) * maxScroll;
  }
}

void updateDraggingLogic() {
  if (draggingLeft) {
    leftSidePanelWidth = mouseX;
    if (leftSidePanelWidth < 120) leftSidePanelWidth = 120;
    if (leftSidePanelWidth > width - rightSidePanelWidth - 100) {
      leftSidePanelWidth = width - rightSidePanelWidth - 100;
    }
  }
  if (draggingRight) {
    rightSidePanelWidth = width - mouseX;
    if (rightSidePanelWidth < 50) rightSidePanelWidth = 50;
    if (rightSidePanelWidth > width - leftSidePanelWidth - 100) {
      rightSidePanelWidth = width - leftSidePanelWidth - 100;
    }
  }
}

void mouseWheel(MouseEvent event) {
  float e = event.getCount();
  float totalContentHeight = visibleRows.size() * 20;
  
  // Left Panel Scroll checking
  if (mouseX > 0 && mouseX < leftSidePanelWidth && mouseY >= fileTreeTopY && mouseY <= fileTreeBottomY) {
    if (totalContentHeight > fileTreeHeightLimit) {
      leftScrollOffset += e * 20; 
      float maxScroll = totalContentHeight - fileTreeHeightLimit;
      if (leftScrollOffset < 0) leftScrollOffset = 0;
      if (leftScrollOffset > maxScroll) leftScrollOffset = maxScroll;
    }
    return;
  }
  
  // Main Panel Preview Mode vs Directory Scroll checking
  float workspaceX = leftSidePanelWidth + 20;
  float workspaceW = width - leftSidePanelWidth - rightSidePanelWidth - 40;
  
  if (mouseX >= workspaceX && mouseX <= workspaceX + workspaceW) {
    if (fileToPreview != null) {
      float viewH = height - (topBarHeight + 20) - 30;
      float textHeightLimit = viewH - 45;
      float totalTextHeight = previewLines.length * 18 + 20;
      if (totalTextHeight > textHeightLimit) {
        previewScrollOffset += e * 18;
        float maxScroll = totalTextHeight - textHeightLimit;
        if (previewScrollOffset < 0) previewScrollOffset = 0;
        if (previewScrollOffset > maxScroll) previewScrollOffset = maxScroll;
      }
    } else {
      float tableTopY = topBarHeight + 45;
      float tableHeightLimit = height - tableTopY - 30;
      float totalWorkHeight = visibleWorkspaceRows.size() * 22;
      if (totalWorkHeight > tableHeightLimit) {
        workspaceScrollOffset += e * 22;
        float maxScroll = totalWorkHeight - tableHeightLimit;
        if (workspaceScrollOffset < 0) workspaceScrollOffset = 0;
        if (workspaceScrollOffset > maxScroll) workspaceScrollOffset = maxScroll;
      }
    }
  }
}

void mousePressed() {
  // 1. Tab Interaction checks
  int tabX = 200;
  textSize(14);
  for (int i = 0; i < tabs.size(); i++) {
    String tab = (String) tabs.get(i);
    float widthOfTabText = textWidth(tab);
    float tabWidth = widthOfTabText + 3 * 2 + 17;
    float circleX = tabX + widthOfTabText + 3 * 2 + 7;
    float circleY = (topBarHeight + 3) / 2.0;
    float circleRadius = 5;
    
    if (dist(mouseX, mouseY, circleX, circleY) < circleRadius) {
      tabs.remove(i);
      return; 
    }
    tabX += tabWidth + 2;
  }
  
  // Intercept events differently if we are currently inside the File Content Preview Mode
  float workspaceX = leftSidePanelWidth + 20;
  float workspaceW = width - leftSidePanelWidth - rightSidePanelWidth - 40;
  float workspaceY = topBarHeight + 20;
  
  if (fileToPreview != null) {
    // Intercept Back Button Click
    if (mouseX >= workspaceX && mouseX <= workspaceX + 70 && mouseY >= workspaceY && mouseY <= workspaceY + 22) {
      fileToPreview = null;
      previewLines = new String[0];
      previewScrollOffset = 0;
      return;
    }
    
    // Preview Mode Scrollbar Drag Check
    float viewH = height - workspaceY - 30;
    float textHeightLimit = viewH - 45;
    float totalTextHeight = previewLines.length * 18 + 20;
    float scrollW = 8;
    float scrollX = workspaceX + workspaceW - scrollW - 5;
    float textTopY = workspaceY + 35;
    
    if (totalTextHeight > textHeightLimit) {
      float trackHeight = (textTopY + textHeightLimit - 5) - (textTopY + 5);
      float thumbHeight = (textHeightLimit / totalTextHeight) * trackHeight;
      if (thumbHeight < 20) thumbHeight = 20;
      float maxScroll = totalTextHeight - textHeightLimit;
      float maxThumbTravel = trackHeight - thumbHeight;
      float thumbY = (textTopY + 5) + (previewScrollOffset / maxScroll) * maxThumbTravel;
      
      if (mouseX >= scrollX && mouseX <= scrollX + scrollW && mouseY >= thumbY && mouseY <= thumbY + thumbHeight) {
        draggingWorkspaceScroll = true;
        dragWorkScrollStartMouseY = mouseY;
        dragWorkScrollStartThumbY = thumbY;
        return;
      }
    }
    return; // Block remaining file layout actions
  }
  
  // 2. Directory Custom Scrollbar interactions
  float scrollBarX = leftSidePanelWidth - 10;
  float scrollBarW = 8;
  float totalContentHeight = visibleRows.size() * 20;
  
  if (totalContentHeight > fileTreeHeightLimit) {
    float trackHeight = fileTreeBottomY - fileTreeTopY;
    float thumbHeight = (fileTreeHeightLimit / totalContentHeight) * trackHeight;
    if (thumbHeight < 20) thumbHeight = 20;
    
    float maxScroll = totalContentHeight - fileTreeHeightLimit;
    float maxThumbTravel = trackHeight - thumbHeight;
    float thumbY = fileTreeTopY + (leftScrollOffset / maxScroll) * maxThumbTravel;
    
    if (mouseX >= scrollBarX && mouseX <= scrollBarX + scrollBarW && mouseY >= thumbY && mouseY <= thumbY + thumbHeight) {
      draggingLeftScroll = true;
      dragScrollStartMouseY = mouseY;
      dragScrollStartThumbY = thumbY;
      return; 
    }
  }
  
  // 3. Side File Tree Navigation operations
  if (mouseX > 5 && mouseX < leftSidePanelWidth - 12 && mouseY >= (fileTreeTopY - 15) && mouseY < fileTreeBottomY) {
    for (int i = 0; i < visibleRows.size(); i++) {
      RenderRow row = (RenderRow) visibleRows.get(i);
      if (mouseY >= row.y - 8 && mouseY <= row.y + 12) {
        boolean arrowClicked = (mouseX >= row.indent - 12 && mouseX <= row.indent);
        
        if (row.node.isFolder) {
          if (arrowClicked) {
            row.node.isExpanded = !row.node.isExpanded;
          } else {
            boolean isDoubleClick = (row.node == lastClickedNode && millis() - lastClickTime < 300);
            if (isDoubleClick) {
              row.node.isExpanded = !row.node.isExpanded;
            } else {
              boolean ctrlPressed = (keyPressed && keyCode == CONTROL);
              if (ctrlPressed) {
                if (selectedNodes.contains(row.node)) {
                  selectedNodes.remove(row.node);
                } else {
                  selectedNodes.add(row.node);
                }
              } else {
                selectedNodes.clear();
                selectedNodes.add(row.node);
              }
            }
            lastClickedNode = row.node;
            lastClickTime = millis();
          }
          
          float newTotalHeight = visibleRows.size() * 20;
          if (newTotalHeight <= fileTreeHeightLimit) {
            leftScrollOffset = 0;
          } else if (leftScrollOffset > newTotalHeight - fileTreeHeightLimit) {
            leftScrollOffset = newTotalHeight - fileTreeHeightLimit;
          }
          return;
        }
      }
    }
  }
  
  // 4. Main Workspace Scrollbar Interaction check
  float tableTopY = topBarHeight + 45;
  float tableHeightLimit = height - tableTopY - 30;
  float totalWorkHeight = visibleWorkspaceRows.size() * 22;
  float scrollW = 8;
  float scrollX = workspaceX + workspaceW - scrollW - 5;
  
  if (totalWorkHeight > tableHeightLimit) {
    float trackHeight = (tableTopY + tableHeightLimit) - tableTopY;
    float thumbHeight = (tableHeightLimit / totalWorkHeight) * trackHeight;
    if (thumbHeight < 20) thumbHeight = 20;
    float maxScroll = totalWorkHeight - tableHeightLimit;
    float maxThumbTravel = trackHeight - thumbHeight;
    float thumbY = tableTopY + (workspaceScrollOffset / maxScroll) * maxThumbTravel;
    
    if (mouseX >= scrollX && mouseX <= scrollX + scrollW && mouseY >= thumbY && mouseY <= thumbY + thumbHeight) {
      draggingWorkspaceScroll = true;
      dragWorkScrollStartMouseY = mouseY;
      dragWorkScrollStartThumbY = thumbY;
      return;
    }
  }

  // 5. Main Workspace Row Item Interaction check
  if (mouseX >= workspaceX && mouseX <= workspaceX + workspaceW - scrollW && mouseY >= tableTopY + 22 && mouseY < tableTopY + tableHeightLimit) {
    for (int i = 0; i < visibleWorkspaceRows.size(); i++) {
      WorkspaceRow row = (WorkspaceRow) visibleWorkspaceRows.get(i);
      if (mouseY >= row.y && mouseY < row.y + 22) {
        boolean isDoubleClick = (row.file == lastClickedFile && millis() - lastFileClickTime < 300);
        
        if (isDoubleClick) {
          if (row.isDirectory) {
            // Traverse inside directory
            FileNode targetNode = null;
            if (currentViewedNode != null) {
              currentViewedNode.populate();
              for (int j = 0; j < currentViewedNode.children.size(); j++) {
                FileNode child = (FileNode) currentViewedNode.children.get(j);
                if (child.file != null && child.file.getAbsolutePath().equals(row.file.getAbsolutePath())) {
                  targetNode = child;
                  break;
                }
              }
            }
            if (targetNode == null) {
              targetNode = new FileNode(row.file, row.file.getName(), true);
            }
            
            selectedNodes.clear();
            selectedNodes.add(targetNode);
            targetNode.isExpanded = true;
            workspaceScrollOffset = 0; 
          } else {
            // Double clicked a file -> Load and open file content string array
            fileToPreview = row.file;
            try {
              previewLines = loadStrings(row.file.getAbsolutePath());
              if (previewLines == null) {
                previewLines = new String[] { "Error loading file content or file is empty." };
              }
            } catch (Exception e) {
              previewLines = new String[] { "Access denied: Failed to parse file content details." };
            }
            previewScrollOffset = 0;
          }
        } else {
          // Standard Single Click Selection Math
          boolean ctrlPressed = (keyPressed && keyCode == CONTROL);
          if (ctrlPressed) {
            if (selectedFiles.contains(row.file)) selectedFiles.remove(row.file);
            else selectedFiles.add(row.file);
          } else {
            selectedFiles.clear();
            selectedFiles.add(row.file);
          }
        }
        lastClickedFile = row.file;
        lastFileClickTime = millis();
        return;
      }
    }
  }
  
  // 6. Panel dragging anchors Check
  if (abs(mouseX - leftSidePanelWidth) < dragThreshold && mouseY > topBarHeight) {
    draggingLeft = true;
  } else if (abs(mouseX - (width - rightSidePanelWidth)) < dragThreshold && mouseY > topBarHeight) {
    draggingRight = true;
  }
}

void mouseReleased() {
  draggingLeft = false;
  draggingRight = false;
  draggingLeftScroll = false;
  draggingWorkspaceScroll = false;
}
