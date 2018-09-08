package Finance::SE::IDX::Any;

# DATE
# VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;
use Log::ger;

use Finance::SE::IDX ();

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       list_idx_boards
                       list_idx_firms
                       list_idx_sectors
               );

our %SPEC = %Finance::SE::IDX::SPEC;

our $FALLBACK_PERIOD = 4*3600;

my $warned_static_age;
my $last_fail_time;

sub _doit {
    my $which = shift;

    my $now = time();
    unless ($last_fail_time &&
                ($now-$last_fail_time) <= $FALLBACK_PERIOD) {
        my $res = &{"Finance::SE::IDX::$which"}(@_);
        if ($res->[0] == 200) {
            undef $last_fail_time;
            return $res;
        } else {
            log_warn "Finance::SE::IDX::$which() failed, falling back to ".
                "Finance::SE::IDX::Static version ...";
            $last_fail_time = $now;
        }
    }
    require Finance::SE::IDX::Static;
    unless ($warned_static_age) {
        my $mtime = ${"Finance::SE::IDX::Static::data_mtime"};
        if (($now - $mtime) > 2*30*86400) {
            log_warn "Finance::SE::IDX::Static version is older than 60 days, ".
                "data might be out of date, please consider updating to a ".
                "new version of Finance::SE::IDX::Static";
        }
        $warned_static_age++;
    }
    return &{"Finance::SE::IDX::Static::$which"}(@_);
}

sub list_idx_boards  { _doit("list_idx_boards", @_) }

sub list_idx_firms   { _doit("list_idx_firms", @_) }

sub list_idx_sectors { _doit("list_idx_sectors", @_) }

1;
# ABSTRACT:

=head1 SYNOPSIS

Use like you would use L<Finance::SE::IDX>.


=head1 DESCRIPTION

This module provides the same functions as L<Finance::SE::IDX>, e.g.
C<list_idx_firms> and will call the Finance::SE::IDX version but will fallback
for a while (default: 4 hours) to the L<Finance::SE::IDX::Static> version when
the functions fail.


=head1 VARIABLES

=head2 $FALLBACK_PERIOD

Specify, in seconds, how long should the fallback (static) version be used after
a failure. Default is 4*3600 (4 hours).


=head1 SEE ALSO

L<Finance::SE::IDX>

L<Finance::SE::IDX::Static>

=cut
