---
layout: post
category: posts
title:  The Most Valuable Skill I Can't Put on a Resume
description: It's a skill that has kept companies in business, and saved millions. But most people don't even see it.
tags: tech
---
Occasionally on a job listing you see someone adding these sorts of things:

* "Detail oriented"
* "Thorough"
* "Excellent planning and organizational skills"

Most of the time, this appears in a job listing because you they have a typically chaotic operations environment and they need someone who does more than "I do what I am told."

That's close to what I am thinking. But this is further. I'm going to call this skill  "salvage yard."

In a good slavage yard, you know where everything is. There might be a lot going on, 
some things may be a mess, but you've taken the time to explore, cleanup and understand where and what it all is.

You don't build this knowledge immediately. It comes from good sanitation and work over time.

"Put all the hubcaps over there, so the customers can find them." as each car comes in.

Let me give you an example:

At one company I was brought into, there had not been terribly adult supervision in the administration of the server farms for several years.

I walked into a machine room where no one had pulled a cable in 10-years. Some servers had been running for years, and if you powered them down they would not power up again. In some cases fiber cables were stretched banjo tight across racks. There was no monitoring. There was no password control. There was a DR facility that had stacks of years-old equipment that had never been racked. There was a "storage room" of "spares" that were basically all the machines that had broken over the years that no one bothered to fix, stacked floor-to-ceiling and back-to-front filling an entire office.

So it was a busy job of fixing things. This is no surprise.

Faced with a giant unknown, I started a policy of "if I touch it, I take control of it and write things down." This was a functioning prod environment, I couldn't immediately change things. But I could start to organize the mess logically.

Evert task, every ticket, I slowly gathered up info: root passwords, disks, serial numbers, models, etc. I dug up old purchase orders. I slowly got rid of trash and cleared out storage spaces.

Eventually we did cage move within the datacenter and de-racked and re-racked everything properly. And then triaged what was left. That was the day I found 5 active demarked T1's in our cage I didn't know about. We were paying for 5. Only one was still in use.

So how did the salvageyard skill pay off?

We had a surprise audit of hardware as part of a financial transaction. One significant block of hardware (about 100 servers) had been provided to us as part of a contract. The finance company had trouble with that and did a no-notice audit on us.

Because I had been steadily gathering info on every machine, I was able to hit print on
a listing of our inventory system, and then the finance assistant and I walked over to the machine room and physically touched all 100 machines. It took about 20 minutes. The longest part was the walk to the machine room. And we made pleasant small talk the whole time.

Let me be clear: Because I had done the "salvage" work, a surprise financial audio in front of a company-sale passed in less than 20 minutes with zero push back. We even got thanked for the auditors for providing them a hard copy listing of machines and other associated information, which could be used as an appendix item in the audit.

The company later sold for a decent price. Did I help that? Sure. Could they have done it without me being a "salvage" guy? Probably. I doubt it would have been fun or gone well.

Another example:

A unicorn startup is hiring their first infrastructure people. One of the first tasks is to tackle DNS changes. As per ususal, people add DNS entries and run away. No one deletes old entries or tracks anything.

So we put together a private-cloud DNS control system.

And later we add IP issuing to it, because we have a lot of static labs.

Instantly we start to have history and usernames associated with who created what.

Monitoring had been a similar untracked mess. We realize we can hang monitoring controls off the DNS system. One click and you can create a new system and have it in various levels of monitoring. If you remove an old entry out of DNS, it also cleans up monitoring.

We start hanging configuration automation on it too. It can driver software installs of known configurations. Create and remove users.

We build a self-service provisioning system that sits next to this. Engineers can now create, reboot, destroy, and hop on the console of their own systems.

With all this tracking of user ownership, we can do clean off-boarding. Shut down and archive their infrastructure.

(I know some of you are shaking your head wondering why we just built AWS Route 53 or VMware's vCloud Director -- but this particular company had restrictions that required us to be in our own datacenter and working with physical equipment as well as VMs.)

That urge to keep the salvage yard organized and usable... set up habits that avoided gigantic messes and kept us ontop of efficient ownership of resources.

How the heck do you put that on a resume?

"I clean up after the initial task is done?"

"I make sure I know where everything is, who owns it, and what it's doing?"

I still don't know how to put it on a resume. And it's never been called out in an annual review. But it's probably the most business-valuable thing I do.
