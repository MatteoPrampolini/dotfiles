# Prampo's Dotfiles

W.I.P. repo for my dotfiles.

This is *my personal config*, so it might be garbage for you.

The idea is to be as system-agnostic as possible.

This repo **must** be cloned into `$HOME/dotfiles`.

From that point on, `$HOME/dotfiles` becomes the source of truth.

This is not intended to be just a "read-only" copy of my configs to manually copy and paste around. This is not a reference.

**This is it. The real config.**

For example, the Doom Emacs config would normally live in `$HOME/.doom.d/`.

We can run this once:

```powershell
New-Item -ItemType SymbolicLink `
    -Path "$HOME\.doom.d" `
    -Target "$HOME\dotfiles\doom"
```

From then on, `$HOME\dotfiles\doom` is the source of truth.

Pulling an update will update all the configs at once (hopefully).
