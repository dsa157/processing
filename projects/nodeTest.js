const { exec } = require("child_process");

var cmd = "/usr/local/bin/processing-java --sketch=/Users/dsa157/Documents/Processing/projects/nodeTest --run ";

exec(cmd, (error, stdout, stderr) => {
    if (error) {
        console.log(`error: ${error.message}`);
        return;
    }
    if (stderr) {
        console.log(`stderr: ${stderr}`);
        return;
    }
    console.log(`stdout: ${stdout}`);
});
