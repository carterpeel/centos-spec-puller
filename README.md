# centos-spec-puller
Pulls all the ".spec" files from https://git.centos.org/ , downloads their sources, then builds them into SRPMs.

## DISCLAIMER: Please note this is NOT a solid method of SRPM retrieval or building. 
It takes forever, is a glorified `for` loop, `shellcheck.org` lights up like a christmas tree, etc. The list could go on. This is merely a testing script I wrote for fun and to help out a colleague.
