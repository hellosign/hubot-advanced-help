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

## Configuration

No further configuration besides `external-scripts.json` is required in order to get hubot-advanced-help to work.
However, you can optionally disable this script with the environment variable `HUBOT_ADVANCED_HELP_DISABLE`:

```shell
HUBOT_ADVANCED_HELP_DISABLE="true" bin/hubot
```

This is helpful if you want to dynamically control usage of hubot-advanced-help.
Remember that you still need to use `external-scripts.json` regardless of whether the env variable is used.

## Sample Interaction

```
user1>> hubot tags
hubot>> #foo, #bar, #baz, #some-tag
user1>> hubot help #some-tag
hubot>> this is a command tagged with #some-tag
user1>> hubot e.g. #some-tag
hubot>> this is an example tagged with #some-tag
```
