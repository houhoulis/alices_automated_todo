This repo is a slightly-tweaked version of Alice Goldfuss's [automated todo system](https://blog.alicegoldfuss.com/automating-my-todo/). This system allows you to create and manage to-do items using a Kanban system. The automated part uses the text from your completed Kanban cards to create a weekly "release" in your Kanban system, and to send you a summary of the release in a text message.

It sounded both more effective, and easier, than my tendency to keep scraps of lists everywhere.

It's cool that Alice wrote this up! You should read her [writeup](https://blog.alicegoldfuss.com/automating-my-todo) in her blog. She even provides a Python script.

She describes the approach so well, it sounded like something I could implement in a few hours. So I did.

The tweaks I made were the time-consuming parts, and that's why I'm posting this repo. These are the changes I made:

- [update API authentication to GitHub](#update-github-authentication)
- [port Python script to Ruby](#port-to-ruby)
  - rvm wrappers
  - rvm alias
  - crontab entry
- [create a blank release, if necessary](#create-a-blank-release-if-necessary)


## Update GitHub authentication

In order to access the Project via the GitHub REST API†, you need a "personal access token" ([Settings > Developer Settings > Personal access tokens](https://github.com/settings/tokens)). The token needs to have _"repo"_ scope; there's apparently no finer-grained access available.

The tweak I made here is to adhere to a change in GitHub's REST API. GitHub wants access tokens to be passed in an HTTP header now, not in the URL as a query string. (Here's GitHub's [REST API doc](https://docs.github.com/en/rest/overview/resources-in-the-rest-api#authentication) about authentication, and the [blog post](https://developer.github.com/changes/2020-02-10-deprecating-auth-through-query-param/) where they announced the deprecation.)

[Here's](https://github.com/houhoulis/alices_automated_todo/blob/b6cf8cd451fb9bf9a8e22d363f82d5b778325c11/weekly_release.rb#L14) the header: `"Authorization: token <MY_GITHUB_TOKEN>"`. That worked fine, both in `curl` and in my script.


## Port to Ruby

The initial version of my script is [here](https://github.com/houhoulis/alices_automated_todo/blob/b6cf8cd451fb9bf9a8e22d363f82d5b778325c11/weekly_release.rb). This works as a cron job or from the command line, using [`rvm`](https://rvm.io/) to manage the Ruby version and gemset (since I use `rvm`††).


I used rvm wrappers and an rvm alias to make it easier to run the script as a cron job. It was simple, but I hadn't done it before. It's documented well on [rvm's site](https://rvm.io/deployment/cron).

Once I'd created the rvm alias for the ruby version and gemset I'd created for the project, this is the cron job (slightly elided) that I ended up with. It runs at 5pm Fridays:

```
0 17 * * 5 cd PROJECT_DIR && source CREDENTIALS_FILE && ~/.rvm/wrappers/RVM_ALIAS/ruby weekly_release.rb >> cron.log 2>>err.log
```

It works great! The script takes about 2 seconds, and I get a text from Twilio immediately with the summary of what I accomplished for the week.

## Create a blank release if necessary

I don't want to suggest I ever have a week where I don't accomplish any of the tasks on my to-do list. . . but . . .

... If, on Friday at 5pm, there are no cards in the "Done" column, the inital version of my script runs fine -- sort of:

1. The script tries to create a "Release" card using the text of the "Done" cards.
1. There are no "Done" cards, so there is no text to use for the "Release" card.
1. Creating the "Release" card fails, with the GitHub API error _"Note can't be blank"_.
1. The script continues: it sends a text via twilio with only the  "💪🏼  Weekly Release! 🎉" message, and then archives each of the 0 cards in the Done list.

So: there's an API error, there's no "Release" card for the week, and a nearly-blank text is sent.

I've changed the script so that if there are no "Done" cards, it creates a "Release" card and sends a text message saying no progress was made.

## Enjoy!

Check out Alice's [blog post](https://blog.alicegoldfuss.com/automating-my-todo) for more details, including about the decisions she made.

------------------

† _I would have used GitHub's GraphQL API rather than the REST API, but the GraphQL API did not sufficiently support Projects._

†† _I had just switched to using the [fish shell](https://github.com/fish-shell/fish-shell/). In order to use `rvm` in fish, I needed to download this function into `~/.config/fish/functions/`: https://github.com/lunks/fish-nuggets/blob/4986034/functions/rvm.fish_
