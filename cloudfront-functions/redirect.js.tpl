var target = ${target};
var statusCode = ${status_code};
var statusDescription = ${status_description};
var preservePath = ${preserve_path};

function queryString(querystring) {
  var parts = [];
  Object.keys(querystring).forEach(function (name) {
    var param = querystring[name];
    var values = param.multiValue ? param.multiValue.map(function (v) { return v.value; }) : [param.value];
    values.forEach(function (value) {
      parts.push(value === "" ? name : name + "=" + value);
    });
  });
  return parts.length > 0 ? "?" + parts.join("&") : "";
}

function handler(event) {
  var location = target;
  if (preservePath) {
    location = target.replace(/\/$/, "") + event.request.uri + queryString(event.request.querystring);
  }
  return {
    statusCode: statusCode,
    statusDescription: statusDescription,
    headers: {
      location: { value: location }
    }
  };
}
