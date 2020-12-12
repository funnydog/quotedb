use strict;
use vars qw($VERSION %IRSSI);
use Irssi;
use DBI;

$VERSION = "0.01";
%IRSSI = (
    authors => "funnydog",
    contact => "funnydog\@users.noreply.github.com",
    name => "quotes",
    description => "quotes",
    license => "Public Domain",
    );

# global variables
my $last_addquote;

# configuration variables
my $database_path;
my %target_channels;
my $lurking_mode;
my $lurking_nickname;
Irssi::settings_add_str("quotes", "quotes_database", "database.db");
Irssi::settings_add_str("quotes", "quotes_channels", "##fdt");
Irssi::settings_add_bool("quotes", "quotes_lurking_mode", 0);
Irssi::settings_add_str("quotes", "quotes_lurking_nickname", "");

# load the configuration variables
sub load_settings {
    $database_path = Irssi::settings_get_str("quotes_database");
    %target_channels = map { $_ => 1 } split / /, Irssi::settings_get_str("quotes_channels");
    $lurking_nickname = Irssi::settings_get_str("quotes_lurking_nickname");
    my $new_mode = Irssi::settings_get_bool("quotes_lurking_mode");
    if ($lurking_nickname eq "") {
	$new_mode = 0;
    } else {
	$new_mode = Irssi::settings_get_bool("quotes_lurking_mode");
    }
    if ($new_mode != $lurking_mode) {
	$lurking_mode = $new_mode;
	$last_addquote = "";
    }
}
Irssi::signal_add("setup changed", \&load_settings);
load_settings();

# incoming messages from other clients
sub incoming
{
    my ($server, $msg, $nick, $address, $target) = @_;

    return if !exists($target_channels{$target});

    if ($lurking_mode == 0)
    {
	# normal mode with all the commands
	if ($msg =~ m/^!quote (\d+)$/)
	{
	    my $sql = q{SELECT id, quote FROM quotes WHERE id = ?;};
	    if (my $dbh = DBI->connect("dbi:SQLite:dbname=$database_path", "", "")) {
		if (my $stmt = $dbh->prepare($sql)) {
		    if ($stmt->execute($1)) {
			if (my @row = $stmt->fetchrow_array) {
			    $server->command("MSG $target [$row[0]] $row[1]");
			} else {
			    $server->command("MSG $target [$1]");
			}
		    }
		}
		$dbh->disconnect;
	    }
	}
	elsif ($msg =~ m/^!quote$/)
	{
	    my $sql = q{SELECT id, quote FROM quotes ORDER BY RANDOM() LIMIT 1;};
	    if (my $dbh = DBI->connect("dbi:SQLite:dbname=$database_path", "", "")) {
		if (my $stmt = $dbh->prepare($sql)) {
		    if ($stmt->execute()) {
			while (my @row = $stmt->fetchrow_array) {
			    $server->command("MSG $target [$row[0]] $row[1]");
			}
		    }
		}
		$dbh->disconnect;
	    }
	}
	elsif ($msg =~ m/^!addquote (.*)$/)
	{
	    my $sql = q{INSERT INTO quotes(quote) VALUES(?);};
	    if (my $dbh = DBI->connect("dbi:SQLite:dbname=$database_path", "", "")) {
		if (my $stmt = $dbh->prepare($sql)) {
		    if ($stmt && $stmt->execute($1)) {
			$server->command("MSG $target Quote added!");
		    } else {
			$server->command("MSG $target addquote failed :(");
		    }
		}
		$dbh->disconnect;
	    }
	}
    }
    else
    {
	# in lurking mode we look for two patterns: !addquote and Quote added!
	if ($msg =~ m/^!addquote (.*)$/)
	{
	    $last_addquote = $1;
	}
	elsif ($nick eq $lurking_nickname && $msg =~ m/^Quote added!$/)
	{
	    my $sql = q{INSERT INTO quotes(quote) VALUES(?);};
	    if (my $dbh = DBI->connect("dbi:SQLite:dbname=$database_path", "", "")) {
		if (my $stmt = $dbh->prepare($sql)) {
		    if ($stmt && $stmt->execute($last_addquote)) {
			Irssi::print("New quote added for $target")
		    } else {
			Irssi::print("Addquote failed for $target");
		    }
		}
		$dbh->disconnect;
	    }
	    $last_addquote = "";
	}
    }
}
Irssi::signal_add_last("message public", \&incoming);

# outgoing messages from our client
sub outgoing
{
    Irssi::timeout_add_once(
	100, sub {
	    my $a = shift;
	    incoming($a->[0], $a->[1], "", "", $a->[2]);
	}, \@_);
}
Irssi::signal_add_last("message own_public", \&outgoing);

# unregister the signals
sub UNLOAD
{
    Irssi::signal_remove("message own_public", \&outgoing);
    Irssi::signal_remove("message public", \&incoming);
    Irssi::signal_remove("setup changed", \&load_settings);
}
