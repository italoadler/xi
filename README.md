# Xi  [![Build Status](https://travis-ci.org/xi-livecode/xi.svg?branch=master)](https://travis-ci.org/xi-livecode/xi)

Xi (pronounced /ˈzaɪ/) is a musical pattern language inspired in Tidal and
SuperCollider for building higher-level musical constructs easily.  It is
implemented on the Ruby programming language.

Xi is only a patterns library, but can talk to different backends:

- [SuperCollider](https://github.com/supercollider/supercollider)
- MIDI devices

*NOTE*: Be advised that this project is in very early alpha stages. There are a
multiple known bugs, missing features, documentation and tests.

## Example

```ruby
melody = [1,4,7,8,9]
scale = [Scale.iwato, Scale.jiao]

fm.set degree: melody.p(1/2,1/8,1/8,1/8,1/16,1/8,1/8).seq(2),
       gate: :degree,
       detune: [0.1, 0.4, 0.4],
       sustain: [1,2,3,10],
       accelerate: [0.5, 0, 0.1],
       octave: [3,4,5,6].p(1/3),
       scale: scale.p(1/2),
       amp: P.new { |y| y << rand * 0.2 + 0.8 }.p(1/2)

kick.set freq: s("xi.x .ix. | xi.x xx.x", 70, 200), amp: 0.8, gate: :freq

clap.set n: s("..x. xyz. .x.. .xyx", 60, 61, 60).p.decelerate(2),
         gate: :n,
         amp: 0.35,
         pan: P.sin(16, 2) * 0.6,
         sustain: 0.25
```

## Installation

### Quickstart

You will need Ruby 2.1+ installed on your system.  Check by running `ruby
-v`.  To install Xi you must install the core libraries and REPL, and then one
or more backends.

If you want to use Xi with SuperCollider:

    $ gem install xi-lang xi-supercollider

Or with MIDI:

    $ gem install xi-lang xi-midi

Then run Xi REPL with:

    $ xi

There is a configuration file that is written automatically for you when run
for the first time at `~/.config/xi/init.rb`. You can add require lines and
define all the function helpers you want.

### Repository

Becase Xi is still in **alpha** stage, you might want to clone the repository
using Git instead:

    $ git clone https://github.com/xi-livecode/xi

After that, change into the new directory and install gem dependencies with
Bundler.  If you don't have Bundler installed, run `gem install bundler` first.
Then:

    $ cd xi
    $ bundle install
    $ rake install

You're done! Fire up the REPL using `xi`.

## Development

After checking out the repo, run `bundle` to install dependencies. Then, run
`rake test` to run the tests.

To install this gem onto your local machine, run `bundle exec rake install`. To
release a new version, update the version number in `version.rb`, and then run
`bundle exec rake release`, which will create a git tag for the version, push
git commits and tags, and push the `.gem` file to
[rubygems.org](https://rubygems.org).

You can also try things on the REPL without installing the gem on your machine
by doing `bundle exec bin/xi`.

## Contributing

Bug reports and pull requests are welcome on GitHub at
https://github.com/xi-livecode/xi. This project is intended to be a safe,
welcoming space for collaboration, and contributors are expected to adhere to
the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The MIT License (MIT)

Copyright (c) 2017 Damián Emiliano Silvani

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
