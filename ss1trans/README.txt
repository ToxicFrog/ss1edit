# ss1trans -- a simple tool for modifying SS1 text resources.

This is a tool that can unpack CYBSTRNG.RES (or any other text resource file
containing the same chunks, including the french and german RES files) into
a bunch of text files you can edit with your text editor of choice, and then
pack them back into a RES file when you're done.

It's intended for translators and other people who need to make edits to large
amounts of SS1 text, as opposed to people who just want to patch one or two
messages, but it's useful for anything that requires editing *STRNG.RES.

At present, it doesn't support all text resources, but object and texture names,
papers, emails, vmails audio logs, and Lansing's hidden c/space messages are
all supported. Support for other resources is in the works.

## Usage

Unpack the program wherever.

To unpack a res file, just drag and drop it onto ss1trans.exe. A directory will
be created next to the res file, with the same name ending in .D rather than
.RES. All the text files are inside that directory.

Edit them as you see fit. You may also want to use some kind of version control.
The different files come with explanatory comments at the top detailing what
kind of data is contained therein and how to edit it.

`trnstrng.txt` is special; it's the control file for the packing process. It
controls what RES file is loaded as the original, which patches are applied, and
what the name of the output file is. If you want to change filenames, this is
where you do it.

When you're done, just drag the .D directory onto ss1trans.exe and it'll
generate a new RES file for you. Note that if the file already exists, it will
be overwritten without confirmation.
