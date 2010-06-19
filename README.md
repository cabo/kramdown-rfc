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

The guts of kramdown-rfc2629 are in one Ruby file, `kramdown-rfc2629.rb`
--- this melds nicely into the extension structure provided by
kramdown.  `convert1.rb` is a command-line demo showing how to use this,
which needs to be adapted to the place where a copy of a recent
kramdown (~ 0.9.0) lives.  Oh, and you'll need a Ruby 1.9, and maybe
XML2RFC if you want to see the fruits of your work.

    ./convert1.rb mydraft.mkd >mydraft.xml
    xml2rfc mydraft.xml

# Examples

`stupid.mkd` is a markdown version of an actual Internet-Draft (for a
protocol called [STuPiD][] [sic!]).  This demonstrates some, but not
all features of kramdown-rfc2629.  Since markdown/kramdown does not
cater for all the structure of an RFC 2629 style document, some of the
markup is in XML, and the example switches between XML and markdown
using kramdown's `{::nomarkdown}` and `{:/nomarkdown}` (this is ugly,
but works well enough).

# Risks and Side-Effects

The code is not very polished (in particular, the code for tables is a
joke), and you probably still need to understand [RFC 2629][] if you
want to write an Internet-Draft.

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
