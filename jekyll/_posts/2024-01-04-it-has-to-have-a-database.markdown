---
layout: post
title:  "It HAS to have a database!"
date:   2024-01-04 16:28:30 -0500
categories: compute_stories
---

It's the early 20-teens and I am on a contract to a department store known for its upscale clothing.

The headquarters building is in the fancy financial end of this large west coast city. They have 1500 programmers! They proudly tell me this in my first 15 minutes there. It seems like everyone here is wearing fancy clothing. My passing humorous assumption is that frustrated people who wanted to be in fashion design ended up in IT and tech here. 

Thinking more about it: They have "1500 programmers" to run a retailer website and the cash registers for about 500 locations. A quick glance at salary info for this company shows they are paying about 60% the going rate for tech jobs. Very quickly, and somewhat horrified, I wondered how accurate my humorous assumption might be.

Now there are two kinds of companies that hire consultants. Maybe 1 or 2 times out of 10, they are hiring you to specifically accelerate a known bit of work. Especially if it is something that requires esoteric knowledge or is a specifically compartmented task. Those gigs are wonderful. You do amazing things in them.

The other 9 out of 10 jobs are companies that have to hire consultants to function. You are there to overcome one or both of two common causes: 1) the company has knowingly hired substandard people for the daily work and this task needs an adult to execute it, or 2) the company has a broken work environment so that you are there to either work around the problem by being external and untained -- or you will be used as a weapon in their ongoing interdeparmental war.

Thankfully this gig was mostly problem 1 - helping people do a task that is beyond them. They had a relatively simply defined goal: basically they needed a way to provide statistics and information on the status of a given set of virutal machines. A daily report on how well certain internal products were done. For various internal reasons, monitoring and normal reporting methods were not acceptable. This gig was "write a script that poops out a report on the VMs."

If you think that is trivial, it is. That's not the point. I am being paid because no one currently in this group can do this and with the knowledge of doing it the right way.

So after a round of meetings so every related department could give me their take on the reqirements, and after securing a code repo and place to work, I had this done basically in a day or two. Spinkle on some pretty documentation, and poof: one contract finished.

In the first "song and dance" meeting of "this is done, this is what you get" though there was a major panic. I had gone through the fancy deck of slides that shows "this is a script. This is how you run it. This is where it is stored. This is the report it poops out. Tada!" and we were into the questions section. One of the "developers" raised his hand and asked "where's the database?"

I had never witnessed anything like this.

Like some weird religious responsorial a mutter went around the table: "Yes. A database." "Of course. We need a database" "A database."

Look, I watched my nephew gleefully yell the pokemon name at the "Which Pokemon is this?" screen. It had nothing on how Pavlovian this bizarre moment was.

I politely explained we were querying an active control system to get the previous day's data. And then we generated a report. Said control system had all the data we needed. We did not need to store anything anywhere in our work.

The manager, an older fellow, took off his glasses and in a fatherly tone one might use with a child who is about to eat a penny said: "I don't think you understand. This needs a database."

He then turned and started tasking people with stuff to do at the table. Being a "big company" there was a lead time to things. They would need to ask for a rush on procuring of a database. And they would have to ask about licenses. And then there was a 10 minute discussion on how long the backups should be kept.

The team lept into action, and they busted their asses. 6 programmers made sure that by 2 days later I had a mysql database instance to use. And I was sternly instructed to make sure I had it integrated into my work "before the contract was out." There was the vague nodding threat of "we won't pay more for this."

I then spent about an hour writing the dumbest code I have ever written.

My initial impulse was to use a single table, a single column, and a single row. But I just couldn't bring myself to do it.

So I created a single table with two colums: a date and a text field. I wrote the script to store the report it created under the date it was generated, and to automatically delete anything more than a week old.

As requested the way the program flowed now was: it would build the report, store it into the database, then read it back out of the database, and then write the report to a file.

It now used a database. The contract was saved.

I even threw in a couple of command line parameters to list reports currently in the database. And a bypass that if they database was down it would just print the current report and warn the database was down.

Those "extra" features got a huge "Wow" from the crowd when I presented them in my "song and dance" exit meeting round 2. The boss even noted they could hire me again if they wanted something complex lime making it keep 2 weeks of reports!

There's no good lesson here. Just occasionally when I am tasked some apparently-insane thing to do I might laugh. Because at least they didn't tell me to add a database to it, too.