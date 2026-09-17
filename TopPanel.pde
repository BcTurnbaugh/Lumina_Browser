void drawTopPanel(int currentCursorState) {
  // Branding Text
  textSize(20);
  fill(255);
  textAlign(LEFT, CENTER);
  text("Lumina Browser", 25, topBarHeight / 2.0);
  
  // Render Dynamic Tabs Engine
  int tabX = 200; 
  textSize(14);
  
  for (int i = 0; i < tabs.size(); i++) {
    String tab = (String) tabs.get(i);
    float widthOfTabText = textWidth(tab);
    float tabWidth = widthOfTabText + 3 * 2 + 17;
    
    float circleX = tabX + widthOfTabText + 3 * 2 + 7;
    float circleY = (topBarHeight + 3) / 2.0;
    float circleRadius = 5; 
    
    boolean isHoveringClose = dist(mouseX, mouseY, circleX, circleY) < circleRadius;
    
    // Draw Tab Base Background
    fill(50);
    rect(tabX, 0, tabWidth, topBarHeight);
    
    // Draw Tab Accent Line
    fill(100);       
    rect(tabX, 0, tabWidth, 3);
    
    // Draw Close Button (Hover: Light Red, Default: Red)
    if (isHoveringClose) {
      fill(255, 107, 107); 
      cursor(Cursor.HAND_CURSOR); // Dynamic cursor correction override
    } else {
      fill(237, 71, 71); 
    }
    ellipse(circleX, circleY, circleRadius * 2, circleRadius * 2);
    
    // Draw Tab Text
    fill(255);
    textAlign(LEFT, CENTER);
    text(tab, tabX + 4, (topBarHeight + 3) / 2.0);
    
    tabX += tabWidth + 2;
  }
}
