# quotedb

This repository has two scripts:

  * **dump.py** a python utility used to scrape irrsi logs and dump
    !quotes and !addquotes into a sqlite3 database;
  * **quotes.pl** a perl script for irssi that uses said database to
    print and add quotes.

## Motivation

The scripts were written to backup the database of quotes without the
help of the user who ran the old script, since we couldn't reach him
when his script broke down.

It will also serve as an insurance for any future incident.

## Scraping the logs

To scrape the logs and build a database of quotes just run the `dump.py`
script from your shell:

```sh
$ python dump.py log1 log2 ... logn
```

This command concatenates the logs and creates a sqlite3 database
named database.db.

## Using the database in irssi

The `quotes.pl` script depends on perl DBI and SQLite3 packages so you need to
install them before using it.

For Debian the needed packages are `libdbi-perl` and
`libdbd-sqlite3-perl`:

```sh
$ sudo apt install libdbi-perl libdbd-sqlite3-perl
```

For the other distributions please install the analogous packages or
use CPAN.

After installing the dependencies put `quotes.pl` in
`$HOME/.irssi/scripts` and load it with `/script load quotes`.

There are four variables to configure:

  * **quotes_database** the full path of the quotes database;
  * **quotes_channels** a space separated list of channels where the
    script looks for commands;
  * **quotes_lurking_mode** when set to ON the script won't output
    anything to the channels and will only listen for !addquote and
    Quote added! patterns;
  * **quotes_lurking_nickname** the nickname who responds to the
    !addquote command.

To set them use the irssi command `/set <variable> <value>`. Once set
you can save the whole configuration with the command
`/save`. This way the variables will survive irssi restarts.

When `lurking_mode` is OFF (default) the commands understood by the
script are the following:

  * **!quote** prints a random quote;
  * **!quote \<id\>** prints the quote associated with the given id;
  * **!addquote \<text\>** adds a new quote to the database.

When `lurking_mode` is ON the script will keep the database
synchronized with the one managed by `lurking_nickname`: it intercepts
the **!addquote** command and when `lurking_nickname` replies with
**Quote added!** it will add the the quote into the database. No
output is echoed on the channel and the results of the insertion are
printed on the screen instead.

You can unload and therefore disable the script any time using the
irssi command `/script unload quotes`.

If you'd like to autoload the script when irssi starts you can use
`scriptassist`: `/run scriptassist` (only once per session) and then
`/script autorun quotes` (this command creates a symbolic link to the
script in `$HOME/.irssi/scripts/autorun`).

## License

Public domain

## Disclaimer

Use at your own risk.
