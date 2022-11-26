#SingleInstance

TraySetIcon('Shell32.dll', 19)
CoordMode('Mouse', 'Screen')



; max dimensions of the grid thickness when changing their size with + and - hotkeys (aka = and -)
maxThickness := 5

; color of the grid lines
gridColor := '00ff00'



; -------------------------------------------------------------------------------
; HOTKEYS
; -------------------------------------------------------------------------------
$F4::       ; press once to send F4, press twice within 250ms to toggle grid alignment tool
{
    static presses := 0

    if presses > 0 {            ; if SetTimer is already started, add keypresses
        presses += 1
        return
    }

    presses := 1
    SetTimer(After250ms, -250)  ; wait for more presses within a 250 millisecond window.

    After250ms()                ; perform actions based on keypresses within 250ms
    {
        if presses = 1 {
            Send('{F4}')
        }
        else if presses = 2 {   ; the if and else here that create or destroy the grid are the important parts to keep if you want a simpler hotkey
            if IsSet(Horizontal_Line) or IsSet(Vertical_Line)
                Destroy_Align_Tool()
            else
                CreateAlignmentGrid()
        }
        presses := 0    ; reset keypress to prepare for the next series of presses
    }
}



#HotIf IsSet(Horizontal_Line) or IsSet(Vertical_Line)

    ; move grid one pixel in given direction
    Up::MoveUpOrDown(-1)
    Down::MoveUpOrDown(1)
    Left::MoveLeftOrRight(-1)
    Right::MoveLeftOrRight(1)


    =:: ; increase grid thickness
    {
        Horizontal_Line.GetPos(,,, &height)
        Horizontal_Line.Move(,,, height+1 <= maxThickness ? height+1 : height)

        Vertical_Line.GetPos(,, &width)
        Vertical_Line.Move(,, width+1 <= maxThickness ? width+1 : width)
    }


    -:: ; decrease grid thickness
    {
        Horizontal_Line.GetPos(,,, &height)
        Horizontal_Line.Move(,,, height-1 > 0 ? height-1 : height)

        Vertical_Line.GetPos(,, &width)
        Vertical_Line.Move(,, width-1 > 0 ? width-1 : width)
    }


    ~LButton::  ; re-position the grid
    {
        MouseGetPos(&mouse_x, &mouse_y)
        if mouse_x > A_ScreenWidth or mouse_x < 0 ; because of multiple monitors
            return

        Horizontal_Line.Move(, mouse_y)
        Vertical_Line.Move(mouse_x)
    }

#HotIf



; -------------------------------------------------------------------------------
; CREATE ALIGNMENT GRID
; -------------------------------------------------------------------------------
CreateAlignmentGrid()
{
    ; +E0x20 and WinSetTransColor necessary to allow you to click through the grid lines, just don't use the color 'fffffe'  :)
    global Horizontal_Line := Gui('+AlwaysOnTop -SysMenu +ToolWindow -Caption -Border +E0x20')
    WinSetTransColor('fffffe', Horizontal_Line)

    Horizontal_Line.BackColor := gridColor
    Horizontal_Line.Show('xCenter yCenter w' A_ScreenWidth ' h1 NoActivate')



    global Vertical_Line := Gui('+AlwaysOnTop -SysMenu +ToolWindow -Caption -Border +E0x20')
    WinSetTransColor('fffffe', Vertical_Line)

    Vertical_Line.BackColor := gridColor
    Vertical_Line.Show('xCenter yCenter w1 h' A_ScreenHeight ' NoActivate')
}



; -------------------------------------------------------------------------------
; FUNCTIONS
; -------------------------------------------------------------------------------
MoveUpOrDown(move)
{
    Horizontal_Line.GetPos(, &y)

    if y + 1 <= A_ScreenHeight and y - 1 >= 0
        Horizontal_Line.Move(, y+move)
}



MoveLeftOrRight(move)
{
    Vertical_Line.GetPos(&x)

    if x + 1 <= A_ScreenWidth and x - 1 >= 0
        Vertical_Line.Move(x+move)
}



Destroy_Align_Tool(*)
{
    if IsSet(Horizontal_Line) {
        Horizontal_Line.Destroy()
        global Horizontal_Line := unset
    }

    if IsSet(Vertical_Line) {
        Vertical_Line.Destroy()
        global Vertical_Line := unset
    }
}