#Requires AutoHotkey v2.0
#SingleInstance

; =================== TAFJ terminal

#HotIf WinActive("C:\Windows\system32\cmd.exe")

; copy
NumpadDiv::Send "{Enter}"

; paste
NumpadAdd::Send "{RButton}"

#HotIf

#HotIf WinActive("C:\Windows\system32\cmd.exe - trun  tex")

; copy
NumpadDiv::Send "{Enter}"

; paste
NumpadAdd::Send "{RButton}"

F1::
    {
    send "^U{Enter}"
    return
    }

F2::
    {
    send "^B{Enter}"
    return
    }

F3::
    {
    send "^F{Enter}"
    return
    }

F4::
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

F7::
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

#HotIf

; ---- keys remapping
Capslock::return

Numpad0::RWin

; Copy/Paste
NumpadDiv::Send "^{Ins}"
NumpadAdd::Send "+{Ins}"

; Show clipboard
NumpadSub::Run "D:Users\x594822\dev\kzm\py\clipb.pyw"

; Ru keyboard
NumpadMult::Run "D:Users\x594822\dev\kzm\py\ru-keyb.pyw"

