/***************************************************************
 * Name:      StartupCommanderMain.cpp
 * Purpose:   Code for Application Frame
 * Author:    Ammar Qammaz (ammarkov+rgbd@gmail.com)
 * Created:   2017-10-31
 * Copyright: Ammar Qammaz (http://ammar.gr)
 * License:
 **************************************************************/

#include "StartupCommanderMain.h"
#include <wx/msgdlg.h>

//(*InternalHeaders(StartupCommanderFrame)
#include <wx/string.h>
#include <wx/intl.h>
//*)

//helper functions
enum wxbuildinfoformat {
    short_f, long_f };

wxString wxbuildinfo(wxbuildinfoformat format)
{
    wxString wxbuild(wxVERSION_STRING);

    if (format == long_f )
    {
#if defined(__WXMSW__)
        wxbuild << _T("-Windows");
#elif defined(__UNIX__)
        wxbuild << _T("-Linux");
#endif

#if wxUSE_UNICODE
        wxbuild << _T("-Unicode build");
#else
        wxbuild << _T("-ANSI build");
#endif // wxUSE_UNICODE
    }

    return wxbuild;
}

//(*IdInit(StartupCommanderFrame)
const long StartupCommanderFrame::ID_BUTTON1 = wxNewId();
const long StartupCommanderFrame::ID_BUTTON2 = wxNewId();
const long StartupCommanderFrame::ID_GAUGE1 = wxNewId();
const long StartupCommanderFrame::idMenuQuit = wxNewId();
const long StartupCommanderFrame::idMenuAbout = wxNewId();
const long StartupCommanderFrame::ID_STATUSBAR1 = wxNewId();
//*)

BEGIN_EVENT_TABLE(StartupCommanderFrame,wxFrame)
    //(*EventTable(StartupCommanderFrame)
    //*)
END_EVENT_TABLE()

StartupCommanderFrame::StartupCommanderFrame(wxWindow* parent,wxWindowID id)
{
    //(*Initialize(StartupCommanderFrame)
    wxMenuItem* MenuItem2;
    wxMenuItem* MenuItem1;
    wxMenu* Menu1;
    wxMenuBar* MenuBar1;
    wxMenu* Menu2;

    Create(parent, id, _("StartupCommander"), wxDefaultPosition, wxDefaultSize, wxDEFAULT_FRAME_STYLE, _T("id"));
    SetClientSize(wxSize(553,450));
    ButtonStartup = new wxButton(this, ID_BUTTON1, _("Use Startup File"), wxPoint(88,104), wxSize(368,88), 0, wxDefaultValidator, _T("ID_BUTTON1"));
    ButtonExit = new wxButton(this, ID_BUTTON2, _("Exit"), wxPoint(88,264), wxSize(368,32), 0, wxDefaultValidator, _T("ID_BUTTON2"));
    GaugeTimeout = new wxGauge(this, ID_GAUGE1, 100, wxPoint(88,192), wxSize(368,28), 0, wxDefaultValidator, _T("ID_GAUGE1"));
    MenuBar1 = new wxMenuBar();
    Menu1 = new wxMenu();
    MenuItem1 = new wxMenuItem(Menu1, idMenuQuit, _("Quit\tAlt-F4"), _("Quit the application"), wxITEM_NORMAL);
    Menu1->Append(MenuItem1);
    MenuBar1->Append(Menu1, _("&File"));
    Menu2 = new wxMenu();
    MenuItem2 = new wxMenuItem(Menu2, idMenuAbout, _("About\tF1"), _("Show info about this application"), wxITEM_NORMAL);
    Menu2->Append(MenuItem2);
    MenuBar1->Append(Menu2, _("Help"));
    SetMenuBar(MenuBar1);
    StatusBar1 = new wxStatusBar(this, ID_STATUSBAR1, 0, _T("ID_STATUSBAR1"));
    int __wxStatusBarWidths_1[1] = { -1 };
    int __wxStatusBarStyles_1[1] = { wxSB_NORMAL };
    StatusBar1->SetFieldsCount(1,__wxStatusBarWidths_1);
    StatusBar1->SetStatusStyles(1,__wxStatusBarStyles_1);
    SetStatusBar(StatusBar1);

    Connect(ID_BUTTON1,wxEVT_COMMAND_BUTTON_CLICKED,(wxObjectEventFunction)&StartupCommanderFrame::OnButtonStartupClick);
    Connect(ID_BUTTON2,wxEVT_COMMAND_BUTTON_CLICKED,(wxObjectEventFunction)&StartupCommanderFrame::OnButtonExitClick);
    Connect(idMenuQuit,wxEVT_COMMAND_MENU_SELECTED,(wxObjectEventFunction)&StartupCommanderFrame::OnQuit);
    Connect(idMenuAbout,wxEVT_COMMAND_MENU_SELECTED,(wxObjectEventFunction)&StartupCommanderFrame::OnAbout);
    //*)
}

StartupCommanderFrame::~StartupCommanderFrame()
{
    //(*Destroy(StartupCommanderFrame)
    //*)
}

void StartupCommanderFrame::OnQuit(wxCommandEvent& event)
{
    Close();
}

void StartupCommanderFrame::OnAbout(wxCommandEvent& event)
{
    wxString msg = wxbuildinfo(long_f);
    wxMessageBox(msg, _("Welcome to..."));
}

void StartupCommanderFrame::OnButtonExitClick(wxCommandEvent& event)
{
    Close();
}

void StartupCommanderFrame::OnButtonStartupClick(wxCommandEvent& event)
{
  //wxExecute("/home/ammar/.autorun.sh",wxEXEC_ASYNC);
  //int i=system("/bin/bash /home/ammar/testScript.sh&");
  int i=system("/bin/bash /home/ammar/.startupcommander.sh &");
  if (i!=0) {fprintf(stderr,"Could not execute script..");}

  Close();
}
