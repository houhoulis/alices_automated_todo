This repo is a slightly-tweaked version of Alice Goldfuss's [automated todo system](https://blog.alicegoldfuss.com/automating-my-todo/). This system allows you to create and manage to-do items using a Kanban system. The automated part creates weekly "releases" in your Kanban system, and sends you a summary of the release in a text.

It's cool that Alice wrote this up! You should read her [writeup](https://blog.alicegoldfuss.com/automating-my-todo) in her blog. She even provides a Python script.

She describes the benefits and the approach so well, it sounded like something I could do in a few hours. Which I did.

The tweaks I made were the time-consuming parts, and that's why I'm posting this repo. These are the changes I made:

- [update API authentication to GitHub](#update-authentication)
- [port Python script to Ruby](#port-to-ruby)
  - rvm wrappers
  - rvm alias
  - crontab entry
- [create a blank release, if necessary](#create-a-blank-release-if-necessary)


## Update authentication

In order to access the Project via the GitHub REST API†, you need a "personal access token" ([Settings > Developer Settings > Personal access tokens](https://github.com/settings/tokens)). The token needs to have _"repo"_ scope; there's apparently no finer-grained access available.

The tweak I made here is due to the fact that GitHub wants access tokens to be passed in an HTTP header now, not in the URL as a query string. (GitHub's [REST API doc](https://docs.github.com/en/rest/overview/resources-in-the-rest-api#authentication) and [blog post](https://developer.github.com/changes/2020-02-10-deprecating-auth-through-query-param/).)

[Here's](b6cf8cd451fb9bf9a8e22d363f82d5b778325c11/weekly_release.rb#L14) the header: `"Authorization: token <MY_GITHUB_TOKEN>"`. That worked fine.


## Port to Ruby

My original version of the script is [here](https://github.com/houhoulis/alices_automated_todo/blob/b6cf8cd451fb9bf9a8e22d363f82d5b778325c11/weekly_release.rb). This works fine from the command-line, using an [`rvm`](https://rvm.io/) ruby and gemset (since I use `rvm`††).


To run the script as a cron job, I used rvm wrappers and an rvm alias. It was simple, but I hadn't done it before. It's documented well on [rvm's site](https://rvm.io/deployment/cron).

Once I'd created the rvm alias for the ruby version and gemset, this is the (significantly elided) cron job I ended up with. It runs at 5pm Fridays:

```
0 17 * * 5 source CREDENTIALS_FILE && ~/.rvm/wrappers/RVM_ALIAS/ruby ./weekly_release.rb >> ./cron.log 2>>./err.log
```

It works great! The script takes about 2 seconds, and I get a text from Twilio immediately with the summary of what I accomplished.

## Create a blank release if necessary

I don't want to say I ever have weeks where I don't accomplish any of the tasks on my to-do list...................

My [inital script](b6cf8cd451fb9bf9a8e22d363f82d5b778325c11/weekly_release.rb) runs fine, for some definitions of "fine", if there are no cards in the "Done" column. The script tries to create a "Release" card using the text of the "Done" cards. This fails with the error _"Note can't be blank"_ if there are no cards. The script continues: it sends a text via twilio, and then archives each of the 0 cards in the Done list. So, a blank test is sent, and no changes are made to the Project.

I wanted to create a "release" indicating no progress was made, rather than 1) erroring via the GitHub API and 2) sending a blank text.

------------------

† _I would have used GitHub's GraphQL API rather than the REST API, but the GraphQL API did not sufficiently support Projects._

†† _I had just switched to using the [fish shell](https://github.com/fish-shell/fish-shell/). In order to use `rvm` in fish, I needed to download this function into `~/.config/fish/functions/`: https://github.com/lunks/fish-nuggets/blob/4986034/functions/rvm.fish_
