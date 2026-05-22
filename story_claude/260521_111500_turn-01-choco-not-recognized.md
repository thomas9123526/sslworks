# Turn 01 — choco not recognized

**User prompt:**
> (pasted error) `choco install mkcert` failed —
> `'choco' is not recognized as the name of a cmdlet...`

**Assistant response:**
Chocolatey isn't installed. Checked which package managers were
available: `winget` present
(`C:\Users\aaa\AppData\Local\Microsoft\WindowsApps\winget.exe`),
`scoop` and `choco` absent. Recommended
`winget install FiloSottile.mkcert`, and offered to run it.

## Latest prompt

> choco : The term 'choco' is not recognized as the name of a cmdlet,
> function, script file, or operable program. Check the spelling of the
> name, or if a path was included, verify that the path is correct and
> try again.
> At line:1 char:1
> + choco install mkcert            # or: scoop install mkcert
