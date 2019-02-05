create_user = function(_, request) {
  var User = require('views/lib/user');
  var user = User.from(request);

  return [user.doc(), user.summary()]
}
