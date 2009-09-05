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
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
// or visit <URL:http://www.fsf.org/>

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/glu.h>
#import "GLUtils.h"

// This code encapsulates all the ugly details of loading a texture from a graphics file
// into allocated memory, and converting it into the format needed by OpenGL.
@interface MatrixTexture : NSObject {
   // Size of texture (height and width)
   NSSize size;

   // Format of texture (GL_RGB or GL_RGBA)
   GLenum format;

   // Raw data
   char *data;

   // OpenGL handle used to refer to texture
   GLuint texture;

   // View context to use for OpenGL operations
   NSOpenGLView *glview;

   // Has the texture data been successfully loaded?
   BOOL fileWasLoaded;

   // Bitmap data for glyphs
   NSMutableData *dataobj;
}

- (id)initWithNSOpenGLView:(NSOpenGLView *)someview;

// Method to load texture from a file 
// (kept in the application package Contents/Resources folder)
- (BOOL)loadFromFile:(NSString *)filename;

// Accessor method for GL texture ID
- (GLuint)GLtexture;

// Accessor method for whether the file has been loaded successfully yet
- (BOOL)fileLoaded;
@end
