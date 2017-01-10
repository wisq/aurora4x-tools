# aurora4x-tools

A set of tools to help with playing Aurora 4X.

## Tools

### `watch.rb`

Watches your game and provides feedback.

Current feedback areas:

* Are you using all your …
  * Research labs?
  * Factories?
* Are all your mining colonies operational?
  * Do they have minerals left?
  * If they have mass drivers, do they have a target / are themselves a target?
  * Are there any mass drivers on mining colonies with no mines?
* Do all your colonies and sectors have governors?
* Are any of your assigned governors or researchers going to die / retire soon?
  * Did any of them die last turn, and how/why?  (Monitors the game log.)

Note that some of the above may be duplicates of in-game warnings — but you typically only get those warnings after your next jump, which could be up to 30 days of e.g. wasted lab time.  This lets you keep on top of things and avoid wasted time.

This script is a work in progress.  Possible future additions:

* Are all your shipyards doing something?
* Are there any construction projects, shipyard updates, or research projects that will finish in less than 30 days?  (for optimal time warping)
* **Suggestions welcome!**

### `test.rb`

A development script for testing out raw queries, typically for adding them to other scripts.

## Setup

You'll need …

* a Windows system
* [Aurora 4X](http://aurorawiki.pentarch.org/) version 7.1 (or a higher 7.x)
* Ruby & bundler
* the password for the Aurora database
* an ODBC connection set up with the name `aurora`

### Windows

You'll need to run this directly on the Windows system you play Aurora on; it requires the Microsoft Access drivers.  I'm not currently aware of any method of running it on other operating systems.  Besides, it needs to operate directly on the live Aurora database.

Personally, I use Cygwin, but if you're running Windows 10 or higher, you could probably get this working under the *Windows Subsystem for Linux* framework.  I can't test it personally under that environment, but I can accept pull requests to help make it work.

### Aurora 4X

These tools were developed against Aurora version 7.1.  It's possible that it will work with prior versions, but I have no idea.

There is currently an effort underway to rewrite Aurora in C# (instead of Visual Basic).  The database format will also be changing (likely to SQLite), but more importantly, it will no longer be writing to the database in real-time — only when you save your game.

As such, these tools will very likely become obsolete once Aurora 8.0 hits.  I may be able to use memory inspection to recreate them, but that would be a significant rewrite, with no guarantee it's even possible.

**TL;DR:** If you're using Aurora 8.0 or higher — particularly if it doesn't include a `Stevefire.mdb` database file — you're probably SOL as far as using these tools go.  Either enjoy the new version, or go back to 7.1.

### Ruby & bundler

You'll need Ruby installed.  Run `ruby -v` and see if you get a version number.  You want at least `2.0`, but ideally `2.2` or higher.

You'll need the `bundler` gem installed.  Run `bundle`.  If it installs a bunch of gems for you, then you're set.  Otherwise, run `gem install bundler` and try `bundle` again.

### Database password

You'll need to get the password for the `Stevefire.mdb` database that comes with Aurora 4X.  The proper way to get this password is to contact Steve (the creator) privately and ask for it.

**Please don't share this password.**  If you need to report any bugs, make sure the password isn't included in your bug report — particularly in any debug output you paste.

I'm aware that there are other ways to get the password for an Access database.  I won't post any details on these, and I ask that you please refrain from doing so as well.

### ODBC connection

1. Open `Administrative Tools` (in the Control Panel).
2. Run the `ODBC Data Sources (32-bit)` tool.
3. Select `Add ...`.
4. Pick the `Microsoft Access Driver (*.mdb)` driver and press `Finish`.
5. Enter the following details:
  * **Data Source Name:** `aurora`
  * **Database:** Press `Select`, navigate to your Aurora directory, and select the `Stevefire.mdb` file.
  * You must also enter the database password on the `Advanced` screen.
6. Press `OK` and ensure your data source shows up in the ODBC listing.
