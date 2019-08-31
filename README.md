# Scripts

Typical script repo. Right now It's only tested in Ubuntu 19.04. I'll be adding a feature to autodetect the distor and adjust package managers accordingly. 

I've subdivided the monolith script so that in the future I can prompt (or auto) for desired package/setup groups. For example, for some burner machine, I may need my dev tools, but not my communications packages like Riot, Keybase, etc.

To Do:

* Auto detect OS and vary the package manager/installation syntax.

* Add Prompts for package groups.

	* Add prompt to accept packages after they're explicity listed, and abort if they don't want them. Or continue without installing packages (so user can just get the dotfiles.)

* Add NetSec scripts.
