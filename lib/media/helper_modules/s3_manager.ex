defmodule Media.S3Manager do
  @moduledoc """
    This module is responsible for uploading, deleting, updating or reading files
    from S3 configured bucket.
  """
  alias ExAws.{S3, S3.Upload, STS}
  alias Media.Helpers

  def upload_file(filename, path, destination) do
    # File.write!(filename, Base.decode64!(file))
    aws =
      path
      # |> File.stream!()
      |> Upload.stream_file()
      |> S3.upload(
        Helpers.env(:aws_bucket_name),
        "#{destination}/#{filename}#{
          filename
          |> Path.extname()
          |> unique_filename()
        }",
        content_type: MIME.from_path(filename)
      )
      |> ExAws.request!()

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
  end

  def delete_file(path) do
    Helpers.env(:aws_bucket_name)
    |> S3.delete_object(path)
    |> ExAws.request!()
  end

  def get_file(filename) do
    aws =
      Helpers.env(:aws_bucket_name)
      |> S3.list_objects(prefix: filename)
      |> ExAws.request!()

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
    bucket = Helpers.env(:aws_bucket_name)
    path = "https://s3.amazonaws.com/#{bucket}/#{file.key}"
    {:ok, %{id: file.e_tag, filename: file.key, path: path, bucket: bucket}}
  end

  defp unique_filename(extension) do
    UUID.uuid4(:hex) <> extension
  end

  defp fetch_extension(file) do
    file
    |> Base.decode64!()
    |> image_extension()
  end

  # Helper functions to read the binary to determine the image extension
  defp image_extension(<<0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, _::binary>>), do: ".png"
  defp image_extension(<<0xFF, 0xD8, _::binary>>), do: ".jpg"

  defp image_extension(_), do: ""

  def upload_file_base64(file, destination) do
    file
    |> fetch_extension()
    |> unique_filename()
    |> upload_file_base64(file, destination)
  end

  def upload_file_base64(filename, image_base64, destination) do
    image_bucket = Helpers.env(:aws_bucket_name)
    image_binary = Base.decode64!(image_base64)

    image_bucket
    |> S3.put_object("#{destination}/#{filename}", image_binary)
    |> ExAws.request!()
    |> case do
      %{status_code: 200, body: _body} ->
        # %{
        #   "CompleteMultipartUploadResult" => %{
        #     "Location" => path,
        #     "Key" => name,
        #     "ETag" => id,
        #     "Bucket" => bucket
        #   }
        # } = body |> XmlToMap.naive_map()
        path = "https://#{image_bucket}.s3.amazonaws.com/#{destination}/#{filename}"
        # {:ok, %{id: id, filename: name, path: path, bucket: bucket}}
        {:ok, %{url: path}}

      _ ->
        {:error, "Unable to upload file to amazon"}
    end
  end

  def get_temporary_aws_credentials(profile_id) do
    resp =
      STS.assume_role(
        "arn:aws:iam::" <>
          Application.get_env(:media, :aws_iam_id) <>
          ":role/" <> Application.get_env(:media, :aws_role_name),
        "#{profile_id}"
      )

    {:ok, resp} = resp |> ExAws.request()

    %{
      access_key: resp.body.access_key_id,
      secret_key: resp.body.secret_access_key,
      session_token: resp.body.session_token
    }
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

  defp change_privacy(object_key, acl_permission) do
    S3.put_object_acl(
      Application.get_env(:media, :aws_bucket_name),
      object_key,
      [{:acl, acl_permission}]
    )
    |> ExAws.request!()
  end

  def read_private_object(credentials, destination) do
    url = "https://eweevtestbucketprivate.s3.amazonaws.com/#{destination}?Action=GetObject"
    # url = "https://s3.amazonaws.com/Action=GetObject"
    headers = %{"X-Amz-Secure-Token" => credentials.session_token}

    {:ok, %{} = sig_data, _} =
      Sigaws.sign_req(url,
        region: Application.get_env(:ex_aws, :region) || "us-east-1",
        service: "s3",
        headers: headers,
        access_key: Application.get_env(:ex_aws, :access_key_id),
        secret: Application.get_env(:ex_aws, :secret_access_key)
      )

    ## TO DO we don't need to actually get the object
    ## we only need to send the url headers and params to the front
    HTTPoison.get(
      url,
      Map.merge(headers, sig_data)
      |> Map.delete("X-Amz-SignedHeaders")
      |> Map.delete("X-Amz-Algorithm")
    )
  end
end
