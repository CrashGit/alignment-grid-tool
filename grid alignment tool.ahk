#SingleInstance

TraySetIcon('Shell32.dll', 19)
CoordMode('Mouse', 'Screen')


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
                Grid.Destroy_Align_Tool()

            else Grid.CreateAlignmentGrid()
        }
        presses := 0    ; reset keypress to prepare for the next series of presses
    }
}

^F4::Grid.FollowMouse()



#HotIf IsSet(Horizontal_Line) or IsSet(Vertical_Line)

    ; move grid x pixels in given direction
    Up::Grid.MoveUpOrDown(-1)
    Down::Grid.MoveUpOrDown(1)
    Left::Grid.MoveLeftOrRight(-1)
    Right::Grid.MoveLeftOrRight(1)

    ^Up::Grid.MoveUpOrDown(-5)
    ^Down::Grid.MoveUpOrDown(5)
    ^Left::Grid.MoveLeftOrRight(-5)
    ^Right::Grid.MoveLeftOrRight(5)

    =::Grid.IncreaseThickness(1)     ; increase grid thickness
    ^=::Grid.IncreaseThickness(5)    ; increase grid thickness by five

    -::Grid.DecreaseThickness(1)     ; decrease grid thickness
    ^-::Grid.DecreaseThickness(5)    ; decrease grid thickness by five

    Control & WheelUp::Grid.IncreaseThickness(1)
    Control & WheelDown::Grid.DecreaseThickness(1)


    ~LButton::Grid.UpdatePosition()  ; re-position the grid

#HotIf




class Grid {

    ; max dimensions of the grid thickness when changing their size with + and - keys (aka = and -)
    static maxThickness := 40

    ; starting thickness
    static size := 1

    ; color of the grid lines
    static gridColor := '00ff00'

    ; used for tooltip position
    static x_pos := unset
    static y_pos := unset

    ; create margin for spacing between tooltip and grid
    static margin := 8

    ; initialize tooltip id
    static tooltip_id := unset

    ; following mouse toggle and method
    static followingTheMouse := false
    static FollowTheMouse := ObjBindMethod(this, 'UpdatePosition')



    ; -------------------------------------------------------------------------------
    ; CREATE ALIGNMENT GRID
    ; -------------------------------------------------------------------------------
    static CreateAlignmentGrid()
    {
        ; +E0x20 and WinSetTransColor necessary to allow you to click through the grid lines, just don't use the color 'fffffe'  :)
        global Horizontal_Line := Gui('+AlwaysOnTop -SysMenu +ToolWindow -Caption -Border +E0x20')
        WinSetTransColor('fffffe', Horizontal_Line)

        Horizontal_Line.BackColor := this.gridColor
        Horizontal_Line.Show('x0 w' A_ScreenWidth ' h1 NoActivate')


        global Vertical_Line := Gui('+AlwaysOnTop -SysMenu +ToolWindow -Caption -Border +E0x20')
        Vertical_Line.MarginY := 0
        WinSetTransColor('fffffe', Vertical_Line)

        Vertical_Line.BackColor := this.gridColor
        Vertical_Line.Show('y0 w1 h' A_ScreenHeight ' NoActivate')



        this.tooltip_id := ToolTip('Thickness: ' this.size 'px')
        this.ShowToolTip()
    }



    ; -------------------------------------------------------------------------------
    ; THICKNESS METHODS
    ; -------------------------------------------------------------------------------
    static IncreaseThickness(increment)
    {
        ; increase thickness if less than max
        ; then move lines to fit inside monitor if increased thickness bleed outside the monitor
        Horizontal_Line.GetPos(, &y,, &lineSize)
        Horizontal_Line.Move(,,, (lineSize + increment <= this.maxThickness) ? (lineSize + increment) : this.maxThickness)
        Horizontal_Line.GetPos(, &y,, &lineSize)
        Horizontal_Line.Move(, (y + lineSize > A_ScreenHeight) ? (A_ScreenHeight - lineSize) : y)

        Vertical_Line.GetPos(&x,, &lineSize)
        Vertical_Line.Move(,, (lineSize + increment <= this.maxThickness) ? (lineSize + increment) : this.maxThickness)
        Vertical_Line.GetPos(&x,, &lineSize)
        Vertical_Line.Move((x + lineSize > A_ScreenWidth) ? (A_ScreenWidth - lineSize) : x)

        this.ShowToolTip()
    }



    static DecreaseThickness(decrement)
    {
        Horizontal_Line.GetPos(, &y,, &lineSize)
        Horizontal_Line.Move(,,, (lineSize - decrement > 0) ? (lineSize - decrement) : 1)

        Vertical_Line.GetPos(&x,, &lineSize)
        Vertical_Line.Move(,, (lineSize - decrement > 0) ? (lineSize - decrement) : 1)


        this.ShowToolTip()
    }



    ; -------------------------------------------------------------------------------
    ; METHODS
    ; -------------------------------------------------------------------------------
    static UpdatePosition() {
        MouseGetPos(&mouse_x, &mouse_y)

        if mouse_x > A_ScreenWidth or mouse_x < 0 ; because of multiple monitors
            return

        try {
            Horizontal_Line.Move(, mouse_y)
            Vertical_Line.Move(mouse_x)

            Horizontal_Line.Opt('AlwaysOnTop')
            Vertical_Line.Opt('AlwaysOnTop')

            this.ShowToolTip()
        }
    }



    static FollowMouse() {
        this.followingTheMouse := !this.followingTheMouse

        if IsSet(Horizontal_Line) or IsSet(Vertical_Line)
            if this.followingTheMouse
                SetTimer(this.FollowTheMouse, 10)
            else SetTimer(this.FollowTheMouse, 0)

        else {
            if this.followingTheMouse {
                this.CreateAlignmentGrid()
                SetTimer(this.FollowTheMouse, 10)
            }
        }
    }



    static MoveUpOrDown(move)
    {
        Horizontal_Line.GetPos(, &y,, &lineSize)


        ; y position has enough room to move the requested amount
        if (y + move <= A_ScreenHeight - lineSize) and (y + move >= 0)
            Horizontal_Line.Move(, y + move)

        ; y position is near screenheight
        else if y + move > A_ScreenHeight - lineSize
            Horizontal_Line.Move(, A_ScreenHeight - lineSize)

        ; y position is near 0
        else Horizontal_Line.Move(, 0)


        Horizontal_Line.Opt('AlwaysOnTop')
        Vertical_Line.Opt('AlwaysOnTop')
        this.ShowToolTip()
    }



    static MoveLeftOrRight(move)
    {
        Vertical_Line.GetPos(&x,, &lineSize)


        if (x + move <= A_ScreenWidth - lineSize) and (x + move >= 0)
            Vertical_Line.Move(x + move)

        else if x + move > A_ScreenWidth - lineSize
            Vertical_Line.Move(A_ScreenWidth - lineSize)

        else Vertical_Line.Move(0)


        Horizontal_Line.Opt('AlwaysOnTop')
        Vertical_Line.Opt('AlwaysOnTop')
        this.ShowToolTip()
    }



    static ShowToolTip()
    {
        Horizontal_Line.GetPos(, &line_yPos,, &lineSize)
        Vertical_Line.GetPos(&line_xPos)

        WinGetPos(,, &tooltipWidth, &tooltipHeight, this.tooltip_id)


        if UpperLeftQuadrant()
            this.x_pos := line_xPos+lineSize+this.margin,       this.y_pos := line_yPos+lineSize+this.margin

        else if LowerLeftQuadrant()
            this.x_pos := line_xPos+lineSize+this.margin,       this.y_pos := line_yPos-this.margin-tooltipHeight

        else if UpperRightQuadrant()
            this.x_pos := line_xPos-this.margin-tooltipWidth,   this.y_pos := line_yPos+lineSize+this.margin

        else if LowerRightQuadrant()
            this.x_pos := line_xPos-this.margin-tooltipWidth,   this.y_pos := line_yPos-this.margin-tooltipHeight


        ToolTip('Thickness: ' lineSize 'px', this.x_pos, this.y_pos)

        UpperLeftQuadrant()  => line_xPos <  (A_ScreenWidth/2) and line_yPos <  (A_ScreenHeight/2)
        LowerLeftQuadrant()  => line_xPos <  (A_ScreenWidth/2) and line_yPos >= (A_ScreenHeight/2)
        UpperRightQuadrant() => line_xPos >= (A_ScreenWidth/2) and line_yPos <  (A_ScreenHeight/2)
        LowerRightQuadrant() => line_xPos >= (A_ScreenWidth/2) and line_yPos >= (A_ScreenHeight/2)
    }



    static Destroy_Align_Tool()
    {
        this.size := 1
        this.followingTheMouse := false

        ToolTip()
        SetTimer(this.followTheMouse, 0)

        if IsSet(Horizontal_Line) {
            Horizontal_Line.Destroy()
            global Horizontal_Line := unset
        }

        if IsSet(Vertical_Line) {
            Vertical_Line.Destroy()
            global Vertical_Line := unset
        }
    }
}
