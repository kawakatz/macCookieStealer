# macCookieStealer
<p align="center">
<a href="https://opensource.org/licenses/MIT"><img src="https://img.shields.io/badge/license-MIT-_red.svg"></a>
<a href="https://github.com/kawakatz/macCookieStealer/issues"><img src="https://img.shields.io/badge/contributions-welcome-brightgreen.svg?style=flat"></a>
<a href="https://twitter.com/kawakatz"><img src="https://img.shields.io/twitter/follow/kawakatz.svg?logo=twitter"></a>
</p>
macCookieStealer steals cookies from Google Chrome.

# Logic
1. terminate Google Chrome because we cannot start it in debug mode if normal session is running.
2. start Google Chrome in debug mode with "--restore-last-session" option.
3. connect to debugging port.
4. steal cookies from debugging port.

Note:
- we cannot start Google Chrome in debug mode while original session is running.
- It takes about 1 or 2 seconds to restart Gogle Chrome.
- Google Chrome will be still running after macCookieStealer finished.

## Usage
on a victim's machine
```sh
➜  ~ ./macCookieStealer
...
[+] import the following json to Firefox with CookieQuickManager
...
```

and import the output to CookieQuickManager.<br>
CookieQuickManager: https://addons.mozilla.org/en-US/firefox/addon/cookie-quick-manager/

# Basic Idea
https://github.com/defaultnamehere/cookie_crimes
