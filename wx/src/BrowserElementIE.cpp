// -*- Mode: C++; tab-width: 4; c-basic-offset: 4; -*-

#include "TamaleHeaders.h"
#include <IEHtmlWin.h>
#include <exdispid.h>
#include "BrowserElementIE.h"
#include "EventDispatcher.h"


//=========================================================================
//  CustomIEHtmlWindow Support Class
//=========================================================================
//  You will probably find the following documentation useful:
//
//    http://msdn.microsoft.com/workshop/browser/webbrowser/reflist_cpp.asp
//    http://msdn.microsoft.com/workshop/browser/prog_browser_node_entry.asp

enum {
	// XXX - Assign a real ID.
    ID_MSHTML = 592
};

class CustomIEHtmlWindow : public wxIEHtmlWin {
    BrowserElementIE *mElement;

public:
    CustomIEHtmlWindow(wxWindow *inParent,
                       const wxRect &inBounds,
                       BrowserElementIE *inElement);

private:
    void OnMSHTMLStatusTextChangeX(wxActiveXEvent& event);
    void OnMSHTMLWindowClosingX(wxActiveXEvent& event);
    void OnMSHTMLBeforeNavigate2X(wxActiveXEvent& event);
    void OnMSHTMLNavigateComplete2X(wxActiveXEvent& event);
    void OnMSHTMLTitleChangeX(wxActiveXEvent& event);
	void OnMSHTMLNewWindow2X(wxActiveXEvent& event);
    void OnMSHTMLProgressChangeX(wxActiveXEvent& event);

    DECLARE_EVENT_TABLE()
};

BEGIN_EVENT_TABLE(CustomIEHtmlWindow, wxIEHtmlWin)
    EVT_ACTIVEX_DISPID(ID_MSHTML, DISPID_STATUSTEXTCHANGE,
                       OnMSHTMLStatusTextChangeX)
	EVT_ACTIVEX(ID_MSHTML, "WindowClosing",     OnMSHTMLWindowClosingX)
    EVT_ACTIVEX(ID_MSHTML, "BeforeNavigate2",   OnMSHTMLBeforeNavigate2X)
    EVT_ACTIVEX(ID_MSHTML, "NavigateComplete2", OnMSHTMLNavigateComplete2X)
	EVT_ACTIVEX(ID_MSHTML, "TitleChange",       OnMSHTMLTitleChangeX)
	EVT_ACTIVEX(ID_MSHTML, "NewWindow2",        OnMSHTMLNewWindow2X)
	EVT_ACTIVEX(ID_MSHTML, "ProgressChange",    OnMSHTMLProgressChangeX)
END_EVENT_TABLE()

CustomIEHtmlWindow::CustomIEHtmlWindow(wxWindow *inParent,
                                       const wxRect &inBounds,
                                       BrowserElementIE *inElement)
    : wxIEHtmlWin(inParent, ID_MSHTML,
                  inBounds.GetPosition(), inBounds.GetSize(), wxSIMPLE_BORDER),
      mElement(inElement)
{
    // Don't allow the browser window to be resized.  I don't know if this
    // actually accomplishes anything, or whether it's merely advisory.
    m_webBrowser->put_Resizable(VARIANT_FALSE);
}

void CustomIEHtmlWindow::OnMSHTMLStatusTextChangeX(wxActiveXEvent& event) {
    mElement->GetDispatcher()->DoEventStatusTextChanged(event["Text"]);
}

void CustomIEHtmlWindow::OnMSHTMLWindowClosingX(wxActiveXEvent& event) {
    // Naughty, naughty.  We don't want JavaScript to close our window.
    event["Cancel"] = true;
}

void CustomIEHtmlWindow::OnMSHTMLBeforeNavigate2X(wxActiveXEvent& event) {
    bool vetoed;
    mElement->GetDispatcher()->DoEventBrowserNavigate(event["Url"], vetoed);
    if (vetoed)
        event["Cancel"] = true;
}

void CustomIEHtmlWindow::OnMSHTMLNavigateComplete2X(wxActiveXEvent& event) {
    // We can't use event["Url"], because it may be the URL of a sub-page.
    mElement->GetDispatcher()->DoEventBrowserPageChanged(LocationUrl());
}

void CustomIEHtmlWindow::OnMSHTMLTitleChangeX(wxActiveXEvent& event) {
    // TODO - event["Text"] includes URLs as well as titles.  Ick.  I'm
    // not quite sure how to fix this, actually.
    mElement->GetDispatcher()->DoEventBrowserTitleChanged(event["Text"]);
}

void CustomIEHtmlWindow::OnMSHTMLNewWindow2X(wxActiveXEvent& event) {
    // Theoretically, we can do 'event["Cancel"] = true' to force all
    // navigation to occur in the current window.  Unfortunately, this
    // is pretty broken in various IE versions. See
    //
    //   http://support.microsoft.com/default.aspx?scid=kb;EN-US;Q294870
    //   http://support.microsoft.com/default.aspx?scid=kb;EN-US;185538
    //
    // So we're just going to allow IE to create new windows.  Ick.
}

void CustomIEHtmlWindow::OnMSHTMLProgressChangeX(wxActiveXEvent& event) {
    long progress = event["Progress"];
    long progress_max = event["ProgressMax"];
    bool is_done = true;
    double value = 0.0;

    // progress == -1 means we should hide the progress gauge, because
    // nothing is happening.
    if (progress != -1) {
        is_done = false;
        if (progress_max != 0.0)
            value = (1.0 * progress) / progress_max;
        else
            value = 0.0;
    }
    mElement->GetDispatcher()->DoEventProgressChanged(is_done, value);    
}


//=========================================================================
//  BrowserElementIE Methods
//=========================================================================

BrowserElementIE::BrowserElementIE(Stage *inStage, const wxString &inName,
                                   const wxRect &inBounds,
                                   FIVEL_NS TCallback *inDispatch)
    : BrowserElement(inStage, inName, inDispatch)
                      
{
    mHtmlWindow = new CustomIEHtmlWindow(inStage, inBounds, this);
    InitializeWidgetWindow(mHtmlWindow);
}

void BrowserElementIE::LoadPage(const wxString &inUrl){
    mHtmlWindow->LoadUrl(inUrl);
}

wxString BrowserElementIE::GetCurrentPageUrl() {
    // XXX - We can figure this out somehow.
    return "about:blank";
}

wxString BrowserElementIE::GetCurrentPageTitle() {
    // XXX - We can figure this out somehow.
    return "";
}

bool BrowserElementIE::CanGoBack() {
    // XXX - We can figure this out from the control update events.
    return true;
}

bool BrowserElementIE::GoBack() {
    return mHtmlWindow->GoBack();
}

bool BrowserElementIE::CanGoForward() {
    // XXX - We can figure this out from the control update events.
    return true;
}

bool BrowserElementIE::GoForward() {
    return mHtmlWindow->GoForward();
}

bool BrowserElementIE::CanRefresh() {
    return true;
}

bool BrowserElementIE::Refresh() {
    return mHtmlWindow->Refresh(wxIEHTML_REFRESH_NORMAL);
}

bool BrowserElementIE::CanStop() {
    // XXX - We can figure this out using various page load events.
    return true;
}

bool BrowserElementIE::Stop() {
    return mHtmlWindow->Stop();
}
