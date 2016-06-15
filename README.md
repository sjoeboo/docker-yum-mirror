# docker-yum-mirror

Builds yum package mirrors for you in a containers via a yaml formatted config file.

Why?

In a few environments I've worked in, we've needed local yum mirrors, but needed to not only have up-to-date copies of them, but also point-in-time snapshots of some/all of them (HPC systems, kernel bound filesystems, etc. Basically, be able to bring up 1000s of systems "updated" to the exact same version of all RPMS.)

So, this container + script will help do this. It takes a config file and a directory mounted into it, and supports mirrors using rsync or reposync (and thus, anything yum itself can use).

## Features

* Supports rsync or reposync
* Can create a large 'all' repo (all pacakges form all repos, smushed together + generated repodata)
* This 'all' repo can be snapshot'ed, to remain frozen in time.
* Likewise, individual repos can be snapshot'd, freezing them in time.
* These 'snaps' are datestamped, and created (optionally) via hardlinks, to be space efficient.
* hardlink (the program) is also used to file-level de-dupe your repos.

A resulting directory structure may look like:

```
- /mirror/
|__ centos-7-x86_64/
  |__all
  |__all.2016-06-14
  |__os
  |__updates
|__ centos-6_x86_64/
  ...
```
all would be `all` the rpms from os + updates, as hardlinks. `all.2016-06-14` would be what `all` looked like on that date, all hardlinks to save space. `os` and `updates` would be mirrors of the  upstream repos.

In production i would, most likley, enable all+datestamp_all, do a sync, then disable then until i wanted to make another snapshot. subsequent runs would sync upstream, but leave teh datestamped 'all' directory as is.


## Usage

```
docker run -v /path/to/storage:/mirror -v /path/to/config.yaml:/config.yaml sjoeboo/docker-yum-mirror:latest
```

## config example:

```
---
:hardlink: true
:hardlink_dir: '/mirror'
:all: true
:all_name: 'all'
:datestamp_all: true
:mirror_base: '/mirror'
mirrors:
  os:
    :dist: 'centos-7-x86_64'
    :type: 'rsync'
    :url: 'rsync://mirrors.kernel.org/centos/7/os/x86_64/'
  extras:
    :dist: 'centos-7-x86_64'
    :type: 'rsync'
    :url: 'rsync://mirrors.kernel.org/centos/7/extras/x86_64/'
    :datestamp: true
    :hardlink_datestamp: true
  plus:
    :dist: 'centos-7-x86_64'
    :type: 'reposync'
    :url: 'http://mirrors.kernel.org/centos/7/centosplus/x86_64/'
    :dest: '/some/other/location/'
    :datestamp: true
    :link_datestamp: true
```

Lets dive into the above config a little, it would:

* Create mirrors in `/mirror/centos-7-x86_64` (since centos-7-x86_64 is the `dist` for the mirrors listed)
* Except for `plus` which would be created elsewhere `(dist the then ignored)`
* `plus` would, after being sync'd, be moved to `plus.YYYY-MM-DD`, with `plus` becoming a symbloic link to `plus.YYYY-MM-DD`
* `extras` would, after getting sync'd, have `extras.YYYY-MM-DD` created, as a tree of hardlinks back to `extras`. You could do this on multiple days to have multiple space efficent snapshots for `extras` as well as track upstream.
* additionally, a `all` repo, named `all` would be created, containing al of the rpms from each `dist` listed. It would also have a hardlink tree created `all.YYYY-MM-DD`
* finally, the `hardlink` program would be run on ``/mirror` to file-level de-dup the rpms.

The above config is....silly. I can't think of why one would want to datestamp all AND individual repos, but, you could. I would either datestamp `all`, or, datestamp individual repos and not create an `all` whatsoever.


## options

`:hardlink:` Boolean. Should we run hardlink at the end to try to find duplicates. Default: true
`:hardlink_dir:` String. What directory to run hardlink on Default: /mirror
`:all:` true Boolean. Create an 'all' repo. Default: true
`:all_name:` String. name for all repo. Default: all
`:datestamp_all:` Boolean. To make a hardlinked, datestamped copy of 'all'. Default True.
`:mirror_base:` String. Base directory to use to create destinations, `dist` will be appended. Default: /mirror
`:mirrors:` Hash. List of mirrors to create.
Format/parameters are:


```
name: (name of repo, will be appended to mirror_base + dist unless dest is specified)
  :dist: (distribution, whatever you want, basically, a grouping of repos. Appended to mirror_base unless dest is specified. Also how 'all' is created/grouped.)
  :type: (rsync or reposync)
  :url: (url to sync from. rsync:// for rsync, something yum supports for reposync)
  :datestamp: (Boolean, should a datestamped copy be made)
  :hardlink_datestamp: (Boolean, should that copy be made of hardlinks)
  :link_datestamp: (Should the original repo be turned into a link to the most recent datestamped version)
```
