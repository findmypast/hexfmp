defmodule HexWeb.RouterTest do
  use HexWebTest.Case
  import Plug.Test
  alias HexWeb.Router
  alias HexWeb.User
  alias HexWeb.Package
  alias HexWeb.Release
  alias HexWeb.RegistryBuilder

  setup do
    User.create("other", "other@mail.com", "other")
    { :ok, user } = User.create("eric", "eric@mail.com", "eric")
    { :ok, _ }    = Package.create("postgrex", user, [])
    { :ok, pkg }  = Package.create("decimal", user, [])
    { :ok, _ }    = Release.create(pkg, "0.0.1", [{ "postgrex", "0.0.1" }])
    :ok
  end

  test "create user" do
    body = [username: "name", email: "email@mail.com", password: "pass"]
    conn = conn("POST", "/api/users", JSON.encode!(body), headers: [{ "content-type", "application/json" }])
    conn = Router.call(conn, [])

    assert conn.status == 201
    body = JSON.decode!(conn.resp_body)
    assert body["url"] == "http://hex.pm/api/users/name"

    user = assert User.get("name")
    assert user.email == "email@mail.com"
  end

  test "create user validates" do
    body = [username: "name", password: "pass"]
    conn = conn("POST", "/api/users", JSON.encode!(body), headers: [{ "content-type", "application/json" }])
    conn = Router.call(conn, [])

    assert conn.status == 422
    body = JSON.decode!(conn.resp_body)
    assert body["message"] == "Validation failed"
    assert body["errors"]["email"] == "can't be blank"
    refute User.get("name")
  end

  test "update user" do
    headers = [ { "content-type", "application/json" },
                { "authorization", "Basic " <> :base64.encode("other:other") }]
    body = [email: "email@mail.com", password: "pass"]
    conn = conn("PATCH", "/api/users/other", JSON.encode!(body), headers: headers)
    conn = Router.call(conn, [])

    assert conn.status == 200
    body = JSON.decode!(conn.resp_body)
    assert body["url"] == "http://hex.pm/api/users/other"
    user = assert User.get("other")
    assert user.email == "email@mail.com"

    headers = [ { "content-type", "application/json" },
                { "authorization", "Basic " <> :base64.encode("other:pass") }]
    body = [username: "foo"]
    conn = conn("PATCH", "/api/users/other", JSON.encode!(body), headers: headers)
    conn = Router.call(conn, [])

    assert conn.status == 200
    body = JSON.decode!(conn.resp_body)
    assert body["url"] == "http://hex.pm/api/users/other"
    assert User.get("other")
    refute User.get("foo")
  end

  test "create package" do
    headers = [ { "content-type", "application/json" },
                { "authorization", "Basic " <> :base64.encode("eric:eric") }]
    body = [meta: []]
    conn = conn("PUT", "/api/packages/ecto", JSON.encode!(body), headers: headers)
    conn = Router.call(conn, [])

    assert conn.status == 201
    body = JSON.decode!(conn.resp_body)
    assert body["url"] == "http://hex.pm/api/packages/ecto"

    user_id = User.get("eric").id
    package = assert Package.get("ecto")
    assert package.name == "ecto"
    assert package.owner_id == user_id
  end

  test "update package" do
    Package.create("ecto", User.get("eric"), [])

    headers = [ { "content-type", "application/json" },
                { "authorization", "Basic " <> :base64.encode("eric:eric") }]
    body = [meta: [description: "awesomeness"]]
    conn = conn("PUT", "/api/packages/ecto", JSON.encode!(body), headers: headers)
    conn = Router.call(conn, [])

    assert conn.status == 200
    body = JSON.decode!(conn.resp_body)
    assert body["url"] == "http://hex.pm/api/packages/ecto"

    assert Package.get("ecto").meta["description"] == "awesomeness"
  end

  test "create package authorizes" do
    headers = [ { "content-type", "application/json" },
                { "authorization", "Basic " <> :base64.encode("eric:WRONG") }]
    body = [meta: []]
    conn = conn("PUT", "/api/packages/ecto", JSON.encode!(body), headers: headers)
    conn = Router.call(conn, [])

    assert conn.status == 401
    assert conn.resp_headers["www-authenticate"] == "Basic realm=hex"
  end

  test "update package authorizes" do
    Package.create("ecto", User.get("eric"), [])

    headers = [ { "content-type", "application/json" },
                { "authorization", "Basic " <> :base64.encode("other:other") }]
    body = [meta: []]
    conn = conn("PUT", "/api/packages/ecto", JSON.encode!(body), headers: headers)
    conn = Router.call(conn, [])

    assert conn.status == 401
    assert conn.resp_headers["www-authenticate"] == "Basic realm=hex"
  end

  test "create package validates" do
    headers = [ { "content-type", "application/json" },
                { "authorization", "Basic " <> :base64.encode("eric:eric") }]
    body = [meta: [links: "invalid"]]
    conn = conn("PUT", "/api/packages/ecto", JSON.encode!(body), headers: headers)
    conn = Router.call(conn, [])

    assert conn.status == 422
    body = JSON.decode!(conn.resp_body)
    assert body["message"] == "Validation failed"
    assert body["errors"]["meta"]["links"] == "wrong type, expected: dict(string, string)"
  end

  test "create releases" do
    headers = [ { "content-type", "application/octet-stream" },
                { "authorization", "Basic " <> :base64.encode("eric:eric") }]
    body = create_tar([app: :postgrex, version: "0.0.1", git_url: "url", git_ref: "ref", requirements: []], [])
    conn = conn("POST", "/api/packages/postgrex/releases", body, headers: headers)
    conn = Router.call(conn, [])

    assert conn.status == 201
    body = JSON.decode!(conn.resp_body)
    assert body["url"] == "http://hex.pm/api/packages/postgrex/releases/0.0.1"

    body = create_tar([app: :postgrex, version: "0.0.2", git_url: "url", git_ref: "ref", requirements: []], [])
    conn = conn("POST", "/api/packages/postgrex/releases", body, headers: headers)
    conn = Router.call(conn, [])

    assert conn.status == 201

    postgrex = Package.get("postgrex")
    postgrex_id = postgrex.id
    assert [ Release.Entity[package_id: ^postgrex_id, version: "0.0.1"],
             Release.Entity[package_id: ^postgrex_id, version: "0.0.2"] ] =
           Release.all(postgrex)
  end

  test "update release" do
    headers = [ { "content-type", "application/octet-stream" },
                { "authorization", "Basic " <> :base64.encode("eric:eric") }]
    body = create_tar([app: :postgrex, version: "0.0.1", git_url: "url", git_ref: "ref", requirements: []], [])
    conn = conn("POST", "/api/packages/postgrex/releases", body, headers: headers)
    conn = Router.call(conn, [])
    assert conn.status == 201

    body = create_tar([app: :postgrex, version: "0.0.1", git_url: "new_url", git_ref: "new_ref", requirements: []], [])
    conn = conn("POST", "/api/packages/postgrex/releases", body, headers: headers)
    conn = Router.call(conn, [])
    assert conn.status == 200

    postgrex = Package.get("postgrex")
    assert Release.get(postgrex, "0.0.1")
  end

  test "delete release" do
    headers = [ { "content-type", "application/octet-stream" },
                { "authorization", "Basic " <> :base64.encode("eric:eric") }]
    body = create_tar([app: :postgrex, version: "0.0.1", git_url: "url", git_ref: "ref", requirements: []], [])
    conn = conn("POST", "/api/packages/postgrex/releases", body, headers: headers)
    conn = Router.call(conn, [])
    assert conn.status == 201

    headers = [ { "authorization", "Basic " <> :base64.encode("eric:eric") }]
    conn = conn("DELETE", "/api/packages/postgrex/releases/0.0.1", [], headers: headers)
    conn = Router.call(conn, [])
    assert conn.status == 204

    postgrex = Package.get("postgrex")
    refute Release.get(postgrex, "0.0.1")
  end

  test "create release authorizes" do
    headers = [ { "content-type", "application/octet-stream" },
                { "authorization", "Basic " <> :base64.encode("other:other") }]
    body = create_tar([app: :postgrex, version: "0.0.1", git_url: "url", git_ref: "ref", requirements: []], [])
    conn = conn("POST", "/api/packages/postgrex/releases", body, headers: headers)
    conn = Router.call(conn, [])

    assert conn.status == 401
    assert conn.resp_headers["www-authenticate"] == "Basic realm=hex"
  end

  test "create releases with requirements" do
    headers = [ { "content-type", "application/octet-stream" },
                { "authorization", "Basic " <> :base64.encode("eric:eric") }]
    body = create_tar([app: :postgrex, version: "0.0.1", git_url: "url", git_ref: "ref", requirements: [decimal: "~> 0.0.1"]], [])
    conn = conn("POST", "/api/packages/postgrex/releases", body, headers: headers)
    conn = Router.call(conn, [])

    assert conn.status == 201
    body = JSON.decode!(conn.resp_body)
    assert body["requirements"] == [{ "decimal", "~> 0.0.1" }]

    postgrex = Package.get("postgrex")
    assert [{ "decimal", "~> 0.0.1" }] = Release.get(postgrex, "0.0.1").requirements.to_list
  end

  test "create release updates registry" do
    path = "tmp/registry.ets"
    { :ok, _ } = RegistryBuilder.start_link
    RegistryBuilder.sync_rebuild

    File.touch!(path, {{2000,1,1,},{1,1,1}})
    File.Stat[mtime: mtime] = File.stat!(path)

    headers = [ { "content-type", "application/octet-stream" },
                { "authorization", "Basic " <> :base64.encode("eric:eric") }]
    body = create_tar([app: :postgrex, version: "0.0.1", git_url: "url", git_ref: "ref", requirements: [decimal: "~> 0.0.1"]], [])
    conn = conn("POST", "/api/packages/postgrex/releases", body, headers: headers)
    conn = Router.call(conn, [])
    assert conn.status == 201

    refute File.Stat[mtime: {{2000,1,1,},{1,1,1}}] = File.stat!(path)
  after
    RegistryBuilder.stop
  end

  test "fetch registry" do
    { :ok, _ } = RegistryBuilder.start_link
    RegistryBuilder.sync_rebuild

    conn = conn("GET", "/registry.ets.gz")
    conn = Router.call(conn, [])

    assert conn.status in 200..399
  after
    RegistryBuilder.stop
  end

  @tag :integration
  test "integration fetch registry" do
    if HexWeb.Config.s3_bucket do
      HexWeb.Config.store(HexWeb.Store.S3)
    end

    { :ok, _ } = RegistryBuilder.start_link
    RegistryBuilder.sync_rebuild

    port = HexWeb.Config.port
    url = String.to_char_list!("http://localhost:#{port}/registry.ets.gz")
    :inets.start

    assert { :ok, response } = :httpc.request(:head, { url, [] }, [], [])
    assert { { _version, 200, _reason }, _headers, _body } = response
  after
    RegistryBuilder.stop
    HexWeb.Config.store(HexWeb.Store.Local)
  end

  @tag :integration
  test "integration fetch tarball" do
    if HexWeb.Config.s3_bucket do
      HexWeb.Config.store(HexWeb.Store.S3)
    end

    headers = [ { "content-type", "application/octet-stream" },
                { "authorization", "Basic " <> :base64.encode("eric:eric") }]
    body = create_tar([app: :postgrex, version: "0.0.1", requirements: [decimal: "~> 0.0.1"]], [])
    conn = conn("POST", "/api/packages/postgrex/releases", body, headers: headers)
    conn = Router.call(conn, [])
    assert conn.status == 201

    port = HexWeb.Config.port
    url = String.to_char_list!("http://localhost:#{port}/tarballs/postgrex-0.0.1.tar")
    :inets.start

    assert { :ok, response } = :httpc.request(:head, { url, [] }, [], [])
    assert { { _version, 200, _reason }, _headers, _body } = response
  after
    HexWeb.Config.store(HexWeb.Store.Local)
  end

  test "get user" do
    conn = conn("GET", "/api/users/eric", [], [])
    conn = Router.call(conn, [])

    assert conn.status == 200
    body = JSON.decode!(conn.resp_body)
    assert body["username"] == "eric"
    assert body["email"] == "eric@mail.com"
    refute body["password"]
  end

  test "elixir media response" do
    headers = [ { "accept", "application/vnd.hex+elixir" } ]
    conn = conn("GET", "/api/users/eric", [], headers: headers)
    conn = Router.call(conn, [])

    assert conn.status == 200
    { body, [] } = Code.eval_string(conn.resp_body)
    assert body["username"] == "eric"
    assert body["email"] == "eric@mail.com"
  end

  test "elixir media request" do
    body = [username: "name", email: "email@mail.com", password: "pass"]
           |> HexWeb.Util.safe_serialize_elixir
    conn = conn("POST", "/api/users", body, headers: [{ "content-type", "application/vnd.hex+elixir" }])
    conn = Router.call(conn, [])

    assert conn.status == 201
    body = JSON.decode!(conn.resp_body)
    assert body["url"] == "http://hex.pm/api/users/name"

    user = assert User.get("name")
    assert user.email == "email@mail.com"
  end

  test "get package" do
    conn = conn("GET", "/api/packages/decimal", [], [])
    conn = Router.call(conn, [])

    assert conn.status == 200
    body = JSON.decode!(conn.resp_body)
    assert body["name"] == "decimal"

    release = List.first(body["releases"])
    assert release["url"] == "http://hex.pm/api/packages/decimal/releases/0.0.1"
    assert release["version"] == "0.0.1"
  end

  test "get release" do
    conn = conn("GET", "/api/packages/decimal/releases/0.0.1", [], [])
    conn = Router.call(conn, [])

    assert conn.status == 200
    body = JSON.decode!(conn.resp_body)
    assert body["url"] == "http://hex.pm/api/packages/decimal/releases/0.0.1"
    assert body["version"] == "0.0.1"
  end

  test "accepted formats" do
    headers = [ { "accept", "application/xml" } ]
    conn = conn("GET", "/api/users/eric", [], headers: headers)
    conn = Router.call(conn, [])
    assert conn.status == 415

    headers = [ { "accept", "application/xml" } ]
    conn = conn("GET", "/api/WRONGURL", [], headers: headers)
    conn = Router.call(conn, [])
    assert conn.status == 404

    headers = [ { "accept", "application/json" } ]
    conn = conn("GET", "/api/users/eric", [], headers: headers)
    conn = Router.call(conn, [])
    assert conn.status == 200
    JSON.decode!(conn.resp_body)

    headers = [ { "accept", "application/vnd.hex" } ]
    conn = conn("GET", "/api/users/eric", [], headers: headers)
    conn = Router.call(conn, [])
    assert conn.status == 200
    JSON.decode!(conn.resp_body)

    headers = [ { "accept", "application/vnd.hex+json" } ]
    conn = conn("GET", "/api/users/eric", [], headers: headers)
    conn = Router.call(conn, [])
    assert conn.status == 200
    assert conn.resp_headers["x-hex-media-type"] == "hex.beta"
    JSON.decode!(conn.resp_body)

    headers = [ { "accept", "application/vnd.hex.vUNSUPPORTED+json" } ]
    conn = conn("GET", "/api/users/eric", [], headers: headers)
    conn = Router.call(conn, [])
    assert conn.status == 415

    headers = [ { "accept", "application/vnd.hex.beta" } ]
    conn = conn("GET", "/api/users/eric", [], headers: headers)
    conn = Router.call(conn, [])
    assert conn.status == 200
    assert conn.resp_headers["x-hex-media-type"] == "hex.beta"
    JSON.decode!(conn.resp_body)
  end

  test "fetch many packages" do
    conn = conn("GET", "/api/packages", [], [])
    conn = Router.call(conn, [])

    assert conn.status == 200
    body = JSON.decode!(conn.resp_body)
    assert length(body) == 2

    conn = conn("GET", "/api/packages?search=post", [], [])
    conn = Router.call(conn, [])

    assert conn.status == 200
    body = JSON.decode!(conn.resp_body)
    assert length(body) == 1

    conn = conn("GET", "/api/packages?page=1", [], [])
    conn = Router.call(conn, [])

    assert conn.status == 200
    body = JSON.decode!(conn.resp_body)
    assert length(body) == 2

    conn = conn("GET", "/api/packages?page=2", [], [])
    conn = Router.call(conn, [])

    assert conn.status == 200
    body = JSON.decode!(conn.resp_body)
    assert length(body) == 0
  end

  test "installs" do
    conn = conn("GET", "/installs", [], [])
    conn = Router.call(conn, [])

    assert conn.status == 200
    body = JSON.decode!(conn.resp_body)
    assert body["dev"]["version"] == "0.0.1-dev"
  end

  test "redirect" do
    url      = HexWeb.Config.url
    app_host = HexWeb.Config.app_host
    use_ssl  = HexWeb.Config.use_ssl

    HexWeb.Config.url("https://hex.pm")
    HexWeb.Config.app_host("some-host.com")
    HexWeb.Config.use_ssl(true)

    try do
      conn = conn("GET", "/foobar", [], []).scheme(:http)
      conn = Router.call(conn, [])
      assert conn.status == 301
      assert conn.resp_headers["location"] == "https://hex.pm/foobar"

      conn = conn("GET", "/foobar", [], []).scheme(:https).host("some-host.com")
      conn = Router.call(conn, [])
      assert conn.status == 301
      assert conn.resp_headers["location"] == "https://hex.pm/foobar"
    after
      HexWeb.Config.url(url)
      HexWeb.Config.app_host(app_host)
      HexWeb.Config.use_ssl(use_ssl)
    end
  end

  test "forwarded" do
    headers = [ { "x-forwarded-proto", "https" } ]
    conn = conn("GET", "/foobar", [], headers: headers)
    conn = Router.call(conn, [])
    assert conn.scheme == :https

    headers = [ { "x-forwarded-port", "12345" } ]
    conn = conn("GET", "/foobar", [], headers: headers)
    conn = Router.call(conn, [])
    assert conn.port == 12345
  end
end
