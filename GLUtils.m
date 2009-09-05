#import <OpenGL/glu.h>
#import "GLUtils.h"

// The main change between this function and the Apple version is that
// this one counts the number of errors, and silently ignores errors
// after the first three.
// This is because some users discovered that RedPill would report GL
// errors *even when everything worked fine*, and their system log would
// get filled up with 30 lines of error text every second until it ate
// all available disk space. Ouch!

__private_extern__ void CheckGLError(const char *func, const char *note)
{
  static int errcount = 0;

  GLenum error = glGetError();
  if (error)
  {
    if (errcount < 4) {
      errcount += 1;
      NSLog(@"%s.%s: %s (%d)", func, note, gluErrorString(error), error);
    }
  }
}

__private_extern__ void LogError(const char *func, const char *note)
{
  static int logcount = 0;
  
  if (logcount < 4) {
    logcount += 1;
    NSLog(@"%s: %s", func, note);
  }
}