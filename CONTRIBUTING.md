# Contributing to the NMEAPlus gem

NMEAPlus uses a very standard GitHub workflow.

1. Fork the repository on github
2. Make your desired changes
3. Push to your personal fork
4. Open a pull request

Pull requests will trigger a Travis CI job.  The following two commands will be expected to pass (so you may want to run them locally before opening the pull request):

 * `coffeelint` - code style tests
 * `npm test` - functional tests

Be prepared to write tests to accompany any code you would like to see merged.


## Code Organization and Operation

A very trivial parser extracts the emoji and macro names, creating a tree of workers (with work functions).  The tree is resolved, converting workers to results.


## Packaging for npm

* Merge pull request with new features
* Bump the version in `package.json`
* Update the sections of `CHANGELOG.md`
* `git add package.json CHANGELOG.md`
* `git commit -m "vVERSION bump"`
* `git tag -a vVERSION -m "Released version VERSION"`
* `npm publish`
* `git push upstream`
* `git push upstream --tags`
