#!/usr/bin/env perl

use strict;
use warnings;

use Text::Table::Manifold ':constants';

# -----------

my($table) = Text::Table::Manifold -> new;

$table -> headers(['Name', 'Type', 'Null', 'Key', 'Auto increment']);
$table -> data(
[
	['id', 'int(11)', 'not null', 'primary key', 'auto_increment'],
	['description', 'varchar(255)', 'not null', '', ''],
	['name', 'varchar(255)', 'not null', '', ''],
	['upper_name', 'varchar(255)', 'not null', '', ''],
	[undef, '', '', '', ''],
]);
$table -> footers(['One', 'Two', 'Three', 'Four', 'Five']);
$table -> alignment(justify_center);
$table -> empty(empty_as_minus);
$table -> undef(undef_as_text);
$table -> padding(1);
$table -> style(as_boxed);

print "Style: as_boxed: \n";
print join("\n", @{$table -> render}), "\n";
print "\n";

$table -> style(as_github);

print "Style: as_github: \n";
print join("\n", @{$table -> render}), "\n";
print "\n";

$table -> style(as_html);

print "Style: as_html: \n";
print join("\n", @{$table -> render}), "\n";
print "\n";
