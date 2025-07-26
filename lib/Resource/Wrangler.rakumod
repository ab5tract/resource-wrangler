use v6.*;

unit role Resource::Wrangler[&RES];

method resources() { RES() }

method random-sequence {
    state @chars ||= [ |('A'..'Z'), |('a'..'z'), |(^10) ];
    @chars.roll(32).join
}

# This candidate gives direct control over the output path
multi method load-resource-to-path(
        Str  $resource,
        Str  :$filename = $resource,
        IO() :$prefix!,
        Bool :$manual!
--> IO::Path) {
    state $call-lock //= Lock.new;
    $call-lock.protect: -> {
        my $resource-maybe = self.resources{$resource}
            // fail "Unable to access resource '$resource': {$! // ""}";

        if (my $resource-handle = $resource-maybe.IO) ~~ Empty {
            return fail "Resource '$resource' is not provided by the distribution";
        }

        # Here we try to create the prefix if not already existing
        unless $prefix.d {
            mkdir($prefix) or fail "Could not make path '$prefix': $!";
        }

        my $safe-path = $prefix.add($filename);
        if $safe-path.IO.e {
            fail "Path '{~$safe-path}' already exists';"
        }

        $safe-path.spurt: $resource-handle.IO.slurp(:bin, :close), :bin, :close;
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
        my $resource-maybe = self.resources{$resource}
            // fail "Unable to access resource '$resource': {$! // ""}";

        if (my $resource-handle = $resource-maybe.IO) ~~ Empty {
            return fail "Resource '$resource' is not provided by the distribution";
        }

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
    }
}

method AT-KEY(Str() $key) {
    self.resources<< $key >>;
}