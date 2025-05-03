use v6.d;

unit module Resource::Wrangler;


sub load-resource-to-path(Str $resource, :$prefix = "/tmp/" --> Str) is export {
    my $fh = %?RESOURCES{$resource}
        // die "Unable to access resource '$resource'";
    my $safe-path = $prefix ~ $resource.comb.grep(/\w/).join;
    $safe-path.IO.spurt: :bin, $fh.slurp(:bin);
    $safe-path
}