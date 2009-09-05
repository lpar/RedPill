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

#import "MatrixPrefsWindow.h"

@implementation MatrixPrefsWindow

- (NSWindow *)window
{
   // Initialize parent
   NSWindow *w = [super window];
   // Work out what our defaults are called
   NSString *identifier = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
   if(identifier == nil) {
      LogError("window", "Trying to load preferences but identifier is nil.");
      return w;
   }  
   // Load defaults
   ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:identifier];
   // Initialize the UI elements
   [strips setFloatValue:[defaults floatForKey:STRIPS_KEY]];
   [velocity setFloatValue:[defaults floatForKey:VELOCITY_KEY]];
   [depth setFloatValue:[defaults floatForKey:DEPTH_KEY]];
   [cycling setFloatValue:[defaults floatForKey:CYCLING_KEY]];
   [falling setFloatValue:[defaults floatForKey:FALLING_KEY]];
   [cursor setFloatValue:[defaults floatForKey:CURSOR_KEY]];
   [fog setFloatValue:[defaults floatForKey:FOG_KEY]];
   [topstart setState:[defaults boolForKey:TOPSTART_KEY]];
   [mainonly setState:[defaults boolForKey:MAINONLY_KEY]];
   // Find out version from bundle
   NSBundle *bundle = [NSBundle bundleForClass:[self class]];
   NSMutableString *versionString = [[NSMutableString alloc]
      initWithString:[[bundle infoDictionary] 
      objectForKey:@"CFBundleShortVersionString"]];
   [version setStringValue:versionString];
   [versionString autorelease];
   [spoon setState:FALSE];
   // Hide spoon mode most of the time
   if ((random() % 5) != 3) {
      [spoon setTransparent:TRUE];
   } else {
      [spoon setTransparent:FALSE];
   }
   return w;
}

// Reset the values of the sliders to their defaults
- (IBAction)reset:(id)sender
{
   [strips setFloatValue:[STRIPS_DEFAULT floatValue]];
   [velocity setFloatValue:[VELOCITY_DEFAULT floatValue]];
   [depth setFloatValue:[DEPTH_DEFAULT floatValue]];
   [cycling setFloatValue:[CYCLING_DEFAULT floatValue]];
   [falling setFloatValue:[FALLING_DEFAULT floatValue]];
   [cursor setFloatValue:[CURSOR_DEFAULT floatValue]];
   [fog setFloatValue:[FOG_DEFAULT floatValue]];
   [topstart setState:TOPSTART_DEFAULT_BOOLEAN];
   [mainonly setState:MAINONLY_DEFAULT_BOOLEAN];
}

// The About button takes them to a web site
- (IBAction)about:(id)sender
{
   NSAppleScript *go = [[NSAppleScript alloc]
initWithSource:@"open location \"http://meta.ath0.com/redpill/\""];
   [go executeAndReturnError:nil];
}

- (IBAction)cancel:(id)sender
{
   [NSApp endSheet:[self window]];
}

- (IBAction)spoonclick:(id)sender
{
   [spoon setTransparent:FALSE];
}
   
- (IBAction)ok:(id)sender
{
   // Work out what our defaults are called
   NSString *identifier = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
   if(identifier == nil) {
      LogError("ok", "Trying to save preferences but identifier is nil.");
      [NSApp endSheet:[self window]];
      return;
   }
   // Load defaults
   ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:identifier];
   // Set values based on new positions and states of UI elements
   [defaults setFloat:[strips floatValue] forKey:STRIPS_KEY];
   [defaults setFloat:[velocity floatValue] forKey:VELOCITY_KEY];
   [defaults setFloat:[depth floatValue] forKey:DEPTH_KEY];
   [defaults setFloat:[cycling floatValue] forKey:CYCLING_KEY];
   [defaults setFloat:[falling floatValue] forKey:FALLING_KEY];
   [defaults setFloat:[cursor floatValue] forKey:CURSOR_KEY];
   [defaults setFloat:[fog floatValue] forKey:FOG_KEY];
   [defaults setBool:[topstart state] forKey:TOPSTART_KEY];
   [defaults setBool:[mainonly state] forKey:MAINONLY_KEY];
   // Plug web site if user selects spoon mode
   if ([spoon state] == TRUE) {
      NSRunAlertPanel(@"Realize", @"There is no spoon.", @"OK", nil, nil);
      [self about:sender];
   }
   // Update to disk
   [defaults synchronize];

   // Tell the main scrensaver loop to reload the preferences from us
   [[NSNotificationCenter defaultCenter] postNotificationName:PREFS_NOTIFICATION object:nil];
   
   [NSApp endSheet:[self window]];
}
@end
