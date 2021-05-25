# Media

**Media** is a dependancy to manage, as the name implies, your media. By ``media`` we mean, your files such as documents (pdf, txt etc..), images, videos or podcasts.

  Media stores the actual files on [S3 Amazon service](https://aws.amazon.com/s3/).

## Installation

In your mix.exs add this to your list of dependancies:

```elixir
{:media, "~> 0.1.0"}
```
Now in your ``config.exs`` add the following: 

  ```elixir
  config :media,
    otp_app: :your_app,
    active_database: "mongoDB",
    repo: :mongo,
    router: YouAppWeb.Router,
    aws_bucket_name: "your_bucket",
    aws_role_name: "you_role_to_assume_arn",
    aws_iam_id: "403016165142" ## the IAM user id,
    content_schema: Blogs.Schema.Article,
    content_table: "blogs" ## in case the db used is a postgreSQL
  ```
   ``active_database``: the database your project is using accepted values are: "mongoDB" or "postgreSQL"
  ``repo``: The mongodb application name or the repo module in case it's a postgreSQL based project i.e ``YourApp.Repo``.

  The content is what your media will be related too. Let's consider having articles table that needs videos,images or even podcasts to have a clean article rendered for your applciation. In this case the articles are considered as the ``content`` for **Media**.

In case your project relies on a ``MongoDB``, in your  ``application.ex`` file add this tuple to the children list inside the ``start`` function:
  ```elixir
  {
  Task,
    fn ->
      Media.Helpers.create_collections()
    end
  }
  ```

  Before running your project perform the following mix commands:

  - ``MongoDB`` project: mix media.setup
  - ``PostgreSQL`` project: mix media.setup && mix ecto.migrate
  