This project is named `Intellector Frontend v3.0` and it is a sandbox for the future iteration of the Intellector board game website (frontend). It will be used to rebuild this project from scratch, improving on the previous iteration located in `C:/Users/mitmi/Documents/GitHub/Intellector` (in the inconsistent and unbuildable state).

ANY AMBIGUITY OR DESIGN DOC GAP SURFACING DURING THE IMPLEMENTATION SHOULD NOT BE RESOLVED SILENTLY. Instead, explicitly ask the question.

`haxe build.hxml` builds the project.

# Tech stack

This project will be written in `Haxe` targeting `HTML5` using the HaxeFolio framework. Its sources are located in the framework's own repo (`C:/Users/mitmi/Documents/GitHub/Libraries/haxefolio`). Utility functions are defined in a separate lib (located in `C:/Users/mitmi/Documents/GitHub/Libraries/morestd`). The source files of both libraries may be freely edited, but the libraries should remain independent and universal, not tailored to `Intellector Frontend v3.0` specifically.

HaxeFolio is built over the `HaxeUI` library (`haxeui-core` plus its `haxeui-html5` backend). `HaxeUI` may have bugs, but they should be identified with care and special approval is needed for implementing the fixes. Each bug found needs to be demonstrated with a minimal reproducible example in the shape of a single XML file.

# Project structure and lib modules

...

# Transition

Overall, the transition will be performed page-after-page. The page will usually be thoroughly tested before the next one will be taken into work.

The original version above can be used as a declarative reference (answering how the result is expected to look like, minus the ill-designed aspects), but the concrete approaches and decisions chosen may and should be subject to being questioned.

...

# Code style conventions

See `code_style.md`.
