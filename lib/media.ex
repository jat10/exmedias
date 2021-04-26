defmodule Media do
  @moduledoc """
  **Media** is a dependancy to manage, as the name implies, your media. By ``media`` we mean, your files such as documents (pdf, txt etc..), images, videos or podcasts.

  Media stores the actual files on [S3 Amazon service](https://aws.amazon.com/s3/).

  ## Installation

  ## Configuration

  ```elixir
  config :media,
    otp_app: :your_app,
    active_database: "mongoDB",
    repo: :mongo,
    router: YouAppWeb.Router,
    aws_bucket_name: "your_bucket",
    aws_role_name: "you_role_to_assume_arn",
    aws_iam_id: "403016165142" ## the IAM user id
  ```
  ``active_database``: the database your project is using accepted values are: "mongoDB" or "postgreSQL"
  ``repo``: The mongodb application name or the repo module in case it's a postgreSQL based project i.e ``YourApp.Repo``.
  """
end
