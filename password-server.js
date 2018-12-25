var express = require("express");
const shell = require('shelljs');
var bodyParser = require('body-parser');


var app = express();
app.use(bodyParser.json()); // support json encoded bodies
app.use(bodyParser.urlencoded({ extended: true }));

const port = process.argv[2];
const confToken = process.argv[3];

const ipFilter = require('./ipConfig.json');
var out = "";
 app.listen(port, function(){
});

app.use(express.static('public'))

app.post("/password/get", function(req, res){
  //console.log("DEBUG ", JSON.stringify(req.query))
  const gi = req.body.collectionIdentifier;
  const pi = req.body.passwordIdentifier;
  const token = req.body.token;
  const cmd = 'sudo confidentalInfo.sh getWithToken "' + gi + '" "' + pi + '" "' + token + '"';
  const password = shell.exec(cmd);
  // shell.exec('clear')
  res.send(password.replace("\n", ""));
});


app.get("/keywords", function (req, res) {
  let keywords = shell.exec("find ./public/keywords/ -type f | sed \"s/.*\\/\\(.*\\).html/\\\"\\1\\\",/\"");
  keywords = keywords.replace(/\$/g, "/");
  keywords = keywords.replace(/\|/g, ".");
  keywords = "[" + keywords.substring(0, keywords.length - 2) + "]"
  res.send(keywords);
});

app.get("/dockerCommand", function (req, res) {
  const cmd = 'grep -oP "docker.*" ./run.sh';
  const dockerCommand = shell.exec(cmd);
  res.send(dockerCommand);
});

app.get("/token", function (req, res) {
  res.send(confToken);
});
