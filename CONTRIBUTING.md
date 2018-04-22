# Contributing to the Macramoji NPM package

Macramoji uses a very standard GitHub workflow.

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

The basic unit of image processing is the `ImageResult`.  New emoji functions take some number of `ImageResult`s as arguments (which are automatically set to be the same size).  They are automatically cleaned up afterward, although you should ensure that intermediate results are added to the final result.

ImageResults can contain errors, and the `ImageWorker` propagates these along if they arise.


## Debugging tips

* Some files have `debug = false` in them, which can be set to true for extra console logging messages.  Stop piping test output to `faucet` in order to see those.
* Specifying a directory in the environment variable `MACRAMOJI_DEBUG_TMP` will create temp images there (instead of in `/tmp`), and not delete them after the test has completed.  The filenames will also be sequential, which can aid in troubleshooting GM.


## Packaging for npm

Note to the maintainer

* Merge pull request with new features
* `git stash save`
* `git pull --rebase`
* Bump the version in `package.json`
* Update the sections of `CHANGELOG.md`
* `git add package.json CHANGELOG.md`
* `git commit -m "vVERSION bump"`
* `git tag -a vVERSION -m "Released version VERSION"`
* `npm publish`
* `git stash pop`
* `git pull --rebase`
* `git push upstream --tags`
