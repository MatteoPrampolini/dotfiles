#Requires AutoHotkey v2.0
#SingleInstance Force
#UseHook
; Uccidiamo CAPS LOCK.
; Poi diciamo: se siamo dentro emacs CAPS LOCK diventa F13, altrimenti F24.

; Caps never toggles the Windows Caps Lock state (and its LED).
SetCapsLockState "AlwaysOff"
SetStoreCapsLockMode false
SetKeyDelay -1

; Translate Caps chords to LeopardWM's dedicated F24 modifier.
; Actions belong in leopardwm/config.toml, not in this script.
; Send each chord as a complete press/release so F24 cannot remain held
; when the script is reloaded, stopped, or LeopardWM changes keyboard hooks.
layerKeys := StrSplit("Left Right Up Down Home End PgUp PgDn Space Tab Enter Escape Backspace Delete Insert vkBB vkBD NumpadAdd NumpadSub", " ")
for key in StrSplit("abcdefghijklmnopqrstuvwxyz0123456789")
    layerKeys.Push(key)
for key in layerKeys
    Hotkey("CapsLock & " key, SendCapsChord.Bind(key))

capsChordSerial := 0

SendCapsChord(key, *) {
    global capsChordSerial
    serial := ++capsChordSerial
    SendCapsPress(key)

    ; Only navigation/resizing repeats; holding Q/F/etc. must not repeatedly
    ; close windows or toggle modes. Keep this hotkey busy until key release.
    if !RegExMatch(key, "i)^(Left|Right|Up|Down|Home|End|PgUp|PgDn|u|i|vkBB|vkBD|NumpadAdd|NumpadSub)$") {
        KeyWait key
        return
    }

    ; LeopardWM ignores native key auto-repeat. Generate separate presses
    ; after the initial delay, while both physical keys remain held.
    if KeyWait(key, "T0.3")
        return
    while serial = capsChordSerial && GetKeyState("CapsLock", "P") && GetKeyState(key, "P") {
        SendCapsPress(key)
        Sleep 80
    }
}

SendCapsPress(key) {
    ; Main-keyboard and numpad +/- use the same LeopardWM bindings.
    outputKey := key = "NumpadAdd" ? "vkBB" : key = "NumpadSub" ? "vkBD" : key
    ; Custom combinations also fire with Ctrl/Shift held; Blind preserves them.
    ; LeopardWM may have seen the original key-down before AHK intercepted it.
    ; Release it first so the translated press is not discarded as auto-repeat.
    SendEvent "{Blind}{" key " up}{F24 down}{" outputKey "}{F24 up}"
}

; As a custom-combination prefix, Caps fires alone only on release and only
; when it was not used in a chord. F13 lets Doom decide whether Evil is active.
*CapsLock:: {
    if A_PriorKey = "CapsLock" && WinActive("ahk_class Emacs")
        SendEvent "{F13}"
}
