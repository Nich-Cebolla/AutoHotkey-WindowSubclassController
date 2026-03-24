
#Requires AutoHotkey >=2.0-a
#SingleInstance force
; https://github.com/Nich-Cebolla/AutoHotkey-Logfont/blob/main/src/Logfont.ahk
#include <Logfont>
; https://github.com/Nich-Cebolla/AutoHotkey-Rect/blob/main/src/Rect.ahk
#include <Rect>
#include ..\src\WindowSubclassController.ahk

; Create a `WindowSubclassManager` object
subclassManager := WindowSubclassManager()

g := gui()
g.SetFont('s11 q5')

itemHeight := 24 ; the height of each combo box item

; `items` will be an array of strings, each string the name of a font
items := StrSplit(GetSystemFonts(), '`n', '`s')

; This `Logfont` object will be used by `MeasureItem`
lf := Logfont()

; Add an event handler for the message WM_DRAWITEM
subclassManager.MessageAdd(g.hwnd,0x002B, DrawItem) ; WM_DRAWITEM

; Add an event handler for the message WM_MEASUREITEM
subclassManager.MessageAdd(g.hwnd,0x002C, MeasureItem) ; WM_MEASUREITEM

; Create the combo box
CBS_OWNERDRAWFIXED := '0x0010'
CBS_HASSTRINGS := '0x0200'
cb := g.Add('ComboBox', 'x10 y10 w500 r10 +' CBS_OWNERDRAWFIXED ' +' CBS_HASSTRINGS, items)
lf.hwnd := cb.hwnd
; Let's make the text height a bit smaller than the item height, so the items don't appear crowded
lf.height := -18
lf.Apply()

g.show()

MeasureItem(subclassController, HwndSubclass, uMsg, wParam, lParam, *) {
    mis := MEASUREITEMSTRUCT(lParam)
    if wParam || mis.CtlType != 1 { ; ODT_MENU
        mis.itemHeight := itemHeight
    }
}
DrawItem(subclassController, HwndSubclass, uMsg, wParam, lParam, *) {
    dis := DRAWITEMSTRUCT(lParam)
    index := dis.itemID
    if index = -1 {
        return 1
    }
    hdc := dis.hdc
    savedDC := DllCall('SaveDC', 'ptr', hdc, 'ptr')
    disabled := dis.itemState & 0x0004 ; ODS_DISABLED
    focused := dis.itemState & 0x0010 ; ODS_FOCUS
    rc := Rect.FromPtr(dis.ptr + dis.offset_l)
    if dis.itemState & 0x0001 { ; ODS_SELECTED
        oldText := DllCall('SetTextColor', 'ptr', hdc, 'uint', DllCall('GetSysColor', 'uint', 14, 'uint'), 'uint')
        oldBk := DllCall('SetBkColor', 'ptr', hdc, 'uint', DllCall('GetSysColor', 'uint', 13, 'uint'), 'uint')
        if !DllCall('FillRect', 'ptr', hdc, 'ptr', rc, 'int64', DllCall('GetSysColorBrush', 'uint', 13, 'int64'), 'int') {
            throw OSError()
        }
    } else {
        oldText := DllCall('SetTextColor', 'ptr', hdc, 'uint', DllCall('GetSysColor', 'uint', disabled ? 17 : 8, 'uint'), 'uint')
        oldBk := DllCall('SetBkColor', 'ptr', hdc, 'uint', DllCall('GetSysColor', 'uint', 5, 'uint'), 'uint')
        if !DllCall('FillRect', 'ptr', hdc, 'ptr', rc, 'int64', DllCall('GetSysColorBrush', 'uint', 5, 'int64'), 'int') {
            throw OSError()
        }
    }
    if oldText = -1 {
        throw OSError()
    }
    if oldBk = -1 {
        throw OSError()
    }
    len := SendMessage(0x0149, index, 0, dis.hwndItem) ; CB_GETLBTEXTLEN
    buf := Buffer(len * 2 + 2)
    SendMessage(0x0148, index, buf.ptr, dis.hwndItem) ; CB_GETLBTEXT
    font := StrGet(buf, 'cp1200')
    lf.FaceName := font
    hfont := DllCall('CreateFontIndirectW', 'ptr', lf, 'ptr')
    hfontOld := DllCall('SelectObject', 'ptr', hdc, 'ptr', hfont, 'ptr')
    result := DllCall('DrawTextW', 'ptr', hdc, 'ptr', buf, 'uint', len, 'ptr', rc, 'uint', 0x00000020 | 0x00000004 |0x00000800, 'uint')
    if !result {
        throw OSError()
    }
    if focused {
        if !DllCall('DrawFocusRect', 'ptr', hdc, 'ptr', rc, 'int') {
            throw OSError()
        }
    }
    if DllCall('SelectObject', 'ptr', hdc, 'ptr', hfontOld, 'ptr') = -1 {
        throw OSError()
    }
    if !DllCall('RestoreDC', 'ptr', hdc, 'ptr', savedDC, 'int') {
        throw OSError()
    }
    if !DllCall('DeleteObject', 'ptr', hfont, 'int') {
        throw OSError()
    }
}

/**
 * @desc - Enumerates the fonts on the system with
 * {@link https://learn.microsoft.com/en-us/windows/win32/api/wingdi/nf-wingdi-enumfontfamiliesexw EnuFontFamiliesExW},
 * adding each font name to a string, separated by a linefeed ( `n ) character. Calls
 * {@link https://www.autohotkey.com/docs/v2/lib/Sort.htm Sort} and returns the string.
 *
 * This skips fonts that begin with "@".
 *
 * @param {Integer} [CharSet = 0] - One of the following:
 *
 *    |  Name                 |  Value  |
 *    |  ---------------------|-------  |
 *    |  ANSI_CHARSET         |  0      |
 *    |  DEFAULT_CHARSET      |  1      |
 *    |  SYMBOL_CHARSET       |  2      |
 *    |  SHIFTJIS_CHARSET     |  128    |
 *    |  HANGEUL_CHARSET      |  129    |
 *    |  HANGUL_CHARSET       |  129    |
 *    |  GB2312_CHARSET       |  134    |
 *    |  CHINESEBIG5_CHARSET  |  136    |
 *    |  OEM_CHARSET          |  255    |
 *    |  JOHAB_CHARSET        |  130    |
 *    |  HEBREW_CHARSET       |  177    |
 *    |  ARABIC_CHARSET       |  178    |
 *    |  GREEK_CHARSET        |  161    |
 *    |  TURKISH_CHARSET      |  162    |
 *    |  VIETNAMESE_CHARSET   |  163    |
 *    |  THAI_CHARSET         |  222    |
 *    |  EASTEUROPE_CHARSET   |  238    |
 *    |  RUSSIAN_CHARSET      |  204    |
 *    |  MAC_CHARSET          |  77     |
 *    |  BALTIC_CHARSET       |  186    |
 *
 * @returns {String}
 */
GetSystemFonts(charSet := 0) {
    originalCritical := Critical('On')
    lf := Buffer(92, 0)
    cb := CallbackCreate(Callback, 'F')
    NumPut('uchar', charSet, lf, 23)
    s := ''
    VarSetStrCapacity(&s, 1024 * 128)
    hdc := DllCall(g_user32_GetDC, 'ptr', 0, 'ptr')
    DllCall('EnumFontFamiliesExW', 'ptr', hdc, 'ptr', lf, 'ptr', cb, 'ptr', 0, 'uint', 0, 'uint')
    DllCall('ReleaseDC', 'ptr', 0, 'ptr', hdc)
    CallbackFree(cb)
    Critical(originalCritical)

    return Sort(SubStr(s, 1, -1), 'U')

    Callback(lpelfe, *) {
        if NumGet(lpelfe + 92, 'char') != 64 { ; if the first character is not "@"
            s .= StrGet(lpelfe + 92, 'cp1200') '`n'
        }
        return 1
    }
}

class DRAWITEMSTRUCT {
    static __New() {
        this.DeleteProp('__New')
        proto := this.Prototype
        proto.size :=
        ; Size      Type           Symbol        Offset                Padding
        4 +         ; UINT         CtlType       0
        4 +         ; UINT         CtlID         4
        4 +         ; UINT         itemID        8
        4 +         ; UINT         itemAction    12
        A_PtrSize + ; UINT         itemState     16                    +4 on x64 only
        A_PtrSize + ; HWND         hwndItem      16 + A_PtrSize * 1
        A_PtrSize + ; HDC          hDC           16 + A_PtrSize * 2
        4 +         ; int          l             16 + A_PtrSize * 3
        4 +         ; int          t             20 + A_PtrSize * 3
        4 +         ; int          r             24 + A_PtrSize * 3
        4 +         ; int          b             28 + A_PtrSize * 3
        A_PtrSize   ; ULONG_PTR    itemData      32 + A_PtrSize * 3
        proto.offset_CtlType     := 0
        proto.offset_CtlID       := 4
        proto.offset_itemID      := 8
        proto.offset_itemAction  := 12
        proto.offset_itemState   := 16
        proto.offset_hwndItem    := 16 + A_PtrSize * 1
        proto.offset_hDC         := 16 + A_PtrSize * 2
        proto.offset_l           := 16 + A_PtrSize * 3
        proto.offset_t           := 20 + A_PtrSize * 3
        proto.offset_r           := 24 + A_PtrSize * 3
        proto.offset_b           := 28 + A_PtrSize * 3
        proto.offset_itemData    := 32 + A_PtrSize * 3
    }
    __New(ptr) {
        this.ptr := ptr
    }
    CtlType {
        Get => NumGet(this.ptr, this.offset_CtlType, 'uint')
        Set {
            NumPut('uint', Value, this.ptr, this.offset_CtlType)
        }
    }
    CtlID {
        Get => NumGet(this.ptr, this.offset_CtlID, 'uint')
        Set {
            NumPut('uint', Value, this.ptr, this.offset_CtlID)
        }
    }
    itemID {
        Get => NumGet(this.ptr, this.offset_itemID, 'uint')
        Set {
            NumPut('uint', Value, this.ptr, this.offset_itemID)
        }
    }
    itemAction {
        Get => NumGet(this.ptr, this.offset_itemAction, 'uint')
        Set {
            NumPut('uint', Value, this.ptr, this.offset_itemAction)
        }
    }
    itemState {
        Get => NumGet(this.ptr, this.offset_itemState, 'uint')
        Set {
            NumPut('uint', Value, this.ptr, this.offset_itemState)
        }
    }
    hwndItem {
        Get => NumGet(this.ptr, this.offset_hwndItem, 'ptr')
        Set {
            NumPut('ptr', Value, this.ptr, this.offset_hwndItem)
        }
    }
    hDC {
        Get => NumGet(this.ptr, this.offset_hDC, 'ptr')
        Set {
            NumPut('ptr', Value, this.ptr, this.offset_hDC)
        }
    }
    l {
        Get => NumGet(this.ptr, this.offset_l, 'int')
        Set {
            NumPut('int', Value, this.ptr, this.offset_l)
        }
    }
    t {
        Get => NumGet(this.ptr, this.offset_t, 'int')
        Set {
            NumPut('int', Value, this.ptr, this.offset_t)
        }
    }
    r {
        Get => NumGet(this.ptr, this.offset_r, 'int')
        Set {
            NumPut('int', Value, this.ptr, this.offset_r)
        }
    }
    b {
        Get => NumGet(this.ptr, this.offset_b, 'int')
        Set {
            NumPut('int', Value, this.ptr, this.offset_b)
        }
    }
    itemData {
        Get => NumGet(this.ptr, this.offset_itemData, 'ptr')
        Set {
            NumPut('ptr', Value, this.ptr, this.offset_itemData)
        }
    }
}

class MEASUREITEMSTRUCT {
    static __New() {
        this.DeleteProp('__New')
        proto := this.Prototype
        proto.size :=
        ; Size      Type           Symbol        Offset                Padding
        4 +         ; UINT         CtlType       0
        4 +         ; UINT         CtlID         4
        4 +         ; UINT         itemID        8
        4 +         ; UINT         itemWidth     12
        A_PtrSize + ; UINT         itemHeight    16                    +4 on x64 only
        A_PtrSize   ; ULONG_PTR    itemData      16 + A_PtrSize * 1
        proto.offset_CtlType     := 0
        proto.offset_CtlID       := 4
        proto.offset_itemID      := 8
        proto.offset_itemWidth   := 12
        proto.offset_itemHeight  := 16
        proto.offset_itemData    := 16 + A_PtrSize * 1
    }
    __New(ptr) {
        this.ptr := ptr
    }
    CtlType {
        Get => NumGet(this.ptr, this.offset_CtlType, 'uint')
        Set {
            NumPut('uint', Value, this.ptr, this.offset_CtlType)
        }
    }
    CtlID {
        Get => NumGet(this.ptr, this.offset_CtlID, 'uint')
        Set {
            NumPut('uint', Value, this.ptr, this.offset_CtlID)
        }
    }
    itemID {
        Get => NumGet(this.ptr, this.offset_itemID, 'uint')
        Set {
            NumPut('uint', Value, this.ptr, this.offset_itemID)
        }
    }
    itemWidth {
        Get => NumGet(this.ptr, this.offset_itemWidth, 'uint')
        Set {
            NumPut('uint', Value, this.ptr, this.offset_itemWidth)
        }
    }
    itemHeight {
        Get => NumGet(this.ptr, this.offset_itemHeight, 'uint')
        Set {
            NumPut('uint', Value, this.ptr, this.offset_itemHeight)
        }
    }
    itemData {
        Get => NumGet(this.ptr, this.offset_itemData, 'ptr')
        Set {
            NumPut('ptr', Value, this.ptr, this.offset_itemData)
        }
    }
}
