package Text::Table::Manifold;

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.
use open     qw(:std :utf8); # Undeclared streams in UTF-8.

use Const::Exporter constants =>
[
	# Values for style.

	as_boxed       =>  0, # The default.
	as_github      =>  1,

	# Values of centering.

	justify_left   =>  0,
	justify_center =>  1,
	justify_right  =>  2,

	# Values for handling missing data.

	undef_as_empty =>  0,
	undef_as_minus =>  1,
	undef_as_text  =>  2, # 'undef'.
	empty_as_empty =>  4,
	empty_as_minus =>  8,
	empty_as_text  => 16, # 'empty'.
];

use List::AllUtils 'max';

use Moo;

use Types::Standard qw/Any ArrayRef HashRef Int Str/;

use Unicode::GCString;

has align =>
(
	default  => sub{return justify_center},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has data =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

has escapes =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

has headers =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

has header_widths =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

has options =>
(
	default  => sub{return {} },
	is       => 'rw',
	isa      => HashRef,
	required => 0,
);

has padding =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has style =>
(
	default  => sub{return as_boxed},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has widths =>
(
	default  => sub{return []},
	is       => 'rw',
	isa      => ArrayRef,
	required => 0,
);

our $VERSION = '1.00';

# ------------------------------------------------

sub align_center
{
	my($self, $s, $width, $padding) = @_;
	my($s_width) = Unicode::GCString -> new($s) -> chars;
	my($left)    = int( ($width - $s_width) / 2);
	my($right)   = $width - $s_width - $left;

	return (' ' x ($left + $padding) ) . $s . (' ' x ($right + $padding) );

} # End of align_center;

# ------------------------------------------------

sub align_left
{
	my($self, $s, $width, $padding) = @_;
	my($s_width) = Unicode::GCString -> new($s) -> chars;
	my($left)    = $width - $s_width;

	return (' ' x ($left + $padding) ) . $s . ' ';

} # End of align_left;

# ------------------------------------------------

sub align_right
{
	my($self, $s, $width, $padding) = @_;
	my($s_width) = Unicode::GCString -> new($s) -> chars;
	my($right)   = $width - $s_width;

	return ' ' . $s . (' ' x ($right + $padding) );

} # End of align_right;

# ------------------------------------------------

sub gather_statistics
{
	my($self, $headers, $data) = @_;

	my($column_count);

	for my $row (0 .. $#$data)
	{
		$column_count = $#{$$data[$row]};

		die "Error: # of data columns (@{[$column_count]}) != # of header columns (@{[$#$headers]})\n" if ($column_count != $#$headers);
	}

	my(@header_widths);
	my(@max_widths);

	for my $column (0 .. $#$headers)
	{
		my(@column);

		for my $row (0 .. $#$data)
		{
			push @column, $$data[$row][$column];
		}

		push @header_widths, Unicode::GCString -> new($$headers[$column]) -> chars;
		push @max_widths, max $header_widths[$#header_widths], map{Unicode::GCString -> new($_) -> chars} @column;
	}

	$self -> header_widths([@header_widths]);
	$self -> widths(\@max_widths);

} # End of gather_statistics.

# ------------------------------------------------

sub render
{
	my($self) = @_;

	my($output);

	if ($self -> style == as_boxed)
	{
		$output = $self -> render_as_boxed;
	}
	elsif ($self -> style == as_github)
	{
		$output = $self -> render_as_github;
	}
	else
	{
		die 'Error: Style not implemented: ' . $self -> style . "\n";
	}

	return $output;

} # End of render.

# ------------------------------------------------

sub render_as_boxed
{
	my($self)    = @_;
	my($headers) = $self -> headers;
	my($data)    = $self -> data;

	$self -> gather_statistics($headers, $data);

	my($widths)    = $self -> widths;
	my($separator) = '+' . join('+', map{'-' x ($_ + 2)} @$widths) . '+';
	my(@output)    = $separator;
	my($padding)   = $self -> padding;

	my(@s);

	for my $column (0 .. $#$widths)
	{
		push @s, $self -> align_center($$headers[$column], $$widths[$column], $padding);
	}

	push @output, '|' . join('|', @s) . '|';
	push @output, $separator;

	for my $row (0 .. $#$data)
	{
		@s = ();

		for my $column (0 .. $#$widths)
		{
			push @s, $self -> align_center($$data[$row][$column], $$widths[$column], $padding);
		}

		push @output, '|' . join('|', @s) . '|';
	}

	push @output, $separator;

	return [@output];

} # End of render_as_boxed.

# ------------------------------------------------

sub render_as_github
{
	my($self)    = @_;
	my($headers) = $self -> headers;
	my($data)    = $self -> data;

	$self -> gather_statistics($headers, $data);

	my(@output) = join('|', @$headers);

	push @output, join('|', map{'-' x $_} @{$self -> header_widths});

	my($width);

	for my $row (0 .. $#$data)
	{
		push @output, join('|', @{$$data[$row]});
	}

	return [@output];

} # End of render_as_github.

# ------------------------------------------------

1;

=pod

=head1 NAME

C<Text::Table::Manifold> - Render tables in manifold styles

=head1 Synopsis

This is scripts/synopsis.pl:

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
	]);

	$table -> style(as_boxed);

	print "Style: as_boxed: \n";
	print join("\n", @{$table -> render}), "\n";
	print "\n";

	$table -> style(as_github);

	print "Style: as_github: \n";
	print join("\n", @{$table -> render}), "\n";
	print "\n";

This is the output of synopsis.pl:

	Style: as_boxed:
	+-------------+--------------+----------+-------------+----------------+
	|    Name     |     Type     |   Null   |     Key     | Auto increment |
	+-------------+--------------+----------+-------------+----------------+
	|     id      |   int(11)    | not null | primary key | auto_increment |
	| description | varchar(255) | not null |             |                |
	|    name     | varchar(255) | not null |             |                |
	| upper_name  | varchar(255) | not null |             |                |
	+-------------+--------------+----------+-------------+----------------+

	Style: as_github:
	Name|Type|Null|Key|Auto increment
	----|----|----|---|--------------
	id|int(11)|not null|primary key|auto_increment
	description|varchar(255)|not null||
	name|varchar(255)|not null||
	upper_name|varchar(255)|not null||

=head1 Description

Renders your data as tables of various types:

=over 4

=item o as_boxed

All headers and table data are surrounded by ASCII characters.

=item o as_github

As github-flavoured markdown.

=back

See data/*.log for output corresponding to scripts/*.pl.

See the L</FAQ> for various topics, including:

=over 4

=item o UFT8 handling

See scripts/utf8.pl and data/utf8.log.

=back

=head1 Distributions

This module is available as a Unix-style distro (*.tgz).

See L<http://savage.net.au/Perl-modules/html/installing-a-module.html>
for help on unpacking and installing distros.

=head1 Installation

Install L<Text::Table::Manifold> as you would any C<Perl> module:

Run:

	cpanm Text::Table::Manifold

or run:

	sudo cpan Text::Table::Manifold

or unpack the distro, and then either:

	perl Build.PL
	./Build
	./Build test
	sudo ./Build install

or:

	perl Makefile.PL
	make (or dmake or nmake)
	make test
	make install

=head1 Constructor and Initialization

C<new()> is called as C<< my($parser) = Text::Table::Manifold -> new(k1 => v1, k2 => v2, ...) >>.

It returns a new object of type C<Text::Table::Manifold>.

Key-value pairs accepted in the parameter list (see corresponding methods for details
[e.g. L</data([$arrayref])>]):

=over 4

=item o data => $arrayref of arrayrefs

An arrayref of arrayrefs, each one a line of data.

The # of elements in each row must match the # of elements in the C<headers> arrayref (if any).

See the L</FAQ> for details.

A value for this option is optional.

Default: [].

=item o style => An imported constant

A value for this option is optional.

Default: as_boxed.

=back

=head1 Methods

=head2 data([$arrayref])

Here, the [] indicate an optional parameter.

Returns the data as an arrayref. Each element in this arrayref is an arrayref of one row of data.

The structure of C<$arrayref>, if provided, must match the description in the line above.

All rows must have the same number of elements.

Use Perl's C<undef> or '' (the empty string) for missing values.

See L</missing_data([$option])> for how C<undef> and '' are handled.

=head2 headers([$arrayref])

Here, the [] indicate an optional parameter.

Returns the headers as an arrayref of strings.

The structure of C<$arrayref>, if provided, must be an arrayref of strings.

=head2 missing_data([$option])

Here, the [] indicate an optional parameter.

Returns the missing data option.

=head2 style([$style])

Here, the [] indicate an optional parameter.

Returns the style as a constant (actually an integer).

The C<$style>, if provided, must be one of the following:

=over 4

=item o as_boxed => 0

=item o as_github => 1

=back


=head1 FAQ

=head2 How do I run author tests?

This runs both standard and author tests:

	shell> perl Build.PL; ./Build; ./Build authortest

=head1 TODO

=over 4

=item o This

=item o That

=back

=head1 See Also

L<Any::Renderer>

L<Data::Formatter::Text>

L<Data::Tab>

L<Data::Table>

L<Data::Tabulate>

L<Gapp>

L<HTML::Table>

L<HTML::Tabulate>

L<Text::ASCIITable>

L<Text::CSV>

L<Text::Table>

L<Text::TabularDisplay>

L<Text::Tabulate>

L<Tie::Array::CSV>

=head1 Machine-Readable Change Log

The file Changes was converted into Changelog.ini by L<Module::Metadata::Changes>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/Text-Table-Manifold>

=head1 Support

Email the author, or log a bug on RT:

L<https://rt.cpan.org/Public/Dist/Display.html?Name=Text::Table::Manifold>.

=head1 Author

L<Text::Table::Manifold> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2015.

Marpa's homepage: L<http://savage.net.au/Marpa.html>.

My homepage: L<http://savage.net.au/>.

=head1 Copyright

Australian copyright (c) 2014, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License 2.0, a copy of which is available at:
	http://opensource.org/licenses/alphabetical.

=cut
