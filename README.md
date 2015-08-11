# hubot-advanced-help

A hubot help replacement that supports #hashtags

See [`src/advanced-help.coffee`](src/advanced-help.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-advanced-help --save`

Then add **hubot-advanced-help** to your `external-scripts.json`:

```json
[
  "hubot-advanced-help"
]
```

## Sample Interaction

```
user1>> hubot tags
hubot>> #foo, #bar, #baz, #some-tag
user1>> hubot help #some-tag
hubot>> this is a command tagged with #some-tag
user1>> hubot e.g. #some-tag
hubot>> this is an example tagged with #some-tag
```
