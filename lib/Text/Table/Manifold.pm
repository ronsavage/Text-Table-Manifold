package Text::Table::Manifold;

use strict;
use warnings;
use warnings qw(FATAL utf8); # Fatalize encoding glitches.
use open     qw(:std :utf8); # Undeclared streams in UTF-8.

use Const::Exporter constants =>
[
	# Values for style().

	as_boxed       => 0, # The default.
	as_github      => 1,

	# Values of alignment().

	justify_left   => 0,
	justify_center => 1,
	justify_right  => 2,

	# Values for handling missing data.

	empty_as_empty => 0,
	empty_as_minus => 1,
	empty_as_text  => 2, # 'empty'.
	empty_as_undef => 3,

	undef_as_empty => 0,
	undef_as_minus => 1,
	undef_as_text  => 2, # 'undef'.
	undef_as_undef => 3,
];

use List::AllUtils 'max';

use Moo;

use Types::Standard qw/Any ArrayRef HashRef Int Str/;

use Unicode::GCString;

has alignment =>
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

has handle_empty =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has handle_undef =>
(
	default  => sub{return 0},
	is       => 'rw',
	isa      => Int,
	required => 0,
);

has headers =>
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
	$s           ||= '';
	my($s_width) = Unicode::GCString -> new($s) -> chars;
	my($left)    = int( ($width - $s_width) / 2);
	my($right)   = $width - $s_width - $left;

	return (' ' x ($left + $padding) ) . $s . (' ' x ($right + $padding) );

} # End of align_center;

# ------------------------------------------------

sub align_left
{
	my($self, $s, $width, $padding) = @_;
	$s           ||= '';
	my($s_width) = Unicode::GCString -> new($s || '') -> chars;
	my($left)    = $width - $s_width;

	return (' ' x ($left + $padding) ) . $s . ' ';

} # End of align_left;

# ------------------------------------------------

sub align_right
{
	my($self, $s, $width, $padding) = @_;
	$s           ||= '';
	my($s_width) = Unicode::GCString -> new($s || '') -> chars;
	my($right)   = $width - $s_width;

	return ' ' . $s . (' ' x ($right + $padding) );

} # End of align_right;

# ------------------------------------------------

sub _clean_data
{
	my($self, $headers, $data) = @_;

	for my $column (0 .. $#$headers)
	{
		$$headers[$column] = defined($$headers[$column]) ? $$headers[$column] : '-';
	}

	my($empty) = $self -> handle_empty;
	my($undef) = $self -> handle_undef;

	my($s);

	for my $row (0 .. $#$data)
	{
		for my $column (0 .. $#{$$data[$row]})
		{
			$s = $$data[$row][$column];
			$s = defined($s)
					? (length($s) == 0) # Unicode::GCString should not be necessary here.
						? ($empty & empty_as_minus)
							? '-'
							: ($empty & empty_as_text)
								? 'empty'
								: ($empty & empty_as_undef)
									? undef
									: $s # No need to check to empty_as_empty here!
						: $s
					: ($undef & undef_as_empty)
							? ''
							: ($undef & undef_as_minus)
								? '-'
								: ($undef & undef_as_text)
									? 'undef'
									: $s; # No need to check for undef_as_undef here!

			$$data[$row][$column] = $s;
		}
	}

} # End of _clean_data.

# ------------------------------------------------

sub gather_statistics
{
	my($self, $headers, $data) = @_;

	$self -> _clean_data($headers, $data);

	my($column_count);

	for my $row (0 .. $#$data)
	{
		$column_count = $#{$$data[$row]};

		die "Error: # of data columns (@{[$column_count]}) in row @{[$row + 1]} != # of header columns (@{[$#$headers]})\n" if ($column_count != $#$headers);
	}

	my(@column);
	my($header_width);
	my(@max_widths);

	for my $column (0 .. $#$headers)
	{
		@column = $$headers[$column];

		for my $row (0 .. $#$data)
		{
			push @column, $$data[$row][$column];
		}

		push @max_widths, max map{Unicode::GCString -> new($_ || '') -> chars} @column;
	}

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

	my($padding)   = $self -> padding;
	my($widths)    = $self -> widths;
	my($separator) = '+' . join('+', map{'-' x ($_ + 2 * $padding)} @$widths) . '+';
	my(@output)    = $separator;

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

	push @output, join('|', map{'-' x $_} @{$self -> widths});

	my($width);

	for my $row (0 .. $#$data)
	{
		push @output, join('|', map{defined($_) ? $_ : ''} @{$$data[$row]});
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
	$table -> align(justify_center);
	$table -> padding(1);
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

=item o alignment => An imported constant

A value for this parameter is optional.

See the L</FAQ> for details.

Default: justify_center.

=item o data => $arrayref of arrayrefs

An arrayref of arrayrefs, each one a line of data.

The # of elements in each row must match the # of elements in the C<headers> arrayref (if any).

See the L</FAQ> for details.

A value for this parameter is optional.

Default: [].

=item o handle_empty => An imported constant

A value for this parameter is optional.

See the L</FAQ> for details.

Default: empty_as_empty. I.e. do not transform.

=item o handle_undef => An imported constant

A value for this parameter is optional.

See the L</FAQ> for details.

Default: undef_as_empty (sic).

=item o padding => $integer

A value for this parameter is optional.

See the L</FAQ> for details.

Default: 0.

=item o style => An imported constant

A value for this parameter is optional.

See the L</FAQ> for details.

Default: as_boxed.

=back

=head1 Methods

=head2 alignment([$alignment])

Here, the [] indicate an optional parameter.

Returns the alignment as a constant (actually an integer).

Alignment controls how many spaces are added to both sides of a cell value.

See the L</FAQ#What are the constants for alignment?>.

=head2 data([$arrayref])

Here, the [] indicate an optional parameter.

Returns the data as an arrayref. Each element in this arrayref is an arrayref of one row of data.

The structure of C<$arrayref>, if provided, must match the description in the line above.

All rows must have the same number of elements.

Use Perl's C<undef> or '' (the empty string) for missing values.

See L</handle_empty([$option])> and L</handle_undef([$option])> for how C<undef> and '' are handled.

=head2 handle_empty([$option])

Here, the [] indicate an optional parameter.

Returns the option speciying how empty cell values ('') are being dealt with, as a constant.

Controls how empty strings in cells are rendered.

See the L</FAQ#What are the constants for missing data?>.

=head2 handle_undef([$option])

Here, the [] indicate an optional parameter.

Returns the option speciying how undef cell values are being dealt with, as a constant.

Controls how undefs in cells are rendered.

See the L</FAQ#What are the constants for missing data?>.

=head2 headers([$arrayref])

Here, the [] indicate an optional parameter.

Returns the headers as an arrayref of strings.

The structure of C<$arrayref>, if provided, must be an arrayref of strings.

=head2 padding([$integer])

Here, the [] indicate an optional parameter.

Returns the padding as a constant (actually an integer).

Padding is the # of spaces on either side of the cell value after it has been aligned.

=head2 style([$style])

Here, the [] indicate an optional parameter.

Returns the style as a constant (actually an integer).

See the L</FAQ#What are the constants for styling?>.

=head1 FAQ

=head2 What are the constants for alignment?

The C<alignment>, if provided, must be one of the following:

=over 4

=item o justify_left => 0

=item o justify_left => 1

=item o justify_right => 2

=back

Note: The integer values are just here for completeness. Use the constants on their left.

=head2 What are the constants for handling missing data?

The C<missing data option>, if provided, must be one of the following:

=over 4

=item o empty_as_empty => 0

Display empty cell values as the empty string.

=item o empty_as_minus => 1

Display empty cell values as '-'.

=item o empty_as_text  => 2

Display empty cell values as 'empty'.

=item o undef_as_empty => 4

Display undef cell values as the empty string.

=item o undef_as_minus => 8

Display undef cell values as '-'.

=item o undef_as_text  => 16

Display undef cell values as 'undef'.

=back

Note: The integer values are just here for completeness. Use the constants on their left.

=head2 What are the constants for styling?

The C<style>, if provided, must be one of the following:

=over 4

=item o as_boxed => 0

=item o as_github => 1

=back

Note: The integer values are just here for completeness. Use the constants on their left.

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
