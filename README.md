# Resource::Wrangler

This module provides a very simple wrapper to handle the
scenario where you need to have a path that points to a
resource bundled in your Raku distribution.

The answer is really quite simple and easy enough to
hand-roll on one's own.

However, the plan is to cook up some good heuristics for
safely generating files that won't clash in terms of names.

That's the primary edge case I can think of so far, but
nevertheless it's nice not to have to write this transfer code
over and over again.

Release under the Artistic License 2.0
