---
layout: post
category: posts
title:  "Home monitoring with Raspberry Pi"
description: "Setting up a single Raspberry Pi to monitor the house, the network and to use DNS to kill ads."
tags: home_monitoring
---

Recently, I have been updating the home network. I had an old raspberry PI lying around and wanted to try a few things.

My major goal is three packages in play: PiHole DNS, Smokeping, and Nagios. And basically put it all on the one Raspberry Pi.

Many of these projects assume you have a dedicated Pi just for them, so they conflict a little. Here's how I worked this out:

**PiHole DNS - Ad Blocking**

First off, I had heard good things of the PiHole project.

This is a DNS server that you set up on a raspberry pi that automatically kills a lot of basic adware and spam at the DNS level. 

Compared to blocking a website in a firewall, which may require your browser to timeout the action for each blocked item, DNS has the ability to respond negatively built in. That means the block is basically instant and processed quickly as you browse.

This one was the simplest install, since it was first. Set up a pihole account and do the install:

{% highlight shell %}
sudo pihole -a -p (set blank to remove password)
{% endhighlight %}

**Smokeping - Network latency monitoring**

Next to install is Smokeping. A useful tool to monitoring for network latency and loss.

First a basic setup of getting the app to run:

	* sudo apt-get install smokeping
	* sudo nano /etc/smokeping/config.d/Targets
	* sudo nano /etc/systemd/system/multi-user.target.wants/smokeping.service
		* Add Environment="LC_ALL=" 
	* systemctl daemon-reload
	* systemctl start smokeping.service

The curveball here is configiring it to display on the web server that PiHole just installed.

* Add smokeping to pihole HTTPd	
	* sudo ln -s /usr/share/smokeping/www /var/www/html/smokeping
	* sudo cp /var/www/html/smokeping/smokeping.fcgi.dist /var/www/html/smokeping/smokeping.fcgi
	* sudo echo 'exec /usr/lib/cgi-bin/smokeping.cgi /etc/smokeping/config' >> /var/www/html/smokeping/smokeping.fcgi
	* Create /etc/lighttpd/conf-available/20-smokeping.conf
>fastcgi.server += (
  "smokeping.fcgi" => ((
    "socket"   => "/var/run/lighttpd/fcgi.socket",
    "bin-path" => "/usr/share/smokeping/www/smokeping.fcgi"
  ))
)
* sudo lighttpd-enable-mod smokeping
	* sudo lighttpd-enable-mod fastcgi
	* sudo /etc/init.d/lighttpd force-reload
	* Add at the end of /etc/lighttpd/lighttpd.conf
>\$HTTP["url"] =~ "^/smokeping/" {
         setenv.add-environment = ( "LC_ALL" => "" )
         url.redirect  = ("^/smokeping/?$" => "/smokeping/smokeping.fcgi")
}

* * service lighttpd force-reload
	* You can now access it at /smokeping/


* sudo lighttpd-enable-mod nagios fastcgi-php cgi

**Nagios - Complex system monitoring**
