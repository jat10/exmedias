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
    # s3_bucket = Helpers.env(:aws_bucket_name) |> IO.inspect(label: "s3_bucket")

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

  defp update_files(old_files, new_files) do
    # old_files = changeset |> get_field(:files) |> IO.inspect(label: "old files")

    old_ids = old_files |> Enum.map(&Map.get(&1, :file_id))

    {files_to_upload, files_to_persist, ids_to_delete} =
      Enum.reduce(new_files, {[], [], []}, fn {new_file,
                                               {files_to_upload, files_to_persist,
                                                files_ids_to_delete}} ->
        new_id = new_file |> Map.get(:file_id, -1)

        files_to_upload =
          if new_id in old_ids do
            files_ids_to_delete = old_ids -- new_id
            files_to_upload
          else
            files_to_upload ++ new_file
          end

        {files_to_upload, files_to_persist ++ new_file, files_ids_to_delete}
      end)

    files_to_delete = Enum.filter(old_files, &(Map.get(&1, :file_id) in ids_to_delete))
    ## Check which files are removed
    ## if a file is removed deleted from S3
    ## if a file is updated remove the file and download a new one
    ## For comparision rely on ids
    {files_to_delete, files_to_upload, files_to_persist}
  end
end
