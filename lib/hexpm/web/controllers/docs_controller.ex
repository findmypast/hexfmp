defmodule Hexpm.Web.DocsController do
  use Hexpm.Web, :controller

  def usage(conn, _params) do
    render conn, "usage.html", [
      title: "Mix usage",
      container: "container page docs"
    ]
  end

  def fmp(conn, _params) do
    render conn, "fmp.html", [
      title: "Hexfmp usage",
      container: "container page docs"
    ]
  end

  def rebar3_usage(conn, _params) do
    render conn, "rebar3_usage.html", [
      title: "Rebar3 usage",
      container: "container page docs"
    ]
  end

  def publish(conn, _params) do
    render conn, "publish.html", [
      title: "Mix publish package",
      container: "container page docs"
    ]
  end

  def rebar3_publish(conn, _params) do
    render conn, "rebar3_publish.html", [
      title: "Rebar3 publish package",
      container: "container page docs"
    ]
  end

  def tasks(conn, _params) do
    render conn, "tasks.html", [
      title: "Mix tasks",
      container: "container page docs"
    ]
  end

  def coc(conn, _params) do
    render conn, "coc.html", [
      title: "Code of Conduct",
      container: "container page docs"
    ]
  end

  def faq(conn, _params) do
    render conn, "faq.html", [
      title: "FAQ",
      container: "container page docs"
    ]
  end

  def mirrors(conn, _params) do
    render conn, "mirrors.html", [
      title: "Mirrors",
      container: "container page docs"
    ]
  end

  def public_keys(conn, _params) do
    render conn, "public_keys.html", [
      title: "Public keys",
      container: "container page docs"
    ]
  end
end
