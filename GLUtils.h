#import <Foundation/Foundation.h>
#import <OpenGL/gl.h>

// This file contains a handy GL error checking function adapted from 
// the one found in the Apple OpenGL sample code.

// Note that __private_extern__ protects CheckGLError from conflicting
// with other screen saver modules, preference panes, frameworks,
// and other bundles that get loaded into the System Preferences
// application, and which have quite likely used the same function.
__private_extern__ void CheckGLError(const char *func, const char *note);
__private_extern__ void LogError(const char *func, const char *note);