# kramdown-rfc2629

[kramdown][] is a [markdown][] parser by Thomas Leitner, which has a
number of backends for generating HTML, Latex, and markdown again.

**kramdown-rfc2629** is an additional backend to that: It allows the
generation of [RFC 2629][] compliant XML markup (also known as XML2RFC
markup).

Who would care?  Anybody who is writing Internet-Drafts and RFCs in
the [IETF][] and prefers (or has co-authors who prefer) to do part of
their work in markdown.

# Usage

Start by installing the kramdown-rfc2629 gem (this requires kramdown
version 0.13.x, but has also been tested with version 0.11.0 and 0.12.0):

    sudo gem install kramdown-rfc2629

The guts of kramdown-rfc2629 are in one Ruby file,
`lib/kramdown-rfc2629.rb` --- this melds nicely into the extension
structure provided by kramdown.  `bin/kramdown-rfc2629` started out as
a simple command-line program showing how to use this, but can now do
much more (see below).

To use kramdown-rfc2629, you'll need a Ruby 1.9 that can be found
under the name "ruby1.9", the command "wget" (if you want to use the
offline feature), and maybe XML2RFC if you want to see the fruits of
your work.

    kramdown-rfc2629 mydraft.mkd >mydraft.xml
    xml2rfc mydraft.xml

# Examples

`stupid.mkd` is a markdown version of an actual Internet-Draft (for a
protocol called [STuPiD][] \[sic!]).  This demonstrates some, but not
all features of kramdown-rfc2629.  Since markdown/kramdown does not
cater for all the structure of an RFC 2629 style document, some of the
markup is in XML, and the example switches between XML and markdown
using kramdown's `{::nomarkdown}` and `{:/nomarkdown}` (this is ugly,
but works well enough).  `stupid.xml` and `stupid.txt` show what
kramdown-rfc2629 and xml2rfc make out of this.

`stupid-s.mkd` is the same document in the new sectionized format
supported by kramdown-rfc2629.  The document metadata are in a short
piece of YAML at the start, and from there, `abstract`, `middle`,
references (`normative` and `informative`) and `back` are sections
delimited in the markdown file.  See the example for how this works.
Much less scary, and no `{:/nomarkdown}` etc. is needed any more.
Similarly, `stupid-s.xml` and `stupid-s.txt` show what
kramdown-rfc2629 and xml2rfc make out of this.

`draft-ietf-core-block-xx.mkd` is a real-world example of a current
Internet-Draft done this way.  For RFC and Internet-Draft references,
it uses document prolog entities instead of caching the references in
the XML (this is easier to handle when collaborating with XML-only
co-authors).  See the `bibxml` metadata.

# Risks and Side-Effects

The code is not very polished, but it has been successfully used for a
number of non-trivial Internet-Drafts.  You probably still need to
skim [RFC 2629][] if you want to write an Internet-Draft, but you
don't really need to understand XML very much.  Knowing the basics of
YAML helps with the metadata (but you'll understand it from the
examples.)

# Related Work

Moving from XML to Markdown for RFC writing apparently is a
no-brainer, so I'm not the only one who has written code for this.

[Miek Gieben][] has done a [similar thing][pandoc2rfc] employing
pandoc/asciidoc.  He uses multiple input files instead of
kramdown-rfc2629's sectionized input format.  He keeps the metadata in
a separate XML file, similar to the way the previous version of
kramdown-rfc2629 stored (and still can store) the metadata in XML in
the markdown document.  He also uses a slightly different referencing
syntax, which is closer to what markdown does elsewhere but more
verbose.

# License

(kramdown itself appears to be licensed GPLv3.)  As kramdown-rfc2629
is in part derived from kramdown source, there is little choice: It is
also licensed under GPLv3, which you can google yourself.  (Being
stuck at GPLv3 does not make me happy, but it is just for this tool so
it's probably not going to kill any RFC author.)

[kramdown]: http://kramdown.rubyforge.org/
[stupid]: http://tools.ietf.org/id/draft-hartke-xmpp-stupid-00
[RFC 2629]: http://xml.resource.org
[markdown]: http://en.wikipedia.org/wiki/Markdown
[IETF]: http://www.ietf.org
[Miek Gieben]: http://www.miek.nl/
[pandoc2rfc]: https://github.com/miekg/pandoc2rfc/
