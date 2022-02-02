---
stand_alone: true
ipr: trust200902
cat: info # Check
submissiontype: IETF
area: General [REPLACE]
wg: Internet Engineering Task Force

docname: draft-rfcxml-general-template-standard-00
obsoletes: 4711, 4712 # Remove if not needed/Replace
updates: 4710 # Remove if not needed/Replace

title: Title [REPLACE]
abbrev: Abbreviated Title [REPLACE]
lang: en
kw:
  - keyword1
  - keyword2
# date: 2022-02-02 -- date is filled in automatically by xml2rfc if not given
author:
- role: editor # remove if not true
  ins: I. J-P. Surname [REPLACE]
  name: fullname [REPLACE]
  org: Organization [REPLACE/DELETE]
  street: Street [REPLACE/DELETE]
  city: City [REPLACE/DELETE]
  region: Region [REPLACE/DELETE] # not always available
  code: Postal code [REPLACE/DELETE]
  country: FJ # use TLD (except UK) or country name
  phone: Phone [REPLACE/DELETE]
  email: Email [REPLACE/DELETE]
  uri: URI [REPLACE/DELETE]
contributor: # Same structure as author list, but goes into contributors
- name: Carsten Bormann
  org: Universität Bremen TZI
  email: cabo@tzi.org
  uri: https://rfc.space
- name: Jay Daley
  org: IETF Administration LLC
  email: exec-director@ietf.org
  contribution: |
    Jay provided the **XML** version of the template.

    That was quite helpful.

normative:
  RFC5234: # REPLACE
informative:
  exampleRefMin:
    title: Title [REPLACE]
    author:
    - name: Givenname Surname[REPLACE]
      org: (ignored here anyway)
    - name: Givenname Surname1 Surname2
      surname: Surname1 Surname2 # needed for Spanish names etc.
      org: (ignored here anyway)
    date: 2006
  exampleRefOrg:
    target: http://www.example.com/
    title: Title [REPLACE]
    author:
    - org: Organization [REPLACE]
    date: 1984-04

--- abstract

Abstract [REPLACE]

--- middle

# Introduction

Introductory text [REPLACE]

## Requirements Language

{::boilerplate bcp14-tagged}

# Body [REPLACE]

Some body text [REPLACE]

This document normatively references {{RFC5234}} and has more
information in {{exampleRefMin}} and {{exampleRefOrg}}. [REPLACE]

1. Ordered list item [REPLACE/DELETE]
2. Ordered list item [REPLACE/DELETE]

* Bulleted list item [REPLACE/DELETE]
* Bulleted list item [REPLACE/DELETE]

| Table head 1 [REPLACE] | Table head2 [REPLACE] |
| Cell 11 [REPLACE]      | Cell 12 [REPLACE]     |
| Cell 21 [REPLACE]      | Cell 22 [REPLACE]     |
{: title="A nice table [REPLACE]"}

~~~~ language-REPLACE/DELETE
source code goes here [REPLACE]
~~~~
{: title='Source [REPLACE]' sourcecode-markers="true"}


# IANA Considerations {#IANA}

This memo includes no request to IANA. [CHECK]


# Security Considerations {#Security}

This document should not affect the security of the Internet. [CHECK]


--- back

# Appendix 1 [REPLACE/DELETE]

This becomes an Appendix [REPLACE]


# Acknowledgements {#Acknowledgements}
{: numbered="false"}

This template uses extracts from templates written by
{{{Pekka Savola}}}, {{{Elwyn Davies}}} and
{{{Henrik Levkowetz}}}. [REPLACE]

