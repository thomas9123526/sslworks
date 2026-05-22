# Turn 27 — count cmake installations

**User prompt:**
> How many cmakes are there in this windows system?

**Assistant response:**
Searched PATH and common install trees. Found **3** cmake
installations, **none on PATH**:

| Source | Version | Path |
|---|---|---|
| Visual Studio 2022 Enterprise (bundled) | 3.31.6-msvc6 | `...\2022\Enterprise\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe` |
| Android SDK | 3.22.1 | `C:\Users\aaa\AppData\Local\Android\Sdk\cmake\3.22.1\bin\cmake.exe` |
| Android SDK | 4.1.2 | `C:\Users\aaa\AppData\Local\Android\Sdk\cmake\4.1.2\bin\cmake.exe` |

Noted that to use one from a normal shell you'd add its dir to PATH or
`winget install Kitware.CMake`.

## Latest prompt

> How many cmakes are there  in this windows system?
