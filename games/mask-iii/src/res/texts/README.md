# Texts

UTF-8. Bit-7-terminated strings: a line ends where a byte has bit 7 set (the character written plain); a last line
without one ends in a backslash; bytes that are not printable ASCII are `{XX}` (in `menu.txt` each string starts
with two place bytes, `{18}{09}PROGRAM` = column `$18`, row `$09`: the credits at the right, DrawMenu `$9D1A`).

| File | Entry |
| --- | --- |
| `menu.txt` | MenuStrings `$9D6C` (the 15 menu strings, "P.ENTER PASSWOID" as the bytes have it) |
| `messages.txt` | Messages `$AD7C` (GOOD LUCK MATT, CODE BROKEN, PASSWORD IS and the 16-byte buffer) |
| `end.txt` | EndTexts `$AE1D` |
| `masks.txt` | MaskNames `$B197`: 11 names of 11 characters, a line each ending in `|` |
| `passwords.txt` | Passwords `$A009`: the four passwords as typed, a line each (stored as key codes row x 16 + bit) |
