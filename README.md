# kramdown-rfc2629

[kramdown][] is a [markdown][] parser by Thomas Leitner, which has a
number of backends for generating HTML, Latex, and markdown again.

**kramdown-rfc2629** is an additional backend to that: It allows the
generation of [XML2RFC][] XML markup (originally known as [RFC 2629][]
compliant markup, now documented in [RFC 7749][]).

Who would care?  Anybody who is writing Internet-Drafts and RFCs in
the [IETF][] and prefers (or has co-authors who prefer) to do part of
their work in markdown.

# Usage

Start by installing the kramdown-rfc2629 gem (this automatically
installs appropriate versions of referenced gems such as kramdown as
well):

    gem install kramdown-rfc2629

(Add a `sudo` and a space in front of that command if you don't have
all the permissions needed.)

The guts of kramdown-rfc2629 are in one Ruby file,
`lib/kramdown-rfc2629.rb` --- this melds nicely into the extension
structure provided by kramdown.  `bin/kramdown-rfc2629` started out as
a simple command-line program showing how to use this, but can now do
much more (see below).

To use kramdown-rfc2629, you'll need a Ruby 2.x, and maybe
[XML2RFC][] if you want to see the fruits of your work.

    kramdown-rfc2629 mydraft.mkd >mydraft.xml
    xml2rfc mydraft.xml

(The most popular file name extension that IETF people have for
markdown is .md -- for those who tend to think about GNU machine
descriptions here, any extension such as .mkd will do, too.)

A more brief interface for both calling kramdown-rfc2629 and XML2RFC
is provided by `kdrfc`:

    kdrfc mydraft.mkd

`kdrfc` can also use a remote installation of XML2RFC if needed:

    kdrfc -r mydraft.mkd

# Examples

For historical interest
`stupid.mkd` was an early markdown version of an actual Internet-Draft
(for a protocol called [STuPiD][] \[sic!]).  This demonstrated some,
but not all features of kramdown-rfc2629.  Since markdown/kramdown
does not cater for all the structure of an RFC 7749 style document,
some of the markup is in XML, and the example switches between XML and
markdown using kramdown's `{::nomarkdown}` and `{:/nomarkdown}` (this
is ugly, but works well enough).  `stupid.xml` and `stupid.txt` show
what kramdown-rfc2629 and xml2rfc make out of this.

`stupid-s.mkd` is the same document in the new sectionized format
supported by kramdown-rfc2629.  The document metadata are in a short
piece of YAML at the start, and from there, `abstract`, `middle`,
references (`normative` and `informative`) and `back` are sections
delimited in the markdown file.  See the example for how this works.
The sections `normative` and `informative` can be populated right from
the metadata, so there is never a need to write XML any more.
Much less scary, and no `{:/nomarkdown}` etc. is needed any more.
Similarly, `stupid-s.xml` and `stupid-s.txt` show what
kramdown-rfc2629 and xml2rfc make out of this.

`draft-ietf-core-block-xx.mkd` is a real-world example of a current
Internet-Draft done this way.  For RFC and Internet-Draft references,
it uses document prolog entities instead of caching the references in
the XML (i.e., not standalone mode, this is easier to handle when
collaborating with XML-only co-authors).  See the `bibxml` metadata.

# The YAML header

Please consult the examples for the structure of the YAML header, this should be mostly
obvious.  The `stand_alone` attribute controls whether the RFC/I-D
references are inserted into the document (yes) or entity-referenced
(no), the latter leads to increased build time, but may be more
palatable for a final XML conversion.
The author entry can be a single hash or a list, as in:

    author:
      ins: C. Bormann
      name: Carsten Bormann
      org: Universität Bremen TZI
      abbrev: TZI
      street: Bibliothekstr. 1
      city: Bremen
      code: D-28359
      country: Germany
      phone: +49-421-218-63921
      email: cabo@tzi.org

or

    author:
      -
        ins: C. Bormann
        name: Carsten Bormann
        org: Universität Bremen TZI
        email: cabo@tzi.org
      -
        ins: Z. Shelby
        name: Zach Shelby
        org: Sensinode
        role: editor
        street: Kidekuja 2
        city: Vuokatti
        code: 88600
        country: Finland
        phone: "+358407796297"
        email: zach@sensinode.com
      -
        role: editor
        ins: P. Thubert
        name: Pascal Thubert
        org: Cisco Systems
        abbrev: Cisco
        street:
        - Village d'Entreprises Green Side
        - 400, Avenue de Roumanille
        - Batiment T3
        city: Biot - Sophia Antipolis
        code: '06410'
        country: FRANCE
        phone: "+33 4 97 23 26 34"
        email: pthubert@cisco.com

(the hash keys are the XML GIs from RFC 7749, with a flattened
structure.  As RFC 7749 requires giving both the full name and
surname/initials, we use `ins` as an abbreviation for
"initials/surname".  Yes, the toolchain is Unicode-capable, even if
the final RFC output is still in ASCII.)

Note that the YAML header needs to be syntactically valid YAML.
Where there is a potential for triggering some further YAML feature, a
string should be put in quotes (like the "+358407796297" above, which
might otherwise be interpreted as a number, losing the + sign).

## References

The references section is built from the references listed in the YAML
header and from references made inline to RFCs and I-Ds in the
markdown text.  Since kramdown-rfc2629 cannot know whether a reference
is normative or informative, no entry is generated by default in the
references section.  By indicating a normative reference as in
`{{!RFC2119}}` or an informative one as in `{{?RFC1925}}`, you can
completely automate the referencing, without the need to write
anything in the header.  Alternatively, you can write something like:

    informative:
      RFC1925:
    normative:
      RFC2119:

and then just write `{{RFC2119}}` or `{{RFC1925}}`.  (Yes, there is a
colon in the YAML, because this is a hash that could provide other
information.)

Since version 1.1, references imported from the [XML2RFC][] databases
can be supplied with a replacement label (anchor name).  E.g., RFC 793
could be referenced as `{{!TCP=RFC0793}}`, further references then just
can say `{{TCP}}`; both will get `[TCP]` as the label.  In the
YAML, the same replacement can be expressed as in the first example:

     normative:
       TCP: RFC0793
     informative:
       SST: DOI.10.1145/1282427.1282421

Notes about this feature:

* Thank you, Martin Thomson, for supplying an implementation and
  insisting this be done.
* While this feature is now available, you are not forced to use it
  for everything: readers of documents often benefit from not having
  to look up references, so continuing to use the draft names and RFC
  numbers as labels may be the preferable style in many cases.
* As a final caveat, renaming anchors does not work in the
  `stand_alone: no` mode (except for IANA and DOI), as there is no
  such mechanism in XML entity referencing; exporting to XML while
  maintaining live references then may require some manual editing to
  get rid of the custom anchors.

If your references are not in the [XML2RFC][] databases and do not
have a DOI (that also happens to have correct data) either, you need
to spell it out like in the examples below:

    informative:
      RFC1925:
      WEI:
        title: "6LoWPAN: the Wireless Embedded Internet"
        # see the quotes above?  Needed because of the embedded colon.
        author:
          -
            ins: Z. Shelby
            name: Zach Shelby
          -
            ins: C. Bormann
            name: Carsten Bormann
        date: 2009
        seriesinfo:
          ISBN: 9780470747995
        ann: This is a really good reference on 6LoWPAN.
      ASN.1:
        title: >
          Information Technology — ASN.1 encoding rules:
          Specification of Basic Encoding Rules (BER), Canonical Encoding
          Rules (CER) and Distinguished Encoding Rules (DER)
        # YAML's ">" syntax used above is a good way to write longer titles
        author:
          org: International Telecommunications Union
        date: 1994
        seriesinfo:
          ITU-T: Recommendation X.690
      REST:
        target: http://www.ics.uci.edu/~fielding/pubs/dissertation/fielding_dissertation.pdf
        title: Architectural Styles and the Design of Network-based Software Architectures
        author:
          ins: R. Fielding
          name: Roy Thomas Fielding
          org: University of California, Irvine
        date: 2000
        seriesinfo:
          "Ph.D.": "Dissertation, University of California, Irvine"
        format:
          PDF: http://www.ics.uci.edu/~fielding/pubs/dissertation/fielding_dissertation.pdf
      COAP:
        title: "CoAP: An Application Protocol for Billions of Tiny Internet Nodes"
        seriesinfo:
          DOI: 10.1109/MIC.2012.29
        date: 2012
        author:
          -
            ins: C. Bormann
            name: Carsten Bormann
          -
            ins: A. P. Castellani
            name: Angelo P. Castellani
          -
            ins: Z. Shelby
            name: Zach Shelby
      IPSO:
        title: IP for Smart Objects (IPSO)
        author:
        - org:
        date: false
        seriesinfo:
          Web: http://ipso-alliance.github.io/pub/
    normative:
      ECMA262:
        author:
          org: European Computer Manufacturers Association
        title: ECMAScript Language Specification 5.1 Edition
        date: 2011-06
        target: http://www.ecma-international.org/publications/files/ecma-st/ECMA-262.pdf
        seriesinfo:
          ECMA: Standard ECMA-262
      RFC2119:
      RFC6690:

(as in the author list, `ins` is an abbreviation for
"initials/surname"; note that the first title had to be put in double
quotes as it contains a colon which is special syntax in YAML.)
Then you can simply reference `{{ASN.1}}` and
`{{ECMA262}}` in the text.  (Make sure the reference keys are valid XML
names, though.)

# Experimental features

Most of the [kramdown syntax][kdsyntax] is supported and does
something useful; with the exception of the math syntax (math has no
special support in XML2RFC), and HTML syntax of course.

A number of more esoteric features have recently been added.
(The minimum required version for each full feature is indicated.)

(1.3.x)
Slowly improving support for SVG generating tools for XML2RFCv3 (i.e.,
with `-3` flag).
These tools must be installed and callable from the command line.

The basic idea is to mark an input code block with one of the following
labels (language types), yielding some plaintext form in the .TXT
output and a graphical form in the .HTML output.  The plaintext is the
input in some cases (e.g., ASCII art, `mscgen`), or some plaintext
output generated by the tool (e.g., `plantuml-utxt`).

Currently supported labels as of 1.3.9:

* [goat][], [ditaa][]: ASCII (plaintext) art to figure conversion
* [mscgen][]: Message Sequence Charts
* [plantuml][]: widely used multi-purpose diagram generator
* plantuml-utxt: Like plantuml, except that a plantuml-generated
  plaintext form is used
* [mermaid][]: Very experimental; the conversion to SVG is prone to
  generate black-on-black text in this version
* math: display math using [tex2svg][] for HTML/PDF and [asciitex][]
  (fork: [asciiTeX][asciiTeX-eggert]) for plaintext

[goat]: https://github.com/blampe/goat
[ditaa]:  https://github.com/stathissideris/ditaa
[mscgen]: http://www.mcternan.me.uk/mscgen/
[plantuml]: https://plantuml.com
[mermaid]: https://github.com/mermaid-js/mermaid-cli
[tex2svg]: https://github.com/mathjax/MathJax-demos-node/blob/master/direct/tex2svg
[asciitex]: http://asciitex.sourceforge.net/
[asciiTeX-eggert]: https://github.com/larseggert/asciiTeX

Note that this feature does not play well with the CI (continuous
integration) support in Martin Thomson's [I-D Template][], as that may
not have the tools installed in its docker instance.

(1.2.9:)
The YAML header now allows specifying [kramdown_options][].

[kramdown_options]: https://kramdown.gettalong.org/options.html

This was added specifically to provide easier access to the kramdown
`auto_id_prefix` feature, which prefixes by some distinguishing string
the anchors that are auto-generated for sections, avoiding conflicts:

```yaml
kramdown_options:
  auto_id_prefix: sec-
```

(1.2.8:)
An experimental feature was added to include [BCP 14] boilerplate:

```markdown
{::boilerplate bcp14}
```

which saves some typing.  Saying "bcp14+" instead of "bcp14" adds some
random clarifications at the end of the [standard boilerplate text][] that
you may or may not want to have.  (Do we need other boilerplate items
beyond BCP14?)

[BCP 14]: https://www.rfc-editor.org/info/bcp14

[standard boilerplate text]: https://tools.ietf.org/html/rfc8174#page-3

(1.0.35:)
An experimental command `doilit` has been added.  It can be used to
convert DOIs given on the command line into references entries for
kramdown-rfc YAML, saving a lot of typing.  Note that the DOI database
is not of very consistent quality, so you likely have to hand-edit the
result before including it into the document (use `-v` to see raw JSON
data from the DOI database, made somewhat readable by converting it
into YAML).  Use `-c` to enable caching (requires `open-uri-cached`
gem).  Use `-h=handle` in front of a DOI to set a handle different
from the default `a`, `b`, etc.  Similarly, use `-x=handle` to
generate XML2RFCv2 XML instead of kramdown-rfc YAML.

(1.0.31:)
The kramdown `smart_quotes` feature can be controlled better.
By default, it is on (with default kramdown settings), unless `coding:
us-ascii` is in effect (1.3.14: or --v3 is given), in which case it is off by default.
It also can be explicitly set on (`true`) or off (`false`) in the YAML
header, or to a specific value (an array of four kramdown entity names
or character numbers).  E.g., for a German text (that is not intended
to become an Internet-Draft), one might write:

```yaml
smart_quotes: [sbquo, lsquo, bdquo, ldquo]
pi:
  topblock: no
  private: yes
```

(1.0.30:)
kramdown-rfc now uses kramdown 1.10, which leads to two notable updates:

 * Support for empty link texts in the standard markdown
   reference syntax, as in `[](#RFC7744)`.
 * Language names in fenced code blocks now support all characters
   except whitespace, so you can go wild with `asn.1` and `C#`.

A heuristic generates missing initials/surname from the `name` entry
in author information.  This should save a lot of redundant typing.
You'll need to continue using the `ins` entry as well if that
heuristic fails (e.g., for Spanish names).

Also, there is some rather experimental support for markdown display
math (blocks between `$$` pairs) if the `tex2mail` tool is available.

(1.0.23:)
Move up to kramdown 1.6.0.  This inherits a number of fixes and one
nice feature:
Markdown footnote definitions that turn into `cref`s can have their
attributes in the footnote definition:

```markdown
{:cabo: source="cabo"}

(This section to be removed by the RFC editor.)[^1]

[^1]: here is my editorial comment: warble warble.
{:cabo}

Another questionable paragraph.[^2]

[^2]: so why not delete it?
{: source="observer"}
```

(1.0.23:)
As before, IAL attributes on a codeblock go to the figure element.
Language attributes on the code block now become the artwork type, and any
attribute with a name that starts "artwork-" is moved over to the artwork.
So this snippet now does the obvious things:

```markdown
~~~ abnf
a = b / %s"foo" / %x0D.0A
~~~
{: artwork-align="center" artwork-name="syntax"}
```

(1.0.22:)
Index entries can be created with `(((item)))` or
`(((item, subitem)))`; use quotes for weird entries: `(((",", comma)))`.
If the index entry is to be marked "primary", prefix an (unquoted) `!`
as in `(((!item)))`.

In addition, auto-indexing is supported by hijacking the kramdown
"abbrev" syntax:

    *[IANA]:
    *[MUST]: BCP14
    *[CBOR]: (((Object Representation, Concise Binary))) (((CBOR)))

The word in square brackets (which must match exactly,
case-sensitively) is entered into the index automatically for each
place where it occurs.  If no title is given, just the word is entered
(first example).  If one is given, that becomes the main item (the
auto-indexed word becomes the subitem, second example).  If full
control is desired (e.g., for multiple entries per occurrence), just
write down the full index entries instead (third example).

(1.0.20:)
As an alternative referencing syntax for references with text,
`{{ref}}` can be expressed as `[text](#ref)`.  As a special case, a
simple `[ref]` is interpreted as `[](#ref)` (except that the latter
syntax is not actually allowed by kramdown).  This syntax does not
allow for automatic entry of items as normative/informative.

(1.0.16:) Markdown footnotes are converted into `cref`s (XML2RFC formal
comments; note that these are only visible if the pi "comments" is set to yes).
The anchor is taken from the markdown footnote name. The source, if
needed, can be supplied by an IAD, as in (first example with
ALD):

```markdown
{:cabo: source="cabo"}

(This section to be removed by the RFC editor.)[^1]{:cabo}

[^1]: here is my editorial comment

Another questionable paragraph.[^2]{: source="observer"}

[^2]: so why not delete it
```

Note that XML2RFC v2 doesn't allow structure in crefs. If you put any,
you get the escaped verbatim XML...

(1.0.11:) Allow overriding "style" attribute (via IAL =
[inline attribute list][kdsyntax-ial]) in lists and spans
as in:

```markdown
{:req: counter="bar" style="format R(%d)"}

{: req}
* Foo
* Bar
* Bax

Text outside the list, so a new IAL is needed.

* Foof
* Barf
* Barx
{: req}
```

(1.0.5:) An IAL attribute "cols" can be added to tables to override
the column layout.  For example, `cols="* 20 30c r"` sets the width attributes to
20 and 30 for the middle columns and sets the right two columns to
center and right alignment, respectively.  The alignment from `cols`
overrides that from the kramdown table, if present.

(1.0.2:) An IAL attribute "vspace" can be added to a definition list
to break after the definition term:

```markdown
{: vspace="0"}
word:
: definition

anotherword:
: another definition
```

(0.x:) Files can be included with the syntax `{::include fn}` (needs
to be in column 1 since 1.0.22; can be suppressed for use in servers
by setting environment variable KRAMDOWN_SAFE since 1.0.22).  A
typical example from a recent RFC, where the contents of a figure was
machine-generated:

```markdown
~~~~~~~~~~
{::include ../ghc/packets-new/p4.out}
~~~~~~~~~~
{: #example2 title="A longer RPL example"}
```

(0.x:) A page break can be forced by adding a horizontal rule (`----`,
note that this creates ugly blank space in some HTML converters).

# Risks and Side-Effects

The code is not very polished, but now quite stable; it has been successfully used for a
number of non-trivial Internet-Drafts and RFCs.  You probably still need to
skim [RFC 7749][] if you want to write an Internet-Draft, but you
don't really need to understand XML very much.  Knowing the basics of
YAML helps with the metadata (but you'll understand it from the
examples).

Occasionally, you do need to reach through to the XML arcana, e.g. by
setting attribute values using kramdown's ["IAL" syntax][IAL].
This can for instance be used to obtain unnumbered appendices:

```markdown
Acknowledgements
================
{: numbered="no"}

John Mattsson was nice enough to point out the need for this being documented.
```

[IAL]: https://kramdown.gettalong.org/syntax.html#inline-attribute-lists

# Upconversion

If you have an old RFC and want to convert it to markdown, try just
using that RFC, it is 80 % there.  It may be possible to automate the
remaining 20 % some more, but that hasn't been done.

If you have XML, there is an experimental upconverter that does 99 %
of the work.  Please [contact the
author](mailto:cabo@tzi.org?subject=Markdown for RFCXML) if you want
to try it.

Actually, if the XML was generated by kramdown-rfc2629, you can simply
extract the input markdown from that XML file (but will of course lose
any edits that have been made to the XML file after generation):

    kramdown-rfc-extract-markdown myfile.xml >myfile.md


# Tools

Joe Hildebrand has a
[grunt][] plugin for kramdown-rfc2629 at:
https://github.com/hildjj/grunt-kramdown-rfc2629
.
Get started with it at:
https://github.com/hildjj/grunt-init-rfc
.
This provides a self-refreshing web page with the
kramdown-rfc2629/xml2rfc rendition of the draft you are editing.

[grunt]: http://gruntjs.com

Martin Thomson has an [I-D Template][] for github repositories that enable
collaboration on draft development.
This supports kramdown-rfc2629 out of the
box.  Just name your draft like `draft-ietf-unicorn-protocol-latest.md` and
follow the installation instructions.

[I-D Template]: https://github.com/martinthomson/i-d-template

# Related Work

Moving from XML to Markdown for RFC writing apparently is a
no-brainer, so I'm not the only one who has written code for this.

[Miek Gieben][] has done a [similar thing][pandoc2rfc] employing
pandoc, now documented in [RFC 7328][].  He uses multiple input files instead of
kramdown-rfc2629's sectionized input format.  He keeps the metadata in
a separate XML file, similar to the way the previous version of
kramdown-rfc2629 stored (and still can store) the metadata in XML in
the markdown document.  He also uses a slightly different referencing
syntax, which is closer to what markdown does elsewhere but more
verbose (this syntax is now also supported in kramdown-rfc2629).
(Miek now also has a new thing going on with mostly different syntax,
see [mmark][] and its [github repository][mmark-git].)

Other human-oriented markup input languages that are being used for authoring RFCXML include:

* [asciidoc][], with the [asciidoctor-rfc][] tool, as documented in [draft-ribose-asciirfc][].
* [orgmode][] (please help supply a more specific link here).

# License

Since kramdown version 1.0, kramdown itself is MIT licensed, which
made it possible to license kramdown-rfc2629 under the same license.

[kramdown]: http://kramdown.rubyforge.org/
[kdsyntax]: http://kramdown.gettalong.org/syntax.html
[kdsyntax-ial]: http://kramdown.gettalong.org/syntax.html#inline-attribute-lists
[stupid]: http://tools.ietf.org/id/draft-hartke-xmpp-stupid-00
[RFC 2629]: http://xml.resource.org/public/rfc/html/rfc2629.html
[RFC 7749]: http://tools.ietf.org/html/rfc7749
[markdown]: http://en.wikipedia.org/wiki/Markdown
[IETF]: http://www.ietf.org
[Miek Gieben]: http://www.miek.nl/
[pandoc2rfc]: https://github.com/miekg/pandoc2rfc/
[XML2RFC]: http://xml.resource.org
[RFC 7328]: http://tools.ietf.org/html/rfc7328
[mmark-git]: https://github.com/miekg/mmark
[mmark]: https://mmark.nl
[YAML]: http://www.yaml.org/spec/1.2/spec.html
[draft-ribose-asciirfc]: https://tools.ietf.org/html/draft-ribose-asciirfc
[asciidoctor-rfc]: https://github.com/metanorma/asciidoctor-rfc
[asciidoc]: http://www.methods.co.nz/asciidoc/
[orgmode]: http://orgmode.org
