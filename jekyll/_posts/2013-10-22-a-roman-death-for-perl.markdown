---
layout: post
category: posts
title: How to die ike a Roman in Perl."
description: "A bit of mischief: how to die like a Roman in Perl"
tags: perl mischief
---
Today’s mischief is brought to you by the line-noise that you can compile: Perl!

You can add this code ANYWHERE in an executing perl stack. (a module, a referenced library, an inherited base class, etc) Then at any point the perl application warns() or dies() and shows the accompanying error, the line number is shown roman numerals.

{% highlight perl linenos %}
BEGIN {
  my $roman = sub {
    my $message = shift @_;
    chomp $message;
    my $file = __FILE__;
    my $line = __LINE__;
    my $roman;

    while ( $line >= 1000 ) { $roman .= 'M' ; $line -= 1000 }
    while ( $line >=  900 ) { $roman .= 'CM'; $line -=  900 }
    while ( $line >=  500 ) { $roman .= 'D' ; $line -=  500 }
    while ( $line >=  400 ) { $roman .= 'CD'; $line -=  400 }
    while ( $line >=  100 ) { $roman .= 'C' ; $line -=  100 }
    while ( $line >=   90 ) { $roman .= 'XC'; $line -=   90 }
    while ( $line >=   50 ) { $roman .= 'L' ; $line -=   50 }
    while ( $line >=   40 ) { $roman .= 'XL'; $line -=   40 }
    while ( $line >=   10 ) { $roman .= 'X' ; $line -=   10 }
    while ( $line >=    9 ) { $roman .= 'IX'; $line -=    9 }
    while ( $line >=    5 ) { $roman .= 'V' ; $line -=    5 }
    while ( $line >=    4 ) { $roman .= 'IV'; $line -=    4 }
    while ( $line >=    1 ) { $roman .= 'I' ; $line -=    1 }

    print STDERR "$message at $file line $roman\n";
    exit 0;
  };
  *CORE::GLOBAL::die  = $roman; 
  *CORE::GLOBAL::warn = $roman;
}
{% endhighlight %}

This is especially effective on large OO deployments and mod_perl setups!
It’s great for driving your friends into homicidal rage! 🙂

Example:

{% highlight perl %}
die "foo";
{% endhighlight %}

Returns:

{% highlight shell %}
foo at mydie.pl line VII
{% endhighlight %}

And yes, it passes “use strict” without notice.