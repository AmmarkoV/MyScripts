/***************************************************************
 * Name:      StartupCommanderMain.h
 * Purpose:   Defines Application Frame
 * Author:    Ammar Qammaz (ammarkov+rgbd@gmail.com)
 * Created:   2017-10-31
 * Copyright: Ammar Qammaz (http://ammar.gr)
 * License:
 **************************************************************/

#ifndef STARTUPCOMMANDERMAIN_H
#define STARTUPCOMMANDERMAIN_H

//(*Headers(StartupCommanderFrame)
#include <wx/gauge.h>
#include <wx/button.h>
#include <wx/menu.h>
#include <wx/statusbr.h>
#include <wx/frame.h>
#include <wx/timer.h>
//*)

class StartupCommanderFrame: public wxFrame
{
    public:

        StartupCommanderFrame(wxWindow* parent,wxWindowID id = -1);
        virtual ~StartupCommanderFrame();

    private:

        //(*Handlers(StartupCommanderFrame)
        void OnQuit(wxCommandEvent& event);
        void OnAbout(wxCommandEvent& event);
        void OnButtonExitClick(wxCommandEvent& event);
        void OnButtonStartupClick(wxCommandEvent& event);
        void OnTimer1Trigger(wxTimerEvent& event);
        //*)

        //(*Identifiers(StartupCommanderFrame)
        static const long ID_BUTTON1;
        static const long ID_BUTTON2;
        static const long ID_GAUGE1;
        static const long idMenuQuit;
        static const long idMenuAbout;
        static const long ID_STATUSBAR1;
        static const long ID_TIMER1;
        //*)

        //(*Declarations(StartupCommanderFrame)
        wxStatusBar* StatusBar1;
        wxGauge* GaugeTimeout;
        wxTimer Timer1;
        wxButton* ButtonExit;
        wxButton* ButtonStartup;
        //*)

        DECLARE_EVENT_TABLE()
};

#endif // STARTUPCOMMANDERMAIN_H
