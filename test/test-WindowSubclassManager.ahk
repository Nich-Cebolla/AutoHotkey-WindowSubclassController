
#Requires AutoHotkey >=2.0-a
#Singleinstance force
#include ..\src\WindowSubclassController.ahk

if !A_IsCompiled && A_ScriptFullPath == A_LineFile {
    test_WindowSubclassManager()
    OutputDebug(A_ScriptName ': complete.`n')
}

class test_WindowSubclassManager {
    static Call() {
        subclassManager := WindowSubclassManager()
        g := this.g := gui()
        subclassManager.CommandAdd(g.hwnd, 1, command)
        subclassManager.MessageAdd(g.hwnd, 1, message)
        subclassManager.NotifyAdd(g.hwnd, 1, notify)

        subclassController := subclassManager.collection.Get(g.hwnd)

        if subclassController.CommandAddIf(1, command) {
            throw Error('Expected 0.')
        }
        if subclassController.commandCollection.Get(1).length != 1 {
            throw Error('Expected 1.')
        }

        if subclassController.MessageAddIf(1, message) {
            throw Error('Expected 0.')
        }
        if subclassController.messageCollection.Get(1).length != 1 {
            throw Error('Expected 1.')
        }

        if subclassController.NotifyAddIf(1, notify) {
            throw Error('Expected 0.')
        }
        if subclassController.notifyCollection.Get(1).length != 1 {
            throw Error('Expected 1.')
        }

        if subclassManager.CommandAddIf(g.hwnd, 1, command) {
            throw Error('Expected 0.')
        }
        if subclassController.commandCollection.Get(1).length != 1 {
            throw Error('Expected 1.')
        }

        if subclassManager.MessageAddIf(g.hwnd, 1, message) {
            throw Error('Expected 0.')
        }
        if subclassController.messageCollection.Get(1).length != 1 {
            throw Error('Expected 1.')
        }

        if subclassManager.NotifyAddIf(g.hwnd, 1, notify) {
            throw Error('Expected 0.')
        }
        if subclassController.notifyCollection.Get(1).length != 1 {
            throw Error('Expected 1.')
        }

        if subclassManager.CommandDeleteIf(g.hwnd, 1, command) != 1 {
            throw Error('Expected 1.')
        }
        if subclassController.commandCollection.Has(1) {
            throw Error('Expected 0.')
        }
        if subclassManager.CommandDeleteIf(g.hwnd, 1, command) != 0 {
            throw Error('Expected 0.')
        }

        if subclassManager.MessageDeleteIf(g.hwnd, 1, message) != 1 {
            throw Error('Expected 1.')
        }
        if subclassController.messageCollection.Has(1) {
            throw Error('Expected 0.')
        }
        if subclassManager.MessageDeleteIf(g.hwnd, 1, message) != 0 {
            throw Error('Expected 0.')
        }

        if subclassManager.NotifyDeleteIf(g.hwnd, 1, notify) != 1 {
            throw Error('Expected 1.')
        }
        if subclassController.notifyCollection.Has(1) {
            throw Error('Expected 0.')
        }
        if subclassManager.NotifyDeleteIf(g.hwnd, 1, notify) != 0 {
            throw Error('Expected 0.')
        }

        if subclassManager.collection.Count != 0 {
            throw Error('Expected 0.')
        }

        if subclassManager.CommandAddIf(g.hwnd, 1, command) != 1 {
            throw Error('Expected 1.')
        }
        if subclassManager.MessageAddIf(g.hwnd, 1, message) != 1 {
            throw Error('Expected 1.')
        }
        if subclassManager.NotifyAddIf(g.hwnd, 1, notify) != 1 {
            throw Error('Expected 1.')
        }

        g.Destroy()

        if subclassManager.collection.Count != 0 {
            throw Error('Expected 0.')
        }

        command(*) {
        }
        message(*) {
        }
        notify(*) {
        }
    }
}
