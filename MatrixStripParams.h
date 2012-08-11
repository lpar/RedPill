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
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
// or visit <URL:http://www.fsf.org/>

// The parameters which determine the animation behavior
struct MatrixStripParams {
   GLfloat cellSize; // size of the quad containing one glyph
   int maxCellLife; // max lifetime of a living cell
   int numGlyphs; // number of glyphs available in texture
   int cursorChangeProbability; // percentage chance of cursor state change during drawing phase
   int cursorLiveProbability; // relative amounts of time the cursor spends drawing live cells,
   int cursorStaticProbability; // static cells,
   int cursorEmptyProbability; // or empty space
   int framesPerLivingCellChange; // how many 1/30ths of a second for each living cell to change glyph
   GLfloat cursorSpeed; // speed of cursor fall
   GLfloat maxDepth; // depth strips start at
   GLfloat minDepth; // depth at which strips are clipped away
   int maxStrips; // how many do we want?
   float spawnChance; // if we don't have enough stuff, what's the probability of adding more stuff
   // this animation frame? Changes to 1.0 after the first strip hits the front...
   GLfloat driftSpeed; // speed stuff drifts towards us at
   GLfloat aspectRatio; // we need this to work out when a strip falls off the sides of the visible area
   GLfloat minStartY; // 1.0 to start at top of screen, 0.0 to start at random point in top half
   GLfloat fogDensity; // 0 to 0.2, or you won't see anything
   GLfloat colorCycleSpeed; // color cycling speed
   GLfloat colorFallSpeed; // rate at which cycling colors fall
};
