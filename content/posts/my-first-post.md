+++
title = "My First Post"
date = "2022-08-17T20:21:48-05:00"
author = "Alejandro Anzola-Ávila"
authorTwitter = "aanzolaavila" #do not include @
cover = ""
tags = ["test", "hugo", "mathjax", "latex", "markdown"]
keywords = ["mathjax", "code", "inline"]
description = "This is my first post with Hugo"
showFullContent = false
readingTime = true
hideComments = true
+++

Some text.

# An image
{{< figure src="/personal-blog/img/smiling-friends.jpg" alt="Smiling Friends" caption="Smiling Friends">}}

# Some code
```bash
$ echo "this is an example"
```

# Some math
{{< mathjax/block >}}
\[ g = f(x) = \int_0^\infty x\ dx \]
{{< /mathjax/block >}}

## Some inline math
Inline shortcode {{< mathjax/inline >}}\(a \ne 0\){{< /mathjax/inline >}} with Mathjax.

Some random change.
