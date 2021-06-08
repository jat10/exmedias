defmodule MediaWeb.PageController do
  @moduledoc false
  use MediaWeb, :controller
  alias Media.Helpers

  def index(conn, _params) do
    render(conn, "index.html", layout: {MediaWeb.LayoutView, "app.html"})
  end

  def upload(conn, %{"upload" => %{"file" => file}}) do
    Media.S3Manager.upload_file(
      file.filename,
      file.path,
      Application.get_env(:media, :otp_app) |> Atom.to_string()
    )

    # file |> IO.inspect(label: "FILE")
    # # Get the file's extension
    # file_extension = Path.extname(file.filename) |> IO.inspect(label: "file_extension")

    # # Generate the UUID
    # file_uuid = UUID.uuid4(:hex)

    # # Set the S3 filename
    # s3_filename =
    #   "#{file.filename}-#{file_uuid}#{file_extension}" |> IO.inspect(label: "s3_filename")

    # # The S3 bucket to upload to
    # s3_bucket = Helpers.aws_bucket_name() |> IO.inspect(label: "s3_bucket")

    # # Load the file into memory
    # # {:ok, file_binary} = File.read(file.path)

    # # Upload the file to S3
    # # {:ok, _} =
    # #   ExAws.S3.put_object(s3_bucket, s3_filename, file_binary)
    # #   |> ExAws.request()

    # ## try this later instead
    # file.path
    # |> ExAws.S3.Upload.stream_file()
    # |> ExAws.S3.upload(s3_bucket, s3_filename, timeout: 600_000)
    # |> ExAws.request!()
    # |> IO.inspect(label: "RESULT")

    render(conn |> put_flash(:success, "File uploaded successfully!"), "app.html")
    # put_flash(:success, "File uploaded successfully!")
    # |> render("app.html")
  end
end
