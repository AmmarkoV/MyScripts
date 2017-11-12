/***************************************************************
 * Name:      StartupCommanderApp.cpp
 * Purpose:   Code for Application Class
 * Author:    Ammar Qammaz (ammarkov+rgbd@gmail.com)
 * Created:   2017-10-31
 * Copyright: Ammar Qammaz (http://ammar.gr)
 * License:
 **************************************************************/

#include "StartupCommanderApp.h"

//(*AppHeaders
#include "StartupCommanderMain.h"
#include <wx/image.h>
//*)

IMPLEMENT_APP(StartupCommanderApp);

bool StartupCommanderApp::OnInit()
{
    //(*AppInitialize
    bool wxsOK = true;
    wxInitAllImageHandlers();
    if ( wxsOK )
    {
    	StartupCommanderFrame* Frame = new StartupCommanderFrame(0);
    	Frame->Show();
    	SetTopWindow(Frame);
    }
    //*)
    return wxsOK;

}
