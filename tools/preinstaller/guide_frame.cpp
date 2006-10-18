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

// This code was originally based on the example code at
// <http://wxwidgets.org/docs/tutorials/hello.htm>.

#include "stdafx.h"
#include "guide_frame.h"
#include "application.h"

#define BIG_SPACE 20
#define LITTLE_SPACE 10
#define BITMAP_RIGHT_SPACE 12
#define SHOW_DEBUGGING 0

enum {
    ID_Timer = 1,

    ID_InstallQuickTime = 1,
    ID_InstallApplication
};

BEGIN_EVENT_TABLE(GuideFrame, wxFrame)
    EVT_BUTTON(ID_InstallQuickTime, GuideFrame::OnInstallQuickTime)
    EVT_TIMER(ID_Timer, GuideFrame::OnTimer)
    EVT_ACTIVATE(GuideFrame::OnActivate)
    EVT_BUTTON(ID_InstallApplication, GuideFrame::OnInstallApplication)
    EVT_CLOSE(GuideFrame::OnClose)
END_EVENT_TABLE()

GuideFrame::GuideFrame(bool shouldWarnAboutProLicense)
    : wxFrame((wxFrame *)NULL, -1,
              "Setup - " + wxGetApp().GetApplicationName(),
              wxDefaultPosition, wxDefaultSize,
              wxCLOSE_BOX|wxSYSTEM_MENU|wxCAPTION),
      mShouldWarnAboutProLicense(shouldWarnAboutProLicense),
      mInForeground(true), // Arbitrary value--will be updated later.
      mShouldCheckQuickTimeVersionWhenInForeground(false),
      mTitleFont(14, wxSWISS, wxNORMAL, wxNORMAL),
      mStepHeadingFont(8, wxSWISS, wxNORMAL, wxBOLD),
      mBlankBitmap(wxBITMAP(BLANK)), mArrowBitmap(wxBITMAP(ARROW)),
      mCheckBitmap(wxBITMAP(CHECK))
{   
    // Set the owner of our mTimer object.
    mTimer.SetOwner(this, ID_Timer);

    // Set our icon.
    SetIcon(wxICON(wxDEFAULT_FRAME));

    // A status bar for debugging purposes.
    if (SHOW_DEBUGGING)
        CreateStatusBar();

    // Create a white window background.  This looks more "installer-like".
    // Make the foreground text black for a clean contrast.
    mBackground = new wxPanel(this, -1, wxDefaultPosition, wxDefaultSize);
    mBackground->SetBackgroundColour(*wxWHITE);
    mBackground->SetForegroundColour(*wxBLACK);

    // Create the sizer for our main column.
    mMainColumn = new wxBoxSizer(wxVERTICAL);

    // Add our title text, and wrap it to a reasonable number of pixels.  This
    // controls the overall size of our window.  Based on code generated by
    // the DialogBlocks GUI editor.
    wxString app_name(wxGetApp().GetApplicationName());
    wxStaticText *title =
        new wxStaticText(mBackground, -1, wxGetApp().GetWelcomeMessage());
    title->SetFont(mTitleFont);
    // Wrap() is not available until wx2.6.2, so GetWelcomeMessage() is
    // currently supplying prewrapped text. Ick.
    //title->SetSize(300, -1);
    //title->Wrap(); 
    mMainColumn->Add(title, 0, wxGROW|wxALL|wxADJUST_MINSIZE, BIG_SPACE);

    // Insert some extra vertical space below our large title.
    mMainColumn->AddSpacer(LITTLE_SPACE);

    // Create each of our steps, and the corresponding buttons.  The
    // special characters for <tm> and (R) are given as octal values
    // in ISO Latin 1.
    // TODO - Do a whole Unicode song and dance to deal with various
    // unfriendly code pages.
    CreateStepHeading(1, "Install QuickTime\256 video support");
    mQTButton  = CreateStepButton(ID_InstallQuickTime, "QuickTime");
    CreateStepHeading(2, "Install " + app_name + "\231");
    mAppButton = CreateStepButton(ID_InstallApplication, app_name);

    // Set up our initial button state.
    mQTButton.bitmap->SetBitmap(mArrowBitmap);
    mAppButton.button->Disable();

    // Attach the sizer.  For now, we only have one column.
    mBackground->SetSizerAndFit(mMainColumn);
    Fit();

    // Position this frame in the center of the screen.
    CenterOnScreen();
}

/// Add a heading of the form "Step N: Blah" to mMainColumn.
void GuideFrame::CreateStepHeading(int number, const wxString &heading) {
    // Based on code generated by the DialogBlocks GUI editor.

    // Assemble the string we'll display.
    wxString label;
    label.Printf("Step %d: ", number);
    label += heading;
    
    // Build our static text object.
    wxStaticText *text = new wxStaticText(mBackground, wxID_STATIC, label);
    text->SetFont(mStepHeadingFont);
    mMainColumn->Add(text, 0, wxALIGN_LEFT|wxLEFT|wxRIGHT|wxADJUST_MINSIZE, 
                     BIG_SPACE);

    // Insert a smaller space between us and our button.
    mMainColumn->AddSpacer(LITTLE_SPACE);
}

/// Add a bitmap and button pair to mMainColumn.
GuideFrame::CheckableButton
GuideFrame::CreateStepButton(int id, const wxString &name) {
    // Based on code generated by the DialogBlocks GUI editor.

    // Create a horizontal sizer to hold our bitmap and button.
    wxBoxSizer* sizer = new wxBoxSizer(wxHORIZONTAL);
    mMainColumn->Add(sizer, 0, wxGROW|wxLEFT|wxRIGHT|wxBOTTOM, BIG_SPACE);

    // Create our bitmap.
    wxStaticBitmap *bitmap =
        new wxStaticBitmap(mBackground, wxID_STATIC, mBlankBitmap,
                           wxDefaultPosition,
                           wxSize(mBlankBitmap.GetWidth(),
                                  mBlankBitmap.GetHeight()));
    sizer->Add(bitmap, 0, wxALIGN_CENTER_VERTICAL|wxRIGHT, BITMAP_RIGHT_SPACE);

    // Create our button.
    wxButton* button = new wxButton(mBackground, id, "Install " + name);
    sizer->Add(button, 0, wxALIGN_CENTER_VERTICAL);

    // Create a place to put progress messages.
    wxStaticText *message = new wxStaticText(mBackground, -1, "");
    sizer->Add(message, 0, wxLEFT|wxALIGN_CENTER_VERTICAL, LITTLE_SPACE);

    // Return our bitmap and button pointers.
    return CheckableButton(bitmap, button, message);
}

static const char *kUpgradeWarning =
"Important notice for QuickTime Pro users:\n\n"
"Upgrading to QuickTime " QUICKTIME_MAJOR_VERSION " will disable any\n"
"QuickTime Pro functionality in earlier\n"
"versions of QuickTime. To reenable Pro\n"
"features, you will need to purchase a new\n"
"QuickTime Pro key from Apple Computer,\n"
"Inc.  Continue installing?";

bool GuideFrame::ConfirmLossOfQuickTimeProOK() {
    wxMessageDialog dialog(this, kUpgradeWarning, "QuickTime Pro Notice",
                           wxYES_NO | wxYES_DEFAULT | wxICON_WARNING);
    return (dialog.ShowModal() == wxID_YES);
}

/// When the user clicks on "Install QuickTime", disable the button, launch
/// the installer, and start our background timer.
void GuideFrame::OnInstallQuickTime(wxCommandEvent& event) {
    if (mShouldWarnAboutProLicense && !ConfirmLossOfQuickTimeProOK()) {
        Destroy();
        return;
    }

    mQTButton.button->Disable();
    mQTButton.message->SetLabel("Installing...");
    wxGetApp().LaunchQuickTimeInstaller();

    // We want to start checking the QuickTime version.
    mShouldCheckQuickTimeVersionWhenInForeground = true;

    // Send a timer event periodically.  We don't want to do this too
    // often, because checking the QuickTime version is fairly expensive.
    mTimer.Start(3000, wxTIMER_CONTINUOUS);
}

/// Periodically check the current QuickTime version.
void GuideFrame::OnTimer(wxTimerEvent& event) {
    wxASSERT(mShouldCheckQuickTimeVersionWhenInForeground);

    // XXX - Only check the QuickTime version when we're in the foreground.
    // If we check the QuickTime version while we're in the background, it
    // greatly increases the odds that the QuickTime installer will notice
    // us, and try to force us to quit!
    //
    // We'd like to have a less ugly workaround, but so far, all the known
    // fixes for this bug have a *lot* of moving parts.  We're going to go
    // with this approach, which should at least prevent most QT <6.5 users
    // from having to run the installer twice.
    if (mInForeground)
        CheckQuickTimeVersion();
}

// Keep track of whether we're in the foreground or the background (so we
// know whether to enable our timer-based checks), and check the QuickTime
// version when we get switched into the foreground.
void GuideFrame::OnActivate(wxActivateEvent& event) {
    if (event.GetActive()) {
        mInForeground = true;
        if (mShouldCheckQuickTimeVersionWhenInForeground) {
            // Repaint the window immediately, so the user sees something
            // useful while we check the QuickTime version.
            ForceImmediateRedraw();
            CheckQuickTimeVersion();
        }
    } else {
        mInForeground = false;
    }
}

/// Check the QuickTime version.  When we appear to have a correct version
/// of QuickTime installed, then the QuickTime installer is *almost*
/// through running, and we can enable our "Install App" button and disable
/// the timer.
void GuideFrame::CheckQuickTimeVersion() {
    wxASSERT(mShouldCheckQuickTimeVersionWhenInForeground);
    wxASSERT(mInForeground);

    if (wxGetApp().GetQuickTimeInstallStatus() == Application::QUICKTIME_OK) {
        mQTButton.bitmap->SetBitmap(mCheckBitmap);
        mQTButton.message->SetLabel("");
        mAppButton.bitmap->SetBitmap(mArrowBitmap);
        mAppButton.button->Enable();
        mTimer.Stop();
        mShouldCheckQuickTimeVersionWhenInForeground = false;
    }

    if (SHOW_DEBUGGING) {
        wxString str;
        str.Printf("QuickTime version: %08x", wxGetApp().QuickTimeVersion());
        SetStatusText(str);
    }
}

/// Launch our application installer and exit this program.
void GuideFrame::OnInstallApplication(wxCommandEvent& event) {
    mAppButton.button->Disable();
    wxGetApp().LaunchApplicationInstaller();
    Destroy(); // Bypass the checks in OnClose().
}

/// If appropriate, ask the user if they really want to quit.
void GuideFrame::OnClose(wxCloseEvent &event) {
    // Only warn the user if we're allowed to veto this event.
    if (event.CanVeto()) {
        // Warn the user.
        wxString msg("Exit without installing " +
                     wxGetApp().GetApplicationName() + "?");
        wxMessageDialog dialog(this, msg, "Exit Setup",
                               wxYES_NO | wxNO_DEFAULT | wxICON_QUESTION);
        if (dialog.ShowModal() == wxID_NO) {
            // They don't want to exit, so veto the event.
            event.Veto();
            return;
        }
    }

    // If we reach here, destroy our frame and quit.
    Destroy();
}

void GuideFrame::ForceImmediateRedraw() {
    // According to the manual, this sequence of calls will first
    // invalidate the entire window (thanks to Refresh) and then redraw it
    // immediately (thanks to Update).
    Refresh();
    Update();
}
