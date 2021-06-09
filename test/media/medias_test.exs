# defmodule Media.MediasTest do
#   use Media.DataCase
#   alias Media.{Helpers, MongoDB, PostgreSQL, S3Manager, TestHelpers}
#   alias Media.Test.Contents
#   import Mock
#   @mongoDB "mongoDB"
#   @update_attrs %{
#     title: "some updated title",
#     author: "some updated author",
#     locked_status: "unlocked",
#     private_status: "public"
#   }
#   setup_with_mocks([
#     {Helpers, [:passthrough],
#      youtube_video_details: fn _url ->
#        {:ok, %{"items" => [%{"contentDetails" => %{"duration" => "PT4M30S"}}]}}
#      end},
#     {S3Manager, [:passthrough],
#      upload_file: fn file_name, _path, aws_bucket_name ->
#        {:ok,
#         %{
#           bucket: aws_bucket_name,
#           filename: "#{file_name <> TestHelpers.uuid()}",
#           id: "#{TestHelpers.uuid()}",
#           url: "some url"
#         }}
#      end,
#      change_object_privacy: fn _file_name, _privacy ->
#        {:ok, %{}}
#      end,
#      get_temporary_aws_credentials: fn _unique_id ->
#        %{
#          access_key: "access_key_id",
#          secret_key: "secret_access_key",
#          session_token: "session_token"
#        }
#      end,
#      read_private_object: fn _credentials, _destination ->
#        %{
#          url: "private url",
#          headers: %{}
#        }
#      end,
#      delete_file: fn _filename ->
#        {:ok, %{}}
#      end}
#   ]) do
#     :ok
#   end

#   describe "Medias CRUD with PostgreSQL" do
#     alias Media.Helpers

#     # alias Media.Platforms.Platform

#     @platform_valid_attrs %{
#       description: "some description",
#       height: 42,
#       name: "some name",
#       width: 42
#     }

#     @valid_attrs %{
#       author: "some author id",
#       locked_status: "locked",
#       private_status: "public",
#       seo_tag: "some seo tag",
#       tags: ["tag1", "tag2"],
#       title: "some media title",
#       type: "image"
#     }

#     @invalid_attrs_author %{
#       author: nil,
#       locked_status: "locked",
#       private_status: "public",
#       seo_tag: "some seo tag",
#       tags: ["tag1", "tag2"],
#       title: "some media title",
#       type: "video"
#     }
#     @invalid_attrs_type %{
#       author: "some author id",
#       locked_status: "locked",
#       private_status: "public",
#       seo_tag: "some seo tag",
#       tags: ["tag1", "tag2"],
#       title: "some media title",
#       type: "what is this media?"
#     }

#     setup_with_mocks([
#       {Helpers, [:passthrough],
#        db_struct: fn args -> struct(%PostgreSQL{}, %{args: args}) end, repo: fn -> Media.Repo end}
#     ]) do
#       :ok
#     end

#     test "list_medias/0 returns all medias (not paginated)" do
#       TestHelpers.set_repo(Media.Repo, "postgreSQL")

#       # with_mock Helpers, [:passthrough], repo: fn -> Media.Repo end do
#       platform = create_platform()

#       files = [
#         %{
#           type: "video",
#           filename: "video.mp4",
#           url: "http://url.com",
#           duration: 240,
#           size: 4_000_000,
#           platform_id: platform.id,
#           file_id: TestHelpers.uuid()
#         }
#       ]

#       media_fixture(%{files: files})

#       platform_id = platform.id

#       assert %{
#                result: [
#                  %{
#                    author: "some author id",
#                    files: [
#                      %{
#                        id: _fileid,
#                        duration: 240,
#                        filename: "video.mp4",
#                        platform: %{
#                          description: "some description",
#                          height: 42,
#                          id: ^platform_id,
#                          # inserted_at: "2021-05-25T13:07:48",
#                          name: "some name",
#                          # updated_at: "2021-05-25T13:07:48",
#                          width: 42
#                        },
#                        platform_id: ^platform_id,
#                        size: 4_000_000,
#                        type: "video",
#                        url: "http://url.com"
#                      }
#                    ],
#                    id: _id,
#                    locked_status: "locked",
#                    number_of_contents: 0,
#                    private_status: "public",
#                    seo_tag: "some seo tag",
#                    tags: ["tag1", "tag2"],
#                    title: "some media title",
#                    type: "video"
#                  }
#                ],
#                total: 1
#              } = Media.Context.list_medias()

#       # end
#     end

#     test "list_medias/0 returns all medias (paginated)" do
#       TestHelpers.set_repo(Media.Repo, "postgreSQL")

#       # with_mock Helpers, [:passthrough], repo: fn -> Media.Repo end do
#       platform = create_platform()

#       files = [
#         %{
#           type: "video",
#           filename: "video.mp4",
#           url: "http://url.com",
#           duration: 240,
#           size: 4_000_000,
#           platform_id: platform.id,
#           file_id: TestHelpers.uuid()
#         }
#       ]

#       media0 = media_fixture(%{files: files})
#       media1 = media_fixture(%{files: files, title: "Media Title 1"})
#       media2 = media_fixture(%{files: files, title: "Media Title 2"})

#       media_id_0 = media0.id
#       media_title_0 = media0.title

#       assert %{result: [%{id: ^media_id_0, title: ^media_title_0}], total: 3} =
#                Media.Context.list_medias(%{per_page: 1, page: 1})

#       media_id_1 = media1.id
#       media_title_1 = media1.title

#       assert %{result: [%{id: ^media_id_1, title: ^media_title_1}], total: 3} =
#                Media.Context.list_medias(%{per_page: 1, page: 2})

#       media_id_2 = media2.id
#       media_title_2 = media2.title

#       assert %{result: [%{id: ^media_id_2, title: ^media_title_2}], total: 3} =
#                Media.Context.list_medias(%{per_page: 1, page: 3})
#     end

#     test "list_medias/0 returns all medias (filtered)" do
#       TestHelpers.set_repo(Media.Repo, "postgreSQL")

#       # with_mock Helpers, [:passthrough], repo: fn -> Media.Repo end do
#       platform = create_platform()

#       image_file = [
#         %{
#           type: "jpeg",
#           filename: "image.jpeg",
#           url: "http://url.com",
#           size: 4_000_000,
#           platform_id: platform.id,
#           file_id: TestHelpers.uuid()
#         }
#       ]

#       files = [
#         %{
#           file: %Plug.Upload{
#             path: "test/fixtures/phoenix.png",
#             filename: "phoenix.png",
#             content_type: "image/png"
#           },
#           platform_id: platform.id
#         }
#       ]

#       media_fixture(%{files: files})

#       media1 =
#         media_fixture(%{
#           files: image_file,
#           title: "Media Title 1",
#           type: "image",
#           locked_status: "unlocked"
#         })

#       media2 = media_fixture(%{files: files, title: "Media Title 2", private_status: "private"})

#       ## FILTER BY TITLE
#       media_id_2 = media2.id
#       media_title_2 = media2.title

#       assert %{result: [%{id: ^media_id_2, title: ^media_title_2}], total: 1} =
#                Media.Context.list_medias(%{filters: [%{key: "title", value: "Media Title 2"}]})

#       media_id_1 = media1.id
#       media_title_1 = media1.title
#       ## type of media
#       assert %{result: [%{id: ^media_id_1, title: ^media_title_1}], total: 1} =
#                Media.Context.list_medias(%{filters: [%{key: "type", value: "image"}]})

#       ## number of contents
#       assert %{result: _res, total: 3} =
#                Media.Context.list_medias(%{
#                  filters: [%{key: "number_of_contents", value: 0, operation: "="}]
#                })

#       ## filter by private_status
#       assert %{total: 1} =
#                Media.Context.list_medias(%{
#                  filters: [%{key: "private_status", value: "private"}]
#                })

#       ## filter by lock_status
#       assert %{total: 1} =
#                Media.Context.list_medias(%{
#                  filters: [%{key: "locked_status", value: "unlocked"}]
#                })
#     end

#     test "get_media/1 returns the media with given id" do
#       TestHelpers.set_repo(Media.Repo, "postgreSQL")

#       # with_mock Helpers, [:passthrough], repo: fn -> Media.Repo end do
#       platform = create_platform()

#       files = [
#         %{
#           file: %Plug.Upload{
#             path: "test/fixtures/phoenix.png",
#             filename: "phoenix.png",
#             content_type: "image/png"
#           },
#           platform_id: platform.id
#         }
#       ]

#       media = media_fixture(%{files: files})

#       platform_id = platform.id

#       assert {:ok,
#               %{
#                 author: "some author id",
#                 files: [
#                   %{
#                     filename: _filename,
#                     platform: %{
#                       description: "some description",
#                       height: 42,
#                       id: ^platform_id,
#                       # inserted_at: "2021-05-25T13:07:48",
#                       name: "some name",
#                       # updated_at: "2021-05-25T13:07:48",
#                       width: 42
#                     },
#                     platform_id: ^platform_id,
#                     size: _size,
#                     type: "image/png",
#                     url: _url
#                   }
#                 ],
#                 id: _id,
#                 locked_status: "locked",
#                 number_of_contents: 0,
#                 private_status: "public",
#                 seo_tag: "some seo tag",
#                 tags: ["tag1", "tag2"],
#                 title: "some media title",
#                 type: "image"
#               }} = Media.Context.get_media(media.id)

#       # end
#     end

#     test "get_media/1 with invalid ID" do
#       TestHelpers.set_repo(Media.Repo, "postgreSQL")

#       assert {:error, :not_found, _} = Media.Context.get_media(0)
#       assert {:error, _errormessage} = Media.Context.get_media("asd")
#     end

#     test "create_media/1 with valid data creates a media" do
#       TestHelpers.set_repo(Media.Repo, "postgreSQL")

#       platform = create_platform()

#       files = [
#         %{
#           file: %Plug.Upload{
#             path: "test/fixtures/phoenix.png",
#             filename: "phoenix.png",
#             content_type: "image/png"
#           },
#           platform_id: platform.id
#         }
#       ]

#       files_to_retreive = [
#         files |> Enum.at(0) |> Map.put(:platform, platform)
#       ]

#       media =
#         media_fixture(%{files: files})
#         |> Map.put(:files, files_to_retreive)
#         |> Map.put(:number_of_contents, 0)

#       platform_id = platform.id

#       assert {:ok,
#               %{
#                 author: "some author id",
#                 files: [
#                   %{
#                     duration: 240,
#                     filename: "video.mp4",
#                     platform: %{
#                       description: "some description",
#                       height: 42,
#                       id: ^platform_id,
#                       # inserted_at: "2021-05-25T13:07:48",
#                       name: "some name",
#                       # updated_at: "2021-05-25T13:07:48",
#                       width: 42
#                     },
#                     platform_id: ^platform_id,
#                     size: 4_000_000,
#                     type: "mp4",
#                     url: "http://url.com"
#                   }
#                 ],
#                 id: _id,
#                 locked_status: "locked",
#                 number_of_contents: 0,
#                 private_status: "public",
#                 seo_tag: "some seo tag",
#                 tags: ["tag1", "tag2"],
#                 title: "some media title",
#                 type: "video"
#               }} = Media.Context.get_media(media.id)
#     end

#     test "create_media/1 with invalid data returns error changeset" do
#       TestHelpers.set_repo(Media.Repo, "postgreSQL")

#       platform = create_platform()

#       ## no duration provided
#       files = [
#         %{
#           type: "mp4",
#           filename: "video.mp4",
#           url: "http://url.com",
#           size: 4_000_000,
#           platform_id: platform.id,
#           file_id: TestHelpers.uuid()
#         }
#       ]

#       assert {:error,
#               %Ecto.Changeset{
#                 changes: %{files: [%Ecto.Changeset{errors: [duration: _error_message]}]}
#               }} = Media.Context.insert_media(@valid_attrs |> Map.put(:files, files))
#     end

#     test "create_media/1 with invalid data returns error changeset (invalid_duration)" do
#       TestHelpers.set_repo(Media.Repo, "postgreSQL")

#       platform = create_platform()

#       ## bad duration format
#       files = [
#         %{
#           type: "mp4",
#           filename: "video.mp4",
#           url: "http://url.com",
#           duration: "asd",
#           size: 4_000_000,
#           platform_id: platform.id,
#           file_id: TestHelpers.uuid()
#         }
#       ]

#       assert {:error,
#               %Ecto.Changeset{
#                 changes: %{files: [%Ecto.Changeset{errors: [duration: _error_message]}]}
#               }} = Media.Context.insert_media(@valid_attrs |> Map.put(:files, files))
#     end

#     test "create_media/1 with invalid data returns error changeset (author not assigned)" do
#       TestHelpers.set_repo(Media.Repo, "postgreSQL")

#       platform = create_platform()

#       files = [
#         %{
#           file: %Plug.Upload{
#             path: "test/fixtures/phoenix.png",
#             filename: "phoenix.png",
#             content_type: "image/png"
#           },
#           platform_id: platform.id
#         }
#       ]

#       assert {:error, %Ecto.Changeset{errors: [author: _error_message]}} =
#                Media.Context.insert_media(@invalid_attrs_author |> Map.put(:files, files))
#     end

#     test "create_media/1 with invalid data returns error changeset (type not valid)" do
#       TestHelpers.set_repo(Media.Repo, "postgreSQL")

#       platform = create_platform()

#       files = [
#         %{
#           type: "mp4",
#           filename: "video.mp4",
#           url: "http://url.com",
#           duration: 240,
#           size: 4_000_000,
#           file_id: TestHelpers.uuid(),
#           platform_id: platform.id
#         }
#       ]

#       assert {:error, %Ecto.Changeset{errors: [type: _error_message]}} =
#                Media.Context.insert_media(@invalid_attrs_type |> Map.put(:files, files))
#     end

#     test "update_media/2 with valid data updates the media" do
#       TestHelpers.set_repo(Media.Repo, "postgreSQL")

#       platform = create_platform()
#       another_platform = create_platform(%{name: "mobile"})
#       file_id = TestHelpers.uuid()

#       files = [
#         %{
#           type: "mp4",
#           file_id: file_id,
#           filename: "video.mp4",
#           url: "http://url.com",
#           duration: 240,
#           size: 4_000_000,
#           platform_id: platform.id
#         }
#       ]

#       media =
#         media_fixture(%{files: files})
#         |> Map.put(:number_of_contents, 0)

#       platform_id = platform.id
#       file_id = TestHelpers.uuid()
#       another_platform_id = another_platform.id
#       another_file_id = TestHelpers.uuid()

#       files = [
#         %{
#           type: "mp4",
#           filename: "video.mp4",
#           url: "http://url.com",
#           duration: 240,
#           size: 4_000_000,
#           platform_id: platform_id,
#           file_id: file_id
#         },
#         %{
#           type: "mp4",
#           filename: "video2.mp4",
#           url: "http://url2.com",
#           duration: 300,
#           size: 5_000_000,
#           platform_id: another_platform_id,
#           file_id: another_file_id
#         }
#       ]

#       assert {:ok, media} =
#                Media.Context.update_media(
#                  @update_attrs
#                  |> Map.put(:id, media.id)
#                  |> Map.put(:files, files)
#                )

#       assert media.title == "some updated title"
#       assert media.author == "some updated author"
#       assert media.locked_status == "unlocked"
#       assert media.private_status == "public"

#       assert %{
#                type: "mp4",
#                filename: "video.mp4",
#                url: "http://url.com",
#                duration: 240,
#                size: 4_000_000,
#                platform_id: ^platform_id,
#                file_id: ^file_id
#              } = media.files |> Enum.find(&(Map.get(&1, :file_id) == file_id))

#       assert %{
#                type: "mp4",
#                filename: "video2.mp4",
#                url: "http://url2.com",
#                duration: 300,
#                size: 5_000_000,
#                platform_id: ^another_platform_id,
#                file_id: ^another_file_id
#              } = media.files |> Enum.find(&(Map.get(&1, :file_id) == another_file_id))
#     end

#     test "update_media/2 with invalid platform returns error" do
#       TestHelpers.set_repo(Media.Repo, "postgreSQL")

#       platform = create_platform()
#       file_id = TestHelpers.uuid()

#       files = [
#         %{
#           type: "mp4",
#           file_id: file_id,
#           filename: "video.mp4",
#           url: "http://url.com",
#           duration: 240,
#           size: 4_000_000,
#           platform_id: platform.id
#         }
#       ]

#       media = media_fixture(%{files: files})
#       file_id = TestHelpers.uuid()

#       files = [
#         %{
#           type: "mp4",
#           filename: "video2.mp4",
#           url: "http://url.com",
#           duration: 300,
#           size: 4_000_000,
#           platform_id: "invalid ID",
#           file_id: file_id
#         }
#       ]

#       assert {:error,
#               %Ecto.Changeset{
#                 valid?: false
#               }} =
#                Media.Context.update_media(
#                  @update_attrs
#                  |> Map.put(:id, media.id)
#                  |> Map.put(:files, files)
#                )
#     end

#     test "delete_media/1 deletes the media" do
#       TestHelpers.set_repo(Media.Repo, "postgreSQL")

#       platform = create_platform()

#       files = [
#         %{
#           file: %Plug.Upload{
#             path: "test/fixtures/phoenix.png",
#             filename: "phoenix.png",
#             content_type: "image/png"
#           },
#           platform_id: platform.id
#         }
#       ]

#       media = media_fixture(%{files: files})
#       assert {:ok, _message} = Media.Context.delete_media(media.id)
#       assert {:error, :not_found, _} = Media.Context.get_media(media.id)
#     end

#     test "delete_media/1 deletes unexsting media returns an error" do
#       TestHelpers.set_repo(Media.Repo, "postgreSQL")

#       assert {:error, :not_found, _} = Media.Context.delete_platform(0)
#     end

#     test "delete_media/1 deletes with invalid id returns an error" do
#       TestHelpers.set_repo(Media.Repo, "postgreSQL")

#       assert {:error, _message} = Media.Context.delete_platform("invalid id")
#     end

#     test "delete_media/1 deleting a used media returns an error" do
#       TestHelpers.set_repo(Media.Repo, "postgreSQL")

#       platform = create_platform()

#       files = [
#         %{
#           file: %Plug.Upload{
#             path: "test/fixtures/phoenix.png",
#             filename: "phoenix.png",
#             content_type: "image/png"
#           },
#           platform_id: platform.id
#         }
#       ]

#       media = media_fixture(%{files: files})

#       Contents.create_content(%{title: "content#{TestHelpers.uuid()}", medias: [media]})

#       assert {:error, _} = Media.Context.delete_media(media.id)
#     end
#   end

#   describe "Medias CRUD with MongoDB" do
#     alias BSON.ObjectId
#     alias Media.Helpers

#     @platform_valid_attrs %{
#       description: "some description",
#       height: 42,
#       name: "some name",
#       width: 42
#     }

#     @valid_attrs %{
#       author: "some author id",
#       locked_status: "locked",
#       private_status: "public",
#       seo_tag: "some seo tag",
#       tags: ["tag1", "tag2"],
#       title: "some media title",
#       type: "image"
#     }
#     @invalid_attrs_author %{
#       author: nil,
#       locked_status: "locked",
#       private_status: "public",
#       seo_tag: "some seo tag",
#       tags: ["tag1", "tag2"],
#       title: "some media title",
#       type: "video"
#     }
#     @invalid_attrs_type %{
#       author: "some author id",
#       locked_status: "locked",
#       private_status: "public",
#       seo_tag: "some seo tag",
#       tags: ["tag1", "tag2"],
#       title: "some media title",
#       type: "what is this media?"
#     }

#     # setup_with_mocks([
#     #   {Helpers, [:passthrough],
#     #    db_struct: fn args -> struct(%MongoDB{}, %{args: args}) end,
#     #    repo: fn ->
#     #      :mongo
#     #    end}
#     # ]) do
#     #   ## to have the database clean for each test
#     #   ## What the sandbox does for postgreSQL
#     #   TestHelpers.clean_mongodb()
#     #   :ok
#     # end

#     test "list_medias/0 returns all medias (not paginated)" do
#       TestHelpers.set_repo(:mongo, @mongoDB)

#       # with_mock Helpers, [:passthrough], repo: fn -> Media.Repo end do
#       platform = create_platform()

#       files = [
#         %{
#           type: "video",
#           filename: "video.mp4",
#           url: "http://url.com",
#           duration: 240,
#           size: 4_000_000,
#           platform_id: platform.id,
#           file_id: TestHelpers.uuid()
#         }
#       ]

#       media_fixture(%{files: files})

#       platform_id = ObjectId.decode!(platform.id)

#       assert %{
#                result: [
#                  %{
#                    author: "some author id",
#                    files: [
#                      %{
#                        duration: 240,
#                        filename: "video.mp4",
#                        platform: %{
#                          description: "some description",
#                          height: 42,
#                          _id: ^platform_id,
#                          # inserted_at: "2021-05-25T13:07:48",
#                          name: "some name",
#                          # updated_at: "2021-05-25T13:07:48",
#                          width: 42
#                        },
#                        platform_id: ^platform_id,
#                        size: 4_000_000,
#                        type: "video",
#                        url: "http://url.com"
#                      }
#                    ],
#                    id: _id,
#                    locked_status: "locked",
#                    number_of_contents: 0,
#                    private_status: "public",
#                    seo_tag: "some seo tag",
#                    tags: ["tag1", "tag2"],
#                    title: "some media title",
#                    type: "video"
#                  }
#                ],
#                total: 1
#              } = Media.Context.list_medias()

#       # end
#     end

#     test "list_medias/0 returns all medias (paginated)" do
#       TestHelpers.set_repo(:mongo, @mongoDB)

#       # with_mock Helpers, [:passthrough], repo: fn -> Media.Repo end do
#       platform = create_platform()

#       files = [
#         %{
#           type: "video",
#           filename: "video.mp4",
#           url: "http://url.com",
#           duration: 240,
#           size: 4_000_000,
#           platform_id: platform.id,
#           file_id: TestHelpers.uuid()
#         }
#       ]

#       media0 = media_fixture(%{files: files})
#       media1 = media_fixture(%{files: files, title: "Media Title 1"})
#       media2 = media_fixture(%{files: files, title: "Media Title 2"})

#       media_id_0 = media0.id
#       media_title_0 = media0.title

#       assert %{result: [%{id: ^media_id_0, title: ^media_title_0}], total: 3} =
#                Media.Context.list_medias(%{per_page: 1, page: 1})

#       media_id_1 = media1.id
#       media_title_1 = media1.title

#       assert %{result: [%{id: ^media_id_1, title: ^media_title_1}], total: 3} =
#                Media.Context.list_medias(%{per_page: 1, page: 2})

#       media_id_2 = media2.id
#       media_title_2 = media2.title

#       assert %{result: [%{id: ^media_id_2, title: ^media_title_2}], total: 3} =
#                Media.Context.list_medias(%{per_page: 1, page: 3})
#     end

#     test "list_medias/0 returns all medias (filtered)" do
#       TestHelpers.set_repo(:mongo, @mongoDB)

#       # with_mock Helpers, [:passthrough], repo: fn -> Media.Repo end do
#       platform = create_platform()

#       image_file = [
#         %{
#           type: "jpeg",
#           filename: "image.jpeg",
#           url: "http://url.com",
#           size: 4_000_000,
#           platform_id: platform.id,
#           file_id: TestHelpers.uuid()
#         }
#       ]

#       files = [
#         %{
#           file: %Plug.Upload{
#             path: "test/fixtures/phoenix.png",
#             filename: "phoenix.png",
#             content_type: "image/png"
#           },
#           platform_id: platform.id
#         }
#       ]

#       media_fixture(%{files: files})

#       media1 =
#         media_fixture(%{
#           files: image_file,
#           title: "Media Title 1",
#           type: "image",
#           locked_status: "unlocked"
#         })

#       media2 = media_fixture(%{files: files, title: "Media Title 2", private_status: "private"})
#       ## FILTER BY TITLE
#       media_id_2 = media2.id
#       media_title_2 = media2.title

#       assert %{result: [%{id: ^media_id_2, title: ^media_title_2}], total: 1} =
#                Media.Context.list_medias(%{filters: [%{key: "title", value: "Media Title 2"}]})

#       media_id_1 = media1.id
#       media_title_1 = media1.title
#       ## type of media
#       assert %{result: [%{id: ^media_id_1, title: ^media_title_1}], total: 1} =
#                Media.Context.list_medias(%{filters: [%{key: "type", value: "image"}]})

#       ## number of contents
#       assert %{result: _res, total: 3} =
#                Media.Context.list_medias(%{
#                  filters: [%{key: "number_of_contents", value: 0, operation: "="}]
#                })

#       ## filter by private_status
#       assert %{total: 1} =
#                Media.Context.list_medias(%{
#                  filters: [%{key: "private_status", value: "private"}]
#                })

#       ## filter by lock_status
#       assert %{total: 1} =
#                Media.Context.list_medias(%{
#                  filters: [%{key: "locked_status", value: "unlocked"}]
#                })
#     end

#     test "get_media/1 returns the media with given id" do
#       TestHelpers.set_repo(:mongo, @mongoDB)

#       platform = create_platform()

#       files = [
#         %{
#           file: %Plug.Upload{
#             path: "test/fixtures/phoenix.png",
#             filename: "phoenix.png",
#             content_type: "image/png"
#           },
#           platform_id: platform.id
#         }
#       ]

#       media = media_fixture(%{files: files})

#       platform_id = ObjectId.decode!(platform.id)

#       assert {:ok,
#               %{
#                 author: "some author id",
#                 files: [
#                   %{
#                     duration: 240,
#                     filename: "video.mp4",
#                     platform: %{
#                       description: "some description",
#                       height: 42,
#                       _id: ^platform_id,
#                       # inserted_at: "2021-05-25T13:07:48",
#                       name: "some name",
#                       # updated_at: "2021-05-25T13:07:48",
#                       width: 42
#                     },
#                     platform_id: ^platform_id,
#                     size: 4_000_000,
#                     type: "mp4",
#                     url: "http://url.com"
#                   }
#                 ],
#                 id: _id,
#                 locked_status: "locked",
#                 number_of_contents: 0,
#                 private_status: "public",
#                 seo_tag: "some seo tag",
#                 tags: ["tag1", "tag2"],
#                 title: "some media title",
#                 type: "video"
#               }} = Media.Context.get_media(media.id)
#     end

#     test "get_media/1 with invalid ID" do
#       TestHelpers.set_repo(:mongo, @mongoDB)

#       assert {:error, _} = Media.Context.get_media(0)
#       assert {:error, _} = Media.Context.get_media("123")

#       assert {:error, :not_found, _} = Media.Context.get_media("012345678912345678912345")
#     end

#     test "create_media/1 with valid data creates a media" do
#       TestHelpers.set_repo(:mongo, @mongoDB)

#       platform = create_platform()

#       files = [
#         %{
#           file: %Plug.Upload{
#             path: "test/fixtures/phoenix.png",
#             filename: "phoenix.png",
#             content_type: "image/png"
#           },
#           platform_id: platform.id
#         }
#       ]

#       media = media_fixture(%{files: files})

#       platform_id = ObjectId.decode!(platform.id)

#       assert {:ok,
#               %{
#                 author: "some author id",
#                 files: [
#                   %{
#                     filename: _filename,
#                     platform: %{
#                       description: "some description",
#                       height: 42,
#                       _id: ^platform_id,
#                       # inserted_at: "2021-05-25T13:07:48",
#                       name: "some name",
#                       # updated_at: "2021-05-25T13:07:48",
#                       width: 42
#                     },
#                     platform_id: ^platform_id,
#                     size: _size,
#                     type: "image/png",
#                     url: "some url",
#                     file_id: _fileid
#                   }
#                 ],
#                 id: _id,
#                 locked_status: "locked",
#                 number_of_contents: 0,
#                 private_status: "public",
#                 seo_tag: "some seo tag",
#                 tags: ["tag1", "tag2"],
#                 title: "some media title",
#                 type: "image"
#               }} = Media.Context.get_media(media.id)
#     end

#     test "create_media/1 with invalid data returns error changeset" do
#       TestHelpers.set_repo(:mongo, @mongoDB)

#       platform = create_platform()

#       ## no duration provided
#       files = [
#         %{
#           type: "mp4",
#           filename: "video.mp4",
#           url: "http://url.com",
#           size: 4_000_000,
#           platform_id: platform.id,
#           file_id: TestHelpers.uuid()
#         }
#       ]

#       assert {:error,
#               %Ecto.Changeset{
#                 errors: [files: _error_message]
#               }} = Media.Context.insert_media(@valid_attrs |> Map.put(:files, files))
#     end

#     test "create_media/1 with invalid data returns error changeset (invalid_duration)" do
#       TestHelpers.set_repo(:mongo, @mongoDB)

#       platform = create_platform()

#       ## bad duration format
#       files = [
#         %{file: %{url: "https://www.youtube.com/watch?v=3HkggxR_kvE"}, platform_id: platform.id}
#       ]

#       assert {:error,
#               %Ecto.Changeset{
#                 errors: [files: _error_message]
#               }} = Media.Context.insert_media(@valid_attrs |> Map.put(:files, files))
#     end

#     test "create_media/1 with invalid data returns error changeset (author not assigned)" do
#       TestHelpers.set_repo(:mongo, @mongoDB)

#       platform = create_platform()

#       ## bad duration format
#       files = [
#         %{
#           file: %Plug.Upload{
#             path: "test/fixtures/phoenix.png",
#             filename: "phoenix.png",
#             content_type: "image/png"
#           },
#           platform_id: platform.id
#         }
#       ]

#       assert {:error, %Ecto.Changeset{errors: [author: _error_message]}} =
#                Media.Context.insert_media(@invalid_attrs_author |> Map.put(:files, files))
#     end

#     test "create_media/1 with invalid data returns error changeset (type not valid)" do
#       TestHelpers.set_repo(:mongo, @mongoDB)

#       platform = create_platform()

#       files = [
#         %{
#           file: %Plug.Upload{
#             path: "test/fixtures/phoenix.png",
#             filename: "phoenix.png",
#             content_type: "image/png"
#           },
#           platform_id: platform.id
#         }
#       ]

#       assert {:error, %Ecto.Changeset{errors: [type: _error_message]}} =
#                Media.Context.insert_media(@invalid_attrs_type |> Map.put(:files, files))
#     end

#     test "update_media/2 with valid data updates the media" do
#       TestHelpers.set_repo(:mongo, @mongoDB)

#       platform = create_platform()
#       another_platform = create_platform(%{name: "mobile"})
#       file_id = TestHelpers.uuid()

#       files = [
#         %{
#           type: "mp4",
#           file_id: file_id,
#           filename: "video.mp4",
#           url: "http://url.com",
#           duration: 240,
#           size: 4_000_000,
#           platform_id: platform.id
#         }
#       ]

#       media =
#         media_fixture(%{files: files})
#         |> Map.put(:number_of_contents, 0)

#       platform_id = platform.id
#       file_id = TestHelpers.uuid()
#       another_platform_id = another_platform.id
#       another_file_id = TestHelpers.uuid()

#       files = [
#         %{
#           type: "mp4",
#           filename: "video.mp4",
#           url: "http://url.com",
#           duration: 240,
#           size: 4_000_000,
#           platform_id: platform_id,
#           file_id: file_id
#         },
#         %{
#           type: "mp4",
#           filename: "video2.mp4",
#           url: "http://url2.com",
#           duration: 300,
#           size: 5_000_000,
#           platform_id: another_platform_id,
#           file_id: another_file_id
#         }
#       ]

#       platform_id = ObjectId.decode!(platform_id)
#       another_platform_id = ObjectId.decode!(another_platform_id)

#       assert {:ok, media} =
#                Media.Context.update_media(
#                  @update_attrs
#                  |> Map.put(:id, media.id)
#                  |> Map.put(:files, files)
#                )

#       assert media.title == "some updated title"
#       assert media.author == "some updated author"
#       assert media.locked_status == "unlocked"
#       assert media.private_status == "public"

#       assert %{
#                type: "mp4",
#                filename: "video.mp4",
#                url: "http://url.com",
#                duration: 240,
#                size: 4_000_000,
#                platform_id: ^platform_id,
#                file_id: ^file_id
#              } = media.files |> Enum.find(&(Map.get(&1, :file_id) == file_id))

#       assert %{
#                type: "mp4",
#                filename: "video2.mp4",
#                url: "http://url2.com",
#                duration: 300,
#                size: 5_000_000,
#                platform_id: ^another_platform_id,
#                file_id: ^another_file_id
#              } = media.files |> Enum.find(&(Map.get(&1, :file_id) == another_file_id))
#     end

#     test "update_media/2 with invalid platform returns error" do
#       TestHelpers.set_repo(:mongo, @mongoDB)

#       platform = create_platform()
#       file_id = TestHelpers.uuid()

#       files = [
#         %{
#           type: "mp4",
#           file_id: file_id,
#           filename: "video.mp4",
#           url: "http://url.com",
#           duration: 240,
#           size: 4_000_000,
#           platform_id: platform.id
#         }
#       ]

#       media = media_fixture(%{files: files})
#       file_id = TestHelpers.uuid()

#       files = [
#         %{
#           type: "mp4",
#           filename: "video.mp4",
#           url: "http://url.com",
#           duration: 240,
#           size: 4_000_000,
#           platform_id: "invalid ID",
#           file_id: file_id
#         }
#       ]

#       assert {:error, %Ecto.Changeset{errors: [files: _]}} =
#                Media.Context.update_media(
#                  @update_attrs
#                  |> Map.put(:id, media.id)
#                  |> Map.put(:files, files)
#                )
#     end

#     test "delete_media/1 deletes the media" do
#       TestHelpers.set_repo(:mongo, @mongoDB)

#       platform = create_platform()

#       files = [
#         %{
#           file: %Plug.Upload{
#             path: "test/fixtures/phoenix.png",
#             filename: "phoenix.png",
#             content_type: "image/png"
#           },
#           platform_id: platform.id
#         }
#       ]

#       media = media_fixture(%{files: files})
#       assert {:ok, _message} = Media.Context.delete_media(media.id)
#       assert {:error, :not_found, _} = Media.Context.get_media(media.id)
#     end

#     test "delete_media/1 deletes unexsting media returns an error" do
#       TestHelpers.set_repo(:mongo, @mongoDB)

#       # TestHelpers.set_repo(:mongo, @mongo_db_name)

#       assert {:error, :not_found, _} = Media.Context.delete_platform("012345678901234567890123")
#     end

#     test "delete_media/1 deletes with invalid id returns an error" do
#       TestHelpers.set_repo(:mongo, @mongoDB)

#       # TestHelpers.set_repo(:mongo, @mongo_db_name)

#       assert {:error, _message} = Media.Context.delete_platform("invalid id")
#     end

#     test "delete_media/1 deleting a used media returns an error" do
#       TestHelpers.set_repo(:mongo, @mongoDB)

#       # TestHelpers.set_repo(:mongo, @mongo_db_name)
#       content = Contents.create_content(%{title: "content#{TestHelpers.uuid()}"})

#       platform = create_platform()

#       files = [
#         %{
#           file: %Plug.Upload{
#             path: "test/fixtures/phoenix.png",
#             filename: "phoenix.png",
#             content_type: "image/png"
#           },
#           platform_id: platform.id
#         }
#       ]

#       media =
#         media_fixture(%{files: files, contents_used: [content["_id"] |> ObjectId.encode!()]})

#       assert {:error, _} = Media.Context.delete_media(media.id)
#     end
#   end

#   ### HELPERS FUNCTIONS ###
#   defp create_platform(attrs \\ %{}) do
#     {:ok, platform} =
#       attrs
#       |> Enum.into(@platform_valid_attrs)
#       |> Media.Context.insert_platform()

#     platform =
#       platform
#       |> Map.from_struct()
#       |> Map.delete(:__meta__)

#     platform
#   end

#   defp media_fixture(attrs \\ %{}) do
#     {:ok, media} =
#       attrs
#       |> Enum.into(@valid_attrs)
#       |> Media.Context.insert_media()

#     media
#   end

#   ### HELPERS FUNCTIONS ###
# end
