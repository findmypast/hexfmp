defmodule Hexpm.Web.OpenSearchControllerTest do
  use Hexpm.ConnCase, async: true

  test "opensearch" do
    conn = get build_conn(), "/hexsearch.xml"
    assert response(conn, 200) =~ "<Url type=\"text/html\" method=\"get\" template=\"http://localhost:4000/packages?search={searchTerms}&amp;sort=downloads\" />"
  end
end
