
org is just something I wrote after getting sick of renaming lots of files
in the same way. It is not supposed to do everything for you - rather it is
there to try and save time at the more menial tasks when organisating a
large number of directories full of files.

The basic workflow:

1. Create a directory with the name of the show.
2. Go into that directory
3. `org import /IncomingDir/[crapsubs]_Some_show_-_01_[DEADBEEF].mkv ...`

org will look in the current directory. If it sees shows numbered 01 to 11,
it will assume that you're trying to import 12 and look in the filename to
make sure there is a 12. This is to try and catch forgetting to download one
episode of a series, but it could bite you if you're not careful when a show
has a number in the title.

It will also check the CRC, if present in the filename, compute an SHA-1
which goes into a file in the same directory and move the file into the
directory.

Multiple files work but have to be specified in order at present. I'm doing
this mostly on Mac OS X where the they get sorted for me when I wildcard.
The code absolutely does not parse apart the filename and understand which
bit is the episode number, but that could be a potential future improvement
if it can be shown to work for all released filename formats.

It doesn't handle episode 00 at all yet. If one is present, you will be
forced to use the -n parameter to manually tell it what number to start at.
Likewise, it doesn't like non-numeric episode tags yet (like NCED, SP or
whatever.) This is all fixable.

