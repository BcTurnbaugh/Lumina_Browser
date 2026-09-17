import java.util.ArrayList;
import java.awt.Cursor;
import java.io.File;

// Convert the tab array to a dynamic ArrayList so we can add/remove elements
ArrayList tabs = new ArrayList();

// Dynamic layout widths
int topBarHeight = 25;
int leftSidePanelWidth = 200;
int rightSidePanelWidth = 300;

// Global variables for layout boundaries
float fileTreeTopY = topBarHeight + 34;
float fileTreeBottomY;
float fileTreeHeightLimit;
float halfLeftHeight;

// Dragging States for Side Panels
boolean draggingLeft = false;
boolean draggingRight = false;
int dragThreshold = 8;

FileNode fileTreeRoot;
float leftScrollOffset = 0;
boolean draggingLeftScroll = false;
float dragScrollStartMouseY = 0;
float dragScrollStartThumbY = 0;

// Selection states
ArrayList selectedNodes = new ArrayList();
FileNode lastClickedNode = null;
int lastClickTime = 0;

// Flat list to calculate rendering positions of open folders
ArrayList visibleRows = new ArrayList();

void setup() {
  size(1000, 650);
  surface.setResizable(true);

  // Initialize default tabs
  tabs.add("c:/users/Brendan/Files");
  tabs.add("Tab2");
  tabs.add("Tab3");
  tabs.add("Tab4");

  // Build and read real system files
  buildFileTree();
}

void draw() {
  background(43);
  int activeCursor = Cursor.DEFAULT_CURSOR;

  // Calculate heights dynamically relative to your custom horizontal divider
  halfLeftHeight = (height + topBarHeight) / 2.0;
  fileTreeBottomY = halfLeftHeight - 10;
  fileTreeHeightLimit = fileTreeBottomY - fileTreeTopY;

  // Determine cursor state based on hover or drag boundaries
  if (draggingLeft || draggingRight) {
    activeCursor = Cursor.E_RESIZE_CURSOR;
  } else {
    if (abs(mouseX - leftSidePanelWidth) < dragThreshold && mouseY > topBarHeight) {
      activeCursor = Cursor.E_RESIZE_CURSOR;
    } else if (abs(mouseX - (width - rightSidePanelWidth)) < dragThreshold && mouseY > topBarHeight) {
      activeCursor = Cursor.E_RESIZE_CURSOR;
    }
  }

  // Update panel sizing math
  updateDraggingLogic();

  // Draw Base Layout Framework
  drawBasePanels();

  // Draw Individual UI Modules
  drawTopPanel(activeCursor); // Pass active cursor to allow inner tab checking
  drawLeftPanel();
  drawMainWorkspace();
  drawRightPanel();

  // Custom scrollbar indicator checking
  float scrollBarX = leftSidePanelWidth - 10;
  float scrollBarW = 8;
  if (mouseX >= scrollBarX && mouseX <= scrollBarX + scrollBarW && mouseY >= fileTreeTopY && mouseY <= fileTreeBottomY) {
    float totalContentHeight = visibleRows.size() * 20;
    if (!draggingLeft && !draggingRight && totalContentHeight > fileTreeHeightLimit) {
      activeCursor = java.awt.Cursor.HAND_CURSOR;
    }
  }

  // Apply final cursor calculation
  cursor(activeCursor);
}
