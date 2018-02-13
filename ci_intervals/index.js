var newman = require('newman');

function go () {
  newman.run({
    collection: './Handy Scripts.postman_collection.json',
    reporters: 'cli',
    globals: {
      "id": "5bfde907-2a1e-8c5a-2246-4aff74b74236",
      "name": "test-env",
      "values": [
          {
            "key": "REPO",
            "value": process.env.REPO,
            "type": "text",
            "enabled": true
          },
          {
            "key": "BRANCH",
            "value": process.env.BRANCH,
            "type": "text",
            "enabled": true
          },
          {
              "key": "GIT_TOKEN",
              "value": process.env.GITHUB,
              "type": "text",
              "enabled": true
          },
          {
              "key": "TARGET_ENVIRONMENT",
              "value": process.env.TARGET_ENVIRONMENT,
              "type": "text",
              "enabled": true
          }
      ],
      "_postman_variable_scope": "globals"
  },
  }, (err) => {
    if (err) { throw err; }
    console.log('collection run complete!');
  });
}
// go() //Uncomment this line for local testing

exports.handler = function (event, context) {
  go()
};
