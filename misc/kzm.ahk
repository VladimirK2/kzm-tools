#Requires AutoHotkey v2.0
#SingleInstance

; CoordMode("Mouse","Screen")

; https://www.autohotkey.com/docs/v2/KeyList.htm

OnClipboardChange MyClipb

NumpadAdd::Send "{NumpadAdd}"

; =================== TAFJ terminal

#HotIf WinActive("TAFJ#")

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

#HotIf WinActive("Miami/GVA R11")
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
;    Send " to "
    return
    }

;;; Numpad0::RWin

; Copy/Paste
NumpadDiv::
    {
    Send "^{Ins}"
    return
    }

;;; NumpadEnter::Send "+{Ins}"
NumpadDot::Send "+{Ins}"

; Show clipboard
^NumpadSub::Run "pythonw D:\Users\NNNNNNN\dev\kzm\py\clipb.pyw"

; manage clipboard history
^NumpadAdd::Run "pythonw D:\Users\NNNNNNN\dev\kzm\py\clipb-tool.pyw D:\Users\NNNNNNN\dev\kzm\runtime\clipb.txt"

; Ru keyboard
Numpad0 & NumpadDot::Run "pythonw D:\Users\NNNNNNN\dev\kzm\py\ru-keyb.pyw"

NumpadAdd & 1::
    {
    If WinActive("TAFJ#1") {
;        MsgBox "yes"
        WinMinimize "TAFJ#1"
    }
    else {
        WinActivate "TAFJ#1"
    }
    return
    }

NumpadAdd & 2::
   {
    If WinActive("TAFJ#2") {
        WinMinimize "TAFJ#2"
    }
    else {
        WinActivate "TAFJ#2"
    }
    return
    }

NumpadAdd & 3::
   {
    If WinActive("TAFJ#3") {
        WinMinimize "TAFJ#3"
    }
    else {
        WinActivate "TAFJ#3"
    }
    return
    }

; browser
NumpadAdd & B::Send "#1"

; mail
NumpadAdd & M::Send "#2"

; editor
NumpadAdd & E::Send "#3"

; mobaXterm >>> git bash
NumpadAdd & X::Send "#4"

; far
NumpadAdd & F::Send "#5"

; Teams
NumpadAdd & T::Send "#6"

; DS /Excel / anything to the right of Teams
NumpadAdd & 7::Send "#7"
NumpadAdd & 8::Send "#8"
NumpadAdd & 9::Send "#9"

; shut accidental +...
NumpadAdd & q::MsgBox "Not mapped", "Key", "T1"
NumpadAdd & w::MsgBox "Not mapped", "Key", "T1"
NumpadAdd & r::MsgBox "Not mapped", "Key", "T1"
NumpadAdd & y::MsgBox "Not mapped", "Key", "T1"
NumpadAdd & u::MsgBox "Not mapped", "Key", "T1"
NumpadAdd & i::MsgBox "Not mapped", "Key", "T1"
NumpadAdd & o::MsgBox "Not mapped", "Key", "T1"
NumpadAdd & p::MsgBox "Not mapped", "Key", "T1"
NumpadAdd & a::MsgBox "Not mapped", "Key", "T1"
NumpadAdd & s::MsgBox "Not mapped", "Key", "T1"
NumpadAdd & d::MsgBox "Not mapped", "Key", "T1"
NumpadAdd & g::MsgBox "Not mapped", "Key", "T1"
NumpadAdd & h::MsgBox "Not mapped", "Key", "T1"
NumpadAdd & j::MsgBox "Not mapped", "Key", "T1"
NumpadAdd & k::MsgBox "Not mapped", "Key", "T1"
NumpadAdd & l::MsgBox "Not mapped", "Key", "T1"
NumpadAdd & c::MsgBox "Not mapped", "Key", "T1"
NumpadAdd & v::MsgBox "Not mapped", "Key", "T1"
NumpadAdd & n::MsgBox "Not mapped", "Key", "T1"

; minimize all
NumpadAdd & Space::Send "#m"

NumpadAdd & Z::
    {
    WinWait "UCRT64"
    WinActivate "UCRT64"
    WinMove 440, 200, A_ScreenWidth/1.2, A_ScreenHeight/1.2, "UCRT64"
    return
    }

MyClipb(dataType)
    {
    if dataType = 1
        {

        Text := FileRead("D:\Users\NNNNNNN\dev\kzm\runtime\clipb.txt")
        clipb := a_clipboard
        FoundPos := InStr("`r`n" Text "`r`n", "`r`n" Clipb "`r`n")
        if FoundPos = 0
            {

            FileAppend "`r`n" A_Clipboard "`r`n", "D:\Users\NNNNNNN\dev\kzm\runtime\clipb.txt"
            }
        }
    return
    }
