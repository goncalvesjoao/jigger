# Jigger

## Authentication

Uses the Rails authentication generator for sign-in, sign-out, and password resets.
Cocktail browsing is public; creating, editing, and deleting requires sign-in.
New cocktails belong to the signed-in user. Any signed-in user can currently edit
or delete any cocktail; ownership-based authorization is not implemented.

Run `bin/rails db:prepare`, then create an account with `bin/rails console`:

```ruby
User.create!(email_address: "you@example.org", password: "your-password", password_confirmation: "your-password")
```

Visit `/session/new` to sign in. There is no public registration page.
Password reset emails use the application's Action Mailer configuration; configure
production delivery and URL host settings before relying on email resets.

Run the tests with `bin/rails test`.
