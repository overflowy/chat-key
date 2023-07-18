# ChatKey 🚀

Supercharge your productivity with ChatGPT/GPT-4 and AutoHotkey

<img src="assets/hero.jpg" width="50%">

## Table of Contents

- [Why?](#why)
- [Example](#example)
- [Usage](#usage)
- [Configuration](#configuration)
  - [Basic settings](#basic-settings)
  - [Adding prompts](#adding-prompts)
  - [Prompt settings](#prompt-settings)

## Why?

With an abundance of AI-powered content-generating tools available on the internet, many come with cost restrictions or require a browser. ChatKey is free, completely [customizable](#configuration), and works in any application that supports text input.

## Example

https://github.com/overflowy/chat-key/assets/98480250/81b9ceb7-5c19-47ef-b4d7-ffc84a552ca3

## Usage

1. Please ensure that you have properly configured the `OPENAI_TOKEN` environment variable
2. Download the latest release from the [releases](https://github.com/overflowy/chat-key/releases/) page
3. Extract the zip file
4. Run `ChatKey.exe`
5. Start typing in any application that supports text input
6. Select the text you want to use as basis for the prompt
7. Press the hotkey to show the popup menu (default: `Alt + .`).
8. Select the prompt you want to use
9. Wait for the response to be generated
10. Review the response and press `Enter` to insert it into the application

## Configuration

You can configure ChatKey by editing the included `config.ini` file.

### Basic settings

| Key            | Description                                          | Default   |
| -------------- | ---------------------------------------------------- | --------- |
| `hotkey`       | The hotkey to show the popup menu                    | `Alt + .` |
| `replace_text` | Whether to replace the selected text with the prompt | `0`       |

More settings will be added in future releases.

### Adding prompts

You can add new prompts by adding a new section to the `config.ini` file. Let's say you want to add a prompt to translate any text to Italian. You can do so by adding the following section to the config file:

```ini
[prompt_translate_to_italian]
name = Translate to Italian
shortcut = t
system_prompt = "I want you to act as an Italian translator. I will say something in any language and you will translate it to Italian. The first thing I want you to translate is:"
temperature = 0.2
model = gpt-3.5-turbo
```

To ensure that the newly added prompt is available in the popup menu, it is necessary to include it in the `[popup_menu]` section. You also have the option to add separators to the popup menu by using the `---` key.

There's no need to restart ChatKey after making changes to the config file. The changes will be applied automatically.

```ini
[popup_menu]
---
prompt_translate_to_italian
```

### Prompt settings

You can individually configure the parameters of each prompt. If keys with default values are omitted, the default values will be used instead.

| Key             | Description                                                                                              | Default   |
| --------------- | -------------------------------------------------------------------------------------------------------- | --------- |
| `name`          | The name of the prompt that will be displayed in the popup menu                                          |           |
| `shortcut`      | The shortcut key to select the prompt from the popup menu                                                |           |
| `system_prompt` | The prompt that will be used to generate the response                                                    |           |
| `temperature`   | The temperature to use when generating the response (0.0 - 1.0)                                          | `0.7`     |
| `model`         | The model to use when generating the response, more info [here](https://platform.openai.com/docs/models) | `gpt-3.5` |

More parameters will be included in future releases.
