defmodule Media.PlatformsTest do
  use Media.DataCase

  alias Media.Helpers
  alias Media.Platforms
  alias Media.TestHelpers
  @mongo_db_name "mongoDB"
  alias Media.Platforms.Platform
  import Mock

  @valid_media_attrs %{
    author: "some author id",
    locked_status: "locked",
    private_status: "public",
    seo_tag: "some seo tag",
    tags: ["tag1", "tag2"],
    title: "some media title",
    type: "video"
  }
  describe "platforms with PostgreSQL" do
    setup_with_mocks([
      {Helpers, [:passthrough], repo: fn -> Media.Repo end}
    ]) do
      :ok
    end

    @valid_attrs %{
      description: "some description",
      height: 42,
      name: "some name",
      width: 42
    }
    @update_attrs %{
      description: "some updated description",
      height: 43,
      name: "some updated name",
      width: 43
    }
    @invalid_attrs %{description: nil, height: nil, name: nil, width: nil}

    def platform_fixture(attrs \\ %{}) do
      {:ok, platform} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Media.Context.insert_platform()

      platform
    end

    test "list_platforms/0 returns all platforms (not paginated)" do
      # with_mock Helpers, [:passthrough], repo: fn -> Media.Repo end do
      TestHelpers.set_repo(Media.Repo, "postgreSQL")

      platform = platform_fixture()

      platform_id = platform.id
      height = @valid_attrs.height
      width = @valid_attrs.width

      assert %{
               result: [
                 %{
                   description: "some description",
                   height: ^height,
                   id: ^platform_id,
                   name: "some name",
                   number_of_medias: 0,
                   width: ^width
                 }
               ],
               total: 1
             } = Media.Context.list_platforms()

      # end
    end

    test "list_platforms/0 returns all platforms (paginated)" do
      TestHelpers.set_repo(Media.Repo, "postgreSQL")

      platform0 = platform_fixture()
      platform1 = platform_fixture(%{name: TestHelpers.uuid()})
      platform2 = platform_fixture(%{name: TestHelpers.uuid()})

      platform0_id = platform0.id
      platform0_name = platform0.name

      assert %{result: [%{id: ^platform0_id, name: ^platform0_name}] = args, total: 3} =
               Media.Context.list_platforms(%{per_page: 1, page: 1})

      assert Enum.count(args) == 1
      platform1_id = platform1.id
      platform1_name = platform1.name

      assert %{result: [%{id: ^platform1_id, name: ^platform1_name}] = args, total: 3} =
               Media.Context.list_platforms(%{per_page: 1, page: 2})

      assert Enum.count(args) == 1
      platform2_id = platform2.id
      platform2_name = platform2.name

      assert %{result: [%{id: ^platform2_id, name: ^platform2_name}] = args, total: 3} =
               Media.Context.list_platforms(%{per_page: 1, page: 3})

      assert Enum.count(args) == 1
    end

    test "list_platforms/0 returns all platforms (filtered)" do
      # with_mock Helpers, [:passthrough], repo: fn -> Media.Repo end do
      name = TestHelpers.uuid()
      platform = platform_fixture(%{name: name})
      platform2 = platform_fixture(%{width: 100, height: 200})

      image_file = [
        %{
          type: "jpeg",
          filename: "image.jpeg",
          url: "http://url.com",
          size: 4_000_000,
          platform_id: platform.id,
          s3_id: TestHelpers.uuid()
        }
      ]

      files = [
        %{
          type: "mp4",
          filename: "video.mp4",
          url: "http://url.com",
          duration: 240,
          size: 4_000_000,
          platform_id: platform.id,
          s3_id: TestHelpers.uuid()
        }
      ]

      media_fixture(%{files: files})

      media_fixture(%{
        files: image_file,
        title: "Media Title 1",
        type: "image"
      })

      media_fixture(%{files: files, title: "Media Title 2"})

      ## FILTER BY NAME
      platform_id = platform.id
      platform_name = platform.name

      assert %{result: [%{id: ^platform_id, name: ^platform_name}], total: 1} =
               Media.Context.list_platforms(%{filters: [%{key: "name", value: platform_name}]})

      platform2_id = platform2.id
      platform2_name = platform2.name
      ## FILTER BY HEIGHT
      assert %{result: [%{id: ^platform2_id, name: ^platform2_name}], total: 1} =
               Media.Context.list_platforms(%{filters: [%{key: "height", value: 200}]})

      ## FILTER BY WITDH
      assert %{result: [%{id: ^platform2_id, name: ^platform2_name}], total: 1} =
               Media.Context.list_platforms(%{filters: [%{key: "width", value: 100}]})

      ## number of contents
      assert %{result: [%{id: ^platform_id, name: ^platform_name, number_of_medias: 3}], total: 1} =
               Media.Context.list_platforms(%{
                 filters: [%{key: "number_of_medias", value: 3, operation: "="}]
               })

      assert %{result: [], total: 0} =
               Media.Context.list_platforms(%{
                 filters: [%{key: "number_of_medias", value: 3, operation: ">"}]
               })

      assert %{result: args, total: 2} =
               Media.Context.list_platforms(%{
                 filters: [%{key: "number_of_medias", value: 4, operation: "<"}]
               })

      assert args |> Enum.count() == 2

      assert %{
               result: [%{id: ^platform2_id, name: ^platform2_name, number_of_medias: 0}],
               total: 1
             } =
               Media.Context.list_platforms(%{
                 filters: [%{key: "number_of_medias", value: 3, operation: "<"}]
               })

      assert %{result: args, total: 2} =
               Media.Context.list_platforms(%{
                 filters: [%{key: "number_of_medias", value: 4, operation: "<="}]
               })

      assert args |> Enum.count() == 2
    end

    test "get_platform/1 returns the platform with given id" do
      # with_mock Helpers, [:passthrough], repo: fn -> Media.Repo end do
      TestHelpers.set_repo(Media.Repo, "postgreSQL")

      platform = platform_fixture()

      assert {:ok, platform} == Media.Context.get_platform(platform.id)
    end

    test "get_platform/1 with invalid ID" do
      TestHelpers.set_repo(Media.Repo, "postgreSQL")

      assert {:error, :not_found, _} = Media.Context.get_media(0)
      assert {:error, _errormessage} = Media.Context.get_media("asd")
    end

    #   test "get_platform!/1 returns the platform with given id" do
    #     platform = platform_fixture()
    #     assert Platforms.get_platform!(platform.id) == platform
    #   end
    test "create_platform/1 with valid data creates a platform" do
      TestHelpers.set_repo(Media.Repo, "postgreSQL")
      assert {:ok, %Platform{} = platform} = Media.Context.insert_platform(@valid_attrs)
      assert platform.description == "some description"
      assert platform.height == 42
      assert platform.name == "some name"
      assert platform.width == 42
    end

    test "create_platform/1 with invalid data returns error changeset" do
      TestHelpers.set_repo(Media.Repo, "postgreSQL")
      assert {:error, %Ecto.Changeset{}} = Platforms.create_platform(@invalid_attrs)
    end

    test "update_platform/2 with valid data updates the platform" do
      TestHelpers.set_repo(Media.Repo, "postgreSQL")

      platform = platform_fixture()

      assert {:ok, %Platform{} = platform} =
               Media.Context.update_platform(@update_attrs |> Map.put(:id, platform.id))

      assert platform.description == "some updated description"
      assert platform.height == 43
      assert platform.name == "some updated name"
      assert platform.width == 43
    end

    test "update_platform/2 with invalid data returns error changeset" do
      TestHelpers.set_repo(Media.Repo, "postgreSQL")

      platform = platform_fixture()

      assert {:error, %Ecto.Changeset{}} =
               Media.Context.update_platform(
                 @invalid_attrs
                 |> Map.put(:id, platform.id)
               )

      assert {:ok, platform} == Media.Context.get_platform(platform.id)
    end

    test "delete_platform/1 deletes the platform" do
      TestHelpers.set_repo(Media.Repo, "postgreSQL")

      platform = platform_fixture()
      assert {:ok, _message} = Media.Context.delete_platform(platform.id)
      assert {:error, :not_found, _} = Media.Context.get_platform(platform.id)
    end

    test "delete_platform/1 deletes unexsting platform returns an error" do
      TestHelpers.set_repo(Media.Repo, "postgreSQL")

      assert {:error, :not_found, _} = Media.Context.delete_platform(0)
    end

    test "delete_platform/1 deletes with invalid id returns an error" do
      TestHelpers.set_repo(Media.Repo, "postgreSQL")

      assert {:error, Helpers.id_error_message("invalid id")} ==
               Media.Context.delete_platform("invalid id")
    end

    test "delete_platform/1 deleting a used platform returns an error" do
      TestHelpers.set_repo(Media.Repo, "postgreSQL")

      platform = platform_fixture()

      files = [
        %{
          type: "mp4",
          filename: "video.mp4",
          url: "http://url.com",
          duration: 240,
          size: 4_000_000,
          platform_id: platform.id,
          s3_id: TestHelpers.uuid()
        }
      ]

      media_fixture(%{files: files})

      assert {:error, _} = Media.Context.delete_platform(platform.id)
    end
  end

  describe "platforms with Mongo DB" do
    @valid_attrs %{description: "some description", height: 42, name: "some name", width: 42}
    # @update_attrs %{
    #   description: "some updated description",
    #   height: 43,
    #   name: "some updated name",
    #   width: 43
    # }
    @invalid_attrs %{description: nil, height: nil, name: nil, width: nil}

    #   test "list_platforms/0 returns all platforms" do
    #     platform = platform_fixture()
    #     assert Platforms.list_platforms() == [platform]
    #   end

    #   test "get_platform!/1 returns the platform with given id" do
    #     platform = platform_fixture()
    #     assert Platforms.get_platform!(platform.id) == platform
    #   end
    # setup _context do
    #   TestHelpers.clean_mongodb() |> IO.inspect(label: "CLEANING")
    # end

    test_with_mock(
      "create_platform/1 with valid data creates a platform",
      Helpers,
      [:passthrough],
      repo: fn -> :mongo end
    ) do
      TestHelpers.set_repo(:mongo, @mongo_db_name)
      assert {:ok, %Platform{} = platform} = Media.Context.insert_platform(@valid_attrs)
      assert platform.description == "some description"
      assert platform.height == 42
      assert platform.name == "some name"
      assert platform.width == 42
    end
  end

  ## Writing this here will trigger the setup for each test
  ## While putting it at the top will invoke it once 🤔
  setup _context do
    TestHelpers.clean_mongodb()
  end

  test "list_platforms/0 returns all platforms (not paginated)" do
    TestHelpers.set_repo(:mongo, @mongo_db_name)

    # with_mock Helpers, [:passthrough], repo: fn -> Media.Repo end do
    platform = platform_fixture()

    platform_id = platform.id
    height = @valid_attrs.height
    width = @valid_attrs.width

    assert %{
             result: [
               %{
                 description: "some description",
                 height: ^height,
                 id: ^platform_id,
                 name: "some name",
                 number_of_medias: 0,
                 width: ^width
               }
             ],
             total: 1
           } = Media.Context.list_platforms()

    # end
  end

  test "list_platforms/0 returns all platforms (paginated)" do
    TestHelpers.set_repo(:mongo, @mongo_db_name)

    platform0 = platform_fixture()
    platform1 = platform_fixture(%{name: TestHelpers.uuid()})
    platform2 = platform_fixture(%{name: TestHelpers.uuid()})

    platform0_id = platform0.id
    platform0_name = platform0.name

    assert %{result: [%{id: ^platform0_id, name: ^platform0_name}] = args, total: 3} =
             Media.Context.list_platforms(%{per_page: 1, page: 1})

    assert Enum.count(args) == 1
    platform1_id = platform1.id
    platform1_name = platform1.name

    assert %{result: [%{id: ^platform1_id, name: ^platform1_name}] = args, total: 3} =
             Media.Context.list_platforms(%{per_page: 1, page: 2})

    assert Enum.count(args) == 1
    platform2_id = platform2.id
    platform2_name = platform2.name

    assert %{result: [%{id: ^platform2_id, name: ^platform2_name}] = args, total: 3} =
             Media.Context.list_platforms(%{per_page: 1, page: 3})

    assert Enum.count(args) == 1
  end

  test "list_platforms/0 returns all platforms (filtered)" do
    # with_mock Helpers, [:passthrough], repo: fn -> Media.Repo end do
    TestHelpers.set_repo(:mongo, @mongo_db_name)

    name = TestHelpers.uuid()
    platform = platform_fixture(%{name: name})
    platform2 = platform_fixture(%{width: 100, height: 200})

    image_file = [
      %{
        type: "jpeg",
        filename: "image.jpeg",
        url: "http://url.com",
        size: 4_000_000,
        platform_id: platform.id,
        s3_id: TestHelpers.uuid()
      }
    ]

    files = [
      %{
        type: "mp4",
        filename: "video.mp4",
        url: "http://url.com",
        duration: 240,
        size: 4_000_000,
        platform_id: platform.id,
        s3_id: TestHelpers.uuid()
      }
    ]

    media_fixture(%{files: files})

    media_fixture(%{
      files: image_file,
      title: "Media Title 1",
      type: "image"
    })

    media_fixture(%{files: files, title: "Media Title 2"})

    ## FILTER BY NAME
    platform_id = platform.id
    platform_name = platform.name

    assert %{result: [%{id: ^platform_id, name: ^platform_name}], total: 1} =
             Media.Context.list_platforms(%{filters: [%{key: "name", value: platform_name}]})

    platform2_id = platform2.id
    platform2_name = platform2.name
    ## FILTER BY HEIGHT
    assert %{result: [%{id: ^platform2_id, name: ^platform2_name}], total: 1} =
             Media.Context.list_platforms(%{filters: [%{key: "height", value: 200}]})

    ## FILTER BY WITDH
    assert %{result: [%{id: ^platform2_id, name: ^platform2_name}], total: 1} =
             Media.Context.list_platforms(%{filters: [%{key: "width", value: 100}]})

    ## number of contents
    assert %{result: [%{id: ^platform_id, name: ^platform_name, number_of_medias: 3}], total: 1} =
             Media.Context.list_platforms(%{
               filters: [%{key: "number_of_medias", value: 3, operation: "="}]
             })

    assert %{result: [], total: 0} =
             Media.Context.list_platforms(%{
               filters: [%{key: "number_of_medias", value: 3, operation: ">"}]
             })

    assert %{result: args, total: 2} =
             Media.Context.list_platforms(%{
               filters: [%{key: "number_of_medias", value: 4, operation: "<"}]
             })

    assert args |> Enum.count() == 2

    assert %{
             result: [%{id: ^platform2_id, name: ^platform2_name, number_of_medias: 0}],
             total: 1
           } =
             Media.Context.list_platforms(%{
               filters: [%{key: "number_of_medias", value: 3, operation: "<"}]
             })

    assert %{result: args, total: 2} =
             Media.Context.list_platforms(%{
               filters: [%{key: "number_of_medias", value: 4, operation: "<="}]
             })

    assert args |> Enum.count() == 2
  end

  test "get_platform/1 returns the platform with given id" do
    TestHelpers.set_repo(:mongo, @mongo_db_name)

    platform = platform_fixture()

    assert {:ok, platform} == Media.Context.get_platform(platform.id)
  end

  test "get_platform/1 with invalid ID" do
    TestHelpers.set_repo(:mongo, @mongo_db_name)

    assert {:error, :not_found, _} = Media.Context.get_media("012345678901234567890123")
    assert {:error, _errormessage} = Media.Context.get_media("asd")
  end

  test "create_platform/1 with invalid data returns error changeset" do
    TestHelpers.set_repo(:mongo, @mongo_db_name)

    assert {:error, %Ecto.Changeset{}} = Media.Context.insert_platform(@invalid_attrs)
  end

  test "update_platform/2 with valid data updates the platform" do
    TestHelpers.set_repo(:mongo, @mongo_db_name)

    platform = platform_fixture(%{name: "platform-#{TestHelpers.uuid()}"})

    assert {:ok, %Platform{} = platform} =
             Media.Context.update_platform(@update_attrs |> Map.put(:id, platform.id))

    assert platform.description == "some updated description"
    assert platform.height == 43
    assert platform.name == "some updated name"
    assert platform.width == 43
  end

  test "update_platform/2 with invalid data returns error changeset" do
    TestHelpers.set_repo(:mongo, @mongo_db_name)

    platform = platform_fixture(%{name: "platform-#{TestHelpers.uuid()}"})

    assert {:error, %Ecto.Changeset{}} =
             Media.Context.update_platform(
               @invalid_attrs
               |> Map.put(:id, platform.id)
             )

    assert {:ok, platform} == Media.Context.get_platform(platform.id)
  end

  #   test "update_platform/2 with valid data updates the platform" do
  #     platform = platform_fixture()
  #     assert {:ok, %Platform{} = platform} = Platforms.update_platform(platform, @update_attrs)
  #     assert platform.description == "some updated description"
  #     assert platform.height == 43
  #     assert platform.name == "some updated name"
  #     assert platform.width == 43
  #   end

  #   test "update_platform/2 with invalid data returns error changeset" do
  #     platform = platform_fixture()
  #     assert {:error, %Ecto.Changeset{}} = Platforms.update_platform(platform, @invalid_attrs)
  #     assert platform == Platforms.get_platform!(platform.id)
  #   end

  test "delete_platform/1 deletes the platform" do
    TestHelpers.set_repo(:mongo, @mongo_db_name)

    platform = platform_fixture()
    assert {:ok, _message} = Media.Context.delete_platform(platform.id)
    assert {:error, :not_found, _} = Media.Context.get_platform(platform.id)
  end

  test "delete_platform/1 deletes unexsting platform returns an error" do
    TestHelpers.set_repo(:mongo, @mongo_db_name)

    assert {:error, :not_found, _} = Media.Context.delete_platform("012345678901234567890123")
  end

  test "delete_platform/1 deletes with invalid id returns an error" do
    TestHelpers.set_repo(:mongo, @mongo_db_name)

    assert {:error, _message} = Media.Context.delete_platform("invalid id")
  end

  test "delete_platform/1 deleting a used platform returns an error" do
    TestHelpers.set_repo(:mongo, @mongo_db_name)

    platform = platform_fixture()

    files = [
      %{
        type: "mp4",
        filename: "video.mp4",
        url: "http://url.com",
        duration: 240,
        size: 4_000_000,
        platform_id: platform.id,
        s3_id: TestHelpers.uuid()
      }
    ]

    media_fixture(%{files: files})

    assert {:error, _} = Media.Context.delete_platform(platform.id)
  end

  #   test "change_platform/1 returns a platform changeset" do
  #     platform = platform_fixture()
  #     assert %Ecto.Changeset{} = Platforms.change_platform(platform)
  #   end
  # end

  defp media_fixture(attrs \\ %{}) do
    {:ok, media} =
      attrs
      |> Enum.into(@valid_media_attrs)
      |> Media.Context.insert_media()

    media
  end
end
