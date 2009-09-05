// This file is part of Red Pill
// A 3D OpenGL "Matrix" screensaver for Mac OS X
// Copyright (C) 2002, 2003 mathew <meta@pobox.com>
//
// Red Pill is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
// or visit <URL:http://www.fsf.org/>

#import <Foundation/Foundation.h>
#import <OpenGL/gl.h>
#import "GLUtils.h"
#import "MatrixStripParams.h"

// MatrixStrip implements a single "particle" object consisting of a strip of
// animated "Matrix code" style glyphs
@interface MatrixStrip : NSObject {
   // Internal state variables
   // Location of strip
   GLfloat myX;
   GLfloat myY;
   GLfloat myZ;
   // Position of the cursor which writes/erases glyphs, as a cell number
   int cursorPos;
   // Offset upwards from 0.0 to 1.0 of a cell, to allow for motion slower than 1 cell per animation frame
   GLfloat cursorOffset;
   // State the cursor writes when writing
   int cursorState;
   // Whether the cursor is drawing or erasing
   bool cursorDrawing;
   // The cursor glyph
   int cursorGlyph;
   // Number of cells in strip
   int stripSize;
   // Array of cell states
   int *cellState;
   // Array of glyphs in cells
   int *cellContents;
   // Array of texture coordinates for OpenGL
   GLfloat *textureArray;
   // Array of quad vertices for OpenGL
   GLfloat *quadArray;
   // Array of color vertices for OpenGL
   GLfloat *colorArray;
   // The tweakable parameters which alter the behavior of the strip
   struct MatrixStripParams stripParams;
   // Internal counter used to reduce the animation speed of living cells
   int framecounter;
   // Internal float used to animate the colors
   GLfloat startColor;
    // Ints used to store the first and last visible cells that need to be drawn
    int firstVisibleCell;
    int lastVisibleCell;
}

// Initialize with top left corner at given position
- (id) initWithCells:(int)cells x:(GLfloat)x y:(GLfloat)y z:(GLfloat)z params:(struct MatrixStripParams)params;

// Return my z position
- (GLfloat) z;

// Pick a random cursor drawing state
- (void) randomizeCursorState;

// Pick a random glyph for the cursor
- (void) randomizeCursorGlyph;

// Pick a random cursor drawing state different from the current one
// i.e. if drawing static, either switch to drawing live or drawing empty
- (void) randomizeCursorState:(int)current;

// Compute the entire array of quad vertices, for a strip with the given number of cells (excluding the cursor)
- (void) computeQuadVertices:(int)cells x:(GLfloat)x y:(GLfloat)y z:(GLfloat)z;

// Set up the initial state of the color vertices
- (void) initializeColorVertices:(int)maxcell;

// Compute the array of color vertices (excluding the cursor)
- (void) computeColorVertices;

// Set up the initial state of the color vertices
- (void) initializeTextureVertices:(int)maxcell;

// Compute the texture coordinates for a single cell of the texture coord array
- (void) computeTextureVertices:(int)cellnum;

// Compute quad, color and texture vertices for the cursor, bumped up by given offset
- (void) computeCursor:(int)cell offset:(GLfloat)offset;

// Issue GL calls to draw yourself!
// Assumes context has been set up appropriately, arrays have been enabled, etc.
// (Uses GL_VERTEX_ARRAY, GL_COLOR_ARRAY and GL_TEXTURE_COORD_ARRAY)
- (void) drawSelf;

// Animate yourself, return true if you've finished doing anything interesting
- (BOOL) animateSelfIsComplete;
@end
