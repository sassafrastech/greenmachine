# GreenMachine

Redmine Plugin for Sassafras Billing.

## Development

### Set up Redmine

1. Follow the instructions [here](https://github.com/sassafrastech/redmine/)

### Set up GreenMachine

1. Download GreenMachine as a plugin to Redmine (see Redmine instructions above)
1. `cp lib/secrets.rb.example lib/secrets.rb` and configure
1. It should "just work" when you run the Redmine server

### QuickBooks Sandbox

#### Setup

1. Create a test app [here](https://developer.intuit.com/app/developer/myapps)
1. Create a sandbox company [here](https://developer.intuit.com/app/developer/sandbox)
1. From your test app (the app, not the company), visit **Development > Keys & OAuth**
1. Under Redirect URIs, add `http://localhost:3000/green-machine/quickbooks/callback`
    - Replace `localhost:3000` with whatever URL you hit when developing locally; it must match exactly, including the trailing slash
1. Copy the keys into `secrets.rb`

#### Server flags

Run with `QB_SANDBOX_MODE=1 RAILS_ENV=production rails s` to use a sandboxed QB app.
