use v6.d;

unit module Resource::Wrangler;

use nqp;
sub load-resource-to-path(
    Str $resource,
    :$prefix = "/tmp/{nqp::sha1(~$?DISTRIBUTION)}"--> IO::Path
) is export {
    my $resource-handle = %?RESOURCES{$resource}
        // die "Unable to access resource '$resource': $!";

    mkdir $prefix;
    my $safe-path = $prefix.IO.add($resource.comb.grep(/\w/).join);
    $safe-path.spurt: :bin, $resource-handle.slurp(:bin);
    $safe-path
}