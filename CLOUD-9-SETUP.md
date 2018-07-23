1. Make a new workspace (call it `fp-web`), cloning from the
   `Cadasta/fp-web` repo.

2. In the Cloud9 terminal, do:

```
rvm install ruby-2.2.3
gem install bundle
bundle install
mysql-ctl start
```

3. Then replace `config/database.yml` with:

```
development:
  adapter: mysql2
  encoding: utf8
  database: c9
  username: <%=ENV['C9_USER']%>
  host: <%=ENV['IP']%>
```

4. Next, in the terminal, do:

```
bin/rake db:schema:load RAILS_ENV=development
rails server -b $IP -p PORT
```

The Field Papers web app should then be visible at
http://fp-web-ian-ross.c9users.io (based on using my GitHub user name,
`ian-ross`).
