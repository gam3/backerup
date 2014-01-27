backerup
========

/ˈbækərˈʌp/ noun, plural back·ers-up. 1. a supporter; backer; second. 2. Football. a linebacker.

This software is designed to support you in having offside backups over slower networks.  Like a linebacker it is very tenacious about protecting the data.

Backerup improves on the ideas that http://www.rsnapshot.com uses.  While rsnapshot is very good about limiting the amount of data that has to cross the network and the amount of disk space that is used on the backup server, it is not good about prioritizing the data, or handing failures.  Backerup attempts to keep all of the good features of rsnapshot and remove many of is short comings. 

To-do

- [x] Get the collector to work
- [x] create demo copier
- [x] create demo cleaner
- [x] Get the configuration working
- [x] create copier
- [x] create cleaner

Design principles of backerup
=============================

The main principles that guide the backerup project are: the Unix way,
and simplicity, and robustness.

The major things that are required from the system are that it be
robust. Buy robust I mean some part of the system fails that the whole
system does not. And that it is easy to recover from failures. Backup
systems can go a very long time with out being used. It can be
difficult to be sure that the backup is usable, and when you need to
use a back up you are often under a large amount of stress. If a backup
system is complex it can make these issues overwhelming.

Most system administrators use rsync daily and are familure with how
it operates and since backerup is mostly a simple wrapper around
rsync the user should be able to understand how files are brought
across the network.

The backerup-copier is really just runs 'cp -rl {source} {dest}' and the
operator can use that command to recover from backerup failures.

The backerup-cleaner is just selecting dirctories and deleting them with `rm -rf {dest}'.

As hardlinks are used the operating system cleans up files that are no
longer linked to any `snapshot'.

All of the backerup processes can be killed and be left is a recoverable state.

If more than one copy of any of the processes is run it will be inefficient, but will not corrupt the backup.
