use v6.*;

unit module Resource::Wrangler;

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

# We make it available but we don't export it
our sub random-sequence {
    state @chars ||= [ |('A'..'Z'), |('a'..'z'), |(^10) ];
    @chars.roll(32).join
}

multi sub load-resource-to-path(
        Str  $resource,
        Str  :$filename = random-sequence,
        IO() :$prefix = $*TMPDIR.add(random-sequence)
--> IO::Path) is cached is export {
    state $call-lock //= Lock.new;
    $call-lock.protect: -> {
        my $resource-handle = %?RESOURCES{$resource}
            // die "Unable to access resource '$resource': $!";

        while $prefix.IO.d {
            $prefix = $*TMPDIR.add(random-sequence);
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

multi sub load-resource-to-path(
        Str  $resource,
        Str  :$filename = $resource,
        IO() :$prefix!,
        Bool :$manual!
--> IO::Path) is cached is export {
    state $call-lock //= Lock.new;
    $call-lock.protect: -> {
        my $resource-handle = %?RESOURCES{$resource}
            // die "Unable to access resource '$resource': $!";

        # Here we try to create the prefix if not already existing
        unless $prefix.d {
            mkdir($prefix) or die "Could not make path '$prefix': $!";
        }

        my $safe-path = $prefix.add($filename);
        if $safe-path.IO.e {
            die "Path '{~$safe-path}' already exists';"
        }

        $safe-path.spurt: $resource-handle.slurp(:bin, :close), :bin, :close;
        $safe-path
    }
}