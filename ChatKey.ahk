#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn ; Enable warnings to assist with detecting common errors.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.
#Persistent
#Include libs\JSON.ahk

; Set the tray icon
Menu, Tray, Icon, assets\app.ico

; Use OPENAI_TOKEN environment variable
EnvGet, API_KEY, OPENAI_TOKEN

; If the API key is not set, show an error message and exit
if (API_KEY = "") {
    MsgBox,, Missing API Key, Please set the OPENAI_TOKEN environment variable to your OpenAI API key.
    ExitApp
}

; If the config file is missing, show an error message and exit
if not (FileExist("config.ini")) {
    MsgBox,, Missing Config File, Please make sure the config file is in the same directory as the script.
    ExitApp
}

prevClipboard := ""

CopyText() {
    ; Save the previous clipboard contents
    global prevClipboard := clipboard

    ; Copy the selected text
    clipboard := ""
    SendInput, ^c
    ClipWait, 1

    ; If clipboard is empty, return
    if (clipboard == "") {
        MsgBox,, No Text Selected, Please select some text before running the script.
        clipboard := prevClipboard
        return
    }

    clipboard := RTrim(clipboard, "`n")
    return clipboard
}

PasteText(text) {
    global prevClipboard

    IniRead, replaceText, config.ini, settings, replace_text, 0
    replaceText += 0 ; Convert to number

    if (replaceText == 1) {
        clipboard := text
    }
    else {
        newText = %clipboard%`n`n%text%
        clipboard := newText
    }

    SendInput, ^v

    ; Restore the previous clipboard contents
    Sleep, 500
    clipboard := prevClipboard
}

PrepareRequestBody(section) {
    ; Copy the selected text]
    text := CopyText()

    Gui, Destroy ; Destroy previous GUI

    if (text == "") {
        return
    }

    ; Read config parameters
    IniRead, model, config.ini, % section, model, gpt-3.5-turbo
    IniRead, temperature, config.ini, % section, temperature, 0.7
    IniRead, systemPrompt, config.ini, % section, system_prompt

    ; Make sure system_prompt param is defined
    if (systemPrompt == "ERROR") {
        MsgBox,, Missing System Prompt, Please set the system_prompt parameter in the config file.
        return
    }

    ; Prepare the request body
    requestBody := {}
    requestBody.model := model
    requestBody.temperature := temperature + 0 ; Convert to number
    requestBody.messages := [{"role": "system", "content": systemPrompt}, {"role": "user", "content": text}]

    return requestBody
}

SendRequest(requestBody) {
    global API_KEY

    ; Convert the request body to valid JSON
    requestBodyJson := Json.Dump(requestBody)

    ; Send the request
    http := ComObjCreate("Msxml2.ServerXMLHTTP")
    http.Open("POST", "https://api.openai.com/v1/chat/completions", false)
    http.SetRequestHeader("Authorization", "Bearer " . API_KEY)
    http.SetRequestHeader("Content-Type", "application/json")
    http.Send(requestBodyJson)

    ; Parse the response
    response := http.ResponseText
    jsonResponse := Json.Load(response)

    ; Check for errors
    err := jsonResponse.error.message
    if (err != "") {
        MsgBox,, Response Error, % err
        return
    }

    ; Return the message content
    return jsonResponse.choices[1].message.content
}

HideTrayTip() {
    TrayTip ; Attempt to hide it the normal way
    if SubStr(A_OSVersion,1,3) = "10." {
        Menu Tray, NoIcon
        Sleep 200
        Menu Tray, Icon
    }
}

; Show the popup menu
ShowMenu() {
    try {
        Menu, popupMenu, DeleteAll
    }
    catch e {
        ; Do nothing
    }

    IniRead, menu_items, config.ini, popup_menu
    prompts := {}

    Loop, Parse, menu_items, `n
    {
        section := A_LoopField
        if (section == "---") { ; Separator
            Menu, popupMenu, Add
        }
        else {
            IniRead, name, config.ini, % section, name
            IniRead, shortcut, config.ini, % section, shortcut

            label = &%shortcut% %name%
            prompts[label] := section
        }
        Menu, popupMenu, Add, % label, MenuHandler
    }
    Menu, popupMenu, Show
    return

    MenuHandler:
        TrayTip,, Waiting..., 5, 1

        section := prompts[A_ThisMenuItem]

        ; If the section is not defined, return
        if not (section) {
            MsgBox, "Section not defined"
            return
        }

        ; Prepare the request body
        requestBody := PrepareRequestBody(section)
        if (requestBody == "") {
            ToolTip
            return
        }

        ; Send the request and get the response
        responseText := SendRequest(requestBody)
        HideTrayTip()

        if (responseText == "") {
            return
        }

        DllCall("User32\SetThreadDpiAwarenessContext", "UInt" , -1) ; Disable DPI scaling
        Gui, -Caption +AlwaysOnTop -DPIScale
        Gui, Margin, 0, 0
        Gui, Font, s13 c1d1d1d Calibri
        Gui, Color, c1d1d1d, c1d1d1d
        Gui, Add, Progress, x-1 y-1 w400 h32 Backgroundb5614b Disabled
        Gui, Add, Text, x0 y0 w400 h30 BackgroundTrans Center 0x200 gGuiMove vCaption, ChatKey
        Gui, Add, Edit, vMainEdit cb4b4b4 x6 y+14 w411 r20 -E0x200 ; Add the edit box
        GuiControl,, MainEdit, % responseText ; Set the text
        Gui, Add, Picture, x350 y+5 w42 h42 gConfirm, assets\enter.ico
        Gui, Add, Button, y+10 Default gConfirm, Confirm ; Add a hidden button so we can use Enter to confirm
        Gui, +LastFound ; Make the GUI window the last found window for the next WinSet
        WinSet, Region, 0-0 w400 h508 r6-6 ; Round the corners
        Gui, Show, w400
        SendInput, {End} ; Move the cursor to the end of the text
        GuiControl, Focus, Confirm ; Focus the hidden button
    return

    Confirm:
        Gui, Submit, NoHide
        GuiControlGet, text,, MainEdit
        Gui, Destroy

        PasteText(text)
    return

    GuiMove:
        PostMessage, 0xA1, 2
    return

    GuiEscape:
        Gui, Destroy
    return
}

; Init the popup menu hotkey
IniRead, popupMenuHotkey, config.ini, settings, popup_menu_hotkey, !.
Hotkey, % popupMenuHotkey, ShowMenu

TrayTip,, Ready to use, 3, 1

Menu, Tray, NoStandard
Menu, Tray, Add, Edit Config, EditConfig
Menu, Tray, Add, Reload, Reload_
Menu, Tray, Add, Update ChatKey, Update
Menu, Tray, Add, About
Menu, Tray, Add, Exit
return

EditConfig:
    Run, %A_ScriptDir%\config.ini
return

Reload_:
    Reload
return

Update:
    Run, https://github.com/overflowy/chat-key/releases/latest/download/ChatKey.zip
return

About:
    Run, https://github.com/overflowy/chat-key
return

Exit:
ExitApp
