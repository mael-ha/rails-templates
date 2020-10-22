# Generate new Rails app with Tailwind and Devise
(including tailwind components from https://devdojo.com/tailwindcss/components)

```bash
rails new \
  --database postgresql \
  --webpack \
  -m https://github.com/mael-ha/rails-templates/raw/master/tailwind/devise.rb \
  PROJECT-NAME
```

/!\ CSS to manage in app/javascript/stylesheets instead of app/assets/stylesheets
