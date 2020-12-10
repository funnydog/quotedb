# quotedb

This repository has two scripts:

  * **dump.py** a python utility used to scrape irrsi logs and dump
    !quotes and !addquotes into a sqlite3 database;
  * **quotes.pl** a perl script for irssi that uses said database to
    print and add quotes.

## Motivation

The scripts were written to backup the database of quotes without the
help of the user who run the old script because we couldn't reach him
when his script broke down.

It will also serve as an insurance for any future incident.

## Scraping the logs

To scrape the logs and build a database of quotes just run the dump.py
script from your shell:

```sh
$ python dump.py log1 log2 ... logn
```

This command concatenates the logs and creates a sqlite3 database
named database.db.

## Using the database in irssi

The script depends on perl DBI and SQLite3 packages so you need to
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

You should configure two variables:

  * **quotes_database** the full path of the quotes database;
  * **quotes_channels** a space separated list of channels where the
    script looks for commands.

To set them use the irssi command `/set <variable> <value>`.

The commands understood by the script are the following:

  * **!quote** prints a random quote;
  * **!quote \<id\>** prints the quote associated with the given id;
  * **!addquote \<text\>** adds a new quote to the database.

You can unload and therefore disable the script any time using the irssi command `/script unload quotes`.

## License

Public domain

## Disclaimer

Use at your own risk.
