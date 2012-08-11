// This file is part of Red Pill
// A 3D OpenGL "Matrix" screensaver for Mac OS X
// Copyright (C) 2002, 2003 mathew <meta@pobox.com>
//
// Red Pill is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
// or visit <URL:http://www.fsf.org/>

#import <OpenGL/gl.h>
#import "MatrixStrip.h"
#import "MatrixView.h"
#import "MatrixMacros.h"

// Given bottom,left coordinates of a 32x32 square within a 256x256 texture,
// this is the amount to add to both coordinates to get the top,right pixel
// of the same texture. It's equal to 31.0 / 256.0.
#define GLYPH_TEX_SIZE 0.121

@implementation MatrixStrip

- (id) initWithCells:(int)cells x:(GLfloat)x y:(GLfloat)y z:(GLfloat)z params:(struct MatrixStripParams)params;
{
int c;

   // Do whatever NSObject needs to do
   self = [super init];
   if (self == nil) {
      return nil;
   }
   // So far, so good; now allocate storage
   cellState = malloc(cells * sizeof(int));
   cellContents = malloc(cells * sizeof(int));
   // Each cell needs four x,y texture vertex coordinates
   textureArray = malloc(cells * 4 * 2 * sizeof(GLfloat));
   // and four x,y,z quad vertex coordinates
   quadArray = malloc(cells * 4 * 3 * sizeof(GLfloat));
   // and four r,g,b,a color values
   colorArray = malloc(cells * 4 * 4 * sizeof(GLfloat));

   // Check all those mallocs worked
   if (cellState == NULL || cellContents == NULL || textureArray == NULL || quadArray == NULL
      || colorArray == NULL) {
      LogError("initwithCells", "Failed to allocate memory for strip. Time to buy more memory.");
      [self autorelease];
      return nil;
   }
   // Record how big we are and where
   stripSize = cells;
   myX = x;
   myY = y;
   myZ = z;
   // Copy/store the behavior parameters
   stripParams = params;
   // Initialize the cursor
   [self randomizeCursorState];
   cursorPos = 1;
   cursorOffset = 1.0;
   cursorDrawing = TRUE;
   framecounter = 0;
   startColor = 0.2;
   [self randomizeCursorGlyph];
   // Initialize cells
   for (c = 0; c<cells; c++) {
      cellState[c] = 0; // Empty
      cellContents[c] = 0; // Space
   }
   // Create the strip of quads by creating the OpenGL arrays needed to draw it
   [self computeQuadVertices:cells x:x y:y z:z];
   [self initializeColorVertices:cells];
   [self initializeTextureVertices:cells];
   return self;
}

- (void) dealloc
{
   // Free any allocated arrays
   if (cellState) { free(cellState); }
   if (cellContents) { free(cellContents); }
   if (textureArray) { free(textureArray); }
   if (quadArray) { free(quadArray); }
   if (colorArray) { free(colorArray); }
	 [super dealloc];
}

// Access method
- (GLfloat) z
{
   return myZ;
}

// Method to pick a random glyph for the cursor
- (void) randomizeCursorGlyph
{
   if (cursorDrawing) {
      cursorGlyph = 1 + (random() % (stripParams.numGlyphs - 1));
   } else {
      cursorGlyph = 0;
   }
}

// Two methods to change the cursor's state between drawing live cells,
// drawing static cells, and drawing blanks.
// The first just sets things up from scratch.
- (void) randomizeCursorState
{
   [self randomizeCursorState:-1];
}
// The second implements a simple state machine.
- (void) randomizeCursorState:(int)current
{
   if (current == 0) {
      // Cursor is drawing empty space
      // Next state is either draw-live or draw-static
      cursorState = (random() % (stripParams.cursorLiveProbability + 
         stripParams.cursorStaticProbability)) < stripParams.cursorLiveProbability ? 
         (random() % stripParams.maxCellLife) : 1;
   } else if (current == 1) {
      // Cursor is drawing static cells
      // Next state is either draw-live or draw-empty-space
      cursorState = (random() % (stripParams.cursorLiveProbability + 
         stripParams.cursorEmptyProbability)) < stripParams.cursorLiveProbability ? 
         (random() % stripParams.maxCellLife) : 0;
   } else if (current > 1) {
      // Cursor is drawing live cells
      // Next state is either draw-static or draw-empty-space
      cursorState = (random() % (stripParams.cursorStaticProbability + 
         stripParams.cursorEmptyProbability)) < stripParams.cursorStaticProbability ? 
         1 : 0;
   } else {
      // None of the above
      // Pick a state completely at random
      int x = (random() % (stripParams.cursorStaticProbability +
         stripParams.cursorEmptyProbability + stripParams.cursorLiveProbability));
      if (x < stripParams.cursorEmptyProbability) {
         cursorState = 0;
      } else if (x < (stripParams.cursorEmptyProbability + stripParams.cursorStaticProbability)) {
         cursorState = 1;
      } else {
         cursorState = (random() % stripParams.maxCellLife);
      }
   }
}

// Compute an entire array of quad vertices, given x,y,z of the top left corner
- (void) computeQuadVertices:(int)cells x:(GLfloat)x y:(GLfloat)y z:(GLfloat)z
{
int i;
GLfloat by, size;
GLfloat minY,maxY;

minY = z * TAN_FOV;
maxY = -minY;
firstVisibleCell = -1;
lastVisibleCell = -1;

   size = stripParams.cellSize;
   for (i = 0; i < cells; i++) {
      // Compute bottom y coord of cell
      by = y - QUAD_SQUISH_FACTOR * size * (GLfloat) i;
      // Record the first cell that is at least partially on screen
      if ((by < maxY) && (firstVisibleCell == -1)) {
         firstVisibleCell = i;
      }
      // and the last
      if (((by + size) < minY) && (lastVisibleCell == -1)) {
         lastVisibleCell = i-1;
      }
      // Bottom left vertex
      quadArray[12*i + 0] = x;
      quadArray[12*i + 1] = by;
      quadArray[12*i + 2] = z;
      // Bottom right vertex
      quadArray[12*i + 3] = x + size;
      quadArray[12*i + 4] = by;
      quadArray[12*i + 5] = z;
      // Top right vertex
      quadArray[12*i + 6] = x + size;
      quadArray[12*i + 7] = by + size;
      quadArray[12*i + 8] = z;
      // Top left vertex
      quadArray[12*i + 9] = x;
      quadArray[12*i +10] = by + size;
      quadArray[12*i +11] = z;
   }
   // Check for case where all cells are above bottom of screen
   if (lastVisibleCell == -1) {
      lastVisibleCell = cells;
   }
}

// Initialize the array of color vertices
- (void) initializeColorVertices:(int)maxcell
{
int i;

   for (i=0; i< maxcell * 16; i++) {
      colorArray[i] = 0.0;
   }
}

// Compute the new state of the color vertices
- (void) computeColorVertices
{
   int i,maxi,c;
   GLfloat g, gstep, cursorglow;

   c = 0; // To suppress spurious warning
   gstep = stripParams.colorCycleSpeed;
   // First, run down the strip cycling colors to bright then back to dark
   g = startColor;
   maxi = cursorDrawing ? cursorPos : stripSize;
   for (i=0; i < maxi; i++) {
      for (c = 0; c < 4; c++) {
         // Some shade of green if cell is not empty
         colorArray[16*i + 4*c + 1] = (cellState[i] == 0) ? 0.0 : g;
         // Cells which are very bright are slightly whitened
         colorArray[16*i + 4*c + 0] = ((g > 0.7) && (cellState[i] != 0)) ? (g - 0.6) : 0.0;
         colorArray[16*i + 4*c + 2] = ((g > 0.7) && (cellState[i] != 0)) ? (g - 0.6) : 0.0;
         // Transparent if cell is empty, otherwise opaque
         colorArray[16*i + 4*c + 3] = (cellState[i] == 0) ? 0.0 : 1.0;
      }
      g += gstep;
      if (g > 1.0) {
         g = 0.2;
      }
   }
   // Cycle the start color used above, to make the colors appear to fall
   startColor -= stripParams.colorFallSpeed;
   if (startColor < 0.2) {
      startColor = 1.0;
   }
   
   // If the cursor's drawing, work up from its position making sure the cells aren't too dark
   if (cursorDrawing) {
      maxi = cursorPos - 1;
      cursorglow = 0.8;
      for (i = maxi; i >= 0 && cursorglow > 0.2; i--) {
      // If there's some cursor-imparted glow left, use it
         if (colorArray[16*i + 4*c + 1] < cursorglow) {
            for (c = 0; c < 4; c++) {
               // Some shade of green if cell is not empty
               colorArray[16*i + 4*c + 1] = (cellState[i] == 0) ? 0.0 : cursorglow;
               // Cells which are very bright are slightly whitened
               colorArray[16*i + 4*c + 0] = ((cursorglow > 0.7) && (cellState[i] != 0)) ? (cursorglow - 0.6) : 0.0;
               colorArray[16*i + 4*c + 2] = ((cursorglow > 0.7) && (cellState[i] != 0)) ? (cursorglow - 0.6) : 0.0;
               // Transparent if cell is empty, otherwise opaque
               colorArray[16*i + 4*c + 3] = (cellState[i] == 0) ? 0.0 : 1.0;
            }
         }
         cursorglow -= gstep;
      }
   }
}

// It's a pity memset would require nasty assumptions about the internal format of floats...
- (void) initializeTextureVertices:(int)maxcell
{
   int i;

   for (i=0; i< maxcell * 8; i++) {
      textureArray[i] = 0.0;
   }
}

// Compute the texture coordinates for a single cell of the texture coord array
- (void) computeTextureVertices:(int)cellnum
{
int ix,iy;
GLfloat tx,ty;
int g;

   // Get the glyph
   g = cellContents[cellnum];
   // Work out the X and Y positions of the glyph in the texture
   ix = (g * 32) % 256;
   iy = 224 - 32 * ((g * 32) / 256) + 1;
   // Convert to floats
   tx = (GLfloat) ix / 256.0;
   ty = (GLfloat) iy / 256.0;
   // Now work out the texture coordinates of the square containing the glyph
   // Bottom left
   textureArray[8*cellnum + 0] = tx;
   textureArray[8*cellnum + 1] = ty;
   // Bottom right
   textureArray[8*cellnum + 2] = tx + GLYPH_TEX_SIZE;
   textureArray[8*cellnum + 3] = ty;
   // Top right
   textureArray[8*cellnum + 4] = tx + GLYPH_TEX_SIZE;
   textureArray[8*cellnum + 5] = ty + GLYPH_TEX_SIZE;
   // Top left
   textureArray[8*cellnum + 6] = tx;
   textureArray[8*cellnum + 7] = ty + GLYPH_TEX_SIZE;
}

// Compute quad, color and texture vertices for the cursor, bumped up by given offset
- (void) computeCursor:(int)cell offset:(GLfloat)offset
{
int c;
GLfloat y,by,x,z;
GLfloat size;
GLfloat cc;

   // Color is easy -- bright white at all four corners if drawing, else black
   cc = cursorDrawing ? 1.0 : 0.0;
   for (c = 0; c < 4; c++) {
      colorArray[16*cell + 4*c + 0] = cc;
      colorArray[16*cell + 4*c + 1] = cc;
      colorArray[16*cell + 4*c + 2] = cc;
      colorArray[16*cell + 4*c + 3] = 1.0;
   }
   // Position is like for a regular cell, but bumped up by offset * cell height
   size = stripParams.cellSize;
   // Find the top quad
   x = quadArray[0];
   y = quadArray[1];
   z = quadArray[2];
   by = y - QUAD_SQUISH_FACTOR * size * ((GLfloat) cell - offset);
   // Bottom left vertex
   quadArray[12*cell + 0] = x;
   quadArray[12*cell + 1] = by;
   quadArray[12*cell + 2] = z;
   // Bottom right vertex
   quadArray[12*cell + 3] = x + size;
   quadArray[12*cell + 4] = by;
   quadArray[12*cell + 5] = z;
   // Top right vertex
   quadArray[12*cell + 6] = x + size;
   quadArray[12*cell + 7] = by + size;
   quadArray[12*cell + 8] = z;
   // Top left vertex
   quadArray[12*cell + 9] = x;
   quadArray[12*cell +10] = by + size;
   quadArray[12*cell +11] = z;
   // Texture is just a call to self
   cellContents[cell] = cursorGlyph;
   [self computeTextureVertices:cell];
}

// Method to issue GL calls to draw the strip
// After all the work to build the OpenGL arrays, this is really easy
- (void) drawSelf
{
   int i;
   GLfloat jitter;
   GLfloat tenths;
   int lastcell;
   GLint first;
   GLsizei count;
       
   // Each vertex has 3 coordinates (x,y,z), which are GLfloats; it's a packed array
   glVertexPointer(3, GL_FLOAT, 0, quadArray);
   CheckGLError("drawSelf","glVertexPointer");
   // Each color vertex has 4 floats (RGBA); it's a packed array
   glColorPointer(4, GL_FLOAT, 0, colorArray);
   CheckGLError("drawSelf","glColorPointer");
   // Each texture coordinate has two coordinates (x and y), which are floats; it's a packed array
   glTexCoordPointer(2, GL_FLOAT, 0, textureArray);
   CheckGLError("drawSelf","glTexCoordPointer");
   // Work out the last cell we actually need to draw
   lastcell = (cursorDrawing) ? cursorPos : (stripSize - 1);
   if (lastcell > lastVisibleCell) {
      lastcell = lastVisibleCell;
   }
   // Now go draw all array elements from firstVisibleCell to lastcell
   first = firstVisibleCell * 4;
   count = (1 + lastcell - firstVisibleCell) * 4;
   if (count == 0) {
      return;
   }
   if (first < 0) {
      LogError("drawSelf", "Likely error: GLint first < 0");
   }
   if ((count % 4) != 0 || (count / 4) > stripSize) {
      LogError("drawSelf", "Likely error: GLsizei count incorrect");
   }
   glDrawArrays(GL_QUADS, first, count); /// was +1
   CheckGLError("drawSelf","glDrawArrays");
   // Now we draw some motion trails behind the falling cursor.
   // You don't consciously notice it, but it makes a big difference.
   if (cursorDrawing) {
      jitter = 0.75 * stripParams.cursorSpeed * stripParams.cellSize;
      glDisableClientState(GL_COLOR_ARRAY);
      CheckGLError("drawSelf","glDisableClientState(GL_COLOR_ARRAY)");
      for (i=0; i<3; i++) {
         tenths = (GLfloat)i * 0.1;
         glTranslatef(0.0,jitter,0.0); // jitter translation matrix up a bit
         CheckGLError("drawSelf","glTranslatef");
         glColor4f(1.0 - tenths, 1.0 - tenths, 1.0 - tenths, 0.5 - tenths);
         CheckGLError("drawSelf","glColor4f");         
         glDrawArrays(GL_QUADS, 4 * cursorPos, 4);
         CheckGLError("drawSelf","glDrawArrays");
      }
      glEnableClientState(GL_COLOR_ARRAY);
      CheckGLError("drawSelf","glEnableClientState(GL_COLOR_ARRAY)");
      glTranslatef(0.0,-3*jitter,0.0); // translate back again
      CheckGLError("drawSelf","glTranslatef");
   }
}

// Animate the strip, return true if the entire lifecycle of this strip is complete
- (BOOL) animateSelfIsComplete
{
int c;
GLfloat minY, cursLX, cursRX, maxX;
BOOL nearfront;
float zapchance;

   // First, are we about to splat into the screen?
   nearfront = (-myZ - stripParams.minDepth) < 5.0;
   if (nearfront) {
      // If so, we want a 1.0 probability of the cells being dead by the time they move the last 5.0
      zapchance = 1.0 / (5.0 / stripParams.driftSpeed);
      // Zap some random cells
      for (c = stripSize - 1; c >= 0; c--) {
         if (RANDOM_FLOAT_01 < zapchance) {
            cellState[c] = 0;
            cellContents[c] = 0;
            [self computeTextureVertices:c];
         }
      }
   }
   // Now for normal movement. Move the cursor down.
   cursorOffset -= stripParams.cursorSpeed;
   if (cursorOffset < 0) {
      cursorOffset = 1.0;
      // Cursor has fallen to the bottom of its cell.
      // Paint the cell with whatever is appropriate for the cursor mode
      if (cursorDrawing) {
         cellState[cursorPos] = cursorState;
         cellContents[cursorPos] = cursorGlyph;
         [self computeTextureVertices:cursorPos];
         // Move the cursor down a cell and pick a random glyph
         cursorPos += 1;
         // Should we change the cursor's draw state?
         if ((random() % 100) < stripParams.cursorChangeProbability) {
            // Pick a different state
            [self randomizeCursorState:cursorState];
         }
      } else {
         // We're in erase-only mode
         cellState[cursorPos] = 0;
         cellContents[cursorPos] = 0;
         [self computeTextureVertices:cursorPos];
         cursorPos += 1;
      }
   }
   // When we get to the bottom of the strip or the screen, see if we're in draw mode.
   // If so, go into erase mode. If we're already in erase mode, return true 'cause we're done.
   minY = myZ * TAN_FOV;
   if ((cursorPos >= stripSize) || (quadArray[12*cursorPos + 10] < minY)) {
      if (cursorDrawing) {
      cursorPos = 0;
      cursorDrawing = false;
      } else {
         return TRUE;
      }
   }
   if (framecounter++ == stripParams.framesPerLivingCellChange) {
      framecounter = 0;
      [self randomizeCursorGlyph];
      // Animate the cells based on their state
      // Work from the bottom up, as some cells take their value from the cells above
      for (c = stripSize - 1; c >= 0; c--) {
         if ((cellState[c] > 1) || (nearfront && cellState[c] > 0)) {
            // Animated cell, will change glyph
            // If it's the top cell, give it a random value
            if (c == 0) {
               cellContents[c] = 1 + (random() % (stripParams.numGlyphs - 1));
            } else if (cellState[c-1] <= 1) {
               // If the cell above isn't alive, give this one a random value
               cellContents[c] = 1 + (random() % (stripParams.numGlyphs - 1));
            } else {
               // Otherwise give this one the value of the cell above
               cellContents[c] = cellContents[c-1];
            }
            // Decrement state to age the cell
            cellState[c] -= 1;
            if (cellState[c] < 0) {
               cellState[c] = 0;
            }
            // A cell is never less alive than the one below it
            if (c < stripSize) {
               if (cellState[c+1] > cellState[c]) {
                  cellState[c] = cellState[c+1];
               }
            }
            // Recompute the cell's texture based on the new glyph contents
            [self computeTextureVertices:c];
         }
      }
   }
   // Generate color vertices
   [self computeColorVertices];
   // Move the strip towards the viewer
   myZ += stripParams.driftSpeed;
   if (-myZ < stripParams.minDepth) {
      return TRUE;
   }
   // If we fell off the sides of the screen, we're done
   maxX = -myZ * TAN_FOV * stripParams.aspectRatio;
   cursLX = quadArray[12*cursorPos + 9]; // Top left x
   cursRX = quadArray[12*cursorPos + 6]; // Top right x
   if ((cursLX > maxX) || (cursRX < -maxX)) {
      return TRUE;
   }
   // Don't need this any more
   [self computeQuadVertices:stripSize x:myX y:myY z:myZ];
   // Generate the cursor
   [self computeCursor:cursorPos offset:cursorOffset];
   // I'm not dead yet!
   return FALSE;
}
@end
