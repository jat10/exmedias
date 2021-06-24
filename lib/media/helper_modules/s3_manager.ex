defmodule Media.S3Manager do
  @moduledoc """
    This module is responsible for uploading, deleting, updating or reading files
    from S3 configured bucket.
  """
  alias ExAws.{S3, S3.Upload, STS}
  alias Media.Helpers

  def upload_file(filename, path) do
    ext =
      filename
      |> Path.extname()

    filename = filename |> Path.basename(ext)

    aws_filename =
      "#{Application.get_env(:media, :otp_app)}/#{filename}#{
        ext
        |> unique_filename()
      }"

    ## for test mocking purposes
    __MODULE__.upload(path, aws_filename)
  end

  def upload_thumbnail(filename, path) do
    filename = thumbnail_filename(filename)

    __MODULE__.upload(path, filename)
  end

  def thumbnail_filename(filename) do
    path_list = filename |> Path.split()
    filename = path_list |> Enum.at(-1)
    ext = filename |> Path.extname()

    path_list
    |> List.replace_at(-1, "#{filename |> Path.basename(ext)}_thumbnail#{ext}")
    |> Path.join()
  end

  def upload(path, filename) do
    if Helpers.test_mode?() do
      aws =
        path
        |> Upload.stream_file()
        |> S3.upload(
          Helpers.aws_bucket_name(),
          filename,
          content_type: MIME.from_path(filename)
        )
        |> send_request()

      case aws.status_code do
        200 ->
          # File.rm!(filename)

          %{
            "CompleteMultipartUploadResult" => %{
              "Location" => url,
              "Key" => name,
              "ETag" => id,
              "Bucket" => bucket
            }
          } = aws.body |> XmlToMap.naive_map()

          {:ok, %{id: id, filename: name, url: url, bucket: bucket}}

        _ ->
          {:error, "Unable to upload file to amazon"}
      end
    else
      {:ok,
       %{
         id: "fake_file_id",
         filename: "fake_filename",
         url: "https://www.fake-url.com",
         bucket: "fake-bucket"
       }}
    end
  end

  def delete_file(path) do
    Helpers.aws_bucket_name()
    |> S3.delete_object(path)
    |> send_request()
  end

  def get_file(filename) do
    aws =
      Helpers.aws_bucket_name()
      |> S3.list_objects(prefix: filename)
      |> send_request()

    case aws.status_code do
      200 ->
        %{
          contents: contents
        } = aws.body

        fetch_file(contents)

      _ ->
        {:error, "File not found"}
    end
  end

  def fetch_file([]) do
    {:error, "File not found"}
  end

  def fetch_file(contents) do
    file = hd(contents)
    bucket = Helpers.aws_bucket_name()
    path = "https://s3.amazonaws.com/#{bucket}/#{file.key}"
    {:ok, %{id: file.e_tag, filename: file.key, path: path, bucket: bucket}}
  end

  defp unique_filename(extension) do
    UUID.uuid4(:hex) <> extension
  end

  def get_temporary_aws_credentials(profile_id) do
    resp =
      STS.assume_role(
        "arn:aws:iam::" <>
          Application.get_env(:media, :aws_iam_id) <>
          ":role/" <> Application.get_env(:media, :aws_role_name),
        "#{profile_id}"
      )

    {:ok, resp} = resp |> send_request()

    %{
      access_key: resp.body.access_key_id,
      secret_key: resp.body.secret_access_key,
      session_token: resp.body.session_token
    }
  end

  def send_request(req) do
    case ExAws.request(req, Helpers.aws_config()) do
      {:ok, response} -> response
      error -> error
    end
  end

  @doc """
  This function toggles the object privacy.
  It takes the object key as a first argument and the new privacy status as a second argument
  The object key is the object filename.
  """
  def change_object_privacy(object_key, "public") do
    change_privacy(object_key, :public_read)
  end

  def change_object_privacy(object_key, "private") do
    change_privacy(object_key, :private)
  end

  def change_object_privacy(object_key, _) do
    change_privacy(object_key, :private)
  end

  defp change_privacy(object_key, acl_permission) do
    if Helpers.test_mode?() do
      {:ok,
       S3.put_object_acl(
         Application.get_env(:media, :aws_bucket_name),
         object_key,
         [{:acl, acl_permission}]
       )
       |> send_request()}
    else
      {:ok, :done}
    end
  end

  def read_private_object(credentials, destination) do
    url = "https://#{Helpers.aws_bucket_name()}.s3.amazonaws.com/#{destination}?Action=GetObject"
    headers = %{"X-Amz-Secure-Token" => credentials.session_token}

    {:ok, %{} = sig_data, _} =
      Sigaws.sign_req(url,
        region: Application.get_env(:ex_aws, :region) || "us-east-1",
        service: "s3",
        headers: headers,
        access_key: Application.get_env(:ex_aws, :access_key_id),
        secret: Application.get_env(:ex_aws, :secret_access_key)
      )

    headers =
      Map.merge(headers, sig_data)
      |> Map.delete("X-Amz-SignedHeaders")
      |> Map.delete("X-Amz-Algorithm")

    %{url: url, headers: headers}
  end
end
