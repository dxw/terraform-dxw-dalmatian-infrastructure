function pathChroot(path, trimDirsNum, newRoot) {
  var pattern = "^\/(?:[^\/]*\/){" + trimDirsNum.toString() + "}"
  var re = new RegExp(pattern, "g");
  var newPath = path.replace(re, "/");
  newPath = newRoot.concat("", newPath);
  newPath = newPath.replace(/\/\//g, "/");
  return newPath;
}
function basicAuth(request, userList) {
  var headers = request.headers;
  var authHeader = headers.authorization && headers.authorization.value;
  if (authHeader && authHeader.startsWith("Basic ")) {
    var encodedCreds = authHeader.split(' ')[1];
    var decoded = null;
    try {
      decoded = atob(encodedCreds);
    } catch (e) {}
    if (decoded) {
      var parts = decoded.split(':');
      if (parts.length === 2) {
        var username = parts[0];
        var password = parts[1];
        if (userList[username] === password) {
          return request;
        }
      }
    }
  }
  return {
    statusCode: 401,
    statusDescription: 'Unauthorized',
    headers: {
      'www-authenticate': {
        value: 'Basic realm="Restricted Area"'
      },
      'content-type': {
        value: 'text/html'
      }
    },
    body: '<html><body><h1>401 Unauthorized</h1><p>Access denied</p></body></html>'
  };
}
function handler(event) {
  var req = event.request;

  %{~ if new_root != "/" || trim_request_dirs_num != 0}
  var newRoot = "${new_root}"
  var trimRequestDirsNum = ${trim_request_dirs_num};
  var newUri = pathChroot(req.uri, trimRequestDirsNum, newRoot);
  if (newUri.slice(-1) == "/") {
    newUri = newUri.concat("", "index.html")
  }
  req.uri = newUri;
  %{endif~}
  %{~ if basic_auth_user_list != "{}" }
  const userList = JSON.parse('${basic_auth_user_list}');
  req = basicAuth(req, userList)
  %{endif~}

  return req;
}
