#!/usr/bin/env python3

import re
import sqlite3
import sys

quote_pattern = re.compile(r"\d{2}:\d{2} <@sarrusofono> \[(\d+)] (.*)")
addquote_pattern = re.compile(r"\d{2}:\d{2} <[@ ]\w+> !addquote (.*)")
confirm_pattern = re.compile(r"\d{2}:\d{2} <@sarrusofono> Quote added!")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: {} <filename1> [<filename2> ... <filenameN>]".format(sys.argv[0]), file=sys.stderr)
        exit(1)


    # read the quotes and the addquotes
    quotes = []
    addquotes = []
    pending_addquote = None
    for filename in sys.argv[1:]:
        try:
            with open(filename, "rt", errors="surrogateescape") as f:
                for line in f:
                    m = quote_pattern.match(line)
                    if m and m[2]:
                        num = int(m[1])
                        # sanitize to take care of sarrubugs
                        if num < 100000:
                            quotes.append((num, m[2]))

                    m = addquote_pattern.match(line)
                    if m:
                        pending_addquote = m[1]

                    m = confirm_pattern.match(line)
                    if m and pending_addquote:
                        addquotes.append(pending_addquote)
                        pending_addquote = None
        except FileNotFoundError as f:
            print("Cannot open {}".format(filename), file=sys.stderr)

    # try to assign a number to each addquote
    quotemap = {s: n for n, s in quotes}
    start = 0
    for aq in addquotes:
        num = quotemap.get(aq)
        if num:
            start = num + 1
            continue

        quotes.append((start, aq))
        start += 1

    # filter duplicates and print missing quotes
    lst = []
    quotes.sort(key=lambda x: x[0])
    counter = 0
    for tup in quotes:
        while counter < tup[0]:
            print("missing {}".format(counter))
            counter +=1

        # skip duplicates
        if counter == tup[0]:
            counter += 1
            lst.append(tup)

    try:
        conn = sqlite3.connect("database.db")
        model = """
CREATE TABLE IF NOT EXISTS quotes (
        id integer PRIMARY KEY,
        quote text NOT NULL
);"""
        cur = conn.cursor()
        cur.execute(model)
        truncate = """DELETE FROM quotes;"""
        cur.execute(truncate)
        insert = """INSERT INTO quotes(id, quote) VALUES(?, ?);"""
        for keyval in lst:
            cur.execute(insert, keyval)

        conn.commit()
    except sqlite3.Error as e:
        print(e)
    finally:
        if conn:
            conn.close()
