#SingleInstance

TraySetIcon('Shell32.dll', 19)
CoordMode('Mouse', 'Screen')



; max dimensions of the grid thickness when changing their size with + and - hotkeys (aka = and -)
maxThickness := 40

; starting thickness
size := 1

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

    ; move grid x pixels in given direction
    Up::MoveUpOrDown(-1)
    Down::MoveUpOrDown(1)
    Left::MoveLeftOrRight(-1)
    Right::MoveLeftOrRight(1)
    ^Up::MoveUpOrDown(-5)
    ^Down::MoveUpOrDown(5)
    ^Left::MoveLeftOrRight(-5)
    ^Right::MoveLeftOrRight(5)

    =::IncreaseThickness(1) ; increase grid thickness
    ^=::IncreaseThickness(5) ; increase grid thickness by five

    -::DecreaseThickness(1) ; decrease grid thickness
    ^-::DecreaseThickness(5) ; decrease grid thickness by five

    Control & WheelUp::IncreaseThickness(1)
    Control & WheelDown::DecreaseThickness(1)
    
    

    ; thickness functions
    IncreaseThickness(increment)
    {
        ; increase thickness if less than max
        ; then move lines to fit inside monitor if increased thickness bleed outside the monitor
        Horizontal_Line.GetPos(, &y,, &size)
        Horizontal_Line.Move(,,, (size + increment <= maxThickness) ? (size + increment) : maxThickness)
        Horizontal_Line.GetPos(, &y,, &size)
        Horizontal_Line.Move(, (y + size > A_ScreenHeight) ? (A_ScreenHeight - size) : y)

        Vertical_Line.GetPos(&x,, &size)
        Vertical_Line.Move(,, (size + increment <= maxThickness) ? (size + increment) : maxThickness)
        Vertical_Line.GetPos(&x,, &size)
        Vertical_Line.Move((x + size > A_ScreenWidth) ? (A_ScreenWidth - size) : x)

        ShowToolTip()
    }



    DecreaseThickness(decrement)
    {
        Horizontal_Line.GetPos(, &y,, &size)
        Horizontal_Line.Move(,,, (size - decrement > 0) ? (size - decrement) : 1)

        Vertical_Line.GetPos(&x,, &size)
        Vertical_Line.Move(,, (size - decrement > 0) ? (size - decrement) : 1)


        ShowToolTip()
    }



    ~LButton::  ; re-position the grid
    {
        MouseGetPos(&mouse_x, &mouse_y)
        if mouse_x > A_ScreenWidth or mouse_x < 0 ; because of multiple monitors
            return

        Horizontal_Line.Move(, mouse_y)
        Vertical_Line.Move(mouse_x)

        SetTimer(() => Horizontal_Line.Opt('AlwaysOnTop'), -10)
        SetTimer(() => Vertical_Line.Opt('AlwaysOnTop'), -10)

        ShowToolTip()
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
    Horizontal_Line.Show('x0 w' A_ScreenWidth ' h1 NoActivate')



    global Vertical_Line := Gui('+AlwaysOnTop -SysMenu +ToolWindow -Caption -Border +E0x20')
    Vertical_Line.MarginY := 0
    WinSetTransColor('fffffe', Vertical_Line)

    Vertical_Line.BackColor := gridColor
    Vertical_Line.Show('y0 w1 h' A_ScreenHeight ' NoActivate')



    Horizontal_Line.GetPos(, &y)
    Vertical_Line.GetPos(&x)
    global tooltip_id := ToolTip('Thickness: ' size, (x+size+8), (y+size+8))
}



; -------------------------------------------------------------------------------
; FUNCTIONS
; -------------------------------------------------------------------------------
MoveUpOrDown(move)
{
    Horizontal_Line.GetPos(, &y,, &size)


    ; y position has enough room to move the requested amount
    if (y + move <= A_ScreenHeight - size) and (y + move >= 0)
        Horizontal_Line.Move(, y + move)

    ; y position is near screenheight
    else if y + move > A_ScreenHeight - size
        Horizontal_Line.Move(, A_ScreenHeight - size)

    ; y position is near 0
    else
        Horizontal_Line.Move(, 0)


    Horizontal_Line.Opt('AlwaysOnTop')
    Vertical_Line.Opt('AlwaysOnTop')
    ShowToolTip()
}



MoveLeftOrRight(move)
{
    Vertical_Line.GetPos(&x,, &size)


    if (x + move <= A_ScreenWidth - size) and (x + move >= 0)
        Vertical_Line.Move(x + move)

    else if x + move > A_ScreenWidth - size
        Vertical_Line.Move(A_ScreenWidth - size)

    else
        Vertical_Line.Move(0)


    Horizontal_Line.Opt('AlwaysOnTop')
    Vertical_Line.Opt('AlwaysOnTop')
    ShowToolTip()
}



ShowToolTip()
{
    static x_pos := unset
    static y_pos := unset

    Horizontal_Line.GetPos(, &y,, &size)
    Vertical_Line.GetPos(&x)

    WinGetPos(,, &tooltipWidth, &tooltipHeight, tooltip_id)


    ; if tooltip WOULD go off screen ; x_pos
    if (x+size+8+tooltipWidth) > A_ScreenWidth
        x_pos := x-8-tooltipWidth
    else
        x_pos := x+size+8


    ; if tooltip WOULD go off screen ; y_pos
    if (y+size+tooltipHeight) > A_ScreenHeight
        y_pos := y-8-tooltipHeight
    else
        y_pos := y+size+8


    global tooltip_id := ToolTip('Thickness: ' size, x_pos, y_pos)
}



Destroy_Align_Tool()
{
    if IsSet(Horizontal_Line) {
        Horizontal_Line.Destroy()
        global Horizontal_Line := unset
    }

    if IsSet(Vertical_Line) {
        Vertical_Line.Destroy()
        global Vertical_Line := unset
    }

    global size := 1

    ToolTip()
}
