use v6.d;

unit module Resource::Wrangler;

## We add a custom variant of caching so that we don't
## duplicate work at the FS level. Defined at the bottom
## for readability.
multi sub trait_mod:<is>(Routine $r, :$cached!) { ... }

# We make it available but we don't export it
our sub random-sequence {
    state @chars ||= [ |('A'..'Z'), |('a'..'z'), |(^10) ];
    @chars.roll(32).join
}

use nqp;
sub load-resource-to-path(
        Str $resource,
        Str :$filename = random-sequence,                   #| This is the file name
        IO::Path :$prefix = $*TMPDIR.add(random-sequence)   #| This is the prefix in the $*TMPDIR
--> IO::Path) is cached is export {
    state $call-lock //= Lock.new;
    $call-lock.protect: -> {
        my $resource-handle = %?RESOURCES{$resource}
            // die "Unable to access resource '$resource': $!";

        while $prefix.IO.d {
            $prefix = $*TMPDR.add(random-sequence);
        }
        mkdir $prefix;

        my $safe-path = $prefix.add($filename);
        while $safe-path.IO.e {
            $safe-path = $prefix.add(random-sequence);
        }

        $safe-path.spurt: $resource-handle.slurp(:bin, :close), :bin, :close;
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
