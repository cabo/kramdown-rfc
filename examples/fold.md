---
coding: utf-8
v: 3

title: Many fine lunches and dinners
abbrev: mfld
docname: draft-mfld-00
category: info
stream: IETF

author:
  - name: Carsten Bormann
    org: Universität Bremen TZI
    street: Postfach 330440
    city: Bremen
    code: D-28359
    country: Germany
    phone: +49-421-218-63921
    email: cabo@tzi.org

--- abstract

insert abstract here

--- middle

# Introduction

{::boilerplate bcp14-tagged-bcp14}

## Testing fold

~~~ test-vectors
short line
short line with one \
short line with two \\
aaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
   bbbbbbbbbbbbb bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
      cccccccccc ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
  dddddddddddddd ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
~~~
{: post="fold40hardleft2dry" title="fold40hardleft2dry"}

~~~ test-vectors
short line
short line with one \
short line with two \\
aaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
   bbbbbbbbbbbbb bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
      cccccccccc ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
  dddddddddddddd ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
~~~
{: post="fold40smart2dry" title="fold40smart2dry"}

~~~ test-vectors
short line
short line with one \
short line with two \\
aaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
   bbbbbbbbbbbbb bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
      cccccccccc ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
  dddddddddddddd ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
~~~
{: post="fold40hardsmart2dry" title="fold40hardsmart2dry"}

~~~ test-vectors
short line
short line with one \
short line with two \\
aaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
   bbbbbbbbbbbbb bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
      cccccccccc ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
  dddddddddddddd ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd
~~~
{: post="fold40dry" title="fold40dry"}
