#NoEnv ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn ; Enable warnings to assist with detecting common errors.
SendMode Input ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir% ; Ensures a consistent starting directory.

#Include libs\JSON.ahk

; Check if the API key is set in the OPENAI_TOKEN environment variable
EnvGet, API_KEY, OPENAI_TOKEN

; If the API key is not set, show an error message and exit
if (API_KEY = "") {
    MsgBox,, Missing API Key, Please set the OPENAI_TOKEN environment variable to your OpenAI API key.
    ExitApp
}

; If the config file is missing, show an error message and exit
if not (FileExist("config.ini")) {
    MsgBox,, Missing Config File, Please redownload the script and make sure the config file in the same directory as the script.
    ExitApp
}

MODEL := "gpt-3.5-turbo"
TEMPERATURE = 0.7

prevClipboard := ""

; Copy the selected text to the clipboard
CopyText() {
    ; Save the previous clipboard contents
    global prevClipboard := clipboard

    clipboard := ""
    SendInput, ^c
    ClipWait, 1

    ; If clipboard is empty, return
    if (clipboard == "") {
        MsgBox,, No Text Selected, Please select some text before running the script.
        clipboard := prevClipboard
        return
    }

    return clipboard
}

; Paste the text to the active window
PasteText(text) {
    global prevClipboard

    clipboard := text
    SendInput, ^v

    ; Restore the previous clipboard contents
    Sleep, 500
    clipboard := prevClipboard
}

SendRequest(systemPrompt, userPrompt) {
    global API_KEY
    global MODEL
    global TEMPERATURE

    ; Create a WinHttpRequest object
    http := ComObjCreate("Msxml2.ServerXMLHTTP")

    ; Prepare the request body object
    requestBody := {}
    requestBody.model := MODEL
    requestBody.temperature := TEMPERATURE + 0 ; Convert to number

    requestBody.messages := [{"role": "system", "content": systemPrompt}, {"role": "user", "content": userPrompt}]

    ; Convert the request body to valid JSON string
    requestBodyJson := Json.Dump(requestBody)

    ; Send the request
    http.Open("POST", "https://api.openai.com/v1/chat/completions", false)
    http.SetRequestHeader("Authorization", "Bearer " . API_KEY)
    http.SetRequestHeader("Content-Type", "application/json")
    http.Send(requestBodyJson)

    ; Retrieve the response
    response := http.ResponseText
    ; -- MsgBox, % response

    ; Parse the response to extract the completed text
    jsonResponse := Json.Load(response)

    ; Check for errors
    err := jsonResponse.error.message
    if (err != "") {
        MsgBox,, Response Error, % err
        return
    }

    return jsonResponse.choices[1].message.content
}

; Trigger the script when the user presses Alt + .
!.::
    try {
        ; Show a tooltip
        ToolTip, ...
        Sleep, 20

        ; Copy the selected text
        text := CopyText()
        if (text == "") {
            ToolTip
            return
        }

        ; Replace the selected text with the completion
        text := SendRequest("You are a helpful assistant.", text)
        PasteText(text)

        ; Remove the tooltip
        ToolTip
    }
    catch e {
        ToolTip
    }

return
