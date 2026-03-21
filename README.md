# AutoHotkey-WindowSubclassController
An AutoHotkey (AHK) library with tools for subclassing windows and intercepting window messages.

The `WindowSubclassController` class object can be used to implement event handlers
for any window created by the AHK process. Subclassing a window allows your code to
intercept the messages sent to the window before the window receives them.

For details about the Windows API, see:

- [SetWindowSubclass](https://learn.microsoft.com/en-us/windows/win32/api/commctrl/nf-commctrl-setwindowsubclass) - This is the function that creates the subclass.
- [Subclassing Controls](https://learn.microsoft.com/en-us/windows/win32/controls/subclassing-overview#subclassing-controls-using-comctl32dll-version-6) - An overview of subclassing controls.
- [SUBCLASSPROC](https://learn.microsoft.com/en-us/windows/win32/api/commctrl/nc-commctrl-subclassproc) - The function prototype for the function that receives the window messages.

The static property "collection" (`WindowSubclassController.collection`) is a `Map` where
each item key is a window handle (hwnd) and each item value is a `WindowSubclassController`
object.

When your code calls one of the below methods, if an item **does not** exist in the
`WindowSubclassController.collection` map, a new
`WindowSubclassController` object is created.

- `WindowSubclassController.CommandAdd`
- `WindowSubclassController.MessageAdd`
- `WindowSubclassController.NotifyAdd`

If an item **does** exist in the `WindowSubclassController.collection` map, then the function
is added to the `WindowSubclassController` internal collections.

The `WindowSubclassController` instance object has the following properties:

- `commandCollection` - A `Map` object where the item keys are a
  WM_COMMAND code, and the item values are an array of functions that will be called when the
  window is sent that code.
- `messageCollection` - A `Map` object where the item keys are a
  window message constant, and the item values are an array of functions that will be called when
  the window is sent that message.
- `notifyCollection` - A `Map` object where the item keys are a
  WM_NOTIFY code, and the item values are an array of functions that will be called when the
  window is sent that code.

When the first function is added to one of the `WindowSubclassController` object's collections,
the window subclass is installed. By default, the function
`WindowSubclassController_SubclassProc` is used as the SUBCLASSPROC.

When the window associated with a `WindowSubclassController` object receives a message,
if the message matches one of the items in the `WindowSubclassController` object's collections,
the functions are called.

This is `WindowSubclassController_SubclassProc`:

```ahk
/**
 * @desc - {@link https://learn.microsoft.com/en-us/windows/win32/api/commctrl/nc-commctrl-subclassproc}.
 * This is intended to be used with {@link WindowSubclassController}.
 *
 * @param {Integer} hwndSubclass - The handle to the subclassed window (the handle passed to `SetWindowSubclass`).
 *
 * @param {Integer} uMsg - The message being passed.
 *
 * @param {Integer} wParam - Additional message information. The contents of this parameter depend on the value of uMsg.
 *
 * @param {Integer} lParam - Additional message information. The contents of this parameter depend on the value of uMsg.
 *
 * @param {Integer} uIdSubclass - The subclass ID. This is the value pased to the `uIdSubclass` parameter of `SetWindowSubclass`.
 *
 * @param {Integer} dwRefData - The reference data provided to `SetWindowSubclass`.
 */
WindowSubclassController_SubclassProc(hwndSubclass, uMsg, wParam, lParam, uIdSubclass, dwRefData) {
    Critical(-1)
    subclassController := ObjFromPtrAddRef(dwRefData)
    switch uMsg {
    case 0x0111: ; WM_COMMAND
        if callbackCollection := subclassController.commandCollection.Get((wParam >> 16) & 0xFFFF) {
            for cb in callbackCollection {
                if cb(subclassController, hwndSubclass, uMsg, wParam, lParam, uIdSubclass, &value) {
                    return value
                }
            }
        }
    case 0x004E: ; WM_NOTIFY
        if callbackCollection := subclassController.notifyCollection.Get(NumGet(lParam, g_windowSubclass_nmhdr_code_offset, 'int')) {
            for cb in callbackCollection {
                if cb(subclassController, hwndSubclass, uMsg, wParam, lParam, uIdSubclass, &value) {
                    return value
                }
            }
        }
    default:
        if callbackCollection := subclassController.messageCollection.Get(uMsg) {
            for cb in callbackCollection {
                if cb(subclassController, hwndSubclass, uMsg, wParam, lParam, uIdSubclass, &value) {
                    return value
                }
            }
        }
    }
    return DllCall(
        g_comctl32_DefSubclassProc
      , 'ptr', hwndSubclass
      , 'uint', uMsg
      , 'uptr', wParam
      , 'ptr', lParam
      , 'ptr'
    )
}
```

# Usage example

This is an example using `WindowSubclassController` to create a combo box control with
[CBS_OWNERDRAWFIXED](https://learn.microsoft.com/en-us/windows/win32/controls/combo-box-styles) style.
The combo box displays every font on the user's system. We intercept the
[WM_MEASUREITEM](https://learn.microsoft.com/en-us/windows/win32/controls/wm-measureitem) and
[WM_DRAWITEM](https://learn.microsoft.com/en-us/windows/win32/controls/wm-drawitem) messages to
allow us to update the font of each item in the combo box, so each item
is drawn using the actual font that the item is associated with.

To run the example, you will need to have three dependencies in your
[lib folder](https://www.autohotkey.com/docs/v2/Scripts.htm#lib), or just replace the `#include`
statements with the actual code copied from the file.

- [Logfont](https://github.com/Nich-Cebolla/AutoHotkey-Logfont/blob/main/src/Logfont.ahk)
- [Rect](https://github.com/Nich-Cebolla/AutoHotkey-Rect/blob/main/src/Rect.ahk)
- [WindowSubclassController](https://github.com/Nich-Cebolla/AutoHotkey-WindowSubclassController/blob/main/src/WindowSubclassController.ahk) (this repo)

In the example, we add an event handler for WM_DRAWITEM and another for WM_MEASUREITEM. By intercepting
these messages, we are able to respond to them before the default window procedure.

```ahk
#Requires AutoHotkey >=2.0-a
#SingleInstance force
#include <Logfont>
#include <WindowSubclassController>
#include <Rect>

g := gui()
g.SetFont('s11 q5')

itemHeight := 24 ; the height of each combo box item

; `items` will be an array of strings, each string the name of a font
items := StrSplit(GetSystemFonts(), '`n', '`s')

; This `Logfont` object will be used by `MeasureItem`
lf := Logfont()

; Add an event handler for the message WM_DRAWITEM
WindowSubclassController.MessageAdd(g.hwnd,0x002B, DrawItem) ; WM_DRAWITEM

; Add an event handler for the message WM_MEASUREITEM
WindowSubclassController.MessageAdd(g.hwnd,0x002C, MeasureItem) ; WM_MEASUREITEM

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

```
