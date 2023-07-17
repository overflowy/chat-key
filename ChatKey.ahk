#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn ; Enable warnings to assist with detecting common errors.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.
#Persistent
#Include libs\JSON.ahk

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
        MsgBox, Replace mode active.
        clipboard := text
    }
    else {
        MsgBox, Replace mode inactive.
        newText = %clipboard%`n`n%text%
        clipboard := newText
    }

    SendInput, ^v

    ; Restore the previous clipboard contents
    Sleep, 500
    clipboard := prevClipboard
}

PrepareRequestBody(section) {
    ; Copy the selected text
    text := CopyText()
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

    http := ComObjCreate("Msxml2.ServerXMLHTTP")
    http.Open("POST", "https://api.openai.com/v1/chat/completions", false)
    http.SetRequestHeader("Authorization", "Bearer " . API_KEY)
    http.SetRequestHeader("Content-Type", "application/json")
    http.Send(requestBodyJson)

    response := http.ResponseText

    ; Parse the response
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
        try {
            section := prompts[A_ThisMenuItem]

            ; If the section is not defined, return
            if not (section) {
                MsgBox, "Section not defined"
                return
            }

            ; Show a generic tooltip
            ToolTip, ...
            Sleep, 200

            ; Prepare the request body
            requestBody := PrepareRequestBody(section)
            if (requestBody == "") {
                ToolTip
                return
            }

            ; Send the request
            text := SendRequest(requestBody)

            ; Remove the tooltip
            ToolTip

            ; Paste the text
            PasteText(text)
        }
        catch e {
            ToolTip
        }
    return
}

; Init the popup menu shortcut
IniRead, popupMenuShortcut, config.ini, settings, popup_menu_shortcut, !.
Hotkey, % popupMenuShortcut, ShowMenu
