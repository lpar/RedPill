// This file is part of Red Pill
// A 3D OpenGL "Matrix" screensaver for Mac OS X
// Copyright (C) 2002-2005 mathew <meta@pobox.com>
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

#import "MatrixTexture.h"

@interface MatrixTexture (InternalMethods)
- (BOOL)loadBitmap:(NSString *)filename;
@end

@implementation MatrixTexture : NSObject

void myxor(char *, size_t);

// Initializer needs to know what GL view the texture will be used in.
- (instancetype)initWithNSOpenGLView:(NSOpenGLView *)someview
{
   if (self = [super init]) {
      glview = someview;
      fileWasLoaded = FALSE;
   }
   if (glview == nil) {
      LogError("initWithNSOpenGLView", "initWithNSOpenGLView was passed a nil NSOpenGLView. This should not happen.");
   }
   return self;
}

- (void) dealloc
{
   // Unload the OpenGL texture and deallocate our memory
   [[glview openGLContext] makeCurrentContext];
   if (texture != 0) {
      glDeleteTextures(1, &texture);
      CheckGLError("dealloc","glDeleteTextures");
   }
   if (data) { free(data); }
}

- (GLuint) GLtexture
{
   return texture;
}

- (BOOL) fileLoaded
{
   return fileWasLoaded;
}

// Load bitmap data from a file.
- (BOOL) loadBitmap:(NSString *)filename
{
   NSBitmapImageRep *img;
   int depth, rowsize;
   unsigned char *imgdata;
   int row, destrow;

   // Load image file
   img = [NSBitmapImageRep imageRepWithContentsOfFile:filename];
   if (img == nil) {
      LogError("loadBitmap", "imageRepWithContentsOfFile returned nil. Image file is broken?");
      return FALSE;
   }

   // Work out format
   depth = [img samplesPerPixel];
   rowsize = [img bytesPerRow];
   if(depth == 3) {
      // 24 bit RGB
      format = GL_RGB;
   } else if(depth == 4) {
      // 24 bit RGB plus alpha
      format = GL_RGBA;
   } else {
      LogError("loadBitmap", "unrecognized bitmap format.");
      return FALSE;
   }
   size.width = [img pixelsWide];
   size.height = [img pixelsHigh];
   // Allocate space for the GL bitmap data
   data = calloc(rowsize * size.height, 1);
   if (data == NULL) {
      LogError("loadBitmap", "failed to allocate space for the bitmap.");
      return FALSE;
   }
   // Copy the image into the GL bitmap, 
   // flipping the rows top to bottom
   imgdata = [img bitmapData];
   destrow = 0;
   for(row = size.height - 1; row >= 0; row--, destrow++ ) {
      // Copy the entire row in one shot
      memcpy(data + (destrow * rowsize), imgdata + (row * rowsize), rowsize );
   }
   fileWasLoaded = TRUE;
   return TRUE;
}

// Load bitmap data from a file, using the above method, then create an OpenGL texture from it.
- (BOOL)loadFromFile:(NSString *)filename
{
NSString *filespec;

   // Work out full path to image file
   filespec = [NSString stringWithFormat:@"%@/%@",
   [[NSBundle bundleForClass:[self class]] resourcePath ], filename ];
   // See if it exists
   NSFileManager *fileman = [NSFileManager defaultManager];
   if (![fileman fileExistsAtPath:filespec]) {
      return FALSE;
   }
   if (![self loadBitmap:filespec]) {
      LogError("loadFromFile", "loadFromFile failed to load bitmap.");
      return FALSE;
   }
   if (format != GL_RGB) {
      LogError("loadFromFile", "Warning: Bitmaps not RGB!");
   }
   // Now create an OpenGL texture
   [[glview openGLContext] makeCurrentContext];
   if (texture == 0) {
      // Find free texture slot
      glGenTextures(1, &texture);
      CheckGLError("loadFromFile","glGenTextures");
   }
   glBindTexture(GL_TEXTURE_2D, texture);
   CheckGLError("loadFromFile","glBindTexture");
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
   CheckGLError("loadFromFile","glTexParameteri");
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
   CheckGLError("loadFromFile","glTexParameteri"); 
   // Define the texture from the bitmap data
   // We want an INTENSITY texture where alpha = intensity of pixel
   // as we're modulating quads into letters of whatever color
   // and the source image is colored letters on black
   glTexImage2D(GL_TEXTURE_2D, 0, GL_INTENSITY, (GLsizei) size.width, (GLsizei) size.height, 0, format, GL_UNSIGNED_BYTE, data);
   CheckGLError("loadFromFile","glTexImage2D");
   return TRUE;
}

@end
