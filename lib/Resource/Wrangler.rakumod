use v6.*;

unit role Resource::Wrangler[&RES];

method resources() { RES() }

## This is to limit our footprint if the same file is accessed
## many times.
has %!cache;

# We make it available but we don't export it
method random-sequence {
    state @chars ||= [ |('A'..'Z'), |('a'..'z'), |(^10) ];
    @chars.roll(32).join
}


multi method load-resource-to-path(
        Str  $resource,
        Str  :$filename = $resource,
        IO() :$prefix!,
        Bool :$manual!
--> IO::Path) {
    state $call-lock //= Lock.new;
    $call-lock.protect: -> {
        my $resource-handle = self.resources{$resource}
            // fail "Unable to access resource '$resource': {$! // ""}";

        # Here we try to create the prefix if not already existing
        unless $prefix.d {
            mkdir($prefix) or fail "Could not make path '$prefix': $!";
        }

        my $safe-path = $prefix.add($filename);
        if $safe-path.IO.e {
            fail "Path '{~$safe-path}' already exists';"
        }

        $safe-path.spurt: $resource-handle.slurp(:bin, :close), :bin, :close;
        $safe-path
    }
}

multi method load-resource-to-path(
        Str  $resource,
        Str  :$filename = self.random-sequence,
        IO() :$prefix = $*TMPDIR.add(self.random-sequence)
--> IO::Path) {
    state $call-lock //= Lock.new;
    $call-lock.protect: -> {
        return %!cache{$resource} if %!cache{$resource}:exists;

        my $resource-handle = self.resources{$resource}
            // fail "Unable to access resource '$resource': {$! // ""}";

        while $prefix.IO.d {
            $prefix = $*TMPDIR.add(self.random-sequence);
        }
        mkdir $prefix;

        my $safe-path = $prefix.add($filename);
        while $safe-path.IO.e {
            $safe-path = $prefix.add(self.random-sequence);
        }

        $safe-path.spurt: $resource-handle.slurp(:bin, :close), :bin, :close;
        $safe-path
        %!cache{$resource} = $safe-path
    }
}
