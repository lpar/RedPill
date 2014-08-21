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

#import "MatrixView.h"
#import <AppKit/AppKit.h>
#import <AppKit/NSAttributedString.h>
#import "MatrixMacros.h"
#import "MatrixStripParams.h"

@implementation MatrixView

/// SECTION ONE
/// Core ScreenSaverView method implementations

// Override setFrameSize to resize the GL universe too.
- (void)setFrameSize:(NSSize)newSize
{
   [super setFrameSize:newSize];
   if (glview != nil) {
      [glview setFrameSize:newSize];
      [self resizeGL:(int)newSize.width :(int)newSize.height];
   }
}

// Constructor to initialize a screensaver in the specified rectangular frame.
// The frame may be a full screen, or a preview window.
- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)previewmode
{
// Note that double buffering makes performance worse and doesn't improve display quality,
// so we don't demand it
NSOpenGLPixelFormatAttribute attributes[] = {
   NSOpenGLPFAColorSize, 16,
   NSOpenGLPFAAlphaSize, 8,
   (NSOpenGLPixelFormatAttribute)0};
NSOpenGLPixelFormat *pixformat;

   isPreview = previewmode;
   // Initialize the superclass to set up the environment for the screensaver
   self = [super initWithFrame:frame isPreview:isPreview];
   if (self == nil) {
      LogError("initWithFrame", "Failed to initialize screensaver environment. Not my fault.");
      return nil;
   }

   // Work out what our defaults are called
   NSBundle *bundle = [NSBundle bundleForClass:[self class]];
   NSString *identifier = [bundle bundleIdentifier];
   if(identifier == nil) {
      LogError("initWithFrame", "Trying to initialize preferences but identifier is nil!");
      return nil;
   }
   ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:identifier];
   // Create and register an array of "default defaults"
   // Note that since the screensaver parameters are mostly between 0 and something < 1 internally,
   // and UI sliders only have a resolution of 0.1, we multiply 'em all by 100, so 0.15 becomes 15.
   NSDictionary *defdefs = @{STRIPS_KEY: STRIPS_DEFAULT,
      VELOCITY_KEY: VELOCITY_DEFAULT,
      DEPTH_KEY: DEPTH_DEFAULT,
      CYCLING_KEY: CYCLING_DEFAULT,
      FALLING_KEY: FALLING_DEFAULT,
      CURSOR_KEY: CURSOR_DEFAULT,
      FOG_KEY: FOG_DEFAULT,
      TOPSTART_KEY: TOPSTART_DEFAULT,
      MAINONLY_KEY: MAINONLY_DEFAULT,
      SPOON_KEY: SPOON_DEFAULT};
   [defaults registerDefaults:defdefs];
   // Now load either those defaults, or the user's prior choice of preferences
   [self loadDefaults:nil];

   // Work out if we're running on the main display
   // This lets us offer a "run on main screen only" option for when OpenGL doesn't like running two monitors
   isMainScreen = ((frame.origin.x == 0 && frame.origin.y == 0) || isPreview);
   // If we're running in preview mode, we need to set up a notification so the preferences dialog
   // can tell us when we need to reload our parameters to show the changes.
   // Note that the notification center should always be set up, otherwise it's possible to cause
   // race conditions that result in a crash by clicking buttons quickly and repeatedly.
   [[NSNotificationCenter defaultCenter]
      addObserver:self
         selector:@selector(loadDefaults:)
             name:PREFS_NOTIFICATION
           object:nil];
   
   // Create pixel format
   pixformat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attributes];
   if(!pixformat) {
      LogError("initWithFrame", "Failed to create a suitable pixel format. Your graphics card can't cope with this screensaver, sorry.");
      return nil;
   }

   // Create the GL context
   // QUERY: Why NSZeroRect? Why not frame? I don't know, perhaps someone can tell me...
   glview = [[MatrixOpenGLView alloc] initWithFrame:NSZeroRect pixelFormat:pixformat];
   if (glview == nil) {
      LogError("initWithFrame", "Failed to initialize OpenGL. Not my fault.");
      return nil;
   }
   // We do the actual glFoo initialization calls later
   didGLinit = FALSE;   
   // Make the GL context a subview of us
   [self addSubview:glview];
   // Now we can release our handle on it
   // Set the animation speed
   [self setAnimationTimeInterval:1/30.0];
   // Initialize the parameters which aren't editable in the dialog box.
   // The idea is to parameterize everything in advance, so that you can
   // change what's editable in the dialog without too much pain.
   saverParams.cellSize = 2.0;
   saverParams.maxCellLife = 120;
   saverParams.numGlyphs = NUM_GLYPHS;
   saverParams.cursorChangeProbability = 20;
   saverParams.cursorLiveProbability = 30;
   saverParams.cursorStaticProbability = 30;
   saverParams.cursorEmptyProbability = 10;
   saverParams.framesPerLivingCellChange = 3;
   saverParams.minDepth = CLIP_NEAR;
   saverParams.spawnChance = 0.2;
   return self;
}

// Handle a change of preferences/configuration
- (void)loadDefaults:(NSNotification *) n
{
   // Work out what our defaults are called
   NSString *identifier = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
   if(identifier == nil) {
      LogError("initWithFrame", "Trying to load preferences but identifier is nil.");
      return;
   }
   // Load defaults
   ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:identifier];
   // Scale the values appropriately and set the saver parameters
   saverParams.maxStrips = [defaults floatForKey:STRIPS_KEY];
   saverParams.driftSpeed = [defaults floatForKey:VELOCITY_KEY] / 100.0;
   saverParams.maxDepth = [defaults floatForKey:DEPTH_KEY];
   saverParams.colorCycleSpeed = [defaults floatForKey:CYCLING_KEY] / 100.0;
   saverParams.colorFallSpeed = [defaults floatForKey:FALLING_KEY] / 100.0;
   saverParams.cursorSpeed = [defaults floatForKey:CURSOR_KEY] / 100.0;
   saverParams.fogDensity = [defaults floatForKey:FOG_KEY] / 100.0;
   saverParams.minStartY = ([defaults boolForKey:TOPSTART_KEY] ? 1.0 : 0.0);
   mainScreenOnly = ([defaults boolForKey:MAINONLY_KEY] ? 1 : 0);
   // Check for main screen only and this isn't main screen
   if (mainScreenOnly && !isMainScreen) {
      return;
   }
   // If fog value is now zero, disable fog
   if (glview == nil) {
      // Oops, nothing we can do
      return;
   }
   [[glview openGLContext] makeCurrentContext];
   if (saverParams.fogDensity == 0.0) {
      glDisable(GL_FOG);
      CheckGLError("loadDefaults","glDisable(GL_FOG)");
   } else {
      glEnable(GL_FOG);
      CheckGLError("loadDefaults","glEnable(GL_FOG)");
   }
}

- (void)startAnimation
{
   // Anything to do?
   if (mainScreenOnly && !isMainScreen) {
      return;
   }  

   if (glview == nil) {
      LogError("startAnimation", "OS called startAnimation before NSOpenGLView initialized. This should not happen.");
      return;
   }
   // Clear the screen to black, so that the screensaver fades to black
   [[glview openGLContext] makeCurrentContext];
   glClearColor(0.0, 0.0, 0.0, 0.0);
   CheckGLError("startAnimation","glClearColor(0.0, 0.0, 0.0, 0.0)");
   glClear(GL_COLOR_BUFFER_BIT);
   CheckGLError("startAnimation","glClear(GL_COLOR_BUFFER_BIT)");
   glFlush();
   CheckGLError("startAnimation","glFlush");
   // Allocate the texture storage object if necessary
      [[glview openGLContext] makeCurrentContext];
   if (matrixGlyphs == nil) {
      matrixGlyphs = [[MatrixTexture alloc] initWithNSOpenGLView:glview];
   }
   // Load and bind the texture bitmap
   if (![matrixGlyphs fileLoaded]) {
      // Load the PNG of glyphs
      [matrixGlyphs loadFromFile:@"Glyphs.png"];
   }
   // Set up some parameters
   x = 0.0;
   y = 0.0;
   [super startAnimation];
}

- (void)stopAnimation
{
   // Release the textures
   if (matrixGlyphs != nil) {
      // very important!
      matrixGlyphs = nil;
   }
   [super stopAnimation];
}

// Draw the current frame
- (void)drawRect:(NSRect)rect
{
   [super drawRect:rect];

   
   // Initialize OpenGL if necessary
   if (!didGLinit) {
      didGLinit = TRUE;
      [self initGL];
   }
   
   if (glview == nil) {
     return;
   }
   
   if (mainScreenOnly && !isMainScreen) {
     [[glview openGLContext] makeCurrentContext];
     glClearColor(0.0, 0.0, 0.0, 0.0);
     return;
   }     
   
   [self drawGL];

   // This is where we'd flush the double buffer to the screen if we were using one, with
   // [[glview openGLContext] flushBuffer];
}

- (void)animateOneFrame
{
GLfloat xs,ys;
GLfloat d;
int cells;
MatrixStrip *strip;
MatrixStrip *newstrip;
int maxi,newstripi;
int i;
struct MatrixStripParams tweaked;


   if (glview == nil) {
      LogError("animateOneFrame", "OS called animateOneFrame before NSOpenGLView initialized. This should not happen.");
      return;
   }
   
   // Anything to do?
  if (mainScreenOnly && !isMainScreen) {
    return;
  }

   if (matrixGlyphs == nil) {
      // Unfortunately the OS calling "draw frame" before "initialize screensaver" happens quite a lot,
       // and shouldn't be reported as an error
      return;
   }
   
   // Allocate the array of matrix strips if necessary
   if (matrixStrips == nil) {
      matrixStrips = [[NSMutableArray alloc] init];
   }
   // If the number of Matrix strips is less than the max, create another every now and again
   maxi = [matrixStrips count];
   if ((maxi < saverParams.maxStrips) && (RANDOM_FLOAT_01 < saverParams.spawnChance)) {
      // Copy the current parameters
      tweaked = saverParams;
      // If the velocity is 0, we make the depth random
      if (saverParams.driftSpeed == 0.0) {
         d = -CLIP_NEAR - RANDOM_FLOAT_01 * (CLIP_FAR - CLIP_NEAR);
      } else {
         // Depth is whatever the current parameters are, only negative (away from the viewer)
         d = -saverParams.maxDepth;
      }
      // Work out range of X and Y at that depth
       ys = -d * TAN_FOV;
      xs = ys * aspectRatio;
       // Position the strip
      x = xs * RANDOM_FLOAT_11;
      y = saverParams.cellSize + ys * (saverParams.minStartY == 0.0 ? RANDOM_FLOAT_01 : saverParams.minStartY);
      // Work out how many cells it needs to cover the screen vertically
      cells = (int) ((y + ys) / saverParams.cellSize / QUAD_SQUISH_FACTOR) + 2;
      // Tweak the cursor speed a bit, randomly
       tweaked.cursorSpeed = saverParams.cursorSpeed + 0.2 * RANDOM_FLOAT_01;
       // I guess we could tweak the other parameters to vary things a bit, but it looks good enough anyway
      // Now create a strip
      newstrip = [[MatrixStrip alloc] initWithCells:cells x:x y:y z:d params:tweaked];
      newstripi = -1;
      // Add it to the array
       if (saverParams.driftSpeed == 0.0) {
          // In "zero velocity mode", we need to find the first strip that's in front of this one
          for (i = 0; i < maxi; i++) {
             strip = matrixStrips[i];
             if ([strip z] > d) {
                break;
             }
          }
          [matrixStrips insertObject:newstrip atIndex:i];
       } else {
          // In regular mode, strips are always added at the back
          if (maxi == 0) {
             // Adding first strip to array, so add it to the end
             [matrixStrips addObject:newstrip];
          } else {
             // Add it to the start of the array
             [matrixStrips insertObject:newstrip atIndex:0];
          }
       }
      // Now send a release, as the array will have retained it
   }
   // Animate all the strips
   maxi = [matrixStrips count];
   for (i = 0; i < maxi; i++) {
      strip = matrixStrips[i];
      if ([strip animateSelfIsComplete]) {
         // Strip has finished doing anything interesting, so delete it from the array
         // Note that the array releases it for us
         [matrixStrips removeObjectAtIndex:i];
         // The array is now one smaller, and we need to loop over the same index again
         i -= 1;
         maxi -= 1;
         // Plus we can now spawn new strips faster
         if (saverParams.spawnChance < 1.0) {
            saverParams.spawnChance += 0.05;
         }
      }
   }
   // Trigger a rectangle redraw
   [self setNeedsDisplay:YES];
}

/// SECTION TWO
/// Everything OpenGL

// Initialize OpenGL
- (void)initGL
{
GLfloat fogcolor[4] = {0.0, 0.0, 0.0, 1.0};

   // Check there's an NSOpenGLView before we continue
   if (glview == nil) {
      LogError("initGL", "Screensaver called initGL before NSOpenGLView initialized. This should not happen.");
      return;
   }
   // OK, let's go
   [[glview openGLContext] makeCurrentContext];
   // All we need is flat shaded polygons
   glShadeModel(GL_FLAT);
   CheckGLError("initGL","glShadeModel(GL_FLAT)");
   // Enable textures, use them to modulate the brightness of the pixels of the quads we draw
   glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
   CheckGLError("initGL","glTexEnvf(GL_MODULATE)");
   glEnable(GL_TEXTURE_2D);
   CheckGLError("initGL","glEnable(GL_TEXTURE_2D)");
   // Skip stuff that's almost black
   glAlphaFunc(GL_GEQUAL, 0.0625);
   CheckGLError("initGL","glAlphaFunc(GL_GEQUAL, 0.0625)");
   // Set up the blending function for drawing the text quads
   glEnable(GL_BLEND);
   CheckGLError("initGL","glEnable(GL_BLEND)");
   glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
   // Enable fog
   glEnable(GL_FOG);
   CheckGLError("initGL","glEnable(GL_FOG)");
   glFogi(GL_FOG_MODE, GL_LINEAR);
   CheckGLError("initGL","glFogi");
   glFogfv(GL_FOG_COLOR, fogcolor);
   CheckGLError("initGL","glFogf(GL_FOG_COLOR)");
   glFogf(GL_FOG_DENSITY, saverParams.fogDensity);
   CheckGLError("initGL","glFogf(GL_FOG_DENSITY)");
   glFogf(GL_FOG_START, CLIP_NEAR);
   CheckGLError("initGL","glFogf(GL_FOG_START)");
   glFogf(GL_FOG_END, CLIP_FAR*1.2);
   CheckGLError("initGL","glFogf(GL_FOG_END)");
   // Now maybe disable fog...
   if (saverParams.fogDensity == 0.0) {
      glDisable(GL_FOG);
      CheckGLError("initGL","glDisable(GL_FOG)");
   } else {
      glEnable(GL_FOG);
      CheckGLError("initGL","glEnable(GL_FOG)");
   }
   // We use GL arrays for drawing the Matrix strips, so enable them now
   glEnableClientState(GL_VERTEX_ARRAY);
   CheckGLError("initGL","glEnableClientState(GL_VERTEX_ARRAY)");
   glEnableClientState(GL_COLOR_ARRAY);
   CheckGLError("initGL","glEnableClientState(GL_COLOR_ARRAY)");
   glEnableClientState(GL_TEXTURE_COORD_ARRAY);
   CheckGLError("initGL","glEnableClientState(GL_TEXTURE_COORD_ARRAY)");   
}

// Set up viewport and projection appropriately for the given screen rectangle
- (void)resizeGL:(int)width :(int) height
{
   if (glview == nil) {
      LogError("resizeGL", "Screensaver called resizeGL before NSOpenGLView initialized. This should not happen.");
      return;
   }
   [[glview openGLContext] makeCurrentContext];
   glViewport(0, 0, width, height);
   CheckGLError("resizeGL","glViewport");
   glMatrixMode(GL_PROJECTION);
   CheckGLError("resizeGL","glMatrixMode(GL_PROJECTION)");
   glLoadIdentity();
   CheckGLError("resizeGL","glLoadIdentity");
   // 45 degrees FOV = 50mm lens on a 35mm camera, should look natural
   // Store the aspect ratio for later use
   aspectRatio = (GLfloat) width / (GLfloat) height;
   saverParams.aspectRatio = aspectRatio;
   gluPerspective(FIELD_OF_VIEW, aspectRatio, CLIP_NEAR, CLIP_FAR);
   CheckGLError("resizeGL","gluPerspective(FIELD_OF_VIEW)");
   // Go back to manipulating the model (objects)
   glMatrixMode(GL_MODELVIEW);
   CheckGLError("resizeGL","glMatrixMode(GL_MODELVIEW)");
   glLoadIdentity();
   CheckGLError("resizeGL","glLoadIdentity");
}

- (void)drawGL
{
GLuint tex;
NSEnumerator *e;
MatrixStrip *strip;

   if (glview == nil) {
      LogError("drawGL", "Screensaver called drawGL called before NSOpenGLView initialized. This should not happen.");
      return;
   }
   if (matrixGlyphs == nil) {
      // Unfortunately the OS calling "draw frame" before "initialize screensaver" happens quite a lot,
       // and shouldn't be reported as an error
      return;
   }
   [[glview openGLContext] makeCurrentContext];
   glClearColor(0.0, 0.0, 0.0, 0.0);
   CheckGLError("drawGL","glClearColor(0.0, 0.0, 0.0, 0.0)");
   glClear(GL_COLOR_BUFFER_BIT);
   CheckGLError("drawGL","glClear(GL_COLOR_BUFFER_BIT)");
   if (matrixStrips == nil) {
      // I guess we didn't get around to it yet
       return;
   }
   // Bind the texture we loaded
   tex = [matrixGlyphs GLtexture];
   if (!glIsTexture(tex)) {
      LogError("drawGL", "Someone stole our texture, call the OpenGL texture police.");
   }
   CheckGLError("drawGL","glIsTexture");
   glBindTexture(GL_TEXTURE_2D, tex);
   CheckGLError("drawGL","glBindTexture");
   // Draw all the strips by asking them to draw themselves
   e = [matrixStrips objectEnumerator];
   while (strip = [e nextObject]) {
      [strip drawSelf];
   }  
   glFlush();
   CheckGLError("drawGL","glFlush");
}

/// SECTION THREE
/// Configuration sheet handling

- (BOOL)hasConfigureSheet
{
   return YES;
}

- (NSWindow*)configureSheet
{
   if (!prefsWindow) {
      prefsWindow = [[MatrixPrefsWindow alloc]
      initWithWindowNibName:@"Matrix"];
   }
   return [prefsWindow window];
}

/// SECTION FOUR
/// Clean up after ourselves
- (void) dealloc
{
   [[NSNotificationCenter defaultCenter]
      removeObserver:self
                name:PREFS_NOTIFICATION
              object:nil];
}
@end
