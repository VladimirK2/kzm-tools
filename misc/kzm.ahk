#Requires AutoHotkey v2.0
#SingleInstance

; CoordMode("Mouse","Screen")

; https://www.autohotkey.com/docs/v2/KeyList.htm

OnClipboardChange MyClipb

NumpadAdd::Send "{NumpadAdd}"

; =================== TAFJ terminal

#HotIf WinActive("TAFJ1")

; paste
NumpadDot::
    {
    MouseMove 1900, 20
    Sleep 100
    Send "{RButton}"
    return
    }


F1::
    {
    send "^U{Enter}"
    return
    }

F2::
PgUp::
    {
    send "^B{Enter}"
    return
    }

F3::
PgDn::
    {
    send "^F{Enter}"
    return
    }

F4::
;End::
    {
    send "^E{Enter}"
    return
    }

F5::
    {
    send "^V{Enter}"
    return
    }

F6::
    {
    send "^W{Enter}"
    return
    }

^F7::
    {
    send "^T{Enter}"
    return
    }

q::Q
w::W
e::E
r::R
t::T
y::Y
u::U
i::I
o::O
p::P
a::A
s::S
d::D
f::F
g::G
h::H
j::J
k::K
l::L
z::Z
x::X
c::C
v::V
b::B
n::N
m::M
+q::q
+w::w
+e::e
+r::r
+t::t
+y::y
+u::u
+i::i
+o::o
+p::p
+a::a
+s::s
+d::d
+f::f
+g::g
+h::h
+j::j
+k::k
+l::l
+z::z
+x::x
+c::c
+v::v
+b::b
+n::n
+m::m

#HotIf

; ============================== personal

; ----- Mobaxterm

#HotIf WinActive("R11")
q::Q
w::W
e::E
r::R
t::T
y::Y
u::U
i::I
o::O
p::P
a::A
s::S
d::D
f::F
g::G
h::H
j::J
k::K
l::L
z::Z
x::X
c::C
v::V
b::B
n::N
m::M
+q::q
+w::w
+e::e
+r::r
+t::t
+y::y
+u::u
+i::i
+o::o
+p::p
+a::a
+s::s
+d::d
+f::f
+g::g
+h::h
+j::j
+k::k
+l::l
+z::z
+x::x
+c::c
+v::v
+b::b
+n::n
+m::m

Home::Send "^A"
End::Send "^E"

PgUp::send "{F2}"
PgDn::send "{F3}"
^Delete::send "^K"

#HotIf

; ---- keys remapping

>!T::Send " to "

Capslock::
    {
    return
    }

; Copy/Paste
NumpadDiv::
    {
    Send "^{Ins}"
    return
    }

NumpadDot::Send "+{Ins}"

; Show clipboard
^NumpadSub::Run "pythonw D:\Users\xNNNNNN\dev\kzm\py\clipb.pyw"

; manage clipboard history
^NumpadAdd::Run "pythonw D:\Users\xNNNNNN\dev\kzm\py\clipb-tool.pyw D:\Users\xNNNNNN\dev\kzm\runtime\clipb.txt"

; Ru keyboard
Numpad0 & NumpadDot::Run "pythonw D:\Users\xNNNNNN\dev\kzm\py\ru-keyb.pyw"

NumpadAdd & 1::
    {
    If WinActive("TAFJ1") {
;        MsgBox "yes"
        WinMinimize "TAFJ1"
    }
    else {
        WinActivate "TAFJ1"
    }
    return
    }

NumpadAdd & 2::
   {
    If WinActive("TAFJ2") {
        WinMinimize "TAFJ2"
    }
    else {
        WinActivate "TAFJ2"
    }
    return
    }

NumpadAdd & 3::
   {
    If WinActive("TAFJ3") {
        WinMinimize "TAFJ3"
    }
    else {
        WinActivate "TAFJ3"
    }
    return
    }


; browser
NumpadAdd & B::Send "#1"
; mail
NumpadAdd & M::Send "#2"
; teams
;NumpadAdd & T::Send "#3"
; editor
NumpadAdd & E::Send "#3"
; mobaXterm
NumpadAdd & X::Send "#4"
; far
NumpadAdd & F::Send "#5"
; tafJ
; NumpadAdd & J::Send "#6"
; DS
NumpadAdd & D::Send "#7"
; Excel or someth else
NumpadAdd & T::Send "#8"
; minimize all
NumpadAdd & Space::Send "#m"

NumpadAdd & Z::
    {
    WinWait "MINGW"
    WinActivate "MINGW"
    WinMove 440, 196, A_ScreenWidth/1.2, A_ScreenHeight/1.2, "MINGW"
    return
    }

MyClipb(dataType)
    {
    if dataType = 1
        {

        Text := FileRead("D:\Users\xNNNNNN\dev\kzm\runtime\clipb.txt")
        clipb := a_clipboard
        FoundPos := InStr("`r`n" Text "`r`n", "`r`n" Clipb "`r`n")
        if FoundPos = 0
            {

            FileAppend "`r`n" A_Clipboard "`r`n", "D:\Users\xNNNNNN\dev\kzm\runtime\clipb.txt"
            }
        }
    return
    }
