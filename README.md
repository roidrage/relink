### relink - A URL shortener-based on Redis, because personal URL-shortening is the new bit.ly, and because Redis is awesome

Requirements
============

* [Sinatra](http://sinatrarb.com)
* [Redis](http://code.google.com/p/redis)
* [redis](http://github.com/ezmobius/redis-rb) Ruby library, install from gemcutter via `gem install redis`
* [sinatra-authorization](http://github.com/integrity/sinatra-authorization) from gemcutter

URLs
====

To shorten a URL, go to the start page and enter the URL, or post to /t with url=http://www.github.com in the request body. That'll return just the shortened URL as plain text, convenient for usage in scripts to simplify shortening, see below for more details.

/p/<id> shows the clicks and the expanded URL

/list lists all known URLs and their click count.

Authentication
==============

If you put a file httpasswd in the application's root directory, the app will protect most URLs (except the homepage and a shortened URL) with a http authentication. The file's format is a list of user names with a SHA1-encoded password:

redis:1be168ff837f043bde17c0314341c84271047b31

If you deploy using Capistrano, just put the htpasswd file into app\_dir/shared/config, and it'll be automatically linked into the app directory.

Scripting URL shortening
========================

Thanks to @janl for sponsoring this little AppleScript to shorten the URL currently open in Safari. Adapt for your needs.

    tell application "Safari"
      set longURL to URL of front document as string
    end tell

    set shellScript to ("curl -X POST --url http://USER:PASS@short.en/t --data 'url=" & longURL & "' ")

    set shortURL to (do shell script shellScript)

    set the clipboard to shortURL

Use LaunchBar or QuickSilver or whatever script app you like to execute it conveniently.

Misc
====

The app is not tied to any specific domain. Deploy and be done with it.

License
=======

MIT baby!

copyright 2009 Mathias Meyer <meyer@paperplanes.de>