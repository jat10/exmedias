## Medias

In order to contribute to grow medias as a dependency you need to follow this guide.

#### Prerequesits

Make sure to have installed on your system these two packages as media relies on [thumbnex](https://github.com/talklittle/thumbnex):

- [ImageMagick](https://imagemagick.org/)
- [FFmpeg](https://ffmpeg.org/)

#### How to contribute

1. Fork the repository

2. You will need to setup two database connections for test environement. Two databases types are needed. So in your `test.exs` add the configuration for your `PostgreSQL` and `MongoDB`:

```elixir
## PostgreSQL
config :media, Media.Repo,
  after_connect: {Postgrex, :query!, ["SET search_path TO media,public", []]},
  username: "testing",
  password: "testing",
  database: "test",
  hostname: "host",
  pool: Ecto.Adapters.SQL.Sandbox

## MongoDB
config :media, :db,
  mongo_url: "mongo_url",
  database: "database",
  mongo_ssl: false,
  port: 8017
```

3. Create Your tests

Create automated tests to cover the feature/fix added to the project.

4. Implement

Add your feature/fix to the code following best practices.

5. Last Step

Before submitting a PR, Make sure to run the following commands:

- Test Coverage:

```elixir
mix coveralls
```

- Code Quality:
```
mix credo --strict
```

If the commands succeed then just submit your PR.

All contributions are welcome!  💻 🎉
