#import <Cocoa/Cocoa.h>

#define RASTERIZER

#include "CNFGFunctions.h"
#include "CNFGRasterizer.h"

id app_menubar, app_appMenuItem, app_appMenu, app_appName, app_quitMenuItem, app_quitTitle, app_quitMenuItem, app_window;
id app_imageView;

NSAutoreleasePool *app_pool;
int app_sw=0, app_sh=0;
int app_mouseX=0, app_mouseY=0;
char app_mouseDown[3] = {0,0,0};

void CNFGGetDimensions( short * x, short * y )
{
    *x = app_sw;
    *y = app_sh;
}

void CNFGSetup( const char * WindowName, int sw, int sh )
{
    app_sw=sw; app_sh=sh;
    [NSAutoreleasePool new];
    [NSApplication sharedApplication];
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    app_menubar = [[NSMenu new] autorelease];
    app_appMenuItem = [[NSMenuItem new] autorelease];
    [app_menubar addItem:app_appMenuItem];
    [NSApp setMainMenu:app_menubar];
    app_appMenu = [[NSMenu new] autorelease];
    app_appName = [[NSProcessInfo processInfo] processName];
    app_quitTitle = [@"Quit " stringByAppendingString:app_appName];
    app_quitMenuItem = [[[NSMenuItem alloc] initWithTitle:app_quitTitle
        action:@selector(terminate:) keyEquivalent:@"q"] autorelease];
    [app_appMenu addItem:app_quitMenuItem];
    [app_appMenuItem setSubmenu:app_appMenu];
    app_window = [[[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, app_sw, app_sh)
        styleMask:NSWindowStyleMaskBorderless | NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable backing:NSBackingStoreBuffered defer:NO]
            autorelease];

    app_imageView = [[NSImageView alloc] init];

    NSString *title = [[NSString alloc] initWithCString: WindowName encoding: NSUTF8StringEncoding];
    [app_window setTitle:title];
    [app_window setContentView:app_imageView];
    [app_window cascadeTopLeftFromPoint:NSMakePoint(20,20)];
    [app_window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
    [NSApp finishLaunching];
    [NSApp updateWindows];
    app_pool = [[NSAutoreleasePool alloc] init];
}

#define XK_Left                          0xff51  /* Move left, left arrow */
#define XK_Up                            0xff52  /* Move up, up arrow */
#define XK_Right                         0xff53  /* Move right, right arrow */
#define XK_Down                          0xff54  /* Move down, down arrow */
#define KEY_UNDEFINED 255
#define KEY_LEFT_MOUSE 0

// NSEvent enum types
#define EVENT_KEY_DOWN        10
#define EVENT_KEY_UP          11
#define EVENT_LEFT_MOUSE_DOWN 1
#define EVENT_LEFT_MOUSE_UP   2

static int keycode(key)
{
    if (key < 256) return key;
    switch(key) {
        case 63232: return XK_Up;
        case 63233: return XK_Down;
        case 63234: return XK_Left;
        case 63235: return XK_Right;
    }
    return KEY_UNDEFINED;
}

void CNFGHandleInput()
{
printf("CNFGHandleInput\n");

    // Quit if no open windows left
    if ([[NSApp windows] count] == 0) [NSApp terminate: nil];
    //----------------------
    // Check for mouse motion (NOTE: the mouse move event
    //  has complex behavior after a mouse click.
    //  we can work around this by checking mouse motion explicitly)
    //----------------------
    NSPoint location = [app_window mouseLocationOutsideOfEventStream];
    if ((int)location.x != app_mouseX || (int)location.y != app_mouseY) {
        app_mouseX = (int)location.x;
        app_mouseY = (int)location.y;
        if (app_mouseX >= 0 && app_mouseX < app_sw &&
            app_mouseY >= 0 && app_mouseY < app_sh)
        {
            HandleMotion(app_mouseX, app_mouseY, app_mouseDown[0]||app_mouseDown[1]||app_mouseDown[2]);
        }
    }

    //----------------------
    // Peek at the next event
    //----------------------
    NSDate *app_currDate = [NSDate new];

    // If we have events, handle them!
    NSEvent *event;
    for (;(event = [NSApp
                    nextEventMatchingMask:NSEventMaskAny
                    untilDate:app_currDate
                    inMode:NSDefaultRunLoopMode
                    dequeue:YES]);)
    {
        NSEventType type = [event type];
        switch (type)
        {
            case NSEventTypeKeyDown:
                for (int i=0; i<[event.characters length]; i++) {
                    unichar ch = [event.characters characterAtIndex: i];
                    HandleKey(keycode(ch), 1);
                }
                break;
                
            case NSEventTypeKeyUp:
                for (int i=0; i<[event.characters length]; i++) {
                    unichar ch = [event.characters characterAtIndex: i];
                    HandleKey(keycode(ch), 0);
                }
                break;
                    
            case NSEventTypeLeftMouseDown:
                HandleButton(app_mouseX, app_mouseY, KEY_LEFT_MOUSE, 1);
                app_mouseDown[0]=1;
                break;
                    
            case NSEventTypeLeftMouseUp:
                HandleButton(app_mouseX, app_mouseY, KEY_LEFT_MOUSE, 0);
                app_mouseDown[0]=0;
                break;

            default:
                break;
        }
        [NSApp sendEvent:event];
    }
    [app_currDate release];
}

void CNFGUpdateScreenWithBitmap( unsigned long * data, int w, int h )
{
    [app_pool release];
    app_pool = [NSAutoreleasePool new];

    NSBitmapImageRep *bitmap = [[NSBitmapImageRep alloc]
        initWithBitmapDataPlanes:(unsigned char **)&data pixelsWide:w
        pixelsHigh:h bitsPerSample:8 samplesPerPixel:3 hasAlpha:NO
        isPlanar:NO colorSpaceName:NSCalibratedRGBColorSpace
        bitmapFormat: 0
        bytesPerRow:(w*4) bitsPerPixel:32];

    id new_image = [[[NSImage alloc] initWithSize:[bitmap size]] autorelease];
    [new_image addRepresentation:bitmap];
    [app_imageView setImage: new_image];
    [app_imageView setNeedsDisplay:YES];
    [bitmap release];
}

