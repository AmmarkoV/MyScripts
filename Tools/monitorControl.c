// To compile :
//gcc monitorControl.c -o monitorControl -lX11

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <X11/Xlib.h>
#include <X11/Xutil.h>
#include <X11/keysym.h>




void setWindowColorS(Display *display, Window window, unsigned char R, unsigned char G, unsigned char B) 
{
    XSetWindowAttributes attr;
    attr.background_pixel = ((R << 16) | (G << 8) | B);

    XChangeWindowAttributes(display, window, CWBackPixel, &attr);

    // Clear the entire window to trigger an Expose event
    XClearArea(display, window, 0, 0, 1, 1, True);

    XFlush(display);
}

void setWindowColor(Display *display, Window window, unsigned char R, unsigned char G, unsigned char B) 
{
    XSetWindowAttributes attr;
    attr.background_pixel = ((R << 16) | (G << 8) | B);

    XChangeWindowAttributes(display, window, CWBackPixel, &attr);

    // Trigger an Expose event
    XEvent exposeEvent;
    exposeEvent.type = Expose;
    exposeEvent.xexpose.window = window;
    XSendEvent(display, window, False, ExposureMask, &exposeEvent);
    
    XFlush(display);
}

int flushFIFO(char * str)
{    
    int fd = open(str, O_WRONLY| O_NONBLOCK);

    if (fd == -1) {
        perror("Failed to open FIFO");
        return 1;
    }

    // Write zero bytes to flush the FIFO
    if (write(fd, "", 0) == -1) {
        perror("Failed to flush FIFO");
        close(fd);
        return 1;
    }

    close(fd);
    return 0;
}



int main(void) 
{
    const int monWidth  = 1280;
    const int monHeight = 1024;

    int i=system("mkfifo /tmp/colorPipe1");
        i=system("mkfifo /tmp/colorPipe2");

    flushFIFO("/tmp/colorPipe1");
    flushFIFO("/tmp/colorPipe2");

    Display *disp = XOpenDisplay(NULL);
    if (disp != NULL) 
     {
        printf("Display :0 has 1 screen\n");

        int screenNumber = DefaultScreen(disp);

        // Create window 1 at position (0, 0)
        Window window1 = XCreateSimpleWindow(disp, RootWindow(disp, screenNumber), 0, 0, monWidth, monHeight+100, 0, 0, 0);
        XSelectInput(disp, window1, StructureNotifyMask | ExposureMask);
        XMapWindow(disp, window1);
        //XSetWindowAttributes attr1={0};
        //attr1.override_redirect = 1;
        //XChangeWindowAttributes(disp, window1, CWOverrideRedirect, &attr1);
        XRaiseWindow(disp, window1);
        setWindowColor(disp, window1, 255, 0, 0); // Red


        // Create window 2 at position (1921, 1081)
        Window window2 = XCreateSimpleWindow(disp, RootWindow(disp, screenNumber), monWidth+1 , 0, monWidth, monHeight+100, 0, 0, 0);
        XSelectInput(disp, window2, StructureNotifyMask | ExposureMask);
        //XSetWindowAttributes attr2={0};
        //attr2.override_redirect = 1;
        //XChangeWindowAttributes(disp, window2, CWOverrideRedirect, &attr2);
        XMapWindow(disp, window2);
        XRaiseWindow(disp, window2);
        setWindowColor(disp, window2, 0, 0, 255); // Blue

        XEvent event;
        while (1) 
        {
            XNextEvent(disp, &event);
            if (event.type == MapNotify)
                break;
        }
        
        fprintf(stderr,"READY\n");

        // Explicitly move window 2 to the correct position
        XMoveWindow(disp, window1, 0, 0);
        XMoveWindow(disp, window2, monWidth+1, 0);


        // Disable window decorations for both windows
        XSetTransientForHint(disp, window1, window1);
        XSetTransientForHint(disp, window2, window2);

 

       //Apply everything
       XClearWindow(disp, window1);
       XClearWindow(disp, window2);

        // Open pipes for communication
        int colorPipe1 = open("/tmp/colorPipe1", O_RDONLY | O_NONBLOCK);
        int colorPipe2 = open("/tmp/colorPipe2", O_RDONLY | O_NONBLOCK);

        if (colorPipe1 == -1 || colorPipe2 == -1) {
            perror("Failed to open pipes");
            return 1;
        }

       while (1) {
            fd_set fds;
            FD_ZERO(&fds);
            FD_SET(colorPipe1, &fds);
            FD_SET(colorPipe2, &fds);

            // Wait for data in the FIFOs
            int maxfd = colorPipe1 > colorPipe2 ? colorPipe1 : colorPipe2;
            select(maxfd + 1, &fds, NULL, NULL, NULL);

            unsigned char color1[3], color2[3];
            if (FD_ISSET(colorPipe1, &fds) && read(colorPipe1, color1, sizeof(color1)) == sizeof(color1)) {
                setWindowColor(disp, window1, color1[0], color1[1], color1[2]);
                XClearWindow(disp, window1);
                fprintf(stderr, "Altering Screen 1 to %u,%u,%u\n", color1[0], color1[1], color1[2]);
            }

            if (FD_ISSET(colorPipe2, &fds) && read(colorPipe2, color2, sizeof(color2)) == sizeof(color2)) {
                setWindowColor(disp, window2, color2[0], color2[1], color2[2]);
                XClearWindow(disp, window2);
                fprintf(stderr, "Altering Screen 2 to %u,%u,%u\n", color2[0], color2[1], color2[2]);
            }

            if (XPending(disp)) {
                XNextEvent(disp, &event);
                if (event.type == KeyPress) {
                    if (XLookupKeysym(&event.xkey, 0) == XK_Escape) {
                        break;  // Exit the loop if the Escape key is pressed
                    }
                }
            }
        }

        close(colorPipe1);
        close(colorPipe2);
        XCloseDisplay(disp);
    } else 
    {
        fprintf(stderr, "Unable to open display\n");
        return 1;
    }

    return 0;
}
