
class WindowSubclassManager {
    static __New() {
        this.DeleteProp('__New')
        this.collection := Map()
        this.collection.Default := ''
    }
    /**
     * @desc - The {@link WindowSubclassManager} class object can be used to implement event handlers
     * for any window created by the AHK process. Creating a window subclass allows your code to
     * intercept the messages sent to the window before the window receives them.
     *
     * The property {@link WindowSubclassManager#collection} is a `Map` where
     * each item key is a window handle (hwnd) and each item value is a {@link WindowSubclassController}
     * object.
     *
     * When your code calls one of the below methods, if an item **does not** exist in the
     * {@link WindowSubclassManager#collection} map for the window, a new
     * {@link WindowSubclassController} object is created.
     *
     * - {@link WindowSubclassManager.Prototype.CommandAdd}
     * - {@link WindowSubclassManager.Prototype.MessageAdd}
     * - {@link WindowSubclassManager.Prototype.NotifyAdd}
     *
     * If an item **does** exist in the {@link WindowSubclassManager#collection} map, then the function
     * is added to the {@link WindowSubclassController} internal collections.
     *
     * The {@link WindowSubclassController} instance object has the following properties:
     *
     * - {@link WindowSubclassController#commandCollection} - A `Map` object where the item keys are a
     *   WM_COMMAND code, and the item values are an array of functions that will be called when the
     *   window is sent that code.
     * - {@link WindowSubclassController#messageCollection} - A `Map` object where the item keys are a
     *   window message constant, and the item values are an array of functions that will be called when
     *   the window is sent that message.
     * - {@link WindowSubclassController#notifyCollection} - A `Map` object where the item keys are a
     *   WM_NOTIFY code, and the item values are an array of functions that will be called when the
     *   window is sent that code.
     *
     * When the first function is added to one of the {@link WindowSubclassController} object's collections,
     * the window subclass is installed. By default, the function
     * {@link WindowSubclassController_SubclassProc} is used as the SUBCLASSPROC.
     *
     * When the window associated with a {@link WindowSubclassController} object receives a message,
     * if the message matches one of the items in the {@link WindowSubclassController} object's collections,
     * the functions are called.
     *
     * @param {*} [subclassProc = WindowSubclassController_SubclassProc] - The value that is passed
     * to the `subclassProc` parameter of
     * {@link WindowSubclassController.Prototype.__New} whenever a new
     * {@link WindowSubclassController} object is created by calling one of:
     *
     * - {@link WindowSubclassManager.Prototype.CommandAdd}
     * - {@link WindowSubclassManager.Prototype.MessageAdd}
     * - {@link WindowSubclassManager.Prototype.NotifyAdd}
     *
     * @param {String} [callbackCreateOptions = ""] - The value that is passed to the
     * `callbackCreateOptions` parameter of
     * {@link WindowSubclassController.Prototype.__New} whenever a new
     * {@link WindowSubclassController} object is created by calling one of:
     *
     * - {@link WindowSubclassManager.Prototype.CommandAdd}
     * - {@link WindowSubclassManager.Prototype.MessageAdd}
     * - {@link WindowSubclassManager.Prototype.NotifyAdd}
     */
    __New(subclassProc := WindowSubclassController_SubclassProc, callbackCreateOptions := '') {
        loop 10000 {
            id := Random(1, 4294967295)
            if !WindowSubclassManager.collection.Has(id) {
                this.id := id
                WindowSubclassManager.collection.Set(id, this)
                ObjRelease(ObjPtr(this))
                break
            }
        }
        if !this.HasOwnProp('id') {
            throw Error('Failed to produce a unique id.')
        }
        this.collection := Map()
        this.collection.default := ''
        this.callbackCreateOptions := ''
        this.subclassProc := subclassProc
        this.callbackCreateOptions := callbackCreateOptions
    }
    /**
     * @desc - Adds a function to be called when the specified WM_COMMAND is sent to the window
     * associated with `hwndSubclass`. If a {@link WindowSubclassController} object does not exist
     * yet for `hwndSubclass`, a new object is created. References to the
     * {@link WindowSubclassController} objects are cached in a `Map` object set to property
     * {@link WindowSubclassManager#collection}. When a {@link WindowSubclassController} object is
     * created, the function {@link WindowSubclassController_OnNCDestroy} is added to its
     * "messageCollection" map. {@link WindowSubclassController_OnNCDestroy} deletes the
     * {@link WindowSubclassController} object from {@link WindowSubclassManager#collection} when
     * the control / window is destroyed.
     *
     * @param {Integer} hwndSubclass - The handle to the window that is subclassed.
     *
     * @param {Integer} CommandCode - The WM_COMMAND code.
     *
     * @param {*} Callback - A `Func` or callable object to call.
     *
     * Parameters:
     * 1. **{WindowSubclassController}** - This {@link WindowSubclassController} object
     * 2. **{Integer}** - hwndSubclass
     * 3. **{Integer}** - uMsg
     * 4. **{Integer}** - wParam
     * 5. **{Integer}** - lParam
     * 6. **{Integer}** - uIdSubclass
     * 7. **{VarRef}** - The value to return to the system.
     *
     * Regarding the last parameter: If your function needs to return a value to the system, it must
     * set the last parameter with the value that is to be returned and also the function must return
     * a nonzero value to the caller.
     *
     * If the function returns zero or an empty string, the process continues and the next function
     * is called. If the function returns a nonzero value, the value of the last parameter is returned
     * to the system and no further functions are called.
     *
     * @param {Integer} [InsertAt] - If set, an integer indicating the index at which the function
     * is to be inserted in the list of functions. If unset, the function is appended to the end
     * of the list.
     *
     * @returns {Integer} - The index at which the function was inserted.
     */
    CommandAdd(hwndSubclass, CommandCode, Callback, InsertAt?) {
        if !(subclassController := this.collection.Get(hwndSubclass)) {
            this.collection.Set(hwndSubclass, subclassController := WindowSubclassController(hwndSubclass, , this.callbackCreateOptions, this.subclassProc))
            subclassController.MessageAdd(0x0082, WindowSubclassController_OnNCDestroy) ; WM_NCDESTROY
        }
        return subclassController.CommandAdd(CommandCode, Callback, InsertAt?)
    }
    /**
     * @desc - Deletes one or all functions associated with `CommandCode`. If there is only one
     * remaining item in each of the {@link WindowSubclassController} object's collections, and if
     * that item is the {@link WindowSubclassController_OnNCDestroy} object that was automatically
     * added when the {@link WindowSubclassController} object was created, the window subclass
     * is uninstalled and the {@link WindowSubclassController} object is deleted from
     * {@link WindowSubclassManager#collection}.
     *
     * @param {Integer} hwndSubclass - The handle to the window that is subclassed.
     *
     * @param {Integer} CommandCode - The WM_COMMAND code.
     *
     * @param {*} [Callback] - If set, the function to delete. If unset, all of the functions
     * associated with `CommandCode` are deleted.
     *
     * @returns {Integer} - Returns the sum of the "Count" properties from each of the collections:
     * - {@link WindowSubclassController#commandCollection}
     * - {@link WindowSubclassController#messageCollection}
     * - {@link WindowSubclassController#notifyCollection}
     *
     * @throws {Error} - "The ``WindowSubclassController`` object does not exist in the collection."
     * This occurs if `hwndSubclass` is not represented in
     * {@link WindowSubclassManager#collection}.
     */
    CommandDelete(hwndSubclass, CommandCode, Callback?) {
        if subclassController := this.collection.Get(hwndSubclass) {
            count := subclassController.CommandDelete(CommandCode, Callback?)
            if count = 1
            && subclassController.messageCollection.count
            && (callbackCollection := subclassController.messageCollection.Get(0x0082)) ; WM_NCDESTROY
            && callbackCollection.length = 1
            && callbackCollection[1] = WindowSubclassController_OnNCDestroy {
                subclassController.Uninstall()
                this.collection.Delete(hwndSubclass)
            }
            return count
        } else {
            __WindowSubclassController_ThrowMissingObjectError(hwndSubclass)
        }
    }
    /**
     * @desc - Adds a function to be called when the specified message is sent to the window
     * associated with `hwndSubclass`. If a {@link WindowSubclassController} object does not exist
     * yet for `hwndSubclass`, a new object is created. References to the
     * {@link WindowSubclassController} objects are cached in a `Map` object set to property
     * {@link WindowSubclassController.collection}. When a {@link WindowSubclassController} object is
     * created, the function {@link WindowSubclassController_OnNCDestroy} is added to its
     * "messageCollection" map. {@link WindowSubclassController_OnNCDestroy} deletes the
     * {@link WindowSubclassController} object from {@link WindowSubclassController.collection} when
     * the control / window is destroyed.
     *
     * @param {Integer} hwndSubclass - The handle to the window that is subclassed.
     *
     * @param {Integer} MessageCode - The message code.
     *
     * @param {*} Callback - A `Func` or callable object to call.
     *
     * Parameters:
     * 1. **{WindowSubclassController}** - This {@link WindowSubclassController} object
     * 2. **{Integer}** - hwndSubclass
     * 3. **{Integer}** - uMsg
     * 4. **{Integer}** - wParam
     * 5. **{Integer}** - lParam
     * 6. **{Integer}** - uIdSubclass
     * 7. **{VarRef}** - The value to return to the system.
     *
     * Regarding the last parameter: If your function needs to return a value to the system, it must
     * set the last parameter with the value that is to be returned and also the function must return
     * a nonzero value to the caller.
     *
     * If the function returns zero or an empty string, the process continues and the next function
     * is called. If the function returns a nonzero value, the value of the last parameter is returned
     * to the system and no further functions are called.
     *
     * @param {Integer} [InsertAt] - If set, an integer indicating the index at which the function
     * is to be inserted in the list of functions. If unset, the function is appended to the end
     * of the list.
     *
     * @returns {Integer} - The index at which the function was inserted.
     */
    MessageAdd(hwndSubclass, MessageCode, Callback, InsertAt?) {
        if !(subclassController := this.collection.Get(hwndSubclass)) {
            this.collection.Set(hwndSubclass, subclassController := WindowSubclassController(hwndSubclass, , this.callbackCreateOptions, this.subclassProc))
            subclassController.MessageAdd(0x0082, WindowSubclassController_OnNCDestroy) ; WM_NCDESTROY
        }
        return subclassController.MessageAdd(MessageCode, Callback, InsertAt?)
    }
    /**
     * @desc - Deletes one or all functions associated with `MessageCode`. If there is only one
     * remaining item in each of the {@link WindowSubclassController} object's collections, and if
     * that item is the {@link WindowSubclassController_OnNCDestroy} object that was automatically
     * added when the {@link WindowSubclassController} object was created, the window subclass
     * is uninstalled and the {@link WindowSubclassController} object is deleted from
     *
     * @param {Integer} hwndSubclass - The handle to the window that is subclassed.
     *
     * @param {Integer} MessageCode - The WM_MESSAGE value.
     *
     * @param {*} [Callback] - If set, the function to delete. If unset, all of the functions
     * associated with `MessageCode` are deleted.
     *
     * @returns {Integer} - Returns the sum of the "Count" properties from each of the collections:
     * - {@link WindowSubclassController#commandCollection}
     * - {@link WindowSubclassController#messageCollection}
     * - {@link WindowSubclassController#notifyCollection}
     *
     * @throws {Error} - "The ``WindowSubclassController`` object does not exist in the collection."
     * This occurs if `hwndSubclass` is not represented in
     * {@link WindowSubclassManager#collection}.
     */
    MessageDelete(hwndSubclass, MessageCode, Callback?) {
        if subclassController := this.collection.Get(hwndSubclass) {
            count := subclassController.MessageDelete(MessageCode, Callback?)
            if count = 1
            && subclassController.messageCollection.count
            && (callbackCollection := subclassController.messageCollection.Get(0x0082)) ; WM_NCDESTROY
            && callbackCollection.length = 1
            && callbackCollection[1] = WindowSubclassController_OnNCDestroy {
                subclassController.Uninstall()
                this.collection.Delete(hwndSubclass)
            }
            return count
        } else {
            __WindowSubclassController_ThrowMissingObjectError(hwndSubclass)
        }
    }
    /**
     * @desc - Adds a function to be called when the specified WM_NOTIFY code is sent to the window
     * associated with `hwndSubclass`. If a {@link WindowSubclassController} object does not exist
     * yet for `hwndSubclass`, a new object is created. References to the
     * {@link WindowSubclassController} objects are cached in a `Map` object set to property
     * {@link WindowSubclassController.collection}. When a {@link WindowSubclassController} object is
     * created, the function {@link WindowSubclassController_OnNCDestroy} is added to its
     * "messageCollection" map. {@link WindowSubclassController_OnNCDestroy} deletes the
     * {@link WindowSubclassController} object from {@link WindowSubclassController.collection} when
     * the control / window is destroyed.
     *
     * @param {Integer} hwndSubclass - The handle to the window that is subclassed.
     *
     * @param {Integer} NotifyCode - The WM_NOTIFY code. This should be a signed value, not an
     * unsigned value.
     *
     * @param {*} Callback - A `Func` or callable object to call.
     *
     * Parameters:
     * 1. **{WindowSubclassController}** - This {@link WindowSubclassController} object
     * 2. **{Integer}** - hwndSubclass
     * 3. **{Integer}** - uMsg
     * 4. **{Integer}** - wParam
     * 5. **{Integer}** - lParam
     * 6. **{Integer}** - uIdSubclass
     * 7. **{VarRef}** - The value to return to the system.
     *
     * Regarding the last parameter: If your function needs to return a value to the system, it must
     * set the last parameter with the value that is to be returned and also the function must return
     * a nonzero value to the caller.
     *
     * If the function returns zero or an empty string, the process continues and the next function
     * is called. If the function returns a nonzero value, the value of the last parameter is returned
     * to the system and no further functions are called.
     *
     * @param {Integer} [InsertAt] - If set, an integer indicating the index at which the function
     * is to be inserted in the list of functions. If unset, the function is appended to the end
     * of the list.
     *
     * @returns {Integer} - The index at which the function was inserted.
     */
    NotifyAdd(hwndSubclass, NotifyCode, Callback, InsertAt?) {
        if !(subclassController := this.collection.Get(hwndSubclass)) {
            this.collection.Set(hwndSubclass, subclassController := WindowSubclassController(hwndSubclass, , this.callbackCreateOptions, this.subclassProc))
            subclassController.MessageAdd(0x0082, WindowSubclassController_OnNCDestroy) ; WM_NCDESTROY
        }
        return subclassController.NotifyAdd(NotifyCode, Callback, InsertAt?)
    }
    /**
     * @desc - Deletes one or all functions associated with `NotifyCode`. If there is only one
     * remaining item in each of the {@link WindowSubclassController} object's collections, and if
     * that item is the {@link WindowSubclassController_OnNCDestroy} object that was automatically
     * added when the {@link WindowSubclassController} object was created, the window subclass
     * is uninstalled and the {@link WindowSubclassController} object is deleted from
     * {@link WindowSubclassManager#collection}.
     *
     * @param {Integer} hwndSubclass - The handle to the window that is subclassed.
     *
     * @param {Integer} NotifyCode - The WM_NOTIFY code.
     *
     * @param {*} [Callback] - If set, the function to delete. If unset, all of the functions
     * associated with `NotifyCode` are deleted.
     *
     * @returns {Integer} - Returns the sum of the "Count" properties from each of the collections:
     * - {@link WindowSubclassController#commandCollection}
     * - {@link WindowSubclassController#messageCollection}
     * - {@link WindowSubclassController#notifyCollection}
     *
     * @throws {Error} - "The ``WindowSubclassController`` object does not exist in the collection."
     * This occurs if `hwndSubclass` is not represented in
     * {@link WindowSubclassManager#collection}.
     */
    NotifyDelete(hwndSubclass, NotifyCode, Callback?) {
        if subclassController := this.collection.Get(hwndSubclass) {
            count := subclassController.NotifyDelete(NotifyCode, Callback?)
            if count = 1
            && subclassController.messageCollection.count
            && (callbackCollection := subclassController.messageCollection.Get(0x0082)) ; WM_NCDESTROY
            && callbackCollection.length = 1
            && callbackCollection[1] = WindowSubclassController_OnNCDestroy {
                subclassController.Uninstall()
                this.collection.Delete(hwndSubclass)
            }
            return count
        } else {
            __WindowSubclassController_ThrowMissingObjectError(hwndSubclass)
        }
    }
    /**
     * @desc - Sets the value that is passed to the `callbackCreateOptions` parameter of
     * {@link WindowSubclassController.Prototype.__New} whenever a new
     * {@link WindowSubclassController} object is created by calling one of:
     *
     * - {@link WindowSubclassManager.Prototype.CommandAdd}
     * - {@link WindowSubclassManager.Prototype.MessageAdd}
     * - {@link WindowSubclassManager.Prototype.NotifyAdd}
     *
     * @param {String} value - The value.
     */
    SetCallbackCreateOptions(value) {
        this.callbackCreateOptions := value
    }
    /**
     * @desc - Adds an item to the map set to property {@link WindowSubclassController#data}.
     * Since the {@link WindowSubclassController} object is passed to each function, you can use
     * this to ensure your function has access to any needed data.
     *
     * @param {Integer} hwndSubclass - The handle to the window that is subclassed.
     *
     * @param {*} key - The item's key.
     *
     * @param {*} value - The item's value.
     */
    SetData(hwndSubclass, key, value) {
        if subclassController := this.collection.Get(hwndSubclass) {
            subclassController.data.Set(key, value)
        } else {
            __WindowSubclassController_ThrowMissingObjectError(hwndSubclass)
        }
    }
    /**
     * @desc - Sets the value that is passed to the `subclassProc` parameter of
     * {@link WindowSubclassController.Prototype.__New} whenever a new
     * {@link WindowSubclassController} object is created by calling one of:
     *
     * - {@link WindowSubclassManager.Prototype.CommandAdd}
     * - {@link WindowSubclassManager.Prototype.MessageAdd}
     * - {@link WindowSubclassManager.Prototype.NotifyAdd}
     *
     * @param {*} subclassProc - The function.
     */
    SetSubclassProc(subclassProc) {
        this.subclassProc := subclassProc
    }
}

class WindowSubclassController {
    static __New() {
        this.DeleteProp('__New')
        this.ids := Map()
        this.ids.Default := ''
        proto := this.Prototype
        proto.windowSubclass := proto.flag_callbackFree := proto.pfnSubclass := 0
        global g_windowSubclass_nmhdr_code_offset := A_PtrSize * 2
    }
    /**
     * @desc - A {@link WindowSubclassController} is a tool to organize a window subclass using
     * callback functions, instead of writing the logic directly into the subclass procedure.
     *
     * The {@link WindowSubclassController} object has three properties defined with map objects:
     *
     * - {@link WindowSubclassController#commandCollection commandCollection}
     * - {@link WindowSubclassController#messageCollection messageCollection}
     * - {@link WindowSubclassController#notifyCollection notifyCollection}
     *
     * The keys are message codes and the values are arrays of functions.
     *
     * The function {@link WindowSubclassController_SubclassProc} is intended to be used
     * as the {@link https://learn.microsoft.com/en-us/windows/win32/api/commctrl/nc-commctrl-subclassproc SUBCLASSPROC}
     * when using {@link WindowSubclassController}. {@link WindowSubclassController_SubclassProc}
     * performs the following actions:
     *
     * - A reference to this {@link WindowSubclassController} object is obtained by passing `dwRefData`
     *   to {@link https://www.autohotkey.com/docs/v2/Objects.htm#ObjFromPtr ObjFromPtrAddRef}.
     * - If the message is
     *   {@link https://learn.microsoft.com/en-us/windows/win32/menurc/wm-command WM_COMMAND},
     *   "commandCollection" is checked for the command code. If an item is found, the functions are
     *   iterated and called.
     * - If the message is
     *   {@link https://learn.microsoft.com/en-us/windows/win32/controls/wm-notify WM_NOTIFY},
     *   the NMHDR pointer is passed to {@link WindowSubclass_Nmhdr}, which is a wrapper around the
     *   {@link https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-nmhdr NMHDR}
     *   structure. Then "notifyCollection" is checked for the notification code. If an item is found,
     *   the functions are iterated and called.
     * - If the message is any other message, "messageCollection" is checked for the message code.
     *   If an item is found, the functions are iterated and called.
     *
     * If any of the functions returns a nonzero value, that value gets returned to the system. The
     * effect of this depends on the message. In some cases it means the window never receives the
     * message. You will need to read the documentation for the individual message to learn
     * the significance of returning a value.
     *
     * In the below example, whenever the window is moved, the text control is updated with the
     * new coordinates.
     *
     * @example
     * g := Gui()
     * g.Add("Text", , "The window's current position:")
     * g.Add("Text", "w300 vpos")
     * subclassController := WindowSubclassController(g.Hwnd)
     * subclassController.MessageAdd(0x0003, OnMoveWindow) ; WM_MOVE
     * g.Show()
     *
     * OnMoveWindow(hwndSubclass, uMsg, wParam, lParam, *) {
     *     x := lParam & 0xFFFF
     *     y := (lParam >> 16) & 0xFFFF
     *     g := GuiFromHwnd(hwndSubclass)
     *     g['pos'].Text := x ', ' y
     * }
     * @
     *
     * See {@link https://github.com/Nich-Cebolla/AutoHotkey-LibV2/blob/main/test-files/test-WindowSubclassController.ahk}
     * for another usage example.
     *
     * @class
     *
     * @param {Integer} hwndSubclass - The handle to the window for which `SubclassProc`
     * will intercept its messages and notifications. Note that the window must have been
     * created by the AHK process.
     *
     * @param {Integer} [uIdSubclass] - If set, the unique identifier for this subclass. If unset,
     * a random number is generated. To avoid using the same id more than once, this library tracks
     * `uIdSubclass` values using the map object {@link WindowSubclassController.ids}.
     *
     * @param {String} [callbackCreateOptions = ""] - The value to pass to the `Options` parameter
     * of {@link https://www.autohotkey.com/docs/v2/lib/CallbackCreate.htm CallbackCreate}.
     *
     * @param {*} [subclassProc = WindowSubclassController_SubclassProc] - The function that will be
     * used as the subclass procedure, or the pointer to the function.
     *
     * If `SubclassProc` is a function object, it is passed to
     * {@link https://www.autohotkey.com/docs/v2/lib/CallbackCreate.htm CallbackCreate}, passing
     * `callbackCreateOptions` to the `Options` parameter.
     *
     * See {@link https://learn.microsoft.com/en-us/windows/win32/api/commctrl/nc-commctrl-subclassproc}
     * for details.
     *
     * @param {Boolean} [suppressUniqueIdError = false] - If false, if `uIdSubclass` already exists
     * in {@link WindowSubclassController.ids}, an error is thrown. If true, that error is suppressed
     * and the constructor is allowed to proceed normally. This parameter is included because it
     * is valid to use the same `uIdSubclass` more than once as long as the `SubclassProc` is different.
     *
     * @throws {Error} - "The `uIdSubclass` is already in use."
     */
    __New(hwndSubclass, uIdSubclass?, callbackCreateOptions := '', subclassProc := WindowSubclassController_SubclassProc, suppressUniqueIdError := false) {
        if IsSet(uIdSubclass) {
            if WindowSubclassController.ids.Has(uIdSubclass) {
                if suppressUniqueIdError {
                    WindowSubclassController.ids[uIdSubclass]++
                } else {
                    throw Error('The ``uIdSubclass`` is already in use.', , uIdSubclass)
                }
            }
        } else {
            loop {
                uIdSubclass := Random(1, 4294967295)
                if !WindowSubclassController.ids.Has(uIdSubclass) {
                    WindowSubclassController.ids.Set(uIdSubclass, 1)
                    break
                }
                if A_Index > 10000 {
                    throw Error('Failed to produce a unique id.')
                }
            }
        }
        if IsObject(subclassProc) {
            this.pfnSubclass := CallbackCreate(subclassProc, callbackCreateOptions)
            this.flag_callbackFree := 1
        } else {
            this.pfnSubclass := subclassProc
        }
        this.windowSubclass := WindowSubclass(this.pfnSubclass, uIdSubclass, hwndSubclass, ObjPtr(this), true)
        this.commandCollection := Map()
        this.messageCollection := Map()
        this.notifyCollection := Map()
        this.commandCollection.default :=
        this.messageCollection.default :=
        this.notifyCollection.default := ''
        this.data := Map()
    }
    /**
     * @desc - Adds a function to be called when the specified WM_COMMAND is sent.
     *
     * @param {Integer} CommandCode - The WM_COMMAND code.
     *
     * @param {*} Callback - A `Func` or callable object to call.
     *
     * Parameters:
     * 1. **{WindowSubclassController}** - This {@link WindowSubclassController} object
     * 2. **{Integer}** - hwndSubclass
     * 3. **{Integer}** - uMsg
     * 4. **{Integer}** - wParam
     * 5. **{Integer}** - lParam
     * 6. **{Integer}** - uIdSubclass
     * 7. **{VarRef}** - The value to return to the system.
     *
     * Regarding the last parameter: If your function needs to return a value to the system, it must
     * set the last parameter with the value that is to be returned and also the function must return
     * a nonzero value to the caller.
     *
     * If the function returns zero or an empty string, the process continues and the next function
     * is called. If the function returns a nonzero value, the value of the last parameter is returned
     * to the system and no further functions are called.
     *
     * @param {Integer} [InsertAt] - If set, an integer indicating the index at which the function
     * is to be inserted in the list of functions. If unset, the function is appended to the end
     * of the list.
     *
     * @returns {Integer} - The index at which the function was inserted.
     */
    CommandAdd(CommandCode, Callback, InsertAt?) {
        return this.__Add('Command', CommandCode, Callback, InsertAt ?? unset)
    }
    /**
     * @desc - Deletes one or all functions associated with `CommandCode`. If there are no remaining
     * callbacks in any of the containers, the window subclass is uninstalled. The winow subclass
     * will be reinstalled automatically the next time a callback is added to one of the containers.
     *
     * @param {Integer} CommandCode - The WM_COMMAND code.
     *
     * @param {*} [Callback] - If set, the function to delete. If unset, all of the functions
     * associated with `CommandCode` are deleted.
     *
     * @returns {Integer} - Returns the sum of the "Count" properties from each of the collections:
     * - {@link WindowSubclassController#commandCollection}
     * - {@link WindowSubclassController#messageCollection}
     * - {@link WindowSubclassController#notifyCollection}
     */
    CommandDelete(CommandCode, Callback?) {
        return this.__DeleteCallback('Command', CommandCode, Callback ?? unset)
    }
    /**
     * @param {Integer} Code - The code.
     *
     * @returns {WindowSubclass_CallbackCollection|String} - If `Code` exists in the collection,
     * returns the array of functions. Else, returns an empty string.
     */
    CommandGet(Code) {
        return this.commandCollection.Get(Code)
    }
    Dispose() {
        if this.windowSubclass {
            uIdSubclass := this.windowSubclass.uIdSubclass
            if WindowSubclassController.ids.Has(uIdSubclass) {
                value := WindowSubclassController.ids.Get(uIdSubclass)
                if value <= 1 {
                    WindowSubclassController.ids.Delete(uIdSubclass)
                } else {
                    WindowSubclassController.ids.Set(uIdSubclass, value - 1)
                }
            }
            this.windowSubclass.Uninstall()
            this.DeleteProp('WindowSubclass')
        }
        for name in [ 'Command', 'Message', 'Notify' ] {
            if this.HasOwnProp(name 'Collection') {
                collection := this.%name%Collection
                for code, callbackCollection in collection {
                    callbackCollection.length := 0
                }
                collection.Clear()
                this.DeleteProp(name 'Collection')
            }
        }
    }
    /**
     * @desc - Adds a function to be called when the specified message is sent.
     *
     * @param {Integer} MessageCode - The message code.
     *
     * @param {*} Callback - A `Func` or callable object to call.
     *
     * Parameters:
     * 1. **{WindowSubclassController}** - This {@link WindowSubclassController} object
     * 2. **{Integer}** - hwndSubclass
     * 3. **{Integer}** - uMsg
     * 4. **{Integer}** - wParam
     * 5. **{Integer}** - lParam
     * 6. **{Integer}** - uIdSubclass
     * 7. **{VarRef}** - The value to return to the system.
     *
     * Regarding the last parameter: If your function needs to return a value to the system, it must
     * set the last parameter with the value that is to be returned and also the function must return
     * a nonzero value to the caller.
     *
     * If the function returns zero or an empty string, the process continues and the next function
     * is called. If the function returns a nonzero value, the value of the last parameter is returned
     * to the system and no further functions are called.
     *
     * @param {Integer} [InsertAt] - If set, an integer indicating the index at which the function
     * is to be inserted in the list of functions. If unset, the function is appended to the end
     * of the list.
     *
     * @returns {Integer} - The index at which the function was inserted.
     */
    MessageAdd(MessageCode, Callback, InsertAt?) {
        return this.__Add('Message', MessageCode, Callback, InsertAt ?? unset)
    }
    /**
     * @desc - Deletes one or all functions associated with `MessageCode`. If there are no remaining
     * callbacks in any of the containers, the window subclass is uninstalled. The winow subclass
     * will be reinstalled automatically the next time a callback is added to one of the containers.
     *
     * @param {Integer} MessageCode - The message code.
     *
     * @param {*} [Callback] - If set, the function to delete. If unset, all of the functions
     * associated with `CommandCode` are deleted.
     *
     * @returns {Integer} - Returns the sum of the "Count" properties from each of the collections:
     * - {@link WindowSubclassController#commandCollection}
     * - {@link WindowSubclassController#messageCollection}
     * - {@link WindowSubclassController#notifyCollection}
     */
    MessageDelete(MessageCode, Callback?) {
        return this.__DeleteCallback('Message', MessageCode, Callback ?? unset)
    }
    /**
     * @param {Integer} Code - The code.
     *
     * @returns {WindowSubclass_CallbackCollection|String} - If `Code` exists in the collection,
     * returns the array of functions. Else, returns an empty string.
     */
    MessageGet(Code) {
        return this.messageCollection.Get(Code)
    }
    /**
     * @desc - Adds a function to be called when the specified WM_NOTIFY code is sent.
     *
     * @param {Integer} NotifyCode - The WM_NOTIFY code. This should be a signed value, not an
     * unsigned value.
     *
     * @param {*} Callback - A `Func` or callable object to call.
     *
     * Parameters:
     * 1. **{WindowSubclassController}** - This {@link WindowSubclassController} object
     * 2. **{Integer}** - hwndSubclass
     * 3. **{Integer}** - uMsg
     * 4. **{Integer}** - wParam
     * 5. **{Integer}** - lParam
     * 6. **{Integer}** - uIdSubclass
     * 7. **{VarRef}** - The value to return to the system.
     *
     * Regarding the last parameter: If your function needs to return a value to the system, it must
     * set the last parameter with the value that is to be returned and also the function must return
     * a nonzero value to the caller.
     *
     * If the function returns zero or an empty string, the process continues and the next function
     * is called. If the function returns a nonzero value, the value of the last parameter is returned
     * to the system and no further functions are called.
     *
     * @param {Integer} [InsertAt] - If set, an integer indicating the index at which the function
     * is to be inserted in the list of functions. If unset, the function is appended to the end
     * of the list.
     *
     * @returns {Integer} - The index at which the function was inserted.
     */
    NotifyAdd(NotifyCode, Callback, InsertAt?) {
        return this.__Add('Notify', NotifyCode, Callback, InsertAt ?? unset)
    }
    /**
     * @desc - Deletes one or all functions associated with `NotifyCode`. If there are no remaining
     * callbacks in any of the containers, the window subclass is uninstalled. The winow subclass
     * will be reinstalled automatically the next time a callback is added to one of the containers.
     *
     * @param {Integer} NotifyCode - The WM_NOTIFY code.
     *
     * @param {*} [Callback] - If set, the function to delete. If unset, all of the functions
     * associated with `CommandCode` are deleted.
     *
     * @returns {Integer} - Returns the sum of the "Count" properties from each of the collections:
     * - {@link WindowSubclassController#commandCollection}
     * - {@link WindowSubclassController#messageCollection}
     * - {@link WindowSubclassController#notifyCollection}
     */
    NotifyDelete(NotifyCode, Callback?) {
        return this.__DeleteCallback('Notify', NotifyCode, Callback ?? unset)
    }
    /**
     * @param {Integer} Code - The code.
     *
     * @returns {WindowSubclass_CallbackCollection|String} - If `Code` exists in the collection,
     * returns the array of functions. Else, returns an empty string.
     */
    NotifyGet(Code) {
        return this.notifyCollection.Get(Code)
    }
    /**
     * @desc - Adds an item to the map set to property {@link WindowSubclassController#data}.
     * Since the {@link WindowSubclassController} object is passed to each function, you can use
     * this to ensure your function has access to any needed data.
     *
     * @param {*} key - The item's key.
     *
     * @param {*} value - The item's value.
     */
    SetData(key, value) {
        this.data.Set(key, value)
    }
    __Add(Name, Code, Callback, InsertAt?) {
        Critical('On')
        collection := this.%Name%Collection
        if collection.count {
            if !(callbackCollection := collection.Get(Code)) {
                collection.Set(code, callbackCollection := WindowSubclass_CallbackCollection(Code))
            }
        } else {
            collection.Set(code, callbackCollection := WindowSubclass_CallbackCollection(Code))
            if !this.windowSubclass.isInstalled {
                this.windowSubclass.Install()
            }
        }
        if IsSet(InsertAt) {
            callbackCollection.InsertAt(InsertAt, Callback)
            return InsertAt
        } else {
            callbackCollection.Push(Callback)
            return callbackCollection.Length
        }
    }
    __DeleteCallback(Name, Code, Callback?) {
        collection := this.%Name%Collection
        if IsSet(Callback) {
            if callbackCollection := collection.Get(Code) {
                ; DeleteCallback returns the number of items in the collection after deletion.
                if !callbackCollection.DeleteCallback(Callback) {
                    collection.Delete(Code)
                }
            } else {
                throw UnsetItemError('Code not found.', , Code)
            }
        } else {
            collection.Delete(Code)
        }
        count := this.commandCollection.count + this.messageCollection.count + this.notifyCollection.count
        if !count {
            this.windowSubclass.Uninstall()
        }
        return count
    }
    __Delete() {
        if this.windowSubclass {
            uIdSubclass := this.windowSubclass.uIdSubclass
            if value := WindowSubclassController.ids.Get(uIdSubclass) {
                if value <= 1 {
                    WindowSubclassController.ids.Delete(uIdSubclass)
                } else {
                    WindowSubclassController.ids.Set(uIdSubclass, value - 1)
                }
            }
            this.windowSubclass.Uninstall()
        }
        if this.flag_callbackFree && this.pfnSubclass {
            CallbackFree(this.pfnSubclass)
        }
    }
}

class WindowSubclass {
    static __New() {
        this.DeleteProp('__New')
        proto := this.Prototype
        proto.dwRefData :=
        proto.hwndSubclass :=
        proto.isInstalled :=
        proto.pfnSubclass :=
        proto.uIdSubclass :=
        proto.__flag_callbackFree := 0

        hmod := DllCall('GetModuleHandleW', 'wstr', 'Comctl32', 'ptr')
        global g_comctl32_DefSubclassProc := DllCall('GetProcAddress', 'ptr', hmod, 'astr', 'DefSubclassProc', 'ptr')
        , g_comctl32_SetWindowSubclass := DllCall('GetProcAddress', 'ptr', hmod, 'astr', 'SetWindowSubclass', 'ptr')
        , g_comctl32_RemoveWindowSubclass := DllCall('GetProcAddress', 'ptr', hmod, 'astr', 'RemoveWindowSubclass', 'ptr')
    }
    /**
     * @desc - Calls {@link https://learn.microsoft.com/en-us/windows/win32/api/commctrl/nf-commctrl-setwindowsubclass SetWindowSubclass}
     *
     * A subclass allows your code to intercept every message that gets sent to a window that was
     * created in the AHK process. This offers complete control in how to respond to the messages.
     *
     * Further reading:
     *
     * - {@link https://learn.microsoft.com/en-us/windows/win32/controls/subclassing-overview}
     * - {@link https://learn.microsoft.com/en-us/windows/win32/api/commctrl/nf-commctrl-defsubclassproc}
     *
     * @class
     *
     * @param {*} SubclassProc - The function that will be used as the subclass procedure, or the
     * pointer to the function.
     *
     * If `SubclassProc` is a function object, it is passed to
     * {@link https://www.autohotkey.com/docs/v2/lib/CallbackCreate.htm CallbackCreate} with no
     * options.
     *
     * See {@link https://learn.microsoft.com/en-us/windows/win32/api/commctrl/nc-commctrl-subclassproc}
     * for details.
     *
     * @param {Integer} uIdSubclass - Serves as the unique id for this subclass.
     *
     * @param {Integer} hwndSubclass - The handle to the window for which `SubclassProc`
     * will intercept its messages and notifications. Note that the window must have been
     * created by the AHK process.
     *
     * @param {Buffer|Integer} [dwRefData] - If set, a buffer containing data that will be passed to the
     * subclass procedure, or a pointer to a memory address containing the data, or the data itself
     * if the data can be represented as a ptr-sized value.
     *
     * To later change this option, call {@link WindowSubclass.Prototype.SetRefData}.
     *
     * @param {Boolean} [DeferActivation = false] - If true, `SetWindowSubclass` is not called; your
     * code must call {@link WindowSubclass.Prototype.Install}.
     */
    __New(SubclassProc, uIdSubclass, hwndSubclass, dwRefData?, DeferActivation := false) {
        this.uIdSubclass := uIdSubclass
        this.hwndSubclass := hwndSubclass
        if IsSet(dwRefData) {
            this.dwRefData := dwRefData
        }
        if IsObject(SubclassProc) {
            this.pfnSubclass := CallbackCreate(SubclassProc)
            this.__flag_callbackFree := true
        } else {
            this.pfnSubclass := SubclassProc
        }
        if !DeferActivation {
            this.Install()
        }
    }
    /**
     * @desc - If the subclass has not been installed, installs it. If the subclass has already
     * been installed, this has no effect.
     *
     * @throws {OSError} - "The call to `SetWindowSubclass` failed."
     */
    Install() {
        if !this.isInstalled {
            if DllCall(
                g_comctl32_SetWindowSubclass
              , 'ptr', this.hwndSubclass
              , 'ptr', this.pfnSubclass
              , 'uptr', this.uIdSubclass
              , 'uptr', this.dwRefData
              , 'int'
            ) {
                this.isInstalled := true
            } else {
                throw OSError('The call to ``SetWindowSubclass`` failed.')
            }
        }
    }
    /**
     * @desc - Changes the value of property {@link WindowSubclass#dwRefData}. Then, if the window
     * subclass is installed, uninstalls it and reinstalls it using the new value.
     *
     * @param {Buffer|Integer} dwRefData - A buffer containing data that will be passed to the
     * subclass procedure, or a pointer to a memory address containing the data.
     *
     * @returns {Buffer|Integer} - The previous value.
     */
    SetRefData(dwRefData) {
        previous := this.dwRefData
        this.dwRefData := dwRefData
        if this.isInstalled {
            this.Uninstall()
            this.Install()
        }
        return previous
    }
    /**
     * @desc - If the window subclass is installed, uninstalls it by calling
     * {@link https://learn.microsoft.com/en-us/windows/win32/api/commctrl/nf-commctrl-removewindowsubclass RemoveWindowSubclass}.
     * If the window subclass is not installed, this has no effect.
     *
     * @throws {OSError} - "The call to `RemoveWindowSubclass` failed."
     */
    Uninstall() {
        if this.isInstalled {
            if DllCall(
                g_comctl32_RemoveWindowSubclass
              , 'ptr', this.hwndSubclass
              , 'ptr', this.pfnSubclass
              , 'uptr', this.uIdSubclass
              , 'int'
            ) {
                this.isInstalled := false
            } else {
                throw OSError('The call to ``RemoveWindowSubclass`` failed.')
            }
        }
    }
    __Delete() {
        if this.isInstalled {
            this.Uninstall()
        }
        if this.__flag_callbackFree {
            CallbackFree(this.pfnSubclass)
        }
    }
    /**
     * This has the following own properties:
     *
     * - dwRefData {@link WindowSubclas#dwRefData}
     * - hwndSubclass {@link WindowSubclas#hwndSubclass}
     * - isInstalled {@link WindowSubclas#isInstalled}
     * - pfnSubclass {@link WindowSubclas#pfnSubclass}
     * - uIdSubclass {@link WindowSubclas#uIdSubclass}
     */
}

class WindowSubclass_CallbackCollection extends Array {
    __New(code) {
        this.code := code
    }
    DeleteCallback(Callback) {
        for cb in this {
            if Callback = cb {
                this.RemoveAt(A_Index)
                return this.Length
            }
        }
        throw UnsetItemError('Callback not found.', , HasProp(Callback, 'Name') ? Callback.Name : '')
    }
}

class WindowSubclass_Nmhdr {
    static __New() {
        this.DeleteProp('__New')
        this.Prototype.Size := A_PtrSize * 3 ; +4 padding on x64
    }
    /**
     * @desc - A wrapper around the
     * {@link https://learn.microsoft.com/en-us/windows/win32/api/winuser/ns-winuser-nmhdr NMHDR}
     * structure.
     *
     * @param {Integer} ptr - The value passed to the "lParam" parameter of
     * {@link https://learn.microsoft.com/en-us/windows/win32/api/commctrl/nc-commctrl-subclassproc SUBCLASSPROC}
     * when the message is
     * {@link https://learn.microsoft.com/en-us/windows/win32/controls/wm-notify WM_NOTIFY}.
     */
    __New(ptr) {
        this.ptr := ptr
    }
    code => NumGet(this.ptr, g_windowSubclass_nmhdr_code_offset, 'uint')
    code_int => NumGet(this.ptr, g_windowSubclass_nmhdr_code_offset, 'int')
    hwndFrom => NumGet(this.ptr, 'ptr')
    idFrom => NumGet(this.ptr, A_PtrSize, 'ptr')
}

/**
 * @desc - {@link https://learn.microsoft.com/en-us/windows/win32/api/commctrl/nc-commctrl-subclassproc}.
 * This is intended to be used with {@link WindowSubclassController}.
 *
 * @param {Integer} hwndSubclass - The handle to the subclassed window (the handle passed to `SetWindowSubclass`).
 *
 * @param {Integer} uMsg - The message being processed.
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

WindowSubclassController_OnNCDestroy(subclassController, *) {
    WindowSubclassController.collection.Delete(subclassController.windowSubclass.hwndSubclass)
    subclassController.windowSubclass.Uninstall()
}
__WindowSubclassController_ThrowMissingObjectError(hwndSubclass) {
    throw Error('The ``WindowSubclassController`` object has been deleted from the collection.', , 'hwnd: ' hwndSubclass)
}
