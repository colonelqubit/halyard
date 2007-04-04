// -*- Mode: C++; tab-width: 4; c-basic-offset: 4; -*-
// @BEGIN_LICENSE
//
// Tamale - Multimedia authoring and playback system
// Copyright 1993-2006 Trustees of Dartmouth College
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

#ifndef EditBox_H
#define EditBox_H

#include "Widget.h"

class wxTextCtrl;

/// An edit box allows the user to edit a string of text.
class EditBox : public Widget {
    wxTextCtrl *mControl;

public:
    /// Create a new edit box.  inSize is the text size, in points, and
    /// inEnterIsEvent, if true, will cause presses of the Enter key to be
    /// passed to the script as an event.
    EditBox(Stage *inStage, const wxString &inName, 
            FIVEL_NS TCallbackPtr inDispatch,
            const wxRect &inBounds, const wxString inText,
            uint32 inSize, bool inIsMultiline, bool inEnterIsEvent);

    /// Get the current value of the text box.
    wxString GetValue() const;
};    

#endif // EditBox_H