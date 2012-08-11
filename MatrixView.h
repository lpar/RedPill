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
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
// or visit <URL:http://www.fsf.org/>

#import <ScreenSaver/ScreenSaver.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import "MatrixOpenGLView.h"
#import "MatrixStripParams.h"
#import "MatrixStrip.h"
#import "MatrixTexture.h"
#import "MatrixPrefsWindow.h"
#import "GLUtils.h"

// This is the main control object for the screensaver.
// It inherits from and implements the ScreenSaverView API.
@interface MatrixView : ScreenSaverView 
{
   // The NSOpenGLView subclass where we draw the graphics
   MatrixOpenGLView *glview;
   
   // Flag to indicate GL has been initialized
   BOOL didGLinit;

   // Flag indicating whether this screensaver process is drawing on the main screen,
   // or on a second monitor
   BOOL isMainScreen;
   // Similar flag for preference checkbox
   BOOL mainScreenOnly;
   // and for whether we're running in the preview box
   BOOL isPreview;
   
   // The screen aspect ratio, stored and used to compute the ranges of X and Y allowed at given depth
   GLfloat aspectRatio;

   GLfloat x;
   GLfloat y;

   // The texture containing the glyphs
   MatrixTexture *matrixGlyphs;

   // Array of strips of Matrix
   NSMutableArray *matrixStrips;

   // Parameters for the animation
   struct MatrixStripParams saverParams;

   // Preferences window
   MatrixPrefsWindow *prefsWindow;
}

// Handle a change of preferences/configuration
- (void)loadDefaults:(NSNotification *)n;

// Method to initialize OpenGL
- (void)initGL;

// Method to set up viewport and projection
- (void)resizeGL:(int)width :(int)height;

// Method to actually draw stuff on the screen
- (void)drawGL;
@end
