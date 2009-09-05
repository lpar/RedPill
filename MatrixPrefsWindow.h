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

#import <Cocoa/Cocoa.h>
#import <AppKit/AppKit.h>
#import <ScreenSaver/ScreenSaver.h>

#import "GLUtils.h"

// Strings to use when saving the preferences
#define STRIPS_KEY @"strips"
#define VELOCITY_KEY @"velocity"
#define DEPTH_KEY @"depth"
#define CYCLING_KEY @"cycling"
#define FALLING_KEY @"falling"
#define CURSOR_KEY @"cursor"
#define FOG_KEY @"fog"
#define TOPSTART_KEY @"topstart"
#define MAINONLY_KEY @"mainonly"
#define SPOON_KEY @"spoon"

// Default values for same
#define STRIPS_DEFAULT @"50"
#define VELOCITY_DEFAULT @"40"
#define DEPTH_DEFAULT @"200"
#define CYCLING_DEFAULT @"5"
#define FALLING_DEFAULT @"2"
#define CURSOR_DEFAULT @"10"
#define FOG_DEFAULT @"15"
#define TOPSTART_DEFAULT @"YES"
#define TOPSTART_DEFAULT_BOOLEAN TRUE
#define MAINONLY_DEFAULT @"NO"
#define MAINONLY_DEFAULT_BOOLEAN FALSE
#define SPOON_DEFAULT @"NO"
#define SPOON_DEFAULT_BOOLEAN FALSE

// Notification to send the main object
#define PREFS_NOTIFICATION @"PreferencesChanged"

@interface MatrixPrefsWindow :  NSWindowController
{
   IBOutlet NSSlider *strips;
   IBOutlet NSSlider *velocity;
   IBOutlet NSSlider *depth;
   IBOutlet NSSlider *cycling;
   IBOutlet NSSlider *falling;
   IBOutlet NSSlider *cursor;
   IBOutlet NSSlider *fog;
   IBOutlet NSButton *topstart;
   IBOutlet NSButton *mainonly;
   IBOutlet NSButton *spoon;
   IBOutlet NSTextField *version;
}

- (IBAction)cancel:(id)sender;
- (IBAction)ok:(id)sender;
- (IBAction)about:(id)sender;
- (IBAction)reset:(id)sender;
- (IBAction)spoonclick:(id)sender;
@end
