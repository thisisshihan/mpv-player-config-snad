repl.lua.
========

Keybindings
-----------

| Key | Action |
| ---: | :--- |
| <kbd>`</kbd> | Show the REPL |
| <kbd>Esc</kbd> | Hide the REPL |
| <kbd>Enter</kbd> | Run the typed command |
| <kbd>Shift</kbd> + <kbd>Enter</kbd> | Type a literal newline character |
| <kbd>Ctrl</kbd> + <kbd>←</kbd>, <kbd>Ctrl</kbd> + <kbd>→</kbd> | Move cursor to previous/next word |
| <kbd>↑</kbd>, <kbd>↓</kbd> | Navigate command history |
| <kbd>PgUp</kbd> | Go to the first command in the history |
| <kbd>PgDn</kbd> | Stop navigating command history |
| <kbd>Insert</kbd> | Toggle insert mode |
| <kbd>Shift</kbd> + <kbd>Insert</kbd> | Paste text (uses the primary selection on X11) |
| <kbd>Tab</kbd> | Complete the command or property name at the cursor |
| <kbd>Ctrl</kbd> + <kbd>C</kbd> | Clear current line |
| <kbd>Ctrl</kbd> + <kbd>K</kbd> | Delete text from the cursor to the end of the line |
| <kbd>Ctrl</kbd> + <kbd>L</kbd> | Clear all log messages from the console |
| <kbd>Ctrl</kbd> + <kbd>U</kbd> | Delete text from the cursor to the beginning of the line |
| <kbd>Ctrl</kbd> + <kbd>V</kbd> | Paste text (uses the clipboard on X11) |
| <kbd>Ctrl</kbd> + <kbd>W</kbd> | Delete text from the cursor to the beginning of the current word |

Commands
--------

| Command | Action |
| :--- | :--- |
| ``script-message-to repl type "<text>"`` | Show the REPL and pre-fill it with the provided text |

Known issues
