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

my $database_path;
my %target_channels;
Irssi::settings_add_str("quotes", "quotes_database", "database.db");
Irssi::settings_add_str("quotes", "quotes_channels", "##fdt");

# reload signal
Irssi::signal_add("setup changed", \&reload_settings);
sub reload_settings {
    $database_path = Irssi::settings_get_str("quotes_database");
    %target_channels = map { $_ => 1 } split / /, Irssi::settings_get_str("quotes_channels");
}
$database_path = Irssi::settings_get_str("quotes_database");
%target_channels = map { $_ => 1 } split / /, Irssi::settings_get_str("quotes_channels");

# incoming messages from other clients
Irssi::signal_add_last("message public", \&autoanswer);
sub autoanswer
{
    my ($server, $msg, $nick, $address, $target) = @_;

    return if !exists($target_channels{$target});

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

# outgoing messages from our client
Irssi::signal_add_last("send command", \&outgoing);
sub outgoing
{
    my ($msg, $server, $channel) = @_;

    return if $channel->{type} ne 'CHANNEL';
    autoanswer($server, $msg, "", "", $channel->{name});
}

# unregister the signals
sub UNLOAD
{
    Irssi::signal_remove("send command", \&outgoing);
    Irssi::signal_remove("message public", \&autoanswer);
    Irssi::signal_remove("setup changed", \&reload_settings);
}
