# Turn 28 — count python installations

**User prompt:**
> How many python are there in this windows system?

**Assistant response:**
Checked PATH, the `py` launcher registry, Microsoft Store aliases, and
common install trees. Found **2 real installations**:

| Source | Version | Path |
|---|---|---|
| Standalone (user-profile installer) | 3.10.11 | `C:\Users\aaa\AppData\Local\Programs\Python\Python310\python.exe` |
| Anaconda (base environment) | 3.13.9 | `C:\Users\aaa\anaconda3\python.exe` |

Not real installations: the `WindowsApps\python*.exe` App Execution
Alias stubs, `C:\Windows\py.exe` (launcher — only knows the 3.10),
venv-template `python.exe` copies, and Anaconda's `pkgs` cache copy.
Flagged that neither PATH nor `py -0p` knows about the Anaconda 3.13 —
it needs `conda activate`.

## Latest prompt

> How many python are there  in this windows system?
