# Resource::Wrangler

This module provides a very simple wrapper to handle the
scenario where you need to have a path that points to a
resource bundled in your Raku distribution.

## Usage

You are creating a new Raku module and you want to be able
to provide users access to a resource that you ship in your 
distribution via a file handle.

Normally this requires manual juggling of `%?RESOURCES` to
get the contents of a file and to then write them to a 
location manually.

With `Resource::Wrangler`, it becomes simple to get either
a randomized path location (for a bit of security, where
it matters) or to copy the resource to a specific path.

The major "trick" that is required for it to work, however,
is that your consuming module needs to pass it's own resource
map as a role parameter to `Resource::Wrangler`.

Most often it will look like this:

    my $wrangler = Resource::Wrangler[{ %?RESOURCES }].new

But you can also create your own map (`Str` => `IO`). In fact,
that's how the tests are implemented.

### On dependency injection

`Resource::Wrangler` can be integrated into a project in a 
number of ways, but the most flexible is to "inject" a
`Resource::Wrangler` object as a constructor argument on
the consuming class.

    class Resourceful {
        has $.resources handles <AT-KEY>
            = Resource::Wrangler[{ %?RESOURCES }].new;
    }


By setting the default initializer to use the current
CompUnit's `%?RESOURCES`, we ensure that the default behavior
will Do What I Mean.

However, when writing tests, you can inject a mocked hash:

    use Test;
    use Resourceful;
    
    my %resources = test => "/tmp/test".IO;
    my $resourceful = Resourceful.new:
        :resources(Resource::Wrangler[-> { %resources }].new);
    
    is "/tmp/test".IO, $resourceful<< $name >>, "injected!";

Note that when using prepared hashes this way, it is necessary
to include a signature to the block so that it isn't seen
as a hash initializer by the Raku grammar.

Doing this inline

### Randomized Path Location

The following code will copy the resource from the location
deep within `%?RESOURCES` to a location based on randomized
path components (under `$*TMPDIR`):

    use Resource::Wrangler;
    constant WR = Resource::Wrangler[{ %?RESOURCES }].new;
    my IO::Path $path = WR.load-resource-to-path("resource-name.png");
    say $path.Str
    # >>> "/tmp/j0gbX6hUQjh20Qqf5BxAyVsanRLkDMVE/KAHsTx9m7pkE0jhMbdBdj63bp1Rjd7PI"

Note that `filename` and `prefix` are both available.
By default they are set to a random sequence but they can
be manually stated.

However, note that if a `prefix` is passed that already exists as 
a path, it will randomly add additional sub-paths from random 
sequences until a non-existing `prefix` path is accomplished.

For direct control over the exact resource destination, see
below.

### Manual Path Location

If you prefer loading resources to persistent (outside
of `$*TMPDIR`, etc) or predictable / human-readable paths, then 
you can provide your own value for the `filename`
(it defaults to the resource name if unspecified).

The `prefix` and `manual` named parameters are required:

    use Resource::Wrangler;
    my $wr = Resource::Wrangler[{ %?RESOURCES }].new;
    my IO::Path $path = $wr.load-resource-to-path(
                                "resource-name.png",
                                filename => "output-name.png",
                                prefix => $*HOME.add("known/safe/path"),
                                :manual);
    say $path.Str;
    # >>> "/home/user1/known/safe/path/output-name.png"

`prefix` can be any value that coerces to `IO()`, so the above
could have been written:

    prefix => "/home/user1/known/safe/path"

### Security Notes

There will always be tension between security and usability.

It is possible that attackers can exploit any deterministic resource
naming scheme to allow arbitrary loading of malicious stuffs.

That said, software needs to remain usable to be of any benefit to
actual users, not to mention the developer experience trying to
provide software to those users.

This library uses path randomization under OS-provided temporary
directories to provide some obfuscation. Highly motivated attackers
have compromised much more complex systems than this.

That said, the original point about the balance between security
and usability still stands. If you have any concerns or have spotted
a glaring hole in the implementation of this module, please file
a ticket on the GitHub repository and it will be resolved
as soon as possible.

tl;dr - Use responsibly and Don't Panic.

## License

Release under the Artistic License 2.0
