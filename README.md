# docker-yum-mirror

Builds yum package mirrors for you in a containers via a yaml formatted config file.

## config example:

```
---
:hardlink: true
:hardlink_dir: '/mirror'
:mirrors:
  centos-7-x86-64-extras:
    :type: 'reposync'
    :url: 'http://mirrors.tripadvisor.com/centos/7/extras/x86_64/'
    :dest: '/mirror/centos-7-x86_64/extras'
    :datestamp: true
    :link_datestamp: true
  puppetlabs-pc1-7-x86-64:
    :type: 'rsync'
    :url: 'rsync://yum.puppetlabs.com/packages/yum/el/7/PC1/x86_64/'
    :dest: '/mirror/centos-7-x86_64/pc1'
    :datestamp: true
    :link_datestamp: false
  puppetlabs-pc1-6-x86-64:
    :type: 'rsync'
    :url: 'rsync://yum.puppetlabs.com/packages/yum/el/6/PC1/x86_64/'
    :dest: '/mirror/centos-6-x86_64/pc1'
```

## options:

`hardlink` will enabled running hardlink you your repos to save space.
`hardlink_dir` required if `hardlink` is set true, the dir to use for hardlinking (the common parent directory of all the repos you with to hardlink)
`mirrors` A hash of mirror, with the following attributes:

`type` currently `rsync` or `reposync`
`url` the source url to sync, must be a type usable by the `type` specified
`dest` destination of the sync.
`datestamp` boolean to enable moving the `dest` to `dest.YYYY-MM-DD`
`link_datestamp` if datestamp'ing, enabled likning `dest` to `dest.YYYY-MM-DD`

When using `reposync`, we will also do a `createrepo` on the fetched packages. `rsync` gets everything so you'll have the same repodata as the source.
