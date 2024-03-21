function pathChroot(path, trimDirsNum, newRoot) {
  var pattern = "^\/(?:[^\/]*\/){" + trimDirsNum.toString() + "}"
  var re = new RegExp(pattern, "g");
  var newPath = path.replace(re, "/");
  newPath = newRoot.concat("", newPath);
  newPath = newPath.replace(/\/\//g, "/");
  return newPath;
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

  return req;
}
