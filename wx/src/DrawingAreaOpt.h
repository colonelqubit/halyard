// -*- Mode: C++; tab-width: 4; c-basic-offset: 4; -*-
// @BEGIN_LICENSE
//
// Halyard - Multimedia authoring and playback system
// Copyright 1993-2009 Trustees of Dartmouth College
// 
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
//
// @END_LICENSE

#ifndef DrawingAreaOpt_H
#define DrawingAreaOpt_H

#include <wx/rawbmp.h>

// These functions require raw bitmap access because they work with
// alpha channels.  Most of them are parameterized for PixelData type
// so they can work with both wxNativePixelData and wxAlphaPixelData.

template <class PixelData> extern
void DrawPixMapOpt(PixelData &inDstData,
				   GraphicsTools::Point inPoint,
				   GraphicsTools::PixMap &inPixMap);

template <class PixelData> extern
void FillBoxOpt(PixelData &inDstData,
				const wxRect &inBounds,
				const GraphicsTools::Color &inColor);

extern
void ClearOpt(wxAlphaPixelData &inDstData,
			  const GraphicsTools::Color &inColor);

extern
void MaskOpt(wxAlphaPixelData &inDstData,
             wxAlphaPixelData &inMaskData,
             wxCoord inX, wxCoord inY);

#endif // DrawingAreaOpt_H
