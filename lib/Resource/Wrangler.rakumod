use v6.d;

unit module Resource::Wrangler;

## We add a custom variant of caching so that we don't
## duplicate work at the FS level. Defined at the bottom
## for readability.
multi sub trait_mod:<is>(Routine $r, :$cached!) { ... }

use nqp;
my $lock = Lock.new;
sub load-resource-to-path(
        Str $resource,
        IO::Path :$prefix = $*TMPDIR.add(nqp::sha1(~$?DISTRIBUTION))
--> IO::Path) is cached is export {
    $lock.protect: {
        my $resource-handle = %?RESOURCES{$resource}
            // die "Unable to access resource '$resource': $!";

        mkdir $prefix;
        my $safe-path = $prefix.add($resource.comb.grep(/\w/).join);
        $safe-path.spurt: :bin, $resource-handle.slurp(:bin);
        $safe-path
    }
}

## This a direct copy of the version in Rakudo experimental.
## It's not a great general purpose cache but for our purposes
## it is perfect, with the addition of the file existence check.
multi sub trait_mod:<is>(Routine $r, :$cached!) {
    my %cache;
    $r.wrap(-> |c {
        my $key := c.Str;
        %cache.EXISTS-KEY($key) && %cache{$key}.e
            ?? %cache{$key}
            !! (%cache{$key} := callsame);
    });
}
